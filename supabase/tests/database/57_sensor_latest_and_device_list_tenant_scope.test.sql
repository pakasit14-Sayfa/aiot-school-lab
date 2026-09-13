-- sensor_latest / list_school_devices: ขอบเขตระดับโรงเรียน
--
-- แทนที่ 14_facility_manager_building_scope และ 16_facility_manager_device_list
-- ซึ่งล้มทุกครั้งตั้งแต่ 2026-08-25 (`invalid input value for enum role_type:
-- "facility_manager"`) — role นั้นถูกรวมเข้า school_admin, การ scope ตามอาคาร
-- ถูกถอดออกจาก sensor_latest และ list_devices_in_my_building ถูก rename เป็น
-- list_school_devices ทั้ง 2 ไฟล์จึงทดสอบพฤติกรรมที่ไม่มีอยู่แล้ว ไม่ใช่ระบบพัง
--
-- แต่ถ้าลบเฉย ๆ sensor_latest (ที่ realtime_service / aiot_lab_service เรียก
-- ทุกหน้าที่โชว์ค่าเซนเซอร์) จะไม่มี pgTAP คุมเลย ไฟล์นี้ล็อกสัญญาปัจจุบัน:
-- เห็นเฉพาะอุปกรณ์ในโรงเรียนตัวเอง · ค่าที่คืนคือค่าล่าสุดจริง · ระบุ device_id
-- ของโรงเรียนอื่นแล้วต้องได้ว่าง ไม่ใช่รั่ว
begin;

create extension if not exists pgtap with schema extensions;
select plan(11);

insert into packages (id, name, license_type)
values ('57100000-0000-0000-0000-000000000001', 'Sensor scope package', 'perpetual');

insert into schools (id, package_id, name, school_code) values
  ('57200000-0000-0000-0000-000000000001', '57100000-0000-0000-0000-000000000001', 'Sensor school A', 'SENSOR-A'),
  ('57200000-0000-0000-0000-000000000002', '57100000-0000-0000-0000-000000000001', 'Sensor school B', 'SENSOR-B');

insert into users (id, school_id, email, password_hash, first_name, last_name, created_by) values
  ('57500000-0000-0000-0000-000000000001', '57200000-0000-0000-0000-000000000001',
   'sensor-admin-a@pdpa.test', crypt('x', gen_salt('bf')), 'Admin', 'A',
   '57500000-0000-0000-0000-000000000001'),
  ('57500000-0000-0000-0000-000000000002', '57200000-0000-0000-0000-000000000001',
   'sensor-teacher-a@pdpa.test', crypt('x', gen_salt('bf')), 'Teacher', 'A',
   '57500000-0000-0000-0000-000000000001'),
  ('57500000-0000-0000-0000-000000000003', '57200000-0000-0000-0000-000000000002',
   'sensor-admin-b@pdpa.test', crypt('x', gen_salt('bf')), 'Admin', 'B',
   '57500000-0000-0000-0000-000000000003');

insert into user_roles (user_id, role, school_id, granted_by) values
  ('57500000-0000-0000-0000-000000000001', 'school_admin', '57200000-0000-0000-0000-000000000001', '57500000-0000-0000-0000-000000000001'),
  ('57500000-0000-0000-0000-000000000002', 'teacher',      '57200000-0000-0000-0000-000000000001', '57500000-0000-0000-0000-000000000001'),
  ('57500000-0000-0000-0000-000000000003', 'school_admin', '57200000-0000-0000-0000-000000000002', '57500000-0000-0000-0000-000000000003');

