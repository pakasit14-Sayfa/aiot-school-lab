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
      ('parent'::role_type,           'parent@aiot-school-lab.local',      'ผู้ปกครอง',  'ทดสอบ',    null::varchar)
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

  -- 2026-08-18: Seed lesson materials and AIoT sensor link with sample readings
  if not exists (select 1 from lesson_materials where lesson_id = v_lesson_id) then
    insert into lesson_materials (lesson_id, type, title, url, sort_order) values
      (v_lesson_id, 'link', 'คู่มือการใช้งานเซนเซอร์ PM2.5 (PDF)', 'https://example.com/materials/pm25_manual.pdf', 1),
      (v_lesson_id, 'link', 'สไลด์บรรยายบทเรียน PM2.5', 'https://example.com/slides/pm25_intro', 2);
  end if;

  if not exists (select 1 from lesson_sensor_links where lesson_id = v_lesson_id) then
    declare
      v_pm25_dev_id uuid;
    begin
      select id into v_pm25_dev_id from devices where school_id = v_school_id and name = 'เซนเซอร์ PM2.5 โถงกลาง' limit 1;
      if v_pm25_dev_id is null then
        select id into v_pm25_dev_id from devices where school_id = v_school_id and name = 'เซนเซอร์ PM2.5 ชุดฝึก' limit 1;
      end if;

      if v_pm25_dev_id is not null then
        insert into lesson_sensor_links (lesson_id, device_id, metric, time_start, time_end, caption)
        values (v_lesson_id, v_pm25_dev_id, 'pm25', now() - interval '24 hours', now(), 'ข้อมูลการวัดค่าฝุ่น PM2.5 ย้อนหลัง 24 ชั่วโมง');

        if not exists (select 1 from sensor_readings where device_id = v_pm25_dev_id) then
          insert into sensor_readings (device_id, metric, ts, value) values
            (v_pm25_dev_id, 'pm25', now() - interval '20 hours', 15.2),
            (v_pm25_dev_id, 'pm25', now() - interval '16 hours', 18.7),
            (v_pm25_dev_id, 'pm25', now() - interval '12 hours', 22.4),
            (v_pm25_dev_id, 'pm25', now() - interval '8 hours', 31.0),
            (v_pm25_dev_id, 'pm25', now() - interval '4 hours', 25.6),
            (v_pm25_dev_id, 'pm25', now() - interval '1 hour', 19.3);
        end if;
      end if;
    end;
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

  -- 2026-08-17: Seed sample devices
  if not exists (select 1 from devices where name = 'ไฟแสงสว่าง โถงทางเดิน ชั้น 1') then
    insert into devices (school_id, type, name, location, status, registered_by) values
      (v_school_id, 'relay', 'ไฟแสงสว่าง โถงทางเดิน ชั้น 1', 'อาคาร 3 (วิทยาศาสตร์) · ชั้น 1', 'online', v_super_admin_id),
      (v_school_id, 'relay', 'ระบบปั๊มน้ำ รดน้ำสวนหน้าอาคาร', 'อาคาร 3 (วิทยาศาสตร์) · สวนหน้าอาคาร', 'online', v_super_admin_id),
      (v_school_id, 'relay', 'ไฟส่องสว่าง ดาดฟ้า', 'อาคาร 3 (วิทยาศาสตร์) · ดาดฟ้า', 'offline', v_super_admin_id),
      (v_school_id, 'camera', 'กล้อง CCTV ทางเข้าหลัก', 'อาคาร 3 (วิทยาศาสตร์) · ทางเข้าหลัก', 'online', v_super_admin_id),
      (v_school_id, 'pm25_sensor', 'เซนเซอร์ PM2.5 โถงกลาง', 'อาคาร 3 (วิทยาศาสตร์) · โถงกลาง', 'online', v_super_admin_id);
  end if;

  -- 2026-08-18: Seed classroom AIoT teaching kit devices bound to course_id
  if not exists (select 1 from devices where name = 'ไฟชุดฝึก LED') then
    insert into devices (school_id, type, name, location, status, registered_by, course_id) values
      (v_school_id, 'relay', 'ไฟชุดฝึก LED', 'Lab 3 · ชุดฝึกที่ 1', 'online', v_teacher_id, v_course_id),
      (v_school_id, 'relay', 'ปั๊มน้ำจำลอง', 'Lab 3 · ชุดฝึกที่ 1', 'online', v_teacher_id, v_course_id),
      (v_school_id, 'relay', 'รีเลย์ควบคุม', 'Lab 3 · ชุดฝึกที่ 1', 'online', v_teacher_id, v_course_id),
      (v_school_id, 'pm25_sensor', 'เซนเซอร์ PM2.5 ชุดฝึก', 'Lab 3 · ชุดฝึกที่ 1', 'online', v_teacher_id, v_course_id);
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

