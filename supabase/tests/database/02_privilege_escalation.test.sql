begin;

create extension if not exists pgtap with schema extensions;

select plan(2);

insert into packages (id, name, license_type)
values ('10000000-0000-0000-0000-000000000001', 'PDPA test package', 'perpetual');

insert into schools (id, package_id, name, school_code)
values (
  '20000000-0000-0000-0000-000000000001',
  '10000000-0000-0000-0000-000000000001',
  'PDPA test school',
  'PDPA-TEST'
);

insert into users (id, school_id, email, password_hash, first_name, last_name)
values
  (
    '30000000-0000-0000-0000-000000000001',
    '20000000-0000-0000-0000-000000000001',
    'school-admin@pdpa.test',
    crypt('irrelevant', gen_salt('bf')),
    'School',
    'Admin'
  ),
  (
    '30000000-0000-0000-0000-000000000002',
    '20000000-0000-0000-0000-000000000001',
    'student@pdpa.test',
    crypt('irrelevant', gen_salt('bf')),
    'Test',
    'Student'
  );

insert into user_roles (user_id, role, school_id, granted_by)
values
  (
    '30000000-0000-0000-0000-000000000001',
    'school_admin',
    '20000000-0000-0000-0000-000000000001',
    '30000000-0000-0000-0000-000000000001'
  ),
  (
    '30000000-0000-0000-0000-000000000002',
    'student',
    '20000000-0000-0000-0000-000000000001',
    '30000000-0000-0000-0000-000000000001'
  );

insert into sessions (user_id, active_role, active_school_id, token_hash, expires_at)
values (
  '30000000-0000-0000-0000-000000000001',
  'school_admin',
  '20000000-0000-0000-0000-000000000001',
  encode(digest('pdpa-school-admin-token', 'sha256'), 'hex'),
  now() + interval '1 hour'
);

select throws_ok(
  $$select update_user_role(
    'pdpa-school-admin-token',
    '30000000-0000-0000-0000-000000000002',
    'super_admin'
  )$$,
  'P0001',
  'forbidden_role_grant',
  'school admin cannot grant the super_admin role'
);

select results_eq(
  $$select role::text from user_roles
    where user_id = '30000000-0000-0000-0000-000000000002'
    order by role::text$$,
  array['student'::text],
  'failed privilege escalation leaves the target role unchanged'
);

select * from finish();
rollback;
