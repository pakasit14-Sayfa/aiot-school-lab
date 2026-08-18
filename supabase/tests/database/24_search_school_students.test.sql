-- pgTAP Tests: search_school_students RPC

begin;

create extension if not exists pgtap with schema extensions;
select plan(5);

insert into packages (id, name, license_type)
values ('99100000-0000-0000-0000-000000000001', 'AIoT Lab package', 'perpetual');

insert into schools (id, package_id, name, school_code) values
  ('99200000-0000-0000-0000-000000000001', '99100000-0000-0000-0000-000000000001', 'School A', 'SCH-A'),
  ('99200000-0000-0000-0000-000000000002', '99100000-0000-0000-0000-000000000001', 'School B', 'SCH-B');

insert into users (
  id, school_id, email, password_hash, first_name, last_name, created_by
) values
  ('99500000-0000-0000-0000-000000000001', '99200000-0000-0000-0000-000000000001',
   'teacherA@test.local', crypt('pass', gen_salt('bf')), 'Teacher', 'Alpha', '99500000-0000-0000-0000-000000000001'),
  ('99500000-0000-0000-0000-000000000002', '99200000-0000-0000-0000-000000000001',
   'studentA1@test.local', crypt('pass', gen_salt('bf')), 'Sompong', 'Jaiyuen', '99500000-0000-0000-0000-000000000001'),
  ('99500000-0000-0000-0000-000000000003', '99200000-0000-0000-0000-000000000001',
   'studentA2@test.local', crypt('pass', gen_salt('bf')), 'Somchai', 'Deedee', '99500000-0000-0000-0000-000000000001'),
  ('99500000-0000-0000-0000-000000000004', '99200000-0000-0000-0000-000000000002',
   'studentB1@test.local', crypt('pass', gen_salt('bf')), 'Somying', 'OtherSchool', '99500000-0000-0000-0000-000000000001');

insert into user_roles (user_id, role, school_id, granted_by) values
  ('99500000-0000-0000-0000-000000000001', 'teacher', '99200000-0000-0000-0000-000000000001', '99500000-0000-0000-0000-000000000001'),
  ('99500000-0000-0000-0000-000000000002', 'student', '99200000-0000-0000-0000-000000000001', '99500000-0000-0000-0000-000000000001'),
  ('99500000-0000-0000-0000-000000000003', 'student', '99200000-0000-0000-0000-000000000001', '99500000-0000-0000-0000-000000000001'),
  ('99500000-0000-0000-0000-000000000004', 'student', '99200000-0000-0000-0000-000000000002', '99500000-0000-0000-0000-000000000001');

insert into sessions (user_id, active_role, active_school_id, token_hash, expires_at) values
  ('99500000-0000-0000-0000-000000000001', 'teacher', '99200000-0000-0000-0000-000000000001',
   encode(digest('teacherA-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('99500000-0000-0000-0000-000000000002', 'student', '99200000-0000-0000-0000-000000000001',
   encode(digest('studentA1-token', 'sha256'), 'hex'), now() + interval '1 hour');

-- 1. Empty query returns all students in School A (2 students)
select is(
  (select count(*)::int from search_school_students('teacherA-token', '')),
  2,
  'Teacher A can search and see all 2 students in School A'
);

-- 2. Query filter works
select is(
  (select count(*)::int from search_school_students('teacherA-token', 'Sompong')),
  1,
  'Teacher A query for Sompong returns 1 matching student'
);

-- 3. Tenant isolation: student from School B is not returned
select is(
  (select count(*)::int from search_school_students('teacherA-token', 'OtherSchool')),
  0,
  'Teacher A cannot see students from School B'
);

-- 4. Role guard: Student cannot search school students
prepare student_search as select search_school_students('studentA1-token', '');
select throws_ok('student_search', 'forbidden', 'Student role is forbidden from searching school students');

-- 5. Role guard: Invalid token throws invalid_session
prepare invalid_token as select search_school_students('invalid-token', '');
select throws_ok('invalid_token', 'invalid_session', 'Invalid session token throws invalid_session');

select * from finish();
rollback;
