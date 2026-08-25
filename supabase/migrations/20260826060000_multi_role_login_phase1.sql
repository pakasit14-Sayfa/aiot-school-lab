-- =====================================================================
-- Migration: Multi-Role Accounts — Phase 1 (Data Model & Auth Core)
-- Supports users having multiple roles across schools and picking role
-- at login.
-- =====================================================================

-- 1. Table for short-lived role selection challenges (5 minutes expiry)
create table if not exists role_selection_challenges (
  token_hash text primary key,
  user_id uuid not null references users(id) on delete cascade,
  expires_at timestamptz not null default (now() + interval '5 minutes'),
  used_at timestamptz,
  created_at timestamptz not null default now()
);

alter table role_selection_challenges enable row level security;

-- 2. add_secondary_role RPC (adds an additional role row without deleting existing ones)
create or replace function public.add_secondary_role(
  p_token text,
  p_target_user_id uuid,
  p_role role_type,
  p_school_id uuid default null
)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_target users%rowtype;
  v_school_id uuid;
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

    if p_role = 'super_admin'
       or exists (
         select 1 from user_roles
         where user_id = p_target_user_id and role = 'super_admin'
       ) then
      raise exception 'forbidden_role_grant';
    end if;
  end if;

  -- Resolve school_id for the role
  if p_role = 'super_admin' then
    v_school_id := null;
  else
    v_school_id := coalesce(p_school_id, v_target.school_id, v_actor.school_id);
  end if;

  -- Prevent duplicate role assignment in the same school
  if exists (
    select 1 from user_roles
    where user_id = p_target_user_id
      and role = p_role
      and school_id is not distinct from v_school_id
  ) then
    raise exception 'role_already_granted';
  end if;

  -- Insert new role row WITHOUT deleting existing ones
  insert into user_roles (user_id, role, school_id, granted_by, granted_at)
  values (p_target_user_id, p_role, v_school_id, v_actor.user_id, now());

  -- Revoke active sessions to require fresh login/selection
  update sessions
  set revoked_at = now()
  where user_id = p_target_user_id and revoked_at is null;

  insert into audit_logs (
    school_id, user_id, acted_role, action, entity_type, entity_id, details
  )
  values (
    v_actor.school_id,
    v_actor.user_id,
    v_actor.role,
    'user.add_role',
    'users',
    p_target_user_id::text,
    jsonb_build_object('added_role', p_role, 'school_id', v_school_id)
  );
end;
$$;

revoke all on function public.add_secondary_role(text, uuid, role_type, uuid) from public;
grant execute on function public.add_secondary_role(text, uuid, role_type, uuid) to anon, authenticated;
