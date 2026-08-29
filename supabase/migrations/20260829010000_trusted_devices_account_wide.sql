-- =====================================================================
-- Migration: widen "remember this device" trust from per-role to
-- per-account — one OTP verification on a device should cover every
-- role that account holds, not just the one role that was active when
-- the checkbox was ticked.
--
-- trusted_devices still records which role/school the trust was earned
-- under (informational — useful for an eventual "your trusted devices"
-- management screen) but the lookup in auth_sign_in / auth_select_role
-- now matches on user_id alone. Password is still checked first and
-- unconditionally in both functions — unchanged from the previous
-- migration, this only widens what a trust token can skip OTP for.
-- =====================================================================

create or replace function public.auth_sign_in(
  p_email text,
  p_password text,
  p_device_info text default null::text,
  p_ip_address text default null::text,
  p_device_trust_token text default null::text
)
returns table(
  auth_state text,
  session_token text,
  user_id uuid,
  email character varying,
  first_name character varying,
  last_name character varying,
  must_change_password boolean,
  active_role role_type,
  active_school_id uuid,
  otp_token text,
  otp_code text,
  otp_expires_at timestamp with time zone,
  building character varying
)
language plpgsql
security definer
set search_path to 'public', 'extensions'
as $function$
declare
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
  v_role_count integer;
  v_role_selection_token text;
  v_available_roles_json text;
  v_token text;
  v_session_id uuid;
  v_last_otp_sent timestamptz;
  v_daily_otp_count integer;
  v_daily_otp_cap integer;
  v_otp_token text;
  v_otp_code text;
  v_otp_expires_at timestamptz;
  v_trusted trusted_devices%rowtype;
