-- Migration: 20260907040000_meeting_records_and_notices.sql
-- Description: สิ่งที่ทำให้บันทึกการประชุมเป็นเอกสารราชการได้จริง —
-- เลขที่การประชุม, ผู้เข้าร่วมจากภายนอก, การเช็คชื่อผู้มาประชุมจริง
-- และการแจ้งเตือนที่แยกเป็นหมวด
--
-- Settled with the project owner on 2026-09-07, after 20260907030000:
--
--   * A Thai school's minutes are headed "ครั้งที่ N/พ.ศ." — so meetings carry
--     a number, allocated per school per Buddhist-era year. A one-on-one
--     summons does not take one: it is not a numbered meeting of the school,
--     and letting it consume numbers would put gaps in the official series.
--
--   * วิทยากร / กรรมการสถานศึกษา / ศึกษานิเทศก์ have no account here and
--     should not be given one. They are recorded as names with an
--     organisation so they appear in the document, and nothing more —
--     no login, no invitation, no response.
--
--   * Accepting an invitation and turning up are different facts. Attendance
--     is taken once, by one person, in one call, and until that happens the
--     answer is "ยังไม่ได้เช็คชื่อ" — never "มาครบทุกคน".
--
--   * Being invited is useless if nobody is told. Meeting events write to the
--     existing `notifications` table, and notifications gain a category so the
--     bell can group them instead of showing one flat list.
--
-- Everything here is additive.

-- ---------------------------------------------------------------------------
-- เลขที่การประชุม
-- ---------------------------------------------------------------------------

ALTER TABLE public.meetings
  ADD COLUMN IF NOT EXISTS meeting_no int,
  -- Buddhist era, the way the document is headed.
  ADD COLUMN IF NOT EXISTS meeting_year int,
  ADD COLUMN IF NOT EXISTS attendance_taken_at timestamptz,
  ADD COLUMN IF NOT EXISTS attendance_taken_by uuid REFERENCES public.users(id);

CREATE UNIQUE INDEX IF NOT EXISTS meetings_number_per_year_idx
  ON public.meetings (school_id, meeting_year, meeting_no)
  WHERE meeting_no IS NOT NULL;

-- Allocated inside the transaction that creates the meeting, so two people
-- creating a meeting at once cannot both take the same number.
CREATE OR REPLACE FUNCTION public._next_meeting_no(
  p_school_id uuid,
  p_year int
)
RETURNS int
LANGUAGE plpgsql
SET search_path = public, extensions
AS $$
DECLARE
  v_next int;
BEGIN
  -- The advisory lock is per school+year, so unrelated schools do not queue
  -- behind each other.
  PERFORM pg_advisory_xact_lock(hashtext(p_school_id::text || ':' || p_year));

  SELECT coalesce(max(meeting_no), 0) + 1 INTO v_next
    FROM public.meetings
   WHERE school_id = p_school_id AND meeting_year = p_year;

  RETURN v_next;
END;
$$;

