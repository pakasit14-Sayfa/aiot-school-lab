-- update/delete อาคาร-ห้อง · ผู้รับผิดชอบอาคาร · แก้อุปกรณ์ · รับทราบทั้งหมด ·
-- สร้างปีการศึกษา/ภาคเรียน (20260914010000) — ล็อกขอบเขตโรงเรียน + กฎที่ raise
begin;

create extension if not exists pgtap with schema extensions;
select plan(23);

insert into packages (id, name, license_type)
values ('58100000-0000-0000-0000-000000000001', 'Assets package', 'perpetual');

insert into schools (id, package_id, name, school_code) values
  ('58200000-0000-0000-0000-000000000001', '58100000-0000-0000-0000-000000000001', 'Assets school A', 'AST-A'),
  ('58200000-0000-0000-0000-000000000002', '58100000-0000-0000-0000-000000000001', 'Assets school B', 'AST-B');

insert into users (id, school_id, email, password_hash, first_name, last_name, created_by) values
  ('58500000-0000-0000-0000-000000000001', '58200000-0000-0000-0000-000000000001',
   'ast-admin-a@pdpa.test', crypt('x', gen_salt('bf')), 'Admin', 'A', '58500000-0000-0000-0000-000000000001'),
  ('58500000-0000-0000-0000-000000000002', '58200000-0000-0000-0000-000000000001',
   'ast-teacher-a@pdpa.test', crypt('x', gen_salt('bf')), 'Teacher', 'A', '58500000-0000-0000-0000-000000000001'),
  ('58500000-0000-0000-0000-000000000003', '58200000-0000-0000-0000-000000000002',
   'ast-admin-b@pdpa.test', crypt('x', gen_salt('bf')), 'Admin', 'B', '58500000-0000-0000-0000-000000000003');

insert into user_roles (user_id, role, school_id, granted_by) values
  ('58500000-0000-0000-0000-000000000001', 'school_admin', '58200000-0000-0000-0000-000000000001', '58500000-0000-0000-0000-000000000001'),
  ('58500000-0000-0000-0000-000000000002', 'teacher',      '58200000-0000-0000-0000-000000000001', '58500000-0000-0000-0000-000000000001'),
  ('58500000-0000-0000-0000-000000000003', 'school_admin', '58200000-0000-0000-0000-000000000002', '58500000-0000-0000-0000-000000000003');

