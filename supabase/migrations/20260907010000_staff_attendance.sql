-- Migration: 20260907010000_staff_attendance.sql
-- Description: ลงเวลาปฏิบัติงานของบุคลากร — staff attendance and staff leave.
--
-- Why this exists: `director_teachers_page` shipped "มาปฏิบัติงานวันนี้ / มาสาย /
-- ลา" cards, and `school_teachers_page` and `director_scan_page` want the same
-- figures. Nothing in the schema could supply them: `attendance_records` and
-- `homeroom_attendance_records` are student-scoped, and `leave_requests` is
-- *student* leave (`student_id` and `parent_id` are both NOT NULL, so a staff
-- member cannot be its subject). Those cards were removed in fe8e4e6 rather
-- than shown as zero; this is the schema that lets them come back honestly.
--
-- Design notes:
--
--   * มาสาย is not a judgement the UI may make. It is derived once, at
--     check-in, against `staff_work_hours` for the school, and stored on the
--     record. A school that has not configured its hours gets
--     `work_hours_not_configured` from check-in rather than a guessed status —
--     the whole point is that lateness has a stated basis.
--
--   * Thailand runs UTC+7 and Postgres `now()` is UTC. Every date and
--     wall-clock comparison here goes through `AT TIME ZONE 'Asia/Bangkok'`,
--     so a 07:30 check-in is not filed against the previous day.
--
--   * A staff member with no record for a day is `no_record`, never `absent`.
--     Absence is something a school_admin asserts; silence is not evidence.
--
--   * Staff leave is its own table rather than a status on the attendance
--     record: it is requested ahead of time, spans a range, and is approved by
--     someone else. An approved leave covering a date wins over the absence of
--     a check-in when the day is read back.
--
-- Everything here is additive. No existing table or RPC is modified.

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------

-- One row per school. Absent = the school has not said when its day starts,
-- which is why check-in refuses rather than assuming 08:00.
CREATE TABLE IF NOT EXISTS public.staff_work_hours (
  school_id uuid PRIMARY KEY REFERENCES public.schools(id) ON DELETE CASCADE,
  work_start_time time NOT NULL,
  work_end_time time NOT NULL,
  -- Minutes after work_start_time that still count as on time.
  late_grace_minutes int NOT NULL DEFAULT 0 CHECK (late_grace_minutes >= 0),
  updated_by uuid REFERENCES public.users(id),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK (work_end_time > work_start_time)
);

ALTER TABLE public.staff_work_hours ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.staff_attendance_records (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id uuid NOT NULL REFERENCES public.schools(id),
  user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  -- The Bangkok calendar date the work belongs to, not a UTC date.
  work_date date NOT NULL,
  check_in_at timestamptz,
  check_out_at timestamptz,
  -- present      = มาปฏิบัติงาน (checked in within the grace window)
  -- late         = มาสาย (checked in after it)
  -- official_duty = ไปราชการ / อบรม — recorded by an admin, no check-in
  -- absent       = ขาดงาน — an assertion an admin makes, never inferred
  status varchar NOT NULL CHECK (status IN ('present', 'late', 'official_duty', 'absent')),
  -- 'self' = the staff member pressed check in; 'admin' = entered for them.
  source varchar NOT NULL DEFAULT 'self' CHECK (source IN ('self', 'admin')),
  note text,
  recorded_by uuid REFERENCES public.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, work_date)
);

ALTER TABLE public.staff_attendance_records ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS staff_attendance_school_date_idx
  ON public.staff_attendance_records (school_id, work_date);

CREATE TABLE IF NOT EXISTS public.staff_leave_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id uuid NOT NULL REFERENCES public.schools(id),
  user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  -- ลาป่วย / ลากิจ / ลาพักผ่อน / ลาคลอด — the four in ระเบียบการลา that a
  -- school records. Constrained because the summary counts them by kind.
  leave_type varchar NOT NULL CHECK (leave_type IN ('sick', 'personal', 'vacation', 'maternity')),
  start_date date NOT NULL,
  end_date date NOT NULL,
  reason text,
  status varchar NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'approved', 'rejected', 'cancelled')),
  reviewed_by uuid REFERENCES public.users(id),
  reviewed_at timestamptz,
  review_note text,
  created_at timestamptz NOT NULL DEFAULT now(),
  CHECK (end_date >= start_date)
);

ALTER TABLE public.staff_leave_requests ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS staff_leave_school_range_idx
  ON public.staff_leave_requests (school_id, start_date, end_date);

