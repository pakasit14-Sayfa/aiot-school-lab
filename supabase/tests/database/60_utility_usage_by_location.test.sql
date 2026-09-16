-- get_utility_usage_by_location (20260914030000): แยกไฟฟ้า/น้ำรายอาคาร/ห้อง
begin;

create extension if not exists pgtap with schema extensions;
select plan(6);

insert into packages (id, name, license_type)
values ('60100000-0000-0000-0000-000000000001', 'Utility package', 'perpetual');
insert into schools (id, package_id, name, school_code) values
  ('60200000-0000-0000-0000-000000000001', '60100000-0000-0000-0000-000000000001', 'Utility school A', 'UTL-A'),
  ('60200000-0000-0000-0000-000000000002', '60100000-0000-0000-0000-000000000001', 'Utility school B', 'UTL-B');
insert into users (id, school_id, email, password_hash, first_name, last_name, created_by) values
  ('60500000-0000-0000-0000-000000000001', '60200000-0000-0000-0000-000000000001',
   'utl-admin-a@pdpa.test', crypt('x', gen_salt('bf')), 'Admin', 'A', '60500000-0000-0000-0000-000000000001'),
  ('60500000-0000-0000-0000-000000000002', '60200000-0000-0000-0000-000000000001',
   'utl-student-a@pdpa.test', crypt('x', gen_salt('bf')), 'Student', 'A', '60500000-0000-0000-0000-000000000001');
insert into user_roles (user_id, role, school_id, granted_by) values
  ('60500000-0000-0000-0000-000000000001', 'school_admin', '60200000-0000-0000-0000-000000000001', '60500000-0000-0000-0000-000000000001'),
  ('60500000-0000-0000-0000-000000000002', 'student',      '60200000-0000-0000-0000-000000000001', '60500000-0000-0000-0000-000000000001');
insert into sessions (user_id, active_role, active_school_id, token_hash, expires_at) values
  ('60500000-0000-0000-0000-000000000001', 'school_admin', '60200000-0000-0000-0000-000000000001',
   encode(digest('utl-admin-a', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('60500000-0000-0000-0000-000000000002', 'student', '60200000-0000-0000-0000-000000000001',
   encode(digest('utl-student-a', 'sha256'), 'hex'), now() + interval '1 hour');

insert into devices (id, school_id, type, name, building, room, status, registered_by) values
  ('60800000-0000-0000-0000-000000000001', '60200000-0000-0000-0000-000000000001', 'energy_meter', 'มิเตอร์ 101', 'อาคาร 1', 'ห้อง 101', 'online', '60500000-0000-0000-0000-000000000001'),
  ('60800000-0000-0000-0000-000000000002', '60200000-0000-0000-0000-000000000001', 'energy_meter', 'มิเตอร์ 201', 'อาคาร 2', null, 'online', '60500000-0000-0000-0000-000000000001'),
  ('60800000-0000-0000-0000-000000000003', '60200000-0000-0000-0000-000000000002', 'energy_meter', 'มิเตอร์ B', 'อาคาร B', null, 'online', '60500000-0000-0000-0000-000000000001');
insert into sensor_readings (device_id, metric, ts, value) values
  ('60800000-0000-0000-0000-000000000001', 'energy_kwh', now() - interval '1 day', 10),
  ('60800000-0000-0000-0000-000000000001', 'energy_kwh', now() - interval '2 day', 5),
  ('60800000-0000-0000-0000-000000000001', 'energy_kwh', now() - interval '40 day', 100),
  ('60800000-0000-0000-0000-000000000002', 'energy_kwh', now() - interval '1 day', 7),
  ('60800000-0000-0000-0000-000000000003', 'energy_kwh', now() - interval '1 day', 999);

select is((select total from get_utility_usage_by_location('utl-admin-a', 'energy_kwh', 30) where building='อาคาร 1'),
  15.00, 'รวมเฉพาะค่าอ่านในช่วง 30 วัน (100 ที่เก่ากว่าถูกตัดออก)');
select is((select room from get_utility_usage_by_location('utl-admin-a', 'energy_kwh', 30) where building='อาคาร 2'),
  'ยังไม่ระบุ', 'อุปกรณ์ที่ไม่ระบุห้องอยู่ในกลุ่ม "ยังไม่ระบุ" ไม่หายไป');
select is((select count(*)::int from get_utility_usage_by_location('utl-admin-a', 'energy_kwh', 30) where building='อาคาร B'),
  0, 'อาคารของโรงเรียนอื่นไม่หลุดมา');
select is((select count(*)::int from get_utility_usage_by_location('utl-admin-a', 'water_m3', 30)),
  0, 'ไม่มีมิเตอร์น้ำ = ไม่มีแถว ไม่ใช่ตัวเลขปลอม');
select throws_ok($$ select * from get_utility_usage_by_location('utl-admin-a', 'pm25', 30) $$,
  'invalid_metric', 'metric ที่ไม่ใช่ไฟฟ้า/น้ำถูกปฏิเสธ');
select throws_ok($$ select * from get_utility_usage_by_location('utl-student-a', 'energy_kwh', 30) $$,
  'forbidden', 'นักเรียนเรียกไม่ได้');

select * from finish();
rollback;
