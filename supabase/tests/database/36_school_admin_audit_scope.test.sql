begin;

create extension if not exists pgtap with schema extensions;
select plan(9);

insert into packages (id, name, license_type)
values ('97100000-0000-0000-0000-000000000001', 'Audit scope test package', 'perpetual');

insert into schools (id, package_id, name, school_code) values
  ('97200000-0000-0000-0000-000000000001', '97100000-0000-0000-0000-000000000001', 'Audit scope school A', 'AUDIT-A'),
  ('97200000-0000-0000-0000-000000000002', '97100000-0000-0000-0000-000000000001', 'Audit scope school B', 'AUDIT-B');

insert into users (
  id, school_id, email, password_hash, first_name, last_name, created_by
) values
  ('97300000-0000-0000-0000-000000000001', '97200000-0000-0000-0000-000000000001',
   'audit-admin-a@pdpa.test', crypt('irrelevant', gen_salt('bf')), 'Admin', 'A',
   '97300000-0000-0000-0000-000000000001'),
  ('97300000-0000-0000-0000-000000000002', '97200000-0000-0000-0000-000000000002',
   'audit-admin-b@pdpa.test', crypt('irrelevant', gen_salt('bf')), 'Admin', 'B',
   '97300000-0000-0000-0000-000000000002'),
  ('97300000-0000-0000-0000-000000000003', '97200000-0000-0000-0000-000000000001',
   'audit-student-a@pdpa.test', crypt('irrelevant', gen_salt('bf')), 'Student', 'A',
   '97300000-0000-0000-0000-000000000001'),
  ('97300000-0000-0000-0000-000000000004', null,
   'audit-super@pdpa.test', crypt('irrelevant', gen_salt('bf')), 'Super', 'Admin',
   '97300000-0000-0000-0000-000000000001');

insert into user_roles (user_id, role, school_id, granted_by) values
  ('97300000-0000-0000-0000-000000000001', 'school_admin', '97200000-0000-0000-0000-000000000001', '97300000-0000-0000-0000-000000000001'),
  ('97300000-0000-0000-0000-000000000002', 'school_admin', '97200000-0000-0000-0000-000000000002', '97300000-0000-0000-0000-000000000002'),
  ('97300000-0000-0000-0000-000000000003', 'student', '97200000-0000-0000-0000-000000000001', '97300000-0000-0000-0000-000000000001'),
  ('97300000-0000-0000-0000-000000000004', 'super_admin', null, '97300000-0000-0000-0000-000000000001');

insert into sessions (user_id, active_role, active_school_id, token_hash, expires_at) values
  ('97300000-0000-0000-0000-000000000001', 'school_admin', '97200000-0000-0000-0000-000000000001', encode(digest('audit-admin-a-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('97300000-0000-0000-0000-000000000002', 'school_admin', '97200000-0000-0000-0000-000000000002', encode(digest('audit-admin-b-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('97300000-0000-0000-0000-000000000003', 'student', '97200000-0000-0000-0000-000000000001', encode(digest('audit-student-a-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('97300000-0000-0000-0000-000000000004', 'super_admin', null, encode(digest('audit-super-token', 'sha256'), 'hex'), now() + interval '1 hour');

-- one real audit row scoped to school A, one scoped to school B, and one
-- global/null-school row (mirrors real rows such as password-reset or
-- login/2FA events, which are user-account-level, not school-level)
insert into audit_logs (school_id, user_id, action, entity_type, details) values
  ('97200000-0000-0000-0000-000000000001', '97300000-0000-0000-0000-000000000001', 'audit_test_school_a', 'test', '{}'),
  ('97200000-0000-0000-0000-000000000002', '97300000-0000-0000-0000-000000000002', 'audit_test_school_b', 'test', '{}'),
  (null, '97300000-0000-0000-0000-000000000001', 'audit_test_global', 'test', '{}');

-- 1. missing/invalid token fails closed
select throws_ok(
  $$select * from list_school_admin_audit_logs(null, 20)$$,
  'P0001', 'invalid_session',
  'a missing token cannot list audit logs'
);

-- 2. wrong role (student) is forbidden
select throws_ok(
  $$select * from list_school_admin_audit_logs('audit-student-a-token', 20)$$,
  'P0001', 'forbidden',
  'a student cannot list audit logs'
);

-- 3. school_admin sees their own school's row
select ok(
  exists(
    select 1 from list_school_admin_audit_logs('audit-admin-a-token', 100)
    where action = 'audit_test_school_a'
  ),
  'school_admin A sees their own school''s audit row'
);

-- 4. school_admin does NOT see the other school's row
select ok(
  not exists(
    select 1 from list_school_admin_audit_logs('audit-admin-a-token', 100)
    where action = 'audit_test_school_b'
  ),
  'school_admin A cannot see school B''s audit row'
);

-- 5. the real fix: school_admin does NOT see the global/null-school row
select ok(
  not exists(
    select 1 from list_school_admin_audit_logs('audit-admin-a-token', 100)
    where action = 'audit_test_global'
  ),
  'school_admin A cannot see the global/null-school audit row'
);

-- 6. same isolation holds for school_admin B
select ok(
  not exists(
    select 1 from list_school_admin_audit_logs('audit-admin-b-token', 100)
    where action in ('audit_test_school_a', 'audit_test_global')
  ),
  'school_admin B sees neither school A''s row nor the global row'
);

-- 7. super_admin still sees every school's row (scope unchanged)
select ok(
  exists(
    select 1 from list_school_admin_audit_logs('audit-super-token', 100)
    where action = 'audit_test_school_a'
  ) and exists(
    select 1 from list_school_admin_audit_logs('audit-super-token', 100)
    where action = 'audit_test_school_b'
  ),
  'super_admin still sees both schools'' audit rows'
);

-- 8. super_admin still sees the global/null-school row (scope unchanged)
select ok(
  exists(
    select 1 from list_school_admin_audit_logs('audit-super-token', 100)
    where action = 'audit_test_global'
  ),
  'super_admin still sees the global/null-school audit row'
);

-- 9. no PUBLIC/service_role execute widening
select ok(
  not has_function_privilege('service_role', 'list_school_admin_audit_logs(text, integer)', 'execute'),
  'service_role has no execute on list_school_admin_audit_logs'
);

select * from finish();
rollback;
