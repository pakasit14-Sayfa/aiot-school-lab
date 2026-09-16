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

-- =====================================================================
-- ลูกคนที่ 2 ของ parent@aiot-school-lab.local — student2@aiot-school-lab.local
--
-- ทำไมต้อง seed: fixture นี้เคยถูกสร้างด้วยมือตอน runtime (2026-09-04) แล้ว
-- **หายไปทุกครั้งที่ `supabase db reset`** — ตรวจ 2026-09-09 พบว่ามันหายไป
-- จริงแล้วรอบหนึ่ง (มีคน reset เมื่อ 2026-09-08) ทำให้ parent@ เหลือลูกคนเดียว
-- และตัวสลับนักเรียน (student-switcher) ที่ใช้ร่วมกันทุกหน้าฝั่งผู้ปกครอง
-- ทดสอบไม่ได้เลยโดยที่ไม่มีใครรู้ตัว — ปัญหาเดียวกับ dual-role fixture ด้านบน
-- ที่แก้ด้วยการย้ายมา seed ไปแล้ว
--
-- ของเดิมถูกสร้างผ่าน `redeem_parent_binding_code` (endpoint ที่เลิกใช้แล้วและ
-- ถูก revoke สิทธิ์ไปใน 20260904000000) — ที่นี่เขียนแถวลง parent_links ตรง ๆ
-- แบบเดียวกับลูกคนแรกด้านบน ไม่ได้จำลอง flow สมัครจริง (ของจริงคือ
-- request_parent_binding_otp → confirm_parent_binding)
--
-- **จงใจไม่สร้าง student_profiles / คะแนน / วิชา ให้** — จุดประสงค์ของ fixture
-- นี้คือให้ผู้ปกครองมีลูก 2 คนไว้สลับ และให้ลูกคนที่ 2 เป็นเคส "ยังไม่มีข้อมูล"
-- ที่ถูกต้อง ทุกหน้าที่ผูกกับนักเรียนจึงต้องขึ้น ยังไม่มีข้อมูล สำหรับเด็กคนนี้
-- =====================================================================
do $$
declare
  v_school_id uuid;
  v_super_admin_id uuid;
  v_parent_id uuid;
  v_student2_id uuid;
  v_code_id uuid;
begin
  select id into v_school_id from schools where school_code = 'TEST01';
  select id into v_super_admin_id from users where email = 'admin@aiot-school-lab.local';
  select id into v_parent_id from users where email = 'parent@aiot-school-lab.local';
  if v_school_id is null or v_super_admin_id is null or v_parent_id is null then
    return;
  end if;

  select id into v_student2_id from users where email = 'student2@aiot-school-lab.local';
  if v_student2_id is null then
    insert into users (school_id, email, password_hash, first_name, last_name, created_by, student_code)
    values (
      v_school_id, 'student2@aiot-school-lab.local', crypt('Test1234!', gen_salt('bf')),
      'นักเรียนสอง', 'ทดสอบ', v_super_admin_id, 'STU002'
    )
    returning id into v_student2_id;
  end if;

  if not exists (
    select 1 from user_roles where user_id = v_student2_id and role = 'student' and school_id = v_school_id
  ) then
    insert into user_roles (user_id, role, school_id, granted_by)
    values (v_student2_id, 'student', v_school_id, v_super_admin_id);
  end if;

  if not exists (
    select 1 from parent_links where parent_id = v_parent_id and student_id = v_student2_id
  ) then
    insert into parent_binding_codes (
      school_id, student_id, code_hash, code_hint, expires_at, status, issued_by, redeemed_by, redeemed_at
    ) values (
      v_school_id, v_student2_id, encode(digest('PARENT-LINK-CODE-002', 'sha256'), 'hex'),
      'DE02', now() + interval '30 days', 'redeemed', v_super_admin_id, v_parent_id, now()
    ) returning id into v_code_id;

    insert into parent_links (
      student_id, parent_id, relationship, binding_code_id, status, requested_at, approved_by, approved_at
    ) values (
      v_student2_id, v_parent_id, 'มารดา', v_code_id, 'approved', now(), v_super_admin_id, now()
    );
  end if;
end $$;

-- =====================================================================
-- 2026-09-11: ข้อมูลนักเรียนเพิ่มเติมสำหรับหน้า "ภาพรวมนักเรียน" ฝั่งผู้บริหาร
-- (director_learning_page.dart) — ก่อนหน้านี้มีนักเรียนแค่คนเดียวที่มีข้อมูล
-- จริง (student@) ทำให้ watchlist/การ์ดดูแลนักเรียน/ตารางเช็คชื่อรายห้อง
-- ว่างเปล่าแทบทั้งหมด ตรวจดีไซน์จริงไม่ได้ บล็อกนี้เพิ่มนักเรียน 4 คนใหม่
-- (STU003-STU006) กระจาย 2 ห้อง พร้อมข้อมูลจริงที่ทำให้:
--   - ตารางเช็คชื่อวันนี้ (homeroom_attendance_records) มีครบ present/late/
--     absent/ยังไม่เช็กชื่อ
--   - list_executive_students_needing_attention ยิงธงได้ 3 แบบ (ขาดเรียนบ่อย
--     ทั้งระดับปกติและ urgent, คะแนนเฉลี่ยต่ำ, ค้างส่งงาน) จากข้อมูลที่บันทึก
--     จริง ไม่ได้ insert ธงตรง ๆ (ไม่มีตารางธงให้ insert อยู่แล้ว มันคำนวณสด)
--   - student_support_cases ครบ 4 หมวด (academic/behavioral/emotional/
--     safety) และ 4 สถานะ (open/in_progress/escalated/resolved) พร้อม
--     interventions ของจริงให้ไดอะล็อกประวัติมีเนื้อหา
-- ไม่แตะ student2@ (ตั้งใจปล่อยว่างตามคอมเมนต์ด้านบน) และไม่แตะ student@ เดิม
-- Safe to re-run: ทุก insert มี guard
-- =====================================================================
do $$
declare
  v_school_id uuid;
  v_super_admin_id uuid;
  v_teacher_id uuid;
  v_academic_year_id uuid;
  v_course_id uuid;
  v_s1 uuid; v_s3 uuid; v_s4 uuid; v_s5 uuid; v_s6 uuid;
  v_row record;
  v_a1 uuid; v_a2 uuid;
  v_case_b uuid; v_case_c uuid;
