-- pgTAP Tests: ฝ่าย / กลุ่มสาระ (departments, department_members, staff_profiles)
--
-- The gates that matter here: school_admin owns the structure, executive can
-- only read it, teachers and students cannot see it at all, and nothing may
-- reach across schools even with a valid session.

begin;

create extension if not exists pgtap with schema extensions;
select plan(18);

insert into packages (id, name, license_type)
values ('99100000-0000-0000-0000-000000000001', 'Org test package', 'perpetual');

insert into schools (id, package_id, name, school_code) values
  ('99200000-0000-0000-0000-000000000001', '99100000-0000-0000-0000-000000000001', 'Org School A', 'ORG-A'),
  ('99200000-0000-0000-0000-000000000002', '99100000-0000-0000-0000-000000000001', 'Org School B', 'ORG-B');

insert into users (
  id, school_id, email, password_hash, first_name, last_name, created_by
) values
  ('99500000-0000-0000-0000-000000000001', '99200000-0000-0000-0000-000000000001',
   'org-admin@test.local', crypt('pass', gen_salt('bf')), 'Org', 'Admin', '99500000-0000-0000-0000-000000000001'),
  ('99500000-0000-0000-0000-000000000002', '99200000-0000-0000-0000-000000000001',
   'org-exec@test.local', crypt('pass', gen_salt('bf')), 'Org', 'Executive', '99500000-0000-0000-0000-000000000001'),
  ('99500000-0000-0000-0000-000000000003', '99200000-0000-0000-0000-000000000001',
   'org-teacher@test.local', crypt('pass', gen_salt('bf')), 'Org', 'Teacher', '99500000-0000-0000-0000-000000000001'),
  ('99500000-0000-0000-0000-000000000004', '99200000-0000-0000-0000-000000000001',
   'org-student@test.local', crypt('pass', gen_salt('bf')), 'Org', 'Student', '99500000-0000-0000-0000-000000000001'),
  -- Same package, different school: the tenant-isolation subject.
  ('99500000-0000-0000-0000-000000000005', '99200000-0000-0000-0000-000000000002',
   'org-outsider@test.local', crypt('pass', gen_salt('bf')), 'Org', 'Outsider', '99500000-0000-0000-0000-000000000005');

insert into user_roles (user_id, role, school_id, granted_by) values
  ('99500000-0000-0000-0000-000000000001', 'school_admin', '99200000-0000-0000-0000-000000000001', '99500000-0000-0000-0000-000000000001'),
  ('99500000-0000-0000-0000-000000000002', 'executive',    '99200000-0000-0000-0000-000000000001', '99500000-0000-0000-0000-000000000001'),
  ('99500000-0000-0000-0000-000000000003', 'teacher',      '99200000-0000-0000-0000-000000000001', '99500000-0000-0000-0000-000000000001'),
  ('99500000-0000-0000-0000-000000000004', 'student',      '99200000-0000-0000-0000-000000000001', '99500000-0000-0000-0000-000000000001'),
  ('99500000-0000-0000-0000-000000000005', 'teacher',      '99200000-0000-0000-0000-000000000002', '99500000-0000-0000-0000-000000000005');

