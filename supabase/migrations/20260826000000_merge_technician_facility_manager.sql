-- Migration: 20260826000000_merge_technician_facility_manager.sql
-- Description: Part A Checkpoint 1 - Rebuild role_type enum to 6 roles (super_admin, school_admin, teacher, executive, student, parent)

-- 1. Reassign data in all 5 tables
UPDATE public.user_roles SET role = 'super_admin' WHERE role::text = 'technician';
UPDATE public.user_roles SET role = 'school_admin' WHERE role::text = 'facility_manager';
UPDATE public.sessions SET active_role = 'super_admin' WHERE active_role::text = 'technician';
UPDATE public.sessions SET active_role = 'school_admin' WHERE active_role::text = 'facility_manager';
UPDATE public.audit_logs SET acted_role = 'super_admin' WHERE acted_role::text = 'technician';
UPDATE public.audit_logs SET acted_role = 'school_admin' WHERE acted_role::text = 'facility_manager';
UPDATE public.otp_codes SET login_role = 'super_admin' WHERE login_role::text = 'technician';
UPDATE public.otp_codes SET login_role = 'school_admin' WHERE login_role::text = 'facility_manager';
UPDATE public.user_invitations SET initial_role = 'super_admin' WHERE initial_role::text = 'technician';
UPDATE public.user_invitations SET initial_role = 'school_admin' WHERE initial_role::text = 'facility_manager';

-- 2. Drop dependent view and default before altering column types
DROP VIEW IF EXISTS public.profiles;
ALTER TABLE public.user_invitations ALTER COLUMN initial_role DROP DEFAULT;

-- 3. Swap the enum type
CREATE TYPE public.role_type_new AS ENUM (
  'super_admin',
  'school_admin',
  'teacher',
  'executive',
  'student',
  'parent'
);

ALTER TABLE public.user_roles ALTER COLUMN role TYPE public.role_type_new USING role::text::public.role_type_new;
ALTER TABLE public.sessions ALTER COLUMN active_role TYPE public.role_type_new USING active_role::text::public.role_type_new;
ALTER TABLE public.audit_logs ALTER COLUMN acted_role TYPE public.role_type_new USING acted_role::text::public.role_type_new;
ALTER TABLE public.otp_codes ALTER COLUMN login_role TYPE public.role_type_new USING login_role::text::public.role_type_new;
ALTER TABLE public.user_invitations ALTER COLUMN initial_role TYPE public.role_type_new USING initial_role::text::public.role_type_new;

ALTER TABLE public.user_invitations ALTER COLUMN initial_role SET DEFAULT 'student'::public.role_type_new;

DROP TYPE public.role_type CASCADE;
ALTER TYPE public.role_type_new RENAME TO role_type;

-- 4. Replay 9 captured functions
CREATE OR REPLACE FUNCTION public.accept_staff_invitation(p_token text, p_first_name text, p_last_name text, p_password text)
 RETURNS TABLE(auth_state text, session_token text, user_id uuid, email character varying, first_name character varying, last_name character varying, active_role role_type, active_school_id uuid, otp_token text, otp_code text, otp_expires_at timestamp with time zone)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
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
$function$
;

CREATE OR REPLACE FUNCTION public.auth_sign_in(p_email text, p_password text, p_device_info text DEFAULT NULL::text, p_ip_address text DEFAULT NULL::text)
 RETURNS TABLE(auth_state text, session_token text, user_id uuid, email character varying, first_name character varying, last_name character varying, must_change_password boolean, active_role role_type, active_school_id uuid, otp_token text, otp_code text, otp_expires_at timestamp with time zone, building character varying)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
DECLARE
  v_email text := lower(trim(p_email));
  v_email_hash text;
  v_ip_hash text;
  v_dummy_password_hash text;
  v_password_hash text;
  v_password_matches boolean;
  v_user_found boolean;
  v_limit auth_login_rate_limits%rowtype;
  v_ip_limit auth_login_ip_rate_limits%rowtype;
  v_user users%rowtype;
  v_role user_roles%rowtype;
  v_token text;
  v_session_id uuid;
  v_last_otp_sent timestamptz;
  v_daily_otp_count integer;
  v_otp_token text;
  v_otp_code text;
  v_otp_expires_at timestamptz;
