-- set_student_profile (20260917010000) — ตัวเขียน student_profiles ตัวแรกของระบบ
begin;

create extension if not exists pgtap with schema extensions;
select plan(12);

insert into packages (id, name, license_type)
values ('63100000-0000-0000-0000-000000000001', 'SP package', 'perpetual');
insert into schools (id, package_id, name, school_code) values
  ('63200000-0000-0000-0000-000000000001', '63100000-0000-0000-0000-000000000001', 'SP school A', 'SP-A'),
  ('63200000-0000-0000-0000-000000000002', '63100000-0000-0000-0000-000000000001', 'SP school B', 'SP-B');
insert into academic_years (id, school_id, name)
values ('63300000-0000-0000-0000-000000000001', '63200000-0000-0000-0000-000000000001', '2569');

insert into users (id, school_id, email, password_hash, first_name, last_name, created_by) values
  ('63500000-0000-0000-0000-000000000001', '63200000-0000-0000-0000-000000000001', 'sp-admin@pdpa.test', crypt('x', gen_salt('bf')), 'Admin', 'A', '63500000-0000-0000-0000-000000000001'),
  ('63500000-0000-0000-0000-000000000002', '63200000-0000-0000-0000-000000000001', 'sp-student@pdpa.test', crypt('x', gen_salt('bf')), 'Stu', 'One', '63500000-0000-0000-0000-000000000001'),
  ('63500000-0000-0000-0000-000000000003', '63200000-0000-0000-0000-000000000001', 'sp-teacher@pdpa.test', crypt('x', gen_salt('bf')), 'Tea', 'Cher', '63500000-0000-0000-0000-000000000001'),
  ('63500000-0000-0000-0000-000000000004', '63200000-0000-0000-0000-000000000002', 'sp-admin-b@pdpa.test', crypt('x', gen_salt('bf')), 'Admin', 'B', '63500000-0000-0000-0000-000000000004');
insert into user_roles (user_id, role, school_id, granted_by) values
  ('63500000-0000-0000-0000-000000000001', 'school_admin', '63200000-0000-0000-0000-000000000001', '63500000-0000-0000-0000-000000000001'),
  ('63500000-0000-0000-0000-000000000002', 'student',      '63200000-0000-0000-0000-000000000001', '63500000-0000-0000-0000-000000000001'),
  ('63500000-0000-0000-0000-000000000003', 'teacher',      '63200000-0000-0000-0000-000000000001', '63500000-0000-0000-0000-000000000001'),
  ('63500000-0000-0000-0000-000000000004', 'school_admin', '63200000-0000-0000-0000-000000000002', '63500000-0000-0000-0000-000000000004');
insert into sessions (user_id, active_role, active_school_id, token_hash, expires_at) values
  ('63500000-0000-0000-0000-000000000001', 'school_admin', '63200000-0000-0000-0000-000000000001', encode(digest('sp-admin', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('63500000-0000-0000-0000-000000000003', 'teacher',      '63200000-0000-0000-0000-000000000001', encode(digest('sp-teacher', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('63500000-0000-0000-0000-000000000004', 'school_admin', '63200000-0000-0000-0000-000000000002', encode(digest('sp-admin-b', 'sha256'), 'hex'), now() + interval '1 hour');

select lives_ok($$ select set_student_profile('sp-admin', '63500000-0000-0000-0000-000000000002', 'ม.1', '1') $$, 'school_admin กำหนดชั้น/ห้องได้');
select is((select grade_level||'/'||room from student_profiles where student_id='63500000-0000-0000-0000-000000000002'), 'ม.1/1', 'แถวถูกสร้างในปีการศึกษาปัจจุบัน');
select is((select grade_level from list_school_students('sp-admin') where student_id='63500000-0000-0000-0000-000000000002'), 'ม.1', 'หน้านักเรียนอ่านค่าที่เพิ่งตั้งได้ทันที');

select lives_ok($$ select set_student_profile('sp-admin', '63500000-0000-0000-0000-000000000002', 'ม.2', '3') $$, 'ตั้งซ้ำ = แก้ไข ไม่ใช่แถวซ้ำ');
select is((select count(*)::int from student_profiles where student_id='63500000-0000-0000-0000-000000000002'), 1, 'ยังมีแถวเดียวต่อปี');
select is((select room from student_profiles where student_id='63500000-0000-0000-0000-000000000002'), '3', 'ห้องถูกอัปเดต');

select throws_ok($$ select set_student_profile('sp-admin', '63500000-0000-0000-0000-000000000002', 'ม.2', '') $$, 'missing_required_field', 'ชั้นมีแต่ห้องว่างไม่รับ');
select throws_ok($$ select set_student_profile('sp-teacher', '63500000-0000-0000-0000-000000000002', 'ม.1', '1') $$, 'forbidden', 'ครูตั้งไม่ได้');
select throws_ok($$ select set_student_profile('sp-admin-b', '63500000-0000-0000-0000-000000000002', 'ม.1', '1') $$, 'forbidden', 'แอดมินโรงเรียนอื่นตั้งไม่ได้');
select throws_ok($$ select set_student_profile('sp-admin', '63500000-0000-0000-0000-000000000003', 'ม.1', '1') $$, 'not_a_student', 'ตั้งให้ครูไม่ได้');

-- import with grade/room writes student_profiles too
select lives_ok($$ select import_school_users_batch_for_school_admin('sp-admin', 'student',
  '[{"email":"sp-new@pdpa.test","first_name":"New","last_name":"Kid","grade_level":"ป.6","room":"2"}]'::jsonb) $$,
  'นำเข้านักเรียนพร้อมชั้น/ห้องได้');
select is((select sp.grade_level||'/'||sp.room from student_profiles sp join users u on u.id=sp.student_id where u.email='sp-new@pdpa.test'), 'ป.6/2',
  'แถวนำเข้าได้ student_profiles ทันที');

select * from finish();
rollback;
