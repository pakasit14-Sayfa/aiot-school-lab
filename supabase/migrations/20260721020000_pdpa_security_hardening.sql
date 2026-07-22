-- =====================================================================
-- PDPA/security hardening.
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

-- ---------------------------------------------------------------------
-- Parent Binding: 7-day, one-time codes with a two-slot quota.
-- ---------------------------------------------------------------------
create or replace function create_parent_binding_code(
  p_token text,
  p_student_code text
)
returns table (
  binding_code text,
  expires_at timestamptz,
  student_first_name varchar,
  student_last_name varchar
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_student users%rowtype;
  v_code text := '';
  v_alphabet constant text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  v_random bytea;
  v_index integer;
  v_active_slots integer;
  v_expires_at timestamptz;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then
    raise exception 'invalid_session';
  end if;

  if v_actor.role not in ('school_admin', 'teacher', 'super_admin') then
    raise exception 'forbidden';
  end if;

  select * into v_student
  from users
  where student_code = trim(p_student_code)
    and status = 'active'
    and (v_actor.role = 'super_admin' or school_id = v_actor.school_id)
  for update;

  if not found then
    raise exception 'student_not_found';
  end if;

  if not exists (
    select 1 from user_roles
    where user_id = v_student.id and role = 'student'
  ) then
    raise exception 'not_a_student';
  end if;

  if v_actor.role = 'teacher' and not exists (
    select 1
    from course_teachers ct
    join course_students cs on cs.course_id = ct.course_id
    where ct.teacher_id = v_actor.user_id
      and cs.student_id = v_student.id
  ) then
    raise exception 'forbidden';
  end if;

  update parent_binding_codes
  set status = 'expired'
  where student_id = v_student.id
    and status = 'issued'
    and expires_at <= now();

  select
    (select count(*)
       from parent_links
       where student_id = v_student.id
         and status in ('pending', 'pending_second_review', 'approved'))
    +
    (select count(*)
       from parent_binding_codes
       where student_id = v_student.id
         and status = 'issued'
         and expires_at > now())
  into v_active_slots;

  if v_active_slots >= 2 then
    raise exception 'parent_quota_reached';
  end if;

  v_random := gen_random_bytes(12);
  for v_index in 0..11 loop
    v_code := v_code || substr(
      v_alphabet,
      (get_byte(v_random, v_index) % length(v_alphabet)) + 1,
      1
    );
  end loop;

  v_expires_at := now() + interval '7 days';

  insert into parent_binding_codes (
    school_id,
    student_id,
    code_hash,
    code_hint,
    expires_at,
    issued_by
  )
  values (
    v_student.school_id,
    v_student.id,
    encode(digest(v_code, 'sha256'), 'hex'),
    left(v_code, 4) || '********',
    v_expires_at,
    v_actor.user_id
  );

  insert into audit_logs (
    school_id, user_id, acted_role, action, entity_type, entity_id, details
  )
  values (
    v_student.school_id,
    v_actor.user_id,
    v_actor.role,
    'parent.issue_binding_code',
    'users',
    v_student.id::text,
    jsonb_build_object('expires_at', v_expires_at)
  );

  return query
  select v_code, v_expires_at, v_student.first_name, v_student.last_name;
end;
$$;

revoke all on function create_parent_binding_code(text, text) from public;
grant execute on function create_parent_binding_code(text, text) to anon, authenticated;

-- Opaque token ties the email OTP to one Binding Code without returning a
-- student id or any student details to the public caller.
alter table otp_codes
  add column if not exists verification_token_hash varchar;

create unique index if not exists idx_otp_codes_verification_token_hash
  on otp_codes (verification_token_hash)
  where verification_token_hash is not null;

create or replace function request_parent_binding_otp(
  p_code text,
  p_email text
)
returns table (
  otp_code text,
  verification_token text
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_code_hash text;
  v_binding parent_binding_codes%rowtype;
  v_email text;
  v_last_sent timestamptz;
  v_daily_count integer;
  v_otp_code text;
  v_verification_token text;
begin
  v_code_hash := encode(digest(upper(trim(p_code)), 'sha256'), 'hex');
  v_email := lower(trim(p_email));

  if v_email !~* '^[A-Z0-9._%+\-]+@[A-Z0-9.\-]+\.[A-Z]{2,}$' then
    return;
  end if;

  select * into v_binding
  from parent_binding_codes
  where code_hash = v_code_hash
    and status = 'issued'
    and expires_at > now();

  if not found then
    return;
  end if;

  select max(last_sent_at), count(*) filter (
    where last_sent_at >= now() - interval '24 hours'
  )
  into v_last_sent, v_daily_count
  from otp_codes
  where purpose = 'parent_email_verify'
    and (
      parent_binding_code_id = v_binding.id
      or sent_to_email = v_email
    );

  if v_last_sent is not null
     and v_last_sent > now() - interval '60 seconds' then
    raise exception 'rate_limited';
  end if;

  if v_daily_count >= 10 then
    raise exception 'daily_rate_limited';
  end if;

  v_otp_code := lpad(
    ((('x' || encode(gen_random_bytes(4), 'hex'))::bit(32)::bigint % 1000000))::text,
    6,
    '0'
  );
  v_verification_token := 'pv_' || encode(gen_random_bytes(32), 'hex');

  insert into otp_codes (
    parent_binding_code_id,
    purpose,
    code_hash,
    sent_to_email,
    verification_token_hash,
    last_sent_at,
    expires_at
  )
  values (
    v_binding.id,
    'parent_email_verify',
    encode(digest(v_otp_code, 'sha256'), 'hex'),
    v_email,
    encode(digest(v_verification_token, 'sha256'), 'hex'),
    now(),
    now() + interval '10 minutes'
  );

  return query select v_otp_code, v_verification_token;
end;
$$;

revoke all on function request_parent_binding_otp(text, text)
  from public, anon, authenticated;
grant execute on function request_parent_binding_otp(text, text) to service_role;

create or replace function confirm_parent_binding(
  p_verification_token text,
  p_otp_code text,
  p_relationship text,
  p_first_name text,
  p_last_name text,
  p_password text
)
returns table (
  parent_link_id uuid,
  status binding_status
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_otp otp_codes%rowtype;
  v_binding parent_binding_codes%rowtype;
  v_user users%rowtype;
  v_link_id uuid;
  v_active_links integer;
begin
  select * into v_otp
  from otp_codes
  where verification_token_hash = encode(
      digest(trim(p_verification_token), 'sha256'),
      'hex'
    )
    and purpose = 'parent_email_verify'
    and used_at is null
  order by last_sent_at desc
  limit 1
  for update;

  if not found or v_otp.expires_at <= now() then
    return;
  end if;

  if v_otp.locked_until is not null and v_otp.locked_until > now() then
    raise exception 'too_many_attempts';
  end if;

  if v_otp.code_hash <> encode(digest(trim(p_otp_code), 'sha256'), 'hex') then
    update otp_codes
    set attempt_count = attempt_count + 1,
        locked_until = case
          when attempt_count + 1 >= 5 then now() + interval '10 minutes'
          else locked_until
        end
    where id = v_otp.id;
    return;
  end if;

  select pb.* into v_binding
  from parent_binding_codes pb
  where pb.id = v_otp.parent_binding_code_id
    and pb.status = 'issued'
    and pb.expires_at > now()
  for update;

  if not found then
    raise exception 'invalid_or_expired_verification';
  end if;

  select count(*) into v_active_links
  from parent_links pl
  where pl.student_id = v_binding.student_id
    and pl.status in ('pending', 'pending_second_review', 'approved');

  if v_active_links >= 2 then
    raise exception 'parent_quota_reached';
  end if;

  select * into v_user from users where email = v_otp.sent_to_email;

  if not found then
    insert into users (
      school_id, email, password_hash, first_name, last_name, created_by
    )
    values (
      v_binding.school_id,
      v_otp.sent_to_email,
      crypt(p_password, gen_salt('bf')),
      trim(p_first_name),
      trim(p_last_name),
      v_binding.issued_by
    )
    returning * into v_user;
  elsif v_user.password_hash is null
     or v_user.password_hash <> crypt(p_password, v_user.password_hash) then
    raise exception 'invalid_credentials';
  end if;

  if exists (
    select 1 from parent_links pl
    where pl.student_id = v_binding.student_id
      and pl.parent_id = v_user.id
  ) then
    raise exception 'already_linked';
  end if;

  insert into parent_links (
    student_id, parent_id, relationship, binding_code_id, status
  )
  values (
    v_binding.student_id,
    v_user.id,
    trim(p_relationship),
    v_binding.id,
    'pending'
  )
  returning id into v_link_id;

  update parent_binding_codes
  set status = 'redeemed', redeemed_by = v_user.id, redeemed_at = now()
  where id = v_binding.id;

  update otp_codes set used_at = now() where id = v_otp.id;

  update otp_codes set used_at = now()
  where parent_binding_code_id = v_binding.id
    and id <> v_otp.id
    and used_at is null;

  insert into audit_logs (
    school_id, user_id, acted_role, action, entity_type, entity_id
  )
  values (
    v_binding.school_id,
    v_user.id,
    'parent',
    'parent.redeem_binding_code',
    'parent_links',
    v_link_id::text
  );

  return query select v_link_id, 'pending'::binding_status;
end;
$$;

revoke all on function confirm_parent_binding(text, text, text, text, text, text)
  from public;
grant execute on function confirm_parent_binding(text, text, text, text, text, text)
  to anon, authenticated;

-- Disable the legacy flow that created a parent account without email OTP.
revoke all on function redeem_parent_binding_code(text, text, text, text, text, text)
  from public, anon, authenticated;

-- ---------------------------------------------------------------------
-- Parent-link approval and the explicitly-audited small-school CoI path.
-- ---------------------------------------------------------------------
create or replace function approve_parent_link(
  p_token text,
  p_parent_link_id uuid
)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_link parent_links%rowtype;
  v_school_id uuid;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('school_admin', 'teacher', 'super_admin') then
    raise exception 'forbidden';
  end if;

  select * into v_link from parent_links
  where id = p_parent_link_id
  for update;
  if not found then raise exception 'link_not_found'; end if;
  if v_link.status <> 'pending' then raise exception 'link_not_pending'; end if;

  select school_id into v_school_id from users where id = v_link.student_id;
  if v_actor.role <> 'super_admin'
     and v_actor.school_id is distinct from v_school_id then
    raise exception 'forbidden';
  end if;

  if v_actor.role = 'teacher' and not exists (
    select 1
    from course_teachers ct
    join course_students cs on cs.course_id = ct.course_id
    where ct.teacher_id = v_actor.user_id
      and cs.student_id = v_link.student_id
  ) then
    raise exception 'forbidden';
  end if;

  if v_actor.user_id = v_link.parent_id then
    raise exception 'coi_self_approval_blocked';
  end if;

  update parent_links
  set status = 'approved',
      approved_by = v_actor.user_id,
      approved_at = now(),
      first_reviewed_by = v_actor.user_id,
      first_reviewed_at = now(),
      coi_conflict = false
  where id = p_parent_link_id;

  insert into user_roles (user_id, role, school_id, granted_by)
  values (v_link.parent_id, 'parent', v_school_id, v_actor.user_id)
  on conflict (user_id, role, school_id) do nothing;

  insert into audit_logs (
    school_id, user_id, acted_role, action, entity_type, entity_id
  )
  values (
    v_school_id, v_actor.user_id, v_actor.role,
    'parent_link.approve', 'parent_links', p_parent_link_id::text
  );
end;
$$;

create or replace function request_parent_link_second_review(
  p_token text,
  p_parent_link_id uuid,
  p_exception_reason text
)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_link parent_links%rowtype;
  v_school_id uuid;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role <> 'school_admin' then raise exception 'forbidden'; end if;
  if nullif(trim(p_exception_reason), '') is null then
    raise exception 'exception_reason_required';
  end if;

  select * into v_link from parent_links
  where id = p_parent_link_id
  for update;
  if not found then raise exception 'link_not_found'; end if;
  if v_link.status <> 'pending' then raise exception 'link_not_pending'; end if;

  select school_id into v_school_id from users where id = v_link.student_id;
  if v_actor.school_id is distinct from v_school_id then
    raise exception 'forbidden';
  end if;
  if v_actor.user_id <> v_link.parent_id then
    raise exception 'exception_only_for_self_approval_coi';
  end if;

  update parent_links
  set status = 'pending_second_review',
      coi_conflict = true,
      exception_reason = trim(p_exception_reason),
      first_reviewed_by = v_actor.user_id,
      first_reviewed_at = now()
  where id = p_parent_link_id;

  insert into audit_logs (
    school_id, user_id, acted_role, action, entity_type, entity_id, details
  )
  values (
    v_school_id, v_actor.user_id, v_actor.role,
    'parent_link.request_second_review', 'parent_links',
    p_parent_link_id::text,
    jsonb_build_object('reason', trim(p_exception_reason), 'sla_hours', 24)
  );
end;
$$;

create or replace function second_approve_parent_link(
  p_token text,
  p_parent_link_id uuid
)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_link parent_links%rowtype;
  v_school_id uuid;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role <> 'school_admin' then raise exception 'forbidden'; end if;

  select * into v_link from parent_links
  where id = p_parent_link_id
  for update;
  if not found then raise exception 'link_not_found'; end if;
  if v_link.status <> 'pending_second_review' then
    raise exception 'second_review_not_pending';
  end if;
  if v_link.first_reviewed_by = v_actor.user_id then
    raise exception 'second_reviewer_must_be_different';
  end if;
  if v_actor.user_id = v_link.parent_id then
    raise exception 'coi_self_approval_blocked';
  end if;

  select school_id into v_school_id from users where id = v_link.student_id;
  if v_actor.school_id is distinct from v_school_id then
    raise exception 'forbidden';
  end if;

  update parent_links
  set status = 'approved',
      approved_by = v_actor.user_id,
      approved_at = now(),
      second_approved_by = v_actor.user_id,
      second_approved_at = now()
  where id = p_parent_link_id;

  insert into user_roles (user_id, role, school_id, granted_by)
  values (v_link.parent_id, 'parent', v_school_id, v_actor.user_id)
  on conflict (user_id, role, school_id) do nothing;

  insert into audit_logs (
    school_id, user_id, acted_role, action, entity_type, entity_id, details
  )
  values (
    v_school_id, v_actor.user_id, v_actor.role,
    'parent_link.second_approve', 'parent_links', p_parent_link_id::text,
    jsonb_build_object(
      'first_reviewer', v_link.first_reviewed_by,
      'elapsed_seconds', extract(epoch from (now() - v_link.first_reviewed_at))
    )
  );
end;
$$;

create or replace function reject_parent_link(
  p_token text,
  p_parent_link_id uuid,
  p_reason text default null
)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_link parent_links%rowtype;
  v_school_id uuid;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('school_admin', 'teacher', 'super_admin') then
    raise exception 'forbidden';
  end if;
  if nullif(trim(p_reason), '') is null then
    raise exception 'rejection_reason_required';
  end if;

  select * into v_link from parent_links
  where id = p_parent_link_id
  for update;
  if not found then raise exception 'link_not_found'; end if;
  if v_link.status not in ('pending', 'pending_second_review') then
    raise exception 'link_not_pending';
  end if;

  select school_id into v_school_id from users where id = v_link.student_id;
  if v_actor.role <> 'super_admin'
     and v_actor.school_id is distinct from v_school_id then
    raise exception 'forbidden';
  end if;
  if v_link.status = 'pending_second_review'
     and v_actor.role <> 'school_admin' then
    raise exception 'forbidden';
  end if;
  if v_actor.role = 'teacher' and not exists (
    select 1
    from course_teachers ct
    join course_students cs on cs.course_id = ct.course_id
    where ct.teacher_id = v_actor.user_id
      and cs.student_id = v_link.student_id
  ) then
    raise exception 'forbidden';
  end if;

  update parent_links
  set status = 'rejected',
      rejected_by = v_actor.user_id,
      rejected_at = now(),
      rejection_reason = trim(p_reason),
      first_reviewed_by = coalesce(first_reviewed_by, v_actor.user_id),
      first_reviewed_at = coalesce(first_reviewed_at, now())
  where id = p_parent_link_id;

  insert into audit_logs (
    school_id, user_id, acted_role, action, entity_type, entity_id, details
  )
  values (
    v_school_id, v_actor.user_id, v_actor.role,
    'parent_link.reject', 'parent_links', p_parent_link_id::text,
    jsonb_build_object(
      'reason', trim(p_reason),
      'previous_status', v_link.status
    )
  );
end;
$$;

revoke all on function approve_parent_link(text, uuid) from public;
revoke all on function request_parent_link_second_review(text, uuid, text) from public;
revoke all on function second_approve_parent_link(text, uuid) from public;
revoke all on function reject_parent_link(text, uuid, text) from public;
grant execute on function approve_parent_link(text, uuid) to anon, authenticated;
grant execute on function request_parent_link_second_review(text, uuid, text)
  to anon, authenticated;
grant execute on function second_approve_parent_link(text, uuid)
  to anon, authenticated;
grant execute on function reject_parent_link(text, uuid, text)
  to anon, authenticated;

-- ---------------------------------------------------------------------
-- Consent history. Current state lives in consents; every transition is
-- appended to consent_events and audit_logs with the exact policy version.
-- ---------------------------------------------------------------------
alter table consent_policies
  add column if not exists is_required boolean not null default false;

create or replace function list_consent_policies_admin(
  p_token text,
  p_school_id uuid default null
)
returns table (
  policy_id uuid,
  school_id uuid,
  consent_type varchar,
  version varchar,
  document_hash varchar,
  content_url varchar,
  is_required boolean,
  effective_at timestamptz,
  retired_at timestamptz
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_school_id uuid;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('school_admin', 'super_admin') then
    raise exception 'forbidden';
  end if;

  v_school_id := case
    when v_actor.role = 'super_admin' then p_school_id
    else v_actor.school_id
  end;
  if v_school_id is null then raise exception 'school_required'; end if;
  if v_actor.role <> 'super_admin'
     and p_school_id is not null
     and p_school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;

  return query
  select cp.id, cp.school_id, cp.consent_type, cp.version,
         cp.document_hash, cp.content_url, cp.is_required,
         cp.effective_at, cp.retired_at
  from consent_policies cp
  where cp.school_id = v_school_id
  order by cp.consent_type, cp.effective_at desc;
end;
$$;

create or replace function publish_consent_policy(
  p_token text,
  p_consent_type text,
  p_version text,
  p_document_hash text,
  p_content_url text,
  p_is_required boolean default false,
  p_effective_at timestamptz default now(),
  p_school_id uuid default null
)
returns uuid
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_school_id uuid;
  v_policy_id uuid;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('school_admin', 'super_admin') then
    raise exception 'forbidden';
  end if;

  v_school_id := case
    when v_actor.role = 'super_admin' then p_school_id
    else v_actor.school_id
  end;
  if v_school_id is null then raise exception 'school_required'; end if;
  if v_actor.role <> 'super_admin'
     and p_school_id is not null
     and p_school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;
  if nullif(trim(p_consent_type), '') is null
     or length(trim(p_consent_type)) > 100 then
    raise exception 'invalid_consent_type';
  end if;
  if nullif(trim(p_version), '') is null or length(trim(p_version)) > 50 then
    raise exception 'invalid_policy_version';
  end if;
  if lower(trim(p_document_hash)) !~ '^[0-9a-f]{64}$' then
    raise exception 'invalid_document_hash';
  end if;
  if trim(p_content_url) !~* '^https://[^[:space:]]+$'
     or length(trim(p_content_url)) > 2048 then
    raise exception 'invalid_content_url';
  end if;

  insert into consent_policies (
    school_id, consent_type, version, document_hash, content_url,
    is_required, effective_at, created_by
  ) values (
    v_school_id, trim(p_consent_type), trim(p_version),
    lower(trim(p_document_hash)), trim(p_content_url),
    coalesce(p_is_required, false), coalesce(p_effective_at, now()),
    v_actor.user_id
  )
  returning id into v_policy_id;

  insert into audit_logs (
    school_id, user_id, acted_role, action, entity_type, entity_id, details
  ) values (
    v_school_id, v_actor.user_id, v_actor.role,
    'consent_policy.publish', 'consent_policies', v_policy_id::text,
    jsonb_build_object(
      'consent_type', trim(p_consent_type),
      'version', trim(p_version),
      'document_hash', lower(trim(p_document_hash)),
      'is_required', coalesce(p_is_required, false),
      'effective_at', coalesce(p_effective_at, now())
    )
  );
  return v_policy_id;
exception when unique_violation then
  raise exception 'policy_version_already_exists';
end;
$$;

create or replace function retire_consent_policy(
  p_token text,
  p_policy_id uuid
)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_policy consent_policies%rowtype;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('school_admin', 'super_admin') then
    raise exception 'forbidden';
  end if;

  select * into v_policy
  from consent_policies
  where id = p_policy_id
  for update;
  if not found then raise exception 'policy_not_found'; end if;
  if v_actor.role <> 'super_admin'
     and v_actor.school_id is distinct from v_policy.school_id then
    raise exception 'forbidden';
  end if;
  if v_policy.retired_at is not null then raise exception 'policy_retired'; end if;

  update consent_policies set retired_at = now() where id = p_policy_id;
  insert into audit_logs (
    school_id, user_id, acted_role, action, entity_type, entity_id, details
  ) values (
    v_policy.school_id, v_actor.user_id, v_actor.role,
    'consent_policy.retire', 'consent_policies', p_policy_id::text,
    jsonb_build_object(
      'consent_type', v_policy.consent_type,
      'version', v_policy.version,
      'document_hash', v_policy.document_hash
    )
  );
end;
$$;

revoke all on function list_consent_policies_admin(text, uuid) from public;
revoke all on function publish_consent_policy(
  text, text, text, text, text, boolean, timestamptz, uuid
) from public;
revoke all on function retire_consent_policy(text, uuid) from public;
grant execute on function list_consent_policies_admin(text, uuid)
  to anon, authenticated;
grant execute on function publish_consent_policy(
  text, text, text, text, text, boolean, timestamptz, uuid
) to anon, authenticated;
grant execute on function retire_consent_policy(text, uuid)
  to anon, authenticated;

create or replace function list_active_consent_policies(p_token text)
returns table (
  policy_id uuid,
  consent_type varchar,
  version varchar,
  document_hash varchar,
  content_url varchar,
  effective_at timestamptz
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role <> 'parent' then raise exception 'forbidden'; end if;

  return query
  select cp.id, cp.consent_type, cp.version, cp.document_hash,
         cp.content_url, cp.effective_at
  from consent_policies cp
  where (cp.school_id is null or cp.school_id = v_actor.school_id)
    and cp.effective_at <= now()
    and (cp.retired_at is null or cp.retired_at > now())
  order by cp.consent_type, cp.effective_at desc;
end;
$$;

create or replace function grant_parent_consent(
  p_token text,
  p_parent_link_id uuid,
  p_policy_id uuid,
  p_evidence jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_link parent_links%rowtype;
  v_policy consent_policies%rowtype;
  v_consent_id uuid;
  v_evidence jsonb;
  v_evidence_hash text;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role <> 'parent' then raise exception 'forbidden'; end if;

  select pl.* into v_link
  from parent_links pl
  join users student on student.id = pl.student_id
  where pl.id = p_parent_link_id
    and pl.parent_id = v_actor.user_id
    and pl.status = 'approved'
    and student.school_id = v_actor.school_id;
  if not found then raise exception 'approved_parent_link_required'; end if;

  select * into v_policy from consent_policies
  where id = p_policy_id
    and (school_id is null or school_id = v_actor.school_id)
    and effective_at <= now()
    and (retired_at is null or retired_at > now());
  if not found then raise exception 'active_policy_required'; end if;

  if coalesce((p_evidence->>'confirmed_read')::boolean, false) is not true then
    raise exception 'policy_read_confirmation_required';
  end if;

  v_evidence := coalesce(p_evidence, '{}'::jsonb) || jsonb_build_object(
    'policy_version', v_policy.version,
    'policy_document_hash', v_policy.document_hash,
    'actor_id', v_actor.user_id,
    'recorded_at', now()
  );
  v_evidence_hash := encode(digest(v_evidence::text, 'sha256'), 'hex');

  insert into consents (
    parent_link_id, policy_id, status, granted_by, granted_at,
    withdrawn_at, evidence_hash, details
  )
  values (
    v_link.id, v_policy.id, 'granted', v_actor.user_id, now(),
    null, v_evidence_hash, v_evidence
  )
  on conflict (parent_link_id, policy_id) do update
  set status = 'granted',
      granted_by = excluded.granted_by,
      granted_at = excluded.granted_at,
      withdrawn_at = null,
      evidence_hash = excluded.evidence_hash,
      details = excluded.details
  returning id into v_consent_id;

  insert into consent_events (
    consent_id, policy_id, actor_id, action, evidence
  )
  values (
    v_consent_id, v_policy.id, v_actor.user_id, 'granted',
    v_evidence || jsonb_build_object('evidence_hash', v_evidence_hash)
  );

  insert into audit_logs (
    school_id, user_id, acted_role, action, entity_type, entity_id, details
  )
  values (
    v_actor.school_id, v_actor.user_id, v_actor.role,
    'consent.grant', 'consents', v_consent_id::text,
    jsonb_build_object(
      'policy_id', v_policy.id,
      'policy_version', v_policy.version,
      'evidence_hash', v_evidence_hash
    )
  );

  return v_consent_id;
end;
$$;

create or replace function withdraw_parent_consent(
  p_token text,
  p_consent_id uuid,
  p_reason text default null
)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_consent consents%rowtype;
  v_evidence jsonb;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role <> 'parent' then raise exception 'forbidden'; end if;

  select c.* into v_consent
  from consents c
  join parent_links pl on pl.id = c.parent_link_id
  join users student on student.id = pl.student_id
  where c.id = p_consent_id
    and pl.parent_id = v_actor.user_id
    and student.school_id = v_actor.school_id
    and c.status = 'granted'
  for update of c;
  if not found then raise exception 'active_consent_not_found'; end if;

  v_evidence := jsonb_build_object(
    'reason', nullif(trim(p_reason), ''),
    'actor_id', v_actor.user_id,
    'recorded_at', now(),
    'previous_evidence_hash', v_consent.evidence_hash
  );

  update consents
  set status = 'withdrawn', withdrawn_at = now()
  where id = v_consent.id;

  insert into consent_events (
    consent_id, policy_id, actor_id, action, evidence
  )
  values (
    v_consent.id, v_consent.policy_id, v_actor.user_id,
    'withdrawn', v_evidence
  );

  insert into audit_logs (
    school_id, user_id, acted_role, action, entity_type, entity_id, details
  )
  values (
    v_actor.school_id, v_actor.user_id, v_actor.role,
    'consent.withdraw', 'consents', v_consent.id::text,
    jsonb_build_object('policy_id', v_consent.policy_id)
  );
end;
$$;

revoke all on function list_active_consent_policies(text) from public;
revoke all on function grant_parent_consent(text, uuid, uuid, jsonb) from public;
revoke all on function withdraw_parent_consent(text, uuid, text) from public;
grant execute on function list_active_consent_policies(text) to anon, authenticated;
grant execute on function grant_parent_consent(text, uuid, uuid, jsonb)
  to anon, authenticated;
grant execute on function withdraw_parent_consent(text, uuid, text)
  to anon, authenticated;

create or replace function list_my_parent_links(p_token text)
returns table (
  parent_link_id uuid,
  student_id uuid,
  student_first_name varchar,
  student_last_name varchar,
  relationship varchar,
  status binding_status
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role <> 'parent' then raise exception 'forbidden'; end if;

  return query
  select pl.id, pl.student_id, u.first_name, u.last_name,
         pl.relationship, pl.status
  from parent_links pl
  join users u on u.id = pl.student_id
  where pl.parent_id = v_actor.user_id
    and u.school_id = v_actor.school_id
  order by u.first_name, u.last_name;
end;
$$;

create or replace function list_my_consents(
  p_token text,
  p_parent_link_id uuid
)
returns table (
  consent_id uuid,
  policy_id uuid,
  consent_type varchar,
  version varchar,
  document_hash varchar,
  content_url varchar,
  is_required boolean,
  status consent_status,
  granted_at timestamptz,
  withdrawn_at timestamptz
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role <> 'parent' then raise exception 'forbidden'; end if;
  if not exists (
    select 1
    from parent_links pl
    join users student on student.id = pl.student_id
    where pl.id = p_parent_link_id
      and pl.parent_id = v_actor.user_id
      and student.school_id = v_actor.school_id
  ) then
    raise exception 'forbidden';
  end if;

  return query
  select c.id, cp.id, cp.consent_type, cp.version,
         cp.document_hash, cp.content_url, cp.is_required, c.status,
         c.granted_at, c.withdrawn_at
  from consent_policies cp
  left join consents c
    on c.policy_id = cp.id
   and c.parent_link_id = p_parent_link_id
  where (cp.school_id is null or cp.school_id = v_actor.school_id)
    and cp.effective_at <= now()
    and (cp.retired_at is null or cp.retired_at > now())
  order by cp.consent_type, cp.effective_at desc;
end;
$$;

revoke all on function list_my_parent_links(text) from public;
revoke all on function list_my_consents(text, uuid) from public;
grant execute on function list_my_parent_links(text) to anon, authenticated;
grant execute on function list_my_consents(text, uuid) to anon, authenticated;

-- ---------------------------------------------------------------------
-- AIoT read scope: current school values for students; building summaries
-- for Facility Manager; raw history only for roles/datasets that allow it.
-- ---------------------------------------------------------------------
create or replace function sensor_latest(
  p_token text,
  p_device_id uuid default null
)
returns table (
  device_id uuid,
  device_name varchar,
  location varchar,
  metric metric_type,
  ts timestamptz,
  value numeric
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;

  if v_actor.role = 'facility_manager' then
    if p_device_id is not null then raise exception 'summary_only'; end if;
    return query
    select
      null::uuid,
      (coalesce(d.location, 'ไม่ระบุอาคาร') || ' summary')::varchar,
      coalesce(d.location, 'ไม่ระบุอาคาร')::varchar,
      r.metric,
      max(r.ts),
      round(avg(r.value), 4)
    from devices d
    join sensor_readings r on r.device_id = d.id
    where d.school_id = v_actor.school_id
      and r.ts >= now() - interval '15 minutes'
    group by d.location, r.metric
    order by d.location, r.metric;
    return;
  end if;

  if v_actor.role not in (
    'school_admin', 'teacher', 'executive', 'student', 'technician'
  ) then
    raise exception 'forbidden';
  end if;

  return query
  select distinct on (d.id, r.metric)
    d.id, d.name, d.location, r.metric, r.ts, r.value
  from devices d
  join sensor_readings r on r.device_id = d.id
  where d.school_id = v_actor.school_id
    and (p_device_id is null or d.id = p_device_id)
  order by d.id, r.metric, r.ts desc;
end;
$$;

create or replace function sensor_history(
  p_token text,
  p_device_id uuid,
  p_metric metric_type,
  p_from timestamptz,
  p_to timestamptz default null
)
returns table (ts timestamptz, value numeric)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_device devices%rowtype;
  v_to timestamptz := coalesce(p_to, now());
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if p_from >= v_to then raise exception 'invalid_time_range'; end if;

  select * into v_device from devices where id = p_device_id;
  if not found then raise exception 'device_not_found'; end if;
  if v_device.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;

  if v_actor.role = 'student' then
    if not exists (
      select 1
      from course_students cs
      join lessons l on l.course_id = cs.course_id and l.status = 'published'
      join lesson_sensor_links lsl on lsl.lesson_id = l.id
      where cs.student_id = v_actor.user_id
        and lsl.device_id = p_device_id
        and lsl.metric = p_metric
        and p_from >= coalesce(lsl.time_start, p_from)
        and v_to <= coalesce(lsl.time_end, v_to)
      union all
      select 1
      from course_students cs
      join assignments a on a.course_id = cs.course_id
      join assignment_sensor_datasets asd on asd.assignment_id = a.id
      where cs.student_id = v_actor.user_id
        and asd.device_id = p_device_id
        and asd.metric = p_metric
        and p_from >= coalesce(asd.time_start, p_from)
        and v_to <= coalesce(asd.time_end, v_to)
    ) then
      raise exception 'learning_dataset_required';
    end if;
  elsif v_actor.role not in (
    'school_admin', 'teacher', 'executive', 'technician'
  ) then
    raise exception 'forbidden';
  end if;

  return query
  select r.ts, r.value
  from sensor_readings r
  where r.device_id = p_device_id
    and r.metric = p_metric
    and r.ts >= p_from
    and r.ts <= v_to
  order by r.ts
  limit 10000;
end;
$$;

revoke all on function sensor_latest(text, uuid) from public;
revoke all on function sensor_history(text, uuid, metric_type, timestamptz, timestamptz)
  from public;
grant execute on function sensor_latest(text, uuid) to anon, authenticated;
grant execute on function sensor_history(text, uuid, metric_type, timestamptz, timestamptz)
  to anon, authenticated;

-- ---------------------------------------------------------------------
-- Signed Gateway ingest. The gateway never sends its device token. It uses
-- SHA-256(device_token) as the HMAC key; that value is already stored as
-- devices.token_hash. Timestamp and per-device nonce prevent replay.
-- ---------------------------------------------------------------------
alter table devices
  add column if not exists token_issued_at timestamptz;

update devices
set token_issued_at = coalesce(token_issued_at, registered_at)
where token_hash is not null;

create table if not exists gateway_request_nonces (
  gateway_id uuid not null references devices(id),
  nonce varchar not null,
  used_at timestamptz not null default now(),
  primary key (gateway_id, nonce)
);

alter table gateway_request_nonces enable row level security;

create or replace function verify_gateway_request(
  p_gateway_id uuid,
  p_timestamp bigint,
  p_nonce text,
  p_signature text,
  p_method text,
  p_path text,
  p_body_hash text
)
returns boolean
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_device devices%rowtype;
  v_expected_signature text;
  v_signed_text text;
begin
  if abs(extract(epoch from now())::bigint - p_timestamp) > 300 then
    raise exception 'gateway_timestamp_out_of_range';
  end if;
  if p_nonce !~ '^[A-Za-z0-9_-]{16,128}$' then
    raise exception 'invalid_gateway_nonce';
  end if;
  if lower(p_body_hash) !~ '^[0-9a-f]{64}$'
     or lower(p_signature) !~ '^[0-9a-f]{64}$' then
    raise exception 'invalid_gateway_signature';
  end if;

  select * into v_device
  from devices
  where id = p_gateway_id
    and token_hash is not null
    and status <> 'error';
  if not found then raise exception 'invalid_gateway'; end if;

  v_signed_text := upper(trim(p_method)) || E'\n'
    || trim(p_path) || E'\n'
    || p_timestamp::text || E'\n'
    || p_nonce || E'\n'
    || lower(p_body_hash);
  v_expected_signature := encode(
    hmac(v_signed_text, v_device.token_hash, 'sha256'),
    'hex'
  );

  if v_expected_signature <> lower(p_signature) then
    raise exception 'invalid_gateway_signature';
  end if;

  begin
    insert into gateway_request_nonces (gateway_id, nonce)
    values (p_gateway_id, p_nonce);
  exception when unique_violation then
    raise exception 'gateway_replay_detected';
  end;

  return true;
end;
$$;

create or replace function ingest_sensor_readings_verified(
  p_gateway_id uuid,
  p_readings jsonb
)
returns integer
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_reading jsonb;
  v_metric metric_type;
  v_value numeric;
  v_ts timestamptz;
  v_inserted integer := 0;
begin
  if not exists (
    select 1 from gateway_request_nonces
    where gateway_id = p_gateway_id
      and used_at >= now() - interval '5 minutes'
  ) then
    raise exception 'verified_gateway_request_required';
  end if;
  if p_readings is null or jsonb_typeof(p_readings) <> 'array' then
    raise exception 'readings_must_be_array';
  end if;
  if jsonb_array_length(p_readings) > 500 then
    raise exception 'batch_too_large';
  end if;

  for v_reading in select * from jsonb_array_elements(p_readings)
  loop
    begin
      v_metric := (v_reading->>'metric')::metric_type;
      v_value := (v_reading->>'value')::numeric;
      v_ts := coalesce((v_reading->>'ts')::timestamptz, now());
    exception when others then
      raise exception 'invalid_sensor_reading';
    end;
    if v_value is null then raise exception 'invalid_sensor_reading'; end if;

    insert into sensor_readings (device_id, metric, ts, value)
    values (p_gateway_id, v_metric, v_ts, v_value)
    on conflict (device_id, metric, ts) do nothing;
    if found then v_inserted := v_inserted + 1; end if;
  end loop;

  update devices set status = 'online' where id = p_gateway_id;
  insert into device_heartbeats (device_id, status, details)
  values (
    p_gateway_id,
    'online',
    jsonb_build_object('readings', jsonb_array_length(p_readings), 'auth', 'hmac')
  );
  return v_inserted;
end;
$$;

-- The legacy bearer-token ingest path is intentionally disabled.
revoke all on function sensor_ingest(text, jsonb)
  from public, anon, authenticated;
revoke all on function verify_gateway_request(uuid, bigint, text, text, text, text, text)
  from public, anon, authenticated;
revoke all on function ingest_sensor_readings_verified(uuid, jsonb)
  from public, anon, authenticated;
grant execute on function verify_gateway_request(uuid, bigint, text, text, text, text, text)
  to service_role;
grant execute on function ingest_sensor_readings_verified(uuid, jsonb)
  to service_role;

create index if not exists idx_gateway_request_nonces_used_at
  on gateway_request_nonces (used_at);

create or replace function set_device_token_issued_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if tg_op = 'INSERT' or new.token_hash is distinct from old.token_hash then
    new.token_issued_at := now();
  end if;
  return new;
end;
$$;

drop trigger if exists trg_device_token_issued_at on devices;
create trigger trg_device_token_issued_at
before update of token_hash on devices
for each row execute function set_device_token_issued_at();

drop trigger if exists trg_device_token_issued_at_insert on devices;
create trigger trg_device_token_issued_at_insert
before insert on devices
for each row execute function set_device_token_issued_at();

revoke all on function set_device_token_issued_at() from public, anon, authenticated;

-- RPC-only client model: direct Data API table access stays revoked even if a
-- future RLS policy is added accidentally. SECURITY DEFINER RPCs are reviewed
-- and allow-listed separately.
do $$
declare
  v_table record;
begin
  for v_table in
    select schemaname, tablename
    from pg_tables
    where schemaname = 'public'
  loop
    execute format(
      'alter table %I.%I enable row level security',
      v_table.schemaname,
      v_table.tablename
    );
  end loop;
end;
$$;

revoke all on all tables in schema public from public, anon, authenticated;
revoke all on all sequences in schema public from public, anon, authenticated;

-- Defense in depth for every SECURITY DEFINER function created by all prior
-- migrations. Explicit grants to anon/authenticated/service_role remain; the
-- implicit PostgreSQL PUBLIC execute privilege is removed universally.
do $$
declare
  v_function record;
begin
  for v_function in
    select
      n.nspname as schema_name,
      p.proname as function_name,
      pg_get_function_identity_arguments(p.oid) as identity_arguments
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.prosecdef
  loop
    execute format(
      'revoke execute on function %I.%I(%s) from public',
      v_function.schema_name,
      v_function.function_name,
      v_function.identity_arguments
    );
  end loop;
end;
$$;
