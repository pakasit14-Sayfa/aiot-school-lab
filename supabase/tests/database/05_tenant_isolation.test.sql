begin;

create extension if not exists pgtap with schema extensions;
select plan(10);

insert into packages (id, name, license_type)
values ('13000000-0000-0000-0000-000000000001', 'Tenant test package', 'perpetual');

insert into schools (id, package_id, name, school_code) values
  ('23000000-0000-0000-0000-000000000001', '13000000-0000-0000-0000-000000000001', 'Tenant school A', 'TENANT-A'),
  ('23000000-0000-0000-0000-000000000002', '13000000-0000-0000-0000-000000000001', 'Tenant school B', 'TENANT-B');

insert into users (
  id, school_id, email, password_hash, first_name, last_name, created_by
) values
  (
    '33000000-0000-0000-0000-000000000001',
    '23000000-0000-0000-0000-000000000001',
    'tenant-admin-a@pdpa.test', crypt('irrelevant', gen_salt('bf')),
    'Admin', 'A', '33000000-0000-0000-0000-000000000001'
  ),
  (
    '33000000-0000-0000-0000-000000000002',
    '23000000-0000-0000-0000-000000000001',
    'tenant-user-a@pdpa.test', crypt('irrelevant', gen_salt('bf')),
    'User', 'A', '33000000-0000-0000-0000-000000000001'
  ),
  (
    '33000000-0000-0000-0000-000000000003',
    '23000000-0000-0000-0000-000000000002',
    'tenant-user-b@pdpa.test', crypt('irrelevant', gen_salt('bf')),
    'User', 'B', '33000000-0000-0000-0000-000000000003'
  );

insert into user_roles (user_id, role, school_id, granted_by) values
  ('33000000-0000-0000-0000-000000000001', 'school_admin', '23000000-0000-0000-0000-000000000001', '33000000-0000-0000-0000-000000000001'),
  ('33000000-0000-0000-0000-000000000002', 'teacher', '23000000-0000-0000-0000-000000000001', '33000000-0000-0000-0000-000000000001'),
  ('33000000-0000-0000-0000-000000000003', 'teacher', '23000000-0000-0000-0000-000000000002', '33000000-0000-0000-0000-000000000003');

insert into sessions (
  user_id, active_role, active_school_id, token_hash, expires_at
) values (
  '33000000-0000-0000-0000-000000000001', 'school_admin',
  '23000000-0000-0000-0000-000000000001',
  encode(digest('tenant-admin-a-token', 'sha256'), 'hex'),
  now() + interval '1 hour'
);

select is(
  (select count(*)::integer
   from pg_class c join pg_namespace n on n.oid = c.relnamespace
   where n.nspname = 'public' and c.relkind in ('r', 'p')
     and not c.relrowsecurity),
  0,
  'RLS is enabled on every public table'
);

select ok(
  not has_table_privilege('anon', 'public.users', 'SELECT'),
  'anon cannot read users directly'
);

select ok(
  not has_table_privilege('authenticated', 'public.users', 'UPDATE'),
  'authenticated cannot update users directly'
);

select ok(
  not has_table_privilege('anon', 'public.parent_links', 'SELECT'),
  'anon cannot read parent links directly'
);

select ok(
  not has_table_privilege('authenticated', 'public.consents', 'SELECT'),
  'authenticated cannot read consents directly'
);

select is(
  (select count(*)::integer from list_school_users('tenant-admin-a-token')),
  2,
  'school admin lists only users in the active school'
);

select ok(
  not exists (
    select 1 from list_school_users('tenant-admin-a-token')
    where email = 'tenant-user-b@pdpa.test'
  ),
  'school B identity is absent from school A results'
);

select throws_ok(
  $$select update_user_profile(
    'tenant-admin-a-token',
    '33000000-0000-0000-0000-000000000003',
    'Compromised', 'Name'
  )$$,
  'P0001', 'forbidden',
  'school admin cannot update a user in another school'
);

select throws_ok(
  $$select update_user_role(
    'tenant-admin-a-token',
    '33000000-0000-0000-0000-000000000003',
    'school_admin'
  )$$,
  'P0001', 'forbidden',
  'school admin cannot grant roles in another school'
);

select is(
  (select first_name from users
   where id = '33000000-0000-0000-0000-000000000003'),
  'User',
  'failed cross-school mutation leaves the target unchanged'
);

select * from finish();
rollback;
