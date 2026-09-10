-- Daily homeroom attendance for the school's currently active students.
-- Missing marks are unknown; course attendance is a separate domain.
CREATE OR REPLACE FUNCTION public.list_school_homeroom_attendance(p_token text,p_class_date date)
RETURNS TABLE(grade_level text,room text,student_count bigint,present_count bigint,
 late_count bigint,absent_count bigint,excused_count bigint,unknown_count bigint)
LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,extensions AS $$
DECLARE v_actor record; v_year uuid;
BEGIN
 SELECT * INTO v_actor FROM get_session_actor(p_token);
 IF NOT FOUND THEN RAISE EXCEPTION 'invalid_session'; END IF;
 IF v_actor.role NOT IN ('executive','school_admin','super_admin') OR v_actor.school_id IS NULL
 THEN RAISE EXCEPTION 'forbidden'; END IF;
 IF p_class_date IS NULL THEN RAISE EXCEPTION 'date_required'; END IF;
 v_year := _current_academic_year_id(v_actor.school_id);
 RETURN QUERY
 SELECT sp.grade_level::text,sp.room::text,count(*),
  count(*) FILTER(WHERE a.status='present'),count(*) FILTER(WHERE a.status='late'),
  count(*) FILTER(WHERE a.status='absent'),count(*) FILTER(WHERE a.status='excused'),
  count(*) FILTER(WHERE a.id IS NULL)
 FROM users u
 LEFT JOIN student_profiles sp ON sp.student_id=u.id AND sp.academic_year_id=v_year
 LEFT JOIN homeroom_attendance_records a ON a.student_id=u.id AND a.class_date=p_class_date
 WHERE u.school_id=v_actor.school_id AND u.status='active'
  AND EXISTS(SELECT 1 FROM user_roles ur WHERE ur.user_id=u.id AND ur.school_id=v_actor.school_id AND ur.role='student')
 GROUP BY sp.grade_level,sp.room ORDER BY sp.grade_level,sp.room;
END;
$$;

-- The live definition still used the admin-only helper despite an earlier
-- widened definition in the same historical migration. Keep this a read gate.
CREATE OR REPLACE FUNCTION public.list_learning_track_rooms(p_token text)
RETURNS TABLE(grade_level varchar,room varchar,student_count bigint,track_id uuid,track_name varchar)
LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,extensions AS $$
DECLARE v_actor record; v_year uuid;
BEGIN
 SELECT * INTO v_actor FROM get_session_actor(p_token);
 IF NOT FOUND THEN RAISE EXCEPTION 'invalid_session'; END IF;
 IF v_actor.role NOT IN ('school_admin','executive','super_admin') THEN RAISE EXCEPTION 'forbidden'; END IF;
 v_year := _current_academic_year_id(v_actor.school_id);
 RETURN QUERY
 SELECT sp.grade_level,sp.room,count(DISTINCT sp.student_id),a.track_id,lt.name
 FROM student_profiles sp
 JOIN users u ON u.id=sp.student_id AND u.school_id=v_actor.school_id
 LEFT JOIN learning_track_room_assignments a ON a.academic_year_id=sp.academic_year_id
  AND a.grade_level=sp.grade_level AND a.room=sp.room
 LEFT JOIN learning_tracks lt ON lt.id=a.track_id
 WHERE sp.academic_year_id=v_year
 GROUP BY sp.grade_level,sp.room,a.track_id,lt.name ORDER BY sp.grade_level,sp.room;
END;
$$;

CREATE OR REPLACE FUNCTION public.list_student_support_cases(
 p_token text,p_course_id uuid DEFAULT NULL,p_status text DEFAULT NULL)
RETURNS TABLE(case_id uuid,student_id uuid,student_name text,student_email text,course_id uuid,
 course_name text,category text,risk_level text,status text,title text,notes text,
 created_by_name text,intervention_count bigint,created_at timestamptz,updated_at timestamptz)
LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,extensions AS $$
DECLARE v_actor record;
BEGIN
 SELECT * INTO v_actor FROM get_session_actor(p_token);
 IF NOT FOUND THEN RAISE EXCEPTION 'invalid_session'; END IF;
 IF v_actor.role NOT IN ('teacher','school_admin','executive') THEN RAISE EXCEPTION 'forbidden'; END IF;
 RETURN QUERY
 SELECT c.id,c.student_id,trim(coalesce(u.first_name,'') || ' ' || coalesce(u.last_name,'')),
  u.email::text,c.course_id,coalesce(crs.subject_name,'ภาพรวมทั่วไป')::text,c.category::text,c.risk_level::text,c.status::text,
  c.title::text,c.notes::text,trim(coalesce(creator.first_name,'') || ' ' || coalesce(creator.last_name,'')),
  count(i.id),c.created_at,c.updated_at
 FROM student_support_cases c JOIN users u ON u.id=c.student_id
 JOIN users creator ON creator.id=c.created_by
 LEFT JOIN courses crs ON crs.id=c.course_id
 LEFT JOIN student_support_interventions i ON i.case_id=c.id
 WHERE c.school_id=v_actor.school_id
  AND (p_course_id IS NULL OR c.course_id=p_course_id) AND (p_status IS NULL OR c.status=p_status)
 GROUP BY c.id,u.id,creator.id,crs.id
 ORDER BY CASE c.risk_level WHEN 'high' THEN 1 WHEN 'medium' THEN 2 ELSE 3 END,c.updated_at DESC;
