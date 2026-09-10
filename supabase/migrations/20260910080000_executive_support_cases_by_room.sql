CREATE OR REPLACE FUNCTION public.list_school_support_cases_by_room(p_token text)
RETURNS TABLE(
  grade_level text, room text, case_id uuid, student_id uuid, student_name text,
  student_email text, course_id uuid, course_name text, category text,
  risk_level text, status text, title text, notes text, created_by_name text,
  intervention_count bigint, created_at timestamptz, updated_at timestamptz
)
LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,extensions AS $$
DECLARE v_actor record; v_year uuid;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN RAISE EXCEPTION 'invalid_session'; END IF;
  IF v_actor.role NOT IN ('executive','school_admin','super_admin') OR v_actor.school_id IS NULL THEN RAISE EXCEPTION 'forbidden'; END IF;
  v_year := _current_academic_year_id(v_actor.school_id);
  RETURN QUERY
  SELECT sp.grade_level::text,sp.room::text,c.id,c.student_id,
    trim(coalesce(u.first_name,'') || ' ' || coalesce(u.last_name,'')),u.email::text,
    c.course_id,coalesce(crs.subject_name,'ภาพรวมทั่วไป')::text,c.category::text,c.risk_level::text,c.status::text,
    c.title::text,c.notes::text,trim(coalesce(creator.first_name,'') || ' ' || coalesce(creator.last_name,'')),
    count(i.id),c.created_at,c.updated_at
  FROM student_support_cases c JOIN users u ON u.id=c.student_id AND u.school_id=v_actor.school_id
  JOIN student_profiles sp ON sp.student_id=c.student_id AND sp.academic_year_id=v_year
  JOIN users creator ON creator.id=c.created_by
  LEFT JOIN courses crs ON crs.id=c.course_id
  LEFT JOIN student_support_interventions i ON i.case_id=c.id
  WHERE c.school_id=v_actor.school_id
  GROUP BY sp.grade_level,sp.room,c.id,u.id,creator.id,crs.id
  ORDER BY sp.grade_level,sp.room,c.updated_at DESC;
END;
$$;
REVOKE ALL ON FUNCTION public.list_school_support_cases_by_room(text) FROM PUBLIC,service_role;
GRANT EXECUTE ON FUNCTION public.list_school_support_cases_by_room(text) TO anon,authenticated;
NOTIFY pgrst,'reload schema';
