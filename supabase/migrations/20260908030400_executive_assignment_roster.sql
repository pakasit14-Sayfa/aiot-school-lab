CREATE OR REPLACE FUNCTION public.list_school_assignment_roster(p_token text, p_assignment_id uuid)
RETURNS TABLE(student_id uuid, student_name text, submission_status text, submitted_at timestamptz)
LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,extensions AS $$
DECLARE v_actor record; v_course courses%rowtype;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN RAISE EXCEPTION 'invalid_session'; END IF;
  IF v_actor.role NOT IN ('executive','school_admin','super_admin') THEN RAISE EXCEPTION 'forbidden'; END IF;
  SELECT c.* INTO v_course FROM assignments a JOIN courses c ON c.id=a.course_id WHERE a.id=p_assignment_id;
  IF NOT FOUND OR v_course.school_id IS DISTINCT FROM v_actor.school_id THEN RAISE EXCEPTION 'forbidden'; END IF;
  RETURN QUERY
  SELECT cs.student_id,
    trim(coalesce(u.first_name,'') || ' ' || coalesce(u.last_name,'')),
    coalesce(s.status::text,'ยังไม่ส่ง'), s.submitted_at
  FROM course_students cs JOIN users u ON u.id=cs.student_id
  LEFT JOIN submissions s ON s.assignment_id=p_assignment_id AND s.student_id=cs.student_id
  WHERE cs.course_id=v_course.id AND u.status='active'
  ORDER BY u.first_name,u.last_name;
END;
$$;
REVOKE ALL ON FUNCTION public.list_school_assignment_roster(text,uuid) FROM PUBLIC,service_role;
GRANT EXECUTE ON FUNCTION public.list_school_assignment_roster(text,uuid) TO anon,authenticated;
NOTIFY pgrst,'reload schema';
