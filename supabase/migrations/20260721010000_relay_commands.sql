-- =====================================================================
-- Relay control (AIO): reverse path app -> device, alongside the
-- existing device -> app path (sensor_ingest / sensor_latest).
--
-- The app can't push to the board directly (board only speaks MQTT to
-- the gateway, not HTTP to Supabase). So commands are queued here and
-- the gateway polls poll_device_commands() using its device token,
-- then republishes each command over MQTT for the board to act on.
--
-- Flow:
--   app -> queue_device_command() -> device_commands row
--   gateway (polls every few seconds) -> poll_device_commands() -> MQTT publish
--   board subscribes to its command topic and switches the relay
-- =====================================================================

set search_path = public, extensions;

create table device_commands (
  id uuid primary key default gen_random_uuid(),
  device_id uuid not null references devices(id),
  command jsonb not null,
  created_by uuid not null,
  created_at timestamptz default now(),
  delivered_at timestamptz
);

create index device_commands_pending_idx on device_commands (device_id) where delivered_at is null;

-- ---------------------------------------------------------------------
-- App side: queue a command for a device. Requires an elevated role
-- (same set allowed to register devices) — no consent/authorization
-- concept for "who can flip a relay" beyond that yet.
-- ---------------------------------------------------------------------
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

  insert into device_commands (device_id, command, created_by)
  values (p_device_id, p_command, v_actor.user_id)
  returning id into v_command_id;

  return v_command_id;
end;
$$;

-- ---------------------------------------------------------------------
-- Gateway side: fetch + mark-delivered undelivered commands for the
-- device owning this token. No user session involved (same auth model
-- as sensor_ingest).
-- ---------------------------------------------------------------------
create or replace function poll_device_commands(p_device_token text)
returns table (command_id uuid, command jsonb, created_at timestamptz)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_device record;
begin
  select * into v_device from devices
    where token_hash = encode(digest(p_device_token, 'sha256'), 'hex');
  if not found then
    raise exception 'invalid_device_token';
  end if;

  return query
    update device_commands
      set delivered_at = now()
      where device_id = v_device.id and delivered_at is null
      returning id, device_commands.command, device_commands.created_at;
end;
$$;

grant execute on function queue_device_command(text, uuid, jsonb) to anon, authenticated;
grant execute on function poll_device_commands(text) to anon, authenticated;
