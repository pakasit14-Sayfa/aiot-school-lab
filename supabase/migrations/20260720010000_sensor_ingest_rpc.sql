-- =====================================================================
-- Sensor ingest + read path (AIO-12): first real data flow for
-- sensor_readings, replacing the client-side mock RealtimeService.
--
-- Flow:
--   1. school_admin/technician calls register_device() from the app —
--      creates the device row and returns a device token (shown once).
--   2. The AIoT gateway POSTs readings to /rest/v1/rpc/sensor_ingest
--      with that token — no user session needed on the device side.
--   3. The app reads via sensor_latest() / sensor_history() with a
--      normal session token, scoped to the actor's school.
--
-- Device tokens are stored as sha256 hashes (same scheme as session
-- tokens). Rotate with issue_device_token(); the old token stops
-- working immediately.
-- =====================================================================

set search_path = public, extensions;

alter table devices add column if not exists token_hash varchar unique;

-- ---------------------------------------------------------------------
-- Register a device and issue its token in one step.
-- ---------------------------------------------------------------------
create or replace function register_device(
  p_token text,
  p_type device_type,
  p_name text,
  p_serial_no text default null,
  p_location text default null,
  p_kit_code text default null
)
returns table (device_id uuid, device_token text)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_device_token text;
  v_device_id uuid;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then
    raise exception 'invalid_session';
  end if;
  if v_actor.role not in ('school_admin', 'super_admin', 'technician') then
    raise exception 'forbidden';
  end if;
  if v_actor.school_id is null then
    raise exception 'no_active_school';
  end if;

  v_device_token := 'dev_' || encode(gen_random_bytes(24), 'hex');

  insert into devices (school_id, type, name, serial_no, location, kit_code,
                       registered_by, token_hash)
  values (v_actor.school_id, p_type, p_name, p_serial_no, p_location, p_kit_code,
          v_actor.user_id, encode(digest(v_device_token, 'sha256'), 'hex'))
  returning id into v_device_id;

  return query select v_device_id, v_device_token;
end;
$$;

-- ---------------------------------------------------------------------
-- Rotate the token of an existing device.
-- ---------------------------------------------------------------------
create or replace function issue_device_token(
  p_token text,
  p_device_id uuid
)
returns text
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_device record;
  v_device_token text;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then
    raise exception 'invalid_session';
  end if;
  if v_actor.role not in ('school_admin', 'super_admin', 'technician') then
    raise exception 'forbidden';
  end if;

  select * into v_device from devices where id = p_device_id;
  if not found then
    raise exception 'device_not_found';
  end if;
  if v_actor.role <> 'super_admin' and v_device.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;

  v_device_token := 'dev_' || encode(gen_random_bytes(24), 'hex');
  update devices
    set token_hash = encode(digest(v_device_token, 'sha256'), 'hex')
    where id = p_device_id;

  return v_device_token;
end;
$$;

-- ---------------------------------------------------------------------
-- Ingest: called by the gateway with its device token (no user session).
-- p_readings = jsonb array of {"metric": ..., "value": ..., "ts": ...}
-- ts is optional (defaults to now()). Duplicate (metric, ts) rows are
-- ignored so the gateway can safely retry a failed batch.
-- Returns the number of readings actually inserted.
-- ---------------------------------------------------------------------
create or replace function sensor_ingest(
  p_device_token text,
  p_readings jsonb
)
returns integer
language plpgsql
security definer
set search_path = public, extensions
as $$
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

  update devices set status = 'online' where id = v_device.id;
  insert into device_heartbeats (device_id, status, details)
  values (v_device.id, 'online',
          jsonb_build_object('readings', jsonb_array_length(p_readings)));

  return v_inserted;
end;
$$;

-- ---------------------------------------------------------------------
-- Latest reading per metric for every device in the actor's school
-- (optionally a single device). Any signed-in role of that school can
-- read — dashboards for students/teachers/parents all consume this.
-- ---------------------------------------------------------------------
create or replace function sensor_latest(
  p_token text,
  p_device_id uuid default null
)
returns table (
  device_id uuid,
  device_name varchar,
  location varchar,
  metric metric_type,
  ts timestamptz,
  value numeric
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then
    raise exception 'invalid_session';
  end if;

  return query
    select distinct on (d.id, r.metric)
      d.id, d.name, d.location, r.metric, r.ts, r.value
    from devices d
    join sensor_readings r on r.device_id = d.id
    where (v_actor.role = 'super_admin' or d.school_id is not distinct from v_actor.school_id)
      and (p_device_id is null or d.id = p_device_id)
    order by d.id, r.metric, r.ts desc;
end;
$$;

-- ---------------------------------------------------------------------
-- History for one device+metric within a time range (for charts).
-- ---------------------------------------------------------------------
create or replace function sensor_history(
  p_token text,
  p_device_id uuid,
  p_metric metric_type,
  p_from timestamptz,
  p_to timestamptz default null
)
returns table (ts timestamptz, value numeric)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_device record;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then
    raise exception 'invalid_session';
  end if;

  select * into v_device from devices where id = p_device_id;
  if not found then
    raise exception 'device_not_found';
  end if;
  if v_actor.role <> 'super_admin' and v_device.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;

  return query
    select r.ts, r.value
    from sensor_readings r
    where r.device_id = p_device_id
      and r.metric = p_metric
      and r.ts >= p_from
      and r.ts <= coalesce(p_to, now())
    order by r.ts
    limit 10000;
end;
$$;

grant execute on function register_device(text, device_type, text, text, text, text) to anon, authenticated;
grant execute on function issue_device_token(text, uuid) to anon, authenticated;
grant execute on function sensor_ingest(text, jsonb) to anon, authenticated;
grant execute on function sensor_latest(text, uuid) to anon, authenticated;
grant execute on function sensor_history(text, uuid, metric_type, timestamptz, timestamptz) to anon, authenticated;
