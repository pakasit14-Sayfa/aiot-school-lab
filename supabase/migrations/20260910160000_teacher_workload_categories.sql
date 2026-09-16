-- Real data for the 4 "ภาพรวมครูและการสอน" workload categories on the
-- executive overview page (สอนในตารางปกติ / กิจกรรม & แล็บ / จัดครูสอนแทน /
-- เตรียมสอน-ประชุม). Two of the four had zero backing table anywhere in the
-- schema before this migration.

-- 1) period_type on class_schedules (สอนในตารางปกติ vs กิจกรรม & แล็บ)
ALTER TABLE class_schedules
  ADD COLUMN period_type character varying NOT NULL DEFAULT 'regular'
  CHECK (period_type IN ('regular', 'activity_lab'));

-- 2) substitute-teacher coverage of a specific period occurrence
CREATE TABLE IF NOT EXISTS class_substitutions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id uuid NOT NULL REFERENCES schools(id),
  class_schedule_id uuid NOT NULL REFERENCES class_schedules(id) ON DELETE CASCADE,
  class_date date NOT NULL,
  original_teacher_id uuid NOT NULL REFERENCES users(id),
  substitute_teacher_id uuid NOT NULL REFERENCES users(id),
  note text,
  created_by uuid NOT NULL REFERENCES users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (class_schedule_id, class_date)
);
ALTER TABLE class_substitutions ENABLE ROW LEVEL SECURITY;

-- 3) self-logged non-teaching prep blocks (the "เตรียมสอน" half; "ประชุม"
-- already has a real home in meetings/meeting_attendees)
CREATE TABLE IF NOT EXISTS staff_prep_blocks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id uuid NOT NULL REFERENCES schools(id),
  teacher_id uuid NOT NULL REFERENCES users(id),
  class_date date NOT NULL,
  start_time time NOT NULL,
  end_time time NOT NULL,
  label text,
  created_by uuid NOT NULL REFERENCES users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  CHECK (end_time > start_time)
);
ALTER TABLE staff_prep_blocks ENABLE ROW LEVEL SECURITY;

-- set_class_schedule: accept an optional period_type (default keeps every
-- existing caller working unchanged). Adding a trailing default param is
-- NOT a like-for-like CREATE OR REPLACE in Postgres -- it creates a second
-- overload instead of replacing the old one, leaving calls ambiguous. Drop
-- the old 6-arg signature explicitly first (same lesson already written up
-- in WORK_LOG.md for poll_device_commands).
DROP FUNCTION IF EXISTS public.set_class_schedule(text, uuid, smallint, time, time, text);
CREATE FUNCTION public.set_class_schedule(
  p_token text, p_course_id uuid, p_day_of_week smallint,
  p_start_time time without time zone, p_end_time time without time zone,
  p_room text DEFAULT NULL::text, p_period_type text DEFAULT 'regular'
) RETURNS TABLE(schedule_id uuid)
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public', 'extensions'
AS $function$
DECLARE
  v_actor record;
  v_course courses%rowtype;
  v_schedule_id uuid;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN RAISE EXCEPTION 'invalid_session'; END IF;
  IF v_actor.role NOT IN ('teacher', 'school_admin') THEN RAISE EXCEPTION 'forbidden'; END IF;
  IF p_period_type NOT IN ('regular', 'activity_lab') THEN
    RAISE EXCEPTION 'invalid_period_type';
  END IF;

  SELECT * INTO v_course FROM courses WHERE id = p_course_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'course_not_found'; END IF;
  IF v_course.school_id IS DISTINCT FROM v_actor.school_id THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF v_actor.role = 'teacher' AND NOT EXISTS (
    SELECT 1 FROM course_teachers ct
    WHERE ct.course_id = p_course_id AND ct.teacher_id = v_actor.user_id
  ) THEN RAISE EXCEPTION 'forbidden'; END IF;

  IF p_end_time <= p_start_time THEN
    RAISE EXCEPTION 'end_time_must_be_after_start_time';
  END IF;

  INSERT INTO class_schedules (course_id, day_of_week, start_time, end_time, room, created_by, period_type)
  VALUES (p_course_id, p_day_of_week, p_start_time, p_end_time, p_room, v_actor.user_id, p_period_type)
  RETURNING id INTO v_schedule_id;

  RETURN QUERY SELECT v_schedule_id;
END;
$function$;

