begin;

create extension if not exists pgtap with schema extensions;
select plan(9);

insert into packages (id, name, license_type)
values ('95000000-0000-0000-0000-000000000001', 'Exec stats test package', 'perpetual');

insert into schools (id, package_id, name, school_code) values
  ('95000000-0000-0000-0000-000000000002', '95000000-0000-0000-0000-000000000001', 'Exec stats school', 'EXECSTAT'),
  ('95000000-0000-0000-0000-000000000009', '95000000-0000-0000-0000-000000000001', 'Other school', 'OTHERSCH');

insert into users (
  id, school_id, email, password_hash, first_name, last_name, created_by
) values
  (
    '95000000-0000-0000-0000-000000000003',
    '95000000-0000-0000-0000-000000000002',
    'exec-stats-exec@execstat.test', crypt('irrelevant', gen_salt('bf')),
    'Executive', 'A', '95000000-0000-0000-0000-000000000003'
  ),
  (
    '95000000-0000-0000-0000-000000000004',
    '95000000-0000-0000-0000-000000000002',
    'exec-stats-teacher@execstat.test', crypt('irrelevant', gen_salt('bf')),
    'Teacher', 'B', '95000000-0000-0000-0000-000000000003'
  ),
  (
    '95000000-0000-0000-0000-000000000005',
    '95000000-0000-0000-0000-000000000002',
    'exec-stats-student1@execstat.test', crypt('irrelevant', gen_salt('bf')),
    'Student', 'One', '95000000-0000-0000-0000-000000000003'
  ),
  (
    '95000000-0000-0000-0000-000000000006',
    '95000000-0000-0000-0000-000000000002',
    'exec-stats-student2@execstat.test', crypt('irrelevant', gen_salt('bf')),
    'Student', 'Two', '95000000-0000-0000-0000-000000000003'
  ),
  (
    '95000000-0000-0000-0000-000000000010',
    '95000000-0000-0000-0000-000000000009',
    'exec-stats-other-school-student@execstat.test', crypt('irrelevant', gen_salt('bf')),
    'Other', 'School', '95000000-0000-0000-0000-000000000003'
  );

insert into user_roles (user_id, role, school_id, granted_by) values
  ('95000000-0000-0000-0000-000000000003', 'executive', '95000000-0000-0000-0000-000000000002', '95000000-0000-0000-0000-000000000003'),
  ('95000000-0000-0000-0000-000000000004', 'teacher', '95000000-0000-0000-0000-000000000002', '95000000-0000-0000-0000-000000000003'),
  ('95000000-0000-0000-0000-000000000005', 'student', '95000000-0000-0000-0000-000000000002', '95000000-0000-0000-0000-000000000003'),
  ('95000000-0000-0000-0000-000000000006', 'student', '95000000-0000-0000-0000-000000000002', '95000000-0000-0000-0000-000000000003'),
  ('95000000-0000-0000-0000-000000000010', 'student', '95000000-0000-0000-0000-000000000009', '95000000-0000-0000-0000-000000000003');

insert into sessions (user_id, active_role, active_school_id, token_hash, expires_at) values
  ('95000000-0000-0000-0000-000000000003', 'executive', '95000000-0000-0000-0000-000000000002', encode(digest('exec-stats-exec-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('95000000-0000-0000-0000-000000000005', 'student', '95000000-0000-0000-0000-000000000002', encode(digest('exec-stats-student-token', 'sha256'), 'hex'), now() + interval '1 hour');

insert into devices (id, school_id, type, name, location, status, registered_by) values
  ('95000000-0000-0000-0000-000000000007', '95000000-0000-0000-0000-000000000002', 'pm25_sensor', 'PM2.5 อาคาร 1', 'อาคาร 1 ชั้น 1', 'online', '95000000-0000-0000-0000-000000000003'),
  ('95000000-0000-0000-0000-000000000008', '95000000-0000-0000-0000-000000000002', 'energy_meter', 'มิเตอร์ไฟ อาคาร 1', 'อาคาร 1 ชั้น 1', 'online', '95000000-0000-0000-0000-000000000003');

-- 1: executive can call count_school_users_by_role (no longer 'forbidden')
select lives_ok(
  $$select * from count_school_users_by_role('exec-stats-exec-token')$$,
  'executive can call count_school_users_by_role'
);

-- 2: it returns per-role counts, not individual rows — 2 students collapse to one row
select is(
  (select user_count::integer from count_school_users_by_role('exec-stats-exec-token') where active_role = 'student'),
  2,
  'student role count is aggregated correctly (2 students -> count 2)'
);

-- 3: result is aggregated by role (4 users in this school collapse into 3
-- role rows: executive, teacher, student — not 4 individual user rows, and
-- the returned columns are only active_role/user_count, no name/email)
select is(
  (select count(*)::integer from (
    select * from count_school_users_by_role('exec-stats-exec-token')
  ) t),
  3,
  '4 users in the school collapse into 3 aggregated role rows, not 4 individual rows'
);

-- 4: tenant isolation — the other school's student is not counted
select isnt(
  (select user_count::integer from count_school_users_by_role('exec-stats-exec-token') where active_role = 'student'),
  3,
  'other-school student is not included in this school''s count'
);

-- 5: student role cannot call count_school_users_by_role
select throws_ok(
  $$select * from count_school_users_by_role('exec-stats-student-token')$$,
  'P0001',
  'forbidden',
  'student role is forbidden from count_school_users_by_role'
);

-- 6: invalid token is rejected
select throws_ok(
  $$select * from count_school_users_by_role('not-a-real-token')$$,
  'P0001',
  'invalid_session',
  'invalid token raises invalid_session'
);

-- 7: executive can now call list_school_devices (was teacher/school_admin only before)
select lives_ok(
  $$select * from list_school_devices('exec-stats-exec-token')$$,
  'executive can call list_school_devices'
);

-- 8: it returns this school's devices
select is(
  (select count(*)::integer from list_school_devices('exec-stats-exec-token')),
  2,
  'executive sees both devices registered to their school'
);

-- 9: student role still forbidden from list_school_devices (role widening did not over-grant)
select throws_ok(
  $$select * from list_school_devices('exec-stats-student-token')$$,
  'P0001',
  'forbidden',
  'student role remains forbidden from list_school_devices'
);

select * from finish();
rollback;
