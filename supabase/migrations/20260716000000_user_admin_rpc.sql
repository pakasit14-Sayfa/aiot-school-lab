-- =====================================================================
-- User admin RPC functions: update_user_profile, update_user_role,
-- suspend_user
--
-- Same reasoning as auth_rpc.sql — RLS is deny-all, so profile/role/
-- suspension changes can only happen through these SECURITY DEFINER
-- functions. Each call is authorized against the caller's session
-- token (anon key carries no identity of its own).
--
-- get_session_actor is an internal helper (not granted to anon/
-- authenticated) — SECURITY DEFINER functions can still call it since
-- they run with the owner's privileges, but PostgREST clients cannot
-- invoke it directly.
--
-- user_status only has 'active'/'suspended' (no hard delete), so
-- suspend_user is what AuthService.deleteUser calls underneath.
-- =====================================================================

create or replace function get_session_actor(p_token text)
returns table (
  user_id uuid,
  role role_type,
  school_id uuid
)
language plpgsql
security definer
set search_path = public, extensions
as $$
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
$$;

create or replace function update_user_profile(
  p_token text,
  p_target_user_id uuid,
  p_first_name text,
  p_last_name text
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

  select * into v_target from users where id = p_target_user_id;
  if not found then
    raise exception 'user_not_found';
  end if;

  if v_actor.user_id <> p_target_user_id
     and not (
       v_actor.role in ('school_admin', 'super_admin')
       and (v_actor.role = 'super_admin' or v_actor.school_id = v_target.school_id)
     ) then
    raise exception 'forbidden';
  end if;

  update users
    set first_name = p_first_name, last_name = p_last_name
    where id = p_target_user_id;

  insert into audit_logs (school_id, user_id, acted_role, action, entity_type, entity_id)
  values (v_actor.school_id, v_actor.user_id, v_actor.role, 'user.update_profile', 'users', p_target_user_id::text);
end;
$$;

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

  if v_actor.role = 'school_admin' and v_actor.school_id is distinct from v_target.school_id then
    raise exception 'forbidden';
  end if;

  delete from user_roles where user_id = p_target_user_id;

  insert into user_roles (user_id, role, school_id, granted_by)
  values (p_target_user_id, p_new_role, v_target.school_id, v_actor.user_id);

  update sessions set revoked_at = now()
    where user_id = p_target_user_id and revoked_at is null;

  insert into audit_logs (school_id, user_id, acted_role, action, entity_type, entity_id, details)
  values (v_actor.school_id, v_actor.user_id, v_actor.role, 'user.update_role', 'users', p_target_user_id::text,
          jsonb_build_object('new_role', p_new_role));
end;
$$;

create or replace function suspend_user(
  p_token text,
  p_target_user_id uuid
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
    raise exception 'cannot_suspend_self';
  end if;

  select * into v_target from users where id = p_target_user_id;
  if not found then
    raise exception 'user_not_found';
  end if;

  if v_actor.role = 'school_admin' and v_actor.school_id is distinct from v_target.school_id then
    raise exception 'forbidden';
  end if;

  update users set status = 'suspended' where id = p_target_user_id;

  update sessions set revoked_at = now()
    where user_id = p_target_user_id and revoked_at is null;

  insert into audit_logs (school_id, user_id, acted_role, action, entity_type, entity_id)
  values (v_actor.school_id, v_actor.user_id, v_actor.role, 'user.suspend', 'users', p_target_user_id::text);
end;
$$;

grant execute on function update_user_profile(text, uuid, text, text) to anon, authenticated;
grant execute on function update_user_role(text, uuid, role_type) to anon, authenticated;
grant execute on function suspend_user(text, uuid) to anon, authenticated;
