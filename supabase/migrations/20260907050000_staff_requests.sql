-- Migration: 20260907050000_staff_requests.sql
-- Description: staff_requests — ขอเข้าพบผู้บริหาร, ขอจัดประชุม, ขอไปราชการ,
-- each carried through a two-tier approval (หัวหน้าฝ่าย → ผอ.), and an
-- approved ไปราชการ request writing itself into staff_attendance_records
-- automatically.
--
-- Why this exists: `staff_check_in`/`list_staff_attendance` (20260907010000)
-- already know an `official_duty` status exists, but nothing could ever set
-- it except a school_admin typing it in by hand after the fact. A teacher
-- approved for ไปราชการ next Tuesday would show ยังไม่ลงเวลา on the day
-- itself, indistinguishable from someone who simply forgot to check in.
--
-- Scoped deliberately narrower than the general meeting/leave machinery
-- already in the schema:
--
--   * This is NOT `staff_leave_requests` (ลา) — that table already exists,
--     already ships, and is explicitly out of scope for this migration (see
--     WORK_LOG.md: "เพิ่มไฟล์แนบให้ staff_leave_requests" is its own,
--     separate pending item). DECISIONS_2026-09-07.md's item D reads "ลา /
--     ไปราชการ: 2 ชั้น" together, but ลา already shipped as a single
--     school_admin review before that decision was written; changing its
--     approval chain now is a decision for the project owner, not something
--     to do silently here. Flagged, not resolved, in the handoff.
--
--   * ขอเข้าพบ (`meet_request`) records the *ask*, not a scheduled meeting.
--     Approving one does not create a row in `meetings` — that would need
--     the approver to also pick a concrete time, which is a screen this
--     migration does not build. The requester and both reviewers see the
--     decision; turning an approved ask into an actual `one_on_one` meeting
--     is future work.
--
--   * Only `teacher` and `school_admin` may file a request here. `executive`
--     is deliberately excluded as a requester: they are the fixed level-2
--     approver in every case, and a director approving their own trip is a
--     self-approval loop this schema does not try to solve.
--
--   * "หัวหน้าฝ่าย" means the head of an administrative ฝ่าย specifically
--     (`departments.kind = 'administrative'`), not a กลุ่มสาระ lead — the
--     decision's wording is about administrative structure, not subject
--     departments. A requester who belongs to no administrative ฝ่าย, or
--     who *is* that ฝ่าย's head, has nobody to be the level-1 reviewer and
--     the request starts at level 2 directly, still requiring the
--     director's decision, never auto-approved.
--
-- Everything here is additive. No existing table or RPC is modified.

CREATE TABLE IF NOT EXISTS public.staff_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id uuid NOT NULL REFERENCES public.schools(id),
  requester_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  -- meet_request    = ขอเข้าพบผู้บริหาร
  -- meeting_request = ขอจัดประชุม
  -- official_duty   = ขอไปราชการ
  request_type varchar NOT NULL
    CHECK (request_type IN ('meet_request', 'meeting_request', 'official_duty')),
  subject varchar NOT NULL,
  detail text,
  start_date date NOT NULL,
  end_date date NOT NULL,
  location varchar,
  -- The administrative ฝ่าย used to route level 1, recorded even after
  -- decision so the trail says who the reviewer actually was at the time.
  department_id uuid REFERENCES public.departments(id) ON DELETE SET NULL,
  status varchar NOT NULL DEFAULT 'pending_head'
    CHECK (status IN ('pending_head', 'pending_executive', 'approved', 'rejected', 'cancelled')),
  head_decision varchar CHECK (head_decision IN ('approved', 'rejected')),
  head_by uuid REFERENCES public.users(id),
  head_at timestamptz,
  head_note text,
  exec_decision varchar CHECK (exec_decision IN ('approved', 'rejected')),
  exec_by uuid REFERENCES public.users(id),
  exec_at timestamptz,
  exec_note text,
  created_at timestamptz NOT NULL DEFAULT now(),
  CHECK (end_date >= start_date)
);

ALTER TABLE public.staff_requests ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS staff_requests_school_status_idx
  ON public.staff_requests (school_id, status);
