CREATE OR REPLACE FUNCTION public.open_executive_support_case_from_flag(
  p_token text,p_student_id uuid,p_reason text,p_detail text,p_action_label text,p_severity text
) RETURNS TABLE(case_id uuid,created boolean)
LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,extensions AS $$
DECLARE v_actor record; v_case uuid; v_title text;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN RAISE EXCEPTION 'invalid_session'; END IF;
  IF v_actor.role NOT IN ('executive','school_admin','super_admin') THEN RAISE EXCEPTION 'forbidden'; END IF;
  IF NOT EXISTS (SELECT 1 FROM users WHERE id=p_student_id AND school_id=v_actor.school_id AND status='active') THEN RAISE EXCEPTION 'student_not_found'; END IF;
  v_title := trim(coalesce(p_reason,'สัญญาณที่ควรติดตาม')||': '||coalesce(p_detail,''));
  SELECT id INTO v_case FROM student_support_cases WHERE school_id=v_actor.school_id AND student_id=p_student_id
    AND status IN ('open','in_progress') AND title=v_title ORDER BY updated_at DESC LIMIT 1;
  IF v_case IS NOT NULL THEN RETURN QUERY SELECT v_case,false; RETURN; END IF;
  INSERT INTO student_support_cases(school_id,student_id,category,risk_level,status,title,notes,created_by)
  VALUES(v_actor.school_id,p_student_id,'academic',CASE WHEN p_severity='urgent' THEN 'high' ELSE 'medium' END,'open',v_title,p_action_label,v_actor.user_id)
  RETURNING id INTO v_case;
  RETURN QUERY SELECT v_case,true;
END;
$$;
REVOKE ALL ON FUNCTION public.open_executive_support_case_from_flag(text,uuid,text,text,text,text) FROM PUBLIC,service_role;
GRANT EXECUTE ON FUNCTION public.open_executive_support_case_from_flag(text,uuid,text,text,text,text) TO anon,authenticated;
NOTIFY pgrst,'reload schema';
