-- Serialize case creation for the same school, student and signal reason.
-- Without this lock, two concurrent requests can both pass the active-case
-- lookup before either insert commits.
CREATE OR REPLACE FUNCTION public.open_executive_support_case_from_flag(
  p_token text,p_student_id uuid,p_reason text,p_detail text,p_action_label text,p_severity text
) RETURNS TABLE(case_id uuid,created boolean)
LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,extensions AS $$
DECLARE
  v_actor record; v_case uuid; v_title text; v_reason text; v_lock_key text;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN RAISE EXCEPTION 'invalid_session'; END IF;
  IF v_actor.role NOT IN ('executive','school_admin','super_admin')
     OR v_actor.school_id IS NULL THEN RAISE EXCEPTION 'forbidden'; END IF;
  IF NOT EXISTS (
    SELECT 1 FROM users u
    WHERE u.id=p_student_id AND u.school_id=v_actor.school_id
      AND u.status='active'
  ) THEN RAISE EXCEPTION 'student_not_found'; END IF;

  v_reason := coalesce(nullif(trim(p_reason),''),'สัญญาณที่ควรติดตาม');
  v_title := v_reason || ': ' || coalesce(trim(p_detail),'');
  v_lock_key := v_actor.school_id::text || '|' || p_student_id::text || '|' || v_reason;
  PERFORM pg_advisory_xact_lock(hashtextextended(v_lock_key,0));

  SELECT c.id INTO v_case
  FROM student_support_cases c
  WHERE c.school_id=v_actor.school_id AND c.student_id=p_student_id
    AND c.category='academic' AND c.status IN ('open','in_progress')
    AND trim(split_part(c.title,':',1))=v_reason
  ORDER BY c.updated_at DESC LIMIT 1;

  IF v_case IS NOT NULL THEN
    UPDATE student_support_cases c
    SET title=v_title,
        notes=nullif(trim(p_action_label),''),
        risk_level=CASE WHEN p_severity='urgent' THEN 'high' ELSE c.risk_level END,
        updated_at=now()
    WHERE c.id=v_case;
    RETURN QUERY SELECT v_case,false;
    RETURN;
  END IF;

  INSERT INTO student_support_cases(
    school_id,student_id,category,risk_level,status,title,notes,created_by
  ) VALUES (
    v_actor.school_id,p_student_id,'academic',
    CASE WHEN p_severity='urgent' THEN 'high' ELSE 'medium' END,
    'open',v_title,nullif(trim(p_action_label),''),v_actor.user_id
  ) RETURNING id INTO v_case;
  RETURN QUERY SELECT v_case,true;
END;
$$;

REVOKE ALL ON FUNCTION public.open_executive_support_case_from_flag(text,uuid,text,text,text,text)
  FROM PUBLIC,service_role;
GRANT EXECUTE ON FUNCTION public.open_executive_support_case_from_flag(text,uuid,text,text,text,text)
  TO anon,authenticated;
NOTIFY pgrst,'reload schema';
