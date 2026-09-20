-- 68_admin_timetable_enrollment.test.sql
BEGIN;

create extension if not exists pgtap with schema extensions;
select plan(35);

-- Setup: create test users and tokens
insert into packages (id, name, license_type) values ('68100000-0000-0000-0000-000000000001', 'SP package', 'perpetual') on conflict do nothing;
insert into schools (id, package_id, name, school_code) values
  ('68200000-0000-0000-0000-000000000001', '68100000-0000-0000-0000-000000000001', 'School 68', 'SCH-68') on conflict do nothing;
insert into academic_years (id, school_id, name)
values ('68300000-0000-0000-0000-000000000001', '68200000-0000-0000-0000-000000000001', '2568') on conflict do nothing;
insert into terms (id, academic_year_id, name, start_date, end_date)
values ('68400000-0000-0000-0000-000000000001', '68300000-0000-0000-0000-000000000001', 'Term 1', '2026-05-16', '2026-10-10') on conflict do nothing;

-- A second school with its own year/term, to prove an admin cannot create a
-- course on another school's term (the room sync would otherwise pull that
-- school's students in).
insert into schools (id, package_id, name, school_code) values
  ('68200000-0000-0000-0000-000000000002', '68100000-0000-0000-0000-000000000001', 'School 68b', 'SCH-68B') on conflict do nothing;
insert into academic_years (id, school_id, name)
values ('68300000-0000-0000-0000-000000000002', '68200000-0000-0000-0000-000000000002', '2568') on conflict do nothing;
insert into terms (id, academic_year_id, name, start_date, end_date)
values ('68400000-0000-0000-0000-000000000002', '68300000-0000-0000-0000-000000000002', 'Term 1', '2026-05-16', '2026-10-10') on conflict do nothing;

insert into users (id, school_id, email, password_hash, first_name, last_name, created_by) values
  ('68500000-0000-0000-0000-000000000001', '68200000-0000-0000-0000-000000000001', 'admin68@pdpa.test', crypt('x', gen_salt('bf')), 'Admin', 'A', '68500000-0000-0000-0000-000000000001'),
  ('68500000-0000-0000-0000-000000000002', '68200000-0000-0000-0000-000000000001', 'student68@pdpa.test', crypt('x', gen_salt('bf')), 'Stu', 'One', '68500000-0000-0000-0000-000000000001'),
  ('68500000-0000-0000-0000-000000000003', '68200000-0000-0000-0000-000000000001', 'teacher68@pdpa.test', crypt('x', gen_salt('bf')), 'Tea', 'Cher', '68500000-0000-0000-0000-000000000001'),
  ('68500000-0000-0000-0000-000000000004', '68200000-0000-0000-0000-000000000001', 'student68_2@pdpa.test', crypt('x', gen_salt('bf')), 'Stu', 'Two', '68500000-0000-0000-0000-000000000001')
on conflict do nothing;

insert into user_roles (user_id, role, school_id, granted_by) values
  ('68500000-0000-0000-0000-000000000001', 'school_admin', '68200000-0000-0000-0000-000000000001', '68500000-0000-0000-0000-000000000001'),
  ('68500000-0000-0000-0000-000000000002', 'student',      '68200000-0000-0000-0000-000000000001', '68500000-0000-0000-0000-000000000001'),
  ('68500000-0000-0000-0000-000000000003', 'teacher',      '68200000-0000-0000-0000-000000000001', '68500000-0000-0000-0000-000000000001'),
  ('68500000-0000-0000-0000-000000000004', 'student',      '68200000-0000-0000-0000-000000000001', '68500000-0000-0000-0000-000000000001')
on conflict do nothing;

