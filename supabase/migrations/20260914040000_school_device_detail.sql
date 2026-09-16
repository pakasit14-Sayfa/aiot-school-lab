-- รายละเอียดอุปกรณ์รายตัวสำหรับหน้าแอดมินโรงเรียน (2026-09-14)
--
-- list_school_devices คืนแค่ id/name/type/location/status หน้าอุปกรณ์จึงต้อง
-- ขึ้น "ข้อมูลที่ระบบยังไม่ได้เก็บ" สำหรับ serial / ห้อง / IP / เฟิร์มแวร์ /
-- ตอบสนองล่าสุด — ทั้งที่คอลัมน์พวกนั้นมีใน devices และ firmware อัปเดตผ่าน
-- poll_device_commands อยู่แล้ว RPC นี้คืนทั้งแถวในขอบเขตโรงเรียน (ไม่คืน
-- token_hash) ค่าที่ยังไม่มีคือ null ให้หน้าบอกว่า "ยังไม่มีข้อมูล" ตรงตามจริง
-- ค่าเริ่มต้นปลอมในสคีมา (20260823080000): อุปกรณ์ทุกตัวที่ลงทะเบียนได้
-- ip_address '192.168.1.100' และ firmware_version 'v1.2.0-prod' ทันทีโดยไม่เคย
-- รายงานอะไร — ค่าจริงมาจาก record_device_heartbeat เท่านั้น ถอด default และ
-- ล้างค่าของอุปกรณ์ที่ไม่เคยส่ง heartbeat เลย (ตัวที่เคยส่ง เก็บไว้ตามที่รายงาน)
alter table public.devices alter column ip_address drop default;
alter table public.devices alter column firmware_version drop default;

update public.devices d
set ip_address = case when d.ip_address = '192.168.1.100' then null else d.ip_address end,
    firmware_version = case when d.firmware_version = 'v1.2.0-prod' then null else d.firmware_version end
where (d.ip_address = '192.168.1.100' or d.firmware_version = 'v1.2.0-prod')
  and not exists (select 1 from public.device_heartbeats h where h.device_id = d.id);

create or replace function get_school_device_detail(p_token text, p_device_id uuid)
returns table (
  id uuid,
  name varchar,
  type device_type,
  status device_status,
  effective_status device_status,
  serial_no varchar,
  device_code text,
  kit_code varchar,
  category_code text,
  location varchar,
  building text,
  room text,
  ip_address text,
  firmware_version text,
  last_seen_at timestamptz,
  registered_at timestamptz,
  updated_at timestamptz,
  parent_device_id uuid,
  relay_no smallint
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
  if v_actor.role not in ('school_admin', 'super_admin', 'teacher', 'executive') then
    raise exception 'forbidden';
  end if;

  return query
    select d.id, d.name, d.type, d.status,
           device_effective_status(d.status, d.last_seen_at),
           d.serial_no, d.device_code, d.kit_code, d.category_code,
           d.location, d.building, d.room,
           d.ip_address, d.firmware_version, d.last_seen_at,
           d.registered_at, d.updated_at, d.parent_device_id, d.relay_no
    from devices d
    where d.id = p_device_id
      and (v_actor.role = 'super_admin' or d.school_id = v_actor.school_id);
end;
$$;

revoke all on function get_school_device_detail(text, uuid) from public;
grant execute on function get_school_device_detail(text, uuid) to anon, authenticated, service_role;