-- =====================================================================
-- Dual-role fixture — teacher@aiot-school-lab.local also holds
-- school_admin in the same school.
--
-- Why this is seeded rather than created by hand: an account with 2+
-- roles is the ONLY way to exercise the multi-role login path
-- (auth_sign_in returns `role_selection_required` instead of picking a
-- role, then auth_select_role issues an OTP for the chosen role). Every
-- other seeded account has exactly one role and never reaches that code.
-- This fixture used to be created manually at runtime, which meant it
-- silently disappeared on every `supabase db reset` and the multi-role
-- flow quietly stopped being tested. Seeding it fixes that.
--
-- It also reproduces a real bug class: `list_school_users` collapses a
-- multi-role account to one `active_role` (most recently granted), which
-- once hid this teacher from the teacher list entirely until
-- `all_roles`/`hasRole` was added.
--
-- Safe to re-run: the insert is guarded on the exact (user, role, school).
-- =====================================================================

do $$
declare
  v_teacher_id uuid;
  v_school_id uuid;
  v_super_admin_id uuid;
begin
  select id, school_id into v_teacher_id, v_school_id
  from users where email = 'teacher@aiot-school-lab.local';

  select id into v_super_admin_id
  from users where email = 'admin@aiot-school-lab.local';

  if v_teacher_id is not null and v_school_id is not null then
    if not exists (
      select 1 from user_roles
      where user_id = v_teacher_id
        and role = 'school_admin'
        and school_id = v_school_id
    ) then
      insert into user_roles (user_id, role, school_id, granted_by)
      values (v_teacher_id, 'school_admin', v_school_id,
              coalesce(v_super_admin_id, v_teacher_id));
    end if;
  end if;
end $$;

-- =====================================================================
-- 2026-09-09: มิเตอร์ไฟ/น้ำ/อากาศ + ค่าที่วัดได้จริง (local dev)
--
-- ทำไมต้องมีบล็อกนี้: `sensor_readings` ว่างเปล่า 0 แถวมาตลอด ทำให้ทุกหน้า
-- ที่ใช้ utility RPC (พลังงาน/น้ำ/ESG/การ์ดอากาศของนักเรียน) ขึ้น
-- "ยังไม่มีข้อมูล" เสมอ — ตรวจไม่ได้เลยว่าหน้าพวกนี้ทำงานถูกไหม และเป็น
-- เหตุผลที่ fallback ปลอมเคยถูกใส่ไว้ปิดบังข้อนี้
--
-- 2 สาเหตุที่ทำให้ว่าง แก้ทั้งคู่ในบล็อกนี้:
--   1. บล็อก lesson_sensor_links (บรรทัด ~157) ค้นหา device ชื่อ
--      'เซนเซอร์ PM2.5 โถงกลาง' *ก่อน* บล็อกที่สร้าง device นั้น (บรรทัด ~262)
--      ตอน db reset ครั้งแรกจึงได้ null เสมอ แล้วข้ามการ insert readings ไป
--      เงียบ ๆ — บล็อกนี้อยู่ท้ายไฟล์ อุปกรณ์ครบแล้วแน่นอน
--   2. ไม่เคยมี device ชนิด energy_meter / water_meter เลยสักตัว ซึ่งเป็น
--      เงื่อนไข `d.type = 'energy_meter'` ใน get_energy_usage_summary/_trend
--      (น้ำก็เช่นกัน) ต่อให้มี readings ก็จะรวมได้ 0 อยู่ดี
--
-- ช่วงเวลา 70 วันเป็นค่าต่ำสุดที่ทำให้ get_energy_efficiency_score คืนคะแนน
-- จริงได้ เพราะมันเทียบเดือนปัจจุบันกับเดือนก่อนหน้า ถ้าเดือนก่อนไม่มีข้อมูล
-- (v_previous <= 0) มันจะคืน null ตามที่ออกแบบไว้
--
-- ค่าที่ใส่เป็นค่าสังเคราะห์สำหรับ dev เท่านั้น ไม่ใช่ค่าที่วัดจากของจริง
-- =====================================================================
do $$
declare
  v_school_id uuid;
  v_super_admin_id uuid;
  v_teacher_id uuid;
  v_energy_dev uuid;
  v_water_dev uuid;
  v_air_dev uuid;
  v_pm25_dev uuid;
  v_lesson_id uuid;
