-- Migration: 20260828010000_wiring_groups_system.sql
-- Description: Real wiring-group + inspection-workflow tracking for the
-- AIoT Smart Wiring Lab, previously 100% hardcoded on the teacher
-- dashboard. A "kit" is devices.kit_code (already real, no dedicated kit
-- table) — this adds the missing piece: which students are grouped
-- together on a kit, and a pass/fail inspection state machine.
-- Deliberately NOT built on student_groups (course_id + nullable
-- assignment_id, with a real one-student-per-group-per-assignment
-- business rule) — that table models a different entity; overloading it
-- with kit_code/status columns would be a two-entities-in-one-table smell.

CREATE TABLE IF NOT EXISTS public.wiring_groups (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id uuid NOT NULL REFERENCES public.courses(id),
  kit_code varchar NOT NULL,
  name varchar NOT NULL,
  status text NOT NULL DEFAULT 'wiring' CHECK (status IN ('wiring', 'passed', 'failed', 'running')),
  inspection_note text,
  inspected_by uuid REFERENCES public.users(id),
  inspected_at timestamptz,
  created_by uuid NOT NULL REFERENCES public.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.wiring_groups ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.wiring_group_members (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id uuid NOT NULL REFERENCES public.wiring_groups(id) ON DELETE CASCADE,
  student_id uuid NOT NULL REFERENCES public.users(id),
  added_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (group_id, student_id)
);

ALTER TABLE public.wiring_group_members ENABLE ROW LEVEL SECURITY;

-- Internal helper: school_admin, or the teacher who owns this course.
CREATE OR REPLACE FUNCTION public._assert_wiring_course_access(
  v_actor record,
  p_course_id uuid
)
RETURNS void
LANGUAGE plpgsql
STABLE
SET search_path = public, extensions
AS $$
BEGIN
  IF v_actor.role = 'teacher' THEN
    IF NOT EXISTS (
      SELECT 1 FROM public.course_teachers
      WHERE course_id = p_course_id AND teacher_id = v_actor.user_id
    ) THEN
      RAISE EXCEPTION 'forbidden';
    END IF;
  ELSIF v_actor.role != 'school_admin' THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.courses
    WHERE id = p_course_id AND school_id = v_actor.school_id
  ) THEN
    RAISE EXCEPTION 'course_not_found';
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public._assert_wiring_course_access FROM PUBLIC, anon, authenticated;

