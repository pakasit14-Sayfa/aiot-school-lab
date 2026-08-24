-- school_students_page.dart and school_teachers_page.dart both edit a
-- user via `client.from('users').update(...)` directly (name/student_code/
-- email/status fields) and toggle suspend/activate the same way — both
-- broken by the same UPDATE revoke on public.users from this morning's
-- security fix, same root cause as permissions_page.dart's name-edit bug
-- (20260824050000_fix_admin_update_user_profile_bugs.sql), just not
-- routed through that RPC yet. Confirmed live: schooladmin@ editing a
-- real student via this exact call shape gets 403 permission denied.
--
-- Extend admin_update_user_profile rather than write two new RPCs — same
-- dual-check authorization already covers this, just needs three more
-- optional fields.
--
-- `create or replace function` only replaces a function whose argument
-- list matches exactly — adding p_building changed the signature, so this
-- silently created a second overload alongside the original 5-arg one
-- instead of replacing it (PostgREST then couldn't resolve which one to
-- call and errored with PGRST203). Drop the old signature explicitly
-- before recreating.

drop function if exists public.admin_update_user_profile(uuid, text, text, text, uuid);
drop function if exists public.admin_update_user_profile(uuid, text, text, text, uuid, text, text, text);

create or replace function public.admin_update_user_profile(
  p_user_id uuid,
  p_first_name text,
  p_last_name text,
  p_role text default null,
  p_school_id uuid default null,
  p_student_code text default null,
  p_email text default null,
  p_status text default null,
  p_building text default null
)
returns jsonb as $$
declare
  v_role_type public.role_type;
  v_target_school_id uuid;
  v_caller_is_super_admin boolean;
  v_status public.user_status;
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

  if p_status is not null and trim(p_status) != '' then
    begin
      v_status := trim(p_status)::public.user_status;
    exception when others then
      raise exception 'invalid_status: %', p_status;
    end;
  end if;

  update public.users
  set first_name = coalesce(nullif(trim(p_first_name), ''), first_name),
      last_name = coalesce(nullif(trim(p_last_name), ''), last_name),
      student_code = coalesce(nullif(trim(p_student_code), ''), student_code),
      email = coalesce(nullif(trim(p_email), ''), email),
      status = coalesce(v_status, status),
      building = coalesce(nullif(trim(p_building), ''), building)
  where id = p_user_id;

  if p_role is not null and trim(p_role) != '' then
    begin
      v_role_type := trim(p_role)::public.role_type;
    exception when others then
      raise exception 'invalid_role: %', p_role;
    end;

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
      'role', p_role,
      'status', p_status
    )
  );

  return jsonb_build_object(
    'success', true,
    'user_id', p_user_id,
    'first_name', p_first_name,
    'last_name', p_last_name,
    'role', p_role,
    'status', p_status
  );
end;
$$ language plpgsql security definer set search_path = public, extensions;