CREATE INDEX IF NOT EXISTS staff_requests_requester_idx
  ON public.staff_requests (requester_id);

-- ---------------------------------------------------------------------------
-- create_staff_request
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.create_staff_request(
  p_token text,
  p_request_type text,
  p_subject text,
  p_start_date date,
  p_end_date date DEFAULT NULL,
  p_detail text DEFAULT NULL,
  p_location text DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_end date;
  v_dept record;
  v_status text;
  v_id uuid;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  IF v_actor.role NOT IN ('teacher', 'school_admin') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  IF p_request_type NOT IN ('meet_request', 'meeting_request', 'official_duty') THEN
    RAISE EXCEPTION 'invalid_request_type';
  END IF;

  IF coalesce(trim(p_subject), '') = '' THEN
    RAISE EXCEPTION 'subject_required';
  END IF;

  v_end := coalesce(p_end_date, p_start_date);
  IF v_end < p_start_date THEN
    RAISE EXCEPTION 'invalid_date_range';
  END IF;

  -- Level-1 routing: the requester's own administrative ฝ่าย, if any.
  SELECT d.id, d.name INTO v_dept
    FROM public.department_members m
    JOIN public.departments d ON d.id = m.department_id
   WHERE m.user_id = v_actor.user_id
     AND d.school_id = v_actor.school_id
     AND d.kind = 'administrative'
   LIMIT 1;

  IF v_dept.id IS NULL THEN
    v_status := 'pending_executive';
  ELSIF EXISTS (
    SELECT 1 FROM public.department_members m
     WHERE m.department_id = v_dept.id AND m.user_id = v_actor.user_id AND m.is_head
  ) THEN
    -- The requester is the head of their own ฝ่าย: nobody else at level 1.
    v_status := 'pending_executive';
  ELSE
    v_status := 'pending_head';
  END IF;

  INSERT INTO public.staff_requests (
    school_id, requester_id, request_type, subject, detail,
    start_date, end_date, location, department_id, status
  ) VALUES (
    v_actor.school_id, v_actor.user_id, p_request_type, trim(p_subject),
    nullif(trim(coalesce(p_detail, '')), ''), p_start_date, v_end,
    nullif(trim(coalesce(p_location, '')), ''), v_dept.id, v_status
  )
  RETURNING id INTO v_id;

  IF v_status = 'pending_head' THEN
    INSERT INTO public.notifications (user_id, type, title, body, payload)
    SELECT m.user_id, 'staff_request_pending_head', 'มีคำขอรออนุมัติ',
           trim(p_subject),
           jsonb_build_object('request_id', v_id, 'request_type', p_request_type)
      FROM public.department_members m
     WHERE m.department_id = v_dept.id AND m.is_head;
  ELSE
    INSERT INTO public.notifications (user_id, type, title, body, payload)
    SELECT u.id, 'staff_request_pending_executive', 'มีคำขอรออนุมัติ',
           trim(p_subject),
           jsonb_build_object('request_id', v_id, 'request_type', p_request_type)
      FROM public.users u
      JOIN public.user_roles ur ON ur.user_id = u.id AND ur.school_id = u.school_id
     WHERE u.school_id = v_actor.school_id AND ur.role = 'executive';
  END IF;

  INSERT INTO public.audit_logs
    (school_id, user_id, acted_role, action, entity_type, entity_id, details)
  VALUES (
    v_actor.school_id, v_actor.user_id, v_actor.role,
    'staff_request.create', 'staff_requests', v_id::text,
    jsonb_build_object('type', p_request_type, 'initial_status', v_status)
  );

  RETURN v_id;
END;
$$;

-- ---------------------------------------------------------------------------
-- review_staff_request — decides whichever stage is currently pending
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.review_staff_request(
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
  v_req public.staff_requests;
  v_day date;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  SELECT * INTO v_req FROM public.staff_requests WHERE id = p_request_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'request_not_found';
  END IF;

  IF v_actor.role <> 'super_admin'
     AND v_req.school_id IS DISTINCT FROM v_actor.school_id THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  IF v_req.status NOT IN ('pending_head', 'pending_executive') THEN
    RAISE EXCEPTION 'already_reviewed';
  END IF;

  IF v_req.status = 'pending_head' THEN
    IF v_actor.role NOT IN ('school_admin', 'super_admin') AND NOT EXISTS (
      SELECT 1 FROM public.department_members m
       WHERE m.department_id = v_req.department_id
         AND m.user_id = v_actor.user_id
         AND m.is_head
    ) THEN
      RAISE EXCEPTION 'forbidden';
    END IF;

    UPDATE public.staff_requests
       SET head_decision = CASE WHEN p_approve THEN 'approved' ELSE 'rejected' END,
           head_by = v_actor.user_id,
           head_at = now(),
           head_note = nullif(trim(coalesce(p_note, '')), ''),
           status = CASE WHEN p_approve THEN 'pending_executive' ELSE 'rejected' END
     WHERE id = p_request_id;

    IF p_approve THEN
      INSERT INTO public.notifications (user_id, type, title, body, payload)
      SELECT u.id, 'staff_request_pending_executive', 'มีคำขอรออนุมัติ',
             v_req.subject,
             jsonb_build_object('request_id', p_request_id, 'request_type', v_req.request_type)
        FROM public.users u
        JOIN public.user_roles ur ON ur.user_id = u.id AND ur.school_id = u.school_id
       WHERE u.school_id = v_req.school_id AND ur.role = 'executive';
    ELSE
      INSERT INTO public.notifications (user_id, type, title, body, payload)
      VALUES (
        v_req.requester_id, 'staff_request_rejected', 'คำขอถูกปฏิเสธ',
        v_req.subject,
        jsonb_build_object('request_id', p_request_id, 'stage', 'head')
      );
    END IF;

  ELSE -- pending_executive
    IF v_actor.role NOT IN ('executive', 'school_admin', 'super_admin') THEN
      RAISE EXCEPTION 'forbidden';
    END IF;

    UPDATE public.staff_requests
       SET exec_decision = CASE WHEN p_approve THEN 'approved' ELSE 'rejected' END,
           exec_by = v_actor.user_id,
           exec_at = now(),
           exec_note = nullif(trim(coalesce(p_note, '')), ''),
           status = CASE WHEN p_approve THEN 'approved' ELSE 'rejected' END
     WHERE id = p_request_id;

    INSERT INTO public.notifications (user_id, type, title, body, payload)
    VALUES (
      v_req.requester_id,
      CASE WHEN p_approve THEN 'staff_request_approved' ELSE 'staff_request_rejected' END,
      CASE WHEN p_approve THEN 'คำขอได้รับการอนุมัติ' ELSE 'คำขอถูกปฏิเสธ' END,
      v_req.subject,
      jsonb_build_object('request_id', p_request_id, 'stage', 'executive')
    );

    -- The whole reason this table exists: an approved ไปราชการ must not
    -- leave the requester looking like they simply never checked in.
    IF p_approve AND v_req.request_type = 'official_duty' THEN
      v_day := v_req.start_date;
      WHILE v_day <= v_req.end_date LOOP
        INSERT INTO public.staff_attendance_records
          (school_id, user_id, work_date, status, source, note, recorded_by)
        VALUES (
          v_req.school_id, v_req.requester_id, v_day, 'official_duty', 'admin',
          'อนุมัติไปราชการ: ' || v_req.subject, v_actor.user_id
        )
        ON CONFLICT (user_id, work_date) DO UPDATE
          SET status = 'official_duty',
              source = 'admin',
              note = 'อนุมัติไปราชการ: ' || v_req.subject,
              recorded_by = v_actor.user_id,
              updated_at = now();
        v_day := v_day + 1;
      END LOOP;
    END IF;
  END IF;

  INSERT INTO public.audit_logs
    (school_id, user_id, acted_role, action, entity_type, entity_id, details)
  VALUES (
    v_req.school_id, v_actor.user_id, v_actor.role,
    'staff_request.review', 'staff_requests', p_request_id::text,
    jsonb_build_object('approved', p_approve, 'stage', v_req.status)
  );
END;
$$;

-- ---------------------------------------------------------------------------
-- cancel_staff_request — the requester withdraws their own, while pending
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.cancel_staff_request(
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
  v_req public.staff_requests;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  SELECT * INTO v_req FROM public.staff_requests WHERE id = p_request_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'request_not_found';
  END IF;

  -- An admin's override is scoped to their own school — a school_admin role
  -- check alone is not a school_id check, and this table has no policy to
  -- catch the gap if the function forgets it.
  IF v_actor.role <> 'super_admin'
     AND v_req.school_id IS DISTINCT FROM v_actor.school_id THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  IF v_req.requester_id <> v_actor.user_id
     AND v_actor.role NOT IN ('school_admin', 'super_admin') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  IF v_req.status NOT IN ('pending_head', 'pending_executive') THEN
    RAISE EXCEPTION 'already_reviewed';
  END IF;

  UPDATE public.staff_requests SET status = 'cancelled' WHERE id = p_request_id;
END;
$$;

-- ---------------------------------------------------------------------------
-- list_staff_requests
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.list_staff_requests(
  p_token text,
  p_status text DEFAULT NULL,
  p_request_type text DEFAULT NULL,
  -- Only what this caller can act on right now: their own department's
  -- pending_head queue, or the school's pending_executive queue.
  p_pending_for_me boolean DEFAULT false
)
RETURNS TABLE (
  request_id uuid,
  requester_id uuid,
  requester_name text,
  request_type text,
  subject varchar,
  detail text,
  start_date date,
  end_date date,
  location varchar,
  status text,
  department_id uuid,
  department_name varchar,
  head_decision text,
  head_by_name text,
  head_at timestamptz,
  head_note text,
  exec_decision text,
  exec_by_name text,
  exec_at timestamptz,
  exec_note text,
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
    r.id, r.requester_id, trim(u.first_name || ' ' || u.last_name),
    r.request_type::text, r.subject, r.detail, r.start_date, r.end_date,
    r.location, r.status::text, r.department_id, d.name,
    r.head_decision::text,
    (SELECT trim(hb.first_name || ' ' || hb.last_name) FROM public.users hb WHERE hb.id = r.head_by),
    r.head_at, r.head_note,
    r.exec_decision::text,
    (SELECT trim(eb.first_name || ' ' || eb.last_name) FROM public.users eb WHERE eb.id = r.exec_by),
    r.exec_at, r.exec_note, r.created_at
  FROM public.staff_requests r
  JOIN public.users u ON u.id = r.requester_id
  LEFT JOIN public.departments d ON d.id = r.department_id
  WHERE r.school_id = v_actor.school_id
    AND (p_status IS NULL OR r.status = p_status)
    AND (p_request_type IS NULL OR r.request_type = p_request_type)
    AND (
      NOT p_pending_for_me
      OR (r.status = 'pending_head' AND EXISTS (
            SELECT 1 FROM public.department_members m
             WHERE m.department_id = r.department_id
               AND m.user_id = v_actor.user_id AND m.is_head
          ))
      OR (r.status = 'pending_executive'
          AND v_actor.role IN ('executive', 'school_admin', 'super_admin'))
    )
    AND (
      p_pending_for_me
      OR v_actor.role IN ('school_admin', 'executive', 'super_admin')
      OR r.requester_id = v_actor.user_id
      OR EXISTS (
           SELECT 1 FROM public.department_members m
            WHERE m.department_id = r.department_id
              AND m.user_id = v_actor.user_id AND m.is_head
         )
    )
  ORDER BY r.created_at DESC;
END;
$$;

-- ---------------------------------------------------------------------------
-- Grants
-- ---------------------------------------------------------------------------

REVOKE ALL ON FUNCTION public.create_staff_request FROM PUBLIC, service_role;
GRANT EXECUTE ON FUNCTION public.create_staff_request TO anon, authenticated;

REVOKE ALL ON FUNCTION public.review_staff_request FROM PUBLIC, service_role;
GRANT EXECUTE ON FUNCTION public.review_staff_request TO anon, authenticated;

REVOKE ALL ON FUNCTION public.cancel_staff_request FROM PUBLIC, service_role;
GRANT EXECUTE ON FUNCTION public.cancel_staff_request TO anon, authenticated;

REVOKE ALL ON FUNCTION public.list_staff_requests FROM PUBLIC, service_role;
GRANT EXECUTE ON FUNCTION public.list_staff_requests TO anon, authenticated;