begin
  select id into v_school_id from schools where school_code = 'TEST01';
  select id into v_super_admin_id from users where email = 'admin@aiot-school-lab.local';
  select id into v_teacher_id from users where email = 'teacher@aiot-school-lab.local';
  select id into v_academic_year_id from academic_years where school_id = v_school_id and name = '2569';
  select id into v_course_id from courses where school_id = v_school_id and subject_name = 'AIoT ชีววิทยาและสิ่งแวดล้อม';
  select id into v_s1 from users where email = 'student@aiot-school-lab.local';
  if v_school_id is null or v_teacher_id is null or v_academic_year_id is null or v_course_id is null then
    return;
  end if;

  -- นักเรียน 4 คนใหม่ + ห้องประจำตัว + ลงทะเบียนวิชาเดียวกับนักเรียนคนแรก
  for v_row in
    select * from (values
      ('student3@aiot-school-lab.local','STU003','นักเรียนสาม','ทดสอบ','ม.4','ม.4/1'),
      ('student4@aiot-school-lab.local','STU004','นักเรียนสี่','ทดสอบ','ม.4','ม.4/1'),
      ('student5@aiot-school-lab.local','STU005','นักเรียนห้า','ทดสอบ','ม.4','ม.4/2'),
      ('student6@aiot-school-lab.local','STU006','นักเรียนหก','ทดสอบ','ม.4','ม.4/2')
    ) as t(email, code, first_name, last_name, grade_level, room)
  loop
    declare v_uid uuid;
    begin
      select id into v_uid from users where email = v_row.email;
      if v_uid is null then
        insert into users (school_id, email, password_hash, first_name, last_name, created_by, student_code)
        values (v_school_id, v_row.email, crypt('Test1234!', gen_salt('bf')), v_row.first_name, v_row.last_name, v_super_admin_id, v_row.code)
        returning id into v_uid;
      end if;
      if not exists (select 1 from user_roles where user_id = v_uid and role = 'student' and school_id = v_school_id) then
        insert into user_roles (user_id, role, school_id, granted_by) values (v_uid, 'student', v_school_id, v_super_admin_id);
      end if;
      if not exists (select 1 from student_profiles where student_id = v_uid and academic_year_id = v_academic_year_id) then
        insert into student_profiles (student_id, academic_year_id, grade_level, room, created_by)
        values (v_uid, v_academic_year_id, v_row.grade_level, v_row.room, v_teacher_id);
      end if;
      if not exists (select 1 from course_students where course_id = v_course_id and student_id = v_uid) then
        insert into course_students (course_id, student_id, enrolled_by) values (v_course_id, v_uid, v_teacher_id);
      end if;
      case v_row.code
        when 'STU003' then v_s3 := v_uid;
        when 'STU004' then v_s4 := v_uid;
        when 'STU005' then v_s5 := v_uid;
        when 'STU006' then v_s6 := v_uid;
      end case;
    end;
  end loop;

  -- ครูคนเดียวที่มีเป็นครูประจำชั้นทั้ง 2 ห้อง ให้ advisor_name ใน watchlist มีค่า
  if not exists (select 1 from homeroom_assignments where academic_year_id = v_academic_year_id and grade_level = 'ม.4' and room = 'ม.4/1' and teacher_id = v_teacher_id) then
    insert into homeroom_assignments (school_id, academic_year_id, grade_level, room, teacher_id, created_by)
    values (v_school_id, v_academic_year_id, 'ม.4', 'ม.4/1', v_teacher_id, v_super_admin_id);
  end if;
  if not exists (select 1 from homeroom_assignments where academic_year_id = v_academic_year_id and grade_level = 'ม.4' and room = 'ม.4/2' and teacher_id = v_teacher_id) then
    insert into homeroom_assignments (school_id, academic_year_id, grade_level, room, teacher_id, created_by)
    values (v_school_id, v_academic_year_id, 'ม.4', 'ม.4/2', v_teacher_id, v_super_admin_id);
  end if;

  -- เช็คชื่อวันนี้: present/late/absent/ยังไม่เช็กชื่อ (นักเรียนหกตั้งใจไม่ใส่
  -- แถว ให้เห็นสถานะ "ยังไม่เช็กชื่อ" จริง ไม่ใช่ 0 คนขาด)
  insert into homeroom_attendance_records (student_id, academic_year_id, grade_level, room, class_date, status, marked_by)
  select v_s3, v_academic_year_id, 'ม.4', 'ม.4/1', current_date, 'present', v_teacher_id
  where not exists (select 1 from homeroom_attendance_records where student_id = v_s3 and class_date = current_date);
  insert into homeroom_attendance_records (student_id, academic_year_id, grade_level, room, class_date, status, marked_by)
  select v_s4, v_academic_year_id, 'ม.4', 'ม.4/1', current_date, 'late', v_teacher_id
  where not exists (select 1 from homeroom_attendance_records where student_id = v_s4 and class_date = current_date);
  insert into homeroom_attendance_records (student_id, academic_year_id, grade_level, room, class_date, status, marked_by)
  select v_s5, v_academic_year_id, 'ม.4', 'ม.4/2', current_date, 'absent', v_teacher_id
  where not exists (select 1 from homeroom_attendance_records where student_id = v_s5 and class_date = current_date);

  -- ขาดเรียนระดับวิชา (attendance_records) ย้อนหลัง 30 วัน — ให้
  -- list_executive_students_needing_attention ยิงธง "ขาดเรียนบ่อย" จากของจริง
  -- นักเรียนห้า 4 ครั้ง (>=4 = urgent), นักเรียนสี่ 2 ครั้ง (ปกติ)
  insert into attendance_records (course_id, student_id, class_date, status, marked_by)
  select v_course_id, v_s5, d, 'absent', v_teacher_id
  from (values (current_date - 3), (current_date - 8), (current_date - 15), (current_date - 22)) as t(d)
  where not exists (select 1 from attendance_records where course_id = v_course_id and student_id = v_s5 and class_date = t.d);
  insert into attendance_records (course_id, student_id, class_date, status, marked_by)
  select v_course_id, v_s4, d, 'absent', v_teacher_id
  from (values (current_date - 5), (current_date - 12)) as t(d)
  where not exists (select 1 from attendance_records where course_id = v_course_id and student_id = v_s4 and class_date = t.d);

  -- คะแนนต่ำ: นักเรียนสาม เฉลี่ย 40% (<50% = ธง "คะแนนเฉลี่ยต่ำ")
  if not exists (select 1 from grades where student_id = v_s3 and course_id = v_course_id) then
    insert into grades (student_id, course_id, source_type, score, max_score, status, graded_by, graded_at)
    values (v_s3, v_course_id, 'manual', 8, 20, 'confirmed', v_teacher_id, now());
  end if;

  -- งานค้างส่ง: 2 งานเลยกำหนดแล้ว นักเรียนหกไม่ส่งทั้งคู่ (>=2 = ธง
  -- "ค้างส่งงาน") ส่วนอีก 4 คนส่งครบ ไม่ให้ติดธงเดียวกันหมดทุกคน
  select id into v_a1 from assignments where course_id = v_course_id and title = 'รายงานคุณภาพน้ำรอบโรงเรียน';
  if v_a1 is null then
    insert into assignments (course_id, type, title, instructions, due_at, status, created_by)
    values (v_course_id, 'homework', 'รายงานคุณภาพน้ำรอบโรงเรียน', 'เก็บตัวอย่างน้ำ 3 จุด วัดค่า pH และสรุปผล', now() - interval '3 days', 'published', v_teacher_id)
    returning id into v_a1;
  end if;
  select id into v_a2 from assignments where course_id = v_course_id and title = 'สรุปการทดลองแยกขยะรีไซเคิล';
  if v_a2 is null then
    insert into assignments (course_id, type, title, instructions, due_at, status, created_by)
    values (v_course_id, 'worksheet', 'สรุปการทดลองแยกขยะรีไซเคิล', 'บันทึกน้ำหนักขยะแต่ละประเภทตลอด 1 สัปดาห์', now() - interval '10 days', 'published', v_teacher_id)
    returning id into v_a2;
  end if;
  insert into submissions (assignment_id, student_id, status, current_version)
  select a, s, 'submitted', 1
  from (values (v_a1), (v_a2)) as assn(a), (select unnest(array[v_s1, v_s3, v_s4, v_s5]) as s) as stu
  where not exists (select 1 from submissions where assignment_id = assn.a and student_id = stu.s);

  -- เคสดูแลนักเรียน 4 หมวด × 4 สถานะ — ให้การ์ดระบบดูแลนักเรียนและลิสต์เคสมี
  -- ของจริงให้แสดง ไม่ใช่แค่ empty state
  if not exists (select 1 from student_support_cases where student_id = v_s4 and title = 'มีภาวะเครียดจากปัญหาครอบครัว') then
    insert into student_support_cases (school_id, student_id, course_id, category, risk_level, status, title, notes, created_by)
    values (v_school_id, v_s4, v_course_id, 'emotional', 'high', 'in_progress', 'มีภาวะเครียดจากปัญหาครอบครัว', 'นักเรียนแจ้งครูแนะแนวว่ามีความเครียดสูง ต้องติดตามใกล้ชิด', v_teacher_id)
    returning id into v_case_b;
  end if;
  if not exists (select 1 from student_support_cases where student_id = v_s5 and title = 'พบร่องรอยการทำร้ายตัวเอง') then
    insert into student_support_cases (school_id, student_id, course_id, category, risk_level, status, title, notes, created_by)
    values (v_school_id, v_s5, v_course_id, 'safety', 'high', 'escalated', 'พบร่องรอยการทำร้ายตัวเอง', 'ครูพยาบาลตรวจพบบาดแผลที่แขน ส่งต่อให้ฝ่ายแนะแนวดูแลต่อเนื่อง', v_teacher_id)
    returning id into v_case_c;
  end if;
  if not exists (select 1 from student_support_cases where student_id = v_s6 and title = 'ตามงานที่ค้างส่งจนครบแล้ว') then
    insert into student_support_cases (school_id, student_id, course_id, category, risk_level, status, title, notes, created_by)
    values (v_school_id, v_s6, v_course_id, 'academic', 'low', 'resolved', 'ตามงานที่ค้างส่งจนครบแล้ว', 'ติดตามและช่วยเหลือจนนักเรียนส่งงานที่ค้างครบทุกชิ้นแล้ว', v_teacher_id);
  end if;
  if not exists (select 1 from student_support_cases where student_id = v_s3 and title = 'ขาดสมาธิในการเรียน มาสายบ่อย') then
    insert into student_support_cases (school_id, student_id, course_id, category, risk_level, status, title, notes, created_by)
    values (v_school_id, v_s3, v_course_id, 'behavioral', 'medium', 'open', 'ขาดสมาธิในการเรียน มาสายบ่อย', 'ผู้ปกครองรายงานว่านักเรียนนอนดึก ส่งผลต่อการเรียนช่วงเช้า', v_teacher_id);
  end if;

  if v_case_b is not null and not exists (select 1 from student_support_interventions where case_id = v_case_b) then
    insert into student_support_interventions (case_id, action_type, notes, recorded_by, created_at) values
      (v_case_b, 'counseling', 'พูดคุยเบื้องต้นกับนักเรียน แนะนำให้พบครูแนะแนวเพิ่มเติม', v_teacher_id, now() - interval '3 days'),
      (v_case_b, 'parent_meeting', 'นัดพบผู้ปกครองเพื่อหารือแนวทางช่วยเหลือร่วมกัน', v_teacher_id, now() - interval '1 day');
  end if;
  if v_case_c is not null and not exists (select 1 from student_support_interventions where case_id = v_case_c) then
    insert into student_support_interventions (case_id, action_type, notes, recorded_by) values
      (v_case_c, 'observation', 'ติดตามพฤติกรรมอย่างใกล้ชิด ประสานงานกับฝ่ายแนะแนวรายวัน', v_teacher_id);
  end if;