BEGIN
  v_email_hash := encode(digest(v_email, 'sha256'), 'hex');
  IF trim(coalesce(p_ip_address, '')) ~ '^[0-9a-f]{64}$' THEN
    v_ip_hash := lower(trim(p_ip_address));
  END IF;

  SELECT * INTO v_limit
  FROM auth_login_rate_limits
  WHERE email_hash = v_email_hash
  FOR UPDATE;

  IF FOUND AND v_limit.blocked_until IS NOT NULL
     AND v_limit.blocked_until > now() THEN
    RETURN;
  END IF;

  IF v_ip_hash IS NOT NULL THEN
    SELECT * INTO v_ip_limit
    FROM auth_login_ip_rate_limits
    WHERE ip_hash = v_ip_hash
    FOR UPDATE;

    IF FOUND AND v_ip_limit.blocked_until IS NOT NULL
       AND v_ip_limit.blocked_until > now() THEN
      RETURN;
    END IF;
  END IF;

  SELECT dummy_password_hash INTO v_dummy_password_hash
  FROM auth_security_constants
  WHERE singleton = true;

  SELECT * INTO v_user
  FROM users
  WHERE users.email = v_email AND users.status = 'active';
  v_user_found := FOUND;

  v_password_hash := coalesce(v_user.password_hash, v_dummy_password_hash);
  v_password_matches := crypt(coalesce(p_password, ''), v_password_hash)
    = v_password_hash;

  IF NOT v_user_found
     OR v_user.password_hash IS NULL
     OR v_password_matches IS NOT TRUE THEN
    INSERT INTO auth_login_rate_limits (
      email_hash, window_started_at, attempt_count, blocked_until, last_attempt_at
    )
    VALUES (v_email_hash, now(), 1, NULL, now())
    ON CONFLICT (email_hash) DO UPDATE
    SET attempt_count = CASE
          WHEN auth_login_rate_limits.window_started_at < now() - interval '15 minutes'
            THEN 1
          ELSE auth_login_rate_limits.attempt_count + 1
        END,
        window_started_at = CASE
          WHEN auth_login_rate_limits.window_started_at < now() - interval '15 minutes'
            THEN now()
          ELSE auth_login_rate_limits.window_started_at
        END,
        blocked_until = CASE
          WHEN (CASE
            WHEN auth_login_rate_limits.window_started_at < now() - interval '15 minutes'
              THEN 1
            ELSE auth_login_rate_limits.attempt_count + 1
          END) >= 5 THEN now() + interval '15 minutes'
          ELSE NULL
        END,
        last_attempt_at = now();

    IF v_ip_hash IS NOT NULL THEN
      INSERT INTO auth_login_ip_rate_limits (
        ip_hash, window_started_at, attempt_count, blocked_until, last_attempt_at
      )
      VALUES (v_ip_hash, now(), 1, NULL, now())
      ON CONFLICT (ip_hash) DO UPDATE
      SET attempt_count = CASE
            WHEN auth_login_ip_rate_limits.window_started_at < now() - interval '15 minutes'
              THEN 1
            ELSE auth_login_ip_rate_limits.attempt_count + 1
          END,
          window_started_at = CASE
            WHEN auth_login_ip_rate_limits.window_started_at < now() - interval '15 minutes'
              THEN now()
            ELSE auth_login_ip_rate_limits.window_started_at
          END,
          blocked_until = CASE
            WHEN (CASE
              WHEN auth_login_ip_rate_limits.window_started_at < now() - interval '15 minutes'
                THEN 1
              ELSE auth_login_ip_rate_limits.attempt_count + 1
            END) >= 20 THEN now() + interval '15 minutes'
            ELSE NULL
          END,
          last_attempt_at = now();
    END IF;
    RETURN;
  END IF;

  DELETE FROM auth_login_rate_limits WHERE email_hash = v_email_hash;

  -- Select newest granted role
  SELECT * INTO v_role
  FROM user_roles
  WHERE user_roles.user_id = v_user.id
    AND (v_user.school_id IS NULL OR user_roles.school_id IS NOT DISTINCT FROM v_user.school_id OR user_roles.role = 'super_admin')
  ORDER BY granted_at DESC
  LIMIT 1;

  IF NOT FOUND THEN
    SELECT * INTO v_role
    FROM user_roles
    WHERE user_roles.user_id = v_user.id
    ORDER BY granted_at DESC
    LIMIT 1;
  END IF;

  IF v_role.role IS NULL THEN
    RETURN;
  END IF;

  -- OTP requirements check
  IF v_role.role IN ('super_admin', 'school_admin', 'executive', 'teacher') THEN
    SELECT max(last_sent_at), count(*) FILTER (
      WHERE last_sent_at >= now() - interval '24 hours'
    )
    INTO v_last_otp_sent, v_daily_otp_count
    FROM otp_codes oc
    WHERE oc.user_id = v_user.id
      AND oc.purpose = 'login_2fa';

    IF (v_last_otp_sent IS NOT NULL AND v_last_otp_sent > now() - interval '60 seconds')
       OR coalesce(v_daily_otp_count, 0) >= 10 THEN
      RETURN QUERY SELECT
        'rate_limited'::text, NULL::text, v_user.id, v_user.email,
        v_user.first_name, v_user.last_name, v_user.must_change_password,
        v_role.role, v_role.school_id, NULL::text, NULL::text,
        NULL::timestamptz, v_user.building;
      RETURN;
    END IF;

    v_otp_token := 'lo_' || encode(gen_random_bytes(32), 'hex');
    v_otp_code := lpad(
      ((('x' || encode(gen_random_bytes(4), 'hex'))::bit(32)::bigint % 1000000))::text,
      6, '0'
    );
    v_otp_expires_at := now() + interval '10 minutes';

    UPDATE otp_codes oc
    SET used_at = now()
    WHERE oc.user_id = v_user.id
      AND oc.purpose = 'login_2fa'
      AND oc.used_at IS NULL;

    INSERT INTO otp_codes (
      user_id, purpose, code_hash, sent_to_email,
      verification_token_hash, login_role, login_school_id,
      login_device_info, login_ip_address, last_sent_at, expires_at
    ) VALUES (
      v_user.id,
      'login_2fa',
      encode(digest(v_otp_code || ':' || v_otp_token, 'sha256'), 'hex'),
      v_user.email,
      encode(digest(v_otp_token, 'sha256'), 'hex'),
      v_role.role,
      v_role.school_id,
      left(p_device_info, 255),
      v_ip_hash,
      now(),
      v_otp_expires_at
    );

    INSERT INTO audit_logs (
      school_id, user_id, acted_role, action, entity_type, details
    ) VALUES (
      v_role.school_id, v_user.id, v_role.role,
      'auth.otp_requested', 'otp_codes',
      jsonb_build_object('purpose', 'login_2fa', 'expires_at', v_otp_expires_at)
    );

    RETURN QUERY SELECT
      'mfa_required'::text, NULL::text, v_user.id, v_user.email,
      v_user.first_name, v_user.last_name, v_user.must_change_password,
      v_role.role, v_role.school_id, v_otp_token, v_otp_code,
      v_otp_expires_at, v_user.building;
    RETURN;
  END IF;

  -- Students/Parents mint session directly
  v_token := encode(gen_random_bytes(32), 'hex');

  INSERT INTO sessions (
    user_id, active_role, active_school_id, token_hash,
    device_info, ip_address, expires_at
  ) VALUES (
    v_user.id, v_role.role, v_role.school_id,
    encode(digest(v_token, 'sha256'), 'hex'),
    left(p_device_info, 255), v_ip_hash,
    now() + interval '7 days'
  )
  RETURNING id INTO v_session_id;

  UPDATE sessions
  SET revoked_at = now()
  WHERE id IN (
    SELECT id FROM sessions
    WHERE sessions.user_id = v_user.id AND revoked_at IS NULL
    ORDER BY created_at DESC, id DESC
    OFFSET 5
  );

  INSERT INTO audit_logs (
    school_id, user_id, acted_role, action, entity_type, entity_id
  ) VALUES (
    v_role.school_id, v_user.id, v_role.role,
    'auth.sign_in', 'sessions', v_session_id::text
  );

  RETURN QUERY SELECT
    'authenticated'::text, v_token, v_user.id, v_user.email,
    v_user.first_name, v_user.last_name, v_user.must_change_password,
    v_role.role, v_role.school_id, NULL::text, NULL::text,
    NULL::timestamptz, v_user.building;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.auth_validate_session(p_token text)
 RETURNS TABLE(user_id uuid, email character varying, first_name character varying, last_name character varying, must_change_password boolean, active_role role_type, active_school_id uuid, building character varying)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
