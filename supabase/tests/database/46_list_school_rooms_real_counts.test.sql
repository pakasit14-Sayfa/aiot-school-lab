begin;

create extension if not exists pgtap with schema extensions;
select plan(5);

insert into packages (id, name, license_type)
values ('98600000-0000-0000-0000-000000000001', 'Rooms real counts test package', 'perpetual');

insert into schools (id, package_id, name, school_code)
values ('98600000-0000-0000-0000-000000000002', '98600000-0000-0000-0000-000000000001', 'Rooms real counts school', 'ROOM-A');

insert into users (
  id, school_id, email, password_hash, first_name, last_name, created_by
) values (
  '98600000-0000-0000-0000-000000000003', '98600000-0000-0000-0000-000000000002',
  'room-admin@pdpa.test', crypt('irrelevant', gen_salt('bf')), 'Admin', 'A',
  '98600000-0000-0000-0000-000000000003'
);

insert into user_roles (user_id, role, school_id, granted_by) values
  ('98600000-0000-0000-0000-000000000003', 'school_admin', '98600000-0000-0000-0000-000000000002', '98600000-0000-0000-0000-000000000003');

insert into sessions (user_id, active_role, active_school_id, token_hash, expires_at) values
  ('98600000-0000-0000-0000-000000000003', 'school_admin', '98600000-0000-0000-0000-000000000002', encode(digest('room-admin-token', 'sha256'), 'hex'), now() + interval '1 hour');

-- room with a real floor value and 2 devices (1 of which is a training kit)
insert into rooms (id, school_id, building_id, name, code, floor, room_type, capacity)
values ('98600000-0000-0000-0000-000000000004', '98600000-0000-0000-0000-000000000002', null, 'LAB-101', 'LAB-101', 'ชั้น 2', 'ห้องปฏิบัติการ', 30);

-- room with no floor set at all — must stay null, not fabricated 'ชั้น 1'
insert into rooms (id, school_id, building_id, name, code, floor, room_type, capacity)
values ('98600000-0000-0000-0000-000000000005', '98600000-0000-0000-0000-000000000002', null, 'A-101', 'A-101', null, 'ห้องเรียน', 40);

insert into users (
  id, school_id, email, password_hash, first_name, last_name, created_by
) values (
  '98600000-0000-0000-0000-000000000006', '98600000-0000-0000-0000-000000000002',
  'device-registrar@pdpa.test', crypt('irrelevant', gen_salt('bf')), 'Registrar', 'B',
  '98600000-0000-0000-0000-000000000003'
);

insert into devices (school_id, type, name, status, registered_by, token_hash, room)
values
  ('98600000-0000-0000-0000-000000000002', 'pm25_sensor', 'เซนเซอร์ PM2.5', 'online', '98600000-0000-0000-0000-000000000006', encode(digest('room-device-1', 'sha256'), 'hex'), 'LAB-101'),
  ('98600000-0000-0000-0000-000000000002', 'relay', 'ชุดฝึก AIoT', 'online', '98600000-0000-0000-0000-000000000006', encode(digest('room-device-2', 'sha256'), 'hex'), 'LAB-101');

-- 1. real device count, not the old hardcoded 0
select is(
  (select devices_count from list_school_rooms('room-admin-token') where id = '98600000-0000-0000-0000-000000000004'),
  2::bigint,
  'devices_count reflects real devices matched to the room, not a hardcoded 0'
);

-- 2. training kit detected by name match
select is(
  (select training_kits_count from list_school_rooms('room-admin-token') where id = '98600000-0000-0000-0000-000000000004'),
  1::bigint,
  'training_kits_count reflects a real device name match, not a hardcoded 0'
);

-- 3. a room with zero devices reports zero, not a fabricated number
select is(
  (select devices_count from list_school_rooms('room-admin-token') where id = '98600000-0000-0000-0000-000000000005'),
  0::bigint,
  'a room with no matching devices reports a real zero'
);

-- 4. floor that was never set stays null — no more fabricated 'ชั้น 1'
select ok(
  (select floor from list_school_rooms('room-admin-token') where id = '98600000-0000-0000-0000-000000000005') is null,
  'an unset floor stays null instead of a fabricated default'
);

-- 5. resource_status has no real signal anywhere in the schema — must be
-- null, never the old hardcoded 'ปกติ' claiming a health check that never ran
select ok(
  (select resource_status from list_school_rooms('room-admin-token') where id = '98600000-0000-0000-0000-000000000004') is null,
  'resource_status is null, not a fabricated "ปกติ" for every room'
);

select * from finish();
rollback;