insert into sessions (user_id, active_role, active_school_id, token_hash, expires_at) values
  ('99500000-0000-0000-0000-000000000001', 'school_admin', '99200000-0000-0000-0000-000000000001',
   encode(digest('org-admin-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('99500000-0000-0000-0000-000000000002', 'executive', '99200000-0000-0000-0000-000000000001',
   encode(digest('org-exec-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('99500000-0000-0000-0000-000000000003', 'teacher', '99200000-0000-0000-0000-000000000001',
   encode(digest('org-teacher-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('99500000-0000-0000-0000-000000000004', 'student', '99200000-0000-0000-0000-000000000001',
   encode(digest('org-student-token', 'sha256'), 'hex'), now() + interval '1 hour');

-- ---------------------------------------------------------------------------
-- create_department
-- ---------------------------------------------------------------------------

select lives_ok(
  $$ select create_department('org-admin-token', 'ฝ่ายวิชาการ', 'administrative', 1) $$,
  'school_admin can create an administrative department'
);

select lives_ok(
  $$ select create_department('org-admin-token', 'วิทยาศาสตร์', 'subject_group', 1) $$,
  'school_admin can create a subject group'
);

select throws_ok(
  $$ select create_department('org-exec-token', 'ฝ่ายลอง', 'administrative', 1) $$,
  'forbidden',
  'executive cannot create a department — it reads the structure, it does not own it'
);

select throws_ok(
  $$ select create_department('org-teacher-token', 'ฝ่ายลอง', 'administrative', 1) $$,
  'forbidden',
  'teacher cannot create a department'
);

select throws_ok(
  $$ select create_department('org-admin-token', 'ฝ่ายลอง', 'ไม่ถูกต้อง', 1) $$,
  'invalid_kind',
  'kind is constrained to administrative / subject_group'
);

select throws_ok(
  $$ select create_department('org-admin-token', '   ', 'administrative', 1) $$,
  'name_required',
  'a whitespace-only name is refused rather than stored'
);

select throws_ok(
  $$ select create_department('not-a-real-token', 'ฝ่ายลอง', 'administrative', 1) $$,
  'invalid_session',
  'an unknown token is refused'
);

-- ---------------------------------------------------------------------------
-- list_departments
-- ---------------------------------------------------------------------------

select is(
  (select count(*)::int from list_departments('org-exec-token')),
  2,
  'executive can read the structure'
);

select is(
  (select count(*)::int from list_departments('org-admin-token', 'subject_group')),
  1,
  'the kind filter narrows to subject groups'
);

select throws_ok(
  $$ select * from list_departments('org-student-token') $$,
  'forbidden',
  'a student cannot read the staff structure'
);

-- ---------------------------------------------------------------------------
-- Membership
-- ---------------------------------------------------------------------------

select lives_ok(
  $$ select set_department_member(
       'org-admin-token',
       (select id from departments where name = 'ฝ่ายวิชาการ'
            and school_id = '99200000-0000-0000-0000-000000000001'),
       '99500000-0000-0000-0000-000000000003',
       true) $$,
  'school_admin can assign a teacher as head of a department'
);

-- The UI can re-send the same assignment; it must not duplicate the row.
select lives_ok(
  $$ select set_department_member(
       'org-admin-token',
       (select id from departments where name = 'ฝ่ายวิชาการ'
            and school_id = '99200000-0000-0000-0000-000000000001'),
       '99500000-0000-0000-0000-000000000003',
       true) $$,
  'assigning the same person twice is idempotent'
);

select is(
  (select member_count from list_departments('org-exec-token', 'administrative')),
  1,
  'the repeat assignment did not create a second membership'
);

select is(
  (select head_name from list_departments('org-exec-token', 'administrative')),
  'Org Teacher',
  'is_head is reported as the department head'
);

-- The isolation case: a valid school_admin session must not be able to pull a
-- person from another school into its own structure.
select throws_ok(
  $$ select set_department_member(
       'org-admin-token',
       (select id from departments where name = 'ฝ่ายวิชาการ'
            and school_id = '99200000-0000-0000-0000-000000000001'),
       '99500000-0000-0000-0000-000000000005',
       false) $$,
  'forbidden',
  'a member from another school cannot be assigned'
);

select lives_ok(
  $$ select remove_department_member(
       'org-admin-token',
       (select id from departments where name = 'ฝ่ายวิชาการ'
            and school_id = '99200000-0000-0000-0000-000000000001'),
       '99500000-0000-0000-0000-000000000003') $$,
  'school_admin can remove a membership'
);

-- ---------------------------------------------------------------------------
-- staff_profiles / directory
-- ---------------------------------------------------------------------------

select lives_ok(
  $$ select set_staff_profile(
       'org-admin-token', '99500000-0000-0000-0000-000000000003',
       'ครูชำนาญการ', '081-000-0000') $$,
  'school_admin can set a position title and phone'
);

-- Students and parents are not staff and must not appear in the directory.
select is(
  (select count(*)::int from list_staff_directory('org-exec-token')),
  3,
  'the directory lists staff only — the student is excluded'
);

rollback;
