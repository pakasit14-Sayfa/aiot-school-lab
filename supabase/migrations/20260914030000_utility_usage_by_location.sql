-- การใช้ไฟฟ้า/น้ำ แยกรายอาคาร/ห้อง (2026-09-14)
--
-- หน้า "การใช้ทรัพยากร" ของแอดมินโรงเรียนมีตัวกรองอาคาร/ห้องที่ถูกปิดไว้
-- เพราะ RPC เดิม (get_energy_usage_trend / get_water_usage_trend) รวมทั้ง
-- โรงเรียน ทั้งที่ devices.building / devices.room มีอยู่แล้ว — RPC นี้ใช้
-- สูตรเดียวกับ trend เดิม (sum ของ readings ต่ออุปกรณ์ในช่วง) แต่ group ตาม
-- ที่ตั้ง อุปกรณ์ที่ยังไม่ระบุอาคาร/ห้องรวมไว้ในกลุ่ม "ยังไม่ระบุ" ไม่ทิ้ง
create or replace function get_utility_usage_by_location(
  p_token text,
  p_metric text,           -- 'energy_kwh' | 'water_m3'
  p_days int default 30
)
returns table (
  building text,
  room text,
  device_count bigint,
  total numeric
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_metric metric_type;
  v_type device_type;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('school_admin', 'executive', 'super_admin') then
    raise exception 'forbidden';
  end if;
  if v_actor.school_id is null then raise exception 'no_active_school'; end if;

  if p_metric = 'energy_kwh' then
    v_metric := 'energy_kwh'; v_type := 'energy_meter';
  elsif p_metric = 'water_m3' then
    v_metric := 'water_m3'; v_type := 'water_meter';
  else
    raise exception 'invalid_metric';
  end if;
  if p_days is null or p_days < 1 or p_days > 366 then
    raise exception 'invalid_days';
  end if;

  return query
  select
    coalesce(nullif(btrim(d.building), ''), 'ยังไม่ระบุ') as building,
    coalesce(nullif(btrim(d.room), ''), 'ยังไม่ระบุ') as room,
    count(distinct d.id) as device_count,
    round(coalesce(sum(sr.value), 0), 2) as total
  from devices d
  left join sensor_readings sr
    on sr.device_id = d.id
   and sr.metric = v_metric
   and sr.ts >= now() - (p_days || ' days')::interval
  where d.school_id = v_actor.school_id
    and d.type = v_type
  group by 1, 2
  order by 1, 2;
end;
$$;

revoke all on function get_utility_usage_by_location(text, text, int) from public;
grant execute on function get_utility_usage_by_location(text, text, int) to anon, authenticated, service_role;
