-- Executive watchlist cards (director_learning_page.dart) need the flagged
-- student's grade/room and homeroom advisor name to match the day-7
-- reference design. Neither was in the original function's return shape, so
-- this can't be a CREATE OR REPLACE (Postgres rejects changing a TABLE
-- function's result columns in place) -- drop and recreate.
DROP FUNCTION IF EXISTS public.list_executive_students_needing_attention(text);

CREATE FUNCTION public.list_executive_students_needing_attention(p_token text)
RETURNS TABLE(
  student_id uuid, student_name text, reason text, detail text,
  action_label text, severity text,
  grade_level text, room text, advisor_name text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'extensions'
AS $function$
DECLARE v_actor record; v_year uuid;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN RAISE EXCEPTION 'invalid_session'; END IF;
  IF v_actor.role NOT IN ('executive','school_admin','super_admin')
     OR v_actor.school_id IS NULL THEN RAISE EXCEPTION 'forbidden'; END IF;
  v_year := _current_academic_year_id(v_actor.school_id);

  RETURN QUERY
  WITH school_courses AS (
    SELECT c.id FROM courses c
    JOIN terms t ON t.id=c.term_id AND t.academic_year_id=v_year
    WHERE c.school_id=v_actor.school_id
  ), students AS (
    SELECT DISTINCT cs.student_id AS id
    FROM course_students cs JOIN school_courses sc ON sc.id=cs.course_id
  ), overdue AS (
    SELECT cs.student_id AS id,count(*) AS n
    FROM course_students cs
    JOIN school_courses sc ON sc.id=cs.course_id
    JOIN assignments a ON a.course_id=cs.course_id
    WHERE a.status='published' AND a.due_at < now()
      AND NOT EXISTS (
        SELECT 1 FROM submissions sub
        WHERE sub.assignment_id=a.id
          AND (
            sub.student_id=cs.student_id OR
            (sub.group_id IS NOT NULL AND EXISTS (
              SELECT 1 FROM group_members gm
              WHERE gm.group_id=sub.group_id AND gm.student_id=cs.student_id
            ))
          )
      )
    GROUP BY cs.student_id
  ), absences AS (
    SELECT ar.student_id AS id,count(*) AS n
    FROM attendance_records ar JOIN school_courses sc ON sc.id=ar.course_id
    WHERE ar.status='absent' AND ar.class_date >= current_date - 30
    GROUP BY ar.student_id
  ), low_grades AS (
    SELECT g.student_id AS id,avg(g.score/nullif(g.max_score,0)) AS ratio
    FROM grades g JOIN school_courses sc ON sc.id=g.course_id
    WHERE g.status='confirmed' AND g.score IS NOT NULL AND g.max_score>0
    GROUP BY g.student_id
    HAVING avg(g.score/nullif(g.max_score,0)) < .5
  ), profile AS (
    SELECT sp.student_id AS id, sp.grade_level, sp.room
    FROM student_profiles sp
    WHERE sp.academic_year_id = v_year
  ), advisor AS (
    SELECT ha.grade_level, ha.room,
      trim(coalesce(tu.first_name,'')||' '||coalesce(tu.last_name,'')) AS advisor_name
    FROM homeroom_assignments ha
    JOIN users tu ON tu.id = ha.teacher_id
    WHERE ha.academic_year_id = v_year AND ha.school_id = v_actor.school_id
  )
  SELECT st.id,trim(coalesce(u.first_name,'')||' '||coalesce(u.last_name,'')),
    CASE WHEN coalesce(o.n,0)>=2 THEN 'ค้างส่งงาน'
         WHEN g.ratio IS NOT NULL THEN 'คะแนนเฉลี่ยต่ำ' ELSE 'ขาดเรียนบ่อย' END,
    CASE WHEN coalesce(o.n,0)>=2 THEN 'ค้างส่ง '||o.n||' งาน'
         WHEN g.ratio IS NOT NULL THEN 'เฉลี่ย '||round(g.ratio*100)||'%'
         ELSE 'ขาดเรียน '||coalesce(ab.n,0)||' ครั้ง (30 วัน)' END,
    CASE WHEN coalesce(o.n,0)>=2 THEN 'ดูงานค้าง'
         WHEN g.ratio IS NOT NULL THEN 'ดูคะแนน' ELSE 'เช็คชื่อ' END,
    CASE WHEN coalesce(o.n,0)>=3 OR coalesce(ab.n,0)>=4 THEN 'urgent' ELSE 'normal' END,
    p.grade_level::text, p.room::text, adv.advisor_name
  FROM students st
  JOIN users u ON u.id=st.id AND u.school_id=v_actor.school_id AND u.status='active'
  LEFT JOIN overdue o ON o.id=st.id
  LEFT JOIN absences ab ON ab.id=st.id
  LEFT JOIN low_grades g ON g.id=st.id
  LEFT JOIN profile p ON p.id=st.id
  LEFT JOIN advisor adv ON adv.grade_level=p.grade_level AND adv.room=p.room
  WHERE coalesce(o.n,0)>=2 OR coalesce(ab.n,0)>=2 OR g.ratio IS NOT NULL
  ORDER BY u.first_name,u.last_name;
END;
$function$;

REVOKE ALL ON FUNCTION public.list_executive_students_needing_attention(text) FROM PUBLIC,service_role;
GRANT EXECUTE ON FUNCTION public.list_executive_students_needing_attention(text) TO anon,authenticated;