declare
  v_token_hash text;
  v_session sessions%rowtype;
  v_user users%rowtype;
begin
  v_token_hash := encode(digest(p_token, 'sha256'), 'hex');

  select * into v_session from sessions
    where token_hash = v_token_hash
      and revoked_at is null
      and expires_at > now();

  if not found then
    return;
  end if;

  select * into v_user from users where id = v_session.user_id and status = 'active';

  if not found then
    return;
  end if;

  return query
    select v_user.id, v_user.email, v_user.first_name, v_user.last_name,
           v_user.must_change_password, v_session.active_role, v_session.active_school_id,
           v_user.building;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.auth_verify_login_otp(p_otp_token text, p_otp_code text)
 RETURNS TABLE(session_token text, user_id uuid, email character varying, first_name character varying, last_name character varying, must_change_password boolean, active_role role_type, active_school_id uuid, building character varying)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
declare
  v_otp otp_codes%rowtype;
  v_user users%rowtype;
  v_token text;
  v_session_id uuid;
begin
  select oc.* into v_otp
  from otp_codes oc
  where oc.verification_token_hash = encode(
      digest(trim(coalesce(p_otp_token, '')), 'sha256'),
      'hex'
    )
    and oc.purpose = 'login_2fa'
    and oc.used_at is null
  order by oc.last_sent_at desc
  limit 1
  for update;

  if not found
     or v_otp.expires_at <= now()
     or (v_otp.locked_until is not null and v_otp.locked_until > now()) then
    return;
  end if;

  if v_otp.code_hash <> encode(
      digest(trim(coalesce(p_otp_code, '')) || ':' || trim(p_otp_token), 'sha256'),
      'hex'
    ) then
    update otp_codes
    set attempt_count = attempt_count + 1,
        locked_until = case
          when attempt_count + 1 >= 5 then now() + interval '10 minutes'
          else locked_until
        end
    where id = v_otp.id;

    insert into audit_logs (
      school_id, user_id, acted_role, action, entity_type, entity_id, details
    ) values (
      v_otp.login_school_id,
      v_otp.user_id,
      v_otp.login_role,
      'auth.otp_failed',
      'otp_codes',
      v_otp.id::text,
      jsonb_build_object('attempt', v_otp.attempt_count + 1)
    );
    return;
  end if;

  select u.* into v_user
  from users u
  where u.id = v_otp.user_id
    and u.status = 'active';

  if not found or not exists (
    select 1
    from user_roles ur
    where ur.user_id = v_otp.user_id
      and ur.role = v_otp.login_role
      and ur.school_id is not distinct from v_otp.login_school_id
  ) then
    update otp_codes set used_at = now() where id = v_otp.id;
    return;
  end if;

  v_token := encode(gen_random_bytes(32), 'hex');
  insert into sessions (
    user_id, active_role, active_school_id, token_hash,
    device_info, ip_address, expires_at
  ) values (
    v_otp.user_id,
    v_otp.login_role,
    v_otp.login_school_id,
    encode(digest(v_token, 'sha256'), 'hex'),
    v_otp.login_device_info,
    v_otp.login_ip_address,
    now() + interval '7 days'
  )
  returning id into v_session_id;

  update otp_codes set used_at = now() where id = v_otp.id;
  update otp_codes oc
  set used_at = now()
  where oc.user_id = v_otp.user_id
    and oc.purpose = 'login_2fa'
    and oc.id <> v_otp.id
    and oc.used_at is null;

  update sessions
  set revoked_at = now()
  where id in (
    select s.id from sessions s
    where s.user_id = v_otp.user_id and s.revoked_at is null
    order by s.created_at desc, s.id desc
    offset 5
  );

  insert into audit_logs (
    school_id, user_id, acted_role, action, entity_type, entity_id
  ) values
    (
      v_otp.login_school_id, v_otp.user_id, v_otp.login_role,
      'auth.otp_verified', 'otp_codes', v_otp.id::text
    ),
    (
      v_otp.login_school_id, v_otp.user_id, v_otp.login_role,
      'auth.sign_in', 'sessions', v_session_id::text
    );

  return query select
    v_token,
    v_user.id,
    v_user.email,
    v_user.first_name,
    v_user.last_name,
    v_user.must_change_password,
    v_otp.login_role,
    v_otp.login_school_id,
    v_user.building;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.create_staff_invitation(p_token text, p_email text, p_role role_type, p_school_id uuid DEFAULT NULL::uuid)
 RETURNS TABLE(invitation_token text, expires_at timestamp with time zone)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
