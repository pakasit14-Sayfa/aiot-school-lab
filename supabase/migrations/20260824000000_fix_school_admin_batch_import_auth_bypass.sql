-- CRITICAL: import_school_users_batch / archive_school_device / archive_school_user
-- (20260823150000_school_admin_hardening_and_batch_import.sql) all share the
-- same fail-open bug:
--
--   IF auth.uid() IS NOT NULL THEN
--     IF NOT (is_super_admin() OR ...) THEN RAISE EXCEPTION ...
--   ELSE
--     -- no check at all, execution just continues
--   END IF;
--
-- auth.uid() is NULL for any caller without a real Supabase Auth session —
-- which is exactly the anon role. Combined with `grant execute ... to anon`
-- on all three functions, this meant literally anyone holding the public
-- anon key (no login at all) could call them with zero authorization.
--
-- Confirmed live and exploitable: an unauthenticated request to
-- import_school_users_batch created a real super_admin account
-- (pwned-test@evil.local) with just the anon key. Also exploitable:
-- archive_school_device/archive_school_user could suspend any device/user
-- in the database from an anonymous request. The proof-of-concept account
-- has been deleted; this migration closes the hole.
--
-- Fix: require auth.uid() IS NOT NULL and a real authorization match in one
-- unconditional check (fail closed, not fail open), and revoke anon's
-- execute grant on all three — plus the two helper functions, which have no
-- legitimate anon use case either.

create or replace function public.import_school_users_batch(
  p_school_id uuid,
  p_role text,
  p_users jsonb
)
returns jsonb as $$
declare
  v_item jsonb;
  v_inserted_count int := 0;
  v_user_id uuid;
  v_email text;
  v_first_name text;
  v_last_name text;
  v_role_type public.role_type;
begin
  if auth.uid() is null then
    raise exception 'invalid_session';
  end if;

  if not (
    public.is_super_admin()
    or (public.has_role('school_admin') and p_school_id = public.current_user_school_id())
  ) then
    raise exception 'forbidden';
  end if;

  begin
    v_role_type := p_role::public.role_type;
  exception when others then
    raise exception 'invalid_role: %', p_role;
  end;

  for v_item in select * from jsonb_array_elements(p_users)
  loop
    v_email := trim(v_item->>'email');
    v_first_name := coalesce(trim(v_item->>'first_name'), 'นักเรียน');
    v_last_name := coalesce(trim(v_item->>'last_name'), 'ใหม่');

    if v_email is not null and v_email != '' then
      insert into public.users (school_id, email, password_hash, first_name, last_name, status)
      values (
        p_school_id,
        v_email,
        '$2a$10$7EqJtq98hPqEX7fNZaFWoO.8H0u.placeholderpasswordhash',
        v_first_name,
        v_last_name,
        'active'
      )
      on conflict (email) do update
      set first_name = excluded.first_name,
          last_name = excluded.last_name,
          school_id = excluded.school_id
      returning id into v_user_id;

      insert into public.user_roles (user_id, role, school_id, granted_by)
      values (v_user_id, v_role_type, p_school_id, auth.uid())
      on conflict (user_id, role, school_id) do nothing;

      v_inserted_count := v_inserted_count + 1;
    end if;
  end loop;

  insert into public.device_logs (device_id, school_id, event_type, message, metadata)
  values (
    null,
    p_school_id,
    'batch_import_completed',
    'Batch import completed for role ' || p_role || ' (total ' || v_inserted_count || ' records)',
    jsonb_build_object('role', p_role, 'count', v_inserted_count)
  );

  return jsonb_build_object(
    'success', true,
    'total_imported', v_inserted_count,
    'school_id', p_school_id,
    'role', p_role
  );
end;
$$ language plpgsql security definer;

create or replace function public.archive_school_device(p_device_id uuid)
returns jsonb as $$
declare
  v_school_id uuid;
begin
  if auth.uid() is null then
    raise exception 'invalid_session';
  end if;

  select school_id into v_school_id from public.devices where id = p_device_id;
  if not found then
    raise exception 'device_not_found';
  end if;

  if not (
    public.is_super_admin()
    or (public.has_role('school_admin') and v_school_id = public.current_user_school_id())
  ) then
    raise exception 'forbidden';
  end if;

  update public.devices set status = 'maintenance' where id = p_device_id;

  return jsonb_build_object('success', true, 'device_id', p_device_id, 'status', 'maintenance');
end;
$$ language plpgsql security definer;

create or replace function public.archive_school_user(p_user_id uuid)
returns jsonb as $$
declare
  v_school_id uuid;
begin
  if auth.uid() is null then
    raise exception 'invalid_session';
  end if;

  select school_id into v_school_id from public.users where id = p_user_id;
  if not found then
    raise exception 'user_not_found';
  end if;

  if not (
    public.is_super_admin()
    or (public.has_role('school_admin') and v_school_id = public.current_user_school_id())
  ) then
    raise exception 'forbidden';
  end if;

  update public.users set status = 'suspended' where id = p_user_id;

  return jsonb_build_object('success', true, 'user_id', p_user_id, 'status', 'suspended');
end;
$$ language plpgsql security definer;

revoke all on function public.import_school_users_batch(uuid, text, jsonb) from anon;
revoke all on function public.archive_school_device(uuid) from anon;
revoke all on function public.archive_school_user(uuid) from anon;
revoke all on function public.has_role(text) from anon;
revoke all on function public.current_user_school_id() from anon;

grant execute on function public.import_school_users_batch(uuid, text, jsonb) to authenticated;
grant execute on function public.archive_school_device(uuid) to authenticated;
grant execute on function public.archive_school_user(uuid) to authenticated;
grant execute on function public.has_role(text) to authenticated;
grant execute on function public.current_user_school_id() to authenticated;
