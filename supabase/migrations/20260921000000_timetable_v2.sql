-- 20260921000000_timetable_v2.sql
-- Admin timetable, second pass (owner review 2026-09-20: "ควรเป็นแบบทั้งโรงเรียน
-- แล้วเป็น ม.ต้น ม.ปลาย และเป็นห้องเรียน"). Backend pieces for the new
-- school → level → room flow:
--   * school_periods.kind — 'lesson' or 'break' (lunch); breaks render as a
--     grey band and cannot take a subject
--   * list_timetable_overview     — every room in the year with how many of
--                                   its lesson slots are filled
--   * list_teacher_week           — one teacher's slots across all rooms, so
--                                   the slot sheet can warn about clashes
--                                   before saving
--   * list_teacher_conflicts      — school-wide clash list for the overview
--   * admin_copy_room_timetable   — copy a room's week (from another room or
--                                   another term) onto a room
--   * admin_clear_room_timetable  — wipe a room's week
-- The read/write helpers keep matching rooms through _class_room_key.

-- ── periods: lesson vs break ───────────────────────────────────────────
ALTER TABLE public.school_periods
  ADD COLUMN IF NOT EXISTS kind varchar NOT NULL DEFAULT 'lesson';
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'school_periods_kind_check') THEN
    ALTER TABLE public.school_periods
      ADD CONSTRAINT school_periods_kind_check CHECK (kind IN ('lesson', 'break'));
  END IF;
END $$;

CREATE OR REPLACE FUNCTION public.set_school_periods(p_token text, p_periods jsonb)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
    v_actor record;
    v_item jsonb;
    v_no smallint;
    v_start time;
    v_end time;
    v_label varchar;
    v_kind varchar;
    v_prev_end time := NULL;
BEGIN
    SELECT * INTO v_actor FROM get_session_actor(p_token);
    IF NOT FOUND THEN RAISE EXCEPTION 'invalid_session'; END IF;
    IF v_actor.role not in ('school_admin') THEN RAISE EXCEPTION 'forbidden'; END IF;

    DELETE FROM public.school_periods WHERE school_id = v_actor.school_id;

    FOR v_item IN SELECT * FROM jsonb_array_elements(p_periods) ORDER BY (value->>'period_no')::int
    LOOP
        v_no := (v_item->>'period_no')::smallint;
        v_start := (v_item->>'start_time')::time;
        v_end := (v_item->>'end_time')::time;
        v_label := v_item->>'label';
        v_kind := coalesce(v_item->>'kind', 'lesson');

        IF v_kind NOT IN ('lesson', 'break') THEN RAISE EXCEPTION 'invalid_period_kind'; END IF;
        IF v_end <= v_start THEN RAISE EXCEPTION 'invalid_period_time'; END IF;
        IF v_prev_end IS NOT NULL AND v_start < v_prev_end THEN RAISE EXCEPTION 'period_overlap'; END IF;
        v_prev_end := v_end;

        INSERT INTO public.school_periods (school_id, period_no, start_time, end_time, label, kind)
        VALUES (v_actor.school_id, v_no, v_start, v_end, v_label, v_kind);
    END LOOP;
END;
$$;