-- list_all_school_schedules / list_my_schedule / list_teacher_schedules:
-- surface period_type. Return-shape change -> drop+create (same lesson as
-- the executive watchlist migration). period_type stays character varying
-- to match the source column exactly, no text-cast mismatch.
DROP FUNCTION IF EXISTS public.list_all_school_schedules(text);
CREATE FUNCTION public.list_all_school_schedules(p_token text)
RETURNS TABLE(schedule_id uuid, course_id uuid, subject_name character varying, day_of_week smallint, start_time time without time zone, end_time time without time zone, room character varying, period_type character varying)
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public', 'extensions'
AS $function$
DECLARE v_actor record;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN RAISE EXCEPTION 'invalid_session'; END IF;
  IF v_actor.role NOT IN ('executive', 'school_admin') THEN RAISE EXCEPTION 'forbidden'; END IF;

  RETURN QUERY
  SELECT cs.id, c.id, c.subject_name, cs.day_of_week, cs.start_time, cs.end_time, cs.room, cs.period_type
  FROM class_schedules cs
  JOIN courses c ON c.id = cs.course_id
  WHERE c.school_id = v_actor.school_id
  ORDER BY cs.day_of_week, cs.start_time;
END;
$function$;
REVOKE ALL ON FUNCTION public.list_all_school_schedules(text) FROM PUBLIC,service_role;
GRANT EXECUTE ON FUNCTION public.list_all_school_schedules(text) TO anon,authenticated,service_role;

DROP FUNCTION IF EXISTS public.list_my_schedule(text);
CREATE FUNCTION public.list_my_schedule(p_token text)
RETURNS TABLE(schedule_id uuid, course_id uuid, subject_name character varying, day_of_week smallint, start_time time without time zone, end_time time without time zone, room character varying, period_type character varying)
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public', 'extensions'
AS $function$
DECLARE v_actor record;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN RAISE EXCEPTION 'invalid_session'; END IF;
  IF v_actor.role <> 'student' THEN RAISE EXCEPTION 'forbidden'; END IF;

  RETURN QUERY
  SELECT cs.id, c.id, c.subject_name, cs.day_of_week, cs.start_time, cs.end_time, cs.room, cs.period_type
  FROM class_schedules cs
  JOIN courses c ON c.id = cs.course_id
  JOIN course_students st ON st.course_id = c.id
  WHERE st.student_id = v_actor.user_id
  ORDER BY cs.day_of_week, cs.start_time;
END;
$function$;
REVOKE ALL ON FUNCTION public.list_my_schedule(text) FROM PUBLIC,service_role;
GRANT EXECUTE ON FUNCTION public.list_my_schedule(text) TO anon,authenticated,service_role;

DROP FUNCTION IF EXISTS public.list_teacher_schedules(text, uuid);
CREATE FUNCTION public.list_teacher_schedules(p_token text, p_course_id uuid DEFAULT NULL::uuid)
RETURNS TABLE(schedule_id uuid, course_id uuid, subject_name character varying, day_of_week smallint, start_time time without time zone, end_time time without time zone, room character varying, period_type character varying)
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public', 'extensions'
AS $function$
DECLARE v_actor record;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN RAISE EXCEPTION 'invalid_session'; END IF;
  IF v_actor.role NOT IN ('teacher', 'school_admin') THEN RAISE EXCEPTION 'forbidden'; END IF;

  RETURN QUERY
  SELECT cs.id, c.id, c.subject_name, cs.day_of_week, cs.start_time, cs.end_time, cs.room, cs.period_type
  FROM class_schedules cs
  JOIN courses c ON c.id = cs.course_id
  WHERE c.school_id = v_actor.school_id
    AND (p_course_id IS NULL OR c.id = p_course_id)
    AND (
      v_actor.role = 'school_admin'
      OR EXISTS (
        SELECT 1 FROM course_teachers ct
        WHERE ct.course_id = c.id AND ct.teacher_id = v_actor.user_id
      )
    )
  ORDER BY cs.day_of_week, cs.start_time;
END;
$function$;
REVOKE ALL ON FUNCTION public.list_teacher_schedules(text, uuid) FROM PUBLIC,service_role;
GRANT EXECUTE ON FUNCTION public.list_teacher_schedules(text, uuid) TO anon,authenticated,service_role;

-- log a self-service prep block (teacher only)
CREATE OR REPLACE FUNCTION public.log_staff_prep_block(
  p_token text, p_class_date date, p_start_time time without time zone,
  p_end_time time without time zone, p_label text DEFAULT NULL::text
) RETURNS TABLE(block_id uuid)
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public', 'extensions'
AS $function$
DECLARE v_actor record; v_id uuid;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN RAISE EXCEPTION 'invalid_session'; END IF;
  IF v_actor.role <> 'teacher' OR v_actor.school_id IS NULL THEN RAISE EXCEPTION 'forbidden'; END IF;
  IF p_end_time <= p_start_time THEN RAISE EXCEPTION 'end_time_must_be_after_start_time'; END IF;

  INSERT INTO staff_prep_blocks (school_id, teacher_id, class_date, start_time, end_time, label, created_by)
  VALUES (v_actor.school_id, v_actor.user_id, p_class_date, p_start_time, p_end_time, p_label, v_actor.user_id)
  RETURNING id INTO v_id;

  RETURN QUERY SELECT v_id;
