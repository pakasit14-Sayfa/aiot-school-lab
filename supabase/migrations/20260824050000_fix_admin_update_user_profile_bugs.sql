-- admin_update_user_profile (20260824040000_admin_update_user_profile.sql)
-- had two real bugs, found while independently re-verifying the "fixed
-- permissions_page.dart, works securely" report.
--
-- 1. BROKEN FOR EVERYONE, not just an edge case: it does
--    `update public.users set ... updated_at = now() ...` but
--    public.users has no updated_at column at all. Confirmed live: even a
--    legitimate super_admin name-edit call fails with
--    "column \"updated_at\" of relation \"users\" does not exist". The
--    "works securely 100%" claim was untested against a real call —
--    running the pgTAP suite / flutter test doesn't exercise this RPC at
--    all, so it stayed broken through both.
--
-- 2. Privilege escalation, currently masked by bug #1: p_role accepts any
--    role_type value including 'super_admin', and the authorization check
--    only verifies WHO can call the function (is_super_admin() OR
--    school_admin-in-own-school), never WHAT role they're allowed to
--    assign. A school_admin calling this with p_role='super_admin' against
--    their own account would self-promote — confirmed the call reaches
--    that far (it only failed on the users.updated_at bug, not an
--    authorization check). The moment someone fixes bug #1 without also
--    fixing this, the escalation goes live immediately.

create or replace function public.admin_update_user_profile(
  p_user_id uuid,
  p_first_name text,
  p_last_name text,
  p_role text default null,
  p_school_id uuid default null
)
returns jsonb as $$
declare
  v_role_type public.role_type;
  v_target_school_id uuid;
  v_caller_is_super_admin boolean;
begin
  if auth.uid() is null then
    raise exception 'invalid_session';
  end if;

  select school_id into v_target_school_id
  from public.users
  where id = p_user_id;

  if not found then
    raise exception 'user_not_found';
  end if;

  v_caller_is_super_admin := public.is_super_admin();

  if not (
    v_caller_is_super_admin
    or (public.has_role('school_admin') and v_target_school_id = public.current_user_school_id())
  ) then
    raise exception 'forbidden';
  end if;

  update public.users
  set first_name = coalesce(nullif(trim(p_first_name), ''), first_name),
      last_name = coalesce(nullif(trim(p_last_name), ''), last_name)
  where id = p_user_id;

  if p_role is not null and trim(p_role) != '' then
    begin
      v_role_type := trim(p_role)::public.role_type;
    exception when others then
      raise exception 'invalid_role: %', p_role;
    end;

    -- Only a real super_admin may assign the super_admin role. A
    -- school_admin (even a legitimate one, in their own school) must not
    -- be able to grant super_admin to anyone, including themselves.
    if v_role_type = 'super_admin' and not v_caller_is_super_admin then
      raise exception 'forbidden';
    end if;

    update public.user_roles
    set role = v_role_type
    where user_id = p_user_id
      and (p_school_id is null or school_id = p_school_id);
  end if;

  insert into public.audit_logs (
    school_id, user_id, acted_role, action, entity_type, entity_id, details
  ) values (
    v_target_school_id,
    auth.uid(),
    case when v_caller_is_super_admin then 'super_admin'::role_type else 'school_admin'::role_type end,
    'user.admin_update',
    'users',
    p_user_id::text,
    jsonb_build_object(
      'first_name', p_first_name,
      'last_name', p_last_name,
      'role', p_role
    )
  );

  return jsonb_build_object(
    'success', true,
    'user_id', p_user_id,
    'first_name', p_first_name,
    'last_name', p_last_name,
    'role', p_role
  );
end;
$$ language plpgsql security definer set search_path = public, extensions;
