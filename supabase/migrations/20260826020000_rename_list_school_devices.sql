-- Migration: 20260826020000_rename_list_school_devices.sql
-- Description: Checkpoint 3 - Rename list_devices_in_my_building to list_school_devices

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
  if v_actor.role not in ('school_admin', 'super_admin', 'teacher') then raise exception 'forbidden'; end if;

  return query
  select d.id, d.name, d.type, d.location, d.status
  from devices d
  where (v_actor.role = 'super_admin' or d.school_id = v_actor.school_id)
  order by d.location, d.name;
end;
$$;

REVOKE ALL ON FUNCTION public.list_devices_in_my_building(text) FROM public;
DROP FUNCTION IF EXISTS public.list_devices_in_my_building(text);

GRANT EXECUTE ON FUNCTION public.list_school_devices TO anon, authenticated;
