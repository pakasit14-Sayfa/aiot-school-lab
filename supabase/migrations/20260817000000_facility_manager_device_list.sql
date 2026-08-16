-- =====================================================================
-- STK-9/STK-11: ผู้ดูแลอาคารสั่งงาน (queue_device_command) และควรเห็น
-- สถานะอุปกรณ์ (STK-9) ได้จริงอยู่แล้วตาม RPC ที่มี แต่ไม่เคยมีทางดึง
-- "รายชื่ออุปกรณ์ในอาคารที่รับผิดชอบ" เลยสักตัว — เพิ่ม RPC นี้ให้ สโคป
-- ตามอาคาร (BR4 "scope = อาคารที่รับผิดชอบเท่านั้น") ด้วยแพทเทิร์นเดียวกับ
-- sensor_latest ของ facility_manager ใน
-- 20260814000000_facility_manager_building_scope.sql (users.building
-- match กับ devices.location แบบ prefix)
-- =====================================================================

create or replace function list_devices_in_my_building(p_token text)
returns table (
  device_id uuid,
  name varchar,
  type device_type,
  location varchar,
  status device_status
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_building varchar;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role <> 'facility_manager' then raise exception 'forbidden'; end if;

  select building into v_building from users where id = v_actor.user_id;
  if v_building is null then
    return;
  end if;

  return query
  select d.id, d.name, d.type, d.location, d.status
  from devices d
  where d.school_id = v_actor.school_id
    and d.location like (v_building || '%')
  order by d.location, d.name;
end;
$$;

revoke all on function list_devices_in_my_building(text) from public;
grant execute on function list_devices_in_my_building(text) to anon, authenticated;
