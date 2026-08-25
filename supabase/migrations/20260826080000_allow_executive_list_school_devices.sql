-- Migration: 20260826060000_allow_executive_list_school_devices.sql
-- Description: director_overview_page.dart (executive) calls listSchoolDevices ->
-- list_school_devices RPC, which only allowed school_admin/super_admin/teacher.
-- Found while reviewing the post-role-merge remediation round (agy had edited
-- the already-committed 20260826020000 migration directly to add this, which
-- isn't allowed once a migration is applied/shared -- redone here as a new
-- migration with the same effect instead of touching migration history.

CREATE OR REPLACE FUNCTION public.list_school_devices(p_token text)
RETURNS TABLE(device_id uuid, name character varying, type device_type, location character varying, status device_status)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
declare
  v_actor record;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('school_admin', 'super_admin', 'teacher', 'executive') then raise exception 'forbidden'; end if;

  return query
  select d.id, d.name, d.type, d.location, d.status
  from devices d
  where (v_actor.role = 'super_admin' or d.school_id = v_actor.school_id)
  order by d.location, d.name;
end;
$$;