END;
$function$;
REVOKE ALL ON FUNCTION public.log_staff_prep_block(text, date, time, time, text) FROM PUBLIC,service_role;
GRANT EXECUTE ON FUNCTION public.log_staff_prep_block(text, date, time, time, text) TO anon,authenticated;

-- record (or update) who covered a specific period occurrence
CREATE OR REPLACE FUNCTION public.record_class_substitution(
  p_token text, p_class_schedule_id uuid, p_class_date date,
  p_original_teacher_id uuid, p_substitute_teacher_id uuid,
  p_note text DEFAULT NULL::text
) RETURNS TABLE(substitution_id uuid)
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public', 'extensions'
AS $function$
DECLARE v_actor record; v_school uuid; v_id uuid;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN RAISE EXCEPTION 'invalid_session'; END IF;
  IF v_actor.role NOT IN ('school_admin', 'executive', 'super_admin')
     OR v_actor.school_id IS NULL THEN RAISE EXCEPTION 'forbidden'; END IF;

  SELECT c.school_id INTO v_school
  FROM class_schedules cs JOIN courses c ON c.id = cs.course_id
  WHERE cs.id = p_class_schedule_id;
  IF NOT FOUND OR v_school IS DISTINCT FROM v_actor.school_id THEN
    RAISE EXCEPTION 'schedule_not_found';
  END IF;

  IF p_substitute_teacher_id = p_original_teacher_id THEN
    RAISE EXCEPTION 'substitute_cannot_be_original_teacher';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM users u JOIN user_roles r ON r.user_id = u.id AND r.role = 'teacher'
    WHERE u.id = p_substitute_teacher_id AND u.school_id = v_actor.school_id AND u.status = 'active'
  ) THEN RAISE EXCEPTION 'substitute_teacher_not_found'; END IF;

  INSERT INTO class_substitutions (school_id, class_schedule_id, class_date, original_teacher_id, substitute_teacher_id, note, created_by)
  VALUES (v_actor.school_id, p_class_schedule_id, p_class_date, p_original_teacher_id, p_substitute_teacher_id, p_note, v_actor.user_id)
  ON CONFLICT (class_schedule_id, class_date) DO UPDATE
    SET substitute_teacher_id = excluded.substitute_teacher_id,
        original_teacher_id = excluded.original_teacher_id,
        note = excluded.note
  RETURNING id INTO v_id;

  RETURN QUERY SELECT v_id;
END;
$function$;
REVOKE ALL ON FUNCTION public.record_class_substitution(text, uuid, date, uuid, uuid, text) FROM PUBLIC,service_role;
GRANT EXECUTE ON FUNCTION public.record_class_substitution(text, uuid, date, uuid, uuid, text) TO anon,authenticated;

-- periods on p_date whose regular teacher is on approved leave that day,
-- with whether a substitution has already been recorded for it
CREATE OR REPLACE FUNCTION public.list_periods_needing_substitute(p_token text, p_date date)
RETURNS TABLE(
  class_schedule_id uuid, subject_name character varying, grade_level character varying, room character varying,
  start_time time without time zone, end_time time without time zone,
  original_teacher_id uuid, original_teacher_name text,
  already_covered boolean, substitute_teacher_name text
)
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public', 'extensions'
AS $function$
DECLARE v_actor record; v_dow int;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN RAISE EXCEPTION 'invalid_session'; END IF;
  IF v_actor.role NOT IN ('school_admin', 'executive', 'super_admin')
     OR v_actor.school_id IS NULL THEN RAISE EXCEPTION 'forbidden'; END IF;

  v_dow := EXTRACT(isodow FROM p_date)::int - 1;

  RETURN QUERY
  SELECT cs.id, c.subject_name, c.grade_level, cs.room, cs.start_time, cs.end_time,
    ct.teacher_id, trim(coalesce(u.first_name, '') || ' ' || coalesce(u.last_name, '')),
    (sub.id IS NOT NULL), trim(coalesce(su.first_name, '') || ' ' || coalesce(su.last_name, ''))
  FROM class_schedules cs
  JOIN courses c ON c.id = cs.course_id AND c.school_id = v_actor.school_id AND c.status = 'active'
  JOIN course_teachers ct ON ct.course_id = c.id
  JOIN users u ON u.id = ct.teacher_id
  JOIN staff_leave_requests lr ON lr.user_id = ct.teacher_id AND lr.status = 'approved'
    AND p_date BETWEEN lr.start_date AND lr.end_date
  LEFT JOIN class_substitutions sub ON sub.class_schedule_id = cs.id AND sub.class_date = p_date
  LEFT JOIN users su ON su.id = sub.substitute_teacher_id
  WHERE cs.day_of_week = v_dow
  ORDER BY cs.start_time;
