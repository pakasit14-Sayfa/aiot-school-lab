-- Migration: 20260824150000_fix_school_admin_role_and_reactivate.sql
-- Description: Fix update_user_role lifecycle, auth_sign_in latest role selection, and add reactivate_user RPC

-- 1. update_user_role
CREATE OR REPLACE FUNCTION public.update_user_role(
  p_token text,
  p_target_user_id uuid,
  p_new_role role_type
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
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
$$;

-- 2. auth_sign_in with latest granted role
CREATE OR REPLACE FUNCTION public.auth_sign_in(
  p_email text,
  p_password text,
  p_device_info text DEFAULT NULL,
  p_ip_address text DEFAULT NULL
)
RETURNS TABLE (
  auth_state text,
  session_token text,
  user_id uuid,
  email varchar,
  first_name varchar,
  last_name varchar,
  must_change_password bool,
  active_role role_type,
  active_school_id uuid,
  otp_token text,
  otp_code text,
  otp_expires_at timestamptz,
  building varchar
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
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
$$;

-- 3. reactivate_user
CREATE OR REPLACE FUNCTION public.reactivate_user(
  p_token text,
  p_target_user_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
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
    RAISE EXCEPTION 'cannot_reactivate_self';
  END IF;

  SELECT * INTO v_target FROM users WHERE id = p_target_user_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'user_not_found';
  END IF;

  IF v_actor.role = 'school_admin' AND v_actor.school_id IS DISTINCT FROM v_target.school_id THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  UPDATE users
  SET status = 'active'
  WHERE id = p_target_user_id;

  INSERT INTO audit_logs (school_id, user_id, acted_role, action, entity_type, entity_id)
  VALUES (v_actor.school_id, v_actor.user_id, v_actor.role, 'user.reactivate', 'users', p_target_user_id::text);
END;
$$;

-- Permissions
REVOKE ALL ON FUNCTION public.update_user_role FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.update_user_role TO anon, authenticated;

REVOKE ALL ON FUNCTION public.auth_sign_in FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.auth_sign_in TO anon, authenticated;

REVOKE ALL ON FUNCTION public.reactivate_user FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.reactivate_user TO anon, authenticated;