DROP FUNCTION IF EXISTS public.list_school_periods(text);
CREATE OR REPLACE FUNCTION public.list_school_periods(p_token text)
RETURNS TABLE (
    id uuid,
    period_no smallint,
    start_time time,
    end_time time,
    label varchar,
    kind varchar
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
    SELECT sp.id, sp.period_no, sp.start_time, sp.end_time, sp.label, sp.kind
    FROM public.school_periods sp
    WHERE sp.school_id = v_actor.school_id
    ORDER BY sp.period_no;
END;
$$;
REVOKE ALL ON FUNCTION public.list_school_periods(text) FROM public;
GRANT EXECUTE ON FUNCTION public.list_school_periods(text) TO anon, authenticated;

-- ── slot assignment refuses break periods ──────────────────────────────
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
  v_kind varchar;
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

  SELECT start_time, end_time, kind INTO v_start, v_end, v_kind
  FROM public.school_periods
  WHERE school_id = v_actor.school_id AND period_no = p_period_no;
  IF NOT FOUND THEN RAISE EXCEPTION 'period_not_found'; END IF;
  IF v_kind = 'break' THEN RAISE EXCEPTION 'period_is_break'; END IF;

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

  INSERT INTO public.teacher_subjects (school_id, teacher_id, subject_name, created_by)
  VALUES (v_actor.school_id, p_teacher_id, trim(p_subject_name), v_actor.user_id)
  ON CONFLICT (teacher_id, subject_name) DO NOTHING;

  INSERT INTO public.class_schedules (course_id, day_of_week, period_no, start_time, end_time, created_by)
  VALUES (v_target_course_id, p_day_of_week, p_period_no, v_start, v_end, v_actor.user_id)
  RETURNING id INTO v_schedule_id;

  RETURN QUERY SELECT v_target_course_id, v_schedule_id;
END;
$$;

-- ── overview: every room of the year with fill ratio ───────────────────
CREATE OR REPLACE FUNCTION public.list_timetable_overview(p_token text, p_term_id uuid)
RETURNS TABLE (
  grade_level text,
  room text,
  room_key text,
  student_count bigint,
  filled_slots bigint,
  lesson_slots bigint
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_year uuid;
  v_lessons bigint;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN RAISE EXCEPTION 'invalid_session'; END IF;
  IF v_actor.role NOT IN ('school_admin', 'executive') THEN RAISE EXCEPTION 'forbidden'; END IF;

  SELECT t.academic_year_id INTO v_year
  FROM terms t JOIN academic_years ay ON ay.id = t.academic_year_id
  WHERE t.id = p_term_id AND ay.school_id = v_actor.school_id;
  IF v_year IS NULL THEN RAISE EXCEPTION 'term_not_found'; END IF;

  SELECT count(*) * 5 INTO v_lessons
  FROM public.school_periods sp
  WHERE sp.school_id = v_actor.school_id AND sp.kind = 'lesson';

  RETURN QUERY
  WITH rooms AS (
    SELECT sp.grade_level::text AS grade_level,
           public._class_room_key(sp.grade_level, sp.room) AS room_key,
           min(sp.room)::text AS room,
           count(*)::bigint AS student_count
    FROM public.student_profiles sp
    JOIN public.users u ON u.id = sp.student_id
    WHERE u.school_id = v_actor.school_id AND sp.academic_year_id = v_year
    GROUP BY sp.grade_level, public._class_room_key(sp.grade_level, sp.room)
  ),
  filled AS (
    SELECT c.grade_level::text AS grade_level,
           public._class_room_key(c.grade_level, c.room) AS room_key,
           count(*)::bigint AS filled_slots
    FROM public.class_schedules cs
    JOIN public.courses c ON c.id = cs.course_id
    WHERE c.school_id = v_actor.school_id AND c.term_id = p_term_id AND cs.period_no IS NOT NULL
    GROUP BY c.grade_level, public._class_room_key(c.grade_level, c.room)
  )
  SELECT r.grade_level, r.room, r.room_key, r.student_count,
         coalesce(f.filled_slots, 0)::bigint, v_lessons
  FROM rooms r
  LEFT JOIN filled f ON f.grade_level = r.grade_level AND f.room_key = r.room_key
  ORDER BY r.grade_level, r.room_key;
END;
$$;
REVOKE ALL ON FUNCTION public.list_timetable_overview(text, uuid) FROM public;
GRANT EXECUTE ON FUNCTION public.list_timetable_overview(text, uuid) TO anon, authenticated;

-- ── one teacher's week (for clash warnings in the slot sheet) ──────────
CREATE OR REPLACE FUNCTION public.list_teacher_week(p_token text, p_term_id uuid, p_teacher_id uuid)
RETURNS TABLE (
  day_of_week smallint,
  period_no smallint,
  grade_level text,
  room text,
  subject_name varchar
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
  IF v_actor.role NOT IN ('school_admin', 'executive')
     AND NOT (v_actor.role = 'teacher' AND p_teacher_id = v_actor.user_id) THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  RETURN QUERY
  SELECT cs.day_of_week, cs.period_no, c.grade_level::text,
         public._class_room_key(c.grade_level, c.room), c.subject_name
  FROM public.class_schedules cs
  JOIN public.courses c ON c.id = cs.course_id
  JOIN public.course_teachers ct ON ct.course_id = c.id AND ct.is_owner = true
  WHERE c.school_id = v_actor.school_id
    AND c.term_id = p_term_id
    AND ct.teacher_id = p_teacher_id
    AND cs.period_no IS NOT NULL
  ORDER BY cs.day_of_week, cs.period_no;
END;
$$;
REVOKE ALL ON FUNCTION public.list_teacher_week(text, uuid, uuid) FROM public;
GRANT EXECUTE ON FUNCTION public.list_teacher_week(text, uuid, uuid) TO anon, authenticated;

-- ── school-wide clashes ────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.list_teacher_conflicts(p_token text, p_term_id uuid)
RETURNS TABLE (
  teacher_id uuid,
  teacher_name text,
  day_of_week smallint,
  period_no smallint,
  rooms text[]
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
  IF v_actor.role NOT IN ('school_admin', 'executive') THEN RAISE EXCEPTION 'forbidden'; END IF;

  RETURN QUERY
  SELECT ct.teacher_id,
         (u.first_name || ' ' || u.last_name)::text,
         cs.day_of_week, cs.period_no,
         array_agg(DISTINCT public._class_room_key(c.grade_level, c.room) ORDER BY public._class_room_key(c.grade_level, c.room))
  FROM public.class_schedules cs
  JOIN public.courses c ON c.id = cs.course_id
  JOIN public.course_teachers ct ON ct.course_id = c.id AND ct.is_owner = true
  JOIN public.users u ON u.id = ct.teacher_id
  WHERE c.school_id = v_actor.school_id
    AND c.term_id = p_term_id
    AND cs.period_no IS NOT NULL
  GROUP BY ct.teacher_id, u.first_name, u.last_name, cs.day_of_week, cs.period_no
  HAVING count(DISTINCT public._class_room_key(c.grade_level, c.room)) > 1
  ORDER BY cs.day_of_week, cs.period_no;
END;
$$;
REVOKE ALL ON FUNCTION public.list_teacher_conflicts(text, uuid) FROM public;
GRANT EXECUTE ON FUNCTION public.list_teacher_conflicts(text, uuid) TO anon, authenticated;

-- ── copy / clear a room's week ─────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.admin_clear_room_timetable(
  p_token text, p_term_id uuid, p_grade_level text, p_room text
)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_n integer;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN RAISE EXCEPTION 'invalid_session'; END IF;
  IF v_actor.role not in ('school_admin') THEN RAISE EXCEPTION 'forbidden'; END IF;

  WITH gone AS (
    DELETE FROM public.class_schedules cs
    USING public.courses c
    WHERE cs.course_id = c.id
      AND c.school_id = v_actor.school_id
      AND c.term_id = p_term_id
      AND c.grade_level = p_grade_level
      AND public._class_room_key(c.grade_level, c.room) = public._class_room_key(p_grade_level, p_room)
      AND cs.period_no IS NOT NULL
    RETURNING cs.id
  )
  SELECT count(*) INTO v_n FROM gone;
  RETURN v_n;
END;
$$;
REVOKE ALL ON FUNCTION public.admin_clear_room_timetable(text, uuid, text, text) FROM public;
GRANT EXECUTE ON FUNCTION public.admin_clear_room_timetable(text, uuid, text, text) TO anon, authenticated;

CREATE OR REPLACE FUNCTION public.admin_copy_room_timetable(
  p_token text,
  p_from_term_id uuid, p_from_grade_level text, p_from_room text,
  p_to_term_id uuid, p_to_grade_level text, p_to_room text
)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_slot record;
  v_n integer := 0;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN RAISE EXCEPTION 'invalid_session'; END IF;
  IF v_actor.role not in ('school_admin') THEN RAISE EXCEPTION 'forbidden'; END IF;
  IF p_from_term_id = p_to_term_id
     AND public._class_room_key(p_from_grade_level, p_from_room) = public._class_room_key(p_to_grade_level, p_to_room) THEN
    RAISE EXCEPTION 'same_room';
  END IF;

  PERFORM public.admin_clear_room_timetable(p_token, p_to_term_id, p_to_grade_level, p_to_room);

  FOR v_slot IN
    SELECT cs.day_of_week, cs.period_no, c.subject_name, ct.teacher_id
    FROM public.class_schedules cs
    JOIN public.courses c ON c.id = cs.course_id
    LEFT JOIN public.course_teachers ct ON ct.course_id = c.id AND ct.is_owner = true
    WHERE c.school_id = v_actor.school_id
      AND c.term_id = p_from_term_id
      AND c.grade_level = p_from_grade_level
      AND public._class_room_key(c.grade_level, c.room) = public._class_room_key(p_from_grade_level, p_from_room)
      AND cs.period_no IS NOT NULL
    ORDER BY cs.day_of_week, cs.period_no
  LOOP
    IF v_slot.teacher_id IS NULL THEN CONTINUE; END IF;
    -- a period that no longer exists (or became a break) is skipped, not an error
    IF NOT EXISTS (
      SELECT 1 FROM public.school_periods sp
      WHERE sp.school_id = v_actor.school_id AND sp.period_no = v_slot.period_no AND sp.kind = 'lesson'
    ) THEN CONTINUE; END IF;
    PERFORM public.admin_set_room_timetable_slot(
      p_token, p_to_term_id, p_to_grade_level, p_to_room,
      v_slot.day_of_week, v_slot.period_no, v_slot.subject_name, v_slot.teacher_id
    );
    v_n := v_n + 1;
  END LOOP;
  RETURN v_n;
END;
$$;
REVOKE ALL ON FUNCTION public.admin_copy_room_timetable(text, uuid, text, text, uuid, text, text) FROM public;
GRANT EXECUTE ON FUNCTION public.admin_copy_room_timetable(text, uuid, text, text, uuid, text, text) TO anon, authenticated;