begin
  v_email_hash := encode(digest(v_email, 'sha256'), 'hex');
  if trim(coalesce(p_ip_address, '')) ~ '^[0-9a-f]{64}$' then
    v_ip_hash := lower(trim(p_ip_address));
  end if;

  select * into v_limit
  from auth_login_rate_limits
  where auth_login_rate_limits.email_hash = v_email_hash
  for update;

  if found and v_limit.blocked_until is not null
     and v_limit.blocked_until > now() then
    return;
  end if;

  if v_ip_hash is not null then
    select * into v_ip_limit
    from auth_login_ip_rate_limits
    where auth_login_ip_rate_limits.ip_hash = v_ip_hash
    for update;

    if found and v_ip_limit.blocked_until is not null
       and v_ip_limit.blocked_until > now() then
      return;
    end if;
  end if;

  select dummy_password_hash into v_dummy_password_hash
  from auth_security_constants
  where singleton = true;

  select * into v_user
  from users
  where users.email = v_email and users.status = 'active';
  v_user_found := found;

  v_password_hash := coalesce(v_user.password_hash, v_dummy_password_hash);
  v_password_matches := crypt(coalesce(p_password, ''), v_password_hash)
    = v_password_hash;

  if not v_user_found
     or v_user.password_hash is null
     or v_password_matches is not true then
    insert into auth_login_rate_limits (
      email_hash, window_started_at, attempt_count, blocked_until, last_attempt_at
    )
    values (v_email_hash, now(), 1, null, now())
    on conflict (email_hash) do update
    set attempt_count = case
          when auth_login_rate_limits.window_started_at < now() - interval '15 minutes'
            then 1
          else auth_login_rate_limits.attempt_count + 1
        end,
        window_started_at = case
          when auth_login_rate_limits.window_started_at < now() - interval '15 minutes'
            then now()
          else auth_login_rate_limits.window_started_at
        end,
        blocked_until = case
          when (case
            when auth_login_rate_limits.window_started_at < now() - interval '15 minutes'
              then 1
            else auth_login_rate_limits.attempt_count + 1
          end) >= 5 then now() + interval '15 minutes'
          else null
        end,
        last_attempt_at = now();

    if v_ip_hash is not null then
      insert into auth_login_ip_rate_limits (
        ip_hash, window_started_at, attempt_count, blocked_until, last_attempt_at
      )
      values (v_ip_hash, now(), 1, null, now())
      on conflict (ip_hash) do update
      set attempt_count = case
            when auth_login_ip_rate_limits.window_started_at < now() - interval '15 minutes'
              then 1
            else auth_login_ip_rate_limits.attempt_count + 1
          end,
          window_started_at = case
            when auth_login_ip_rate_limits.window_started_at < now() - interval '15 minutes'
              then now()
            else auth_login_ip_rate_limits.window_started_at
          end,
          blocked_until = case
            when (case
              when auth_login_ip_rate_limits.window_started_at < now() - interval '15 minutes'
                then 1
              else auth_login_ip_rate_limits.attempt_count + 1
            end) >= 20 then now() + interval '15 minutes'
            else null
          end,
          last_attempt_at = now();
    end if;
    return;
  end if;

  delete from auth_login_rate_limits where auth_login_rate_limits.email_hash = v_email_hash;

  select count(*) into v_role_count
  from user_roles ur
  where ur.user_id = v_user.id
    and (v_user.school_id is null or ur.school_id is not distinct from v_user.school_id or ur.role = 'super_admin');

  if v_role_count >= 2 then
    v_role_selection_token := 'rs_' || encode(gen_random_bytes(32), 'hex');

    insert into role_selection_challenges (token_hash, user_id, expires_at)
    values (
      encode(digest(v_role_selection_token, 'sha256'), 'hex'),
      v_user.id,
      now() + interval '5 minutes'
    );

    select jsonb_agg(
      jsonb_build_object(
        'role', ur.role,
        'school_id', ur.school_id,
        'school_name', coalesce(s.name, 'ส่วนกลาง')
      ) order by ur.granted_at desc
    )::text into v_available_roles_json
    from user_roles ur
    left join schools s on s.id = ur.school_id
    where ur.user_id = v_user.id
      and (v_user.school_id is null or ur.school_id is not distinct from v_user.school_id or ur.role = 'super_admin');

    return query select
      'role_selection_required'::text,
      null::text,
      v_user.id,
      v_user.email,
      v_user.first_name,
      v_user.last_name,
      v_user.must_change_password,
      null::role_type,
      null::uuid,
      v_role_selection_token,
      null::text,
      null::timestamptz,
      v_available_roles_json::varchar;
    return;
  end if;

  select * into v_role
  from user_roles ur
  where ur.user_id = v_user.id
    and (v_user.school_id is null or ur.school_id is not distinct from v_user.school_id or ur.role = 'super_admin')
  order by ur.granted_at desc
  limit 1;

  if not found then
    select * into v_role
    from user_roles ur
    where ur.user_id = v_user.id
    order by ur.granted_at desc
    limit 1;
  end if;

  if v_role.role is null then
    return;
  end if;

  if v_role.role in ('super_admin', 'school_admin', 'executive', 'teacher') then
    -- Trusted-device check: account-wide — a device trusted via ANY role
    -- on this account skips OTP for every role on it, not just the one
    -- that was active when "remember this device" was checked.
    if p_device_trust_token is not null then
      select * into v_trusted
      from trusted_devices td
      where td.token_hash = encode(digest(p_device_trust_token, 'sha256'), 'hex')
        and td.user_id = v_user.id
        and td.revoked_at is null
        and td.expires_at > now();

      if found then
        update trusted_devices set last_used_at = now() where id = v_trusted.id;

        v_token := encode(gen_random_bytes(32), 'hex');
        insert into sessions (
          user_id, active_role, active_school_id, token_hash,
          device_info, ip_address, expires_at
        ) values (
          v_user.id, v_role.role, v_role.school_id,
          encode(digest(v_token, 'sha256'), 'hex'),
          left(p_device_info, 255), v_ip_hash, now() + interval '7 days'
        )
        returning id into v_session_id;

        insert into audit_logs (
          school_id, user_id, acted_role, action, entity_type, entity_id
        ) values (
          v_role.school_id, v_user.id, v_role.role,
          'auth.sign_in_trusted_device', 'sessions', v_session_id::text
        );

        return query select
          'authenticated'::text, v_token, v_user.id, v_user.email,
          v_user.first_name, v_user.last_name, v_user.must_change_password,
          v_role.role, v_role.school_id, null::text, null::text,
          null::timestamptz, v_user.building;
        return;
      end if;
    end if;

    select max(oc.last_sent_at), count(*) filter (
      where oc.last_sent_at >= now() - interval '24 hours'
    )
    into v_last_otp_sent, v_daily_otp_count
    from otp_codes oc
    where oc.user_id = v_user.id
      and oc.purpose = 'login_2fa';

    v_daily_otp_cap := case
      when v_role_count >= 2 then 20
      else 10
    end;

    if (v_last_otp_sent is not null and v_last_otp_sent > now() - interval '60 seconds')
       or coalesce(v_daily_otp_count, 0) >= v_daily_otp_cap then
      return query select
        'rate_limited'::text, null::text, v_user.id, v_user.email,
        v_user.first_name, v_user.last_name, v_user.must_change_password,
        v_role.role, v_role.school_id, null::text, null::text,
        null::timestamptz, v_user.building;
      return;
    end if;

    v_otp_token := 'lo_' || encode(gen_random_bytes(32), 'hex');
    v_otp_code := lpad(
      ((('x' || encode(gen_random_bytes(4), 'hex'))::bit(32)::bigint % 1000000))::text,
      6, '0'
    );
    v_otp_expires_at := now() + interval '10 minutes';

    update otp_codes oc
    set used_at = now()
    where oc.user_id = v_user.id
      and oc.purpose = 'login_2fa'
      and oc.used_at is null;

    insert into otp_codes (
      user_id, purpose, code_hash, sent_to_email,
      verification_token_hash, login_role, login_school_id,
      login_device_info, login_ip_address, last_sent_at, expires_at
    ) values (
      v_user.id, 'login_2fa',
      encode(digest(v_otp_code || ':' || v_otp_token, 'sha256'), 'hex'),
      v_user.email,
      encode(digest(v_otp_token, 'sha256'), 'hex'),
      v_role.role, v_role.school_id,
      left(p_device_info, 255), v_ip_hash, now(), v_otp_expires_at
    );

    insert into audit_logs (
      school_id, user_id, acted_role, action, entity_type, details
    ) values (
      v_role.school_id, v_user.id, v_role.role,
      'auth.otp_requested', 'otp_codes',
      jsonb_build_object('purpose', 'login_2fa', 'expires_at', v_otp_expires_at)
    );

    return query select
      'mfa_required'::text, null::text, v_user.id, v_user.email,
      v_user.first_name, v_user.last_name, v_user.must_change_password,
      v_role.role, v_role.school_id, v_otp_token, v_otp_code,
      v_otp_expires_at, v_user.building;
    return;
  end if;

  v_token := encode(gen_random_bytes(32), 'hex');
  insert into sessions (
    user_id, active_role, active_school_id, token_hash,
    device_info, ip_address, expires_at
  ) values (
    v_user.id, v_role.role, v_role.school_id,
    encode(digest(v_token, 'sha256'), 'hex'),
    left(p_device_info, 255), v_ip_hash, now() + interval '30 days'
  )
  returning id into v_session_id;

  update sessions
  set revoked_at = now()
  where id in (
    select s.id from sessions s
    where s.user_id = v_user.id and s.revoked_at is null
    order by s.created_at desc, s.id desc
    offset 5
  );

  insert into audit_logs (
    school_id, user_id, acted_role, action, entity_type, entity_id
  ) values (
    v_role.school_id, v_user.id, v_role.role,
    'auth.sign_in', 'sessions', v_session_id::text
  );

  return query select
    'authenticated'::text, v_token, v_user.id, v_user.email,
    v_user.first_name, v_user.last_name, v_user.must_change_password,
    v_role.role, v_role.school_id, null::text, null::text,
    null::timestamptz, v_user.building;
