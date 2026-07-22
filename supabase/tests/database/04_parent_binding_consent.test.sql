begin;

create extension if not exists pgtap with schema extensions;
select plan(12);

insert into packages (id, name, license_type) values
  ('12000000-0000-0000-0000-000000000001', 'Parent test package', 'perpetual');

insert into schools (id, package_id, name, school_code) values
  ('22000000-0000-0000-0000-000000000001', '12000000-0000-0000-0000-000000000001', 'Parent school A', 'PARENT-A'),
  ('22000000-0000-0000-0000-000000000002', '12000000-0000-0000-0000-000000000001', 'Parent school B', 'PARENT-B');

insert into users (
  id, school_id, email, student_code, password_hash,
  first_name, last_name, created_by
) values
  (
    '32000000-0000-0000-0000-000000000001',
    '22000000-0000-0000-0000-000000000001',
    'admin-a@pdpa.test', null, crypt('Admin-Pass-123!', gen_salt('bf')),
    'Admin', 'A', '32000000-0000-0000-0000-000000000001'
  ),
  (
    '32000000-0000-0000-0000-000000000002',
    '22000000-0000-0000-0000-000000000001',
    'student-a@pdpa.test', 'STUDENT-A', crypt('Student-Pass-123!', gen_salt('bf')),
    'Student', 'A', '32000000-0000-0000-0000-000000000001'
  );

insert into user_roles (user_id, role, school_id, granted_by) values
  (
    '32000000-0000-0000-0000-000000000001', 'school_admin',
    '22000000-0000-0000-0000-000000000001',
    '32000000-0000-0000-0000-000000000001'
  ),
  (
    '32000000-0000-0000-0000-000000000002', 'student',
    '22000000-0000-0000-0000-000000000001',
    '32000000-0000-0000-0000-000000000001'
  );

insert into sessions (
  user_id, active_role, active_school_id, token_hash, expires_at
) values (
  '32000000-0000-0000-0000-000000000001', 'school_admin',
  '22000000-0000-0000-0000-000000000001',
  encode(digest('parent-admin-token', 'sha256'), 'hex'),
  now() + interval '1 hour'
);

insert into parent_binding_codes (
  id, school_id, student_id, code_hash, status, expires_at, issued_by
) values (
  '42000000-0000-0000-0000-000000000001',
  '22000000-0000-0000-0000-000000000001',
  '32000000-0000-0000-0000-000000000002',
  encode(digest('PARENT-CODE-A', 'sha256'), 'hex'),
  'issued', now() + interval '1 day',
  '32000000-0000-0000-0000-000000000001'
);

create temporary table parent_verification as
select * from request_parent_binding_otp('PARENT-CODE-A', 'parent-a@pdpa.test');

select is(
  (select count(*)::integer from parent_verification),
  1,
  'a valid binding code produces one opaque verification flow'
);

select matches(
  (select verification_token from parent_verification),
  '^pv_',
  'the client receives an opaque verification token'
);

do $$
begin
  perform * from confirm_parent_binding(
    (select verification_token from parent_verification),
    '000000', 'ผู้ปกครอง', 'Parent', 'A', 'Parent-Pass-123!'
  );
end;
$$;

select is(
  (select attempt_count from otp_codes
   where parent_binding_code_id = '42000000-0000-0000-0000-000000000001'),
  1,
  'a wrong OTP attempt is persisted'
);

create temporary table confirmed_parent_link as
select * from confirm_parent_binding(
  (select verification_token from parent_verification),
  (select otp_code from parent_verification),
  'ผู้ปกครอง', 'Parent', 'A', 'Parent-Pass-123!'
);

select is(
  (select status::text from confirmed_parent_link),
  'pending',
  'OTP confirmation creates a pending link'
);

select ok(
  not exists (
    select 1 from user_roles ur
    join users u on u.id = ur.user_id
    where u.email = 'parent-a@pdpa.test' and ur.role = 'parent'
  ),
  'the parent role is withheld until school approval'
);

select lives_ok(
  $$select approve_parent_link(
    'parent-admin-token',
    (select parent_link_id from confirmed_parent_link)
  )$$,
  'school admin can approve an in-school pending link'
);

select is(
  (select status::text from parent_links
   where id = (select parent_link_id from confirmed_parent_link)),
  'approved',
  'approved link state is persisted'
);

select ok(
  exists (
    select 1 from user_roles ur
    join users u on u.id = ur.user_id
    where u.email = 'parent-a@pdpa.test' and ur.role = 'parent'
  ),
  'approval grants the parent role'
);

insert into sessions (
  user_id, active_role, active_school_id, token_hash, expires_at
)
select id, 'parent', school_id,
       encode(digest('approved-parent-token', 'sha256'), 'hex'),
       now() + interval '1 hour'
from users where email = 'parent-a@pdpa.test';

insert into consent_policies (
  id, school_id, consent_type, version, document_hash,
  content_url, effective_at, created_by
) values
  (
    '52000000-0000-0000-0000-000000000001',
    '22000000-0000-0000-0000-000000000001',
    'optional_research', '1.0', repeat('a', 64),
    'https://school-a.invalid/privacy/optional-research-v1',
    now() - interval '1 minute',
    '32000000-0000-0000-0000-000000000001'
  ),
  (
    '52000000-0000-0000-0000-000000000002',
    '22000000-0000-0000-0000-000000000002',
    'other_school_policy', '1.0', repeat('b', 64),
    'https://school-b.invalid/privacy/policy-v1',
    now() - interval '1 minute',
    '32000000-0000-0000-0000-000000000001'
  );

create temporary table granted_consent as
select grant_parent_consent(
  'approved-parent-token',
  (select parent_link_id from confirmed_parent_link),
  '52000000-0000-0000-0000-000000000001',
  '{"confirmed_read": true}'::jsonb
) as consent_id;

select is(
  (select status::text from consents
   where id = (select consent_id from granted_consent)),
  'granted',
  'approved parent can grant an active in-school policy'
);

select throws_ok(
  $$select grant_parent_consent(
    'approved-parent-token',
    (select parent_link_id from confirmed_parent_link),
    '52000000-0000-0000-0000-000000000002',
    '{"confirmed_read": true}'::jsonb
  )$$,
  'P0001',
  'active_policy_required',
  'parent cannot grant a policy owned by another school'
);

select lives_ok(
  $$select withdraw_parent_consent(
    'approved-parent-token',
    (select consent_id from granted_consent),
    'parent choice'
  )$$,
  'parent can withdraw previously granted consent'
);

select is(
  (select count(*)::integer from consent_events
   where consent_id = (select consent_id from granted_consent)),
  2,
  'grant and withdrawal are both retained as append-only events'
);

select * from finish();
rollback;
