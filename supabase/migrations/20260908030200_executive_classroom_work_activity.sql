-- Room-scoped assignment/submission and teacher-created learning activity.
CREATE OR REPLACE FUNCTION public.list_school_classroom_work_activity(p_token text)
RETURNS TABLE(
  grade_level text,
  room text,
  assignment_count bigint,
  expected_submission_count bigint,
  submitted_count bigint,
  pending_submission_count bigint,
  last_activity_at timestamptz,
  last_activity_type text,
  last_activity_by text
)
LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,extensions AS $$
DECLARE v_actor record; v_year uuid;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN RAISE EXCEPTION 'invalid_session'; END IF;
  IF v_actor.role NOT IN ('executive','school_admin','super_admin')
     OR v_actor.school_id IS NULL THEN RAISE EXCEPTION 'forbidden'; END IF;
  v_year := _current_academic_year_id(v_actor.school_id);
  RETURN QUERY
  WITH room_courses AS (
    SELECT c.id, c.grade_level::text AS grade_level, c.room::text AS room
    FROM courses c JOIN terms t ON t.id=c.term_id AND t.academic_year_id=v_year
    WHERE c.school_id=v_actor.school_id AND c.grade_level IS NOT NULL AND c.room IS NOT NULL
  ), assignment_rows AS (
    SELECT rc.grade_level, rc.room, a.id, a.created_at, a.title, a.created_by,
      count(DISTINCT cs.student_id) AS expected,
      count(DISTINCT s.id) AS submitted
    FROM room_courses rc JOIN assignments a ON a.course_id=rc.id
    LEFT JOIN course_students cs ON cs.course_id=rc.id
    LEFT JOIN submissions s ON s.assignment_id=a.id
    GROUP BY rc.grade_level,rc.room,a.id,a.created_at,a.title,a.created_by
  ), lesson_rows AS (
    SELECT rc.grade_level,rc.room,l.created_at,l.title,l.created_by
    FROM room_courses rc JOIN lessons l ON l.course_id=rc.id
  ), activities AS (
    SELECT grade_level,room,created_at,'งาน'::text AS kind,created_by FROM assignment_rows
    UNION ALL
    SELECT grade_level,room,created_at,'บทเรียน'::text,created_by FROM lesson_rows
  ), latest AS (
    SELECT DISTINCT ON (a.grade_level,a.room) a.grade_level,a.room,a.created_at,a.kind,
      trim(coalesce(u.first_name,'') || ' ' || coalesce(u.last_name,'')) AS by_name
    FROM activities a LEFT JOIN users u ON u.id=a.created_by
    ORDER BY a.grade_level,a.room,a.created_at DESC NULLS LAST
  )
  SELECT rc.grade_level,rc.room,
    count(DISTINCT ar.id),
    coalesce(sum(ar.expected),0), coalesce(sum(ar.submitted),0),
    greatest(coalesce(sum(ar.expected),0)-coalesce(sum(ar.submitted),0),0),
    l.created_at,l.kind,l.by_name
  FROM room_courses rc LEFT JOIN assignment_rows ar
    ON ar.grade_level=rc.grade_level AND ar.room=rc.room
  LEFT JOIN latest l ON l.grade_level=rc.grade_level AND l.room=rc.room
  GROUP BY rc.grade_level,rc.room,l.created_at,l.kind,l.by_name
  ORDER BY rc.grade_level,rc.room;
END;
$$;
REVOKE ALL ON FUNCTION public.list_school_classroom_work_activity(text) FROM PUBLIC,service_role;
GRANT EXECUTE ON FUNCTION public.list_school_classroom_work_activity(text) TO anon,authenticated;
NOTIFY pgrst,'reload schema';