end $$;

-- =====================================================================
-- 2026-09-14: เพิ่มระดับชั้น/ห้องให้การ์ด "การมาเรียนแยกตามระดับชั้น" บนหน้า
-- ภาพรวมนักเรียนของผู้บริหาร (director_learning_page.dart) — ก่อนหน้านี้มีแค่
-- ม.4 (2 ห้อง) + นักเรียนไม่ระบุชั้น 1 คน (student2@) รวม 3 กลุ่มเท่านั้น ไม่พอ
-- ให้เห็นว่ากรอบเลื่อนสูงคงที่ 300px ที่เพิ่งใส่ในการ์ดนี้ทำงานจริงตอนโรงเรียน
-- มีหลายระดับชั้น/หลายห้อง บล็อกนี้เพิ่มนักเรียน 12 คนใหม่ (STU007-STU018)
-- กระจาย 6 ห้องใน 5 ระดับชั้นใหม่ (ม.1,ม.2,ม.3,ม.5,ม.6×2 ห้อง) รวมเดิมเป็น 7
-- กลุ่มระดับชั้น/9 ห้อง สถานะเช็คชื่อผสมทั้ง present/late/absent/excused และ
-- เว้นบางคนไว้ไม่เช็ก (unknown) ให้เห็นทั้งแท่งเขียว/เหลือง/แดงและกล่องเส้นประ
-- จริง ไม่ใช่แค่ ม.4 ที่ใส่ไว้ก่อนหน้า — ไม่แตะ course_students/grades/
-- assignments เพราะไม่เกี่ยวกับการ์ดนี้ (ขอบเขตแคบเฉพาะสิ่งที่ RPC
-- list_school_homeroom_attendance ใช้จริง: users/user_roles/student_profiles/
-- homeroom_attendance_records เท่านั้น) Safe to re-run: ทุก insert มี guard
-- =====================================================================
do $$
declare
  v_school_id uuid;
  v_super_admin_id uuid;
  v_teacher_id uuid;
  v_academic_year_id uuid;
  v_row record;
  v_uid uuid;
