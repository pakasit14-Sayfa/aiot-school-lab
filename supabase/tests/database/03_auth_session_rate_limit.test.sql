begin;

create extension if not exists pgtap with schema extensions;
select plan(17);

insert into packages (id, name, license_type)
values ('11000000-0000-0000-0000-000000000001', 'Auth test package', 'perpetual');

insert into schools (id, package_id, name, school_code)
values (
  '21000000-0000-0000-0000-000000000001',
  '11000000-0000-0000-0000-000000000001',
  'Auth test school',
  'AUTH-TEST'
);

insert into users (
  id, school_id, email, password_hash, first_name, last_name
) values (
  '31000000-0000-0000-0000-000000000001',
  '21000000-0000-0000-0000-000000000001',
  'auth-user@pdpa.test',
  crypt('Correct-Password-123!', gen_salt('bf')),
  'Auth',
  'User'
);

insert into user_roles (user_id, role, school_id, granted_by)
values (
  '31000000-0000-0000-0000-000000000001',
  'student',
  '21000000-0000-0000-0000-000000000001',
  '31000000-0000-0000-0000-000000000001'
);

select is(
  (select count(*)::integer from auth_sign_in(
    'auth-user@pdpa.test', 'wrong-1', 'test-device', repeat('1', 64)
  )),
  0,
  'invalid credentials return no session'
);

select is(
  (select attempt_count from auth_login_rate_limits limit 1),
  1,
  'a failed login is committed to the rate-limit counter'
);

select is(
  (select attempt_count from auth_login_ip_rate_limits
   where ip_hash = encode(digest(repeat('1', 64), 'sha256'), 'hex')),
  1,
  'a failed login is also counted in the hashed IP bucket'
);

do $$
begin
  perform * from auth_sign_in('auth-user@pdpa.test', 'wrong-2', 'test-device', repeat('1', 64));
  perform * from auth_sign_in('auth-user@pdpa.test', 'wrong-3', 'test-device', repeat('1', 64));
  perform * from auth_sign_in('auth-user@pdpa.test', 'wrong-4', 'test-device', repeat('1', 64));
  perform * from auth_sign_in('auth-user@pdpa.test', 'wrong-5', 'test-device', repeat('1', 64));
end;
$$;

select is(
  (select attempt_count from auth_login_rate_limits limit 1),
  5,
  'five failures reach the configured threshold'
);

select ok(
  (select blocked_until > now() from auth_login_rate_limits limit 1),
  'the account key is temporarily blocked'
);

select is(
  (select count(*)::integer from auth_sign_in(
    'auth-user@pdpa.test', 'Correct-Password-123!', 'test-device', repeat('1', 64)
  )),
  0,
  'correct credentials cannot bypass an active throttle'
);

update auth_login_rate_limits set blocked_until = now() - interval '1 second';

update auth_login_ip_rate_limits
set blocked_until = now() + interval '15 minutes'
where ip_hash = encode(digest(repeat('1', 64), 'sha256'), 'hex');

select is(
  (select count(*)::integer from auth_sign_in(
    'auth-user@pdpa.test', 'Correct-Password-123!', 'test-device', repeat('1', 64)
  )),
  0,
  'a blocked IP cannot bypass the network throttle with valid credentials'
);

select is(
  (select count(*)::integer from auth_sign_in(
    'auth-user@pdpa.test', 'Correct-Password-123!', 'test-device', repeat('2', 64)
  )),
  1,
  'login succeeds after the temporary block expires'
);

select is(
  (select count(*)::integer from auth_login_rate_limits),
  0,
  'successful login clears the failed-attempt record'
);

do $$
declare
  v_index integer;
begin
  for v_index in 1..5 loop
    perform * from auth_sign_in(
      'auth-user@pdpa.test', 'Correct-Password-123!', 'test-device', repeat('2', 64)
    );
  end loop;
end;
$$;

select is(
  (select count(*)::integer from sessions
   where user_id = '31000000-0000-0000-0000-000000000001'
     and revoked_at is null),
  5,
  'only five live sessions are retained per account'
);

select ok(
  not exists (
    select 1 from sessions
    where user_id = '31000000-0000-0000-0000-000000000001'
      and revoked_at is null
      and (ip_address is null or ip_address !~ '^[0-9a-f]{64}$')
  ),
  'sessions retain only a peppered IP fingerprint, never a raw address'
);

create temporary table latest_auth_token as
select session_token from auth_sign_in(
  'auth-user@pdpa.test', 'Correct-Password-123!', 'test-device', repeat('2', 64)
);

select is(
  auth_sign_out_all((select session_token from latest_auth_token)),
  5,
  'sign out all revokes every live session'
);

select is(
  (select count(*)::integer from sessions
   where user_id = '31000000-0000-0000-0000-000000000001'
     and revoked_at is null),
  0,
  'no live sessions remain after sign out all'
);

select ok(
  not has_table_privilege('anon', 'public.sessions', 'SELECT'),
  'anon has no direct session-table access'
);

select ok(
  not has_table_privilege('authenticated', 'public.auth_login_rate_limits', 'SELECT'),
  'authenticated cannot inspect login throttle state'
);

select ok(
  not has_function_privilege(
    'anon',
    'public.auth_sign_in(text,text,text,text)',
    'EXECUTE'
  ),
  'anon cannot bypass the Edge login boundary by calling the RPC directly'
);

select ok(
  has_function_privilege(
    'service_role',
    'public.auth_sign_in(text,text,text,text)',
    'EXECUTE'
  ),
  'the Edge service role can call the internal login RPC'
);

select * from finish();
rollback;
