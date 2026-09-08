-- poll_device_commands is the regular heartbeat-shaped call relay/camera
-- devices make (they poll for pending commands even when there's nothing to
-- send readings for), but it never touched devices.status/last_seen_at —
-- only sensor_ingest did, which those device types never call. Same class
-- of bug fixed for sensor_ingest in 20260908010000, found while checking
-- whether the same gap existed for non-sensor device types before scoping
-- any offline-detection cron (that part still needs firmware polling-cadence
-- info from the hardware team before a staleness threshold can be picked).
create or replace function public.poll_device_commands(p_device_token text)
returns table(command_id uuid, command jsonb, created_at timestamptz)
language plpgsql
security definer
set search_path to 'public', 'extensions'
as $function$
declare
  v_device record;
begin
  select * into v_device from devices
    where token_hash = encode(digest(p_device_token, 'sha256'), 'hex');
  if not found then
    raise exception 'invalid_device_token';
  end if;

  update devices set status = 'online', last_seen_at = now() where id = v_device.id;

  return query
    update device_commands
      set delivered_at = now()
      where device_id = v_device.id and delivered_at is null
      returning id, device_commands.command, device_commands.created_at;
end;
$function$;
