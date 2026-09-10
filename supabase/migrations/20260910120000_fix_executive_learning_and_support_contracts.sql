-- Repair the Executive classroom work and automatic student-support reads.
-- This is a forward-only correction for the already-applied 20260908030200,
-- 20260908030300, 20260908030600 and 20260908030700 migrations.

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
    FROM courses c
    JOIN terms t ON t.id=c.term_id AND t.academic_year_id=v_year
    WHERE c.school_id=v_actor.school_id
      AND c.grade_level IS NOT NULL AND c.room IS NOT NULL
  ), rooms AS (
    SELECT DISTINCT rc.grade_level,rc.room FROM room_courses rc
  ), assignment_base AS (
    SELECT rc.grade_level,rc.room,rc.id AS course_id,a.id,a.created_at,a.created_by
    FROM room_courses rc JOIN assignments a ON a.course_id=rc.id
  ), assignment_stats AS (
    SELECT ab.id,
      count(DISTINCT cs.student_id) FILTER (WHERE u.status='active')::bigint AS expected,
      count(DISTINCT cs.student_id) FILTER (
        WHERE u.status='active' AND EXISTS (
          SELECT 1 FROM submissions sub
          WHERE sub.assignment_id=ab.id
            AND (
              sub.student_id=cs.student_id OR
              (sub.group_id IS NOT NULL AND EXISTS (
                SELECT 1 FROM group_members gm
                WHERE gm.group_id=sub.group_id AND gm.student_id=cs.student_id
              ))
            )
        )
      )::bigint AS submitted
    FROM assignment_base ab
    LEFT JOIN course_students cs ON cs.course_id=ab.course_id
    LEFT JOIN users u ON u.id=cs.student_id
    GROUP BY ab.id
  ), assignment_rows AS (
    SELECT ab.grade_level,ab.room,ab.id,ab.created_at,ab.created_by,
      coalesce(ast.expected,0)::bigint AS expected,
      coalesce(ast.submitted,0)::bigint AS submitted
    FROM assignment_base ab LEFT JOIN assignment_stats ast ON ast.id=ab.id
  ), activities AS (
    SELECT ar.grade_level,ar.room,ar.created_at AS occurred_at,
      'งาน'::text AS kind,ar.created_by
    FROM assignment_rows ar
    UNION ALL
    SELECT rc.grade_level,rc.room,coalesce(l.published_at,l.updated_at) AS occurred_at,
      'บทเรียน'::text,l.created_by
    FROM room_courses rc JOIN lessons l ON l.course_id=rc.id
  ), latest AS (
    SELECT DISTINCT ON (a.grade_level,a.room)
      a.grade_level,a.room,a.occurred_at,a.kind,
      trim(coalesce(u.first_name,'') || ' ' || coalesce(u.last_name,'')) AS by_name
    FROM activities a LEFT JOIN users u ON u.id=a.created_by
    ORDER BY a.grade_level,a.room,a.occurred_at DESC NULLS LAST
  ), room_totals AS (
    SELECT r.grade_level,r.room,
      count(ar.id)::bigint AS assignments,
      coalesce(sum(ar.expected),0)::bigint AS expected,
      coalesce(sum(ar.submitted),0)::bigint AS submitted
    FROM rooms r LEFT JOIN assignment_rows ar
      ON ar.grade_level=r.grade_level AND ar.room=r.room
    GROUP BY r.grade_level,r.room
  )
  SELECT rt.grade_level,rt.room,rt.assignments,rt.expected,rt.submitted,
    greatest(rt.expected-rt.submitted,0)::bigint,
    l.occurred_at,l.kind,l.by_name
  FROM room_totals rt LEFT JOIN latest l
    ON l.grade_level=rt.grade_level AND l.room=rt.room
  ORDER BY rt.grade_level,rt.room;
