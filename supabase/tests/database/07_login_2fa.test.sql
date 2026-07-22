begin;

create extension if not exists pgtap with schema extensions;
select plan(12);

insert into packages (id, name, license_type)
values ('17000000-0000-0000-0000-000000000001', 'Login 2FA test package', 'perpetual');

insert into schools (id, package_id, name, school_code)
values (
  '27000000-0000-0000-0000-000000000001',
  '17000000-0000-0000-0000-000000000001',
  'Login 2FA test school',
  'LOGIN-2FA'
);

insert into users (
  id, school_id, email, password_hash, first_name, last_name
) values (
  '37000000-0000-0000-0000-000000000001',
  '27000000-0000-0000-0000-000000000001',
  'teacher-2fa@pdpa.test',
  crypt('Correct-Password-123!', gen_salt('bf')),
  'Two Factor',
  'Teacher'
);

insert into user_roles (user_id, role, school_id, granted_by)
values (
  '37000000-0000-0000-0000-000000000001',
  'teacher',
  '27000000-0000-0000-0000-000000000001',
  '37000000-0000-0000-0000-000000000001'
);

create temporary table login_challenge as
select * from auth_sign_in(
  'teacher-2fa@pdpa.test',
  'Correct-Password-123!',
  'test-device',
  repeat('7', 64)
);

select is(
  (select auth_state from login_challenge),
  'mfa_required',
  'a high-risk role receives an MFA challenge after password verification'
);

select is(
  (select count(*)::integer from sessions
   where user_id = '37000000-0000-0000-0000-000000000001'
     and revoked_at is null),
  0,
  'no authenticated session exists before the email OTP is verified'
);

create temporary table wrong_otp_result as
select * from auth_verify_login_otp(
  (select otp_token from login_challenge),
  '000000'
);

select is(
  (select attempt_count from otp_codes
   where user_id = '37000000-0000-0000-0000-000000000001'
     and purpose = 'login_2fa'
   order by last_sent_at desc
   limit 1),
  1,
  'an incorrect login OTP commits one failed attempt without creating a session'
);

create temporary table successful_otp_result as
select * from auth_verify_login_otp(
  (select otp_token from login_challenge),
  (select otp_code from login_challenge)
);

select ok(
  (select count(*) = 1
          and min(session_token) is not null
   from successful_otp_result)
  and exists (
    select 1 from sessions
    where user_id = '37000000-0000-0000-0000-000000000001'
      and revoked_at is null
  ),
  'the correct OTP creates and returns one authenticated session'
);

create temporary table reused_otp_result as
select * from auth_verify_login_otp(
  (select otp_token from login_challenge),
  (select otp_code from login_challenge)
);

select ok(
  (select count(*) = 0 from reused_otp_result)
  and (select count(*) = 1 from sessions
       where user_id = '37000000-0000-0000-0000-000000000001'
         and revoked_at is null),
  'a login OTP is one-use and cannot mint a second session'
);

update otp_codes
set last_sent_at = now() - interval '61 seconds'
where user_id = '37000000-0000-0000-0000-000000000001'
  and purpose = 'login_2fa';

create temporary table locked_challenge as
select * from auth_sign_in(
  'teacher-2fa@pdpa.test',
  'Correct-Password-123!',
  'test-device',
  repeat('7', 64)
);

do $$
declare
  v_index integer;
  v_wrong_code text;
begin
  v_wrong_code := case
    when (select otp_code from locked_challenge) <> '000000' then '000000'
    else '000001'
  end;
  for v_index in 1..5 loop
    perform * from auth_verify_login_otp(
      (select otp_token from locked_challenge),
      v_wrong_code
    );
  end loop;
end;
$$;

select ok(
  (select attempt_count = 5 and locked_until > now()
   from otp_codes
   where verification_token_hash = encode(
     digest((select otp_token from locked_challenge), 'sha256'),
     'hex'
   )),
  'five incorrect attempts lock the login OTP challenge'
);

create temporary table locked_correct_result as
select * from auth_verify_login_otp(
  (select otp_token from locked_challenge),
  (select otp_code from locked_challenge)
);

select ok(
  (select count(*) = 0 from locked_correct_result)
  and (select count(*) = 1 from sessions
       where user_id = '37000000-0000-0000-0000-000000000001'
         and revoked_at is null),
  'a locked challenge cannot mint a session even with the correct OTP'
);

