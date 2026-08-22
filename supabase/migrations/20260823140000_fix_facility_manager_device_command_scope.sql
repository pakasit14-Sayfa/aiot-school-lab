-- queue_device_command (20260721010000_relay_commands.sql) only checked
-- v_device.school_id against the caller's school — for facility_manager
-- that's not enough. BR4 (see 20260817000000_facility_manager_device_list.sql)
-- says a facility manager's scope is "อาคารที่รับผิดชอบเท่านั้น" (only their
-- assigned building), and list_devices_in_my_building/sensor_latest both
-- enforce that via users.building matched as a prefix against
-- devices.location. This RPC didn't, so a facility manager could queue a
-- command against any device anywhere in the school as long as they knew
-- (or guessed) its device_id — confirmed live: facility@ successfully
-- queued a command against a relay in "Lab 3" while assigned to
-- "อาคาร 3", a building list_devices_in_my_building correctly hides from
-- them.

create or replace function queue_device_command(
  p_token text,
  p_device_id uuid,
  p_command jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_device record;
  v_command_id uuid;
  v_building varchar;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then
    raise exception 'invalid_session';
  end if;
  if v_actor.role not in ('school_admin', 'super_admin', 'technician', 'facility_manager') then
    raise exception 'forbidden';
  end if;

  select * into v_device from devices where id = p_device_id;
  if not found then
    raise exception 'device_not_found';
  end if;
  if v_actor.role <> 'super_admin' and v_device.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;

  if v_actor.role = 'facility_manager' then
    select building into v_building from users where id = v_actor.user_id;
    if v_building is null
       or v_device.location is null
       or v_device.location not like (v_building || '%') then
      raise exception 'forbidden';
    end if;
  end if;

  insert into device_commands (device_id, command, created_by)
  values (p_device_id, p_command, v_actor.user_id)
  returning id into v_command_id;

  return v_command_id;
end;
$$;

revoke all on function queue_device_command(text, uuid, jsonb) from public;
grant execute on function queue_device_command(text, uuid, jsonb) to anon, authenticated;
