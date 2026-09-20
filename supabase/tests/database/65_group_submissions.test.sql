-- admin_token_patched
-- PBL-10 (2026-09-18): งานกลุ่ม — สมาชิกกลุ่มส่งร่วมกันในแถวเดียว
begin;

create extension if not exists pgtap with schema extensions;
select plan(13);

insert into packages (id, name, license_type)
values ('65100000-0000-0000-0000-000000000001', 'GS package', 'perpetual');
insert into schools (id, package_id, name, school_code) values
  ('65200000-0000-0000-0000-000000000001', '65100000-0000-0000-0000-000000000001', 'GS school', 'GS-A');
insert into academic_years (id, school_id, name)
values ('65300000-0000-0000-0000-000000000001', '65200000-0000-0000-0000-000000000001', '2026');
insert into terms (id, academic_year_id, name)
values ('65400000-0000-0000-0000-000000000001', '65300000-0000-0000-0000-000000000001', 'Term 1/2026');
insert into users (id, school_id, email, password_hash, first_name, last_name, created_by) values
  ('65900000-0000-0000-0000-000000000000', '65200000-0000-0000-0000-000000000001', 'admin65@pdpa.test', crypt('x', gen_salt('bf')), 'Admin', 'Patch', '65900000-0000-0000-0000-000000000000'),
  ('65500000-0000-0000-0000-000000000001', '65200000-0000-0000-0000-000000000001', 'gs-teacher@pdpa.test', crypt('x', gen_salt('bf')), 'Tea', 'Cher', '65500000-0000-0000-0000-000000000001'),
  ('65500000-0000-0000-0000-000000000002', '65200000-0000-0000-0000-000000000001', 'gs-s1@pdpa.test', crypt('x', gen_salt('bf')), 'Stu', 'One', '65500000-0000-0000-0000-000000000001'),
  ('65500000-0000-0000-0000-000000000003', '65200000-0000-0000-0000-000000000001', 'gs-s2@pdpa.test', crypt('x', gen_salt('bf')), 'Stu', 'Two', '65500000-0000-0000-0000-000000000001'),
  ('65500000-0000-0000-0000-000000000004', '65200000-0000-0000-0000-000000000001', 'gs-s3@pdpa.test', crypt('x', gen_salt('bf')), 'Stu', 'Three', '65500000-0000-0000-0000-000000000001');
insert into user_roles (user_id, role, school_id, granted_by) values
  ('65900000-0000-0000-0000-000000000000', 'school_admin', '65200000-0000-0000-0000-000000000001', '65900000-0000-0000-0000-000000000000'),
  ('65500000-0000-0000-0000-000000000001', 'teacher', '65200000-0000-0000-0000-000000000001', '65500000-0000-0000-0000-000000000001'),
  ('65500000-0000-0000-0000-000000000002', 'student', '65200000-0000-0000-0000-000000000001', '65500000-0000-0000-0000-000000000001'),
  ('65500000-0000-0000-0000-000000000003', 'student', '65200000-0000-0000-0000-000000000001', '65500000-0000-0000-0000-000000000001'),
  ('65500000-0000-0000-0000-000000000004', 'student', '65200000-0000-0000-0000-000000000001', '65500000-0000-0000-0000-000000000001');