insert into users (
  id, school_id, email, password_hash, first_name, last_name
) values (
  '37000000-0000-0000-0000-000000000002',
  '27000000-0000-0000-0000-000000000001',
  'student-no-2fa@pdpa.test',
  crypt('Student-Password-123!', gen_salt('bf')),
  'No Two Factor',
  'Student'
);

insert into user_roles (user_id, role, school_id, granted_by)
values (
  '37000000-0000-0000-0000-000000000002',
  'student',
  '27000000-0000-0000-0000-000000000001',
  '37000000-0000-0000-0000-000000000001'
);

create temporary table student_login as
select * from auth_sign_in(
  'student-no-2fa@pdpa.test',
  'Student-Password-123!',
  'student-device',
  repeat('8', 64)
);

select ok(
  (select auth_state = 'authenticated'
          and session_token is not null
          and otp_token is null
   from student_login),
  'a low-risk student role signs in without an OTP challenge'
);

insert into users (
  id, school_id, email, password_hash, first_name, last_name
) values
  (
    '37000000-0000-0000-0000-000000000003',
    '27000000-0000-0000-0000-000000000001',
    'super-admin-2fa@pdpa.test',
    crypt('Role-Password-123!', gen_salt('bf')), 'Super', 'Admin'
  ),
  (
    '37000000-0000-0000-0000-000000000004',
    '27000000-0000-0000-0000-000000000001',
    'school-admin-2fa@pdpa.test',
    crypt('Role-Password-123!', gen_salt('bf')), 'School', 'Admin'
  ),
  (
    '37000000-0000-0000-0000-000000000005',
    '27000000-0000-0000-0000-000000000001',
    'executive-2fa@pdpa.test',
    crypt('Role-Password-123!', gen_salt('bf')), 'School', 'Executive'
  );

insert into user_roles (user_id, role, school_id, granted_by) values
  (
    '37000000-0000-0000-0000-000000000003', 'super_admin',
    '27000000-0000-0000-0000-000000000001',
    '37000000-0000-0000-0000-000000000001'
  ),
  (
    '37000000-0000-0000-0000-000000000004', 'school_admin',
    '27000000-0000-0000-0000-000000000001',
    '37000000-0000-0000-0000-000000000001'
  ),
  (
    '37000000-0000-0000-0000-000000000005', 'executive',
    '27000000-0000-0000-0000-000000000001',
    '37000000-0000-0000-0000-000000000001'
  );

create temporary table high_risk_role_results (auth_state text);
insert into high_risk_role_results
select auth_state from auth_sign_in(
  'super-admin-2fa@pdpa.test', 'Role-Password-123!', 'device', repeat('9', 64)
);
insert into high_risk_role_results
select auth_state from auth_sign_in(
  'school-admin-2fa@pdpa.test', 'Role-Password-123!', 'device', repeat('a', 64)
);
insert into high_risk_role_results
select auth_state from auth_sign_in(
  'executive-2fa@pdpa.test', 'Role-Password-123!', 'device', repeat('b', 64)
);
insert into high_risk_role_results values ((select auth_state from login_challenge));

select is(
  (select count(*)::integer from high_risk_role_results
   where auth_state = 'mfa_required'),
  4,
  'super admin, school admin, teacher, and executive all require email OTP'
);

select ok(
  not has_function_privilege(
    'anon',
    'public.auth_verify_login_otp(text,text)',
    'EXECUTE'
  ),
  'anon cannot bypass the Edge boundary to verify a login OTP directly'
);

select ok(
  has_function_privilege(
    'service_role',
    'public.auth_verify_login_otp(text,text)',
    'EXECUTE'
  ),
  'only the Edge service role can call the internal login OTP verifier'
);

insert into user_invitations (
  id, school_id, email, initial_role, scope, token_hash,
  expires_at, invited_by
) values (
  '47000000-0000-0000-0000-000000000001',
  '27000000-0000-0000-0000-000000000001',
  'invited-teacher-2fa@pdpa.test',
  'teacher',
  '{}'::jsonb,
  encode(digest('login-2fa-invitation-token', 'sha256'), 'hex'),
  now() + interval '72 hours',
  '37000000-0000-0000-0000-000000000001'
);

create temporary table accepted_staff as
select * from accept_staff_invitation(
  'login-2fa-invitation-token',
  'Invited',
  'Teacher',
  'Invitation-Password-123!'
);

select is(
  (select count(*)::integer from sessions
   where user_id = (select user_id from accepted_staff)),
  0,
  'accepting a high-risk staff invitation creates no session before email OTP'
);

select * from finish();
rollback;