insert into sessions (user_id, active_role, active_school_id, token_hash, expires_at) values
  ('58500000-0000-0000-0000-000000000001', 'school_admin', '58200000-0000-0000-0000-000000000001',
   encode(digest('ast-admin-a', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('58500000-0000-0000-0000-000000000002', 'teacher', '58200000-0000-0000-0000-000000000001',
   encode(digest('ast-teacher-a', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('58500000-0000-0000-0000-000000000003', 'school_admin', '58200000-0000-0000-0000-000000000002',
   encode(digest('ast-admin-b', 'sha256'), 'hex'), now() + interval '1 hour');

insert into buildings (id, school_id, name, code, floors) values
  ('58600000-0000-0000-0000-000000000001', '58200000-0000-0000-0000-000000000001', 'อาคาร 1', 'B1', 2),
  ('58600000-0000-0000-0000-000000000002', '58200000-0000-0000-0000-000000000001', 'อาคาร 2', 'B2', 1),
  ('58600000-0000-0000-0000-000000000009', '58200000-0000-0000-0000-000000000002', 'อาคาร B', 'BB', 1);

insert into rooms (id, school_id, building_id, name, code) values
  ('58700000-0000-0000-0000-000000000001', '58200000-0000-0000-0000-000000000001',
   '58600000-0000-0000-0000-000000000001', 'ห้อง 101', 'R101');

insert into devices (id, school_id, type, name, location, room, status, registered_by) values
  ('58800000-0000-0000-0000-000000000001', '58200000-0000-0000-0000-000000000001',
   'pm25_sensor', 'PM2.5 101', 'อาคาร 1', 'ห้อง 101', 'online', '58500000-0000-0000-0000-000000000001'),
  ('58800000-0000-0000-0000-000000000002', '58200000-0000-0000-0000-000000000002',
   'pm25_sensor', 'PM2.5 B', 'อาคาร B', null, 'online', '58500000-0000-0000-0000-000000000003');

-- ── อาคาร ──
select lives_ok(
  $$ select update_school_building('ast-admin-a', '58600000-0000-0000-0000-000000000001', 'อาคารวิทย์', 'SCI', 3, 'ปรับปรุง 2569') $$,
  'school_admin แก้อาคารของโรงเรียนตัวเองได้');
select is((select name||'/'||code||'/'||floors from buildings where id='58600000-0000-0000-0000-000000000001'),
  'อาคารวิทย์/SCI/3', 'ค่าที่แก้ถูกเขียนลงจริง');
select throws_ok(
  $$ select update_school_building('ast-admin-a', '58600000-0000-0000-0000-000000000001', 'x', 'B2') $$,
  'duplicate_code', 'รหัสอาคารซ้ำกับอาคารอื่นในโรงเรียนเดียวกันต้องถูกปฏิเสธ');
select throws_ok(
  $$ select update_school_building('ast-admin-b', '58600000-0000-0000-0000-000000000001', 'hack', 'H') $$,
  'forbidden', 'แอดมินโรงเรียนอื่นแก้อาคารของเราไม่ได้');
select throws_ok(
  $$ select update_school_building('ast-teacher-a', '58600000-0000-0000-0000-000000000001', 'x', 'Y') $$,
  'forbidden', 'ครูแก้อาคารไม่ได้');
select throws_ok(
  $$ select delete_school_building('ast-admin-a', '58600000-0000-0000-0000-000000000001') $$,
  'building_has_rooms', 'ลบอาคารที่ยังมีห้องไม่ได้');
select lives_ok(
  $$ select delete_school_building('ast-admin-a', '58600000-0000-0000-0000-000000000002') $$,
  'ลบอาคารว่างได้');
select is((select count(*)::int from buildings where id='58600000-0000-0000-0000-000000000002'), 0, 'อาคารหายจริง');

-- ── ผู้รับผิดชอบอาคาร ──
select lives_ok(
  $$ select set_school_building_manager('ast-admin-a', '58600000-0000-0000-0000-000000000001', 'ครูสมศักดิ์') $$,
  'กำหนดผู้รับผิดชอบอาคารได้');
select is((select manager_name from list_school_buildings('ast-admin-a') where id='58600000-0000-0000-0000-000000000001'),
  'ครูสมศักดิ์', 'list_school_buildings อ่านผู้รับผิดชอบที่ตั้งกลับมาได้');

-- ── ห้อง ──
select throws_ok(
  $$ select delete_school_room('ast-admin-a', '58700000-0000-0000-0000-000000000001') $$,
  'room_has_devices', 'ลบห้องที่ยังมีอุปกรณ์อ้างถึงไม่ได้');
select lives_ok(
  $$ select update_school_room('ast-admin-a', '58700000-0000-0000-0000-000000000001', 'ห้องแล็บ', 'LAB1', '2', 'ห้องปฏิบัติการ', 35) $$,
  'แก้ห้องได้');
select is((select name||'/'||code||'/'||floor||'/'||capacity from rooms where id='58700000-0000-0000-0000-000000000001'),
  'ห้องแล็บ/LAB1/2/35', 'ค่าห้องที่แก้ถูกเขียนลงจริง');

-- ── อุปกรณ์ ──
select lives_ok(
  $$ select update_school_device('ast-admin-a', '58800000-0000-0000-0000-000000000001', 'PM2.5 แล็บ', 'อาคารวิทย์', 'อาคารวิทย์', 'ห้องแล็บ', 'maintenance') $$,
  'แก้อุปกรณ์ของโรงเรียนตัวเองได้');
select is((select name||'/'||status from devices where id='58800000-0000-0000-0000-000000000001'),
  'PM2.5 แล็บ/maintenance', 'ค่าอุปกรณ์ที่แก้ถูกเขียนลงจริง');
select throws_ok(
  $$ select update_school_device('ast-admin-a', '58800000-0000-0000-0000-000000000002', 'hack') $$,
  'forbidden', 'แก้อุปกรณ์ของโรงเรียนอื่นไม่ได้');

-- ── รายละเอียดอุปกรณ์ (20260914040000) ──
select is((select firmware_version from get_school_device_detail('ast-admin-a', '58800000-0000-0000-0000-000000000001')),
  null, 'ค่าที่อุปกรณ์ยังไม่เคยรายงานคืนเป็น null ไม่ใช่ค่าแต่ง');
select is((select room from get_school_device_detail('ast-admin-a', '58800000-0000-0000-0000-000000000001')),
  'ห้องแล็บ', 'คืนห้องที่เก็บไว้จริง (หลัง update_school_device)');
select is((select count(*)::int from get_school_device_detail('ast-admin-a', '58800000-0000-0000-0000-000000000002')),
  0, 'อุปกรณ์ของโรงเรียนอื่นมองไม่เห็น');

-- ── รับทราบทั้งหมด ──
insert into thresholds (id, school_id, device_id, metric, max_value, is_active, created_by) values
  ('58900000-0000-0000-0000-000000000001', '58200000-0000-0000-0000-000000000001',
   '58800000-0000-0000-0000-000000000001', 'pm25', 50, true, '58500000-0000-0000-0000-000000000001'),
  ('58900000-0000-0000-0000-000000000002', '58200000-0000-0000-0000-000000000002',
   '58800000-0000-0000-0000-000000000002', 'pm25', 50, true, '58500000-0000-0000-0000-000000000003');
insert into sensor_alerts (threshold_id, device_id, metric, value, status) values
  ('58900000-0000-0000-0000-000000000001', '58800000-0000-0000-0000-000000000001', 'pm25', 90, 'new'),
  ('58900000-0000-0000-0000-000000000001', '58800000-0000-0000-0000-000000000001', 'pm25', 95, 'new'),
  ('58900000-0000-0000-0000-000000000002', '58800000-0000-0000-0000-000000000002', 'pm25', 99, 'new');
select is(acknowledge_all_school_alerts('ast-admin-a'), 2,
  'รับทราบเฉพาะแจ้งเตือนของโรงเรียนตัวเอง (2 จาก 3)');
select is((select count(*)::int from sensor_alerts a join devices d on d.id=a.device_id
           where d.school_id='58200000-0000-0000-0000-000000000002' and a.status='new'), 1,
  'แจ้งเตือนของโรงเรียนอื่นยังเป็น new');

-- ── ปีการศึกษา / ภาคเรียน ──
select lives_ok(
  $$ select create_term('ast-admin-a', create_academic_year('ast-admin-a', '2569', '2026-05-16', '2027-03-31'), 'ภาคเรียนที่ 1/2569', '2026-05-16', '2026-10-10') $$,
  'สร้างปีการศึกษาแล้วสร้างภาคเรียนใต้ปีนั้นได้');
select is((select terms_count::int from list_academic_years('ast-admin-a') where name='2569'), 1,
  'list_academic_years นับภาคเรียนใต้ปีได้');

select * from finish();
rollback;
