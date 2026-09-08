begin;

create extension if not exists pgtap with schema extensions;
select plan(8);

insert into packages (id, name, license_type)
values ('98100000-0000-0000-0000-000000000001', 'Permission matrix test package', 'perpetual');

insert into schools (id, package_id, name, school_code)
values ('98200000-0000-0000-0000-000000000001', '98100000-0000-0000-0000-000000000001', 'Permission matrix school', 'PERM-A');

insert into users (
  id, school_id, email, password_hash, first_name, last_name, created_by
) values
  ('98300000-0000-0000-0000-000000000001', '98200000-0000-0000-0000-000000000001',
   'perm-admin@pdpa.test', crypt('irrelevant', gen_salt('bf')), 'Admin', 'A',
   '98300000-0000-0000-0000-000000000001'),
  ('98300000-0000-0000-0000-000000000002', null,
   'perm-super@pdpa.test', crypt('irrelevant', gen_salt('bf')), 'Super', 'Admin',
   '98300000-0000-0000-0000-000000000001'),
  ('98300000-0000-0000-0000-000000000003', '98200000-0000-0000-0000-000000000001',
   'perm-teacher@pdpa.test', crypt('irrelevant', gen_salt('bf')), 'Teacher', 'A',
   '98300000-0000-0000-0000-000000000001');

insert into user_roles (user_id, role, school_id, granted_by) values
  ('98300000-0000-0000-0000-000000000001', 'school_admin', '98200000-0000-0000-0000-000000000001', '98300000-0000-0000-0000-000000000001'),
  ('98300000-0000-0000-0000-000000000002', 'super_admin', null, '98300000-0000-0000-0000-000000000001'),
  ('98300000-0000-0000-0000-000000000003', 'teacher', '98200000-0000-0000-0000-000000000001', '98300000-0000-0000-0000-000000000001');

insert into sessions (user_id, active_role, active_school_id, token_hash, expires_at) values
  ('98300000-0000-0000-0000-000000000001', 'school_admin', '98200000-0000-0000-0000-000000000001', encode(digest('perm-admin-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('98300000-0000-0000-0000-000000000002', 'super_admin', null, encode(digest('perm-super-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('98300000-0000-0000-0000-000000000003', 'teacher', '98200000-0000-0000-0000-000000000001', encode(digest('perm-teacher-token', 'sha256'), 'hex'), now() + interval '1 hour');

-- 1. missing/invalid token fails closed
select throws_ok(
  $$select * from list_role_permission_matrix(null)$$,
  'P0001', 'invalid_session',
  'a missing token cannot list the permission matrix'
);

-- 2. wrong role (teacher) is forbidden
select throws_ok(
  $$select * from list_role_permission_matrix('perm-teacher-token')$$,
  'P0001', 'forbidden',
  'a teacher cannot list the permission matrix'
);

-- 3. school_admin can call it
select lives_ok(
  $$select * from list_role_permission_matrix('perm-admin-token')$$,
  'school_admin can list the permission matrix'
);

-- 4. super_admin can call it too
select lives_ok(
  $$select * from list_role_permission_matrix('perm-super-token')$$,
  'super_admin can list the permission matrix'
);

-- 5. a real RPC's real role list comes back correctly — this is the actual
-- point of the feature: create_course really does gate on ('teacher',
-- 'school_admin') in its own live function body, not a hand-typed guess.
select ok(
  exists(
    select 1 from list_role_permission_matrix('perm-admin-token')
    where function_name = 'create_course'
      and 'teacher' = any(allowed_roles)
      and 'school_admin' = any(allowed_roles)
      and array_length(allowed_roles, 1) = 2
  ),
  'create_course reports its real ("teacher","school_admin") role gate'
);

-- 6. a role NOT in a function's gate is correctly absent
select ok(
  not exists(
    select 1 from list_role_permission_matrix('perm-admin-token')
    where function_name = 'create_course'
      and 'student' = any(allowed_roles)
  ),
  'create_course does not list a role it never grants'
);

-- 7. functions whose access check does not match the standard
-- "v_actor.role not in (...)" pattern report an honest null rather than a
-- guessed role list
select ok(
  exists(
    select 1 from list_role_permission_matrix('perm-admin-token')
    where function_name = '_assert_school_admin'
      and allowed_roles is null
  ),
  'a non-standard access-check function reports null, not a guess'
);

-- 8. no PUBLIC/service_role execute widening
select ok(
  not has_function_privilege('service_role', 'list_role_permission_matrix(text)', 'execute'),
  'service_role has no execute on list_role_permission_matrix'
);

select * from finish();
rollback;
