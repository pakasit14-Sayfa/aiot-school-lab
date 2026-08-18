-- =====================================================================
-- Dev/test seed data — one test school + one account per role, so each
-- role's dashboard/permissions can be checked manually in the UI without
-- going through the full invite/binding flows first.
--
-- NOT for production. All seeded accounts share the password 'Test1234!'
-- (same hashing as the bootstrap super_admin in
-- 20260715010000_auth_rpc.sql). Delete or change these before go-live.
--
-- This does NOT run automatically against a remote/hosted Supabase
-- project — `supabase db reset` only auto-applies seed.sql for local
-- dev. For the real project, paste this file into the Supabase Dashboard
-- SQL Editor and run it once, or `psql "$DATABASE_URL" -f supabase/seed.sql`.
-- Safe to re-run: every insert is guarded, so running it twice is a no-op.
-- =====================================================================

do $$
declare
  v_super_admin_id uuid;
  v_package_id uuid;
  v_school_id uuid;
  v_password_hash varchar;
  v_user_id uuid;
  v_role record;
begin
  select id into v_super_admin_id from users where email = 'admin@aiot-school-lab.local';
  if v_super_admin_id is null then
    raise exception 'bootstrap super_admin not found — run migrations first (20260715010000_auth_rpc.sql)';
  end if;

  v_password_hash := crypt('Test1234!', gen_salt('bf'));

  -- 20260720000000_rotate_default_credentials.sql rotates the bootstrap
  -- admin's default password away; restore the known dev password here so
  -- local `supabase db reset` still leaves a usable super_admin login.
  update users set password_hash = v_password_hash where id = v_super_admin_id;

  select id into v_package_id from packages where name = 'ทดสอบ Package';
  if v_package_id is null then
    insert into packages (name, license_type, max_users)
    values ('ทดสอบ Package', 'perpetual', 500)
    returning id into v_package_id;
  end if;

  select id into v_school_id from schools where school_code = 'TEST01';
  if v_school_id is null then
    insert into schools (package_id, name, school_code, status)
    values (v_package_id, 'โรงเรียนทดสอบ', 'TEST01', 'active')
    returning id into v_school_id;
  end if;

  for v_role in
    select * from (values
      ('school_admin'::role_type,     'schooladmin@aiot-school-lab.local', 'แอดมิน',    'โรงเรียน', null::varchar),
      ('teacher'::role_type,          'teacher@aiot-school-lab.local',     'ครู',       'ทดสอบ',    null::varchar),
      ('executive'::role_type,        'executive@aiot-school-lab.local',   'ผู้บริหาร',  'ทดสอบ',    null::varchar),
      ('student'::role_type,          'student@aiot-school-lab.local',     'นักเรียน',   'ทดสอบ',    'STU0001'::varchar),
      ('parent'::role_type,           'parent@aiot-school-lab.local',      'ผู้ปกครอง',  'ทดสอบ',    null::varchar),
      ('facility_manager'::role_type, 'facility@aiot-school-lab.local',    'ผู้ดูแล',    'อาคาร',    null::varchar),
      ('technician'::role_type,       'technician@aiot-school-lab.local',  'ช่าง',      'เทคนิค',   null::varchar)
    ) as t(role, email, first_name, last_name, student_code)
  loop
    if not exists (select 1 from users where email = v_role.email) then
      insert into users (school_id, email, password_hash, first_name, last_name, created_by, student_code)
      values (v_school_id, v_role.email, v_password_hash, v_role.first_name, v_role.last_name, v_super_admin_id, v_role.student_code)
      returning id into v_user_id;

      insert into user_roles (user_id, role, school_id, granted_by)
      values (v_user_id, v_role.role, v_school_id, v_super_admin_id);
    end if;
  end loop;
end $$;

-- =====================================================================
-- Classroom & Learning sample data — one course taught by the seeded
-- teacher account with the seeded student enrolled, so the UI has real
-- content to show instead of empty states. Safe to re-run.
-- =====================================================================