insert into sessions (user_id, active_role, active_school_id, token_hash, expires_at) values
  ('65900000-0000-0000-0000-000000000000', 'school_admin', '65200000-0000-0000-0000-000000000001', encode(digest('admin-token-patched-65', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('65500000-0000-0000-0000-000000000001', 'teacher', '65200000-0000-0000-0000-000000000001', encode(digest('gs-teacher', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('65500000-0000-0000-0000-000000000002', 'student', '65200000-0000-0000-0000-000000000001', encode(digest('gs-s1', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('65500000-0000-0000-0000-000000000003', 'student', '65200000-0000-0000-0000-000000000001', encode(digest('gs-s2', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('65500000-0000-0000-0000-000000000004', 'student', '65200000-0000-0000-0000-000000000001', encode(digest('gs-s3', 'sha256'), 'hex'), now() + interval '1 hour');

create temporary table c as
select * from create_course('admin-token-patched-65', '65400000-0000-0000-0000-000000000001', 'AIoT', 'ม.1', '101', 'x', '65500000-0000-0000-0000-000000000001');
select enroll_student('admin-token-patched-65', (select course_id from c), '65500000-0000-0000-0000-000000000002');
select enroll_student('admin-token-patched-65', (select course_id from c), '65500000-0000-0000-0000-000000000003');
select enroll_student('admin-token-patched-65', (select course_id from c), '65500000-0000-0000-0000-000000000004');

-- กลุ่ม A = s1 + s2 · s3 ไม่มีกลุ่ม
create temporary table g as
select create_student_group('gs-teacher', (select course_id from c), 'กลุ่ม A') as id;
select add_group_member('gs-teacher', (select id from g), '65500000-0000-0000-0000-000000000002');
select add_group_member('gs-teacher', (select id from g), '65500000-0000-0000-0000-000000000003');

-- ── is_group ตั้งได้จริง ──
create temporary table ga as
select assignment_id from create_assignment('gs-teacher', (select course_id from c), 'homework', 'โครงงานกลุ่ม', null, null, null, true);
select is((select is_group from assignments where id = (select assignment_id from ga)), true, 'create_assignment(p_is_group => true) บันทึก is_group จริง');
create temporary table ia as
select assignment_id from create_assignment('gs-teacher', (select course_id from c), 'homework', 'งานเดี่ยว');
select is((select is_group from assignments where id = (select assignment_id from ia)), false, 'ค่าเริ่มต้นยังเป็นงานเดี่ยว');
select publish_assignment('gs-teacher', (select assignment_id from ga));
select publish_assignment('gs-teacher', (select assignment_id from ia));

-- ── ส่งงานกลุ่ม ──
create temporary table sub1 as
select * from submit_assignment('gs-s1', (select assignment_id from ga), 'ฉบับที่ 1 โดย s1');
select is((select group_id from submissions where id = (select submission_id from sub1)), (select id from g), 'การส่งของ s1 ผูกกับกลุ่ม A');
create temporary table sub2 as
select * from submit_assignment('gs-s2', (select assignment_id from ga), 'ฉบับที่ 2 โดย s2');
select is((select submission_id from sub2), (select submission_id from sub1), 's2 ส่งเข้าแถวเดียวกับ s1 (ไม่แตกแถวใหม่)');
select is((select version from sub2), 2, 'เป็นเวอร์ชัน 2 ของกลุ่ม');
select is((select count(*)::int from list_my_submission_versions('gs-s1', (select assignment_id from ga))), 2, 's1 เห็นทั้ง 2 เวอร์ชันของกลุ่ม');
select is((select count(*)::int from list_my_submission_versions('gs-s2', (select assignment_id from ga))), 2, 's2 ก็เห็นทั้ง 2 เวอร์ชัน');
select throws_ok($$ select * from submit_assignment('gs-s3', (select assignment_id from ga), 'ไม่มีกลุ่ม') $$, 'not_in_group', 'นักเรียนที่ยังไม่มีกลุ่มส่งงานกลุ่มไม่ได้');
select is((select count(*)::int from g_score_entries where source_id = (select assignment_id from ga) and source = 'assignment_on_time'), 2, 'G-Score ส่งตรงเวลาให้ทั้ง 2 สมาชิก');

-- ── ครูเห็นเป็นงานกลุ่ม ──
select is((select group_name from list_submissions('gs-teacher', (select assignment_id from ga)) limit 1), 'กลุ่ม A'::varchar, 'list_submissions บอกชื่อกลุ่ม');
select is((select count(*)::int from list_submissions('gs-teacher', (select assignment_id from ga))), 1, 'งานกลุ่ม 1 กลุ่ม = 1 แถว');

-- ── งานเดี่ยวยังแยกคน ──
select * from submit_assignment('gs-s1', (select assignment_id from ia), 'เดี่ยว s1');
select * from submit_assignment('gs-s2', (select assignment_id from ia), 'เดี่ยว s2');
select is((select count(*)::int from list_submissions('gs-teacher', (select assignment_id from ia))), 2, 'งานเดี่ยว 2 คน = 2 แถว group_name ว่าง');

-- ── สลับ is_group หลังมีคนส่งแล้ว ต้องไม่ได้ ──
select throws_ok($$ select update_assignment('gs-teacher', (select assignment_id from ga), null, null, null, null, false) $$, 'has_submissions', 'เปลี่ยนกลุ่ม→เดี่ยวหลังมีการส่งแล้วถูกปฏิเสธ');

select * from finish();
rollback;