END;
$$;

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
    WHERE c.school_id=v_actor.school_id
      AND c.grade_level IS NOT NULL AND c.room IS NOT NULL
  ), rooms AS (
    SELECT DISTINCT rc.grade_level,rc.room FROM room_courses rc
  ), assignment_base AS (
    SELECT rc.grade_level,rc.room,rc.id AS course_id,a.id,a.title,a.instructions,
      a.due_at,a.status::text AS status,a.is_group,a.created_at,a.created_by
    FROM room_courses rc JOIN assignments a ON a.course_id=rc.id
  ), assignment_stats AS (
    SELECT ab.id,
      count(DISTINCT cs.student_id) FILTER (WHERE u.status='active')::bigint AS expected,
      count(DISTINCT cs.student_id) FILTER (
        WHERE u.status='active' AND EXISTS (
          SELECT 1 FROM submissions sub
          WHERE sub.assignment_id=ab.id
            AND (
              sub.student_id=cs.student_id OR
              (sub.group_id IS NOT NULL AND EXISTS (
                SELECT 1 FROM group_members gm
                WHERE gm.group_id=sub.group_id AND gm.student_id=cs.student_id
              ))
            )
        )
      )::bigint AS submitted
    FROM assignment_base ab
    LEFT JOIN course_students cs ON cs.course_id=ab.course_id
    LEFT JOIN users u ON u.id=cs.student_id
    GROUP BY ab.id
  ), assignment_rows AS (
    SELECT ab.*,
      trim(coalesce(u.first_name,'') || ' ' || coalesce(u.last_name,'')) AS teacher,
      coalesce(ast.expected,0)::bigint AS expected,
      coalesce(ast.submitted,0)::bigint AS submitted
    FROM assignment_base ab
    LEFT JOIN users u ON u.id=ab.created_by
    LEFT JOIN assignment_stats ast ON ast.id=ab.id
  ), activity_rows AS (
    SELECT rc.grade_level,rc.room,coalesce(l.published_at,l.updated_at) AS occurred_at,
      'บทเรียน'::text AS kind,l.title,
      trim(coalesce(u.first_name,'') || ' ' || coalesce(u.last_name,'')) AS teacher
    FROM room_courses rc JOIN lessons l ON l.course_id=rc.id
    LEFT JOIN users u ON u.id=l.created_by
    UNION ALL
    SELECT ab.grade_level,ab.room,ab.created_at,'งาน'::text,ab.title,
      trim(coalesce(u.first_name,'') || ' ' || coalesce(u.last_name,''))
    FROM assignment_base ab LEFT JOIN users u ON u.id=ab.created_by
  )
  SELECT r.grade_level,r.room,
    coalesce((SELECT jsonb_agg(jsonb_build_object(
      'assignment_id',a.id,'title',a.title,'instructions',a.instructions,
      'due_at',a.due_at,'status',a.status,'is_group',a.is_group,
      'created_at',a.created_at,'teacher',a.teacher,
      'expected',a.expected,'submitted',a.submitted,
      'pending',greatest(a.expected-a.submitted,0)::bigint)
      ORDER BY a.due_at NULLS LAST,a.created_at DESC)
      FROM assignment_rows a
      WHERE a.grade_level=r.grade_level AND a.room=r.room),'[]'::jsonb),
    coalesce((SELECT jsonb_agg(jsonb_build_object(
      'type',x.kind,'title',x.title,'teacher',x.teacher,'created_at',x.occurred_at)
      ORDER BY x.occurred_at DESC)
      FROM (SELECT z.* FROM activity_rows z
        WHERE z.grade_level=r.grade_level AND z.room=r.room
        ORDER BY z.occurred_at DESC NULLS LAST LIMIT 20) x),'[]'::jsonb)
  FROM rooms r ORDER BY r.grade_level,r.room;
END;
$$;

CREATE OR REPLACE FUNCTION public.list_executive_students_needing_attention(p_token text)
RETURNS TABLE(student_id uuid,student_name text,reason text,detail text,action_label text,severity text)
LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,extensions AS $$
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
  )
  SELECT st.id,trim(coalesce(u.first_name,'')||' '||coalesce(u.last_name,'')),
    CASE WHEN coalesce(o.n,0)>=2 THEN 'ค้างส่งงาน'
         WHEN g.ratio IS NOT NULL THEN 'คะแนนเฉลี่ยต่ำ' ELSE 'ขาดเรียนบ่อย' END,
    CASE WHEN coalesce(o.n,0)>=2 THEN 'ค้างส่ง '||o.n||' งาน'
         WHEN g.ratio IS NOT NULL THEN 'เฉลี่ย '||round(g.ratio*100)||'%'
         ELSE 'ขาดเรียน '||coalesce(ab.n,0)||' ครั้ง (30 วัน)' END,
    CASE WHEN coalesce(o.n,0)>=2 THEN 'ดูงานค้าง'
         WHEN g.ratio IS NOT NULL THEN 'ดูคะแนน' ELSE 'เช็คชื่อ' END,
    CASE WHEN coalesce(o.n,0)>=3 OR coalesce(ab.n,0)>=4 THEN 'urgent' ELSE 'normal' END
  FROM students st
  JOIN users u ON u.id=st.id AND u.school_id=v_actor.school_id AND u.status='active'
  LEFT JOIN overdue o ON o.id=st.id
  LEFT JOIN absences ab ON ab.id=st.id
  LEFT JOIN low_grades g ON g.id=st.id
  WHERE coalesce(o.n,0)>=2 OR coalesce(ab.n,0)>=2 OR g.ratio IS NOT NULL
  ORDER BY u.first_name,u.last_name;
END;
$$;

CREATE OR REPLACE FUNCTION public.open_executive_support_case_from_flag(
  p_token text,p_student_id uuid,p_reason text,p_detail text,p_action_label text,p_severity text
) RETURNS TABLE(case_id uuid,created boolean)
LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,extensions AS $$
DECLARE
  v_actor record; v_case uuid; v_title text; v_reason text;
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

REVOKE ALL ON FUNCTION public.list_school_classroom_work_activity(text) FROM PUBLIC,service_role;
REVOKE ALL ON FUNCTION public.list_school_classroom_work_details(text) FROM PUBLIC,service_role;
REVOKE ALL ON FUNCTION public.list_executive_students_needing_attention(text) FROM PUBLIC,service_role;
REVOKE ALL ON FUNCTION public.open_executive_support_case_from_flag(text,uuid,text,text,text,text) FROM PUBLIC,service_role;
GRANT EXECUTE ON FUNCTION public.list_school_classroom_work_activity(text) TO anon,authenticated;
GRANT EXECUTE ON FUNCTION public.list_school_classroom_work_details(text) TO anon,authenticated;
GRANT EXECUTE ON FUNCTION public.list_executive_students_needing_attention(text) TO anon,authenticated;
GRANT EXECUTE ON FUNCTION public.open_executive_support_case_from_flag(text,uuid,text,text,text,text) TO anon,authenticated;
NOTIFY pgrst,'reload schema';
