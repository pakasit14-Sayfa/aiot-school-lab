-- pgTAP Tests: AIoT Lab Teaching Kit RPCs (list_teaching_kit_devices, queue_teaching_kit_command, list_teaching_kit_command_history)

begin;

create extension if not exists pgtap with schema extensions;
select plan(8);

insert into packages (id, name, license_type)
values ('99100000-0000-0000-0000-000000000001', 'AIoT Lab package', 'perpetual');

insert into schools (id, package_id, name, school_code) values
  ('99200000-0000-0000-0000-000000000001', '99100000-0000-0000-0000-000000000001', 'AIoT School A', 'AIOT-A');


insert into users (
  id, school_id, email, password_hash, first_name, last_name, created_by
) values
  ('99500000-0000-0000-0000-000000000001', '99200000-0000-0000-0000-000000000001',
   'teacher1@test.local', crypt('pass', gen_salt('bf')), 'Teacher', 'One', '99500000-0000-0000-0000-000000000001'),
  ('99500000-0000-0000-0000-000000000002', '99200000-0000-0000-0000-000000000001',
   'teacher2@test.local', crypt('pass', gen_salt('bf')), 'Teacher', 'Two', '99500000-0000-0000-0000-000000000001'),
  ('99500000-0000-0000-0000-000000000003', '99200000-0000-0000-0000-000000000001',
   'student1@test.local', crypt('pass', gen_salt('bf')), 'Student', 'One', '99500000-0000-0000-0000-000000000001');

insert into user_roles (user_id, role, school_id, granted_by) values
  ('99500000-0000-0000-0000-000000000001', 'teacher', '99200000-0000-0000-0000-000000000001', '99500000-0000-0000-0000-000000000001'),
  ('99500000-0000-0000-0000-000000000002', 'teacher', '99200000-0000-0000-0000-000000000001', '99500000-0000-0000-0000-000000000001'),
  ('99500000-0000-0000-0000-000000000003', 'student', '99200000-0000-0000-0000-000000000001', '99500000-0000-0000-0000-000000000001');

insert into sessions (user_id, active_role, active_school_id, token_hash, expires_at) values
  ('99500000-0000-0000-0000-000000000001', 'teacher', '99200000-0000-0000-0000-000000000001',
   encode(digest('teacher1-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('99500000-0000-0000-0000-000000000002', 'teacher', '99200000-0000-0000-0000-000000000001',
   encode(digest('teacher2-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('99500000-0000-0000-0000-000000000003', 'student', '99200000-0000-0000-0000-000000000001',
   encode(digest('student1-token', 'sha256'), 'hex'), now() + interval '1 hour');

-- Insert course and course_teachers binding for teacher1
insert into academic_years (id, school_id, name) values
  ('99300000-0000-0000-0000-000000000001', '99200000-0000-0000-0000-000000000001', '2569');

insert into terms (id, academic_year_id, name) values
  ('99400000-0000-0000-0000-000000000001', '99300000-0000-0000-0000-000000000001', 'ภาคเรียนที่ 1/2569');

insert into courses (id, school_id, term_id, subject_name, grade_level, room, created_by) values
  ('99600000-0000-0000-0000-000000000001', '99200000-0000-0000-0000-000000000001', '99400000-0000-0000-0000-000000000001',
   'AIoT Bio Lab', 'ม.4/1', 'Lab 3', '99500000-0000-0000-0000-000000000001');

insert into course_teachers (course_id, teacher_id) values
  ('99600000-0000-0000-0000-000000000001', '99500000-0000-0000-0000-000000000001');

-- Insert devices: one teaching kit (bound to course) and one building device (course_id is null)
insert into devices (id, school_id, type, name, location, status, registered_by, course_id) values
  ('99700000-0000-0000-0000-000000000001', '99200000-0000-0000-0000-000000000001', 'relay', 'Kit LED', 'Lab 3', 'online', '99500000-0000-0000-0000-000000000001', '99600000-0000-0000-0000-000000000001'),
  ('99700000-0000-0000-0000-000000000002', '99200000-0000-0000-0000-000000000001', 'relay', 'Building Light', 'Hallway', 'online', '99500000-0000-0000-0000-000000000001', null);

-- 1. Test list_teaching_kit_devices
select is(
  (select count(*)::int from list_teaching_kit_devices('teacher1-token')),
  1,
  'Teacher 1 can see teaching kit device for their course'
);

select is(
  (select count(*)::int from list_teaching_kit_devices('teacher2-token')),
  0,
  'Teacher 2 (not teaching course) sees 0 devices'
);

-- 2. Test queue_teaching_kit_command
prepare t1_cmd as select queue_teaching_kit_command('teacher1-token', '99700000-0000-0000-0000-000000000001', '{"relay": 1, "state": "on"}'::jsonb);
select lives_ok('t1_cmd', 'Teacher 1 can queue command for their teaching kit device');

prepare t2_cmd as select queue_teaching_kit_command('teacher2-token', '99700000-0000-0000-0000-000000000001', '{"relay": 1, "state": "on"}'::jsonb);
select throws_ok('t2_cmd', 'forbidden', 'Teacher 2 is forbidden from commanding kit device of un-taught course');

prepare bldg_cmd as select queue_teaching_kit_command('teacher1-token', '99700000-0000-0000-0000-000000000002', '{"relay": 1, "state": "on"}'::jsonb);
select throws_ok('bldg_cmd', 'forbidden', 'Teacher is forbidden from commanding building device (course_id is null)');

prepare student_cmd as select queue_teaching_kit_command('student1-token', '99700000-0000-0000-0000-000000000001', '{"relay": 1, "state": "on"}'::jsonb);
select throws_ok('student_cmd', 'forbidden', 'Student is forbidden from queuing teaching kit commands');

-- 3. Test list_teaching_kit_command_history
select is(
  (select count(*)::int from list_teaching_kit_command_history('teacher1-token')),
  1,
  'Teacher 1 can view command history for their teaching kit'
);

select is(
  (select count(*)::int from list_teaching_kit_command_history('teacher2-token')),
  0,
  'Teacher 2 sees 0 command history for un-taught course'
);

select * from finish();
rollback;
