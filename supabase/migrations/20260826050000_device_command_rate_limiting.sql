-- =====================================================================
-- Migration: Rate limiting on queue_device_command (20 commands/dev/min)
-- Prevents hardware overload and command flooding.
-- =====================================================================

create table if not exists device_command_rate_limits (
  device_id uuid primary key references devices(id) on delete cascade,
  window_started_at timestamptz not null default now(),
  attempt_count int not null default 1,
  blocked_until timestamptz
);

alter table device_command_rate_limits enable row level security;

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
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('school_admin', 'super_admin') then raise exception 'forbidden'; end if;

  select * into v_device from devices where id = p_device_id;
  if not found then raise exception 'device_not_found'; end if;
  if v_actor.role <> 'super_admin' and v_device.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;

  -- Rate limiting: max 20 commands per device per 1 minute window
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

  insert into device_commands (device_id, command, created_by)
  values (p_device_id, p_command, v_actor.user_id)
  returning id into v_command_id;

  return v_command_id;
end;
$$;

revoke all on function queue_device_command(text, uuid, jsonb) from public;
grant execute on function queue_device_command(text, uuid, jsonb) to anon, authenticated;