insert into sessions (user_id, active_role, active_school_id, token_hash, expires_at) values
  ('68500000-0000-0000-0000-000000000001', 'school_admin', '68200000-0000-0000-0000-000000000001', encode(digest('token_admin', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('68500000-0000-0000-0000-000000000002', 'student',      '68200000-0000-0000-0000-000000000001', encode(digest('token_student', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('68500000-0000-0000-0000-000000000003', 'teacher',      '68200000-0000-0000-0000-000000000001', encode(digest('token_teacher', 'sha256'), 'hex'), now() + interval '1 hour')
on conflict do nothing;

-- 1. ครูเรียก create_course → forbidden
select throws_ok(
  $$ select create_course('token_teacher', '68400000-0000-0000-0000-000000000001', 'Math 101', 'ม.1', '1', null, '68500000-0000-0000-0000-000000000003') $$,
  'forbidden', 'ครูสร้างคอร์สไม่ได้แล้ว'
);

-- 1b. แอดมินสร้างคอร์สบน term ของโรงเรียนอื่น → term_not_found
select throws_ok(
  $$ select create_course('token_admin', '68400000-0000-0000-0000-000000000002', 'Math 101', 'ม.1', '1', null, '68500000-0000-0000-0000-000000000003') $$,
  'term_not_found', 'term ต้องเป็นของโรงเรียนตัวเอง'
);

-- 2. สร้างคอร์สด้วย admin
select lives_ok(
  $$ select create_course('token_admin', '68400000-0000-0000-0000-000000000001', 'Math 101', 'ม.1', '1', null, '68500000-0000-0000-0000-000000000003') $$,
  'แอดมินสร้างคอร์สได้'
);

-- 3. ครูเรียก enroll_student → forbidden
select throws_ok(
  $$ select enroll_student('token_teacher', (select id from courses where subject_name = 'Math 101' limit 1), '68500000-0000-0000-0000-000000000002') $$,
  'forbidden', 'ครูเรียก enroll_student ไม่ได้'
);

-- 4. ตั้งห้องให้นักเรียน 1 เป็น ม.1/1 → อยู่ในคอร์สของห้องอัตโนมัติ
select lives_ok(
  $$ select set_student_profile('token_admin', '68500000-0000-0000-0000-000000000002', 'ม.1', '1') $$,
  'แอดมินตั้งห้องให้นักเรียนได้'
);
select is((select count(*)::int from course_students cs join courses c on c.id = cs.course_id where cs.student_id = '68500000-0000-0000-0000-000000000002' and c.subject_name = 'Math 101'), 1, 'นักเรียนถูกนำเข้าคอร์สอัตโนมัติหลังตั้งห้อง');

-- 5. สร้างคอร์สห้อง ม.1/1 เพิ่ม → นักเรียนทั้งห้อง(มีคนเดียวตอนนี้)เข้าคอร์สใหม่
select lives_ok(
  $$ select create_course('token_admin', '68400000-0000-0000-0000-000000000001', 'Science 101', 'ม.1', '1', null, '68500000-0000-0000-0000-000000000003') $$,
  'สร้างอีกคอร์สให้ห้องเดิม'
);
select is((select count(*)::int from course_students cs join courses c on c.id = cs.course_id where cs.student_id = '68500000-0000-0000-0000-000000000002' and c.subject_name = 'Science 101'), 1, 'นักเรียนเดิมถูกนำเข้าคอร์สใหม่ด้วย');

-- 6. แอดมิน enroll นักเรียน 2 (ยังไม่มีห้อง) เข้าร่วม Math 101 ด้วยมือ
select lives_ok(
  $$ select enroll_student('token_admin', (select id from courses where subject_name = 'Math 101' limit 1), '68500000-0000-0000-0000-000000000004') $$,
  'แอดมิน enroll เพิ่มเองได้ (ข้อยกเว้น)'
);

-- 7. ตั้งนักเรียน 2 ไปอยู่ห้อง ม.1/2 -> แถวที่แอดมินเพิ่มเองจะไม่หลุด
select lives_ok(
  $$ select set_student_profile('token_admin', '68500000-0000-0000-0000-000000000004', 'ม.1', '2') $$,
  'ตั้งนักเรียนไปห้องอื่น'
);
select is((select count(*)::int from course_students cs join courses c on c.id = cs.course_id where cs.student_id = '68500000-0000-0000-0000-000000000004' and c.subject_name = 'Math 101'), 1, 'แถวที่แอดมินเพิ่มรายคน (enrolled_by not null) ไม่หลุด');

-- 8. ย้ายนักเรียน 1 ไป ม.1/2 → หลุดจากคอร์สของ ม.1/1 ทั้งหมด
select lives_ok(
  $$ select set_student_profile('token_admin', '68500000-0000-0000-0000-000000000002', 'ม.1', '2') $$,
  'ย้ายนักเรียน 1 ไปห้อง ม.1/2'
);
select is((select count(*)::int from course_students cs join courses c on c.id = cs.course_id where cs.student_id = '68500000-0000-0000-0000-000000000002'), 0, 'นักเรียนหลุดจากคอร์ส ม.1/1 แล้ว');

-- 9. sync idempotent
select lives_ok(
  $$ select sync_course_students_for_student('68500000-0000-0000-0000-000000000002') $$,
  'เรียก sync_course_students_for_student ซ้ำไม่พัง'
);
select is((select count(*)::int from course_students cs where cs.student_id = '68500000-0000-0000-0000-000000000002'), 0, 'count เท่าเดิม');

-- 10. set_school_periods และ set_class_schedule (ดึง p_period_no)
select lives_ok(
  $$ select set_school_periods('token_admin', '[{"period_no": 1, "start_time": "08:30", "end_time": "09:20", "label": "คาบ 1"}]'::jsonb) $$,
  'ตั้งคาบเรียน'
);
select lives_ok(
  $$ select admin_set_room_timetable_slot('token_admin', '68400000-0000-0000-0000-000000000001', 'ม.1', '1', 1::smallint, 1::smallint, 'History 101', '68500000-0000-0000-0000-000000000003') $$,
  'แอดมินจัดตารางเรียน'
);
select is((select start_time::text from class_schedules where period_no = 1 limit 1), '08:30:00', 'เวลาดึงมาจาก school_periods ถูกต้อง');

-- 11. timetable slot ทับวิชาเดิม→วิชาเดิมหาย
select lives_ok(
  $$ select admin_set_room_timetable_slot('token_admin', '68400000-0000-0000-0000-000000000001', 'ม.1', '1', 1::smallint, 1::smallint, 'Science 101', '68500000-0000-0000-0000-000000000003') $$,
  'แอดมินจัดตารางทับช่องเดิม'
);
select is((select count(*)::int from class_schedules where period_no = 1 and day_of_week = 1), 1, 'วิชาเดิมถูกลบออกไปแล้วเหลือแค่วิชาใหม่ในช่องนั้น');

-- 12. list_my_courses
-- Move student 2 back to 1/1 so they can see History/Science
select lives_ok(
  $$ select set_student_profile('token_admin', '68500000-0000-0000-0000-000000000002', 'ม.1', '1') $$,
  'ย้ายกลับ ม.1/1'
);
select is((select count(*)::int from list_my_courses('token_student')), 3, 'list_my_courses ของนักเรียนเห็นคอร์สครบ 3 คอร์ส โดยไม่ต้อง enroll เอง');

-- 13. รูปแบบห้องต่างกัน (สถานการณ์จริงบน prod): profile เก็บ (ม.1, '1') แต่คอร์สเก็บ (ม.1, 'ม.1/1')
-- ต้องจับคู่กันได้ผ่าน _class_room_key
select is(public._class_room_key('ม.1', '1'), 'ม.1/1', '_class_room_key เติม grade ให้ห้องสั้น');
select is(public._class_room_key('ม.1', 'ม.1/1'), 'ม.1/1', '_class_room_key ไม่เติมซ้ำ');
select lives_ok(
  $$ select create_course('token_admin', '68400000-0000-0000-0000-000000000001', 'Thai 101', 'ม.1', 'ม.1/1', null, '68500000-0000-0000-0000-000000000003') $$,
  'สร้างคอร์สที่เก็บห้องแบบยาว ม.1/1 (รูปแบบเดียวกับ prod)'
);
select is(
  (select count(*)::int from course_students cs join courses c on c.id = cs.course_id
   where cs.student_id = '68500000-0000-0000-0000-000000000002' and cs.enrolled_by is null and c.subject_name = 'Thai 101'),
  1,
  'นักเรียนที่ profile เก็บห้องแบบสั้น (1) ถูกดึงเข้าคอร์สที่เก็บห้องแบบยาว (ม.1/1)'
);


-- 14. (20260920030000) admin lists every teacher's subjects with names; assigning a slot records the pair
select lives_ok(
  $$ select * from list_teacher_subjects('token_admin') $$,
  'แอดมินเรียก list_teacher_subjects โดยไม่ระบุครูได้ (เดิม forbidden)'
);
select ok(
  exists (select 1 from list_teacher_subjects('token_admin') where subject_name = 'History 101' and teacher_name like 'Tea%'),
  'จัดคาบ History 101 ให้ครูแล้ว teacher_subjects จำคู่ครู-วิชาให้เอง พร้อมชื่อครู'
);
select throws_ok(
  $$ select admin_set_room_timetable_slot('token_admin', '68400000-0000-0000-0000-000000000001', 'ม.1', '1', 2::smallint, 1::smallint, 'Art 101', null) $$,
  'teacher_required', 'จัดคาบโดยไม่ระบุครู → teacher_required'
);
select throws_ok(
  $$ select * from list_teacher_subjects('token_student') $$,
  'forbidden', 'นักเรียนเรียก list_teacher_subjects ไม่ได้'
);


-- 15. every RPC the admin timetable page calls must at least execute (42804 guard)
select lives_ok($$ select * from list_school_classes('token_admin', '68300000-0000-0000-0000-000000000001') $$, 'list_school_classes รันได้ (เคย 42804 varchar/text)');
select is((select count(*)::int from list_school_classes('token_admin', '68300000-0000-0000-0000-000000000001') where grade_level = 'ม.1'), 2, 'list_school_classes นับห้อง ม.1 ได้ 2 ห้อง (1 และ 2)');
select lives_ok($$ select * from list_room_timetable('token_admin', '68400000-0000-0000-0000-000000000001', 'ม.1', '1') $$, 'list_room_timetable รันได้');
select lives_ok($$ select * from list_school_periods('token_admin') $$, 'list_school_periods รันได้');
select throws_ok($$ select * from list_school_classes('token_student', '68300000-0000-0000-0000-000000000001') $$, 'forbidden', 'นักเรียนดูรายชื่อห้องทั้งโรงเรียนไม่ได้');

SELECT * FROM finish();
ROLLBACK;
