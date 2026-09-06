-- NOTE: auth_sign_in treats a p_ip_address that already looks like a
-- sha256 hex digest (^[0-9a-f]{64}$) as pre-hashed and stores it verbatim
-- (v_ip_hash := lower(trim(p_ip_address))) — the raw IP is hashed at the
-- edge, never in the DB. repeat('1', 64) matches that pattern, so it is
-- stored as-is. These lookups used to hash it a second time and therefore
-- matched no row, which silently disabled both IP-throttle assertions.
begin;

create extension if not exists pgtap with schema extensions;
-- 19, not 17: gained two assertions proving the account throttle covers the
-- no-IP fallback path, which is what makes anon EXECUTE on auth_sign_in
-- defensible (see the block near the end of this file).
select plan(19);

delete from auth_login_rate_limits;
delete from auth_login_ip_rate_limits;
delete from sessions where user_id = '31000000-0000-0000-0000-000000000001';

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
   where ip_hash = repeat('1', 64)),
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
where ip_hash = repeat('1', 64);

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

create temporary table latest_auth_token (session_token text);

do $$
declare
  v_index integer;
  v_token text;
begin
  for v_index in 1..5 loop
    select session_token into v_token from auth_sign_in(
      'auth-user@pdpa.test', 'Correct-Password-123!', 'test-device', repeat('3', 64)
    );
  end loop;
  insert into latest_auth_token values (v_token);
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

-- anon CAN call auth_sign_in directly, and that is deliberate: AuthService
-- (packages/shared_core/lib/services/auth_service.dart) invokes the
-- `auth-sign-in` Edge Function first and falls back to this RPC when the
-- function is unreachable, so login still works if the edge runtime is
-- down — which actually happened on 2026-09-06. The grant was added on
-- purpose in 20260826070000_multi_role_auth_core.sql and again in
-- 20260829000000_trusted_devices_remember_login.sql. This assertion used to
-- require the opposite, and had been silently unreachable because the file
-- aborted earlier on a stale function signature.
--
-- What still protects this path is the per-account throttle asserted above
-- (tests 4-6): five failures block the account key regardless of which
-- entry point was used.
--
-- Residual risk, recorded rather than hidden: the IP-based throttle does
-- NOT cover this path. The fallback sends no p_ip_address, and a direct
-- caller controls that argument anyway — auth_sign_in treats any 64-char
-- hex value as an already-hashed IP — so it can be rotated freely.
-- Single-account brute force is still capped, but password spraying across
-- many accounts is not IP-limited here. Closing that needs a product
-- decision (drop the fallback, or hash the IP server-side), not a test fix.
select ok(
  has_function_privilege(
    'anon',
    'public.auth_sign_in(text,text,text,text,text)',
    'EXECUTE'
  ),
  'anon can call auth_sign_in — required by the documented edge-function fallback'
);

-- Compensating control for the assertion directly above. Relaxing the anon
-- grant is only defensible if something still throttles that path, so prove
-- it here instead of asserting it in a comment.
--
-- This reproduces the fallback call shape exactly: AuthService sends only
-- email and password, so p_ip_address defaults to NULL and the IP bucket is
-- never consulted. Every other throttle assertion in this file passes an IP,
-- so none of them actually covered this path.
delete from auth_login_rate_limits;
delete from auth_login_ip_rate_limits;

do $$
begin
  perform * from auth_sign_in('auth-user@pdpa.test', 'fallback-wrong-1');
  perform * from auth_sign_in('auth-user@pdpa.test', 'fallback-wrong-2');
  perform * from auth_sign_in('auth-user@pdpa.test', 'fallback-wrong-3');
  perform * from auth_sign_in('auth-user@pdpa.test', 'fallback-wrong-4');
  perform * from auth_sign_in('auth-user@pdpa.test', 'fallback-wrong-5');
end;
$$;

select ok(
  (select blocked_until > now() from auth_login_rate_limits limit 1),
  'the account throttle still engages on the no-IP fallback path'
);

select is(
  (select count(*)::integer from auth_sign_in(
    'auth-user@pdpa.test', 'Correct-Password-123!'
  )),
  0,
  'a throttled account cannot log in through the fallback path either'
);

select ok(
  has_function_privilege(
    'service_role',
    'public.auth_sign_in(text,text,text,text,text)',
    'EXECUTE'
  ),
  'the Edge service role can call the internal login RPC'
);

select * from finish();
rollback;
