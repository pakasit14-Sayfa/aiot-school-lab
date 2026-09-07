-- Migration: 20260907030000_meetings.sql
-- Description: ระบบประชุม — meetings, วาระ, ผู้เข้าร่วม, บันทึกการประชุม, มติ
-- และไฟล์แนบ รวมถึงการเรียกพบครูเป็นรายบุคคล
--
-- Why this exists: `director_meetings_page` (2,215 lines) offered "ประชุมครู
-- ทั้งหมด", "เลือกผู้เข้าร่วม", "ขอพบรายบุคคล" and a queue of "คำขอเข้าพบ
-- ผู้อำนวยการ" — every button ending in a snackbar saying the appointment had
-- been created. The schema had no meetings table of any kind; `school_events`
-- has no start time, no attendee list and no accept/decline.
--
-- Design notes, all settled with the project owner on 2026-09-07:
--
--   * A one-on-one summons is not listed to anyone but its two parties (and
--     school_admin, who administers the system). Group meetings can be
--     school-wide or attendee-only.
--
--   * A teacher summoned by the director cannot decline; they may accept or
--     ask to postpone with a reason. Declining is a group-meeting response.
--
--   * Minutes are draft → final. A finalised minute can never be edited: a
--     correction is an appended addendum carrying its own author and time, so
--     the question "what did it say when the teacher read it" is always
--     answerable. This is why there is no update path, not an oversight.
--
--   * The person a one-on-one is about always sees its minutes, and may append
--     their own statement, which nobody — the director included — can edit or
--     delete. That right is enforced here, not by hiding a button.
--
--   * A meeting that deliberately needs no minutes says so
--     (`minutes_expected = false`). "ไม่ต้องมีบันทึก" and "ยังไม่ได้บันทึก"
--     are different facts and must not render the same.
--
--   * Reads of a one-on-one's minutes are written to `audit_logs`. Group
--     minutes are not: they are not about one person.
--
-- Everything here is additive. No existing table or RPC is modified.

INSERT INTO storage.buckets (id, name, public)
VALUES ('meeting-files', 'meeting-files', false)
ON CONFLICT (id) DO UPDATE SET public = false;

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.meetings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id uuid NOT NULL REFERENCES public.schools(id),
  title varchar NOT NULL,
  description text,
  -- school_wide = ประชุมทั้งคณะ · group = เลือกผู้เข้าร่วม ·
  -- one_on_one   = เรียกพบรายบุคคล
  meeting_type varchar NOT NULL
    CHECK (meeting_type IN ('school_wide', 'group', 'one_on_one')),
  -- 'school' = staff can see it exists; 'attendees' = only those invited.
  -- Forced to 'attendees' for one_on_one by create_meeting.
  visibility varchar NOT NULL DEFAULT 'attendees'
    CHECK (visibility IN ('school', 'attendees')),
  location varchar,
  start_at timestamptz NOT NULL,
  end_at timestamptz,
  status varchar NOT NULL DEFAULT 'scheduled'
    CHECK (status IN ('scheduled', 'completed', 'cancelled')),
  -- False when the school decided this meeting needs no record at all.
  minutes_expected boolean NOT NULL DEFAULT true,
  cancel_reason text,
  created_by uuid NOT NULL REFERENCES public.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  CHECK (end_at IS NULL OR end_at > start_at)
);

ALTER TABLE public.meetings ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS meetings_school_start_idx
  ON public.meetings (school_id, start_at DESC);

CREATE TABLE IF NOT EXISTS public.meeting_attendees (
  meeting_id uuid NOT NULL REFERENCES public.meetings(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  -- How this person came to be invited. A department invite is expanded to
  -- real people when the meeting is created and never re-expanded, so moving
  -- someone between กลุ่มสาระ later does not rewrite who was invited.
  source varchar NOT NULL DEFAULT 'individual'
    CHECK (source IN ('individual', 'department')),
  source_department_id uuid REFERENCES public.departments(id) ON DELETE SET NULL,
  is_organizer boolean NOT NULL DEFAULT false,
  -- postpone_requested = ขอเลื่อน, the only refusal a summons allows.
  response varchar NOT NULL DEFAULT 'pending'
    CHECK (response IN ('pending', 'accepted', 'declined', 'postpone_requested')),
  response_note text,
  responded_at timestamptz,
  PRIMARY KEY (meeting_id, user_id)
);

ALTER TABLE public.meeting_attendees ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS meeting_attendees_user_idx
  ON public.meeting_attendees (user_id);

CREATE TABLE IF NOT EXISTS public.meeting_agenda_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  meeting_id uuid NOT NULL REFERENCES public.meetings(id) ON DELETE CASCADE,
  sort_order int NOT NULL DEFAULT 0,
  title varchar NOT NULL,
  detail text,
  presenter_user_id uuid REFERENCES public.users(id) ON DELETE SET NULL
);