begin
  select id into v_school_id from schools where school_code = 'TEST01';
  select id into v_super_admin_id from users where email = 'admin@aiot-school-lab.local';
  select id into v_teacher_id from users where email = 'teacher@aiot-school-lab.local';
  if v_school_id is null or v_super_admin_id is null then
    return;
  end if;

  -- อุปกรณ์วัดที่ยังขาด — ต้องมี type ตรงกับที่ RPC กรอง ไม่งั้นรวมยอดได้ 0
  if not exists (select 1 from devices where school_id = v_school_id and type = 'energy_meter') then
    insert into devices (school_id, type, name, location, building, status, registered_by)
    values (v_school_id, 'energy_meter', 'มิเตอร์ไฟฟ้า อาคาร 3', 'อาคาร 3 (วิทยาศาสตร์) · ห้องไฟฟ้า', 'อาคาร 3', 'online', v_super_admin_id);
  end if;
  if not exists (select 1 from devices where school_id = v_school_id and type = 'water_meter') then
    insert into devices (school_id, type, name, location, building, status, registered_by)
    values (v_school_id, 'water_meter', 'มิเตอร์น้ำ อาคาร 3', 'อาคาร 3 (วิทยาศาสตร์) · ห้องปั๊มน้ำ', 'อาคาร 3', 'online', v_super_admin_id);
  end if;
  if not exists (select 1 from devices where school_id = v_school_id and type = 'air_quality_sensor') then
    insert into devices (school_id, type, name, location, building, status, registered_by)
    values (v_school_id, 'air_quality_sensor', 'เซนเซอร์อากาศ ห้องเรียน ม.4/1', 'อาคาร 3 (วิทยาศาสตร์) · ห้อง ม.4/1', 'อาคาร 3', 'online', v_super_admin_id);
  end if;

  -- devices.building เป็น null ทั้ง 9 ตัวที่ seed ไว้เดิม ทำให้ตัวกรอง
  -- "อาคาร" ในหน้า School Admin/Executive ไม่มีอะไรให้กรองเลย
  update devices set building = 'อาคาร 3'
  where school_id = v_school_id and building is null;

  select id into v_energy_dev from devices where school_id = v_school_id and type = 'energy_meter' limit 1;
  select id into v_water_dev  from devices where school_id = v_school_id and type = 'water_meter' limit 1;
  select id into v_air_dev    from devices where school_id = v_school_id and type = 'air_quality_sensor' limit 1;
  select id into v_pm25_dev   from devices where school_id = v_school_id and name = 'เซนเซอร์ PM2.5 โถงกลาง' limit 1;

  -- ไฟฟ้า: รายชั่วโมง 70 วัน · กลางวันวันธรรมดากินไฟมากกว่ากลางคืน/วันหยุด
  -- เพื่อให้กราฟแนวโน้มมีรูปร่างจริง ไม่ใช่เส้นแบน
  if v_energy_dev is not null
     and not exists (select 1 from sensor_readings where device_id = v_energy_dev) then
    insert into sensor_readings (device_id, metric, ts, value)
    select
      v_energy_dev, 'energy_kwh', ts,
      round((
        case when extract(isodow from ts) >= 6 then 1.2
             when extract(hour from ts) between 7 and 16 then 8.5
             when extract(hour from ts) between 17 and 20 then 3.4
             else 1.1 end
        + (random() * 0.8)
      )::numeric, 2)
    from generate_series(date_trunc('hour', now()) - interval '70 days',
                         date_trunc('hour', now()), interval '1 hour') as ts;
  end if;

  -- น้ำ: ทุก 4 ชั่วโมง 70 วัน
  if v_water_dev is not null
     and not exists (select 1 from sensor_readings where device_id = v_water_dev) then
    insert into sensor_readings (device_id, metric, ts, value)
    select
      v_water_dev, 'water_m3', ts,
      round((
        case when extract(isodow from ts) >= 6 then 0.15
             when extract(hour from ts) between 8 and 16 then 1.8
             else 0.4 end
        + (random() * 0.25)
      )::numeric, 3)
    from generate_series(date_trunc('hour', now()) - interval '70 days',
                         date_trunc('hour', now()), interval '4 hours') as ts;
  end if;

  -- อากาศในห้องเรียน: รายชั่วโมง 3 วัน ครบ 4 metric ที่การ์ดอากาศฝั่ง
  -- นักเรียนอ่าน (pm25 / temperature / humidity / light_lux) — ค่ากลางคืน
  -- มืดและเย็นกว่า เพื่อให้เห็นว่าเป็นข้อมูลจริงที่เปลี่ยนตามเวลา
  if v_air_dev is not null
     and not exists (select 1 from sensor_readings where device_id = v_air_dev) then
    insert into sensor_readings (device_id, metric, ts, value)
    select v_air_dev, m.metric::metric_type, ts,
      case m.metric
        when 'pm25'        then round((12 + (random() * 26))::numeric, 1)
        when 'temperature' then round((26 + (case when extract(hour from ts) between 10 and 16 then 4 else 0 end) + random() * 2)::numeric, 1)
        when 'humidity'    then round((55 + (random() * 15))::numeric, 1)
        when 'co2'         then round((450 + (case when extract(hour from ts) between 8 and 15 then 350 else 0 end) + random() * 80)::numeric, 0)
        else round((case when extract(hour from ts) between 6 and 18 then 320 + random() * 240 else random() * 12 end)::numeric, 0)
      end
    from generate_series(date_trunc('hour', now()) - interval '3 days',
                         date_trunc('hour', now()), interval '1 hour') as ts
    cross join (values ('pm25'), ('temperature'), ('humidity'), ('light_lux'), ('co2')) as m(metric);
  end if;

  -- ซ่อมของเดิม: ค่า PM2.5 ของบทเรียน + lesson_sensor_links ที่ไม่เคยถูก
  -- สร้างจริงเพราะปัญหาลำดับที่อธิบายไว้ด้านบน
  if v_pm25_dev is not null
     and not exists (select 1 from sensor_readings where device_id = v_pm25_dev) then
    insert into sensor_readings (device_id, metric, ts, value)
    select v_pm25_dev, 'pm25', ts,
           round((14 + (random() * 22))::numeric, 1)
    from generate_series(date_trunc('hour', now()) - interval '2 days',
                         date_trunc('hour', now()), interval '1 hour') as ts;
  end if;

  select l.id into v_lesson_id
  from lessons l
  join courses c on c.id = l.course_id
  where l.title = 'บทที่ 1: รู้จักเซนเซอร์ PM2.5' and c.school_id = v_school_id
  limit 1;

  if v_lesson_id is not null and v_pm25_dev is not null
     and not exists (select 1 from lesson_sensor_links where lesson_id = v_lesson_id) then
    insert into lesson_sensor_links (lesson_id, device_id, metric, time_start, time_end, caption)
    values (v_lesson_id, v_pm25_dev, 'pm25', now() - interval '24 hours', now(),
            'ข้อมูลการวัดค่าฝุ่น PM2.5 ย้อนหลัง 24 ชั่วโมง');
  end if;

  -- เกณฑ์เตือน: ไม่มีสักแถว แปลว่า sensor_ingest ไม่มีทางสร้าง sensor_alerts
  -- ได้เลย หน้าแจ้งเตือนทุกหน้าจึงว่างถาวรโดยที่ไม่ได้พัง
  if not exists (select 1 from thresholds where school_id = v_school_id) then
    insert into thresholds (school_id, device_id, metric, min_value, max_value, is_active, created_by)
    values
      (v_school_id, v_air_dev, 'pm25', null, 37.5, true, v_super_admin_id),
      (v_school_id, v_air_dev, 'co2', null, 1000, true, v_super_admin_id),
      (v_school_id, null, 'temperature', 18, 35, true, v_super_admin_id);
  end if;
