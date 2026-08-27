-- Migration: 20260827060000_homeroom_attendance_system.sql
-- Description: Real homeroom-teacher assignment (ครูประจำชั้น) + homeroom
-- (per-room, non-course) attendance-taking, alongside the pre-existing
-- course-scoped attendance_records/mark_attendance/list_course_attendance.

-- 1. Homeroom teacher assignment table
CREATE TABLE IF NOT EXISTS public.homeroom_assignments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id uuid NOT NULL REFERENCES public.schools(id),
  academic_year_id uuid NOT NULL REFERENCES public.academic_years(id),
  grade_level varchar NOT NULL,
  room varchar NOT NULL,
  teacher_id uuid NOT NULL REFERENCES public.users(id),
  created_by uuid NOT NULL REFERENCES public.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (academic_year_id, grade_level, room, teacher_id)
);

ALTER TABLE public.homeroom_assignments ENABLE ROW LEVEL SECURITY;

-- 2. Homeroom (per-room, not per-course) attendance table
CREATE TABLE IF NOT EXISTS public.homeroom_attendance_records (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  academic_year_id uuid NOT NULL REFERENCES public.academic_years(id),
  grade_level varchar NOT NULL,
  room varchar NOT NULL,
  class_date date NOT NULL,
  status text NOT NULL CHECK (status IN ('present', 'late', 'absent', 'excused')),
  marked_by uuid NOT NULL REFERENCES public.users(id),
  marked_at timestamptz NOT NULL DEFAULT now(),
  note text,
  UNIQUE (student_id, class_date)
);

ALTER TABLE public.homeroom_attendance_records ENABLE ROW LEVEL SECURITY;

-- 3. Internal helper: resolve a school's current academic year.
-- No "active" flag exists on academic_years; this picks the year whose
-- date range covers today, falling back to the most recently started one.
-- Not granted to anon/authenticated — only called from within other
-- SECURITY DEFINER RPCs below (which then run as the owning `postgres` role).
CREATE OR REPLACE FUNCTION public._current_academic_year_id(p_school_id uuid)
RETURNS uuid
LANGUAGE sql
STABLE
SET search_path = public, extensions
AS $$
  SELECT id FROM public.academic_years
  WHERE school_id = p_school_id
  ORDER BY
    (start_date IS NOT NULL AND end_date IS NOT NULL
      AND CURRENT_DATE BETWEEN start_date AND end_date) DESC,
    start_date DESC NULLS LAST
  LIMIT 1;
$$;

REVOKE ALL ON FUNCTION public._current_academic_year_id FROM PUBLIC, anon, authenticated;

-- 4. set_homeroom_teacher (School admin)
CREATE OR REPLACE FUNCTION public.set_homeroom_teacher(
  p_token text,
  p_grade_level text,
  p_room text,
  p_teacher_id uuid
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_year uuid;
  v_id uuid;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  IF v_actor.role NOT IN ('school_admin', 'super_admin') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = p_teacher_id AND school_id = v_actor.school_id AND role = 'teacher'
  ) THEN
    RAISE EXCEPTION 'teacher_not_found';
  END IF;

  v_year := public._current_academic_year_id(v_actor.school_id);
  IF v_year IS NULL THEN
    RAISE EXCEPTION 'no_academic_year';
  END IF;

  INSERT INTO public.homeroom_assignments (
    school_id, academic_year_id, grade_level, room, teacher_id, created_by
  )
  VALUES (v_actor.school_id, v_year, p_grade_level, p_room, p_teacher_id, v_actor.user_id)
  ON CONFLICT (academic_year_id, grade_level, room, teacher_id) DO NOTHING
  RETURNING id INTO v_id;

  IF v_id IS NULL THEN
    SELECT id INTO v_id FROM public.homeroom_assignments
    WHERE academic_year_id = v_year AND grade_level = p_grade_level
      AND room = p_room AND teacher_id = p_teacher_id;
  END IF;

  RETURN v_id;
END;
$$;

-- 5. remove_homeroom_teacher (School admin)
CREATE OR REPLACE FUNCTION public.remove_homeroom_teacher(
  p_token text,
  p_assignment_id uuid
)
RETURNS boolean
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

  DELETE FROM public.homeroom_assignments
  WHERE id = p_assignment_id AND school_id = v_actor.school_id;

  RETURN FOUND;
