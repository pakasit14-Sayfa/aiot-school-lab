-- Per-assignment submission counts and a bounded history of teacher activity.
CREATE OR REPLACE FUNCTION public.list_school_classroom_work_details(p_token text)
RETURNS TABLE(grade_level text, room text, assignments jsonb, teacher_activities jsonb)
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
    SELECT c.id,c.grade_level::text AS grade_level,c.room::text AS room
    FROM courses c JOIN terms t ON t.id=c.term_id AND t.academic_year_id=v_year
    WHERE c.school_id=v_actor.school_id AND c.grade_level IS NOT NULL AND c.room IS NOT NULL
  ), assignment_rows AS (
    SELECT rc.grade_level,rc.room,a.id,a.title,a.due_at,a.status::text AS status,
      trim(coalesce(u.first_name,'') || ' ' || coalesce(u.last_name,'')) AS teacher,
      count(DISTINCT cs.student_id) AS expected,
      count(DISTINCT s.id) AS submitted, a.created_at
    FROM room_courses rc JOIN assignments a ON a.course_id=rc.id
    LEFT JOIN users u ON u.id=a.created_by
    LEFT JOIN course_students cs ON cs.course_id=rc.id
    LEFT JOIN submissions s ON s.assignment_id=a.id
    GROUP BY rc.grade_level,rc.room,a.id,a.title,a.due_at,a.status,u.first_name,u.last_name,a.created_at
  ), activity_rows AS (
    SELECT rc.grade_level,rc.room,l.created_at,'บทเรียน'::text AS kind,l.title,
      trim(coalesce(u.first_name,'') || ' ' || coalesce(u.last_name,'')) AS teacher
    FROM room_courses rc JOIN lessons l ON l.course_id=rc.id LEFT JOIN users u ON u.id=l.created_by
    UNION ALL
    SELECT rc.grade_level,rc.room,a.created_at,'งาน'::text,a.title,
      trim(coalesce(u.first_name,'') || ' ' || coalesce(u.last_name,''))
    FROM room_courses rc JOIN assignments a ON a.course_id=rc.id LEFT JOIN users u ON u.id=a.created_by
  ), rooms AS (
    SELECT DISTINCT grade_level,room FROM room_courses
  )
  SELECT r.grade_level,r.room,
    coalesce((SELECT jsonb_agg(jsonb_build_object(
      'assignment_id',a.id,'title',a.title,'due_at',a.due_at,'status',a.status,
      'teacher',a.teacher,'expected',a.expected,'submitted',a.submitted,
      'pending',greatest(a.expected-a.submitted,0)) ORDER BY a.due_at NULLS LAST,a.created_at DESC)
      FROM assignment_rows a WHERE a.grade_level=r.grade_level AND a.room=r.room),'[]'::jsonb),
    coalesce((SELECT jsonb_agg(jsonb_build_object(
      'type',x.kind,'title',x.title,'teacher',x.teacher,'created_at',x.created_at)
      ORDER BY x.created_at DESC) FROM (SELECT * FROM activity_rows z
      WHERE z.grade_level=r.grade_level AND z.room=r.room
      ORDER BY z.created_at DESC LIMIT 20) x),'[]'::jsonb)
  FROM rooms r ORDER BY r.grade_level,r.room;
END;
$$;
REVOKE ALL ON FUNCTION public.list_school_classroom_work_details(text) FROM PUBLIC,service_role;
GRANT EXECUTE ON FUNCTION public.list_school_classroom_work_details(text) TO anon,authenticated;
NOTIFY pgrst,'reload schema';
