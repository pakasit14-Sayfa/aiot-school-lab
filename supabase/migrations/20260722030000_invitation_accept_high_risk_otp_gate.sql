-- Email OTP gate for accepting a staff invitation into a high-risk role
-- (super_admin, school_admin, teacher, executive) — same requirement as
-- auth_sign_in's login_2fa gate, and reuses the same otp_codes purpose and
-- auth_verify_login_otp() verifier, so no new verify path is needed.
--
-- Setting a password no longer mints a session directly for these roles:
-- it now creates an OTP challenge and returns it the same shape as
-- auth_sign_in's mfa_required response. Because the plaintext OTP code is
-- returned to the caller, this function moves behind the service-role
-- boundary just like auth_sign_in — the client must go through the
-- accept-staff-invitation Edge Function from now on.

revoke all on function accept_staff_invitation(text, text, text, text)
  from public, anon, authenticated, service_role;
drop function accept_staff_invitation(text, text, text, text);

create function accept_staff_invitation(
  p_token text,
  p_first_name text,
  p_last_name text,
  p_password text
)
returns table (
  auth_state text,
  session_token text,
  user_id uuid,
  email varchar,
  first_name varchar,
  last_name varchar,
  active_role role_type,
  active_school_id uuid,
  otp_token text,
  otp_code text,
  otp_expires_at timestamptz
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_invite_token_hash text;
  v_invitation user_invitations%rowtype;
  v_user_id uuid;
  v_session_token text;
  v_session_token_hash text;
  v_session_id uuid;
  v_otp_token text;
  v_otp_code text;
  v_otp_expires_at timestamptz;
begin
  v_invite_token_hash := encode(digest(p_token, 'sha256'), 'hex');

  select * into v_invitation from user_invitations
    where token_hash = v_invite_token_hash
      and status = 'pending'
      and expires_at > now();

  if not found then
    raise exception 'invalid_or_expired_invitation';
  end if;

  if exists (select 1 from users where users.email = v_invitation.email and users.school_id = v_invitation.school_id) then
    raise exception 'user_already_exists';
  end if;

  insert into users (school_id, email, password_hash, first_name, last_name, created_by)
  values (v_invitation.school_id, v_invitation.email, crypt(p_password, gen_salt('bf')), p_first_name, p_last_name, v_invitation.invited_by)
  returning id into v_user_id;

  insert into user_roles (user_id, role, school_id, granted_by)
  values (v_user_id, v_invitation.initial_role, v_invitation.school_id, v_invitation.invited_by);

  update user_invitations
    set status = 'accepted', accepted_by = v_user_id, accepted_at = now()
    where id = v_invitation.id;

  if v_invitation.initial_role in ('super_admin', 'school_admin', 'teacher', 'executive') then
    v_otp_token := 'iv_' || encode(gen_random_bytes(32), 'hex');
    v_otp_code := lpad(
      ((('x' || encode(gen_random_bytes(4), 'hex'))::bit(32)::bigint % 1000000))::text,
      6,
      '0'
    );
    v_otp_expires_at := now() + interval '10 minutes';

    insert into otp_codes (
      user_id, purpose, code_hash, sent_to_email,
      verification_token_hash, login_role, login_school_id,
      last_sent_at, expires_at
    ) values (
      v_user_id,
      'login_2fa',
      encode(digest(v_otp_code || ':' || v_otp_token, 'sha256'), 'hex'),
      v_invitation.email,
      encode(digest(v_otp_token, 'sha256'), 'hex'),
      v_invitation.initial_role,
      v_invitation.school_id,
      now(),
      v_otp_expires_at
    );

    insert into audit_logs (
      school_id, user_id, acted_role, action, entity_type, details
    ) values (
      v_invitation.school_id, v_user_id, v_invitation.initial_role,
      'auth.otp_requested', 'otp_codes',
      jsonb_build_object('purpose', 'login_2fa', 'reason', 'accept_invitation', 'expires_at', v_otp_expires_at)
    );

    return query select
      'mfa_required'::text, null::text, v_user_id, v_invitation.email,
      p_first_name::varchar, p_last_name::varchar,
      v_invitation.initial_role, v_invitation.school_id,
      v_otp_token, v_otp_code, v_otp_expires_at;
    return;
  end if;

  v_session_token := encode(gen_random_bytes(32), 'hex');
  v_session_token_hash := encode(digest(v_session_token, 'sha256'), 'hex');

  insert into sessions (user_id, active_role, active_school_id, token_hash, expires_at)
  values (v_user_id, v_invitation.initial_role, v_invitation.school_id, v_session_token_hash, now() + interval '7 days')
  returning id into v_session_id;

  insert into audit_logs (school_id, user_id, acted_role, action, entity_type, entity_id)
  values (v_invitation.school_id, v_user_id, v_invitation.initial_role, 'auth.accept_invitation', 'sessions', v_session_id::text);

  return query
    select 'authenticated'::text, v_session_token, v_user_id, v_invitation.email,
           p_first_name::varchar, p_last_name::varchar,
           v_invitation.initial_role, v_invitation.school_id,
           null::text, null::text, null::timestamptz;
end;
$$;

revoke all on function accept_staff_invitation(text, text, text, text)
  from public, anon, authenticated;
grant execute on function accept_staff_invitation(text, text, text, text) to service_role;