END;
$$;

-- 6. list_homeroom_assignments (School admin roster of assignments)
CREATE OR REPLACE FUNCTION public.list_homeroom_assignments(p_token text)
RETURNS TABLE (
  assignment_id uuid,
  grade_level text,
  room text,
  teacher_id uuid,
  teacher_name text,
  student_count bigint
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_year uuid;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  IF v_actor.role NOT IN ('school_admin', 'super_admin', 'executive') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  v_year := public._current_academic_year_id(v_actor.school_id);

  RETURN QUERY
  SELECT
    ha.id AS assignment_id,
    ha.grade_level::text,
    ha.room::text,
    ha.teacher_id,
    (u.first_name || ' ' || u.last_name)::text AS teacher_name,
    (SELECT count(*) FROM public.student_profiles sp
       WHERE sp.academic_year_id = ha.academic_year_id
         AND sp.grade_level = ha.grade_level AND sp.room = ha.room) AS student_count
  FROM public.homeroom_assignments ha
  JOIN public.users u ON u.id = ha.teacher_id
  WHERE ha.school_id = v_actor.school_id AND ha.academic_year_id = v_year
  ORDER BY ha.grade_level ASC, ha.room ASC;
END;
$$;

-- 7. list_my_homeroom_classes (Teacher)
CREATE OR REPLACE FUNCTION public.list_my_homeroom_classes(p_token text)
RETURNS TABLE (
  assignment_id uuid,
  grade_level text,
  room text,
  student_count bigint
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_year uuid;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  IF v_actor.role != 'teacher' THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  v_year := public._current_academic_year_id(v_actor.school_id);

  RETURN QUERY
  SELECT
    ha.id AS assignment_id,
    ha.grade_level::text,
    ha.room::text,
    (SELECT count(*) FROM public.student_profiles sp
       WHERE sp.academic_year_id = ha.academic_year_id
         AND sp.grade_level = ha.grade_level AND sp.room = ha.room) AS student_count
  FROM public.homeroom_assignments ha
  WHERE ha.teacher_id = v_actor.user_id AND ha.academic_year_id = v_year
  ORDER BY ha.grade_level ASC, ha.room ASC;
END;
$$;

-- 8. Internal helper: does this actor have access to take/view attendance
-- for this homeroom (assigned teacher, or school_admin/super_admin/executive)?
CREATE OR REPLACE FUNCTION public._assert_homeroom_access(
  v_actor record,
  p_grade_level text,
  p_room text,
  p_year uuid
)
RETURNS void
LANGUAGE plpgsql
STABLE
SET search_path = public, extensions
AS $$
BEGIN
  IF v_actor.role = 'teacher' THEN
    IF NOT EXISTS (
      SELECT 1 FROM public.homeroom_assignments
      WHERE teacher_id = v_actor.user_id AND academic_year_id = p_year
        AND grade_level = p_grade_level AND room = p_room
    ) THEN
      RAISE EXCEPTION 'forbidden';
    END IF;
  ELSIF v_actor.role NOT IN ('school_admin', 'super_admin', 'executive') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public._assert_homeroom_access FROM PUBLIC, anon, authenticated;

-- 9. list_homeroom_roster (Teacher / school admin)
CREATE OR REPLACE FUNCTION public.list_homeroom_roster(
  p_token text,
  p_grade_level text,
  p_room text
)
RETURNS TABLE (
  student_id uuid,
  student_name text,
  student_code text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_year uuid;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;
  v_year := public._current_academic_year_id(v_actor.school_id);

  PERFORM public._assert_homeroom_access(v_actor, p_grade_level, p_room, v_year);

  RETURN QUERY
  SELECT
    u.id AS student_id,
    (u.first_name || ' ' || u.last_name)::text AS student_name,
    coalesce(u.student_code, '')::text AS student_code
  FROM public.student_profiles sp
  JOIN public.users u ON u.id = sp.student_id
  WHERE sp.academic_year_id = v_year
    AND sp.grade_level = p_grade_level AND sp.room = p_room
  ORDER BY u.first_name ASC, u.last_name ASC;
END;
$$;

-- 10. mark_homeroom_attendance (Teacher bulk upsert)
CREATE OR REPLACE FUNCTION public.mark_homeroom_attendance(
  p_token text,
  p_grade_level text,
  p_room text,
  p_class_date date,
  p_records jsonb
)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_year uuid;
  v_rec jsonb;
  v_student_id uuid;
  v_status text;
  v_note text;
  v_count integer := 0;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;
  v_year := public._current_academic_year_id(v_actor.school_id);

  PERFORM public._assert_homeroom_access(v_actor, p_grade_level, p_room, v_year);

  IF jsonb_typeof(p_records) != 'array' THEN
    RAISE EXCEPTION 'invalid_records_format';
  END IF;

  FOR v_rec IN SELECT * FROM jsonb_array_elements(p_records)
  LOOP
    v_student_id := (v_rec->>'student_id')::uuid;
    v_status := v_rec->>'status';
    v_note := v_rec->>'note';

    IF v_status NOT IN ('present', 'late', 'absent', 'excused') THEN
      RAISE EXCEPTION 'invalid_status';
    END IF;

    IF NOT EXISTS (
      SELECT 1 FROM public.student_profiles
      WHERE student_id = v_student_id AND academic_year_id = v_year
        AND grade_level = p_grade_level AND room = p_room
    ) THEN
      RAISE EXCEPTION 'student_not_in_homeroom';
    END IF;

    INSERT INTO public.homeroom_attendance_records (
      student_id, academic_year_id, grade_level, room, class_date, status, marked_by, marked_at, note
    )
    VALUES (
      v_student_id, v_year, p_grade_level, p_room, p_class_date, v_status, v_actor.user_id, now(), v_note
    )
    ON CONFLICT (student_id, class_date)
    DO UPDATE SET
      grade_level = EXCLUDED.grade_level,
      room = EXCLUDED.room,
      status = EXCLUDED.status,
      marked_by = EXCLUDED.marked_by,
      marked_at = now(),
      note = EXCLUDED.note;

    v_count := v_count + 1;
  END LOOP;

  RETURN v_count;
END;
$$;

-- 11. list_homeroom_attendance (Teacher roster view for a date)
CREATE OR REPLACE FUNCTION public.list_homeroom_attendance(
  p_token text,
  p_grade_level text,
  p_room text,
  p_class_date date
)
RETURNS TABLE (
  student_id uuid,
  student_name text,
  student_code text,
  status text,
  note text,
  marked_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_year uuid;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;
  v_year := public._current_academic_year_id(v_actor.school_id);

  PERFORM public._assert_homeroom_access(v_actor, p_grade_level, p_room, v_year);

  RETURN QUERY
  SELECT
    u.id AS student_id,
    (u.first_name || ' ' || u.last_name)::text AS student_name,
    coalesce(u.student_code, '')::text AS student_code,
    har.status,
    har.note,
    har.marked_at
  FROM public.student_profiles sp
  JOIN public.users u ON u.id = sp.student_id
  LEFT JOIN public.homeroom_attendance_records har
    ON har.student_id = sp.student_id AND har.class_date = p_class_date
  WHERE sp.academic_year_id = v_year
    AND sp.grade_level = p_grade_level AND sp.room = p_room
  ORDER BY u.first_name ASC, u.last_name ASC;
END;
$$;

REVOKE ALL ON FUNCTION public.set_homeroom_teacher FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.set_homeroom_teacher TO anon, authenticated;

REVOKE ALL ON FUNCTION public.remove_homeroom_teacher FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.remove_homeroom_teacher TO anon, authenticated;

REVOKE ALL ON FUNCTION public.list_homeroom_assignments FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.list_homeroom_assignments TO anon, authenticated;

REVOKE ALL ON FUNCTION public.list_my_homeroom_classes FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.list_my_homeroom_classes TO anon, authenticated;

REVOKE ALL ON FUNCTION public.list_homeroom_roster FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.list_homeroom_roster TO anon, authenticated;

REVOKE ALL ON FUNCTION public.mark_homeroom_attendance FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.mark_homeroom_attendance TO anon, authenticated;

REVOKE ALL ON FUNCTION public.list_homeroom_attendance FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.list_homeroom_attendance TO anon, authenticated;
