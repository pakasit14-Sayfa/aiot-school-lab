-- =====================================================================
-- Security fix: sensor_latest's school-scoping WHERE clause was
-- replaced (20260901000003_parent_sensor_latest.sql) with a
-- self-referential `d.school_id = coalesce(v_actor.school_id,
-- d.school_id)` — a tautology whenever the caller's session has no
-- active school, leaking sensor readings across every school. The same
-- change also dropped `super_admin` from the allowed-role list
-- (regression) and left dead branches for the decommissioned
-- `facility_manager`/`technician` roles (merged away 2026-08-25, see
-- CLAUDE.md — zero users currently hold either role).
--
-- See docs/handoff/agy-brief-sensor-latest-school-scope-leak.md for the
-- full writeup. This migration restores the original, correct scoping
-- (super_admin sees every school; every other role strictly limited to
-- their own, never degrading to "no scope") while keeping the
-- legitimate `parent` addition from the buggy version.
-- =====================================================================

set search_path = public, extensions;

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

  if v_actor.role not in (
    'super_admin', 'school_admin', 'teacher', 'executive', 'student', 'parent'
  ) then
    raise exception 'forbidden';
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

grant execute on function sensor_latest(text, uuid) to anon, authenticated;