end $$;

-- แจ้งเตือน 2 รายการที่ผูกกับ threshold จริงด้านบน — ไม่มีสักแถวใน
-- sensor_alerts แปลว่าหน้าแจ้งเตือนของ School Admin/Super Admin/ครู
-- ทดสอบไม่ได้เลย (ว่างเปล่าโดยไม่ได้พัง แยกไม่ออกจากพัง)
-- sensor_ingest จะสร้างของจริงเพิ่มเองเมื่ออุปกรณ์ส่งค่าเกินเกณฑ์
do $$
declare
  v_school_id uuid;
  v_air_dev uuid;
  v_th_pm25 uuid;
  v_th_co2 uuid;
begin
  select id into v_school_id from schools where school_code = 'TEST01';
  if v_school_id is null then return; end if;

  select id into v_air_dev from devices where school_id = v_school_id and type = 'air_quality_sensor' limit 1;
  select id into v_th_pm25 from thresholds where school_id = v_school_id and metric = 'pm25' limit 1;
  select id into v_th_co2  from thresholds where school_id = v_school_id and metric = 'co2' limit 1;

  if v_air_dev is not null and v_th_pm25 is not null
     and not exists (select 1 from sensor_alerts sa join devices d on d.id = sa.device_id where d.school_id = v_school_id) then
    insert into sensor_alerts (threshold_id, device_id, metric, value, triggered_at, status)
    values
      (v_th_pm25, v_air_dev, 'pm25', 41.8, now() - interval '3 hours', 'new'),
      (coalesce(v_th_co2, v_th_pm25), v_air_dev, 'co2', 1180, now() - interval '26 hours', 'new');
  end if;
end $$;

-- Quick reference: everything logs in with password Test1234!
-- (except admin@aiot-school-lab.local, which uses ChangeMe123! from the
-- bootstrap migration).
-- `string_agg` rather than `limit 1`: teacher@ deliberately holds two
-- roles (see the dual-role fixture above), and `limit 1` would pick one
-- of them arbitrarily and hide that fact.
select
  u.email,
  (select string_agg(ur.role::text, ', ' order by ur.role)
     from user_roles ur where ur.user_id = u.id) as roles
from users u
where u.email like '%@aiot-school-lab.local'
order by u.email;
