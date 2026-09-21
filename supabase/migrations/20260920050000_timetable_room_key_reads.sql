-- 20260920050000_timetable_room_key_reads.sql
-- admin_set_room_timetable_slot already matches rooms through
-- _class_room_key (prod profiles say room '1', the course says 'ม.1/1'),
-- but list_room_timetable and admin_clear_room_timetable_slot still
-- compared c.room = p_room, so a slot the admin had just saved for
-- (ม.1, '1') landed on the 'ม.1/1' course and never showed in the grid
-- (iPhone, prod, 2026-09-20 22:04). Both now use the same key.

CREATE OR REPLACE FUNCTION public.list_room_timetable(
  p_token text,
  p_term_id uuid,
  p_grade_level text,
  p_room text
)
RETURNS TABLE (
  schedule_id uuid,
  course_id uuid,
  day_of_week smallint,
  period_no smallint,
  start_time time,
  end_time time,
  subject_name varchar,
  teacher_id uuid,
  teacher_name text
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

  RETURN QUERY
  SELECT
    cs.id, cs.course_id, cs.day_of_week, cs.period_no, cs.start_time, cs.end_time,
    c.subject_name,
    t.id, (t.first_name || ' ' || t.last_name)::text
  FROM public.class_schedules cs
  JOIN public.courses c ON c.id = cs.course_id
  LEFT JOIN public.course_teachers ct ON ct.course_id = c.id AND ct.is_owner = true
  LEFT JOIN public.users t ON t.id = ct.teacher_id
  WHERE c.school_id = v_actor.school_id
    AND c.term_id = p_term_id
    AND c.grade_level = p_grade_level
    AND public._class_room_key(c.grade_level, c.room) = public._class_room_key(p_grade_level, p_room)
    AND cs.period_no IS NOT NULL
  ORDER BY cs.day_of_week, cs.period_no;
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_clear_room_timetable_slot(
  p_token text,
  p_term_id uuid,
  p_grade_level text,
  p_room text,
  p_day_of_week smallint,
  p_period_no smallint
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
  IF NOT FOUND THEN RAISE EXCEPTION 'invalid_session'; END IF;
  IF v_actor.role not in ('school_admin') THEN RAISE EXCEPTION 'forbidden'; END IF;

  DELETE FROM public.class_schedules cs
  USING public.courses c
  WHERE cs.course_id = c.id
    AND c.school_id = v_actor.school_id
    AND c.term_id = p_term_id
    AND c.grade_level = p_grade_level
    AND public._class_room_key(c.grade_level, c.room) = public._class_room_key(p_grade_level, p_room)
    AND cs.day_of_week = p_day_of_week
    AND cs.period_no = p_period_no;
END;
$$;
