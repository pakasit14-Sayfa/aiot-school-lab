-- Daily trend versions of get_energy_usage_summary/get_water_usage_summary
-- (20260819010000_utility_costs.sql) — the summary RPCs only return one
-- aggregate total for a period, which isn't enough to draw a graph. These
-- return one row per day so the student home page's utility card can show
-- an actual trend instead of a single number, for the "help the whole
-- school notice and reduce usage" goal. Same role/scope rules as the
-- summary RPCs they're siblings of (same actor check, same school_id
-- scoping, same device type filter).

create or replace function get_energy_usage_trend(p_token text, p_days integer default 7)
returns table (day date, total_kwh numeric)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;

  if v_actor.role not in (
    'school_admin', 'teacher', 'executive', 'student',
    'facility_manager', 'technician'
  ) then
    raise exception 'forbidden';
  end if;

  if p_days is null or p_days < 1 or p_days > 90 then
    raise exception 'invalid_days';
  end if;

  return query
  select gs.day::date, coalesce(sum(sr.value), 0)::numeric as total_kwh
  from generate_series(
    date_trunc('day', now()) - ((p_days - 1) || ' days')::interval,
    date_trunc('day', now()),
    interval '1 day'
  ) as gs(day)
  left join devices d on d.school_id = v_actor.school_id and d.type = 'energy_meter'
  left join sensor_readings sr on sr.device_id = d.id
    and sr.metric = 'energy_kwh'
    and date_trunc('day', sr.ts) = gs.day
  group by gs.day
  order by gs.day;
end;
$$;

create or replace function get_water_usage_trend(p_token text, p_days integer default 7)
returns table (day date, total_m3 numeric)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;

  if v_actor.role not in (
    'school_admin', 'teacher', 'executive', 'student',
    'facility_manager', 'technician'
  ) then
    raise exception 'forbidden';
  end if;

  if p_days is null or p_days < 1 or p_days > 90 then
    raise exception 'invalid_days';
  end if;

  return query
  select gs.day::date, coalesce(sum(sr.value), 0)::numeric as total_m3
  from generate_series(
    date_trunc('day', now()) - ((p_days - 1) || ' days')::interval,
    date_trunc('day', now()),
    interval '1 day'
  ) as gs(day)
  left join devices d on d.school_id = v_actor.school_id and d.type = 'water_meter'
  left join sensor_readings sr on sr.device_id = d.id
    and sr.metric = 'water_m3'
    and date_trunc('day', sr.ts) = gs.day
  group by gs.day
  order by gs.day;
end;
$$;

revoke all on function get_energy_usage_trend(text, integer) from public;
revoke all on function get_water_usage_trend(text, integer) from public;

grant execute on function get_energy_usage_trend(text, integer) to anon, authenticated;
grant execute on function get_water_usage_trend(text, integer) to anon, authenticated;