do $$
declare
  v_super_admin_id uuid;
  v_school_id uuid;
  v_teacher_id uuid;
  v_student_id uuid;
  v_academic_year_id uuid;
  v_term_id uuid;
  v_course_id uuid;
  v_lesson_id uuid;
  v_assignment_id uuid;
  v_submission_id uuid;
  v_post_id uuid;
  v_quiz_id uuid;
  v_question_id uuid;
begin
  select id into v_super_admin_id from users where email = 'admin@aiot-school-lab.local';
  select id into v_school_id from schools where school_code = 'TEST01';
  select id into v_teacher_id from users where email = 'teacher@aiot-school-lab.local';
  select id into v_student_id from users where email = 'student@aiot-school-lab.local';

  select id into v_academic_year_id from academic_years where school_id = v_school_id and name = '2569';
  if v_academic_year_id is null then
    insert into academic_years (school_id, name)
    values (v_school_id, '2569')
    returning id into v_academic_year_id;
  end if;

  select id into v_term_id from terms where academic_year_id = v_academic_year_id and name = 'ภาคเรียนที่ 1/2569';
  if v_term_id is null then
    insert into terms (academic_year_id, name)
    values (v_academic_year_id, 'ภาคเรียนที่ 1/2569')
    returning id into v_term_id;
  end if;

  select id into v_course_id from courses where school_id = v_school_id and subject_name = 'AIoT ชีววิทยาและสิ่งแวดล้อม';
  if v_course_id is null then
    insert into courses (school_id, term_id, subject_name, grade_level, room, description, created_by)
    values (
      v_school_id, v_term_id, 'AIoT ชีววิทยาและสิ่งแวดล้อม', 'ม.4/1', 'Lab 3',
      'เรียนรู้การใช้เซนเซอร์ IoT วัดคุณภาพอากาศและสภาพแวดล้อมในห้องเรียน',
      v_teacher_id
    )
    returning id into v_course_id;
  end if;

  if not exists (select 1 from course_teachers where course_id = v_course_id and teacher_id = v_teacher_id) then
    insert into course_teachers (course_id, teacher_id) values (v_course_id, v_teacher_id);
  end if;

  if not exists (select 1 from course_students where course_id = v_course_id and student_id = v_student_id) then
    insert into course_students (course_id, student_id, enrolled_by) values (v_course_id, v_student_id, v_teacher_id);
  end if;

  -- 2026-08-18: student_profiles ให้มีห้องประจำตัวจริง — ใช้เป็นค่าเริ่มต้น
  -- ของหน้าแจ้งเหตุฉุกเฉิน (SOS) และเป็นขอบเขตห้องสำหรับ list_incident_reports
  if not exists (select 1 from student_profiles where student_id = v_student_id and academic_year_id = v_academic_year_id) then
    insert into student_profiles (student_id, academic_year_id, grade_level, room, created_by)
    values (v_student_id, v_academic_year_id, 'ม.4', 'ม.4/1', v_teacher_id);
  end if;

  select id into v_lesson_id from lessons where course_id = v_course_id and title = 'บทที่ 1: รู้จักเซนเซอร์ PM2.5';
  if v_lesson_id is null then
    insert into lessons (course_id, title, content, status, published_at, created_by, updated_at)
    values (
      v_course_id, 'บทที่ 1: รู้จักเซนเซอร์ PM2.5',
      '{"body": "เซนเซอร์ PM2.5 วัดค่าฝุ่นละอองขนาดเล็กในอากาศ ใช้หลักการกระเจิงแสง (light scattering) ในการนับจำนวนอนุภาค"}'::jsonb,
      'published', now(), v_teacher_id, now()
    )
    returning id into v_lesson_id;
  end if;

  select id into v_assignment_id from assignments where course_id = v_course_id and title = 'สำรวจคุณภาพอากาศในห้องเรียน';
  if v_assignment_id is null then
    insert into assignments (course_id, type, title, instructions, due_at, status, created_by)
    values (
      v_course_id, 'homework', 'สำรวจคุณภาพอากาศในห้องเรียน',
      'บันทึกค่า PM2.5 และอุณหภูมิในห้องเรียนช่วงเช้า/บ่าย เป็นเวลา 3 วัน แล้วสรุปแนวโน้ม',
      now() + interval '7 days', 'published', v_teacher_id
    )
    returning id into v_assignment_id;
  end if;

  select id into v_submission_id from submissions where assignment_id = v_assignment_id and student_id = v_student_id;
  if v_submission_id is null then
    insert into submissions (assignment_id, student_id, status, current_version)
    values (v_assignment_id, v_student_id, 'submitted', 1)
    returning id into v_submission_id;

    insert into submission_versions (submission_id, version, content, submitted_by)
    values (v_submission_id, 1, 'ค่าเฉลี่ย PM2.5 ช่วงเช้าอยู่ที่ 18 ไมโครกรัม/ลบ.ม. และช่วงบ่าย 24 ไมโครกรัม/ลบ.ม.', v_student_id);
  end if;

  if not exists (select 1 from grades where student_id = v_student_id and course_id = v_course_id) then
    insert into grades (student_id, course_id, source_type, submission_id, score, max_score, status, graded_by, graded_at)
    values (v_student_id, v_course_id, 'manual', v_submission_id, 18, 20, 'confirmed', v_teacher_id, now());
  end if;

  select id into v_post_id from course_posts where course_id = v_course_id and body like '%เตรียมรายงานผลค่าฝุ่น%';
  if v_post_id is null then
    insert into course_posts (course_id, author_id, body, is_pinned)
    values (v_course_id, v_teacher_id, '[ประกาศ] ให้นักเรียนทุกคนเตรียมรายงานผลค่าฝุ่น PM2.5 มาส่งในคาบเรียนถัดไป', true)
    returning id into v_post_id;

    insert into course_post_replies (post_id, author_id, body)
    values (v_post_id, v_student_id, 'รับทราบครับ/ค่ะ');
  end if;

  -- 2026-08-18: Seed a pretest so ASM-3 (student take-quiz flow) has real
  -- data to work with — created directly (not via create_quiz/publish_quiz
  -- RPCs, which need a session token) but matches what those RPCs would
  -- produce: draft insert, questions with correct choices, then published.
  select id into v_quiz_id from quizzes where course_id = v_course_id and title = 'แบบทดสอบก่อนเรียน บทที่ 1: เซนเซอร์ PM2.5';
  if v_quiz_id is null then
    insert into quizzes (course_id, lesson_id, type, title, time_limit_min, status, created_by)
    values (v_course_id, v_lesson_id, 'pre_test', 'แบบทดสอบก่อนเรียน บทที่ 1: เซนเซอร์ PM2.5', 5, 'published', v_teacher_id)
    returning id into v_quiz_id;

    insert into quiz_questions (quiz_id, type, question, points, sort_order)
    values (v_quiz_id, 'multiple_choice', 'PM2.5 หมายถึงฝุ่นละอองขนาดเท่าใด', 1, 1)
    returning id into v_question_id;
    insert into quiz_choices (question_id, choice_text, is_correct, sort_order) values
      (v_question_id, 'เล็กกว่า 2.5 ไมโครเมตร', true, 1),
      (v_question_id, 'เล็กกว่า 2.5 มิลลิเมตร', false, 2),
      (v_question_id, 'เล็กกว่า 25 มิลลิเมตร', false, 3);

    insert into quiz_questions (quiz_id, type, question, points, sort_order)
    values (v_quiz_id, 'true_false', 'เซนเซอร์ PM2.5 ในชุดแล็บใช้หลักการกระเจิงแสง (light scattering)', 1, 2)
    returning id into v_question_id;
    insert into quiz_choices (question_id, choice_text, is_correct, sort_order) values
      (v_question_id, 'จริง', true, 1),
      (v_question_id, 'เท็จ', false, 2);
  end if;

  -- 2026-08-18: Seed a real weekly class schedule so the calendar page has
  -- something to show — created directly (not via set_class_schedule, which
  -- needs a session token) but matches what that RPC would produce.
  if not exists (
    select 1 from class_schedules where course_id = v_course_id and day_of_week = 0
  ) then
    insert into class_schedules (course_id, day_of_week, start_time, end_time, room, created_by)
    values (v_course_id, 0, '08:30', '09:30', 'Lab 3', v_teacher_id);
  end if;
  if not exists (
    select 1 from class_schedules where course_id = v_course_id and day_of_week = 3
  ) then
    insert into class_schedules (course_id, day_of_week, start_time, end_time, room, created_by)
    values (v_course_id, 3, '10:30', '11:30', 'Lab 3', v_teacher_id);
  end if;

  -- 2026-08-17: Seed facility_manager building assignment & sample devices for STK-9/STK-11
  update users set building = 'อาคาร 3 (วิทยาศาสตร์)' where email = 'facility@aiot-school-lab.local';

  if not exists (select 1 from devices where name = 'ไฟแสงสว่าง โถงทางเดิน ชั้น 1') then
    insert into devices (school_id, type, name, location, status, registered_by) values
      (v_school_id, 'relay', 'ไฟแสงสว่าง โถงทางเดิน ชั้น 1', 'อาคาร 3 (วิทยาศาสตร์) · ชั้น 1', 'online', v_super_admin_id),
      (v_school_id, 'relay', 'ระบบปั๊มน้ำ รดน้ำสวนหน้าอาคาร', 'อาคาร 3 (วิทยาศาสตร์) · สวนหน้าอาคาร', 'online', v_super_admin_id),
      (v_school_id, 'relay', 'ไฟส่องสว่าง ดาดฟ้า', 'อาคาร 3 (วิทยาศาสตร์) · ดาดฟ้า', 'offline', v_super_admin_id),
      (v_school_id, 'camera', 'กล้อง CCTV ทางเข้าหลัก', 'อาคาร 3 (วิทยาศาสตร์) · ทางเข้าหลัก', 'online', v_super_admin_id),
      (v_school_id, 'pm25_sensor', 'เซนเซอร์ PM2.5 โถงกลาง', 'อาคาร 3 (วิทยาศาสตร์) · โถงกลาง', 'online', v_super_admin_id);
  end if;

  -- 2026-08-18: Seed approved parent_links connection for parent@aiot-school-lab.local linked to student@aiot-school-lab.local
  if not exists (
    select 1 from parent_links pl
    join users pu on pu.id = pl.parent_id
    where pu.email = 'parent@aiot-school-lab.local'
  ) then
    declare
      v_p_id uuid;
      v_b_code_id uuid;
    begin
      select id into v_p_id from users where email = 'parent@aiot-school-lab.local';

      insert into parent_binding_codes (
        school_id, student_id, code_hash, code_hint, expires_at, status, issued_by, redeemed_by, redeemed_at
      ) values (
        v_school_id, v_student_id, encode(digest('PARENT-LINK-CODE-001', 'sha256'), 'hex'),
        'DE01', now() + interval '30 days', 'redeemed', v_super_admin_id, v_p_id, now()
      ) returning id into v_b_code_id;

      insert into parent_links (
        student_id, parent_id, relationship, binding_code_id, status, requested_at, approved_by, approved_at
      ) values (
        v_student_id, v_p_id, 'parent', v_b_code_id, 'approved', now(), v_super_admin_id, now()
      );
    end;
  end if;
end $$;

-- Quick reference: everything logs in with password Test1234!
-- (except admin@aiot-school-lab.local, which uses ChangeMe123! from the
-- bootstrap migration).
select email, (select role from user_roles ur where ur.user_id = u.id limit 1) as role
from users u
where u.email like '%@aiot-school-lab.local'
order by role;
