-- admin_token_patched
-- list_lesson_progress (20260916010000) — ครูอ่านความคืบหน้าบทเรียนรายคน
begin;

create extension if not exists pgtap with schema extensions;
select plan(9);

insert into packages (id, name, license_type)
values ('61100000-0000-0000-0000-000000000001', 'Lesson progress package', 'perpetual');
insert into schools (id, package_id, name, school_code) values
  ('61200000-0000-0000-0000-000000000001', '61100000-0000-0000-0000-000000000001', 'LP school A', 'LP-A'),
  ('61200000-0000-0000-0000-000000000002', '61100000-0000-0000-0000-000000000001', 'LP school B', 'LP-B');
insert into academic_years (id, school_id, name)
values ('61300000-0000-0000-0000-000000000001', '61200000-0000-0000-0000-000000000001', '2026');
insert into terms (id, academic_year_id, name)
values ('61400000-0000-0000-0000-000000000001', '61300000-0000-0000-0000-000000000001', 'Term 1/2026');

insert into users (id, school_id, email, password_hash, first_name, last_name, created_by) values
  ('61900000-0000-0000-0000-000000000000', '61200000-0000-0000-0000-000000000001', 'admin61@pdpa.test', crypt('x', gen_salt('bf')), 'Admin', 'Patch', '61900000-0000-0000-0000-000000000000'),
  ('61500000-0000-0000-0000-000000000001', '61200000-0000-0000-0000-000000000001', 'lp-teacher@pdpa.test', crypt('x', gen_salt('bf')), 'Teacher', 'A', '61500000-0000-0000-0000-000000000001'),
  ('61500000-0000-0000-0000-000000000002', '61200000-0000-0000-0000-000000000001', 'lp-s1@pdpa.test', crypt('x', gen_salt('bf')), 'Anan', 'One', '61500000-0000-0000-0000-000000000001'),
  ('61500000-0000-0000-0000-000000000003', '61200000-0000-0000-0000-000000000001', 'lp-s2@pdpa.test', crypt('x', gen_salt('bf')), 'Boon', 'Two', '61500000-0000-0000-0000-000000000001'),
  ('61500000-0000-0000-0000-000000000004', '61200000-0000-0000-0000-000000000001', 'lp-other-teacher@pdpa.test', crypt('x', gen_salt('bf')), 'Other', 'T', '61500000-0000-0000-0000-000000000001'),
  ('61500000-0000-0000-0000-000000000005', '61200000-0000-0000-0000-000000000002', 'lp-teacher-b@pdpa.test', crypt('x', gen_salt('bf')), 'Teacher', 'B', '61500000-0000-0000-0000-000000000005');
insert into user_roles (user_id, role, school_id, granted_by) values
  ('61900000-0000-0000-0000-000000000000', 'school_admin', '61200000-0000-0000-0000-000000000001', '61900000-0000-0000-0000-000000000000'),
  ('61500000-0000-0000-0000-000000000001', 'teacher', '61200000-0000-0000-0000-000000000001', '61500000-0000-0000-0000-000000000001'),
  ('61500000-0000-0000-0000-000000000002', 'student', '61200000-0000-0000-0000-000000000001', '61500000-0000-0000-0000-000000000001'),
  ('61500000-0000-0000-0000-000000000003', 'student', '61200000-0000-0000-0000-000000000001', '61500000-0000-0000-0000-000000000001'),
  ('61500000-0000-0000-0000-000000000004', 'teacher', '61200000-0000-0000-0000-000000000001', '61500000-0000-0000-0000-000000000001'),
  ('61500000-0000-0000-0000-000000000005', 'teacher', '61200000-0000-0000-0000-000000000002', '61500000-0000-0000-0000-000000000005');
insert into sessions (user_id, active_role, active_school_id, token_hash, expires_at) values
  ('61900000-0000-0000-0000-000000000000', 'school_admin', '61200000-0000-0000-0000-000000000001', encode(digest('admin-token-patched-61', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('61500000-0000-0000-0000-000000000001', 'teacher', '61200000-0000-0000-0000-000000000001', encode(digest('lp-teacher', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('61500000-0000-0000-0000-000000000002', 'student', '61200000-0000-0000-0000-000000000001', encode(digest('lp-s1', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('61500000-0000-0000-0000-000000000003', 'student', '61200000-0000-0000-0000-000000000001', encode(digest('lp-s2', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('61500000-0000-0000-0000-000000000004', 'teacher', '61200000-0000-0000-0000-000000000001', encode(digest('lp-other-teacher', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('61500000-0000-0000-0000-000000000005', 'teacher', '61200000-0000-0000-0000-000000000002', encode(digest('lp-teacher-b', 'sha256'), 'hex'), now() + interval '1 hour');

create temporary table c as
select * from create_course('admin-token-patched-61', '61400000-0000-0000-0000-000000000001', 'Science', 'M.3', 'R1', null, '61500000-0000-0000-0000-000000000001');
select enroll_student('admin-token-patched-61', (select course_id from c), '61500000-0000-0000-0000-000000000002');
select enroll_student('admin-token-patched-61', (select course_id from c), '61500000-0000-0000-0000-000000000003');
create temporary table l as
select * from create_lesson('lp-teacher', (select course_id from c), 'Lesson 1', '{}'::jsonb);
select publish_lesson('lp-teacher', (select lesson_id from l));

-- ก่อนมีใครเปิด: ทุกคนอยู่ในรายชื่อ progress 0
select is((select count(*)::int from list_lesson_progress('lp-teacher', (select lesson_id from l))), 2, 'นักเรียนทุกคนในวิชาอยู่ในรายชื่อแม้ยังไม่เปิดบทเรียน');
select is((select progress_pct from list_lesson_progress('lp-teacher', (select lesson_id from l)) where email='lp-s1@pdpa.test'), 0::numeric, 'ยังไม่เปิด = 0% ไม่ใช่ null/หายไป');
select is((select completed from list_lesson_progress('lp-teacher', (select lesson_id from l)) where email='lp-s1@pdpa.test'), false, 'ยังไม่เปิด = ยังไม่จบ');

-- นักเรียน 1 อ่าน 40% · นักเรียน 2 จบแล้ว
select update_lesson_progress('lp-s1', (select lesson_id from l), 40);
select mark_lesson_complete('lp-s2', (select lesson_id from l));
select is((select progress_pct from list_lesson_progress('lp-teacher', (select lesson_id from l)) where email='lp-s1@pdpa.test'), 40::numeric, 'อ่านกลับค่าที่นักเรียนเขียนจริง');
select is((select completed from list_lesson_progress('lp-teacher', (select lesson_id from l)) where email='lp-s2@pdpa.test'), true, 'คนที่กดจบเห็นเป็นจบ');
select isnt((select completed_at from list_lesson_progress('lp-teacher', (select lesson_id from l)) where email='lp-s2@pdpa.test'), null, 'มีเวลาจบ');

-- สิทธิ์
select throws_ok($$ select * from list_lesson_progress('lp-other-teacher', (select lesson_id from l)) $$, 'forbidden', 'ครูที่ไม่ได้สอนวิชานี้อ่านไม่ได้');
select throws_ok($$ select * from list_lesson_progress('lp-teacher-b', (select lesson_id from l)) $$, 'forbidden', 'ครูโรงเรียนอื่นอ่านไม่ได้');
select throws_ok($$ select * from list_lesson_progress('lp-s1', (select lesson_id from l)) $$, 'forbidden', 'นักเรียนอ่านสถิติของเพื่อนไม่ได้');

select * from finish();
rollback;
