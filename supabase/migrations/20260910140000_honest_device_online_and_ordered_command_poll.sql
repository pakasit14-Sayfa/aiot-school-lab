-- อุปกรณ์ "online" ตลอดกาล และคิวคำสั่งที่ปล่อยออกมาแบบไม่เรียงลำดับ
--
-- ตรวจกับฐานข้อมูล production เมื่อ 2026-09-10 พบสองเรื่องที่ต่อกัน:
--
-- 1) `poll_device_commands` คืนคำสั่งที่ยังไม่ถูกส่งออกไป **ทั้งหมด** ในครั้งเดียว
--    ไม่มี order by ไม่มี limit — `update ... returning` ไม่รับประกันลำดับแถว
--    ของจริงตอนล้างคิว 16 แถวออกมาสลับกันจริง (10:13:12 → 10:13:23 → 10:16:54
--    → 10:17:11 → 10:17:30 → 10:13:16 ← ย้อนกลับ)
--    บอร์ดหลุดไป 22 ชม. แล้วมีคำสั่งค้าง 16 อัน ถ้ากลับมาออนไลน์ รีเลย์จะถูก
--    สั่งรัวทั้ง 16 ครั้งโดยจบที่สถานะที่เดาไม่ได้ — วาล์วน้ำอาจค้างเปิด
--
-- 2) บรรทัด `update devices set status = 'online'` ใน poll ตัวเดิม เป็น**ที่เดียว
--    ในระบบที่เขียนคอลัมน์ status** และไม่มีโค้ดไหนตั้งกลับเป็น 'offline' เลย
--    ผลคืออุปกรณ์ทั้ง 5 ตัวบน production ยังขึ้น 'online' ทั้งที่ heartbeat
--    เงียบมา 22 ชั่วโมง — `teacher_aiot_dashboard_page.dart:208` อ่านค่านี้ตรง ๆ
--    (`isOnline: d.status == 'online'`) ครูจึงเห็นไฟเขียวของอุปกรณ์ที่ถอดปลั๊กไปแล้ว

-- ── 1. poll: เรียงตามเวลา + จำกัดจำนวน + ทิ้งคำสั่งที่เก่าเกินไป ──────────────
--
-- คำสั่งเปิด/ปิดรีเลย์ที่ค้างมาเกิน 10 นาทีถือว่าหมดอายุ ไม่ควรเอาไปสั่งย้อนหลัง
-- (คนกดปุ่มเมื่อ 22 ชม.ที่แล้วไม่ได้ตั้งใจให้ไฟติดตอนนี้) ปิดด้วย ack_status
-- 'failed' เพื่อให้เห็นในประวัติว่าเกิดอะไรขึ้น แทนที่จะลบทิ้งเงียบ ๆ
drop function if exists poll_device_commands(text, int);

create or replace function poll_device_commands(
  p_device_token text,
  p_limit int default 20
)
returns table (id uuid, command jsonb, created_at timestamptz)
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

  update devices set status = 'online', last_seen_at = now()
    where devices.id = v_device.id;  -- ต้องระบุตาราง: OUT param ชื่อ id ทับกัน

  -- หมดอายุก่อน: จะได้ไม่ถูกหยิบไปทำในรอบนี้
  update device_commands
    set delivered_at = now(),
        acked_at = now(),
        ack_status = 'failed',
        ack_detail = jsonb_build_object(
          'reason', 'expired_before_delivery',
          'age_seconds', extract(epoch from (now() - device_commands.created_at))::int
        )
  where device_commands.device_id = v_device.id
    and device_commands.delivered_at is null
    and device_commands.created_at < now() - interval '10 minutes';

  -- `update ... returning` ไม่รับประกันลำดับแถวที่คืนออกมา ต่อให้เลือก id
  -- ที่เรียงแล้วมาก่อนก็ตาม (ยืนยันด้วยเทสต์ 56 — เคสนี้ fail จริงตอนเขียน)
  -- จึงต้อง order by ที่ชั้นนอกสุดหลัง update เสร็จ
  return query
    with due as (
      select c.id
      from device_commands c
      where c.device_id = v_device.id
        and c.delivered_at is null
      order by c.created_at
      limit greatest(1, least(coalesce(p_limit, 20), 100))
    ), taken as (
      update device_commands
        set delivered_at = now()
        where device_commands.id in (select due.id from due)
        returning device_commands.id,
                  device_commands.command,
                  device_commands.created_at
    )
    select taken.id, taken.command, taken.created_at
    from taken
    order by taken.created_at;
end;
$$;

revoke all on function poll_device_commands(text, int) from public;
grant execute on function poll_device_commands(text, int) to anon, authenticated, service_role;

-- เฟิร์มแวร์เดิมเรียกแบบ 1 อาร์กิวเมนต์ — `p_limit` มีค่าตั้งต้น จึงยังเรียก
-- ได้เหมือนเดิมโดยไม่ต้องแก้โค้ดบนบอร์ด **ห้ามสร้าง overload 1 อาร์กิวเมนต์
-- แยกอีกตัว** เพราะ `poll_device_commands('token')` จะกำกวมทันที
-- (function poll_device_commands(unknown) is not unique) แล้วบอร์ดจะเรียกไม่ได้เลย
drop function if exists poll_device_commands(text);

-- ── 2. สถานะออนไลน์ต้องคิดจาก last_seen_at ไม่ใช่ค่าที่ค้างอยู่ในคอลัมน์ ───────
--
-- ไม่แตะคอลัมน์ `devices.status` (ยังใช้เก็บ 'error'/'maintenance' ที่คนตั้งเอง)
-- แต่ตอน "อ่าน" ให้ตกเป็น offline เมื่อไม่ได้ยินเสียงอุปกรณ์เกิน 5 นาที
create or replace function device_effective_status(
  p_status device_status,
  p_last_seen_at timestamptz
)
returns device_status
language sql
stable  -- ใช้ now() จึงเป็น stable ไม่ใช่ immutable
set search_path = public, extensions
as $$
  select case
    when p_status in ('error', 'maintenance') then p_status
    when p_last_seen_at is null then 'offline'::device_status
    when p_last_seen_at < now() - interval '5 minutes' then 'offline'::device_status
    else p_status
  end;
$$;

create or replace function list_school_devices(p_token text)
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
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('teacher', 'school_admin', 'executive') then
    raise exception 'forbidden';
  end if;

  return query
  select d.id, d.name, d.type, d.location,
         device_effective_status(d.status, d.last_seen_at)
  from devices d
  where d.school_id = v_actor.school_id
  order by d.location, d.name;
end;
$$;

revoke all on function list_school_devices(text) from public;
grant execute on function list_school_devices(text) to anon, authenticated;