begin
  select id into v_school_id from schools where school_code = 'TEST01';
  select id into v_super_admin_id from users where email = 'admin@aiot-school-lab.local';
  select id into v_teacher_id from users where email = 'teacher@aiot-school-lab.local';
  select id into v_academic_year_id from academic_years where school_id = v_school_id and name = '2569';
  if v_school_id is null or v_teacher_id is null or v_academic_year_id is null then
    return;
  end if;

  -- (email, code, first_name, last_name, grade_level, room, status หรือ null=ยังไม่เช็ก)
  for v_row in
    select * from (values
      ('student7@aiot-school-lab.local','STU007','นักเรียนเจ็ด','ทดสอบ','ม.1','ม.1/1','present'),
      ('student8@aiot-school-lab.local','STU008','นักเรียนแปด','ทดสอบ','ม.1','ม.1/1','present'),
      ('student9@aiot-school-lab.local','STU009','นักเรียนเก้า','ทดสอบ','ม.2','ม.2/1','late'),
      ('student10@aiot-school-lab.local','STU010','นักเรียนสิบ','ทดสอบ','ม.2','ม.2/1','absent'),
      ('student11@aiot-school-lab.local','STU011','นักเรียนสิบเอ็ด','ทดสอบ','ม.3','ม.3/1','present'),
      ('student12@aiot-school-lab.local','STU012','นักเรียนสิบสอง','ทดสอบ','ม.3','ม.3/1','excused'),
      ('student13@aiot-school-lab.local','STU013','นักเรียนสิบสาม','ทดสอบ','ม.5','ม.5/1','present'),
      ('student14@aiot-school-lab.local','STU014','นักเรียนสิบสี่','ทดสอบ','ม.5','ม.5/1',null),
      ('student15@aiot-school-lab.local','STU015','นักเรียนสิบห้า','ทดสอบ','ม.6','ม.6/1','present'),
      ('student16@aiot-school-lab.local','STU016','นักเรียนสิบหก','ทดสอบ','ม.6','ม.6/1','late'),
      ('student17@aiot-school-lab.local','STU017','นักเรียนสิบเจ็ด','ทดสอบ','ม.6','ม.6/2','absent'),
      ('student18@aiot-school-lab.local','STU018','นักเรียนสิบแปด','ทดสอบ','ม.6','ม.6/2','present')
    ) as t(email, code, first_name, last_name, grade_level, room, status)
  loop
    select id into v_uid from users where email = v_row.email;
    if v_uid is null then
      insert into users (school_id, email, password_hash, first_name, last_name, created_by, student_code)
      values (v_school_id, v_row.email, crypt('Test1234!', gen_salt('bf')), v_row.first_name, v_row.last_name, v_super_admin_id, v_row.code)
      returning id into v_uid;
    end if;
    if not exists (select 1 from user_roles where user_id = v_uid and role = 'student' and school_id = v_school_id) then
      insert into user_roles (user_id, role, school_id, granted_by) values (v_uid, 'student', v_school_id, v_super_admin_id);
    end if;
    if not exists (select 1 from student_profiles where student_id = v_uid and academic_year_id = v_academic_year_id) then
      insert into student_profiles (student_id, academic_year_id, grade_level, room, created_by)
      values (v_uid, v_academic_year_id, v_row.grade_level, v_row.room, v_teacher_id);
    end if;
    if v_row.status is not null
       and not exists (select 1 from homeroom_attendance_records where student_id = v_uid and class_date = current_date) then
      insert into homeroom_attendance_records (student_id, academic_year_id, grade_level, room, class_date, status, marked_by)
      values (v_uid, v_academic_year_id, v_row.grade_level, v_row.room, current_date, v_row.status, v_teacher_id);
    end if;
  end loop;