end;
$function$;

-- ---------------------------------------------------------------------
-- Same widening for auth_select_role (multi-role picker path).
-- ---------------------------------------------------------------------
create or replace function public.auth_select_role(
  p_role_selection_token text,
  p_role role_type,
  p_school_id uuid default null,
  p_device_info text default null,
  p_ip_address text default null,
  p_device_trust_token text default null
)
returns table(
  auth_state text,
  session_token text,
  user_id uuid,
  email character varying,
  first_name character varying,
  last_name character varying,
  must_change_password boolean,
  active_role role_type,
  active_school_id uuid,
  otp_token text,
  otp_code text,
  otp_expires_at timestamp with time zone,
  building character varying
)
language plpgsql
security definer
set search_path to 'public', 'extensions'
as $function$
declare
  v_token_hash text;
  v_challenge role_selection_challenges%rowtype;
  v_user users%rowtype;
  v_role user_roles%rowtype;
  v_ip_hash text;
  v_last_otp_sent timestamptz;
  v_daily_otp_count integer;
  v_daily_otp_cap integer;
  v_otp_token text;
  v_otp_code text;
  v_otp_expires_at timestamptz;
  v_token text;
  v_session_id uuid;
  v_trusted trusted_devices%rowtype;
begin
  if trim(coalesce(p_role_selection_token, '')) = '' then
    raise exception 'invalid_or_expired_role_selection_token';
  end if;

  v_token_hash := encode(digest(p_role_selection_token, 'sha256'), 'hex');

  select * into v_challenge
  from role_selection_challenges rsc
  where rsc.token_hash = v_token_hash
    and rsc.used_at is null
    and rsc.expires_at > now()
  for update;

  if not found then
    raise exception 'invalid_or_expired_role_selection_token';
  end if;

  select * into v_user
  from users u
  where u.id = v_challenge.user_id and u.status = 'active';

  if not found then
    raise exception 'user_not_found';
  end if;

  if p_role = 'super_admin' then
    select * into v_role
    from user_roles ur
    where ur.user_id = v_user.id and ur.role = 'super_admin'
    order by ur.granted_at desc
    limit 1;
  else
    select * into v_role
    from user_roles ur
    where ur.user_id = v_user.id
      and ur.role = p_role
      and (p_school_id is null or ur.school_id = p_school_id)
    order by ur.granted_at desc
    limit 1;
  end if;

  if not found then
    raise exception 'unauthorized_role_selection';
  end if;

  update role_selection_challenges rsc
  set used_at = now()
  where rsc.token_hash = v_token_hash;

  if trim(coalesce(p_ip_address, '')) ~ '^[0-9a-f]{64}$' then
    v_ip_hash := lower(trim(p_ip_address));
  end if;

  if v_role.role in ('super_admin', 'school_admin', 'executive', 'teacher') then
    -- Account-wide trusted-device check (see auth_sign_in above).
    if p_device_trust_token is not null then
      select * into v_trusted
      from trusted_devices td
      where td.token_hash = encode(digest(p_device_trust_token, 'sha256'), 'hex')
        and td.user_id = v_user.id
        and td.revoked_at is null
        and td.expires_at > now();

      if found then
        update trusted_devices set last_used_at = now() where id = v_trusted.id;

        v_token := encode(gen_random_bytes(32), 'hex');
        insert into sessions (
          user_id, active_role, active_school_id, token_hash,
          device_info, ip_address, expires_at
        ) values (
          v_user.id, v_role.role, v_role.school_id,
          encode(digest(v_token, 'sha256'), 'hex'),
          left(p_device_info, 255), v_ip_hash, now() + interval '7 days'
        )
        returning id into v_session_id;

        insert into audit_logs (
          school_id, user_id, acted_role, action, entity_type, entity_id
        ) values (
          v_role.school_id, v_user.id, v_role.role,
          'auth.sign_in_trusted_device', 'sessions', v_session_id::text
        );

        return query select
          'authenticated'::text, v_token, v_user.id, v_user.email,
          v_user.first_name, v_user.last_name, v_user.must_change_password,
          v_role.role, v_role.school_id, null::text, null::text,
          null::timestamptz, v_user.building;
        return;
      end if;
    end if;

    select max(oc.last_sent_at), count(*) filter (
      where oc.last_sent_at >= now() - interval '24 hours'
    )
    into v_last_otp_sent, v_daily_otp_count
    from otp_codes oc
    where oc.user_id = v_user.id
      and oc.purpose = 'login_2fa';

    v_daily_otp_cap := 20;

    if (v_last_otp_sent is not null and v_last_otp_sent > now() - interval '60 seconds')
       or coalesce(v_daily_otp_count, 0) >= v_daily_otp_cap then
      return query select
        'rate_limited'::text, null::text, v_user.id, v_user.email,
        v_user.first_name, v_user.last_name, v_user.must_change_password,
        v_role.role, v_role.school_id, null::text, null::text,
        null::timestamptz, v_user.building;
      return;
    end if;

    v_otp_token := 'lo_' || encode(gen_random_bytes(32), 'hex');
    v_otp_code := lpad(
      ((('x' || encode(gen_random_bytes(4), 'hex'))::bit(32)::bigint % 1000000))::text,
      6, '0'
    );
    v_otp_expires_at := now() + interval '10 minutes';

    update otp_codes oc
    set used_at = now()
    where oc.user_id = v_user.id
      and oc.purpose = 'login_2fa'
      and oc.used_at is null;

    insert into otp_codes (
      user_id, purpose, code_hash, sent_to_email,
      verification_token_hash, login_role, login_school_id,
      login_device_info, login_ip_address, last_sent_at, expires_at
    ) values (
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

    insert into audit_logs (
      school_id, user_id, acted_role, action, entity_type, details
    ) values (
      v_role.school_id, v_user.id, v_role.role,
      'auth.otp_requested', 'otp_codes',
      jsonb_build_object('purpose', 'login_2fa', 'expires_at', v_otp_expires_at)
    );

    return query select
      'mfa_required'::text, null::text, v_user.id, v_user.email,
      v_user.first_name, v_user.last_name, v_user.must_change_password,
      v_role.role, v_role.school_id, v_otp_token, v_otp_code,
      v_otp_expires_at, v_user.building;
    return;
  end if;

  v_token := encode(gen_random_bytes(32), 'hex');

  insert into sessions (
    user_id, active_role, active_school_id, token_hash, device_info,
    ip_address, expires_at
  ) values (
    v_user.id,
    v_role.role,
    v_role.school_id,
    encode(digest(v_token, 'sha256'), 'hex'),
    left(p_device_info, 255),
    v_ip_hash,
    now() + interval '30 days'
  )
  returning id into v_session_id;

  update sessions
  set revoked_at = now()
  where id in (
    select s.id from sessions s
    where s.user_id = v_user.id and s.revoked_at is null
    order by s.created_at desc, s.id desc
    offset 5
  );

  insert into audit_logs (
    school_id, user_id, acted_role, action, entity_type, entity_id
  ) values (
    v_role.school_id, v_user.id, v_role.role,
    'auth.sign_in', 'sessions', v_session_id::text
  );

  return query select
    'authenticated'::text,
    v_token,
    v_user.id,
    v_user.email,
    v_user.first_name,
    v_user.last_name,
    v_user.must_change_password,
    v_role.role,
    v_role.school_id,
    null::text,
    null::text,
    null::timestamptz,
    v_user.building;
end;
$function$;
