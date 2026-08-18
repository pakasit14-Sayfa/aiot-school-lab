-- =====================================================================
-- Migration: emergency_events RPCs (EMG-4 / EMG-5 / EMG-6)
-- Provides list_emergency_events, acknowledge_emergency_event, and
-- close_emergency_event for physical emergency button events.
-- =====================================================================

set search_path = public, extensions;

-- ---------------------------------------------------------------------
-- 1. list_emergency_events (EMG-6)
-- Allows school_admin (AD), teacher (TE), executive (EX) to query
-- emergency events for their school.
-- ---------------------------------------------------------------------
create or replace function list_emergency_events(
  p_token text,
  p_status emergency_status default null
)
returns table (
  id uuid,
  school_id uuid,
  source_device_id uuid,
  device_name varchar,
  location varchar,
  triggered_at timestamptz,
  status emergency_status,
  warning_light_on boolean,
  acknowledged_by uuid,
  acknowledged_by_name text,
  acknowledged_at timestamptz,
  closed_at timestamptz,
  review_note text
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('school_admin', 'teacher', 'executive') then
    raise exception 'forbidden';
  end if;

  return query
  select
    e.id,
    e.school_id,
    e.source_device_id,
    coalesce(d.name, 'ปุ่มกดกายภาพ')::varchar as device_name,
    e.location,
    e.triggered_at,
    e.status,
    e.warning_light_on,
    e.acknowledged_by,
    (u.first_name || ' ' || u.last_name)::text as acknowledged_by_name,
    e.acknowledged_at,
    e.closed_at,
    e.review_note
  from emergency_events e
  left join devices d on d.id = e.source_device_id
  left join users u on u.id = e.acknowledged_by
  where e.school_id = v_actor.school_id
    and (p_status is null or e.status = p_status)
  order by e.triggered_at desc;
end;
$$;

-- ---------------------------------------------------------------------
-- 2. acknowledge_emergency_event (EMG-5)
-- Allows school_admin (AD) and teacher (TE) to acknowledge a physical
-- emergency event.
-- ---------------------------------------------------------------------
create or replace function acknowledge_emergency_event(
  p_token text,
  p_event_id uuid
)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_event record;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('school_admin', 'teacher') then
    raise exception 'forbidden';
  end if;

  select * into v_event from emergency_events where id = p_event_id;
  if not found then raise exception 'event_not_found'; end if;
  if v_actor.role <> 'super_admin' and v_event.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;

  if v_event.status = 'closed' then
    raise exception 'event_already_closed';
  end if;
  if v_event.status = 'acknowledged' then
    raise exception 'event_already_acknowledged';
  end if;

  update emergency_events
  set status = 'acknowledged',
      acknowledged_by = v_actor.user_id,
      acknowledged_at = now()
  where id = p_event_id;
end;
$$;

-- ---------------------------------------------------------------------
-- 3. close_emergency_event (EMG-5)
-- Allows school_admin (AD) and teacher (TE) to resolve/close an event.
-- Enforces mandatory review_note entry (EMG-5 BR1).
-- ---------------------------------------------------------------------
create or replace function close_emergency_event(
  p_token text,
  p_event_id uuid,
  p_review_note text
)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_event record;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('school_admin', 'teacher') then
    raise exception 'forbidden';
  end if;

  if p_review_note is null or trim(p_review_note) = '' then
    raise exception 'review_note_required';
  end if;

  select * into v_event from emergency_events where id = p_event_id;
  if not found then raise exception 'event_not_found'; end if;
  if v_actor.role <> 'super_admin' and v_event.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;

  if v_event.status = 'closed' then
    raise exception 'event_already_closed';
  end if;

  update emergency_events
  set status = 'closed',
      closed_at = now(),
      review_note = trim(p_review_note),
      warning_light_on = false
  where id = p_event_id;
end;
$$;

-- Grants & Revokes
revoke all on function list_emergency_events(text, emergency_status) from public;
grant execute on function list_emergency_events(text, emergency_status) to anon, authenticated;

revoke all on function acknowledge_emergency_event(text, uuid) from public;
grant execute on function acknowledge_emergency_event(text, uuid) to anon, authenticated;

revoke all on function close_emergency_event(text, uuid, text) from public;
grant execute on function close_emergency_event(text, uuid, text) to anon, authenticated;
