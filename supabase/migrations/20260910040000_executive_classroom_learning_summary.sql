-- Current-year, school-scoped confirmed grade entries. Each valid entry has
-- equal weight after conversion to a percentage; no grades means NULL.
CREATE OR REPLACE FUNCTION public.list_school_classroom_learning_summary(p_token text)
RETURNS TABLE(
  grade_level text,
  room text,
  student_count bigint,
  scored_student_count bigint,
  avg_grade_percent numeric,
  ungraded_student_count bigint
)
LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,extensions AS $$
DECLARE
  v_actor record;
  v_year uuid;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN RAISE EXCEPTION 'invalid_session'; END IF;
  IF v_actor.role NOT IN ('executive','school_admin','super_admin')
     OR v_actor.school_id IS NULL THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  v_year := _current_academic_year_id(v_actor.school_id);
  RETURN QUERY
  WITH valid_grades AS (
    SELECT g.student_id, g.score / g.max_score * 100 AS percent
    FROM grades g
    JOIN courses c ON c.id = g.course_id AND c.school_id = v_actor.school_id
    JOIN terms t ON t.id = c.term_id AND t.academic_year_id = v_year
    WHERE g.status = 'confirmed' AND g.score IS NOT NULL
      AND g.score >= 0 AND g.max_score > 0
  )
  SELECT
    sp.grade_level::text,
    sp.room::text,
    count(DISTINCT sp.student_id),
    count(DISTINCT g.student_id),
    round(avg(g.percent), 2),
    count(DISTINCT sp.student_id) -
      count(DISTINCT g.student_id)
  FROM student_profiles sp
  JOIN users u ON u.id = sp.student_id
    AND u.school_id = v_actor.school_id
    AND u.status = 'active'
  LEFT JOIN valid_grades g ON g.student_id = sp.student_id
  WHERE sp.academic_year_id = v_year
    AND EXISTS (
      SELECT 1 FROM user_roles ur WHERE ur.user_id = sp.student_id
        AND ur.role = 'student' AND ur.school_id = v_actor.school_id
    )
  GROUP BY sp.grade_level, sp.room
  ORDER BY sp.grade_level, sp.room;
END;
$$;

REVOKE ALL ON FUNCTION public.list_school_classroom_learning_summary(text)
  FROM PUBLIC, service_role;
GRANT EXECUTE ON FUNCTION public.list_school_classroom_learning_summary(text)
  TO anon, authenticated;
NOTIFY pgrst, 'reload schema';
