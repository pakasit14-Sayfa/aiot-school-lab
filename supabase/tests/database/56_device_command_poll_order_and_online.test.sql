-- คิวคำสั่งรีเลย์ต้องออกเรียงตามเวลา และ "online" ต้องหมดอายุได้
--
-- ของจริงบน production 2026-09-10: บอร์ดหลุดไป 22 ชม. มีคำสั่งค้าง 16 อัน
-- ตอนล้างคิวออกมาสลับลำดับจริง (10:13:12 → 10:13:23 → 10:16:54 → 10:17:11
-- → 10:17:30 → 10:13:16 ← ย้อนกลับ) เพราะ `update ... returning` ไม่เรียงให้
-- ถ้าบอร์ดกลับมาก่อนล้างคิว รีเลย์จะถูกสั่งรัวจนจบที่สถานะที่เดาไม่ได้
--
-- และอุปกรณ์ทั้ง 5 ตัวยังขึ้น status = 'online' ทั้งที่เงียบมา 22 ชม. เพราะ
-- ไม่มีโค้ดไหนตั้งกลับเป็น 'offline' เลยสักที่
begin;

create extension if not exists pgtap with schema extensions;
select plan(9);

insert into packages (id, name, license_type)
values ('99a10000-0000-0000-0000-000000000001', 'Device poll package', 'perpetual');

insert into schools (id, package_id, name, school_code)
values ('99a20000-0000-0000-0000-000000000001',
        '99a10000-0000-0000-0000-000000000001', 'Device poll school', 'DPS-A');

insert into users (id, school_id, email, password_hash, first_name, last_name, created_by)
values
  ('99a30000-0000-0000-0000-000000000001', '99a20000-0000-0000-0000-000000000001',
   'dps-teacher@test.local', crypt('x', gen_salt('bf')), 'Dps', 'Teacher',
   '99a30000-0000-0000-0000-000000000001');

insert into user_roles (user_id, role, school_id, granted_by)
values ('99a30000-0000-0000-0000-000000000001', 'teacher',
        '99a20000-0000-0000-0000-000000000001', '99a30000-0000-0000-0000-000000000001');

insert into sessions (id, user_id, active_role, active_school_id, token_hash, expires_at)
values ('99a40000-0000-0000-0000-000000000001', '99a30000-0000-0000-0000-000000000001',
        'teacher', '99a20000-0000-0000-0000-000000000001',
        encode(digest('dps-teacher-token', 'sha256'), 'hex'), now() + interval '1 hour');

-- อุปกรณ์ 3 ตัว: ตัวที่เพิ่งคุย · ตัวที่เงียบไปนาน · ตัวที่ไม่เคยคุยเลย
-- ทั้งสามตั้ง status = 'online' ค้างไว้ เหมือนของจริงบน production
insert into devices (
  id, school_id, type, name, status, token_hash, last_seen_at, registered_by
) values
  ('99a50000-0000-0000-0000-000000000001', '99a20000-0000-0000-0000-000000000001',
   'relay', 'รีเลย์สด', 'online',
   encode(digest('dps-device-token', 'sha256'), 'hex'),
   now() - interval '30 seconds', '99a30000-0000-0000-0000-000000000001'),
  ('99a50000-0000-0000-0000-000000000002', '99a20000-0000-0000-0000-000000000001',
   'relay', 'รีเลย์เงียบ', 'online', null,
   now() - interval '22 hours', '99a30000-0000-0000-0000-000000000001'),
  ('99a50000-0000-0000-0000-000000000003', '99a20000-0000-0000-0000-000000000001',
   'relay', 'รีเลย์ไม่เคยคุย', 'online', null,
   null, '99a30000-0000-0000-0000-000000000001');

-- ── สถานะออนไลน์ ────────────────────────────────────────────────────────────
select is(
  (select status::text from list_school_devices('dps-teacher-token')
    where name = 'รีเลย์สด'),
  'online',
  'อุปกรณ์ที่เพิ่งคุยเมื่อ 30 วินาทีที่แล้ว ยังเป็น online'
);

select is(
  (select status::text from list_school_devices('dps-teacher-token')
    where name = 'รีเลย์เงียบ'),
  'offline',
  'อุปกรณ์ที่เงียบมา 22 ชม. ต้องเป็น offline ไม่ใช่ online ค้างตลอดกาล'
);