declare
  v_actor record;
  v_school_id uuid;
  v_email text;
  v_invite_token text;
  v_invite_token_hash text;
  v_expires_at timestamptz;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then
    raise exception 'invalid_session';
  end if;

  if v_actor.role not in ('school_admin', 'super_admin') then
    raise exception 'forbidden';
  end if;

  if p_role = 'super_admin' and v_actor.role <> 'super_admin' then
    raise exception 'forbidden';
  end if;

  if v_actor.role = 'school_admin' then
    v_school_id := v_actor.school_id;
  else
    if p_school_id is null then
      raise exception 'school_id_required';
    end if;
    v_school_id := p_school_id;
  end if;

  v_email := lower(trim(p_email));

  if exists (select 1 from users where email = v_email and school_id = v_school_id) then
    raise exception 'user_already_exists';
  end if;

  update user_invitations
    set status = 'revoked', revoked_at = now()
    where email = v_email and school_id = v_school_id and status = 'pending';

  v_invite_token := encode(gen_random_bytes(32), 'hex');
  v_invite_token_hash := encode(digest(v_invite_token, 'sha256'), 'hex');
  v_expires_at := now() + interval '7 days';

  insert into user_invitations (school_id, email, initial_role, scope, token_hash, expires_at, invited_by)
  values (v_school_id, v_email, p_role, '{}'::jsonb, v_invite_token_hash, v_expires_at, v_actor.user_id);

  insert into audit_logs (school_id, user_id, acted_role, action, entity_type, entity_id, details)
  values (v_school_id, v_actor.user_id, v_actor.role, 'user.invite', 'user_invitations', v_email,
          jsonb_build_object('role', p_role));

  return query select v_invite_token, v_expires_at;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.get_session_actor(p_token text)
 RETURNS TABLE(user_id uuid, role role_type, school_id uuid)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
