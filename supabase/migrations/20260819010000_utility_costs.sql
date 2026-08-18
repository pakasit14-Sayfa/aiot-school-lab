-- Migration: Utility cost calculation & rate setting RPCs (AIO-5, AIO-6 & Water Utility)

-- =====================================================================
-- 1. อ่านอัตราค่าไฟและค่าน้ำของโรงเรียนตนเอง
-- =====================================================================

create or replace function get_school_utility_rates(p_token text)
returns table (
  electricity_rate_thb numeric,
  is_electricity_default boolean,
  water_rate_thb numeric,
  is_water_default boolean
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_elec numeric;
  v_water numeric;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;

  if v_actor.role not in (
    'school_admin', 'teacher', 'executive', 'student',
    'facility_manager', 'technician'
  ) then
    raise exception 'forbidden';
  end if;

  select ss.electricity_rate_thb, ss.water_rate_thb
  into v_elec, v_water
  from school_settings ss
  where ss.school_id = v_actor.school_id;

  return query select
    coalesce(v_elec, 4.50)::numeric as electricity_rate_thb,
    (v_elec is null) as is_electricity_default,
    coalesce(v_water, 18.00)::numeric as water_rate_thb,
    (v_water is null) as is_water_default;
end;
$$;

-- =====================================================================
-- 2. ตั้งค่าอัตราค่าไฟและค่าน้ำ (เฉพาะ school_admin / super_admin)
-- =====================================================================

create or replace function set_school_utility_rates(
  p_token text,
  p_electricity_rate_thb numeric,
  p_water_rate_thb numeric
)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;

  if v_actor.role not in ('school_admin', 'super_admin') then
    raise exception 'forbidden';
  end if;

  if p_electricity_rate_thb <= 0 or p_water_rate_thb <= 0 then
    raise exception 'invalid_utility_rate';
  end if;

  update school_settings
  set electricity_rate_thb = p_electricity_rate_thb,
      water_rate_thb = p_water_rate_thb
  where school_id = v_actor.school_id;
end;
$$;

-- =====================================================================
-- 3. สรุปการใช้พลังงานไฟฟ้า + คำนวณค่าไฟโดยประมาณ (AIO-5 / AIO-6)
-- =====================================================================

create or replace function get_energy_usage_summary(
  p_token text,
  p_period text default 'month'
)
returns table (
  device_count integer,
  total_kwh numeric,
  electricity_rate_thb numeric,
  is_rate_default boolean,
  estimated_cost_thb numeric,
  disclaimer text
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_start_ts timestamptz;
  v_device_count integer := 0;
  v_total_kwh numeric := 0;
  v_school_rate numeric;
  v_rate numeric := 4.50;
  v_is_default boolean := true;
  v_estimated_cost numeric := 0;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;

  if v_actor.role not in (
    'school_admin', 'teacher', 'executive', 'student',
    'facility_manager', 'technician'
  ) then
    raise exception 'forbidden';
  end if;

  if p_period = 'today' then
    v_start_ts := date_trunc('day', now());
  elsif p_period = 'week' then
    v_start_ts := date_trunc('week', now());
  else
    v_start_ts := date_trunc('month', now());
  end if;

  select count(distinct d.id)::integer, coalesce(sum(sr.value), 0)::numeric
  into v_device_count, v_total_kwh
  from devices d
  left join sensor_readings sr on sr.device_id = d.id
    and sr.metric = 'energy_kwh'
    and sr.ts >= v_start_ts
  where d.school_id = v_actor.school_id
    and d.type = 'energy_meter';

  select ss.electricity_rate_thb
  into v_school_rate
  from school_settings ss
  where ss.school_id = v_actor.school_id;

  if v_school_rate is not null then
    v_rate := v_school_rate;
    v_is_default := false;
  end if;

  v_estimated_cost := round(v_total_kwh * v_rate, 2);

  return query select
    v_device_count,
    v_total_kwh,
    v_rate,
    v_is_default,
    v_estimated_cost,
    'ค่าบริการประมาณการเพื่อการบริหารจัดการภายใน ไม่ใช่ใบแจ้งหนี้จริงจากผู้ให้บริการ'::text;
end;
$$;

-- =====================================================================
-- 4. สรุปการใช้น้ำ + คำนวณค่าน้ำโดยประมาณ (Water Utility - เพิ่มใหม่)
-- =====================================================================

create or replace function get_water_usage_summary(
  p_token text,
  p_period text default 'month'
)
returns table (
  device_count integer,
  total_m3 numeric,
  water_rate_thb numeric,
  is_rate_default boolean,
  estimated_cost_thb numeric,
  disclaimer text
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_start_ts timestamptz;
  v_device_count integer := 0;
  v_total_m3 numeric := 0;
  v_school_rate numeric;
  v_rate numeric := 18.00;
  v_is_default boolean := true;
  v_estimated_cost numeric := 0;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;

  if v_actor.role not in (
    'school_admin', 'teacher', 'executive', 'student',
    'facility_manager', 'technician'
  ) then
    raise exception 'forbidden';
  end if;

  if p_period = 'today' then
    v_start_ts := date_trunc('day', now());
  elsif p_period = 'week' then
    v_start_ts := date_trunc('week', now());
  else
    v_start_ts := date_trunc('month', now());
  end if;

  select count(distinct d.id)::integer, coalesce(sum(sr.value), 0)::numeric
  into v_device_count, v_total_m3
  from devices d
  left join sensor_readings sr on sr.device_id = d.id
    and sr.metric = 'water_m3'
    and sr.ts >= v_start_ts
  where d.school_id = v_actor.school_id
    and d.type = 'water_meter';

  select ss.water_rate_thb
  into v_school_rate
  from school_settings ss
  where ss.school_id = v_actor.school_id;

  if v_school_rate is not null then
    v_rate := v_school_rate;
    v_is_default := false;
  end if;

  v_estimated_cost := round(v_total_m3 * v_rate, 2);

  return query select
    v_device_count,
    v_total_m3,
    v_rate,
    v_is_default,
    v_estimated_cost,
    'ค่าบริการประมาณการเพื่อการบริหารจัดการภายใน ไม่ใช่ใบแจ้งหนี้จริงจากผู้ให้บริการ'::text;
end;
$$;

-- Revoke/Grant permissions
revoke all on function get_school_utility_rates(text) from public;
revoke all on function set_school_utility_rates(text, numeric, numeric) from public;
revoke all on function get_energy_usage_summary(text, text) from public;
revoke all on function get_water_usage_summary(text, text) from public;

grant execute on function get_school_utility_rates(text) to anon, authenticated;
grant execute on function set_school_utility_rates(text, numeric, numeric) to anon, authenticated;
grant execute on function get_energy_usage_summary(text, text) to anon, authenticated;
grant execute on function get_water_usage_summary(text, text) to anon, authenticated;