END;
$function$;
REVOKE ALL ON FUNCTION public.list_periods_needing_substitute(text, date) FROM PUBLIC,service_role;
GRANT EXECUTE ON FUNCTION public.list_periods_needing_substitute(text, date) TO anon,authenticated;

-- aggregate for the "ภาพรวมครูและการสอน" bubble card (executive overview)
CREATE OR REPLACE FUNCTION public.get_teacher_workload_summary(p_token text)
RETURNS TABLE(
  regular_periods integer, activity_lab_periods integer,
  regular_teacher_count integer, activity_lab_teacher_count integer,
  substitution_recorded integer, substitution_needed integer,
  prep_meeting_count integer, prep_meeting_teacher_count integer
)
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public', 'extensions'
AS $function$
DECLARE v_actor record; v_year uuid; v_week_start date; v_week_end date;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN RAISE EXCEPTION 'invalid_session'; END IF;
  IF v_actor.role NOT IN ('executive', 'school_admin', 'super_admin')
     OR v_actor.school_id IS NULL THEN RAISE EXCEPTION 'forbidden'; END IF;
  v_year := _current_academic_year_id(v_actor.school_id);
  v_week_start := date_trunc('week', current_date)::date;
  v_week_end := v_week_start + 6;

  RETURN QUERY
  WITH school_schedules AS (
    SELECT cs.id AS class_schedule_id, cs.day_of_week, cs.period_type, ct.teacher_id
    FROM class_schedules cs
    JOIN courses c ON c.id = cs.course_id
    JOIN terms t ON t.id = c.term_id AND t.academic_year_id = v_year
    JOIN course_teachers ct ON ct.course_id = c.id
    WHERE c.school_id = v_actor.school_id AND c.status = 'active'
  ), week_days AS (
    SELECT d::date AS class_date, (EXTRACT(isodow FROM d)::int - 1) AS dow
    FROM generate_series(v_week_start, v_week_end, interval '1 day') d
  ), occurrences AS (
    SELECT ss.class_schedule_id, ss.teacher_id, wd.class_date
    FROM school_schedules ss JOIN week_days wd ON wd.dow = ss.day_of_week
  ), needing AS (
    SELECT DISTINCT o.class_schedule_id, o.class_date
    FROM occurrences o
    JOIN staff_leave_requests lr ON lr.user_id = o.teacher_id AND lr.status = 'approved'
      AND o.class_date BETWEEN lr.start_date AND lr.end_date
  ), recorded AS (
    SELECT n.class_schedule_id, n.class_date
    FROM needing n
    JOIN class_substitutions cs2 ON cs2.class_schedule_id = n.class_schedule_id AND cs2.class_date = n.class_date
  ), prep AS (
    SELECT teacher_id FROM staff_prep_blocks
    WHERE school_id = v_actor.school_id AND class_date BETWEEN v_week_start AND v_week_end
  ), meeting_teachers AS (
    SELECT ma.user_id AS teacher_id
    FROM meetings m
    JOIN meeting_attendees ma ON ma.meeting_id = m.id
    JOIN user_roles r ON r.user_id = ma.user_id AND r.role = 'teacher' AND r.school_id = v_actor.school_id
    WHERE m.school_id = v_actor.school_id AND m.status <> 'cancelled'
      AND m.start_at::date BETWEEN v_week_start AND v_week_end
      AND ma.response <> 'declined'
  )
  SELECT
    (SELECT count(*) FROM school_schedules WHERE period_type = 'regular')::int,
    (SELECT count(*) FROM school_schedules WHERE period_type = 'activity_lab')::int,
    (SELECT count(DISTINCT teacher_id) FROM school_schedules WHERE period_type = 'regular')::int,
    (SELECT count(DISTINCT teacher_id) FROM school_schedules WHERE period_type = 'activity_lab')::int,
    (SELECT count(*) FROM recorded)::int,
    (SELECT count(*) FROM needing)::int,
    ((SELECT count(*) FROM prep) + (SELECT count(*) FROM meeting_teachers))::int,
    (SELECT count(DISTINCT teacher_id) FROM (
      SELECT teacher_id FROM prep UNION SELECT teacher_id FROM meeting_teachers
    ) x)::int;
END;
$function$;
REVOKE ALL ON FUNCTION public.get_teacher_workload_summary(text) FROM PUBLIC,service_role;
GRANT EXECUTE ON FUNCTION public.get_teacher_workload_summary(text) TO anon,authenticated;
