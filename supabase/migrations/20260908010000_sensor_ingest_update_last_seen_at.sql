-- sensor_ingest set devices.status = 'online' on every ingest call but never
-- touched last_seen_at, so the column stayed frozen at whatever value
-- register_device set at registration time even while a device streamed
-- live readings every ~15s (found 2026-09-08 by cross-checking sensor_readings
-- timestamps against devices.last_seen_at on production for a live gas
-- sensor: readings were seconds old, last_seen_at was 11 days stale).
create or replace function public.sensor_ingest(p_device_token text, p_readings jsonb)
returns integer
language plpgsql
security definer
set search_path to 'public', 'extensions'
as $function$
declare
  v_device record;
  v_reading jsonb;
  v_metric metric_type;
  v_value numeric;
  v_ts timestamptz;
  v_inserted integer := 0;
begin
  select * into v_device from devices
    where token_hash = encode(digest(p_device_token, 'sha256'), 'hex');
  if not found then
    raise exception 'invalid_device_token';
  end if;

  if p_readings is null or jsonb_typeof(p_readings) <> 'array' then
    raise exception 'readings_must_be_array';
  end if;
  if jsonb_array_length(p_readings) > 500 then
    raise exception 'batch_too_large'; -- max 500 readings per call
  end if;

  for v_reading in select * from jsonb_array_elements(p_readings)
  loop
    begin
      v_metric := (v_reading->>'metric')::metric_type;
    exception when others then
      raise exception 'unknown_metric: %', v_reading->>'metric';
    end;

    v_value := (v_reading->>'value')::numeric;
    if v_value is null then
      raise exception 'missing_value_for_metric: %', v_metric;
    end if;
    v_ts := coalesce((v_reading->>'ts')::timestamptz, now());

    insert into sensor_readings (device_id, metric, ts, value)
    values (v_device.id, v_metric, v_ts, v_value)
    on conflict (device_id, metric, ts) do nothing;
    if found then
      v_inserted := v_inserted + 1;
    end if;
  end loop;

  update devices set status = 'online', last_seen_at = now() where id = v_device.id;
  insert into device_heartbeats (device_id, status, details)
  values (v_device.id, 'online',
          jsonb_build_object('readings', jsonb_array_length(p_readings)));

  return v_inserted;
end;
$function$;
