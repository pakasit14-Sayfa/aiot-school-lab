-- =====================================================================
-- Password reset via email OTP (Resend, sent from an Edge Function)
--
-- otp_codes already had a `password_reset` purpose reserved in the
-- initial schema — this wires it up:
--
--   1. Flutter calls the `request-password-reset` Edge Function
--      (never this RPC directly) with just an email.
--   2. The Edge Function calls request_password_reset_otp() using the
--      service_role key, gets back the plaintext code, and emails it
--      via Resend. request_password_reset_otp() is NOT granted to
--      anon/authenticated — only the Edge Function's service_role
--      connection can call it, since it's the only caller allowed to
--      see the plaintext code.
--   3. Flutter calls confirm_password_reset() directly (anon) with
--      the email + code the user typed + their new password.
--
-- Both functions return generic results for unknown emails/codes so
-- neither leaks whether an email address has an account (user
-- enumeration).
-- =====================================================================

create or replace function request_password_reset_otp(p_email text)
returns table (
  otp_code text,
  user_id uuid,
  first_name varchar
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_user users%rowtype;
  v_last_sent timestamptz;
  v_code text;
  v_code_hash text;
begin
  select * into v_user from users where email = lower(p_email) and status = 'active';
  if not found then
    return;
  end if;

  select max(last_sent_at) into v_last_sent
    from otp_codes
    where user_id = v_user.id and purpose = 'password_reset';

  if v_last_sent is not null and v_last_sent > now() - interval '60 seconds' then
    raise exception 'rate_limited';
  end if;

  v_code := lpad((('x' || encode(gen_random_bytes(4), 'hex'))::bit(32)::bigint % 1000000)::text, 6, '0');
  v_code_hash := encode(digest(v_code, 'sha256'), 'hex');

  insert into otp_codes (user_id, purpose, code_hash, sent_to_email, last_sent_at, expires_at)
  values (v_user.id, 'password_reset', v_code_hash, v_user.email, now(), now() + interval '15 minutes');

  return query select v_code, v_user.id, v_user.first_name;
end;
$$;

create or replace function confirm_password_reset(
  p_email text,
  p_otp_code text,
  p_new_password text
)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_user users%rowtype;
  v_otp otp_codes%rowtype;
  v_code_hash text;
begin
  select * into v_user from users where email = lower(p_email) and status = 'active';
  if not found then
    raise exception 'invalid_or_expired_code';
  end if;

  select * into v_otp from otp_codes
    where user_id = v_user.id
      and purpose = 'password_reset'
      and used_at is null
    order by last_sent_at desc
    limit 1;

  if not found or v_otp.expires_at <= now() then
    raise exception 'invalid_or_expired_code';
  end if;

  if v_otp.locked_until is not null and v_otp.locked_until > now() then
    raise exception 'too_many_attempts';
  end if;

  v_code_hash := encode(digest(p_otp_code, 'sha256'), 'hex');

  if v_otp.code_hash <> v_code_hash then
    update otp_codes
      set attempt_count = attempt_count + 1,
          locked_until = case when attempt_count + 1 >= 5 then now() + interval '15 minutes' else locked_until end
      where id = v_otp.id;
    raise exception 'invalid_or_expired_code';
  end if;

  update users
    set password_hash = crypt(p_new_password, gen_salt('bf')),
        must_change_password = false
    where id = v_user.id;

  update otp_codes set used_at = now() where id = v_otp.id;

  update sessions set revoked_at = now()
    where user_id = v_user.id and revoked_at is null;

  insert into audit_logs (user_id, action, entity_type, entity_id)
  values (v_user.id, 'auth.password_reset', 'users', v_user.id::text);
end;
$$;

grant execute on function request_password_reset_otp(text) to service_role;
grant execute on function confirm_password_reset(text, text, text) to anon, authenticated;
