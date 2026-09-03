-- Seed Grades and Assignments for mock testing
DO $$
DECLARE
  v_student_id uuid;
  v_school_id uuid;
  v_course_id_math uuid;
  v_course_id_science uuid;
BEGIN
  -- Get the mock student
  SELECT id, school_id INTO v_student_id, v_school_id 
  FROM users 
  WHERE email = 'student@aiot-school-lab.local' LIMIT 1;
  
  IF v_student_id IS NOT NULL THEN
    -- Find or create some courses
    SELECT id INTO v_course_id_math FROM courses WHERE school_id = v_school_id AND subject_name = 'คณิตศาสตร์' LIMIT 1;
    SELECT id INTO v_course_id_science FROM courses WHERE school_id = v_school_id AND subject_name = 'วิทยาศาสตร์' LIMIT 1;
    
    IF v_course_id_math IS NOT NULL THEN
      -- Seed Grade for Math
      INSERT INTO grades (school_id, course_id, student_id, score, max_score, status, confirmed_at)
      VALUES (v_school_id, v_course_id_math, v_student_id, 85, 100, 'confirmed', now())
      ON CONFLICT DO NOTHING;
      
      -- Seed Assignments for Math
      INSERT INTO assignments (id, school_id, course_id, teacher_id, title, due_at)
      VALUES 
        (gen_random_uuid(), v_school_id, v_course_id_math, (SELECT teacher_id FROM courses WHERE id = v_course_id_math), 'แบบฝึกหัดบทที่ 5', now() - interval '1 day'),
        (gen_random_uuid(), v_school_id, v_course_id_math, (SELECT teacher_id FROM courses WHERE id = v_course_id_math), 'รายงานเรื่องพีทาโกรัส', now() + interval '2 days')
      ON CONFLICT DO NOTHING;
    END IF;
    
    IF v_course_id_science IS NOT NULL THEN
      -- Seed Grade for Science
      INSERT INTO grades (school_id, course_id, student_id, score, max_score, status, confirmed_at)
      VALUES (v_school_id, v_course_id_science, v_student_id, 92, 100, 'confirmed', now())
      ON CONFLICT DO NOTHING;
    END IF;
  END IF;
END $$;
