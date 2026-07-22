begin;

create extension if not exists pgtap with schema extensions;

select plan(5);

select ok(
  not has_function_privilege(
    'anon',
    'public.request_password_reset_otp(text)',
    'EXECUTE'
  ),
  'anon cannot execute the RPC that returns a plaintext password-reset OTP'
);

select ok(
  not has_function_privilege(
    'authenticated',
    'public.request_password_reset_otp(text)',
    'EXECUTE'
  ),
  'authenticated cannot execute the RPC that returns a plaintext password-reset OTP'
);

select ok(
  has_function_privilege(
    'service_role',
    'public.request_password_reset_otp(text)',
    'EXECUTE'
  ),
  'service_role can execute the internal password-reset OTP RPC'
);

select ok(
  not has_function_privilege(
    'anon',
    'public.record_operational_alert(text,text,jsonb)',
    'EXECUTE'
  ),
  'anon cannot forge operational alerts'
);

select ok(
  has_function_privilege(
    'service_role',
    'public.record_operational_alert(text,text,jsonb)',
    'EXECUTE'
  ),
  'service role can persist provider delivery alerts'
);

select * from finish();
rollback;
