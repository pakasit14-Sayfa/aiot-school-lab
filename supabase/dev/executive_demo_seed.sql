-- EXECUTIVE_DEMO_V1
-- Local-only, repeatable data for reviewing Executive screens with realistic volume.
begin;

do $$
declare
  v_school uuid;
  v_teacher uuid;
  v_year uuid;
  v_term uuid;
  v_password_hash varchar;
  v_student uuid;
  v_course uuid;
  v_assignment uuid;
  v_submission uuid;
  i integer;
begin
  select id into v_school from public.schools where school_code = 'TEST01';
  select id, password_hash into v_teacher, v_password_hash
  from public.users where email = 'teacher@aiot-school-lab.local';
  select id into v_year from public.academic_years
  where school_id = v_school order by start_date desc nulls last, id limit 1;
  select id into v_term from public.terms
  where academic_year_id = v_year order by start_date desc nulls last, id limit 1;

  if v_school is null or v_teacher is null or v_year is null or v_term is null then
    raise exception 'EXECUTIVE_DEMO_V1 requires TEST01 school, teacher, academic year and term';
  end if;

  insert into public.rooms
    (id, school_id, name, code, floor, room_type, capacity, teacher_name, status)
  values
    ('d3000000-0000-4000-8000-000000000001', v_school, 'ห้องเรียน ม.4/1 [DEMO]', 'DEMO-M401', '4', 'classroom', 40, 'ครูทดสอบ', 'active'),
    ('d3000000-0000-4000-8000-000000000002', v_school, 'ห้องเรียน ม.4/2 [DEMO]', 'DEMO-M402', '4', 'classroom', 40, 'ครูทดสอบ', 'active'),
    ('d3000000-0000-4000-8000-000000000003', v_school, 'ห้องเรียน ม.5/1 [DEMO]', 'DEMO-M501', '5', 'classroom', 40, 'ครูทดสอบ', 'active')
  on conflict (id) do update set name = excluded.name, status = excluded.status;

  for i in 1..12 loop
    v_student := format('d0000000-0000-4000-8000-%s', lpad(i::text, 12, '0'))::uuid;
    insert into public.users
      (id, school_id, email, student_code, password_hash, must_change_password,
       first_name, last_name, status, created_by)
    values
      (v_student, v_school, ('demo.student' || lpad(i::text, 2, '0') || '@aiot-school-lab.local'),
       ('DEMO' || lpad(i::text, 3, '0')), v_password_hash, false,
       ('นักเรียนตัวอย่าง ' || i)::varchar, 'EXECUTIVE_DEMO_V1', 'active', v_teacher)
    on conflict (id) do update set
      first_name = excluded.first_name, last_name = excluded.last_name, status = 'active';

    insert into public.user_roles
      (id, user_id, role, school_id, granted_by)
    values
      (format('d1000000-0000-4000-8000-%s', lpad(i::text, 12, '0'))::uuid,
       v_student, 'student', v_school, v_teacher)
    on conflict do nothing;

    insert into public.student_profiles
      (id, student_id, academic_year_id, grade_level, room, created_by)
    values
      (format('d2000000-0000-4000-8000-%s', lpad(i::text, 12, '0'))::uuid,
       v_student, v_year,
       case when i <= 8 then 'ม.4' else 'ม.5' end,
       case when i <= 4 then '1' when i <= 8 then '2' else '1' end,
       v_teacher)
    on conflict (student_id, academic_year_id) do update set
      grade_level = excluded.grade_level, room = excluded.room;

    insert into public.homeroom_attendance_records
      (id, student_id, academic_year_id, grade_level, room, class_date,
       status, marked_by, marked_at, note)
    values
      (format('d2100000-0000-4000-8000-%s', lpad(i::text, 12, '0'))::uuid,
       v_student, v_year,
       case when i <= 8 then 'ม.4' else 'ม.5' end,
       case when i <= 4 then '1' when i <= 8 then '2' else '1' end,
       current_date,
       case when i in (4, 11) then 'absent' when i in (3, 8) then 'late' when i = 7 then 'excused' else 'present' end,
       v_teacher, now(), 'EXECUTIVE_DEMO_V1')
    on conflict do nothing;
  end loop;

  insert into public.learning_tracks
    (id, school_id, name, color, sort_order, created_by)
  values
    ('d9000000-0000-4000-8000-000000000001', v_school, 'วิทยาศาสตร์และเทคโนโลยี [DEMO]', '#356A9A', 10, v_teacher),
    ('d9000000-0000-4000-8000-000000000002', v_school, 'ศิลป์และนวัตกรรม [DEMO]', '#C33E73', 20, v_teacher)
  on conflict (id) do update set name = excluded.name, color = excluded.color;

  insert into public.learning_track_room_assignments
    (id, school_id, academic_year_id, grade_level, room, track_id, assigned_by)
  values
    ('da000000-0000-4000-8000-000000000001', v_school, v_year, 'ม.4', '1', 'd9000000-0000-4000-8000-000000000001', v_teacher),
    ('da000000-0000-4000-8000-000000000002', v_school, v_year, 'ม.4', '2', 'd9000000-0000-4000-8000-000000000002', v_teacher),
    ('da000000-0000-4000-8000-000000000003', v_school, v_year, 'ม.5', '1', 'd9000000-0000-4000-8000-000000000001', v_teacher)
  on conflict do nothing;

  insert into public.courses
    (id, school_id, term_id, subject_name, grade_level, room, description, status, created_by, join_code)
  values
    ('d4000000-0000-4000-8000-000000000001', v_school, v_term, 'คณิตศาสตร์ประยุกต์ [DEMO]', 'ม.4', '1', 'EXECUTIVE_DEMO_V1', 'active', v_teacher, 'DM401M'),
    ('d4000000-0000-4000-8000-000000000002', v_school, v_term, 'วิทยาศาสตร์ข้อมูล [DEMO]', 'ม.4', '2', 'EXECUTIVE_DEMO_V1', 'active', v_teacher, 'DM402S'),
    ('d4000000-0000-4000-8000-000000000003', v_school, v_term, 'โครงงานนวัตกรรม [DEMO]', 'ม.5', '1', 'EXECUTIVE_DEMO_V1', 'active', v_teacher, 'DM501P')
  on conflict (id) do update set subject_name = excluded.subject_name, status = 'active';

  for i in 1..12 loop
    v_student := format('d0000000-0000-4000-8000-%s', lpad(i::text, 12, '0'))::uuid;
    v_course := case when i <= 4 then 'd4000000-0000-4000-8000-000000000001'::uuid
                     when i <= 8 then 'd4000000-0000-4000-8000-000000000002'::uuid
                     else 'd4000000-0000-4000-8000-000000000003'::uuid end;
    insert into public.course_students (id, course_id, student_id, enrolled_by)
    values (format('d5000000-0000-4000-8000-%s', lpad(i::text, 12, '0'))::uuid,
            v_course, v_student, v_teacher)
    on conflict (course_id, student_id) do nothing;
  end loop;

  insert into public.assignments
    (id, course_id, type, title, instructions, due_at, is_group, status, created_by)
  values
    ('d6000000-0000-4000-8000-000000000001', 'd4000000-0000-4000-8000-000000000001', 'homework', 'สมการเชิงเส้น [DEMO]', 'ทำแบบฝึกหัดข้อ 1–10', now() + interval '2 days', false, 'published', v_teacher),
    ('d6000000-0000-4000-8000-000000000002', 'd4000000-0000-4000-8000-000000000002', 'worksheet', 'วิเคราะห์ข้อมูลอากาศ [DEMO]', 'สรุปข้อมูลจากเซนเซอร์', now() - interval '1 day', false, 'published', v_teacher),
    ('d6000000-0000-4000-8000-000000000003', 'd4000000-0000-4000-8000-000000000003', 'project', 'ต้นแบบโรงเรียนอัจฉริยะ [DEMO]', 'นำเสนอแนวคิดและต้นแบบ', now() + interval '6 days', true, 'published', v_teacher),
    ('d6000000-0000-4000-8000-000000000004', 'd4000000-0000-4000-8000-000000000001', 'worksheet', 'แบบฝึกทบทวน [DEMO]', 'งานฉบับร่างสำหรับทดสอบสถานะ', now() + interval '10 days', false, 'draft', v_teacher)
  on conflict (id) do update set title = excluded.title, due_at = excluded.due_at, status = excluded.status;

  for i in 1..9 loop
    v_student := format('d0000000-0000-4000-8000-%s', lpad(i::text, 12, '0'))::uuid;
    v_assignment := case when i <= 3 then 'd6000000-0000-4000-8000-000000000001'::uuid
                         when i <= 6 then 'd6000000-0000-4000-8000-000000000002'::uuid
                         else 'd6000000-0000-4000-8000-000000000003'::uuid end;
    v_submission := format('d7000000-0000-4000-8000-%s', lpad(i::text, 12, '0'))::uuid;
    insert into public.submissions
      (id, assignment_id, student_id, status, current_version, submitted_at)
    values
      (v_submission, v_assignment, v_student,
       (case when i in (2, 5, 8) then 'graded' else 'submitted' end)::submission_status,
       1, now() - (i || ' hours')::interval)
    on conflict (id) do update set status = excluded.status, submitted_at = excluded.submitted_at;

    insert into public.grades
      (id, student_id, course_id, source_type, submission_id, assignment_id,
       score, max_score, status, graded_by, graded_at, confirmed_by, confirmed_at)
    values
      (format('d8000000-0000-4000-8000-%s', lpad(i::text, 12, '0'))::uuid,
       v_student,
       case when i <= 3 then 'd4000000-0000-4000-8000-000000000001'::uuid
            when i <= 6 then 'd4000000-0000-4000-8000-000000000002'::uuid
            else 'd4000000-0000-4000-8000-000000000003'::uuid end,
       'submission', v_submission, v_assignment,
       55 + i * 4, 100, 'confirmed', v_teacher, now(), v_teacher, now())
    on conflict (id) do update set score = excluded.score, status = 'confirmed';
  end loop;

  insert into public.student_support_cases
    (id, school_id, student_id, course_id, category, risk_level, status,
     title, notes, created_by, created_at, updated_at)
  values
    ('db000000-0000-4000-8000-000000000001', v_school, 'd0000000-0000-4000-8000-000000000004', 'd4000000-0000-4000-8000-000000000001', 'academic', 'high', 'open', 'ติดตามการขาดเรียน [DEMO]', 'ติดต่อผู้ปกครองและติดตามการมาเรียน', v_teacher, now() - interval '5 days', now()),
    ('db000000-0000-4000-8000-000000000002', v_school, 'd0000000-0000-4000-8000-000000000008', 'd4000000-0000-4000-8000-000000000002', 'academic', 'medium', 'in_progress', 'ติดตามงานค้าง [DEMO]', 'วางแผนส่งงานย้อนหลังร่วมกับนักเรียน', v_teacher, now() - interval '3 days', now()),
    ('db000000-0000-4000-8000-000000000003', v_school, 'd0000000-0000-4000-8000-000000000011', 'd4000000-0000-4000-8000-000000000003', 'emotional', 'low', 'resolved', 'พูดคุยให้คำปรึกษา [DEMO]', 'นักเรียนได้รับคำปรึกษาแล้ว', v_teacher, now() - interval '10 days', now())
  on conflict (id) do update set status = excluded.status, notes = excluded.notes, updated_at = now();

  insert into public.student_support_interventions
    (id, case_id, action_type, notes, recorded_by, created_at)
  values
    ('dc000000-0000-4000-8000-000000000001', 'db000000-0000-4000-8000-000000000001', 'parent_meeting', 'โทรศัพท์แจ้งผู้ปกครองแล้ว [DEMO]', v_teacher, now() - interval '2 days'),
    ('dc000000-0000-4000-8000-000000000002', 'db000000-0000-4000-8000-000000000002', 'remedial_lesson', 'กำหนดตารางส่งงานชดเชย [DEMO]', v_teacher, now() - interval '1 day'),
    ('dc000000-0000-4000-8000-000000000003', 'db000000-0000-4000-8000-000000000003', 'counseling', 'ติดตามหลังให้คำปรึกษา [DEMO]', v_teacher, now() - interval '7 days')
  on conflict (id) do update set notes = excluded.notes;
end $$;

commit;