end $$;

-- =====================================================================
-- 2026-09-11: เยี่ยมบ้าน · SDQ · ทุนการศึกษา · สั่งการติดตาม — ระบบใหม่ทั้งหมด
-- (20260911020000_student_followup_system.sql) ที่แทนที่การ์ด "งานติดตามที่
-- ยังไม่รองรับ" (onPressed:null 3 ปุ่ม) บนหน้าภาพรวมนักเรียนของผู้บริหาร ให้
-- มีข้อมูลจริงให้ดูตั้งแต่ reset ครั้งแรก ไม่ต้องกดสร้างเองก่อนถึงจะเห็นการ์ด
-- มีข้อมูล
--
-- คะแนน SDQ ด้านล่างคำนวณด้วยมือตามการจัดกลุ่ม 5 ข้อ/มิติแบบเดียวกับที่
-- record_sdq_assessment ใช้ (ข้อ 1-5=emotional, 6-10=conduct, 11-15=
-- hyperactivity, 16-20=peer, 21-25=prosocial) — ถ้าจะแก้ item_scores ต้องคำนวณ
-- ผลรวมใหม่ให้ตรงกัน ไม่มี trigger คำนวณอัตโนมัติให้ตอน insert ตรงแบบนี้
-- (ต่างจากตอนเรียกผ่าน RPC จริงที่ฝั่ง server คำนวณให้)
-- Safe to re-run: ทุก insert มี guard
-- =====================================================================
do $$
declare
  v_school_id uuid;
  v_teacher_id uuid;
  v_exec_id uuid;
  v_s3 uuid; v_s4 uuid; v_s5 uuid; v_s6 uuid;
  v_sch_id uuid;
begin
  select id into v_school_id from schools where school_code = 'TEST01';
  select id into v_teacher_id from users where email = 'teacher@aiot-school-lab.local';
  select id into v_exec_id from users where email = 'executive@aiot-school-lab.local';
  select id into v_s3 from users where email = 'student3@aiot-school-lab.local';
  select id into v_s4 from users where email = 'student4@aiot-school-lab.local';
  select id into v_s5 from users where email = 'student5@aiot-school-lab.local';
  select id into v_s6 from users where email = 'student6@aiot-school-lab.local';
  if v_school_id is null or v_teacher_id is null or v_exec_id is null
     or v_s3 is null or v_s4 is null or v_s5 is null or v_s6 is null then
    return;
  end if;

  if not exists (select 1 from student_home_visits where student_id = v_s3 and purpose = 'เยี่ยมบ้านตามระบบดูแลนักเรียน') then
    insert into student_home_visits (school_id, student_id, visited_by, visit_date, purpose, family_situation, follow_up_needed, follow_up_notes, created_by)
    values (v_school_id, v_s3, v_teacher_id, current_date, 'เยี่ยมบ้านตามระบบดูแลนักเรียน', 'ผู้ปกครองทำงานต่างจังหวัด อยู่กับยาย', true, 'นัดติดตามอีกครั้งใน 2 สัปดาห์', v_teacher_id);
  end if;

  if not exists (select 1 from sdq_assessments where student_id = v_s4) then
    insert into sdq_assessments (
      school_id, student_id, assessed_by, rater_type, assessment_date, item_scores,
      emotional_score, conduct_score, hyperactivity_score, peer_score, prosocial_score,
      total_difficulties_score, notes
    ) values (
      v_school_id, v_s4, v_teacher_id, 'teacher', current_date,
      '[2,1,2,1,2, 0,1,0,1,0, 2,2,1,2,2, 1,1,0,1,1, 2,2,2,1,2]'::jsonb,
      8, 2, 9, 4, 9, 23, 'สังเกตพฤติกรรมในห้องเรียน 2 สัปดาห์'
    );
  end if;

  select id into v_sch_id from scholarships where school_id = v_school_id and name = 'ทุนเรียนดีขาดแคลนทุนทรัพย์';
  if v_sch_id is null then
    insert into scholarships (school_id, name, sponsor, amount_thb, description, created_by)
    values (v_school_id, 'ทุนเรียนดีขาดแคลนทุนทรัพย์', 'มูลนิธิการศึกษาเพื่อชุมชน', 5000, 'สำหรับนักเรียนที่มีผลการเรียนดีแต่ครอบครัวมีรายได้น้อย', v_exec_id)
    returning id into v_sch_id;
  end if;
  if not exists (select 1 from scholarship_awards where scholarship_id = v_sch_id and student_id = v_s5) then
    insert into scholarship_awards (scholarship_id, student_id, status, awarded_amount_thb, notes, created_by)
    values (v_sch_id, v_s5, 'approved', 5000, 'อนุมัติแล้วในที่ประชุม', v_teacher_id);
  end if;
  -- คนที่สองยังรอพิจารณา ให้แท็บทุนการศึกษาเห็นทั้งสถานะ approved และ applied
  if not exists (select 1 from scholarship_awards where scholarship_id = v_sch_id and student_id = v_s3) then
    insert into scholarship_awards (scholarship_id, student_id, status, notes, created_by)
    values (v_sch_id, v_s3, 'applied', 'ผลการเรียนอยู่ในเกณฑ์ดี รอพิจารณารอบถัดไป', v_teacher_id);
  end if;

  if not exists (select 1 from executive_directives where student_id = v_s6 and title = 'ติดตามการส่งงานที่ค้างของนักเรียนหก') then
    insert into executive_directives (school_id, student_id, assigned_to, assigned_by, title, instructions, due_date, status, completed_notes, acknowledged_at, completed_at)
    values (
      v_school_id, v_s6, v_teacher_id, v_exec_id, 'ติดตามการส่งงานที่ค้างของนักเรียนหก',
      'โทรแจ้งผู้ปกครองและนัดส่งงานภายในสัปดาห์นี้', current_date + 7, 'completed',
      'โทรแจ้งผู้ปกครองแล้ว นักเรียนรับปากจะส่งงานภายในวันศุกร์', now() - interval '2 days', now() - interval '1 day'
    );
  end if;
  -- อีกคำสั่งหนึ่งยังไม่รับทราบ ให้แท็บสั่งการติดตามเห็นสถานะ pending ด้วย
  if not exists (select 1 from executive_directives where student_id = v_s5 and title = 'ติดตามความพร้อมก่อนเบิกจ่ายทุนการศึกษา') then
    insert into executive_directives (school_id, student_id, assigned_to, assigned_by, title, instructions, due_date, status)
    values (
      v_school_id, v_s5, v_teacher_id, v_exec_id, 'ติดตามความพร้อมก่อนเบิกจ่ายทุนการศึกษา',
      'ตรวจสอบเลขบัญชีธนาคารของผู้ปกครองก่อนเบิกจ่ายทุน', current_date + 5, 'pending'
    );
  end if;