-- ---------------------------------------------------------------------------
-- Work hours
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.get_staff_work_hours(p_token text)
RETURNS TABLE (
  work_start_time time,
  work_end_time time,
  late_grace_minutes int
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  -- Any staff member may read them: you cannot know whether you are late
  -- without knowing when the day starts.
  IF v_actor.role NOT IN ('teacher', 'school_admin', 'executive', 'super_admin') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  RETURN QUERY
  SELECT w.work_start_time, w.work_end_time, w.late_grace_minutes
    FROM public.staff_work_hours w
   WHERE w.school_id = v_actor.school_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.set_staff_work_hours(
  p_token text,
  p_work_start_time time,
  p_work_end_time time,
  p_late_grace_minutes int DEFAULT 0
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  IF v_actor.role NOT IN ('school_admin', 'super_admin') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  IF p_work_end_time <= p_work_start_time THEN
    RAISE EXCEPTION 'invalid_work_hours';
  END IF;

  IF p_late_grace_minutes < 0 THEN
    RAISE EXCEPTION 'invalid_grace';
  END IF;

  INSERT INTO public.staff_work_hours
    (school_id, work_start_time, work_end_time, late_grace_minutes, updated_by, updated_at)
  VALUES (
    v_actor.school_id, p_work_start_time, p_work_end_time,
    p_late_grace_minutes, v_actor.user_id, now()
  )
  ON CONFLICT (school_id) DO UPDATE
    SET work_start_time = excluded.work_start_time,
        work_end_time = excluded.work_end_time,
        late_grace_minutes = excluded.late_grace_minutes,
        updated_by = excluded.updated_by,
        updated_at = now();

  INSERT INTO public.audit_logs
    (school_id, user_id, acted_role, action, entity_type, entity_id, details)
  VALUES (
    v_actor.school_id, v_actor.user_id, v_actor.role,
    'staff_work_hours.set', 'staff_work_hours', v_actor.school_id::text,
    jsonb_build_object(
      'start', p_work_start_time, 'end', p_work_end_time,
      'grace', p_late_grace_minutes
    )
  );
END;
$$;

-- ---------------------------------------------------------------------------
-- Check in / check out
-- ---------------------------------------------------------------------------

-- Returns the resulting status ('present' or 'late') so the caller does not
-- have to re-derive it. Refuses when the school has no configured hours: a
-- check-in whose lateness cannot be judged is worse than no check-in.
CREATE OR REPLACE FUNCTION public.staff_check_in(
  p_token text,
  p_note text DEFAULT NULL
)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_hours record;
  v_local timestamp;
  v_date date;
  v_status text;
  v_existing record;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  IF v_actor.role NOT IN ('teacher', 'school_admin', 'executive') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  SELECT * INTO v_hours FROM public.staff_work_hours
   WHERE school_id = v_actor.school_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'work_hours_not_configured';
  END IF;

  v_local := now() AT TIME ZONE 'Asia/Bangkok';
  v_date := v_local::date;

  SELECT * INTO v_existing FROM public.staff_attendance_records
   WHERE user_id = v_actor.user_id AND work_date = v_date;
  IF FOUND AND v_existing.check_in_at IS NOT NULL THEN
    RAISE EXCEPTION 'already_checked_in';
  END IF;

  v_status := CASE
    WHEN v_local::time
         <= v_hours.work_start_time + make_interval(mins => v_hours.late_grace_minutes)
      THEN 'present'
    ELSE 'late'
  END;

  INSERT INTO public.staff_attendance_records
    (school_id, user_id, work_date, check_in_at, status, source, note, recorded_by)
  VALUES (
    v_actor.school_id, v_actor.user_id, v_date, now(), v_status, 'self',
    nullif(trim(coalesce(p_note, '')), ''), v_actor.user_id
  )
  ON CONFLICT (user_id, work_date) DO UPDATE
    SET check_in_at = excluded.check_in_at,
        status = excluded.status,
        source = excluded.source,
        note = coalesce(excluded.note, public.staff_attendance_records.note),
        updated_at = now();

  RETURN v_status;
END;
$$;

CREATE OR REPLACE FUNCTION public.staff_check_out(p_token text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_date date;
  v_existing record;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  IF v_actor.role NOT IN ('teacher', 'school_admin', 'executive') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  v_date := (now() AT TIME ZONE 'Asia/Bangkok')::date;

  SELECT * INTO v_existing FROM public.staff_attendance_records
   WHERE user_id = v_actor.user_id AND work_date = v_date;
  IF NOT FOUND OR v_existing.check_in_at IS NULL THEN
    RAISE EXCEPTION 'not_checked_in';
  END IF;

  UPDATE public.staff_attendance_records
     SET check_out_at = now(), updated_at = now()
   WHERE id = v_existing.id;
END;
$$;

-- The admin path: ไปราชการ, ขาดงาน, or a check-in entered on someone's behalf.
CREATE OR REPLACE FUNCTION public.record_staff_attendance(
  p_token text,
  p_user_id uuid,
  p_work_date date,
  p_status text,
  p_note text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_target record;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  IF v_actor.role NOT IN ('school_admin', 'super_admin') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  IF p_status NOT IN ('present', 'late', 'official_duty', 'absent') THEN
    RAISE EXCEPTION 'invalid_status';
  END IF;

  SELECT * INTO v_target FROM public.users WHERE id = p_user_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'user_not_found';
  END IF;

  IF v_actor.role <> 'super_admin'
     AND v_target.school_id IS DISTINCT FROM v_actor.school_id THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.user_roles ur
     WHERE ur.user_id = p_user_id
       AND ur.school_id = v_target.school_id
       AND ur.role IN ('teacher', 'school_admin', 'executive')
  ) THEN
    RAISE EXCEPTION 'not_staff';
  END IF;

  INSERT INTO public.staff_attendance_records
    (school_id, user_id, work_date, status, source, note, recorded_by)
  VALUES (
    v_target.school_id, p_user_id, p_work_date, p_status, 'admin',
    nullif(trim(coalesce(p_note, '')), ''), v_actor.user_id
  )
  ON CONFLICT (user_id, work_date) DO UPDATE
    SET status = excluded.status,
        source = excluded.source,
        note = excluded.note,
        recorded_by = excluded.recorded_by,
        updated_at = now();

  INSERT INTO public.audit_logs
    (school_id, user_id, acted_role, action, entity_type, entity_id, details)
  VALUES (
    v_target.school_id, v_actor.user_id, v_actor.role,
    'staff_attendance.record', 'staff_attendance_records', p_user_id::text,
    jsonb_build_object('work_date', p_work_date, 'status', p_status)
  );
END;
$$;

-- ---------------------------------------------------------------------------
-- Reads
-- ---------------------------------------------------------------------------

-- One row per staff member for the given day. `status` is 'no_record' when
-- nobody has said anything about them — deliberately not 'absent'.
CREATE OR REPLACE FUNCTION public.list_staff_attendance(
  p_token text,
  p_work_date date DEFAULT NULL
)
RETURNS TABLE (
  user_id uuid,
  full_name text,
  status text,
  leave_type text,
  check_in_at timestamptz,
  check_out_at timestamptz,
  source text,
  note text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_date date;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  IF v_actor.role NOT IN ('school_admin', 'executive', 'super_admin') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  v_date := coalesce(p_work_date, (now() AT TIME ZONE 'Asia/Bangkok')::date);

  RETURN QUERY
  SELECT
    u.id,
    trim(u.first_name || ' ' || u.last_name),
    -- An approved leave covering the day beats the absence of a check-in.
    CASE
      WHEN l.id IS NOT NULL THEN 'leave'
      WHEN r.id IS NOT NULL THEN r.status::text
      ELSE 'no_record'
    END,
    l.leave_type::text,
    r.check_in_at,
    r.check_out_at,
    r.source::text,
    r.note
  FROM public.users u
  LEFT JOIN public.staff_attendance_records r
         ON r.user_id = u.id AND r.work_date = v_date
  LEFT JOIN LATERAL (
    SELECT sl.id, sl.leave_type
      FROM public.staff_leave_requests sl
     WHERE sl.user_id = u.id
       AND sl.status = 'approved'
       AND v_date BETWEEN sl.start_date AND sl.end_date
     LIMIT 1
  ) l ON true
  WHERE u.school_id = v_actor.school_id
    AND EXISTS (
      SELECT 1 FROM public.user_roles ur
       WHERE ur.user_id = u.id
         AND ur.school_id = u.school_id
         AND ur.role IN ('teacher', 'school_admin', 'executive')
    )
  ORDER BY trim(u.first_name || ' ' || u.last_name);
END;
$$;

-- The figures the "มาปฏิบัติงานวันนี้" cards need, counted in one place so two
-- pages cannot disagree. `work_hours_configured` travels with them: without
-- it the caller cannot tell "nobody is late" from "lateness is unknowable".
CREATE OR REPLACE FUNCTION public.get_staff_attendance_summary(
  p_token text,
  p_work_date date DEFAULT NULL
)
RETURNS TABLE (
  work_date date,
  total_staff int,
  present_count int,
  late_count int,
  leave_count int,
  official_duty_count int,
  absent_count int,
  no_record_count int,
  work_hours_configured boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_date date;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  IF v_actor.role NOT IN ('school_admin', 'executive', 'super_admin') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  v_date := coalesce(p_work_date, (now() AT TIME ZONE 'Asia/Bangkok')::date);

  RETURN QUERY
  WITH day AS (
    SELECT * FROM public.list_staff_attendance(p_token, v_date)
  )
  SELECT
    v_date,
    (SELECT count(*)::int FROM day),
    (SELECT count(*)::int FROM day d WHERE d.status = 'present'),
    (SELECT count(*)::int FROM day d WHERE d.status = 'late'),
    (SELECT count(*)::int FROM day d WHERE d.status = 'leave'),
    (SELECT count(*)::int FROM day d WHERE d.status = 'official_duty'),
    (SELECT count(*)::int FROM day d WHERE d.status = 'absent'),
    (SELECT count(*)::int FROM day d WHERE d.status = 'no_record'),
    EXISTS (SELECT 1 FROM public.staff_work_hours w
             WHERE w.school_id = v_actor.school_id);
END;
$$;

-- ---------------------------------------------------------------------------
-- Staff leave
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.request_staff_leave(
  p_token text,
  p_leave_type text,
  p_start_date date,
  p_end_date date,
  p_reason text DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_id uuid;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  IF v_actor.role NOT IN ('teacher', 'school_admin', 'executive') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  IF p_leave_type NOT IN ('sick', 'personal', 'vacation', 'maternity') THEN
    RAISE EXCEPTION 'invalid_leave_type';
  END IF;

  IF p_end_date < p_start_date THEN
    RAISE EXCEPTION 'invalid_date_range';
  END IF;

  INSERT INTO public.staff_leave_requests
    (school_id, user_id, leave_type, start_date, end_date, reason)
  VALUES (
    v_actor.school_id, v_actor.user_id, p_leave_type,
    p_start_date, p_end_date, nullif(trim(coalesce(p_reason, '')), '')
  )
  RETURNING id INTO v_id;

  RETURN v_id;
END;
$$;

-- school_admin sees the school's; a teacher sees only their own. The role
-- decides the scope rather than a caller-supplied flag.
CREATE OR REPLACE FUNCTION public.list_staff_leave_requests(
  p_token text,
  p_status text DEFAULT NULL,
  p_from date DEFAULT NULL,
  p_to date DEFAULT NULL
)
RETURNS TABLE (
  request_id uuid,
  user_id uuid,
  full_name text,
  leave_type text,
  start_date date,
  end_date date,
  reason text,
  status text,
  reviewer_name text,
  reviewed_at timestamptz,
  review_note text,
  created_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  IF v_actor.role NOT IN ('teacher', 'school_admin', 'executive', 'super_admin') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  RETURN QUERY
  SELECT
    sl.id,
    sl.user_id,
    trim(u.first_name || ' ' || u.last_name),
    sl.leave_type::text,
    sl.start_date,
    sl.end_date,
    sl.reason,
    sl.status::text,
    trim(rv.first_name || ' ' || rv.last_name),
    sl.reviewed_at,
    sl.review_note,
    sl.created_at
  FROM public.staff_leave_requests sl
  JOIN public.users u ON u.id = sl.user_id
  LEFT JOIN public.users rv ON rv.id = sl.reviewed_by
  WHERE sl.school_id = v_actor.school_id
    AND (v_actor.role <> 'teacher' OR sl.user_id = v_actor.user_id)
    AND (p_status IS NULL OR sl.status = p_status)
    AND (p_from IS NULL OR sl.end_date >= p_from)
    AND (p_to IS NULL OR sl.start_date <= p_to)
  ORDER BY sl.start_date DESC, sl.created_at DESC;
END;
$$;

CREATE OR REPLACE FUNCTION public.review_staff_leave_request(
  p_token text,
  p_request_id uuid,
  p_approve boolean,
  p_note text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_req record;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  IF v_actor.role NOT IN ('school_admin', 'super_admin') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  SELECT * INTO v_req FROM public.staff_leave_requests WHERE id = p_request_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'request_not_found';
  END IF;

  IF v_actor.role <> 'super_admin'
     AND v_req.school_id IS DISTINCT FROM v_actor.school_id THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  -- Re-deciding a settled request would silently rewrite history; the caller
  -- has stale data and must re-read.
  IF v_req.status <> 'pending' THEN
    RAISE EXCEPTION 'already_reviewed';
  END IF;

  UPDATE public.staff_leave_requests
     SET status = CASE WHEN p_approve THEN 'approved' ELSE 'rejected' END,
         reviewed_by = v_actor.user_id,
         reviewed_at = now(),
         review_note = nullif(trim(coalesce(p_note, '')), '')
   WHERE id = p_request_id;

  INSERT INTO public.audit_logs
    (school_id, user_id, acted_role, action, entity_type, entity_id, details)
  VALUES (
    v_req.school_id, v_actor.user_id, v_actor.role,
    'staff_leave.review', 'staff_leave_requests', p_request_id::text,
    jsonb_build_object('approved', p_approve)
  );
END;
$$;

-- The requester may withdraw their own request while it is still pending.
CREATE OR REPLACE FUNCTION public.cancel_staff_leave_request(
  p_token text,
  p_request_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_req record;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  SELECT * INTO v_req FROM public.staff_leave_requests WHERE id = p_request_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'request_not_found';
  END IF;

  IF v_req.user_id <> v_actor.user_id
     AND v_actor.role NOT IN ('school_admin', 'super_admin') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  IF v_req.status <> 'pending' THEN
    RAISE EXCEPTION 'already_reviewed';
  END IF;

  UPDATE public.staff_leave_requests
     SET status = 'cancelled'
   WHERE id = p_request_id;
END;
$$;

-- ---------------------------------------------------------------------------
-- Grants
--
-- `service_role` is revoked explicitly on every function: it is not a member
-- of anon/authenticated, but this project has leaked access three times by
-- assuming the reverse.
-- ---------------------------------------------------------------------------

REVOKE ALL ON FUNCTION public.get_staff_work_hours FROM PUBLIC, service_role;
GRANT EXECUTE ON FUNCTION public.get_staff_work_hours TO anon, authenticated;

REVOKE ALL ON FUNCTION public.set_staff_work_hours FROM PUBLIC, service_role;
GRANT EXECUTE ON FUNCTION public.set_staff_work_hours TO anon, authenticated;

REVOKE ALL ON FUNCTION public.staff_check_in FROM PUBLIC, service_role;
GRANT EXECUTE ON FUNCTION public.staff_check_in TO anon, authenticated;

REVOKE ALL ON FUNCTION public.staff_check_out FROM PUBLIC, service_role;
GRANT EXECUTE ON FUNCTION public.staff_check_out TO anon, authenticated;

REVOKE ALL ON FUNCTION public.record_staff_attendance FROM PUBLIC, service_role;
GRANT EXECUTE ON FUNCTION public.record_staff_attendance TO anon, authenticated;

REVOKE ALL ON FUNCTION public.list_staff_attendance FROM PUBLIC, service_role;
GRANT EXECUTE ON FUNCTION public.list_staff_attendance TO anon, authenticated;

REVOKE ALL ON FUNCTION public.get_staff_attendance_summary FROM PUBLIC, service_role;
GRANT EXECUTE ON FUNCTION public.get_staff_attendance_summary TO anon, authenticated;

REVOKE ALL ON FUNCTION public.request_staff_leave FROM PUBLIC, service_role;
GRANT EXECUTE ON FUNCTION public.request_staff_leave TO anon, authenticated;

REVOKE ALL ON FUNCTION public.list_staff_leave_requests FROM PUBLIC, service_role;
GRANT EXECUTE ON FUNCTION public.list_staff_leave_requests TO anon, authenticated;

REVOKE ALL ON FUNCTION public.review_staff_leave_request FROM PUBLIC, service_role;
GRANT EXECUTE ON FUNCTION public.review_staff_leave_request TO anon, authenticated;

REVOKE ALL ON FUNCTION public.cancel_staff_leave_request FROM PUBLIC, service_role;
GRANT EXECUTE ON FUNCTION public.cancel_staff_leave_request TO anon, authenticated;