-- list_wiring_groups (Teacher / school admin)
CREATE OR REPLACE FUNCTION public.list_wiring_groups(
  p_token text,
  p_course_id uuid
)
RETURNS TABLE (
  group_id uuid,
  course_id uuid,
  kit_code varchar,
  name varchar,
  status text,
  inspection_note text,
  inspected_by_name text,
  inspected_at timestamptz,
  created_at timestamptz,
  member_count bigint,
  members jsonb,
  kit_device_count bigint,
  kit_online_count bigint
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

  PERFORM public._assert_wiring_course_access(v_actor, p_course_id);

  RETURN QUERY
  SELECT
    wg.id AS group_id,
    wg.course_id,
    wg.kit_code,
    wg.name,
    wg.status,
    wg.inspection_note,
    (ib.first_name || ' ' || ib.last_name)::text AS inspected_by_name,
    wg.inspected_at,
    wg.created_at,
    (SELECT count(*) FROM public.wiring_group_members m WHERE m.group_id = wg.id) AS member_count,
    (
      SELECT coalesce(jsonb_agg(jsonb_build_object(
        'student_id', u.id,
        'student_name', u.first_name || ' ' || u.last_name,
        'student_code', coalesce(u.student_code, '')
      )), '[]'::jsonb)
      FROM public.wiring_group_members m
      JOIN public.users u ON u.id = m.student_id
      WHERE m.group_id = wg.id
    ) AS members,
    (SELECT count(*) FROM public.devices d WHERE d.course_id = wg.course_id AND d.kit_code = wg.kit_code) AS kit_device_count,
    (SELECT count(*) FROM public.devices d WHERE d.course_id = wg.course_id AND d.kit_code = wg.kit_code AND d.status = 'online') AS kit_online_count
  FROM public.wiring_groups wg
  LEFT JOIN public.users ib ON ib.id = wg.inspected_by
  WHERE wg.course_id = p_course_id
  ORDER BY wg.created_at ASC;
END;
$$;

-- create_wiring_group (Teacher / school admin)
CREATE OR REPLACE FUNCTION public.create_wiring_group(
  p_token text,
  p_course_id uuid,
  p_kit_code text,
  p_name text
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

  PERFORM public._assert_wiring_course_access(v_actor, p_course_id);

  IF NOT EXISTS (
    SELECT 1 FROM public.devices
    WHERE course_id = p_course_id AND kit_code = p_kit_code
  ) THEN
    RAISE EXCEPTION 'kit_not_found';
  END IF;

  IF trim(coalesce(p_name, '')) = '' THEN
    RAISE EXCEPTION 'name_required';
  END IF;

  INSERT INTO public.wiring_groups (course_id, kit_code, name, created_by)
  VALUES (p_course_id, p_kit_code, trim(p_name), v_actor.user_id)
  RETURNING id INTO v_id;

  RETURN v_id;
END;
$$;

-- delete_wiring_group (Teacher / school admin)
CREATE OR REPLACE FUNCTION public.delete_wiring_group(
  p_token text,
  p_group_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_course_id uuid;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  SELECT course_id INTO v_course_id FROM public.wiring_groups WHERE id = p_group_id;
  IF v_course_id IS NULL THEN
    RAISE EXCEPTION 'group_not_found';
  END IF;

  PERFORM public._assert_wiring_course_access(v_actor, v_course_id);

  DELETE FROM public.wiring_groups WHERE id = p_group_id;
END;
$$;

-- add_wiring_group_member (Teacher / school admin)
CREATE OR REPLACE FUNCTION public.add_wiring_group_member(
  p_token text,
  p_group_id uuid,
  p_student_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_course_id uuid;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  SELECT course_id INTO v_course_id FROM public.wiring_groups WHERE id = p_group_id;
  IF v_course_id IS NULL THEN
    RAISE EXCEPTION 'group_not_found';
  END IF;

  PERFORM public._assert_wiring_course_access(v_actor, v_course_id);

  IF NOT EXISTS (
    SELECT 1 FROM public.course_students
    WHERE course_id = v_course_id AND student_id = p_student_id
  ) THEN
    RAISE EXCEPTION 'student_not_enrolled';
  END IF;

  INSERT INTO public.wiring_group_members (group_id, student_id)
  VALUES (p_group_id, p_student_id)
  ON CONFLICT (group_id, student_id) DO NOTHING;
END;
$$;

-- remove_wiring_group_member (Teacher / school admin)
CREATE OR REPLACE FUNCTION public.remove_wiring_group_member(
  p_token text,
  p_group_id uuid,
  p_student_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_course_id uuid;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  SELECT course_id INTO v_course_id FROM public.wiring_groups WHERE id = p_group_id;
  IF v_course_id IS NULL THEN
    RAISE EXCEPTION 'group_not_found';
  END IF;

  PERFORM public._assert_wiring_course_access(v_actor, v_course_id);

  DELETE FROM public.wiring_group_members
  WHERE group_id = p_group_id AND student_id = p_student_id;
END;
$$;

-- set_wiring_group_status (Teacher / school admin) — state machine:
-- wiring -> passed|failed, failed -> wiring|passed,
-- passed -> running|wiring|failed, running -> wiring
CREATE OR REPLACE FUNCTION public.set_wiring_group_status(
  p_token text,
  p_group_id uuid,
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
  v_course_id uuid;
  v_current_status text;
  v_legal boolean;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  SELECT course_id, status INTO v_course_id, v_current_status
  FROM public.wiring_groups WHERE id = p_group_id;
  IF v_course_id IS NULL THEN
    RAISE EXCEPTION 'group_not_found';
  END IF;

  PERFORM public._assert_wiring_course_access(v_actor, v_course_id);

  IF p_status NOT IN ('wiring', 'passed', 'failed', 'running') THEN
    RAISE EXCEPTION 'invalid_status';
  END IF;

  v_legal := CASE v_current_status
    WHEN 'wiring' THEN p_status IN ('passed', 'failed')
    WHEN 'failed' THEN p_status IN ('wiring', 'passed')
    WHEN 'passed' THEN p_status IN ('running', 'wiring', 'failed')
    WHEN 'running' THEN p_status IN ('wiring')
    ELSE false
  END;

  IF NOT v_legal THEN
    RAISE EXCEPTION 'invalid_transition';
  END IF;

  UPDATE public.wiring_groups
  SET status = p_status,
      updated_at = now(),
      inspection_note = CASE WHEN p_status IN ('passed', 'failed') THEN p_note ELSE inspection_note END,
      inspected_by = CASE WHEN p_status IN ('passed', 'failed') THEN v_actor.user_id ELSE inspected_by END,
      inspected_at = CASE WHEN p_status IN ('passed', 'failed') THEN now() ELSE inspected_at END
  WHERE id = p_group_id;
END;
$$;

-- get_wiring_lab_summary (Teacher) — aggregate across all courses the
-- teacher teaches, for the dashboard card.
CREATE OR REPLACE FUNCTION public.get_wiring_lab_summary(p_token text)
RETURNS TABLE (
  kits_total int,
  kits_ready int,
  devices_total int,
  devices_online int,
  wiring_count int,
  passed_count int,
  waiting_to_run_count int,
  needs_review_count int,
  alert_kit_code varchar,
  alert_device_name varchar,
  alert_device_status device_status,
  alert_last_seen_at timestamptz
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

  IF v_actor.role != 'teacher' THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  RETURN QUERY
  WITH my_devices AS (
    SELECT d.* FROM public.devices d
    JOIN public.course_teachers ct ON ct.course_id = d.course_id
    WHERE ct.teacher_id = v_actor.user_id AND d.kit_code IS NOT NULL
  ),
  kit_stats AS (
    SELECT kit_code,
      bool_and(status = 'online') AS is_ready
    FROM my_devices
    GROUP BY kit_code
  ),
  my_groups AS (
    SELECT wg.* FROM public.wiring_groups wg
    JOIN public.course_teachers ct ON ct.course_id = wg.course_id
    WHERE ct.teacher_id = v_actor.user_id
  ),
  alert_pick AS (
    SELECT kit_code, name, status, last_seen_at
    FROM my_devices
    WHERE status IN ('offline', 'error') OR last_seen_at < now() - interval '15 minutes'
    ORDER BY (status = 'error') DESC, (status = 'offline') DESC, last_seen_at ASC NULLS FIRST
    LIMIT 1
  )
  SELECT
    (SELECT count(*)::int FROM kit_stats),
    (SELECT count(*)::int FROM kit_stats WHERE is_ready),
    (SELECT count(*)::int FROM my_devices),
    (SELECT count(*)::int FROM my_devices WHERE status = 'online'),
    (SELECT count(*)::int FROM my_groups WHERE status = 'wiring'),
    (SELECT count(*)::int FROM my_groups WHERE status IN ('passed', 'running')),
    (SELECT count(*)::int FROM my_groups WHERE status = 'passed'),
    (SELECT count(*)::int FROM my_groups WHERE status = 'failed'),
    (SELECT kit_code FROM alert_pick),
    (SELECT name FROM alert_pick),
    (SELECT status FROM alert_pick),
    (SELECT last_seen_at FROM alert_pick);
END;
$$;

-- Extend list_teaching_kit_devices to also return kit_code (needed by
-- the create-group dialog to pick a real kit). CREATE OR REPLACE can't
-- change RETURNS TABLE's column set, so DROP + CREATE.
DROP FUNCTION IF EXISTS public.list_teaching_kit_devices(text);

CREATE FUNCTION public.list_teaching_kit_devices(p_token text)
RETURNS TABLE (
  device_id uuid,
  name varchar,
  type device_type,
  location varchar,
  status device_status,
  course_id uuid,
  course_name varchar,
  kit_code varchar
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
  IF v_actor.role NOT IN ('teacher', 'school_admin') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  RETURN QUERY
  SELECT
    d.id AS device_id,
    d.name,
    d.type,
    d.location,
    d.status,
    d.course_id,
    c.subject_name AS course_name,
    d.kit_code
  FROM public.devices d
  JOIN public.courses c ON c.id = d.course_id
  WHERE d.school_id = v_actor.school_id
    AND d.course_id IS NOT NULL
    AND (
      v_actor.role = 'school_admin'
      OR EXISTS (
        SELECT 1 FROM public.course_teachers ct
        WHERE ct.course_id = d.course_id AND ct.teacher_id = v_actor.user_id
      )
    );
END;
$$;

REVOKE ALL ON FUNCTION public.list_wiring_groups FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.list_wiring_groups TO anon, authenticated;

REVOKE ALL ON FUNCTION public.create_wiring_group FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_wiring_group TO anon, authenticated;

REVOKE ALL ON FUNCTION public.delete_wiring_group FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.delete_wiring_group TO anon, authenticated;

REVOKE ALL ON FUNCTION public.add_wiring_group_member FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.add_wiring_group_member TO anon, authenticated;

REVOKE ALL ON FUNCTION public.remove_wiring_group_member FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.remove_wiring_group_member TO anon, authenticated;

REVOKE ALL ON FUNCTION public.set_wiring_group_status FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.set_wiring_group_status TO anon, authenticated;

REVOKE ALL ON FUNCTION public.get_wiring_lab_summary FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_wiring_lab_summary TO anon, authenticated;

REVOKE ALL ON FUNCTION public.list_teaching_kit_devices FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.list_teaching_kit_devices TO anon, authenticated;