end $$;

-- =====================================================================
-- 2026-09-11: กล่องข้อความ (notifications) ของ executive@aiot-school-lab.local
--
-- ทำไมต้อง seed: ตาราง notifications ไม่เคยมีแถวใดถูกเติมจากไฟล์นี้เลย — ทุก
-- แถวเกิดจาก trigger/RPC จริงเท่านั้น (แจ้งเหตุ, เชิญประชุม, ปิดบันทึกประชุม,
-- คำขออนุมัติ) ดังนั้นบัญชี executive@ ที่เพิ่ง reset จะเห็นหน้า "การแจ้งเตือน"
-- ว่างเปล่าเสมอ แยกไม่ออกจากพัง จนกว่าจะมีคนกดสร้างเหตุการณ์จริงก่อน
--
-- ใช้ type string และรูปแบบ payload เดียวกับที่โค้ดจริงสร้างขึ้นทุกจุด
-- (ตรวจจาก 20260907040000_meeting_records_and_notices.sql,
-- 20260907050000_staff_requests.sql, 20260818020000_incident_reports.sql) —
-- ไม่ใช่ schema ที่เดาขึ้นเอง สังเกตว่า payload ของ incident ใช้คีย์ 'severity'
-- ไม่ใช่ 'priority' ตามที่โค้ดจริงเขียน ในขณะที่ UI ฝั่ง
-- director_notifications_page.dart อ่าน payload['priority'] — ช่องกรอง
-- "ความสำคัญ" จึงว่างเสมอแม้มีข้อมูลจริง นี่คือ bug ที่ยังไม่ได้แก้ ไม่ใช่การ
-- ตั้งใจ seed ให้ตรง
--
-- meeting_id ในสอง notification แรกชี้ไปที่แถว meetings จริง (ไม่ใช่ uuid
-- ลอย ๆ) เพราะเป็นคีย์เดียวที่หน้านี้ dereference จริงผ่านปุ่ม "เปิดเรื่อง
-- ต้นทาง" — ส่วน request_id/incident_id ไม่มีปุ่มเปิดเรื่องต้นทางในหน้านี้เลย
-- แต่ยังชี้ไปที่แถวจริงเช่นกัน เผื่ออนาคตมีคนต่อปุ่มนั้นเข้าไป
--
-- Safe to re-run: ทุก insert มี guard
-- =====================================================================
do $$
declare
  v_school_id uuid;
  v_exec_id uuid;
  v_admin_id uuid;
  v_teacher_id uuid;
  v_student_id uuid;
  v_meeting1_id uuid;
  v_meeting2_id uuid;
  v_start1 timestamptz;
  v_start2 timestamptz;
  v_request_id uuid;
  v_incident_id uuid;
