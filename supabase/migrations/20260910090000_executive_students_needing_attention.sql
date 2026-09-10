CREATE OR REPLACE FUNCTION public.list_executive_students_needing_attention(p_token text)
RETURNS TABLE(student_id uuid,student_name text,reason text,detail text,action_label text,severity text)
LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,extensions AS $$
DECLARE v_actor record;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN RAISE EXCEPTION 'invalid_session'; END IF;
  IF v_actor.role NOT IN ('executive','school_admin','super_admin') OR v_actor.school_id IS NULL THEN RAISE EXCEPTION 'forbidden'; END IF;
  RETURN QUERY
  WITH school_courses AS (SELECT id FROM courses WHERE school_id=v_actor.school_id),
  students AS (
    SELECT DISTINCT cs.student_id FROM course_students cs WHERE cs.course_id IN (SELECT id FROM school_courses)
  ), overdue AS (
    SELECT cs.student_id,count(*) AS n FROM course_students cs JOIN assignments a ON a.course_id=cs.course_id
    WHERE cs.course_id IN (SELECT id FROM school_courses) AND a.status='published' AND a.due_at < now()
      AND NOT EXISTS (SELECT 1 FROM submissions s WHERE s.assignment_id=a.id AND s.student_id=cs.student_id)
    GROUP BY cs.student_id
  ), absences AS (
    SELECT student_id,count(*) AS n FROM attendance_records WHERE course_id IN (SELECT id FROM school_courses)
      AND status='absent' AND class_date >= current_date - 30 GROUP BY student_id
  ), low_grades AS (
    SELECT student_id,avg(score/nullif(max_score,0)) AS ratio FROM grades
    WHERE course_id IN (SELECT id FROM school_courses) AND status='confirmed' AND max_score>0
    GROUP BY student_id HAVING avg(score/nullif(max_score,0)) < .5
  )
  SELECT s.student_id,trim(coalesce(u.first_name,'')||' '||coalesce(u.last_name,'')),
    CASE WHEN coalesce(o.n,0)>=2 THEN 'ค้างส่งงาน' WHEN g.ratio IS NOT NULL THEN 'คะแนนเฉลี่ยต่ำ' ELSE 'ขาดเรียนบ่อย' END,
    CASE WHEN coalesce(o.n,0)>=2 THEN 'ค้างส่ง '||o.n||' งาน' WHEN g.ratio IS NOT NULL THEN 'เฉลี่ย '||round(g.ratio*100)||'%' ELSE 'ขาดเรียน '||coalesce(a.n,0)||' ครั้ง (30 วัน)' END,
    CASE WHEN coalesce(o.n,0)>=2 THEN 'ดูงานค้าง' WHEN g.ratio IS NOT NULL THEN 'ดูคะแนน' ELSE 'เช็คชื่อ' END,
    CASE WHEN coalesce(o.n,0)>=3 OR coalesce(a.n,0)>=4 THEN 'urgent' ELSE 'normal' END
  FROM students s JOIN users u ON u.id=s.student_id AND u.school_id=v_actor.school_id
  LEFT JOIN overdue o ON o.student_id=s.student_id LEFT JOIN absences a ON a.student_id=s.student_id LEFT JOIN low_grades g ON g.student_id=s.student_id
  WHERE coalesce(o.n,0)>=2 OR coalesce(a.n,0)>=2 OR g.ratio IS NOT NULL
  ORDER BY u.first_name,u.last_name;
END;
$$;
REVOKE ALL ON FUNCTION public.list_executive_students_needing_attention(text) FROM PUBLIC,service_role;
GRANT EXECUTE ON FUNCTION public.list_executive_students_needing_attention(text) TO anon,authenticated;
NOTIFY pgrst,'reload schema';