-- ---------------------------------------------------------------------------
-- ผู้เข้าร่วมจากภายนอก
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.meeting_external_attendees (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  meeting_id uuid NOT NULL REFERENCES public.meetings(id) ON DELETE CASCADE,
  full_name varchar NOT NULL,
  -- ต้นสังกัด: สพม. / โรงเรียน... / บริษัท...
  organization varchar,
  position_title varchar,
  note text,
  -- NULL until attendance is taken. Not false: nobody has said they were
  -- absent, only that nobody has checked yet.
  attended boolean,
  added_by uuid NOT NULL REFERENCES public.users(id),
  added_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.meeting_external_attendees ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS meeting_external_meeting_idx
  ON public.meeting_external_attendees (meeting_id);

-- Same three-state rule for staff.
ALTER TABLE public.meeting_attendees
  ADD COLUMN IF NOT EXISTS attended boolean;

CREATE OR REPLACE FUNCTION public.add_meeting_external_attendee(
  p_token text,
  p_meeting_id uuid,
  p_full_name text,
  p_organization text DEFAULT NULL,
  p_position_title text DEFAULT NULL,
  p_note text DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_meeting public.meetings;
  v_id uuid;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  SELECT * INTO v_meeting FROM public.meetings WHERE id = p_meeting_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'meeting_not_found';
  END IF;

  IF v_meeting.school_id IS DISTINCT FROM v_actor.school_id
     OR (v_meeting.created_by <> v_actor.user_id
         AND v_actor.role NOT IN ('school_admin', 'super_admin')) THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  IF coalesce(trim(coalesce(p_full_name, '')), '') = '' THEN
    RAISE EXCEPTION 'name_required';
  END IF;

  INSERT INTO public.meeting_external_attendees
    (meeting_id, full_name, organization, position_title, note, added_by)
  VALUES (
    p_meeting_id, trim(p_full_name),
    nullif(trim(coalesce(p_organization, '')), ''),
    nullif(trim(coalesce(p_position_title, '')), ''),
    nullif(trim(coalesce(p_note, '')), ''),
    v_actor.user_id
  )
  RETURNING id INTO v_id;

  RETURN v_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.remove_meeting_external_attendee(
  p_token text,
  p_external_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_meeting public.meetings;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  SELECT m.* INTO v_meeting
    FROM public.meeting_external_attendees e
    JOIN public.meetings m ON m.id = e.meeting_id
   WHERE e.id = p_external_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'external_attendee_not_found';
  END IF;

  IF v_meeting.school_id IS DISTINCT FROM v_actor.school_id
     OR (v_meeting.created_by <> v_actor.user_id
         AND v_actor.role NOT IN ('school_admin', 'super_admin')) THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  DELETE FROM public.meeting_external_attendees WHERE id = p_external_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.list_meeting_external_attendees(
  p_token text,
  p_meeting_id uuid
)
RETURNS TABLE (
  external_id uuid,
  full_name varchar,
  organization varchar,
  position_title varchar,
  note text,
  attended boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_meeting public.meetings;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  SELECT * INTO v_meeting FROM public.meetings WHERE id = p_meeting_id;
  IF NOT FOUND OR NOT public._can_see_meeting(
       v_actor.user_id, v_actor.role::text, v_actor.school_id, v_meeting) THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  RETURN QUERY
  SELECT e.id, e.full_name, e.organization, e.position_title, e.note, e.attended
    FROM public.meeting_external_attendees e
   WHERE e.meeting_id = p_meeting_id
   ORDER BY e.added_at;
END;
$$;

-- ---------------------------------------------------------------------------
-- เช็คชื่อผู้มาประชุมจริง — one call, one person, once
-- ---------------------------------------------------------------------------

-- Everyone on the list is marked in a single call: those in the arrays are
-- present, everyone else on the meeting is absent. Taking attendance twice
-- simply overwrites, because a correction on the day is normal.
CREATE OR REPLACE FUNCTION public.set_meeting_attendance(
  p_token text,
  p_meeting_id uuid,
  p_present_user_ids uuid[] DEFAULT NULL,
  p_present_external_ids uuid[] DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_meeting public.meetings;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  SELECT * INTO v_meeting FROM public.meetings WHERE id = p_meeting_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'meeting_not_found';
  END IF;

  IF v_meeting.school_id IS DISTINCT FROM v_actor.school_id
     OR (v_meeting.created_by <> v_actor.user_id
         AND v_actor.role NOT IN ('school_admin', 'super_admin')) THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  UPDATE public.meeting_attendees a
     SET attended = (a.user_id = ANY (coalesce(p_present_user_ids, '{}'::uuid[])))
   WHERE a.meeting_id = p_meeting_id;

  UPDATE public.meeting_external_attendees e
     SET attended = (e.id = ANY (coalesce(p_present_external_ids, '{}'::uuid[])))
   WHERE e.meeting_id = p_meeting_id;

  UPDATE public.meetings
     SET attendance_taken_at = now(), attendance_taken_by = v_actor.user_id
   WHERE id = p_meeting_id;
END;
$$;

-- ---------------------------------------------------------------------------
-- แจ้งเตือน
-- ---------------------------------------------------------------------------

-- Groups the flat `notifications.type` into the headings a person actually
-- thinks in. Unknown types fall to 'other' rather than being hidden.
CREATE OR REPLACE FUNCTION public._notification_category(p_type text)
RETURNS text
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CASE
    WHEN p_type LIKE 'meeting%' THEN 'meeting'
    WHEN p_type LIKE 'staff_request%' THEN 'request'
    WHEN p_type IN ('incident_report', 'sos') THEN 'incident'
    WHEN p_type IN ('grade_confirmed', 'assignment_published') THEN 'learning'
    ELSE 'other'
  END;
$$;

CREATE OR REPLACE FUNCTION public.list_my_notification_categories(p_token text)
RETURNS TABLE (
  category text,
  total int,
  unread int,
  latest_at timestamptz
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

  RETURN QUERY
  SELECT
    public._notification_category(n.type::text),
    count(*)::int,
    count(*) FILTER (WHERE n.read_at IS NULL)::int,
    max(n.created_at)
  FROM public.notifications n
  WHERE n.user_id = v_actor.user_id
  GROUP BY 1
  ORDER BY max(n.created_at) DESC;
END;
$$;

CREATE OR REPLACE FUNCTION public.list_my_notifications_in_category(
  p_token text,
  p_category text DEFAULT NULL,
  p_limit int DEFAULT 50
)
RETURNS TABLE (
  id uuid,
  type varchar,
  category text,
  title varchar,
  body text,
  payload jsonb,
  created_at timestamptz,
  read_at timestamptz
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

  RETURN QUERY
  SELECT n.id, n.type, public._notification_category(n.type::text),
         n.title, n.body, n.payload, n.created_at, n.read_at
    FROM public.notifications n
   WHERE n.user_id = v_actor.user_id
     AND (p_category IS NULL
          OR public._notification_category(n.type::text) = p_category)
   ORDER BY n.created_at DESC
   LIMIT greatest(coalesce(p_limit, 50), 1);
END;
$$;

-- ---------------------------------------------------------------------------
-- ปฏิทินของบุคลากร — school events and the meetings this person may see
-- ---------------------------------------------------------------------------

-- `list_calendar_events` is the student/parent view and has no meetings in
-- it. Staff need one calendar that carries both, or a meeting is something
-- you only find by remembering to look for it.
CREATE OR REPLACE FUNCTION public.list_staff_calendar(
  p_token text,
  p_from date DEFAULT NULL,
  p_to date DEFAULT NULL
)
RETURNS TABLE (
  entry_id uuid,
  kind text,
  title varchar,
  detail text,
  location varchar,
  start_at timestamptz,
  end_at timestamptz,
  status text,
  my_response text
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
    m.id,
    CASE WHEN m.meeting_type = 'one_on_one' THEN 'summons' ELSE 'meeting' END,
    m.title,
    m.description,
    m.location,
    m.start_at,
    m.end_at,
    m.status::text,
    (SELECT a.response::text FROM public.meeting_attendees a
      WHERE a.meeting_id = m.id AND a.user_id = v_actor.user_id)
  FROM public.meetings m
  WHERE m.school_id = v_actor.school_id
    AND public._can_see_meeting(
          v_actor.user_id, v_actor.role::text, v_actor.school_id, m)
    AND (p_from IS NULL OR m.start_at >= p_from::timestamptz)
    AND (p_to IS NULL OR m.start_at < (p_to + 1)::timestamptz)

  UNION ALL

  SELECT
    e.id,
    'school_event',
    e.title,
    e.description,
    e.location,
    e.start_date::timestamptz,
    e.end_date::timestamptz,
    'scheduled',
    NULL
  FROM public.school_events e
  WHERE e.school_id = v_actor.school_id
    AND (p_from IS NULL OR e.start_date >= p_from)
    AND (p_to IS NULL OR e.start_date <= p_to)

  ORDER BY 6;
END;
$$;

-- ---------------------------------------------------------------------------
-- Wire the notices into the meeting flow
-- ---------------------------------------------------------------------------

-- Replaces the 20260907030000 version: same behaviour plus a meeting number
-- and an invitation notice for everyone but the organiser.
CREATE OR REPLACE FUNCTION public.create_meeting(
  p_token text,
  p_title text,
  p_meeting_type text,
  p_start_at timestamptz,
  p_end_at timestamptz DEFAULT NULL,
  p_location text DEFAULT NULL,
  p_description text DEFAULT NULL,
  p_visibility text DEFAULT 'attendees',
  p_minutes_expected boolean DEFAULT true,
  p_user_ids uuid[] DEFAULT NULL,
  p_department_ids uuid[] DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_id uuid;
  v_visibility text;
  v_attendees int;
  v_year int;
  v_no int;
  v_when text;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  IF v_actor.role NOT IN ('executive', 'school_admin', 'super_admin') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  IF coalesce(trim(p_title), '') = '' THEN
    RAISE EXCEPTION 'title_required';
  END IF;

  IF p_meeting_type NOT IN ('school_wide', 'group', 'one_on_one') THEN
    RAISE EXCEPTION 'invalid_meeting_type';
  END IF;

  IF p_end_at IS NOT NULL AND p_end_at <= p_start_at THEN
    RAISE EXCEPTION 'invalid_time_range';
  END IF;

  v_visibility := CASE
    WHEN p_meeting_type = 'one_on_one' THEN 'attendees'
    WHEN p_meeting_type = 'school_wide' THEN 'school'
    ELSE coalesce(p_visibility, 'attendees')
  END;

  IF v_visibility NOT IN ('school', 'attendees') THEN
    RAISE EXCEPTION 'invalid_visibility';
  END IF;

  -- A summons takes no number: it is not part of the school's numbered
  -- series, and giving it one would leave gaps in that series.
  IF p_meeting_type <> 'one_on_one' THEN
    v_year := extract(year FROM (p_start_at AT TIME ZONE 'Asia/Bangkok'))::int + 543;
    v_no := public._next_meeting_no(v_actor.school_id, v_year);
  END IF;

  INSERT INTO public.meetings (
    school_id, title, description, meeting_type, visibility, location,
    start_at, end_at, minutes_expected, created_by, meeting_no, meeting_year
  ) VALUES (
    v_actor.school_id, trim(p_title),
    nullif(trim(coalesce(p_description, '')), ''),
    p_meeting_type, v_visibility, nullif(trim(coalesce(p_location, '')), ''),
    p_start_at, p_end_at, coalesce(p_minutes_expected, true), v_actor.user_id,
    v_no, v_year
  )
  RETURNING id INTO v_id;

  INSERT INTO public.meeting_attendees (meeting_id, user_id, is_organizer, response)
  VALUES (v_id, v_actor.user_id, true, 'accepted');

  IF p_meeting_type = 'school_wide' THEN
    INSERT INTO public.meeting_attendees (meeting_id, user_id)
    SELECT v_id, u.id
      FROM public.users u
     WHERE u.school_id = v_actor.school_id
       AND u.id <> v_actor.user_id
       AND EXISTS (
         SELECT 1 FROM public.user_roles ur
          WHERE ur.user_id = u.id AND ur.school_id = u.school_id
            AND ur.role IN ('teacher', 'school_admin', 'executive')
       )
    ON CONFLICT DO NOTHING;
  END IF;

  IF p_department_ids IS NOT NULL THEN
    INSERT INTO public.meeting_attendees
      (meeting_id, user_id, source, source_department_id)
    SELECT v_id, m.user_id, 'department', m.department_id
      FROM public.department_members m
      JOIN public.departments d ON d.id = m.department_id
     WHERE d.school_id = v_actor.school_id
       AND m.department_id = ANY (p_department_ids)
       AND m.user_id <> v_actor.user_id
    ON CONFLICT DO NOTHING;
  END IF;

  IF p_user_ids IS NOT NULL THEN
    INSERT INTO public.meeting_attendees (meeting_id, user_id)
    SELECT v_id, u.id
      FROM public.users u
     WHERE u.id = ANY (p_user_ids)
       AND u.school_id = v_actor.school_id
       AND u.id <> v_actor.user_id
    ON CONFLICT DO NOTHING;
  END IF;

  SELECT count(*) INTO v_attendees
    FROM public.meeting_attendees WHERE meeting_id = v_id;

  IF p_meeting_type = 'one_on_one' AND v_attendees <> 2 THEN
    RAISE EXCEPTION 'one_on_one_needs_exactly_one_person';
  END IF;

  IF v_attendees < 2 THEN
    RAISE EXCEPTION 'attendees_required';
  END IF;

  v_when := to_char(p_start_at AT TIME ZONE 'Asia/Bangkok', 'DD/MM ')
            || to_char(p_start_at AT TIME ZONE 'Asia/Bangkok', 'HH24:MI') || ' น.';

  -- Being invited is not information until somebody is told.
  INSERT INTO public.notifications (user_id, type, title, body, payload)
  SELECT
    a.user_id,
    CASE WHEN p_meeting_type = 'one_on_one'
         THEN 'meeting_summons' ELSE 'meeting_invite' END,
    CASE WHEN p_meeting_type = 'one_on_one'
         THEN 'ผู้บริหารขอพบ' ELSE 'เชิญเข้าร่วมประชุม' END,
    trim(p_title) || ' • ' || v_when,
    jsonb_build_object('meeting_id', v_id, 'meeting_type', p_meeting_type)
  FROM public.meeting_attendees a
  WHERE a.meeting_id = v_id AND a.user_id <> v_actor.user_id;

  INSERT INTO public.audit_logs
    (school_id, user_id, acted_role, action, entity_type, entity_id, details)
  VALUES (
    v_actor.school_id, v_actor.user_id, v_actor.role,
    'meeting.create', 'meetings', v_id::text,
    jsonb_build_object(
      'type', p_meeting_type, 'attendees', v_attendees,
      'meeting_no', v_no, 'meeting_year', v_year
    )
  );

  RETURN v_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.cancel_meeting(
  p_token text,
  p_meeting_id uuid,
  p_reason text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_meeting public.meetings;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  SELECT * INTO v_meeting FROM public.meetings WHERE id = p_meeting_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'meeting_not_found';
  END IF;

  IF v_meeting.school_id IS DISTINCT FROM v_actor.school_id
     OR (v_meeting.created_by <> v_actor.user_id
         AND v_actor.role NOT IN ('school_admin', 'super_admin')) THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  IF coalesce(trim(coalesce(p_reason, '')), '') = '' THEN
    RAISE EXCEPTION 'reason_required';
  END IF;

  UPDATE public.meetings
     SET status = 'cancelled', cancel_reason = trim(p_reason)
   WHERE id = p_meeting_id;

  -- People who cleared their timetable for it must be told it is off.
  INSERT INTO public.notifications (user_id, type, title, body, payload)
  SELECT a.user_id, 'meeting_cancelled', 'ยกเลิกการประชุม',
         v_meeting.title || ' • ' || trim(p_reason),
         jsonb_build_object('meeting_id', p_meeting_id)
    FROM public.meeting_attendees a
   WHERE a.meeting_id = p_meeting_id AND a.user_id <> v_actor.user_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.finalize_meeting_minutes(
  p_token text,
  p_meeting_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_meeting public.meetings;
  v_minutes public.meeting_minutes;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  SELECT * INTO v_meeting FROM public.meetings WHERE id = p_meeting_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'meeting_not_found';
  END IF;

  IF v_meeting.school_id IS DISTINCT FROM v_actor.school_id
     OR (v_meeting.created_by <> v_actor.user_id
         AND v_actor.role NOT IN ('school_admin', 'super_admin')) THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  SELECT * INTO v_minutes FROM public.meeting_minutes
   WHERE meeting_id = p_meeting_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'minutes_not_found';
  END IF;
  IF v_minutes.status = 'final' THEN
    RAISE EXCEPTION 'minutes_already_final';
  END IF;

  UPDATE public.meeting_minutes
     SET status = 'final', finalized_at = now(), updated_at = now()
   WHERE meeting_id = p_meeting_id;

  -- The subject of a summons is told the moment the record about them is
  -- fixed, which is what makes the right of reply usable.
  INSERT INTO public.notifications (user_id, type, title, body, payload)
  SELECT a.user_id, 'meeting_minutes_final',
         CASE WHEN v_meeting.meeting_type = 'one_on_one'
              THEN 'บันทึกการเข้าพบถูกปิดแล้ว'
              ELSE 'บันทึกการประชุมถูกปิดแล้ว' END,
         v_meeting.title,
         jsonb_build_object('meeting_id', p_meeting_id)
    FROM public.meeting_attendees a
   WHERE a.meeting_id = p_meeting_id AND a.user_id <> v_actor.user_id;

  INSERT INTO public.audit_logs
    (school_id, user_id, acted_role, action, entity_type, entity_id, details)
  VALUES (
    v_meeting.school_id, v_actor.user_id, v_actor.role,
    'meeting_minutes.finalize', 'meeting_minutes', p_meeting_id::text,
    jsonb_build_object('meeting_type', v_meeting.meeting_type)
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.create_meeting_resolution(
  p_token text,
  p_meeting_id uuid,
  p_body text,
  p_assignee_user_id uuid DEFAULT NULL,
  p_due_date date DEFAULT NULL,
  p_agenda_item_id uuid DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_meeting public.meetings;
  v_id uuid;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  SELECT * INTO v_meeting FROM public.meetings WHERE id = p_meeting_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'meeting_not_found';
  END IF;

  IF v_meeting.school_id IS DISTINCT FROM v_actor.school_id
     OR (v_meeting.created_by <> v_actor.user_id
         AND v_actor.role NOT IN ('school_admin', 'super_admin')) THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  IF coalesce(trim(coalesce(p_body, '')), '') = '' THEN
    RAISE EXCEPTION 'body_required';
  END IF;

  IF p_assignee_user_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.meeting_attendees a
     WHERE a.meeting_id = p_meeting_id AND a.user_id = p_assignee_user_id
  ) THEN
    RAISE EXCEPTION 'assignee_not_an_attendee';
  END IF;

  INSERT INTO public.meeting_resolutions
    (meeting_id, agenda_item_id, body, assignee_user_id, due_date, created_by)
  VALUES (
    p_meeting_id, p_agenda_item_id, trim(p_body),
    p_assignee_user_id, p_due_date, v_actor.user_id
  )
  RETURNING id INTO v_id;

  -- A resolution nobody was told about is a resolution nobody will act on.
  IF p_assignee_user_id IS NOT NULL AND p_assignee_user_id <> v_actor.user_id THEN
    INSERT INTO public.notifications (user_id, type, title, body, payload)
    VALUES (
      p_assignee_user_id, 'meeting_resolution_assigned',
      'ได้รับมอบหมายจากที่ประชุม',
      trim(p_body)
        || CASE WHEN p_due_date IS NULL THEN ''
                ELSE ' • ภายใน ' || to_char(p_due_date, 'DD/MM/YYYY') END,
      jsonb_build_object('meeting_id', p_meeting_id, 'resolution_id', v_id)
    );
  END IF;

  RETURN v_id;
END;
$$;

-- ---------------------------------------------------------------------------
-- Grants
-- ---------------------------------------------------------------------------

REVOKE ALL ON FUNCTION public._next_meeting_no FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public._notification_category FROM PUBLIC, anon, authenticated, service_role;

REVOKE ALL ON FUNCTION public.add_meeting_external_attendee FROM PUBLIC, service_role;
GRANT EXECUTE ON FUNCTION public.add_meeting_external_attendee TO anon, authenticated;

REVOKE ALL ON FUNCTION public.remove_meeting_external_attendee FROM PUBLIC, service_role;
GRANT EXECUTE ON FUNCTION public.remove_meeting_external_attendee TO anon, authenticated;

REVOKE ALL ON FUNCTION public.list_meeting_external_attendees FROM PUBLIC, service_role;
GRANT EXECUTE ON FUNCTION public.list_meeting_external_attendees TO anon, authenticated;

REVOKE ALL ON FUNCTION public.set_meeting_attendance FROM PUBLIC, service_role;
GRANT EXECUTE ON FUNCTION public.set_meeting_attendance TO anon, authenticated;

REVOKE ALL ON FUNCTION public.list_my_notification_categories FROM PUBLIC, service_role;
GRANT EXECUTE ON FUNCTION public.list_my_notification_categories TO anon, authenticated;

REVOKE ALL ON FUNCTION public.list_my_notifications_in_category FROM PUBLIC, service_role;
GRANT EXECUTE ON FUNCTION public.list_my_notifications_in_category TO anon, authenticated;

REVOKE ALL ON FUNCTION public.list_staff_calendar FROM PUBLIC, service_role;
GRANT EXECUTE ON FUNCTION public.list_staff_calendar TO anon, authenticated;
