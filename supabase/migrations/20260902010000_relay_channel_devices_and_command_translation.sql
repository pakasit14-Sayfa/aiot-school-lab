-- =====================================================================
-- Multi-relay board support.
--
-- Problem: existing relay-control UI (school_admin_device_control_page,
-- super_admin_device_control_page) assumes 1 devices row = 1 relay, and
-- sends queue_device_command(..., {"action":"on"/"off"}) with no relay
-- number. The Cytron Maker Feather AIoT S3 board is a single physical
-- device (1 device_token) exposing 4 relay channels, and expects
-- {"relay":1-4,"state":"ON"/"OFF"/"TOGGLE"} on poll_device_commands.
--
-- Fix: model each relay channel as its own `devices` row (type =
-- 'relay') linked to its physical parent via parent_device_id/relay_no,
-- so the existing UI (which lists devices where type = 'relay' and
-- calls queue_device_command per row) needs zero changes. All the
-- translation happens inside queue_device_command: if the targeted
-- device is a channel of a parent, redirect the command to the
-- parent's device_id and translate {"action":"on"/"off"/"toggle"} into
-- the {"relay":N,"state":"ON"/"OFF"/"TOGGLE"} shape the board expects.
--
-- Does not touch sensor_ingest / poll_device_commands.
-- =====================================================================

set search_path = public, extensions;

alter table devices
  add column if not exists parent_device_id uuid references devices(id) on delete cascade,
  add column if not exists relay_no smallint check (relay_no between 1 and 4);

create unique index if not exists devices_parent_relay_unique
  on devices (parent_device_id, relay_no)
  where parent_device_id is not null;

-- ---------------------------------------------------------------------
-- Register the 4 relay channels of the real Cytron board already
-- streaming sensor data in this environment (เซนเซอร์ห้องทดลอง).
-- Relay 1 is named for water per the existing "เปิดปิดน้ำ" test and the
-- historical relay1 command log; relays 2-4 are generic pending
-- confirmation of what they actually control — rename via the normal
-- device-editing flow once known.
-- ---------------------------------------------------------------------
insert into devices (school_id, type, name, location, registered_by, parent_device_id, relay_no, status)
select d.school_id, 'relay', label, d.location, d.registered_by, d.id, g.relay_no, 'online'
from devices d
cross join (values (1, 'วาล์วน้ำ (Relay 1)'), (2, 'รีเลย์ 2'), (3, 'รีเลย์ 3'), (4, 'รีเลย์ 4')) as g(relay_no, label)
where d.id = 'be76fccb-1100-4147-bc4b-baf652c3963a'
  and not exists (
    select 1 from devices existing
    where existing.parent_device_id = d.id and existing.relay_no = g.relay_no
  );

-- ---------------------------------------------------------------------
-- queue_device_command: same signature/permissions as before, but now
-- redirects to the parent device and translates the command when the
-- targeted device is a relay channel.
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
  v_rl record;
  v_now timestamptz := clock_timestamp();
  v_target_device_id uuid;
  v_final_command jsonb;
  v_action text;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('school_admin', 'super_admin') then raise exception 'forbidden'; end if;

  select * into v_device from devices where id = p_device_id;
  if not found then raise exception 'device_not_found'; end if;
  if v_actor.role <> 'super_admin' and v_device.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;

  -- Rate limiting: max 20 commands per (channel) device per 1 minute window
  select * into v_rl
  from device_command_rate_limits
  where device_id = p_device_id
  for update;

  if not found then
    insert into device_command_rate_limits (device_id, window_started_at, attempt_count)
    values (p_device_id, v_now, 1)
    on conflict (device_id) do update
      set attempt_count = device_command_rate_limits.attempt_count + 1;
  else
    if v_now < v_rl.window_started_at + interval '1 minute' then
      if v_rl.attempt_count >= 20 then
        update device_command_rate_limits
        set attempt_count = attempt_count + 1,
            blocked_until = v_rl.window_started_at + interval '1 minute'
        where device_id = p_device_id;
        raise exception 'rate_limited';
      else
        update device_command_rate_limits
        set attempt_count = attempt_count + 1
        where device_id = p_device_id;
      end if;
    else
      -- Window expired, reset window
      update device_command_rate_limits
      set window_started_at = v_now,
          attempt_count = 1,
          blocked_until = null
      where device_id = p_device_id;
    end if;
  end if;

  if v_device.parent_device_id is not null and v_device.relay_no is not null then
    v_target_device_id := v_device.parent_device_id;
    v_action := lower(coalesce(p_command->>'action', ''));
    v_final_command := case v_action
      when 'on' then jsonb_build_object('relay', v_device.relay_no, 'state', 'ON')
      when 'off' then jsonb_build_object('relay', v_device.relay_no, 'state', 'OFF')
      when 'toggle' then jsonb_build_object('relay', v_device.relay_no, 'state', 'TOGGLE')
      when 'emergency_stop' then jsonb_build_object('relay', v_device.relay_no, 'state', 'OFF')
      else p_command || jsonb_build_object('relay', v_device.relay_no)
    end;
  else
    v_target_device_id := p_device_id;
    v_final_command := p_command;
  end if;

  insert into device_commands (device_id, command, created_by)
  values (v_target_device_id, v_final_command, v_actor.user_id)
  returning id into v_command_id;

  return v_command_id;
end;
$$;

grant execute on function queue_device_command(text, uuid, jsonb) to anon, authenticated;
