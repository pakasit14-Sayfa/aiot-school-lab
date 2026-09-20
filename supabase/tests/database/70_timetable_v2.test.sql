-- 68_admin_timetable_enrollment.test.sql
BEGIN;

create extension if not exists pgtap with schema extensions;
select plan(20);

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


-- rooms: student 1 in ม.1/1 (short form), student 2 in ม.1/2; a second term in the same year for "copy from last term"
select set_student_profile('token_admin', '68500000-0000-0000-0000-000000000002', 'ม.1', '1');
select set_student_profile('token_admin', '68500000-0000-0000-0000-000000000004', 'ม.1', '2');
insert into terms (id, academic_year_id, name, start_date, end_date)
values ('68400000-0000-0000-0000-000000000003', '68300000-0000-0000-0000-000000000001', 'Term 2', '2026-11-01', '2027-03-31');

-- 1. periods with a lunch break; overlap rejected
select lives_ok(
  $$ select set_school_periods('token_admin', '[
    {"period_no":1,"start_time":"08:30","end_time":"09:20"},
    {"period_no":2,"start_time":"09:20","end_time":"10:10"},
    {"period_no":3,"start_time":"10:10","end_time":"11:00","kind":"break","label":"พักกลางวัน"},
    {"period_no":4,"start_time":"11:00","end_time":"11:50"}]'::jsonb) $$,
  'ตั้งคาบ 4 คาบ มีพักกลางวัน 1');
select is((select kind from list_school_periods('token_admin') where period_no = 3), 'break', 'คาบ 3 เป็นพัก');
select throws_ok(
  $$ select set_school_periods('token_admin', '[{"period_no":1,"start_time":"08:30","end_time":"09:20"},{"period_no":2,"start_time":"09:00","end_time":"10:00"}]'::jsonb) $$,
  'period_overlap', 'คาบทับกัน → period_overlap');
-- (restore the 4-period set after the failed call rolled back its own statement only)
select set_school_periods('token_admin', '[
    {"period_no":1,"start_time":"08:30","end_time":"09:20"},
    {"period_no":2,"start_time":"09:20","end_time":"10:10"},
    {"period_no":3,"start_time":"10:10","end_time":"11:00","kind":"break","label":"พักกลางวัน"},
    {"period_no":4,"start_time":"11:00","end_time":"11:50"}]'::jsonb);

-- 2. a break cannot take a subject
select throws_ok(
  $$ select admin_set_room_timetable_slot('token_admin', '68400000-0000-0000-0000-000000000001', 'ม.1', '1', 1::smallint, 3::smallint, 'Math', '68500000-0000-0000-0000-000000000003') $$,
  'period_is_break', 'จัดวิชาลงคาบพัก → period_is_break');

-- 3. overview: both rooms listed, lesson_slots = 3 lessons × 5 days = 15, nothing filled yet
select is((select count(*)::int from list_timetable_overview('token_admin', '68400000-0000-0000-0000-000000000001')), 2, 'overview เห็น 2 ห้อง');
select is((select lesson_slots::int from list_timetable_overview('token_admin', '68400000-0000-0000-0000-000000000001') where room_key = 'ม.1/1'), 15, 'lesson_slots = 15 (ไม่นับคาบพัก)');
select is((select filled_slots::int from list_timetable_overview('token_admin', '68400000-0000-0000-0000-000000000001') where room_key = 'ม.1/1'), 0, 'ยังไม่จัด = 0');

-- 4. fill 3 slots in ม.1/1, overview counts them
select admin_set_room_timetable_slot('token_admin', '68400000-0000-0000-0000-000000000001', 'ม.1', '1', 1::smallint, 1::smallint, 'Math', '68500000-0000-0000-0000-000000000003');
select admin_set_room_timetable_slot('token_admin', '68400000-0000-0000-0000-000000000001', 'ม.1', '1', 1::smallint, 2::smallint, 'Science', '68500000-0000-0000-0000-000000000003');
select admin_set_room_timetable_slot('token_admin', '68400000-0000-0000-0000-000000000001', 'ม.1', '1', 2::smallint, 1::smallint, 'Math', '68500000-0000-0000-0000-000000000003');
select is((select filled_slots::int from list_timetable_overview('token_admin', '68400000-0000-0000-0000-000000000001') where room_key = 'ม.1/1'), 3, 'จัดแล้ว 3 คาบ');
select is((select student_count::int from list_timetable_overview('token_admin', '68400000-0000-0000-0000-000000000001') where room_key = 'ม.1/2'), 1, 'ม.1/2 มีนักเรียน 1');

-- 5. teacher week + conflict detection
select is((select count(*)::int from list_teacher_week('token_admin', '68400000-0000-0000-0000-000000000001', '68500000-0000-0000-0000-000000000003')), 3, 'ครูมี 3 คาบในสัปดาห์');
select is((select count(*)::int from list_teacher_conflicts('token_admin', '68400000-0000-0000-0000-000000000001')), 0, 'ยังไม่ชน');
select admin_set_room_timetable_slot('token_admin', '68400000-0000-0000-0000-000000000001', 'ม.1', '2', 1::smallint, 1::smallint, 'Math', '68500000-0000-0000-0000-000000000003');
select is((select count(*)::int from list_teacher_conflicts('token_admin', '68400000-0000-0000-0000-000000000001')), 1, 'ครูคนเดียวสอน 2 ห้อง จันทร์/คาบ 1 → ชน 1');
select is((select rooms from list_teacher_conflicts('token_admin', '68400000-0000-0000-0000-000000000001') limit 1), array['ม.1/1','ม.1/2']::text[], 'รายงานทั้งสองห้อง');
select throws_ok($$ select * from list_teacher_conflicts('token_teacher', '68400000-0000-0000-0000-000000000001') $$, 'forbidden', 'ครูดูรายการชนทั้งโรงเรียนไม่ได้');

-- 6. copy ม.1/1 → ม.1/2 (replaces the one slot there), students of ม.1/2 land in the new courses
select is(admin_copy_room_timetable('token_admin', '68400000-0000-0000-0000-000000000001', 'ม.1', '1', '68400000-0000-0000-0000-000000000001', 'ม.1', '2'), 3, 'คัดลอก 3 คาบ');
select is((select filled_slots::int from list_timetable_overview('token_admin', '68400000-0000-0000-0000-000000000001') where room_key = 'ม.1/2'), 3, 'ม.1/2 ได้ 3 คาบ (ของเดิม 1 คาบถูกแทน)');
select is((select count(*)::int from list_my_courses('token_student')), 2, 'นักเรียน ม.1/1 เห็น Math + Science ที่เกิดจากตารางโดยไม่มีใครกดเพิ่ม');
select throws_ok($$ select admin_copy_room_timetable('token_admin', '68400000-0000-0000-0000-000000000001', 'ม.1', '1', '68400000-0000-0000-0000-000000000001', 'ม.1', 'ม.1/1') $$, 'same_room', 'คัดลอกทับตัวเอง → same_room');

-- 7. copy from last term into the new term for the same room, then clear
select is(admin_copy_room_timetable('token_admin', '68400000-0000-0000-0000-000000000001', 'ม.1', '1', '68400000-0000-0000-0000-000000000003', 'ม.1', '1'), 3, 'ใช้ตารางเทอมที่แล้ว → 3 คาบในเทอมใหม่');
select is(admin_clear_room_timetable('token_admin', '68400000-0000-0000-0000-000000000003', 'ม.1', '1'), 3, 'ล้างเทอมใหม่ได้ 3');

SELECT * FROM finish();
ROLLBACK;