declare
  v_token_hash text;
begin
  v_token_hash := encode(digest(p_token, 'sha256'), 'hex');

  return query
    select s.user_id, s.active_role, s.active_school_id
    from sessions s
    where s.token_hash = v_token_hash
      and s.revoked_at is null
      and s.expires_at > now();
end;
$function$
;

CREATE OR REPLACE FUNCTION public.list_school_invitations(p_token text, p_school_id uuid DEFAULT NULL::uuid)
 RETURNS TABLE(id uuid, email character varying, initial_role role_type, status invitation_status, expires_at timestamp with time zone, created_at timestamp with time zone)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
declare
  v_actor record;
  v_school_id uuid;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then
    raise exception 'invalid_session';
  end if;

  if v_actor.role not in ('school_admin', 'super_admin') then
    raise exception 'forbidden';
  end if;

  if v_actor.role = 'school_admin' then
    v_school_id := v_actor.school_id;
  else
    if p_school_id is null then
      raise exception 'school_id_required';
    end if;
    v_school_id := p_school_id;
  end if;

  return query
    select ui.id, ui.email, ui.initial_role, ui.status, ui.expires_at, ui.created_at
    from user_invitations ui
    where ui.school_id = v_school_id
    order by ui.created_at desc;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.redeem_parent_binding_code(p_code text, p_relationship text, p_email text, p_first_name text, p_last_name text, p_password text)
 RETURNS TABLE(session_token text, user_id uuid, email character varying, first_name character varying, last_name character varying, active_role role_type, active_school_id uuid)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