ALTER TABLE public.meeting_agenda_items ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS meeting_agenda_meeting_idx
  ON public.meeting_agenda_items (meeting_id, sort_order);

-- One record per meeting. `final` is terminal: there is deliberately no RPC
-- that updates `body` after finalisation.
CREATE TABLE IF NOT EXISTS public.meeting_minutes (
  meeting_id uuid PRIMARY KEY REFERENCES public.meetings(id) ON DELETE CASCADE,
  body text NOT NULL,
  status varchar NOT NULL DEFAULT 'draft'
    CHECK (status IN ('draft', 'final')),
  recorded_by uuid NOT NULL REFERENCES public.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  finalized_at timestamptz,
  -- Cancelled, never deleted: the text stays readable with a reason attached.
  cancelled_at timestamptz,
  cancelled_by uuid REFERENCES public.users(id),
  cancel_reason text,
  CHECK (status <> 'final' OR finalized_at IS NOT NULL)
);

ALTER TABLE public.meeting_minutes ENABLE ROW LEVEL SECURITY;

-- Append-only. No update or delete RPC exists for this table, which is what
-- makes a correction visible as a correction.
CREATE TABLE IF NOT EXISTS public.meeting_minute_addenda (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  meeting_id uuid NOT NULL REFERENCES public.meetings(id) ON DELETE CASCADE,
  body text NOT NULL,
  -- recorder = ผู้บันทึกเพิ่มเติม · subject = คำชี้แจงของผู้ถูกเรียกพบ
  author_kind varchar NOT NULL CHECK (author_kind IN ('recorder', 'subject')),
  author_id uuid NOT NULL REFERENCES public.users(id),
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.meeting_minute_addenda ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS meeting_addenda_meeting_idx
  ON public.meeting_minute_addenda (meeting_id, created_at);

-- มติที่ประชุม: what was decided, who owns it, when it is due.
CREATE TABLE IF NOT EXISTS public.meeting_resolutions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  meeting_id uuid NOT NULL REFERENCES public.meetings(id) ON DELETE CASCADE,
  agenda_item_id uuid REFERENCES public.meeting_agenda_items(id) ON DELETE SET NULL,
  body text NOT NULL,
  assignee_user_id uuid REFERENCES public.users(id) ON DELETE SET NULL,
  due_date date,
  status varchar NOT NULL DEFAULT 'open'
    CHECK (status IN ('open', 'done', 'cancelled')),
  created_by uuid NOT NULL REFERENCES public.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  completed_at timestamptz
);

ALTER TABLE public.meeting_resolutions ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS meeting_resolutions_meeting_idx
  ON public.meeting_resolutions (meeting_id);
CREATE INDEX IF NOT EXISTS meeting_resolutions_assignee_idx
  ON public.meeting_resolutions (assignee_user_id, status);

CREATE TABLE IF NOT EXISTS public.meeting_attachments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  meeting_id uuid NOT NULL REFERENCES public.meetings(id) ON DELETE CASCADE,
  agenda_item_id uuid REFERENCES public.meeting_agenda_items(id) ON DELETE SET NULL,
  storage_path text NOT NULL UNIQUE,
  file_name varchar NOT NULL,
  file_type varchar NOT NULL,
  size_bytes bigint NOT NULL CHECK (size_bytes >= 0),
  uploaded_by uuid NOT NULL REFERENCES public.users(id),
  uploaded_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.meeting_attachments ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS meeting_attachments_meeting_idx
  ON public.meeting_attachments (meeting_id);

-- ---------------------------------------------------------------------------
-- Access helper
-- ---------------------------------------------------------------------------

-- Can this actor see this meeting at all?
--
-- executive/school_admin/super_admin see everything in their school — the
-- owner's decision on 2026-09-07 was that school_admin sees one-on-ones too,
-- since they administer the system. Everyone else sees a meeting they are
-- invited to, or a school-wide one.
CREATE OR REPLACE FUNCTION public._can_see_meeting(
  p_user_id uuid,
  p_role text,
  p_school_id uuid,
  p_meeting public.meetings
)
RETURNS boolean
LANGUAGE sql
STABLE
SET search_path = public, extensions
AS $$
  SELECT p_meeting.school_id = p_school_id
     AND (
       p_role IN ('executive', 'school_admin', 'super_admin')
       OR p_meeting.visibility = 'school'
       OR EXISTS (
         SELECT 1 FROM public.meeting_attendees a
          WHERE a.meeting_id = p_meeting.id AND a.user_id = p_user_id
       )
     );
$$;

