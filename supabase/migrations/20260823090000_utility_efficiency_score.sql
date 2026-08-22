-- Efficiency score for the student utility trend card: compares the last
-- 7 days total against the 7 days before that. Using less than before is
-- rewarded (score > 50), using more is penalized (score < 50) — score =
-- clamp(50 + percent_reduction, 0, 100). Same role/scope rules as the
-- summary/trend RPCs (20260819010000_utility_costs.sql,
-- 20260823080000_utility_usage_trend.sql).
--
-- Label bands (BR: computed server-side, not guessed client-side, so the
-- threshold logic lives in one place): >=70 ดีมาก, >=50 พอใช้, <50 ควรปรับปรุง.
-- No prior-period data at all (e.g. meters just installed) returns
-- score=null so the UI can say "ยังไม่มีข้อมูลเทียบ" instead of a fake 50.

create or replace function get_energy_efficiency_score(p_token text)
returns table (score numeric, label text, current_kwh numeric, previous_kwh numeric)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_current numeric;
  v_previous numeric;
  v_score numeric;
  v_label text;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;

  if v_actor.role not in (
    'school_admin', 'teacher', 'executive', 'student',
    'facility_manager', 'technician'
  ) then
    raise exception 'forbidden';
  end if;

  select coalesce(sum(sr.value), 0) into v_current
  from devices d
  join sensor_readings sr on sr.device_id = d.id and sr.metric = 'energy_kwh'
  where d.school_id = v_actor.school_id and d.type = 'energy_meter'
    and sr.ts >= now() - interval '7 days';

  select coalesce(sum(sr.value), 0) into v_previous
  from devices d
  join sensor_readings sr on sr.device_id = d.id and sr.metric = 'energy_kwh'
  where d.school_id = v_actor.school_id and d.type = 'energy_meter'
    and sr.ts >= now() - interval '14 days' and sr.ts < now() - interval '7 days';

  if v_previous <= 0 then
    return query select null::numeric, null::text, v_current, v_previous;
    return;
  end if;

  v_score := greatest(0, least(100, 50 + ((v_previous - v_current) / v_previous * 100)));
  v_label := case
    when v_score >= 70 then 'ดีมาก'
    when v_score >= 50 then 'พอใช้'
    else 'ควรปรับปรุง'
  end;

  return query select round(v_score, 0), v_label, v_current, v_previous;
end;
$$;

create or replace function get_water_efficiency_score(p_token text)
returns table (score numeric, label text, current_m3 numeric, previous_m3 numeric)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_current numeric;
  v_previous numeric;
  v_score numeric;
  v_label text;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;

  if v_actor.role not in (
    'school_admin', 'teacher', 'executive', 'student',
    'facility_manager', 'technician'
  ) then
    raise exception 'forbidden';
  end if;

  select coalesce(sum(sr.value), 0) into v_current
  from devices d
  join sensor_readings sr on sr.device_id = d.id and sr.metric = 'water_m3'
  where d.school_id = v_actor.school_id and d.type = 'water_meter'
    and sr.ts >= now() - interval '7 days';

  select coalesce(sum(sr.value), 0) into v_previous
  from devices d
  join sensor_readings sr on sr.device_id = d.id and sr.metric = 'water_m3'
  where d.school_id = v_actor.school_id and d.type = 'water_meter'
    and sr.ts >= now() - interval '14 days' and sr.ts < now() - interval '7 days';

  if v_previous <= 0 then
    return query select null::numeric, null::text, v_current, v_previous;
    return;
  end if;

  v_score := greatest(0, least(100, 50 + ((v_previous - v_current) / v_previous * 100)));
  v_label := case
    when v_score >= 70 then 'ดีมาก'
    when v_score >= 50 then 'พอใช้'
    else 'ควรปรับปรุง'
  end;

  return query select round(v_score, 0), v_label, v_current, v_previous;
end;
$$;

revoke all on function get_energy_efficiency_score(text) from public;
revoke all on function get_water_efficiency_score(text) from public;

grant execute on function get_energy_efficiency_score(text) to anon, authenticated;
grant execute on function get_water_efficiency_score(text) to anon, authenticated;
