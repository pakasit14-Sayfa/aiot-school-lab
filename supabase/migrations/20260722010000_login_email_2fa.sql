-- Email OTP gate for high-risk roles. Password verification creates a
-- short-lived challenge; an authenticated session is minted only after OTP
-- verification. The plaintext OTP is returned only to the service-role Edge
-- Function and is never exposed through PostgREST to anon/authenticated.

alter table otp_codes
  add column if not exists login_role role_type,
  add column if not exists login_school_id uuid,
  add column if not exists login_device_info varchar,
  add column if not exists login_ip_address varchar;

alter table otp_codes
  drop constraint if exists fk_otp_codes_login_school;
alter table otp_codes
  add constraint fk_otp_codes_login_school
  foreign key (login_school_id) references schools(id);

create index if not exists idx_otp_codes_login_user_recent
  on otp_codes (user_id, last_sent_at desc)
  where purpose = 'login_2fa';

revoke all on function auth_sign_in(text, text, text, text)
  from public, anon, authenticated, service_role;
drop function auth_sign_in(text, text, text, text);

create function auth_sign_in(
  p_email text,
  p_password text,
  p_device_info text default null,
  p_ip_address text default null
)
returns table (
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
  otp_expires_at timestamptz
)
language plpgsql
security definer
set search_path = public, extensions
as $$
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
  v_token text;
  v_session_id uuid;
  v_last_otp_sent timestamptz;
  v_daily_otp_count integer;
  v_otp_token text;
  v_otp_code text;
  v_otp_expires_at timestamptz;
begin
  v_email_hash := encode(digest(v_email, 'sha256'), 'hex');
  if trim(coalesce(p_ip_address, '')) ~ '^[0-9a-f]{64}$' then
    v_ip_hash := encode(digest(trim(p_ip_address), 'sha256'), 'hex');
  end if;

  select * into v_limit
  from auth_login_rate_limits
  where email_hash = v_email_hash
  for update;

  if found and v_limit.blocked_until is not null
     and v_limit.blocked_until > now() then
    return;
  end if;

  if v_ip_hash is not null then
    select * into v_ip_limit
    from auth_login_ip_rate_limits
    where ip_hash = v_ip_hash
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

  delete from auth_login_rate_limits where email_hash = v_email_hash;

  select * into v_role
  from user_roles
  where user_roles.user_id = v_user.id
  order by granted_at asc
  limit 1;

  if not found then
    raise exception 'no_role_assigned';
  end if;

  if v_role.role in ('super_admin', 'school_admin', 'teacher', 'executive') then
    select max(last_sent_at), count(*) filter (
      where last_sent_at >= now() - interval '24 hours'
    )
    into v_last_otp_sent, v_daily_otp_count
    from otp_codes oc
    where oc.user_id = v_user.id
      and oc.purpose = 'login_2fa';

    if (v_last_otp_sent is not null
        and v_last_otp_sent > now() - interval '60 seconds')
       or v_daily_otp_count >= 10 then
      return query select
        'rate_limited'::text, null::text, v_user.id, v_user.email,
        v_user.first_name, v_user.last_name, v_user.must_change_password,
        v_role.role, v_role.school_id, null::text, null::text,
        null::timestamptz;
      return;
    end if;

    v_otp_token := 'lo_' || encode(gen_random_bytes(32), 'hex');
    v_otp_code := lpad(
      ((('x' || encode(gen_random_bytes(4), 'hex'))::bit(32)::bigint % 1000000))::text,
      6,
      '0'
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
      case
        when trim(coalesce(p_ip_address, '')) ~ '^[0-9a-f]{64}$'
          then lower(trim(p_ip_address))
        else null
      end,
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
      v_otp_expires_at;
    return;
  end if;

  v_token := encode(gen_random_bytes(32), 'hex');
  insert into sessions (
    user_id, active_role, active_school_id, token_hash,
    device_info, ip_address, expires_at
  )
  values (
    v_user.id, v_role.role, v_role.school_id,
    encode(digest(v_token, 'sha256'), 'hex'),
    left(p_device_info, 255),
    case
      when trim(coalesce(p_ip_address, '')) ~ '^[0-9a-f]{64}$'
        then lower(trim(p_ip_address))
      else null
    end,
    now() + interval '7 days'
  )
  returning id into v_session_id;

  update sessions
  set revoked_at = now()
  where id in (
    select id from sessions
    where sessions.user_id = v_user.id and revoked_at is null
    order by created_at desc, id desc
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
    null::timestamptz;
end;
$$;

revoke all on function auth_sign_in(text, text, text, text)
  from public, anon, authenticated;
grant execute on function auth_sign_in(text, text, text, text) to service_role;

create function auth_verify_login_otp(
  p_otp_token text,
  p_otp_code text
)
returns table (
  session_token text,
  user_id uuid,
  email varchar,
  first_name varchar,
  last_name varchar,
  must_change_password bool,
  active_role role_type,
  active_school_id uuid
)
language plpgsql
security definer
set search_path = public, extensions
as $$
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
    v_otp.login_school_id;
end;
$$;

revoke all on function auth_verify_login_otp(text, text)
  from public, anon, authenticated;
grant execute on function auth_verify_login_otp(text, text) to service_role;
