-- =====================================================================
-- Session token + login rate limit hardening (PDPA gate 3 + 4).
--
-- PostgreSQL grants EXECUTE on newly-created functions to PUBLIC by
-- default.  Sensitive SECURITY DEFINER functions must therefore revoke
-- PUBLIC explicitly before granting the minimum caller roles.
-- =====================================================================

revoke all on function request_password_reset_otp(text) from public;
revoke all on function request_password_reset_otp(text) from anon, authenticated;
grant execute on function request_password_reset_otp(text) to service_role;

-- Internal token-to-actor helper.  Only SECURITY DEFINER functions owned by
-- the database owner should call it; exposing it through PostgREST would
-- unnecessarily disclose the active role/school attached to a bearer token.
revoke all on function get_session_actor(text) from public, anon, authenticated;

-- Custom-session hardening and server-side login throttling. Failed attempts
-- return no rows instead of raising so the counter is committed; an exception
-- would roll back the rate-limit update in the same transaction.
create table if not exists auth_login_rate_limits (
  email_hash text primary key,
  window_started_at timestamptz not null default now(),
  attempt_count integer not null default 0 check (attempt_count >= 0),
  blocked_until timestamptz,
  last_attempt_at timestamptz not null default now()
);

create table if not exists auth_login_ip_rate_limits (
  ip_hash text primary key,
  window_started_at timestamptz not null default now(),
  attempt_count integer not null default 0 check (attempt_count >= 0),
  blocked_until timestamptz,
  last_attempt_at timestamptz not null default now()
);

-- A real password hash is used for nonexistent/disabled accounts so every
-- credential check pays the same bcrypt cost and does not reveal membership
-- through response timing.
create table if not exists auth_security_constants (
  singleton boolean primary key default true check (singleton),
  dummy_password_hash text not null
);

insert into auth_security_constants (singleton, dummy_password_hash)
values (
  true,
  crypt(encode(gen_random_bytes(32), 'hex'), gen_salt('bf'))
)
on conflict (singleton) do nothing;

create table if not exists operational_alerts (
  id bigserial primary key,
  category varchar not null,
  severity varchar not null check (severity in ('warning', 'critical')),
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  resolved_at timestamptz
);

alter table auth_login_rate_limits enable row level security;
alter table auth_login_ip_rate_limits enable row level security;
alter table auth_security_constants enable row level security;
alter table operational_alerts enable row level security;
revoke all on table auth_login_rate_limits from public, anon, authenticated;
revoke all on table auth_login_ip_rate_limits from public, anon, authenticated;
revoke all on table auth_security_constants from public, anon, authenticated;
revoke all on table operational_alerts from public, anon, authenticated;

-- Existing values came from the legacy direct-RPC flow and may contain raw
-- addresses. They cannot be retroactively peppered without re-identifying
-- them, so minimise the data by removing them before accepting fingerprints.
update sessions set ip_address = null where ip_address is not null;
comment on column sessions.ip_address is
  'Legacy name: stores only a 64-char HMAC-SHA256 IP fingerprint, never a raw address';

create unique index if not exists idx_sessions_token_hash on sessions (token_hash);
create index if not exists idx_sessions_user_active
  on sessions (user_id, created_at desc)
  where revoked_at is null;

create or replace function auth_sign_in(
  p_email text,
  p_password text,
  p_device_info text default null,
  p_ip_address text default null
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
    v_token, v_user.id, v_user.email, v_user.first_name, v_user.last_name,
    v_user.must_change_password, v_role.role, v_role.school_id;
end;
$$;

create or replace function auth_sign_out_all(p_token text)
returns integer
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_count integer;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then return 0; end if;

  update sessions set revoked_at = now()
  where user_id = v_actor.user_id and revoked_at is null;
  get diagnostics v_count = row_count;

  insert into audit_logs (
    school_id, user_id, acted_role, action, entity_type, details
  ) values (
    v_actor.school_id, v_actor.user_id, v_actor.role,
    'auth.sign_out_all', 'sessions', jsonb_build_object('revoked', v_count)
  );
  return v_count;
end;
$$;

revoke all on function auth_sign_in(text, text, text, text)
  from public, anon, authenticated;
revoke all on function auth_sign_out_all(text) from public;
grant execute on function auth_sign_in(text, text, text, text) to service_role;
grant execute on function auth_sign_out_all(text) to anon, authenticated;

create or replace function record_operational_alert(
  p_category text,
  p_severity text,
  p_details jsonb default '{}'::jsonb
)
returns bigint
language plpgsql
security definer
set search_path = public
as $$
declare
  v_alert_id bigint;
begin
  if trim(coalesce(p_category, '')) !~ '^[a-z0-9_]{3,100}$' then
    raise exception 'invalid_alert_category';
  end if;
  if p_severity not in ('warning', 'critical') then
    raise exception 'invalid_alert_severity';
  end if;
  if p_details ?| array['email', 'otp', 'password', 'token', 'ip'] then
    raise exception 'sensitive_alert_details_forbidden';
  end if;

  insert into operational_alerts (category, severity, details)
  values (trim(p_category), p_severity, coalesce(p_details, '{}'::jsonb))
  returning id into v_alert_id;
  return v_alert_id;
end;
$$;

revoke all on function record_operational_alert(text, text, jsonb)
  from public, anon, authenticated;
grant execute on function record_operational_alert(text, text, jsonb)
  to service_role;

-- A School Admin is scoped to one school and must never be able to create a
-- platform-wide Super Admin.  They also cannot alter an existing Super Admin.
create or replace function update_user_role(
  p_token text,
  p_target_user_id uuid,
  p_new_role role_type
)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_target users%rowtype;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then
    raise exception 'invalid_session';
  end if;

  if v_actor.role not in ('school_admin', 'super_admin') then
    raise exception 'forbidden';
  end if;

  if v_actor.user_id = p_target_user_id then
    raise exception 'cannot_change_own_role';
  end if;

  select * into v_target from users where id = p_target_user_id;
  if not found then
    raise exception 'user_not_found';
  end if;

  if v_actor.role = 'school_admin' then
    if v_actor.school_id is distinct from v_target.school_id then
      raise exception 'forbidden';
    end if;

    if p_new_role = 'super_admin'
       or exists (
         select 1
         from user_roles
         where user_id = p_target_user_id
           and role = 'super_admin'
       ) then
      raise exception 'forbidden_role_grant';
    end if;
  end if;

  insert into user_roles (user_id, role, school_id, granted_by)
  values (
    p_target_user_id,
    p_new_role,
    case when p_new_role = 'super_admin' then null else v_target.school_id end,
    v_actor.user_id
  )
  on conflict (user_id, role, school_id) do nothing;

  update sessions
    set revoked_at = now()
    where user_id = p_target_user_id and revoked_at is null;

  insert into audit_logs (
    school_id,
    user_id,
    acted_role,
    action,
    entity_type,
    entity_id,
    details
  )
  values (
    v_actor.school_id,
    v_actor.user_id,
    v_actor.role,
    'user.update_role',
    'users',
    p_target_user_id::text,
    jsonb_build_object('new_role', p_new_role)
  );
end;
$$;

revoke all on function update_user_role(text, uuid, role_type) from public;
grant execute on function update_user_role(text, uuid, role_type) to anon, authenticated;