END;
$$;

CREATE OR REPLACE FUNCTION public.list_student_support_interventions(p_token text,p_case_id uuid)
RETURNS TABLE(intervention_id uuid,case_id uuid,action_type text,notes text,recorded_by_name text,created_at timestamptz)
LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,extensions AS $$
DECLARE v_actor record;
BEGIN
 SELECT * INTO v_actor FROM get_session_actor(p_token);
 IF NOT FOUND THEN RAISE EXCEPTION 'invalid_session'; END IF;
 IF v_actor.role NOT IN ('teacher','school_admin','executive')
  OR NOT EXISTS(SELECT 1 FROM student_support_cases c WHERE c.id=p_case_id AND c.school_id=v_actor.school_id)
 THEN RAISE EXCEPTION 'forbidden'; END IF;
 RETURN QUERY SELECT i.id,i.case_id,i.action_type,i.notes,
  trim(coalesce(u.first_name,'') || ' ' || coalesce(u.last_name,'')),i.created_at
 FROM student_support_interventions i JOIN users u ON u.id=i.recorded_by
 WHERE i.case_id=p_case_id ORDER BY i.created_at DESC;
END;
$$;
REVOKE ALL ON FUNCTION public.list_school_homeroom_attendance(text,date) FROM PUBLIC,service_role;
GRANT EXECUTE ON FUNCTION public.list_school_homeroom_attendance(text,date) TO anon,authenticated;
REVOKE ALL ON FUNCTION public.list_learning_track_rooms(text) FROM PUBLIC,service_role;
GRANT EXECUTE ON FUNCTION public.list_learning_track_rooms(text) TO anon,authenticated;
REVOKE ALL ON FUNCTION public.list_student_support_cases(text,uuid,text) FROM PUBLIC,service_role;
GRANT EXECUTE ON FUNCTION public.list_student_support_cases(text,uuid,text) TO anon,authenticated;
REVOKE ALL ON FUNCTION public.list_student_support_interventions(text,uuid) FROM PUBLIC,service_role;
GRANT EXECUTE ON FUNCTION public.list_student_support_interventions(text,uuid) TO anon,authenticated;
-- A null-extended LEFT JOIN row is not a classroom.
CREATE OR REPLACE FUNCTION public.get_learning_track_overview(p_token text)
RETURNS TABLE(track_id uuid,name varchar,color varchar,sort_order integer,
 student_count bigint,room_count bigint,avg_grade_percent numeric)
LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,extensions AS $$
DECLARE v_actor record; v_year uuid;
BEGIN
 SELECT * INTO v_actor FROM get_session_actor(p_token);
 IF NOT FOUND THEN RAISE EXCEPTION 'invalid_session'; END IF;
 IF v_actor.role NOT IN ('school_admin','executive','super_admin') THEN RAISE EXCEPTION 'forbidden'; END IF;
 v_year := _current_academic_year_id(v_actor.school_id);
 RETURN QUERY
 WITH track_students AS (
  SELECT a.track_id,sp.student_id,sp.grade_level,sp.room
  FROM learning_track_room_assignments a JOIN student_profiles sp
   ON sp.academic_year_id=a.academic_year_id AND sp.grade_level=a.grade_level AND sp.room=a.room
  WHERE a.academic_year_id=v_year
 ), track_grades AS (
  SELECT ts.track_id,avg(g.score/nullif(g.max_score,0))*100 AS avg_percent
  FROM track_students ts JOIN grades g ON g.student_id=ts.student_id AND g.status='confirmed'
  WHERE g.max_score IS NOT NULL AND g.max_score>0 GROUP BY ts.track_id
 )
 SELECT lt.id,lt.name,lt.color,lt.sort_order,count(DISTINCT ts.student_id),
  count(DISTINCT (ts.grade_level,ts.room)) FILTER (WHERE ts.student_id IS NOT NULL),
  tg.avg_percent
 FROM learning_tracks lt LEFT JOIN track_students ts ON ts.track_id=lt.id
 LEFT JOIN track_grades tg ON tg.track_id=lt.id
 WHERE lt.school_id=v_actor.school_id
 GROUP BY lt.id,lt.name,lt.color,lt.sort_order,tg.avg_percent
 ORDER BY lt.sort_order,lt.created_at;
END;
$$;
REVOKE ALL ON FUNCTION public.get_learning_track_overview(text) FROM PUBLIC,service_role;
GRANT EXECUTE ON FUNCTION public.get_learning_track_overview(text) TO anon,authenticated;
NOTIFY pgrst,'reload schema';