declare
  v_code_hash text;
  v_binding parent_binding_codes%rowtype;
  v_email text;
  v_user users%rowtype;
  v_link_id uuid;
  v_session_token text;
  v_session_token_hash text;
  v_session_id uuid;
begin
  v_code_hash := encode(digest(upper(trim(p_code)), 'sha256'), 'hex');

  select * into v_binding from parent_binding_codes
    where code_hash = v_code_hash and status = 'issued' and expires_at > now();

  if not found then
    raise exception 'invalid_or_expired_code';
  end if;

  v_email := lower(trim(p_email));

  select * into v_user from users where email = v_email;

  if not found then
    insert into users (school_id, email, password_hash, first_name, last_name, created_by)
    values (v_binding.school_id, v_email, crypt(p_password, gen_salt('bf')), p_first_name, p_last_name, v_binding.issued_by)
    returning * into v_user;
  else
    -- account already exists (e.g. parent with a kid at another school too) —
    -- verify the password so a binding code + guessed email can't hijack it
    if v_user.password_hash is null or v_user.password_hash <> crypt(p_password, v_user.password_hash) then
      raise exception 'invalid_credentials';
    end if;
  end if;

  if not exists (select 1 from user_roles where user_id = v_user.id and role = 'parent' and school_id = v_binding.school_id) then
    insert into user_roles (user_id, role, school_id, granted_by)
    values (v_user.id, 'parent', v_binding.school_id, v_binding.issued_by);
  end if;

  if exists (select 1 from parent_links where student_id = v_binding.student_id and parent_id = v_user.id) then
    raise exception 'already_linked';
  end if;

  insert into parent_links (student_id, parent_id, relationship, binding_code_id, status)
  values (v_binding.student_id, v_user.id, p_relationship, v_binding.id, 'pending')
  returning id into v_link_id;

  update parent_binding_codes
    set status = 'redeemed', redeemed_by = v_user.id, redeemed_at = now()
    where id = v_binding.id;

  insert into audit_logs (school_id, user_id, acted_role, action, entity_type, entity_id)
  values (v_binding.school_id, v_user.id, 'parent', 'parent.redeem_binding_code', 'parent_links', v_link_id::text);

  v_session_token := encode(gen_random_bytes(32), 'hex');
  v_session_token_hash := encode(digest(v_session_token, 'sha256'), 'hex');

  insert into sessions (user_id, active_role, active_school_id, token_hash, expires_at)
  values (v_user.id, 'parent', v_binding.school_id, v_session_token_hash, now() + interval '7 days')
  returning id into v_session_id;

  return query
    select v_session_token, v_user.id, v_user.email, v_user.first_name, v_user.last_name,
           'parent'::role_type, v_binding.school_id;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.update_user_role(p_token text, p_target_user_id uuid, p_new_role role_type)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
