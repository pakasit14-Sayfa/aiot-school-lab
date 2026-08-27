-- Migration: 20260828000000_students_needing_attention.sql
-- Description: Auto-computed "students needing attention" for the teacher
-- dashboard, distinct from student_support_cases (a teacher-created manual
-- case-tracking system). Flags students in the teacher's own courses on 3
-- real signals: overdue assignments, frequent recent absences, low
-- confirmed-grade average. Chosen over reusing support_cases because the
-- dashboard card is literally named "นักเรียนที่ต้องติดตาม" (students who
-- need following up) — an automatic signal, not a list of cases a teacher
-- happened to remember to open.

CREATE OR REPLACE FUNCTION public.list_students_needing_attention(p_token text)
RETURNS TABLE (
  student_id uuid,
  student_name text,
  reason text,
  detail text,
  action_label text,
  severity text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  IF v_actor.role != 'teacher' THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  RETURN QUERY
  WITH my_courses AS (
    SELECT c.id FROM public.courses c
    JOIN public.course_teachers ct ON ct.course_id = c.id
    WHERE ct.teacher_id = v_actor.user_id
  ),
  my_students AS (
    SELECT DISTINCT cs.student_id
    FROM public.course_students cs
    WHERE cs.course_id IN (SELECT id FROM my_courses)
  ),
  overdue AS (
    SELECT cs.student_id, count(*) AS overdue_count
    FROM public.course_students cs
    JOIN public.assignments a ON a.course_id = cs.course_id
    WHERE cs.course_id IN (SELECT id FROM my_courses)
      AND a.status = 'published'
      AND a.due_at IS NOT NULL AND a.due_at < now()
      AND NOT EXISTS (
        SELECT 1 FROM public.submissions s
        WHERE s.assignment_id = a.id AND s.student_id = cs.student_id
      )
    GROUP BY cs.student_id
  ),
  absences AS (
    SELECT ar.student_id, count(*) AS absent_count
    FROM public.attendance_records ar
    WHERE ar.course_id IN (SELECT id FROM my_courses)
      AND ar.status = 'absent'
      AND ar.class_date >= (current_date - interval '30 days')
    GROUP BY ar.student_id
  ),
  low_grades AS (
    SELECT g.student_id, avg(g.score / NULLIF(g.max_score, 0)) AS avg_ratio
    FROM public.grades g
    WHERE g.course_id IN (SELECT id FROM my_courses)
      AND g.status = 'confirmed'
    GROUP BY g.student_id
    HAVING avg(g.score / NULLIF(g.max_score, 0)) < 0.5
  )
  SELECT
    ms.student_id,
    (u.first_name || ' ' || u.last_name)::text AS student_name,
    (CASE
      WHEN coalesce(o.overdue_count, 0) >= 2 THEN 'ค้างส่งงาน'
      WHEN lg.avg_ratio IS NOT NULL THEN 'คะแนนเฉลี่ยต่ำ'
      ELSE 'ขาดเรียนบ่อย'
    END)::text AS reason,
    (CASE
      WHEN coalesce(o.overdue_count, 0) >= 2 THEN 'ค้างส่ง ' || o.overdue_count || ' งาน'
      WHEN lg.avg_ratio IS NOT NULL THEN 'เฉลี่ย ' || round(lg.avg_ratio * 100) || '%'
      ELSE 'ขาดเรียน ' || ab.absent_count || ' ครั้ง (30 วัน)'
    END)::text AS detail,
    (CASE
      WHEN coalesce(o.overdue_count, 0) >= 2 THEN 'ดูงานค้าง'
      WHEN lg.avg_ratio IS NOT NULL THEN 'ดูคะแนน'
      ELSE 'เช็คชื่อ'
    END)::text AS action_label,
    (CASE
      WHEN coalesce(o.overdue_count, 0) >= 3 OR coalesce(ab.absent_count, 0) >= 4 THEN 'urgent'
      ELSE 'normal'
    END)::text AS severity
  FROM my_students ms
  JOIN public.users u ON u.id = ms.student_id
  LEFT JOIN overdue o ON o.student_id = ms.student_id
  LEFT JOIN absences ab ON ab.student_id = ms.student_id
  LEFT JOIN low_grades lg ON lg.student_id = ms.student_id
  WHERE coalesce(o.overdue_count, 0) >= 2
     OR coalesce(ab.absent_count, 0) >= 2
     OR lg.avg_ratio IS NOT NULL
  ORDER BY
    (CASE WHEN coalesce(o.overdue_count, 0) >= 3 OR coalesce(ab.absent_count, 0) >= 4 THEN 0 ELSE 1 END),
    u.first_name, u.last_name;
END;
$$;

REVOKE ALL ON FUNCTION public.list_students_needing_attention FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.list_students_needing_attention TO anon, authenticated;
