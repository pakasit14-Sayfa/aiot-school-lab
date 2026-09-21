-- 20260920040000_list_school_classes_text_cast.sql
-- list_school_classes declared grade_level/room as text but RETURN QUERY
-- selected the varchar columns straight from student_profiles; plpgsql
-- rejects that at call time ("structure of query does not match function
-- result type", 42804). No pgTAP called it, so it reached prod and the
-- admin timetable page failed on first load (iPhone, 2026-09-20).
CREATE OR REPLACE FUNCTION public.list_school_classes(p_token text, p_academic_year_id uuid)
RETURNS TABLE (
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
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN RAISE EXCEPTION 'invalid_session'; END IF;
  IF v_actor.role NOT IN ('school_admin', 'teacher', 'executive') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  RETURN QUERY
  SELECT sp.grade_level::text, sp.room::text, count(*)::bigint AS student_count
  FROM public.student_profiles sp
  JOIN public.users u ON u.id = sp.student_id
  WHERE u.school_id = v_actor.school_id
    AND sp.academic_year_id = p_academic_year_id
  GROUP BY sp.grade_level, sp.room
  ORDER BY sp.grade_level, sp.room;
END;
$$;