DECLARE
  v_actor record;
  v_target users%rowtype;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  IF v_actor.role NOT IN ('school_admin', 'super_admin') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  IF v_actor.user_id = p_target_user_id THEN
    RAISE EXCEPTION 'cannot_change_own_role';
  END IF;

  SELECT * INTO v_target FROM users WHERE id = p_target_user_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'user_not_found';
  END IF;

  IF v_actor.role = 'school_admin' THEN
    IF v_actor.school_id IS DISTINCT FROM v_target.school_id THEN
      RAISE EXCEPTION 'forbidden';
    END IF;

    IF p_new_role = 'super_admin'
       OR EXISTS (
         SELECT 1
         FROM user_roles
         WHERE user_id = p_target_user_id
           AND role = 'super_admin'
       ) THEN
      RAISE EXCEPTION 'forbidden_role_grant';
    END IF;
  END IF;

  -- Delete previous roles for this user in this school context
  DELETE FROM user_roles
  WHERE user_id = p_target_user_id
    AND (
      (p_new_role != 'super_admin' AND (school_id IS NULL OR school_id = v_target.school_id))
      OR (p_new_role = 'super_admin')
    );

  -- Insert new clean role with current timestamp
  INSERT INTO user_roles (user_id, role, school_id, granted_by, granted_at)
  VALUES (
    p_target_user_id,
    p_new_role,
    CASE WHEN p_new_role = 'super_admin' THEN NULL ELSE v_target.school_id END,
    v_actor.user_id,
    now()
  );

  -- Revoke existing active sessions so user is required to sign in with new role
  UPDATE sessions
  SET revoked_at = now()
  WHERE user_id = p_target_user_id AND revoked_at IS NULL;

  INSERT INTO audit_logs (
    school_id, user_id, acted_role, action, entity_type, entity_id, details
  )
  VALUES (
    v_actor.school_id,
    v_actor.user_id,
    v_actor.role,
    'user.update_role',
    'users',
    p_target_user_id::text,
    jsonb_build_object('new_role', p_new_role)
  );
END;
$function$
;



-- 5. Re-create compatibility view profiles
CREATE OR REPLACE VIEW public.profiles AS
SELECT 
  u.id,
  u.email,
  trim(coalesce(u.first_name, '') || ' ' || coalesce(u.last_name, '')) as full_name,
  ur.role::text as role,
  (u.status = 'active') as is_active,
  u.school_id,
  u.created_at,
  u.created_at as updated_at
FROM public.users u
LEFT JOIN public.user_roles ur ON ur.user_id = u.id;

-- 6. Restore function grants
REVOKE ALL ON FUNCTION public.accept_staff_invitation FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.accept_staff_invitation TO anon, authenticated;

REVOKE ALL ON FUNCTION public.auth_sign_in FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.auth_sign_in TO anon, authenticated;

REVOKE ALL ON FUNCTION public.auth_validate_session FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.auth_validate_session TO anon, authenticated;

REVOKE ALL ON FUNCTION public.auth_verify_login_otp FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.auth_verify_login_otp TO anon, authenticated;

REVOKE ALL ON FUNCTION public.create_staff_invitation FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_staff_invitation TO anon, authenticated;

REVOKE ALL ON FUNCTION public.get_session_actor FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_session_actor TO anon, authenticated;

REVOKE ALL ON FUNCTION public.list_school_invitations FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.list_school_invitations TO anon, authenticated;

REVOKE ALL ON FUNCTION public.redeem_parent_binding_code FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.redeem_parent_binding_code TO anon, authenticated;

REVOKE ALL ON FUNCTION public.update_user_role FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.update_user_role TO anon, authenticated;

-- 7. Revoke active sessions for deleted/remapped users
UPDATE public.sessions
SET revoked_at = now()
WHERE user_id IN (
  SELECT id FROM public.users
  WHERE email IN ('facility@aiot-school-lab.local', 'technician@aiot-school-lab.local')
)
AND revoked_at IS NULL;

-- 8. Delete obsolete seed accounts
DELETE FROM public.users
WHERE email IN ('facility@aiot-school-lab.local', 'technician@aiot-school-lab.local');