insert into sessions (user_id, active_role, active_school_id, token_hash, expires_at) values
  ('57500000-0000-0000-0000-000000000001', 'school_admin', '57200000-0000-0000-0000-000000000001',
   encode(digest('sensor-admin-a-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('57500000-0000-0000-0000-000000000002', 'teacher', '57200000-0000-0000-0000-000000000001',
   encode(digest('sensor-teacher-a-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('57500000-0000-0000-0000-000000000003', 'school_admin', '57200000-0000-0000-0000-000000000002',
   encode(digest('sensor-admin-b-token', 'sha256'), 'hex'), now() + interval '1 hour');

-- โรงเรียน A: เซนเซอร์ PM2.5 (มี 2 ค่า เก่า/ใหม่) + รีเลย์ (ไม่มีค่าอ่าน)
-- โรงเรียน B: เซนเซอร์ PM2.5 1 ตัว 1 ค่า
insert into devices (id, school_id, type, name, location, status, registered_by) values
  ('57600000-0000-0000-0000-000000000001', '57200000-0000-0000-0000-000000000001',
   'pm25_sensor', 'PM2.5 ห้อง 101', 'อาคาร 1 ชั้น 1', 'online', '57500000-0000-0000-0000-000000000001'),
  ('57600000-0000-0000-0000-000000000002', '57200000-0000-0000-0000-000000000001',
   'relay', 'ไฟห้อง 101', 'อาคาร 1 ชั้น 1', 'offline', '57500000-0000-0000-0000-000000000001'),
  ('57600000-0000-0000-0000-000000000003', '57200000-0000-0000-0000-000000000002',
   'pm25_sensor', 'PM2.5 โรงเรียน B', 'อาคาร B', 'online', '57500000-0000-0000-0000-000000000003');

insert into sensor_readings (device_id, metric, ts, value) values
  ('57600000-0000-0000-0000-000000000001', 'pm25', now() - interval '10 minutes', 12.0),
  ('57600000-0000-0000-0000-000000000001', 'pm25', now(), 45.5),
  ('57600000-0000-0000-0000-000000000003', 'pm25', now(), 88.0);

-- ── sensor_latest ────────────────────────────────────────────────────────

-- 1. school_admin A เห็นแถวเดียว: PM2.5 ของ A (รีเลย์ไม่มีค่าอ่าน, ของ B ไม่เห็น)
select is(
  (select count(*)::int from sensor_latest('sensor-admin-a-token')),
  1,
  'school_admin เห็นเฉพาะอุปกรณ์ที่มีค่าอ่านในโรงเรียนตัวเอง'
);

-- 2. และค่าที่ได้คือค่าล่าสุด ไม่ใช่ค่าแรกที่เจอ
select is(
  (select value from sensor_latest('sensor-admin-a-token')),
  45.5::numeric,
  'ค่าที่คืนคือค่าอ่านล่าสุดตาม ts ไม่ใช่ค่าเก่า'
);

-- 3. ครูในโรงเรียนเดียวกันเห็นเท่ากัน (role ที่อนุญาต)
select is(
  (select count(*)::int from sensor_latest('sensor-teacher-a-token')),
  1,
  'teacher เรียก sensor_latest ได้และเห็นขอบเขตเดียวกับโรงเรียนตัวเอง'
);

-- 4. school_admin B เห็นเฉพาะของ B
select is(
  (select device_id from sensor_latest('sensor-admin-b-token')),
  '57600000-0000-0000-0000-000000000003'::uuid,
  'school_admin ของอีกโรงเรียนเห็นเฉพาะอุปกรณ์ของโรงเรียนตัวเอง'
);

-- 5. ระบุ device_id ของโรงเรียนอื่นตรง ๆ ต้องได้ว่าง — ไม่ใช่รั่วเพราะรู้ id
select is(
  (select count(*)::int
     from sensor_latest('sensor-admin-a-token', '57600000-0000-0000-0000-000000000003')),
  0,
  'ระบุ device_id ของโรงเรียนอื่นแล้วต้องได้ 0 แถว ไม่ใช่ข้อมูลของเขา'
);

-- 6. ระบุ device_id ของตัวเองแล้วกรองได้จริง
select is(
  (select device_id
     from sensor_latest('sensor-admin-a-token', '57600000-0000-0000-0000-000000000001')),
  '57600000-0000-0000-0000-000000000001'::uuid,
  'ระบุ device_id ของโรงเรียนตัวเองแล้วได้อุปกรณ์นั้น'
);

-- 7. token ปลอม/หมดอายุ ต้องล้มดัง ๆ
select throws_ok(
  $$ select * from sensor_latest('no-such-token') $$,
  'invalid_session',
  'sensor_latest ปฏิเสธ session ที่ไม่มีอยู่'
);

-- ── list_school_devices ──────────────────────────────────────────────────

-- 8. A เห็นอุปกรณ์ทั้ง 2 ของตัวเอง (ทั้งเซนเซอร์และรีเลย์ ไม่ว่าจะมีค่าอ่านไหม)
select is(
  (select count(*)::int from list_school_devices('sensor-admin-a-token')),
  2,
  'list_school_devices คืนอุปกรณ์ทุกชนิดของโรงเรียนตัวเอง'
);

-- 9. และไม่มีของ B ปนมา
select is(
  (select count(*)::int from list_school_devices('sensor-admin-a-token')
    where device_id = '57600000-0000-0000-0000-000000000003'),
  0,
  'อุปกรณ์ของโรงเรียนอื่นต้องไม่หลุดมาในรายการ'
);

-- 10. B เห็นของ B ตัวเดียว
select is(
  (select count(*)::int from list_school_devices('sensor-admin-b-token')),
  1,
  'โรงเรียน B เห็นอุปกรณ์ของตัวเองตัวเดียว'
);

-- 11. token ปลอม
select throws_ok(
  $$ select * from list_school_devices('no-such-token') $$,
  'invalid_session',
  'list_school_devices ปฏิเสธ session ที่ไม่มีอยู่'
);

select * from finish();
rollback;
