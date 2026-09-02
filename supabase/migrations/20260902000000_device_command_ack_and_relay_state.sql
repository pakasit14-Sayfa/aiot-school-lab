-- =====================================================================
-- Command ACK + relay-state tracking.
--
-- The Cytron Maker Feather AIoT S3 board (CircuitPython) polls
-- poll_device_commands() every ~1s and drives 4 relays directly over
-- GPIO, but there was no way for it to report back "I actually did
-- this" or the resulting relay state, and no way for a dashboard to
-- read current relay state back. This adds an ack path and a per-relay
-- state table.
--
-- Deliberately does NOT touch sensor_ingest / poll_device_commands —
-- the board already depends on those exact names and response shapes.
-- =====================================================================

set search_path = public, extensions;

alter table device_commands
  add column if not exists acked_at timestamptz,
  add column if not exists ack_status text check (ack_status in ('ok', 'failed')),
  add column if not exists ack_detail jsonb;

create table if not exists device_relay_states (
  device_id uuid not null references devices(id) on delete cascade,
  relay_no smallint not null check (relay_no between 1 and 4),
  state boolean not null,
  updated_at timestamptz not null default now(),
  updated_by_command_id uuid references device_commands(id),
  primary key (device_id, relay_no)
);

-- ---------------------------------------------------------------------
-- Board calls this right after executing (or failing to execute) a
-- command polled via poll_device_commands(). Same device-token auth as
-- sensor_ingest/poll_device_commands — no user session needed.
--
-- p_relay/p_state are the *actual* resulting relay state, not an echo
-- of what was requested — matters for TOGGLE, and for a command that
-- only partially succeeded. Pass them whenever p_status = 'ok' and the
-- command was a relay command; omit for non-relay commands or a failed
-- command.
-- ---------------------------------------------------------------------
create or replace function ack_device_command(
  p_device_token text,
  p_command_id uuid,
  p_status text,
  p_relay smallint default null,
  p_state boolean default null,
  p_detail jsonb default null
)
returns void
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

  if p_status not in ('ok', 'failed') then
    raise exception 'invalid_status';
  end if;

  update device_commands
    set acked_at = now(), ack_status = p_status, ack_detail = p_detail
    where id = p_command_id and device_id = v_device.id;
  if not found then
    raise exception 'command_not_found';
  end if;

  if p_status = 'ok' and p_relay is not null and p_state is not null then
    insert into device_relay_states (device_id, relay_no, state, updated_at, updated_by_command_id)
    values (v_device.id, p_relay, p_state, now(), p_command_id)
    on conflict (device_id, relay_no) do update
      set state = excluded.state,
          updated_at = excluded.updated_at,
          updated_by_command_id = excluded.updated_by_command_id;
  end if;
end;
$$;

-- ---------------------------------------------------------------------
-- Dashboard read: current known state of every relay on a device (or
-- every relay in the actor's school). Same school-scoping shape as the
-- *correct* sensor_latest (super_admin sees all, others their own
-- school only) — see agy-brief-sensor-latest-school-scope-leak.md for
-- why this must never degrade to "no scoping."
-- ---------------------------------------------------------------------
create or replace function list_device_relay_states(
  p_token text,
  p_device_id uuid default null
)
returns table (
  device_id uuid,
  device_name varchar,
  location varchar,
  relay_no smallint,
  state boolean,
  updated_at timestamptz
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
    select d.id, d.name, d.location, rs.relay_no, rs.state, rs.updated_at
    from device_relay_states rs
    join devices d on d.id = rs.device_id
    where (v_actor.role = 'super_admin' or d.school_id is not distinct from v_actor.school_id)
      and (p_device_id is null or d.id = p_device_id)
    order by d.id, rs.relay_no;
end;
$$;

grant execute on function ack_device_command(text, uuid, text, smallint, boolean, jsonb) to anon, authenticated;
grant execute on function list_device_relay_states(text, uuid) to anon, authenticated;