begin
  select id into v_school_id from schools where school_code = 'TEST01';
  select id into v_exec_id from users where email = 'executive@aiot-school-lab.local';
  select id into v_admin_id from users where email = 'schooladmin@aiot-school-lab.local';
  select id into v_teacher_id from users where email = 'teacher@aiot-school-lab.local';
  select id into v_student_id from users where email = 'student@aiot-school-lab.local';
  if v_school_id is null or v_exec_id is null or v_admin_id is null
     or v_teacher_id is null or v_student_id is null then
    return;
  end if;

  -- หมวด "ประชุม" 1/2: คำเชิญประชุมที่ยังไม่ตอบรับ (ยังไม่อ่าน)
  select id into v_meeting1_id from meetings where school_id = v_school_id and title = 'ประชุมคณะกรรมการบริหารประจำเดือน';
  if v_meeting1_id is null then
    v_start1 := now() + interval '3 days';
    insert into meetings (school_id, title, description, meeting_type, visibility, location, start_at, status, minutes_expected, created_by)
    values (v_school_id, 'ประชุมคณะกรรมการบริหารประจำเดือน', 'ทบทวนผลการดำเนินงานประจำเดือนและวาระเร่งด่วน', 'school_wide', 'school', 'ห้องประชุมใหญ่', v_start1, 'scheduled', true, v_admin_id)
    returning id into v_meeting1_id;

    insert into meeting_attendees (meeting_id, user_id, is_organizer, response) values
      (v_meeting1_id, v_admin_id, true, 'accepted'),
      (v_meeting1_id, v_exec_id, false, 'pending'),
      (v_meeting1_id, v_teacher_id, false, 'pending');

    insert into notifications (user_id, type, title, body, payload, created_at) values (
      v_exec_id, 'meeting_invite', 'เชิญเข้าร่วมประชุม',
      'ประชุมคณะกรรมการบริหารประจำเดือน • ' ||
        to_char(v_start1 at time zone 'Asia/Bangkok', 'DD/MM ') ||
        to_char(v_start1 at time zone 'Asia/Bangkok', 'HH24:MI') || ' น.',
      jsonb_build_object('meeting_id', v_meeting1_id, 'meeting_type', 'school_wide'),
      now() - interval '2 hours'
    );
  end if;

  -- หมวด "ประชุม" 2/2: ประชุมที่ผ่านไปแล้วและปิดบันทึกแล้ว (อ่านแล้ว)
  select id into v_meeting2_id from meetings where school_id = v_school_id and title = 'ประชุมทบทวนแผนพัฒนาโรงเรียนประจำภาคเรียน';
  if v_meeting2_id is null then
    v_start2 := now() - interval '10 days';
    insert into meetings (school_id, title, description, meeting_type, visibility, location, start_at, status, minutes_expected, created_by)
    values (v_school_id, 'ประชุมทบทวนแผนพัฒนาโรงเรียนประจำภาคเรียน', 'สรุปความคืบหน้าตามแผนพัฒนาและมอบหมายงานต่อ', 'group', 'attendees', 'ห้องประชุมย่อย 2', v_start2, 'completed', true, v_admin_id)
    returning id into v_meeting2_id;

    insert into meeting_attendees (meeting_id, user_id, is_organizer, response) values
      (v_meeting2_id, v_admin_id, true, 'accepted'),
      (v_meeting2_id, v_exec_id, false, 'accepted'),
      (v_meeting2_id, v_teacher_id, false, 'accepted');

    insert into meeting_minutes (meeting_id, body, status, recorded_by, finalized_at)
    values (v_meeting2_id, 'ที่ประชุมรับทราบความคืบหน้าตามแผนพัฒนาโรงเรียน มอบหมายให้แต่ละฝ่ายรายงานผลภายในสิ้นภาคเรียน', 'final', v_admin_id, now() - interval '9 days');

    insert into notifications (user_id, type, title, body, payload, created_at, read_at) values (
      v_exec_id, 'meeting_minutes_final', 'บันทึกการประชุมถูกปิดแล้ว',
      'ประชุมทบทวนแผนพัฒนาโรงเรียนประจำภาคเรียน',
      jsonb_build_object('meeting_id', v_meeting2_id),
      now() - interval '9 days', now() - interval '9 days' + interval '1 hour'
    );
  end if;

  -- หมวด "คำขอ": คำขอไปราชการของครูที่รอผู้บริหารอนุมัติ (ยังไม่อ่าน)
  select id into v_request_id from staff_requests where requester_id = v_teacher_id and subject = 'ขอไปราชการอบรมครูแกนนำด้าน AI ในการศึกษา';
  if v_request_id is null then
    insert into staff_requests (school_id, requester_id, request_type, subject, detail, start_date, end_date, location, status)
    values (v_school_id, v_teacher_id, 'official_duty', 'ขอไปราชการอบรมครูแกนนำด้าน AI ในการศึกษา', 'อบรมเชิงปฏิบัติการจัดโดยเขตพื้นที่การศึกษา', current_date + 6, current_date + 7, 'โรงแรมในตัวเมือง', 'pending_executive')
    returning id into v_request_id;

    insert into notifications (user_id, type, title, body, payload, created_at) values (
      v_exec_id, 'staff_request_pending_executive', 'มีคำขอรออนุมัติ',
      'ขอไปราชการอบรมครูแกนนำด้าน AI ในการศึกษา',
      jsonb_build_object('request_id', v_request_id, 'request_type', 'official_duty'),
      now() - interval '1 day'
    );
  end if;

  -- หมวด "เหตุ": เหตุผิดปกติที่นักเรียนแจ้ง กระจายถึงผู้บริหารตามที่
  -- broadcast_all_incidents_to_all_staff กำหนด (ยังไม่อ่าน)
  select id into v_incident_id from incident_reports where reporter_student_id = v_student_id and room = 'ม.4/1' and category = 'anomaly';
  if v_incident_id is null then
    insert into incident_reports (school_id, reporter_student_id, category, room, status, created_at)
    values (v_school_id, v_student_id, 'anomaly', 'ม.4/1', 'new', now() - interval '30 minutes')
    returning id into v_incident_id;

    insert into notifications (user_id, type, title, body, payload, created_at) values (
      v_exec_id, 'incident_report', 'แจ้งเหตุผิดปกติ',
      coalesce((select first_name || ' ' || last_name from users where id = v_student_id), 'นักเรียน') ||
        ' แจ้งเหตุ (🟠 เหตุปานกลาง): พบคนแปลกหน้าเดินอยู่บริเวณสนามหลังอาคารเรียน จากห้อง ม.4/1',
      jsonb_build_object('incident_id', v_incident_id, 'category', 'anomaly', 'room', 'ม.4/1', 'reason', 'พบคนแปลกหน้าเดินอยู่บริเวณสนามหลังอาคารเรียน', 'severity', 'medium'),
      now() - interval '30 minutes'
    );
  end if;
