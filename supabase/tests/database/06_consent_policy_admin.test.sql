begin;

create extension if not exists pgtap with schema extensions;
select plan(10);

insert into packages (id, name, license_type)
values ('14000000-0000-0000-0000-000000000001', 'Policy test package', 'perpetual');

insert into schools (id, package_id, name, school_code) values
  ('24000000-0000-0000-0000-000000000001', '14000000-0000-0000-0000-000000000001', 'Policy school A', 'POLICY-A'),
  ('24000000-0000-0000-0000-000000000002', '14000000-0000-0000-0000-000000000001', 'Policy school B', 'POLICY-B');

insert into users (
  id, school_id, email, password_hash, first_name, last_name, created_by
) values
  (
    '34000000-0000-0000-0000-000000000001',
    '24000000-0000-0000-0000-000000000001',
    'policy-admin-a@pdpa.test', crypt('irrelevant', gen_salt('bf')),
    'Policy', 'Admin A', '34000000-0000-0000-0000-000000000001'
  ),
  (
    '34000000-0000-0000-0000-000000000002',
    '24000000-0000-0000-0000-000000000002',
    'policy-admin-b@pdpa.test', crypt('irrelevant', gen_salt('bf')),
    'Policy', 'Admin B', '34000000-0000-0000-0000-000000000002'
  );

insert into user_roles (user_id, role, school_id, granted_by) values
  ('34000000-0000-0000-0000-000000000001', 'school_admin', '24000000-0000-0000-0000-000000000001', '34000000-0000-0000-0000-000000000001'),
  ('34000000-0000-0000-0000-000000000002', 'school_admin', '24000000-0000-0000-0000-000000000002', '34000000-0000-0000-0000-000000000002');

insert into sessions (
  user_id, active_role, active_school_id, token_hash, expires_at
) values (
  '34000000-0000-0000-0000-000000000001', 'school_admin',
  '24000000-0000-0000-0000-000000000001',
  encode(digest('policy-admin-a-token', 'sha256'), 'hex'),
  now() + interval '1 hour'
);

create temporary table published_policy as
select publish_consent_policy(
  'policy-admin-a-token',
  'optional_research',
  '1.0',
  repeat('a', 64),
  'https://school-a.invalid/privacy/research-v1',
  false
) as policy_id;

select is(
  (select count(*)::integer from published_policy),
  1,
  'school admin can publish one immutable policy version'
);

select is(
  (select school_id from consent_policies
   where id = (select policy_id from published_policy)),
  '24000000-0000-0000-0000-000000000001'::uuid,
  'published policy is forced into the active school'
);

select is(
  (select document_hash from consent_policies
   where id = (select policy_id from published_policy)),
  repeat('a', 64)::varchar,
  'the exact SHA-256 document evidence is stored'
);

select is(
  (select count(*)::integer
   from list_consent_policies_admin('policy-admin-a-token')),
  1,
  'admin list returns the active school policy'
);

select throws_ok(
  $$select publish_consent_policy(
    'policy-admin-a-token', 'bad_hash', '1.0', 'not-a-hash',
    'https://school-a.invalid/privacy/bad', false
  )$$,
  'P0001', 'invalid_document_hash',
  'invalid document evidence cannot be published'
);

insert into consent_policies (
  id, school_id, consent_type, version, document_hash,
  content_url, effective_at, created_by
) values (
  '54000000-0000-0000-0000-000000000002',
  '24000000-0000-0000-0000-000000000002',
  'other_school_policy', '1.0', repeat('b', 64),
  'https://school-b.invalid/privacy/policy-v1', now(),
  '34000000-0000-0000-0000-000000000002'
);

select ok(
  not exists (
    select 1 from list_consent_policies_admin('policy-admin-a-token')
    where school_id = '24000000-0000-0000-0000-000000000002'
  ),
  'school A cannot list school B policy versions'
);

select throws_ok(
  $$select retire_consent_policy(
    'policy-admin-a-token',
    '54000000-0000-0000-0000-000000000002'
  )$$,
  'P0001', 'forbidden',
  'school A cannot retire a school B policy'
);

select lives_ok(
  $$select retire_consent_policy(
    'policy-admin-a-token',
    (select policy_id from published_policy)
  )$$,
  'school admin can retire an in-school policy'
);

select ok(
  (select retired_at is not null from consent_policies
   where id = (select policy_id from published_policy)),
  'retirement is persisted without deleting the policy version'
);

select is(
  (select count(*)::integer from audit_logs
   where entity_id = (select policy_id::text from published_policy)
     and action in ('consent_policy.publish', 'consent_policy.retire')),
  2,
  'publish and retire both leave an audit trail'
);

select * from finish();
rollback;