select is(
  (select status::text from list_school_devices('dps-teacher-token')
    where name = 'รีเลย์ไม่เคยคุย'),
  'offline',
  'อุปกรณ์ที่ไม่เคยรายงานตัวเลย ต้องไม่ขึ้น online'
);

-- ผู้ดูแลตั้ง 'maintenance'/'error' เอง ต้องไม่ถูกกลบด้วยกฎเวลา
update devices set status = 'maintenance'
  where id = '99a50000-0000-0000-0000-000000000002';
select is(
  (select status::text from list_school_devices('dps-teacher-token')
    where name = 'รีเลย์เงียบ'),
  'maintenance',
  'สถานะที่คนตั้งเอง (maintenance) ต้องไม่ถูกกฎ last_seen_at กลบ'
);

-- ── ลำดับคิวคำสั่ง ──────────────────────────────────────────────────────────
-- ใส่แบบสลับลำดับตั้งใจ: แถวที่ created_at เก่าที่สุดถูก insert เป็นลำดับที่ 3
insert into device_commands (device_id, command, created_by, created_at) values
  ('99a50000-0000-0000-0000-000000000001', '{"relay": 1, "state": "ON"}',
   '99a30000-0000-0000-0000-000000000001', now() - interval '3 minutes'),
  ('99a50000-0000-0000-0000-000000000001', '{"relay": 1, "state": "OFF"}',
   '99a30000-0000-0000-0000-000000000001', now() - interval '1 minute'),
  ('99a50000-0000-0000-0000-000000000001', '{"relay": 2, "state": "ON"}',
   '99a30000-0000-0000-0000-000000000001', now() - interval '5 minutes');

select is(
  (select array_agg(created_at order by ordinality)
     from poll_device_commands('dps-device-token') with ordinality),
  (select array_agg(created_at order by created_at)
     from device_commands where device_id = '99a50000-0000-0000-0000-000000000001'),
  'คำสั่งต้องออกมาเรียงตาม created_at ไม่ใช่ลำดับที่ฐานข้อมูลบังเอิญคืนมา'
);

select is(
  (select count(*)::int from device_commands
    where device_id = '99a50000-0000-0000-0000-000000000001'
      and delivered_at is null),
  0,
  'คำสั่งที่ถูกดึงไปแล้วต้องถูกทำเครื่องหมายว่าส่งออกแล้ว'
);

-- ── จำกัดจำนวนต่อรอบ ────────────────────────────────────────────────────────
insert into device_commands (device_id, command, created_by, created_at)
select '99a50000-0000-0000-0000-000000000001',
       jsonb_build_object('relay', 1, 'state', 'ON'),
       '99a30000-0000-0000-0000-000000000001',
       now() - (i || ' seconds')::interval
from generate_series(1, 30) i;

select is(
  (select count(*)::int from poll_device_commands('dps-device-token', 5)),
  5,
  'ขอมา 5 ต้องได้ 5 ไม่ใช่เทคิวทั้งหมดออกมารวดเดียว'
);

select is(
  (select count(*)::int from poll_device_commands('dps-device-token')),
  20,
  'ไม่ระบุจำนวน ต้องได้ค่าตั้งต้น 20 ไม่ใช่ทั้งคิว'
);

-- ── คำสั่งที่ค้างเกิน 10 นาที ต้องหมดอายุ ไม่ใช่เอาไปสั่งย้อนหลัง ─────────────
-- เคสจริง: คนกดปิดไฟเมื่อ 22 ชม.ที่แล้ว บอร์ดเพิ่งกลับมาออนไลน์ตอนนี้
insert into device_commands (device_id, command, created_by, created_at)
values ('99a50000-0000-0000-0000-000000000001', '{"relay": 4, "state": "ON"}',
        '99a30000-0000-0000-0000-000000000001', now() - interval '22 hours');

select is(
  (select count(*)::int from poll_device_commands('dps-device-token')
    where command->>'relay' = '4'),
  0,
  'คำสั่งที่ค้างมา 22 ชม. ต้องไม่ถูกส่งไปสั่งรีเลย์ย้อนหลัง'
);

select * from finish();
rollback;