-- ---------------------------------------------------------------------------
-- Create / change a meeting
-- ---------------------------------------------------------------------------

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

  -- A summons is never school-visible, whatever the caller asked for.
  v_visibility := CASE
    WHEN p_meeting_type = 'one_on_one' THEN 'attendees'
    WHEN p_meeting_type = 'school_wide' THEN 'school'
    ELSE coalesce(p_visibility, 'attendees')
  END;

  IF v_visibility NOT IN ('school', 'attendees') THEN
    RAISE EXCEPTION 'invalid_visibility';
  END IF;

  INSERT INTO public.meetings (
    school_id, title, description, meeting_type, visibility, location,
    start_at, end_at, minutes_expected, created_by
  ) VALUES (
    v_actor.school_id, trim(p_title),
    nullif(trim(coalesce(p_description, '')), ''),
    p_meeting_type, v_visibility, nullif(trim(coalesce(p_location, '')), ''),
    p_start_at, p_end_at, coalesce(p_minutes_expected, true), v_actor.user_id
  )
  RETURNING id INTO v_id;

  -- The organiser attends their own meeting.
  INSERT INTO public.meeting_attendees (meeting_id, user_id, is_organizer, response)
  VALUES (v_id, v_actor.user_id, true, 'accepted');

  IF p_meeting_type = 'school_wide' THEN
    -- Expanded now, to the staff who exist now.
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

  -- A summons is exactly the director and one other person.
  IF p_meeting_type = 'one_on_one' AND v_attendees <> 2 THEN
    RAISE EXCEPTION 'one_on_one_needs_exactly_one_person';
  END IF;

  IF v_attendees < 2 THEN
    RAISE EXCEPTION 'attendees_required';
  END IF;

  INSERT INTO public.audit_logs
    (school_id, user_id, acted_role, action, entity_type, entity_id, details)
  VALUES (
    v_actor.school_id, v_actor.user_id, v_actor.role,
    'meeting.create', 'meetings', v_id::text,
    jsonb_build_object('type', p_meeting_type, 'attendees', v_attendees)
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
END;
$$;

CREATE OR REPLACE FUNCTION public.complete_meeting(
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

  UPDATE public.meetings SET status = 'completed' WHERE id = p_meeting_id;
END;
$$;

-- ---------------------------------------------------------------------------
-- Responding
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.respond_to_meeting(
  p_token text,
  p_meeting_id uuid,
  p_response text,
  p_note text DEFAULT NULL
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

  IF NOT EXISTS (
    SELECT 1 FROM public.meeting_attendees a
     WHERE a.meeting_id = p_meeting_id AND a.user_id = v_actor.user_id
  ) THEN
    RAISE EXCEPTION 'not_an_attendee';
  END IF;

  IF p_response NOT IN ('accepted', 'declined', 'postpone_requested') THEN
    RAISE EXCEPTION 'invalid_response';
  END IF;

  -- Being summoned by the director is not an invitation to decline. Asking to
  -- postpone, with a reason, is the refusal that exists.
  IF v_meeting.meeting_type = 'one_on_one' AND p_response = 'declined' THEN
    RAISE EXCEPTION 'cannot_decline_summons';
  END IF;

  IF p_response = 'postpone_requested'
     AND coalesce(trim(coalesce(p_note, '')), '') = '' THEN
    RAISE EXCEPTION 'reason_required';
  END IF;

  UPDATE public.meeting_attendees
     SET response = p_response,
         response_note = nullif(trim(coalesce(p_note, '')), ''),
         responded_at = now()
   WHERE meeting_id = p_meeting_id AND user_id = v_actor.user_id;
END;
$$;

-- ---------------------------------------------------------------------------
-- Agenda
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.set_meeting_agenda_item(
  p_token text,
  p_meeting_id uuid,
  p_title text,
  p_sort_order int DEFAULT 0,
  p_detail text DEFAULT NULL,
  p_presenter_user_id uuid DEFAULT NULL,
  p_item_id uuid DEFAULT NULL
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

  IF coalesce(trim(p_title), '') = '' THEN
    RAISE EXCEPTION 'title_required';
  END IF;

  IF p_item_id IS NULL THEN
    INSERT INTO public.meeting_agenda_items
      (meeting_id, sort_order, title, detail, presenter_user_id)
    VALUES (
      p_meeting_id, p_sort_order, trim(p_title),
      nullif(trim(coalesce(p_detail, '')), ''), p_presenter_user_id
    )
    RETURNING id INTO v_id;
  ELSE
    UPDATE public.meeting_agenda_items
       SET title = trim(p_title),
           sort_order = p_sort_order,
           detail = nullif(trim(coalesce(p_detail, '')), ''),
           presenter_user_id = p_presenter_user_id
     WHERE id = p_item_id AND meeting_id = p_meeting_id
    RETURNING id INTO v_id;
    IF v_id IS NULL THEN
      RAISE EXCEPTION 'agenda_item_not_found';
    END IF;
  END IF;

  RETURN v_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.delete_meeting_agenda_item(
  p_token text,
  p_item_id uuid
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
    FROM public.meeting_agenda_items i
    JOIN public.meetings m ON m.id = i.meeting_id
   WHERE i.id = p_item_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'agenda_item_not_found';
  END IF;

  IF v_meeting.school_id IS DISTINCT FROM v_actor.school_id
     OR (v_meeting.created_by <> v_actor.user_id
         AND v_actor.role NOT IN ('school_admin', 'super_admin')) THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  DELETE FROM public.meeting_agenda_items WHERE id = p_item_id;
END;
$$;

-- ---------------------------------------------------------------------------
-- Minutes: draft → final → addenda only
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.save_meeting_minutes_draft(
  p_token text,
  p_meeting_id uuid,
  p_body text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_meeting public.meetings;
  v_existing public.meeting_minutes;
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

  -- A meeting the school decided needs no record does not get one by
  -- accident; the intent has to be changed first.
  IF NOT v_meeting.minutes_expected THEN
    RAISE EXCEPTION 'minutes_not_expected';
  END IF;

  IF coalesce(trim(coalesce(p_body, '')), '') = '' THEN
    RAISE EXCEPTION 'body_required';
  END IF;

  SELECT * INTO v_existing FROM public.meeting_minutes
   WHERE meeting_id = p_meeting_id;

  IF FOUND AND v_existing.status = 'final' THEN
    -- The whole point of the design: after finalisation the text is fixed and
    -- a correction must be an addendum that says who changed what, when.
    RAISE EXCEPTION 'minutes_already_final';
  END IF;

  INSERT INTO public.meeting_minutes (meeting_id, body, recorded_by)
  VALUES (p_meeting_id, p_body, v_actor.user_id)
  ON CONFLICT (meeting_id) DO UPDATE
    SET body = excluded.body, updated_at = now();
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

  INSERT INTO public.audit_logs
    (school_id, user_id, acted_role, action, entity_type, entity_id, details)
  VALUES (
    v_meeting.school_id, v_actor.user_id, v_actor.role,
    'meeting_minutes.finalize', 'meeting_minutes', p_meeting_id::text,
    jsonb_build_object('meeting_type', v_meeting.meeting_type)
  );
END;
$$;

-- The only way to change anything after finalisation. `subject` addenda are
-- the summoned person's own statement; nothing can edit or remove them,
-- because no RPC to do so exists.
CREATE OR REPLACE FUNCTION public.add_meeting_minute_addendum(
  p_token text,
  p_meeting_id uuid,
  p_body text
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_meeting public.meetings;
  v_minutes public.meeting_minutes;
  v_kind text;
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

  SELECT * INTO v_minutes FROM public.meeting_minutes
   WHERE meeting_id = p_meeting_id;
  IF NOT FOUND OR v_minutes.status <> 'final' THEN
    RAISE EXCEPTION 'minutes_not_final';
  END IF;

  IF coalesce(trim(coalesce(p_body, '')), '') = '' THEN
    RAISE EXCEPTION 'body_required';
  END IF;

  IF v_meeting.created_by = v_actor.user_id
     OR v_actor.role IN ('school_admin', 'super_admin') THEN
    v_kind := 'recorder';
  ELSIF EXISTS (
    SELECT 1 FROM public.meeting_attendees a
     WHERE a.meeting_id = p_meeting_id AND a.user_id = v_actor.user_id
  ) THEN
    v_kind := 'subject';
  ELSE
    RAISE EXCEPTION 'forbidden';
  END IF;

  INSERT INTO public.meeting_minute_addenda
    (meeting_id, body, author_kind, author_id)
  VALUES (p_meeting_id, p_body, v_kind, v_actor.user_id)
  RETURNING id INTO v_id;

  RETURN v_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.cancel_meeting_minutes(
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

  -- Only the system's administrator may void a record, and even then the text
  -- stays readable with the reason attached.
  IF v_actor.role NOT IN ('school_admin', 'super_admin') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  SELECT * INTO v_meeting FROM public.meetings WHERE id = p_meeting_id;
  IF NOT FOUND OR v_meeting.school_id IS DISTINCT FROM v_actor.school_id THEN
    RAISE EXCEPTION 'meeting_not_found';
  END IF;

  IF coalesce(trim(coalesce(p_reason, '')), '') = '' THEN
    RAISE EXCEPTION 'reason_required';
  END IF;

  UPDATE public.meeting_minutes
     SET cancelled_at = now(),
         cancelled_by = v_actor.user_id,
         cancel_reason = trim(p_reason)
   WHERE meeting_id = p_meeting_id;

  INSERT INTO public.audit_logs
    (school_id, user_id, acted_role, action, entity_type, entity_id, details)
  VALUES (
    v_meeting.school_id, v_actor.user_id, v_actor.role,
    'meeting_minutes.cancel', 'meeting_minutes', p_meeting_id::text,
    jsonb_build_object('reason', trim(p_reason))
  );
END;
$$;

-- ---------------------------------------------------------------------------
-- Resolutions
-- ---------------------------------------------------------------------------

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

  -- You cannot make somebody responsible for a resolution of a meeting they
  -- were never in.
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

  RETURN v_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.set_meeting_resolution_status(
  p_token text,
  p_resolution_id uuid,
  p_status text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_res public.meeting_resolutions;
  v_meeting public.meetings;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  SELECT * INTO v_res FROM public.meeting_resolutions WHERE id = p_resolution_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'resolution_not_found';
  END IF;

  SELECT * INTO v_meeting FROM public.meetings WHERE id = v_res.meeting_id;
  IF v_meeting.school_id IS DISTINCT FROM v_actor.school_id THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  IF p_status NOT IN ('open', 'done', 'cancelled') THEN
    RAISE EXCEPTION 'invalid_status';
  END IF;

  -- The person it was assigned to can report it done; the organiser and the
  -- administrator can change it either way.
  IF v_res.assignee_user_id IS DISTINCT FROM v_actor.user_id
     AND v_meeting.created_by <> v_actor.user_id
     AND v_actor.role NOT IN ('school_admin', 'super_admin') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  UPDATE public.meeting_resolutions
     SET status = p_status,
         completed_at = CASE WHEN p_status = 'done' THEN now() ELSE NULL END
   WHERE id = p_resolution_id;
END;
$$;

-- ---------------------------------------------------------------------------
-- Attachments (Edge Function pair)
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.assert_meeting_attachment_upload_access(
  p_token text,
  p_meeting_id uuid
)
RETURNS uuid
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

  -- Any attendee may attach a document: the ผู้เข้าร่วม bringing the paper is
  -- the normal case, not only the organiser.
  IF NOT public._can_see_meeting(
       v_actor.user_id, v_actor.role::text, v_actor.school_id, v_meeting)
     OR v_meeting.visibility = 'school'
        AND NOT EXISTS (
          SELECT 1 FROM public.meeting_attendees a
           WHERE a.meeting_id = p_meeting_id AND a.user_id = v_actor.user_id
        )
        AND v_actor.role NOT IN ('executive', 'school_admin', 'super_admin')
  THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  RETURN v_meeting.school_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.register_meeting_attachment(
  p_token text,
  p_meeting_id uuid,
  p_storage_path text,
  p_file_name text,
  p_size_bytes bigint,
  p_agenda_item_id uuid DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_school uuid;
  v_id uuid;
BEGIN
  v_school := public.assert_meeting_attachment_upload_access(p_token, p_meeting_id);
  SELECT * INTO v_actor FROM get_session_actor(p_token);

  IF coalesce(trim(coalesce(p_storage_path, '')), '') = ''
     OR coalesce(trim(coalesce(p_file_name, '')), '') = '' THEN
    RAISE EXCEPTION 'file_required';
  END IF;

  IF p_storage_path NOT LIKE v_school::text || '/%' THEN
    RAISE EXCEPTION 'invalid_storage_path';
  END IF;

  INSERT INTO public.meeting_attachments (
    meeting_id, agenda_item_id, storage_path, file_name, file_type,
    size_bytes, uploaded_by
  ) VALUES (
    p_meeting_id, p_agenda_item_id, p_storage_path, trim(p_file_name),
    public._report_file_type(p_file_name),
    greatest(coalesce(p_size_bytes, 0), 0), v_actor.user_id
  )
  RETURNING id INTO v_id;

  RETURN v_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_meeting_attachment_for_download(
  p_token text,
  p_attachment_id uuid
)
RETURNS TABLE (storage_path text, file_name varchar)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_att public.meeting_attachments;
  v_meeting public.meetings;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  SELECT * INTO v_att FROM public.meeting_attachments WHERE id = p_attachment_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'attachment_not_found';
  END IF;

  SELECT * INTO v_meeting FROM public.meetings WHERE id = v_att.meeting_id;

  IF NOT public._can_see_meeting(
       v_actor.user_id, v_actor.role::text, v_actor.school_id, v_meeting) THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  RETURN QUERY SELECT v_att.storage_path, v_att.file_name;
END;
$$;

-- ---------------------------------------------------------------------------
-- Reads
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.list_meetings(
  p_token text,
  p_from date DEFAULT NULL,
  p_to date DEFAULT NULL,
  p_status text DEFAULT NULL
)
RETURNS TABLE (
  meeting_id uuid,
  title varchar,
  description text,
  meeting_type text,
  visibility text,
  location varchar,
  start_at timestamptz,
  end_at timestamptz,
  status text,
  minutes_expected boolean,
  cancel_reason text,
  organizer_name text,
  attendee_count int,
  accepted_count int,
  pending_count int,
  postpone_count int,
  my_response text,
  minutes_status text,
  agenda_count int,
  attachment_count int,
  open_resolution_count int
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
    m.title,
    m.description,
    m.meeting_type::text,
    m.visibility::text,
    m.location,
    m.start_at,
    m.end_at,
    m.status::text,
    m.minutes_expected,
    m.cancel_reason,
    trim(o.first_name || ' ' || o.last_name),
    (SELECT count(*)::int FROM public.meeting_attendees a
      WHERE a.meeting_id = m.id),
    (SELECT count(*)::int FROM public.meeting_attendees a
      WHERE a.meeting_id = m.id AND a.response = 'accepted'),
    (SELECT count(*)::int FROM public.meeting_attendees a
      WHERE a.meeting_id = m.id AND a.response = 'pending'),
    (SELECT count(*)::int FROM public.meeting_attendees a
      WHERE a.meeting_id = m.id AND a.response = 'postpone_requested'),
    (SELECT a.response::text FROM public.meeting_attendees a
      WHERE a.meeting_id = m.id AND a.user_id = v_actor.user_id),
    -- null when nothing has been recorded, which the UI must not confuse with
    -- a meeting that needs no record (minutes_expected = false).
    (SELECT mn.status::text FROM public.meeting_minutes mn
      WHERE mn.meeting_id = m.id),
    (SELECT count(*)::int FROM public.meeting_agenda_items i
      WHERE i.meeting_id = m.id),
    (SELECT count(*)::int FROM public.meeting_attachments f
      WHERE f.meeting_id = m.id),
    (SELECT count(*)::int FROM public.meeting_resolutions r
      WHERE r.meeting_id = m.id AND r.status = 'open')
  FROM public.meetings m
  JOIN public.users o ON o.id = m.created_by
  WHERE m.school_id = v_actor.school_id
    AND public._can_see_meeting(
          v_actor.user_id, v_actor.role::text, v_actor.school_id, m)
    AND (p_from IS NULL OR m.start_at >= p_from::timestamptz)
    AND (p_to IS NULL OR m.start_at < (p_to + 1)::timestamptz)
    AND (p_status IS NULL OR m.status = p_status)
  ORDER BY m.start_at DESC;
END;
$$;

CREATE OR REPLACE FUNCTION public.list_meeting_attendees(
  p_token text,
  p_meeting_id uuid
)
RETURNS TABLE (
  user_id uuid,
  full_name text,
  is_organizer boolean,
  source text,
  source_department text,
  response text,
  response_note text,
  responded_at timestamptz
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
  SELECT
    a.user_id,
    trim(u.first_name || ' ' || u.last_name),
    a.is_organizer,
    a.source::text,
    d.name::text,
    a.response::text,
    a.response_note,
    a.responded_at
  FROM public.meeting_attendees a
  JOIN public.users u ON u.id = a.user_id
  LEFT JOIN public.departments d ON d.id = a.source_department_id
  WHERE a.meeting_id = p_meeting_id
  ORDER BY a.is_organizer DESC, trim(u.first_name || ' ' || u.last_name);
END;
$$;

CREATE OR REPLACE FUNCTION public.list_meeting_agenda(
  p_token text,
  p_meeting_id uuid
)
RETURNS TABLE (
  item_id uuid,
  sort_order int,
  title varchar,
  detail text,
  presenter_name text
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
  SELECT i.id, i.sort_order, i.title, i.detail,
         trim(p.first_name || ' ' || p.last_name)
    FROM public.meeting_agenda_items i
    LEFT JOIN public.users p ON p.id = i.presenter_user_id
   WHERE i.meeting_id = p_meeting_id
   ORDER BY i.sort_order, i.title;
END;
$$;

-- Draft minutes are visible only to the person writing them. A finalised
-- record is visible to everyone who can see the meeting — including, always,
-- the person a one-on-one is about.
CREATE OR REPLACE FUNCTION public.get_meeting_minutes(
  p_token text,
  p_meeting_id uuid
)
RETURNS TABLE (
  body text,
  status text,
  recorder_name text,
  created_at timestamptz,
  finalized_at timestamptz,
  cancelled_at timestamptz,
  cancel_reason text,
  can_add_addendum boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_meeting public.meetings;
  v_minutes public.meeting_minutes;
  v_is_recorder boolean;
  v_is_attendee boolean;
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

  SELECT * INTO v_minutes FROM public.meeting_minutes
   WHERE meeting_id = p_meeting_id;
  IF NOT FOUND THEN
    RETURN;
  END IF;

  v_is_recorder := v_meeting.created_by = v_actor.user_id
                   OR v_actor.role IN ('school_admin', 'super_admin');
  v_is_attendee := EXISTS (
    SELECT 1 FROM public.meeting_attendees a
     WHERE a.meeting_id = p_meeting_id AND a.user_id = v_actor.user_id
  );

  IF v_minutes.status = 'draft' AND NOT v_is_recorder THEN
    RETURN;
  END IF;

  -- Every read of a one-on-one record is logged. Group minutes are not: they
  -- are not a document about one person.
  IF v_meeting.meeting_type = 'one_on_one' THEN
    INSERT INTO public.audit_logs
      (school_id, user_id, acted_role, action, entity_type, entity_id, details)
    VALUES (
      v_meeting.school_id, v_actor.user_id, v_actor.role,
      'meeting_minutes.read', 'meeting_minutes', p_meeting_id::text,
      jsonb_build_object('status', v_minutes.status)
    );
  END IF;

  RETURN QUERY
  SELECT
    v_minutes.body,
    v_minutes.status::text,
    (SELECT trim(u.first_name || ' ' || u.last_name)
       FROM public.users u WHERE u.id = v_minutes.recorded_by),
    v_minutes.created_at,
    v_minutes.finalized_at,
    v_minutes.cancelled_at,
    v_minutes.cancel_reason,
    (v_minutes.status = 'final' AND (v_is_recorder OR v_is_attendee));
END;
$$;

CREATE OR REPLACE FUNCTION public.list_meeting_minute_addenda(
  p_token text,
  p_meeting_id uuid
)
RETURNS TABLE (
  addendum_id uuid,
  body text,
  author_kind text,
  author_name text,
  created_at timestamptz
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
  SELECT ad.id, ad.body, ad.author_kind::text,
         trim(u.first_name || ' ' || u.last_name), ad.created_at
    FROM public.meeting_minute_addenda ad
    JOIN public.users u ON u.id = ad.author_id
   WHERE ad.meeting_id = p_meeting_id
   ORDER BY ad.created_at;
END;
$$;

CREATE OR REPLACE FUNCTION public.list_meeting_resolutions(
  p_token text,
  p_meeting_id uuid DEFAULT NULL,
  p_mine_only boolean DEFAULT false
)
RETURNS TABLE (
  resolution_id uuid,
  meeting_id uuid,
  meeting_title varchar,
  body text,
  assignee_user_id uuid,
  assignee_name text,
  due_date date,
  status text,
  is_overdue boolean,
  created_at timestamptz,
  completed_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_today date;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  v_today := (now() AT TIME ZONE 'Asia/Bangkok')::date;

  RETURN QUERY
  SELECT
    r.id, m.id, m.title, r.body, r.assignee_user_id,
    trim(u.first_name || ' ' || u.last_name),
    r.due_date, r.status::text,
    (r.due_date IS NOT NULL AND r.due_date < v_today AND r.status = 'open'),
    r.created_at, r.completed_at
  FROM public.meeting_resolutions r
  JOIN public.meetings m ON m.id = r.meeting_id
  LEFT JOIN public.users u ON u.id = r.assignee_user_id
  WHERE m.school_id = v_actor.school_id
    AND public._can_see_meeting(
          v_actor.user_id, v_actor.role::text, v_actor.school_id, m)
    AND (p_meeting_id IS NULL OR r.meeting_id = p_meeting_id)
    AND (NOT p_mine_only OR r.assignee_user_id = v_actor.user_id)
  ORDER BY r.status, r.due_date NULLS LAST, r.created_at DESC;
END;
$$;

CREATE OR REPLACE FUNCTION public.list_meeting_attachments(
  p_token text,
  p_meeting_id uuid
)
RETURNS TABLE (
  attachment_id uuid,
  file_name varchar,
  file_type varchar,
  size_bytes bigint,
  uploader_name text,
  uploaded_at timestamptz
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
  SELECT f.id, f.file_name, f.file_type, f.size_bytes,
         trim(u.first_name || ' ' || u.last_name), f.uploaded_at
    FROM public.meeting_attachments f
    JOIN public.users u ON u.id = f.uploaded_by
   WHERE f.meeting_id = p_meeting_id
   ORDER BY f.uploaded_at;
END;
$$;

-- ---------------------------------------------------------------------------
-- Grants
-- ---------------------------------------------------------------------------

REVOKE ALL ON FUNCTION public._can_see_meeting FROM PUBLIC, anon, authenticated, service_role;

REVOKE ALL ON FUNCTION public.assert_meeting_attachment_upload_access FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.assert_meeting_attachment_upload_access TO service_role;

REVOKE ALL ON FUNCTION public.get_meeting_attachment_for_download FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_meeting_attachment_for_download TO service_role;

REVOKE ALL ON FUNCTION public.create_meeting FROM PUBLIC, service_role;
GRANT EXECUTE ON FUNCTION public.create_meeting TO anon, authenticated;

REVOKE ALL ON FUNCTION public.cancel_meeting FROM PUBLIC, service_role;
GRANT EXECUTE ON FUNCTION public.cancel_meeting TO anon, authenticated;

REVOKE ALL ON FUNCTION public.complete_meeting FROM PUBLIC, service_role;
GRANT EXECUTE ON FUNCTION public.complete_meeting TO anon, authenticated;

REVOKE ALL ON FUNCTION public.respond_to_meeting FROM PUBLIC, service_role;
GRANT EXECUTE ON FUNCTION public.respond_to_meeting TO anon, authenticated;

REVOKE ALL ON FUNCTION public.set_meeting_agenda_item FROM PUBLIC, service_role;
GRANT EXECUTE ON FUNCTION public.set_meeting_agenda_item TO anon, authenticated;

REVOKE ALL ON FUNCTION public.delete_meeting_agenda_item FROM PUBLIC, service_role;
GRANT EXECUTE ON FUNCTION public.delete_meeting_agenda_item TO anon, authenticated;

REVOKE ALL ON FUNCTION public.save_meeting_minutes_draft FROM PUBLIC, service_role;
GRANT EXECUTE ON FUNCTION public.save_meeting_minutes_draft TO anon, authenticated;

REVOKE ALL ON FUNCTION public.finalize_meeting_minutes FROM PUBLIC, service_role;
GRANT EXECUTE ON FUNCTION public.finalize_meeting_minutes TO anon, authenticated;

REVOKE ALL ON FUNCTION public.add_meeting_minute_addendum FROM PUBLIC, service_role;
GRANT EXECUTE ON FUNCTION public.add_meeting_minute_addendum TO anon, authenticated;

REVOKE ALL ON FUNCTION public.cancel_meeting_minutes FROM PUBLIC, service_role;
GRANT EXECUTE ON FUNCTION public.cancel_meeting_minutes TO anon, authenticated;

REVOKE ALL ON FUNCTION public.create_meeting_resolution FROM PUBLIC, service_role;
GRANT EXECUTE ON FUNCTION public.create_meeting_resolution TO anon, authenticated;

REVOKE ALL ON FUNCTION public.set_meeting_resolution_status FROM PUBLIC, service_role;
GRANT EXECUTE ON FUNCTION public.set_meeting_resolution_status TO anon, authenticated;

REVOKE ALL ON FUNCTION public.register_meeting_attachment FROM PUBLIC, service_role;
GRANT EXECUTE ON FUNCTION public.register_meeting_attachment TO anon, authenticated;

REVOKE ALL ON FUNCTION public.list_meetings FROM PUBLIC, service_role;
GRANT EXECUTE ON FUNCTION public.list_meetings TO anon, authenticated;

REVOKE ALL ON FUNCTION public.list_meeting_attendees FROM PUBLIC, service_role;
GRANT EXECUTE ON FUNCTION public.list_meeting_attendees TO anon, authenticated;

REVOKE ALL ON FUNCTION public.list_meeting_agenda FROM PUBLIC, service_role;
GRANT EXECUTE ON FUNCTION public.list_meeting_agenda TO anon, authenticated;

REVOKE ALL ON FUNCTION public.get_meeting_minutes FROM PUBLIC, service_role;
GRANT EXECUTE ON FUNCTION public.get_meeting_minutes TO anon, authenticated;

REVOKE ALL ON FUNCTION public.list_meeting_minute_addenda FROM PUBLIC, service_role;
GRANT EXECUTE ON FUNCTION public.list_meeting_minute_addenda TO anon, authenticated;

REVOKE ALL ON FUNCTION public.list_meeting_resolutions FROM PUBLIC, service_role;
GRANT EXECUTE ON FUNCTION public.list_meeting_resolutions TO anon, authenticated;

REVOKE ALL ON FUNCTION public.list_meeting_attachments FROM PUBLIC, service_role;
GRANT EXECUTE ON FUNCTION public.list_meeting_attachments TO anon, authenticated;
