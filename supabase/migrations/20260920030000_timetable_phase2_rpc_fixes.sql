-- 20260920030000_timetable_phase2_rpc_fixes.sql
-- Two things the admin timetable page (D6 phase 2) needed from the DB that
-- phase 1 did not provide:
--   1. list_teacher_subjects(p_token, null) as school_admin raised
--      'forbidden', so the page could not load the "who teaches what" list
--      at all. A null teacher id from an admin now means "every teacher in
--      my school", and the name comes back with the row so the client does
--      not have to merge the staff directory.
--   2. Nobody had a UI to fill teacher_subjects. Assigning a slot is itself
--      the strongest signal that teacher X teaches subject Y, so
--      admin_set_room_timetable_slot records that pair (idempotent). The
--      subject filter in the slot sheet then improves as the timetable is
--      built, without a separate data-entry screen.

DROP FUNCTION IF EXISTS public.list_teacher_subjects(text, uuid);

CREATE OR REPLACE FUNCTION public.list_teacher_subjects(p_token text, p_teacher_id uuid DEFAULT NULL)
RETURNS TABLE (
    id uuid,
    teacher_id uuid,
    teacher_name text,
    subject_name varchar,
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
    IF NOT FOUND THEN RAISE EXCEPTION 'invalid_session'; END IF;

    IF v_actor.role = 'school_admin' THEN
        RETURN QUERY
        SELECT ts.id, ts.teacher_id, (u.first_name || ' ' || u.last_name)::text, ts.subject_name, ts.created_at
        FROM public.teacher_subjects ts
        JOIN public.users u ON u.id = ts.teacher_id
        WHERE ts.school_id = v_actor.school_id
          AND (p_teacher_id IS NULL OR ts.teacher_id = p_teacher_id)
        ORDER BY ts.subject_name, u.first_name;
    ELSIF v_actor.role = 'teacher' AND (p_teacher_id IS NULL OR p_teacher_id = v_actor.user_id) THEN
        RETURN QUERY
        SELECT ts.id, ts.teacher_id, (u.first_name || ' ' || u.last_name)::text, ts.subject_name, ts.created_at
        FROM public.teacher_subjects ts
        JOIN public.users u ON u.id = ts.teacher_id
        WHERE ts.teacher_id = v_actor.user_id AND ts.school_id = v_actor.school_id
        ORDER BY ts.subject_name;
    ELSE
        RAISE EXCEPTION 'forbidden';
    END IF;
END;
$$;
REVOKE ALL ON FUNCTION public.list_teacher_subjects(text, uuid) FROM public;
GRANT EXECUTE ON FUNCTION public.list_teacher_subjects(text, uuid) TO anon, authenticated;

CREATE OR REPLACE FUNCTION public.admin_set_room_timetable_slot(
  p_token text,
  p_term_id uuid,
  p_grade_level text,
  p_room text,
  p_day_of_week smallint,
  p_period_no smallint,
  p_subject_name text,
  p_teacher_id uuid
)
RETURNS TABLE (course_id uuid, schedule_id uuid)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_course courses%rowtype;
  v_target_course_id uuid;
  v_schedule_id uuid;
  v_start time;
  v_end time;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN RAISE EXCEPTION 'invalid_session'; END IF;
  IF v_actor.role not in ('school_admin') THEN RAISE EXCEPTION 'forbidden'; END IF;

  IF trim(coalesce(p_subject_name, '')) = '' THEN RAISE EXCEPTION 'subject_name_required'; END IF;
  IF p_teacher_id IS NULL THEN RAISE EXCEPTION 'teacher_required'; END IF;
  IF NOT EXISTS (
    SELECT 1 FROM users u JOIN user_roles ur ON ur.user_id = u.id
    WHERE u.id = p_teacher_id AND u.school_id = v_actor.school_id AND ur.role = 'teacher'
  ) THEN RAISE EXCEPTION 'teacher_not_found'; END IF;
  IF p_day_of_week < 1 OR p_day_of_week > 7 THEN RAISE EXCEPTION 'invalid_day'; END IF;

  SELECT start_time, end_time INTO v_start, v_end
  FROM public.school_periods
  WHERE school_id = v_actor.school_id AND period_no = p_period_no;
  IF NOT FOUND THEN RAISE EXCEPTION 'period_not_found'; END IF;

  -- one subject per room per day/period: drop whatever was in that cell
  DELETE FROM public.class_schedules cs
  USING public.courses c
  WHERE cs.course_id = c.id
    AND c.school_id = v_actor.school_id
    AND c.term_id = p_term_id
    AND c.grade_level = p_grade_level
    AND public._class_room_key(c.grade_level, c.room) = public._class_room_key(p_grade_level, p_room)
    AND cs.day_of_week = p_day_of_week
    AND cs.period_no = p_period_no;

  SELECT c.* INTO v_course FROM public.courses c
  WHERE c.term_id = p_term_id
    AND c.grade_level = p_grade_level
    AND public._class_room_key(c.grade_level, c.room) = public._class_room_key(p_grade_level, p_room)
    AND c.subject_name = trim(p_subject_name)
    AND c.school_id = v_actor.school_id
  LIMIT 1;

  IF FOUND THEN
    v_target_course_id := v_course.id;
    IF NOT EXISTS (
      SELECT 1 FROM public.course_teachers ct
      WHERE ct.course_id = v_target_course_id AND ct.teacher_id = p_teacher_id
    ) THEN
      DELETE FROM public.course_teachers ct
      WHERE ct.course_id = v_target_course_id AND ct.is_owner = true;
      INSERT INTO public.course_teachers (course_id, teacher_id, is_owner)
      VALUES (v_target_course_id, p_teacher_id, true);
    END IF;
  ELSE
    SELECT public.create_course(
      p_token, p_term_id, trim(p_subject_name), p_grade_level, p_room, NULL, p_teacher_id
    ) INTO v_target_course_id;
  END IF;

  -- remember that this teacher teaches this subject (feeds the slot sheet's filter)
  INSERT INTO public.teacher_subjects (school_id, teacher_id, subject_name, created_by)
  VALUES (v_actor.school_id, p_teacher_id, trim(p_subject_name), v_actor.user_id)
  ON CONFLICT (teacher_id, subject_name) DO NOTHING;

  INSERT INTO public.class_schedules (course_id, day_of_week, period_no, start_time, end_time, created_by)
  VALUES (v_target_course_id, p_day_of_week, p_period_no, v_start, v_end, v_actor.user_id)
  RETURNING id INTO v_schedule_id;

  RETURN QUERY SELECT v_target_course_id, v_schedule_id;
END;
$$;