end $$;

-- =====================================================================
-- 2026-09-13: การ์ด "การเข้าเรียนของนักเรียน" / "การมาปฏิบัติหน้าที่ของครู"
-- บนหน้าภาพรวมของผู้บริหาร — การมาปฏิบัติหน้าที่ของครูขึ้นว่างเสมอหลัง reset
-- (โรงเรียนไม่เคยตั้งเวลาปฏิบัติงานเลย) ทำให้ทดสอบดีไซน์จริงไม่ได้นอกจากเคส
-- ว่างเปล่า บล็อกนี้ตั้งเวลาปฏิบัติงาน + เติมการลงเวลาของครู
--
-- ฝั่งนักเรียนมีบล็อก "เช็คชื่อวันนี้" อยู่ก่อนแล้วด้านบน (ราว ๆ บรรทัด 690)
-- ที่ให้ student3=present, student4=late, student5=absent และตั้งใจปล่อย
-- student6 ว่างไว้เพื่อโชว์สถานะ "ยังไม่เช็กชื่อ" จริง (ไม่ใช่ 0 คนขาด) — ที่นี่
-- เติมแค่ student1 (present) ที่ยังไม่มีใครแตะ ไม่แตะ student3-6 ซ้ำเพื่อไม่ให้
-- ไปข้ามการออกแบบที่ตั้งใจไว้แต่แรกของบล็อกนั้น (ON CONFLICT DO NOTHING ก็จะ
-- เงียบ ๆ ข้ามไปอยู่ดีถ้าลองใส่ซ้ำ แต่เขียนแยกไว้ชัดกว่า)
--
-- ผลรวมที่ได้จริงจากทั้งสองบล็อกรวมกัน: มาเรียน 2 (present) สาย 1 ขาด 1
-- ยังไม่เช็ก 2 (student6 ตั้งใจเว้นว่าง + student2@ ไม่มี student_profiles)
-- ไม่มี "ลา" เลยเพราะไม่มีนักเรียนคนไหนเหลือให้ตั้งค่าโดยไม่ไปทับของเดิม —
-- 0 ตรงนี้เป็นเลขจริง ไม่ใช่ fallback ปลอม — ครูมาปฏิบัติงาน 1 (teacher@
-- ตรงเวลา) สาย 1 (schooladmin@ เข้างานหลังช่วงผ่อนผัน) ยังไม่ลงเวลา 1
-- (executive@ ปล่อยว่างตั้งใจ เพื่อให้เห็น "ยังไม่ลงเวลา" ด้วย)
--
-- ใช้วันที่แบบเดียวกับที่ RPC จริงคำนวณ ((now() at time zone 'Asia/Bangkok')
-- ::date) ไม่ใช่ current_date เฉย ๆ — ถ้า container รันเป็น UTC ตอนใกล้เที่ยงคืน
-- ไทย current_date จะเป็นคนละวันกับที่ RPC มองว่าเป็น "วันนี้" แล้วแถวที่ seed
-- ไว้จะไม่โผล่ในการ์ดเลย
--
-- Safe to re-run: staff_work_hours ใช้ ON CONFLICT (school_id) DO NOTHING,
-- อีกสองตารางมี UNIQUE(student_id/user_id, date) อยู่แล้วจึงใช้
-- ON CONFLICT ... DO NOTHING ได้ตรง ๆ
-- =====================================================================
do $$
declare
  v_school_id uuid;
  v_admin_id uuid;
  v_teacher_id uuid;
  v_schooladmin_id uuid;
  v_year uuid;
  v_today date := (now() at time zone 'Asia/Bangkok')::date;
  v_s1 uuid;
begin
  select id into v_school_id from schools where school_code = 'TEST01';
  select id into v_admin_id from users where email = 'admin@aiot-school-lab.local';
  select id into v_teacher_id from users where email = 'teacher@aiot-school-lab.local';
  select id into v_schooladmin_id from users where email = 'schooladmin@aiot-school-lab.local';
  select id into v_year from academic_years where school_id = v_school_id and name = '2569';
  select id into v_s1 from users where email = 'student@aiot-school-lab.local';
  if v_school_id is null or v_admin_id is null or v_teacher_id is null
     or v_schooladmin_id is null or v_year is null or v_s1 is null then
    return;
  end if;

  -- เวลาปฏิบัติงานของโรงเรียน — ไม่มีแถวนี้แปลว่าครูลงเวลาไม่ได้เลยสักคน
  insert into staff_work_hours (school_id, work_start_time, work_end_time, late_grace_minutes, updated_by)
  values (v_school_id, '08:00', '16:30', 15, v_admin_id)
  on conflict (school_id) do nothing;

  -- ครู: มาตรงเวลา 1 คน, มาสาย 1 คน, ปล่อย executive@ ว่างไว้ตั้งใจ (ยังไม่ลงเวลา)
  insert into staff_attendance_records (school_id, user_id, work_date, check_in_at, status, source, recorded_by)
  values
    (v_school_id, v_teacher_id, v_today,
     (v_today::timestamp + time '07:50') at time zone 'Asia/Bangkok', 'present', 'self', v_teacher_id),
    (v_school_id, v_schooladmin_id, v_today,
     (v_today::timestamp + time '08:20') at time zone 'Asia/Bangkok', 'late', 'self', v_schooladmin_id)
  on conflict (user_id, work_date) do nothing;

  -- นักเรียนคนเดียวที่ยังไม่มีการเช็กชื่อวันนี้จากบล็อกไหนเลย
  insert into homeroom_attendance_records (student_id, academic_year_id, grade_level, room, class_date, status, marked_by)
  values (v_s1, v_year, 'ม.4', 'ม.4/1', v_today, 'present', v_teacher_id)
  on conflict (student_id, class_date) do nothing;
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
