begin;

create extension if not exists pgtap with schema extensions;
select plan(6);

insert into packages (id, name, license_type)
values ('96000000-0000-0000-0000-000000000001', 'FM device list test package', 'perpetual');

insert into schools (id, package_id, name, school_code) values
  ('96000000-0000-0000-0000-000000000002', '96000000-0000-0000-0000-000000000001', 'FM device list school', 'FMDEVLIST');

insert into users (
  id, school_id, email, password_hash, first_name, last_name, created_by
) values
  (
    '96000000-0000-0000-0000-000000000003',
    '96000000-0000-0000-0000-000000000002',
    'fm-devlist-admin@fmdevlist.test', crypt('irrelevant', gen_salt('bf')),
    'Admin', 'A', '96000000-0000-0000-0000-000000000003'
  ),
  (
    '96000000-0000-0000-0000-000000000004',
    '96000000-0000-0000-0000-000000000002',
    'fm-devlist-fm@fmdevlist.test', crypt('irrelevant', gen_salt('bf')),
    'Facility', 'Manager', '96000000-0000-0000-0000-000000000003'
  ),
  (
    '96000000-0000-0000-0000-000000000005',
    '96000000-0000-0000-0000-000000000002',
    'fm-devlist-unassigned@fmdevlist.test', crypt('irrelevant', gen_salt('bf')),
    'Unassigned', 'FM', '96000000-0000-0000-0000-000000000003'
  ),
  (
    '96000000-0000-0000-0000-000000000011',
    '96000000-0000-0000-0000-000000000002',
    'fm-devlist-teacher@fmdevlist.test', crypt('irrelevant', gen_salt('bf')),
    'Teacher', 'T', '96000000-0000-0000-0000-000000000003'
  );

insert into user_roles (user_id, role, school_id, granted_by) values
  ('96000000-0000-0000-0000-000000000003', 'school_admin', '96000000-0000-0000-0000-000000000002', '96000000-0000-0000-0000-000000000003'),
  ('96000000-0000-0000-0000-000000000004', 'facility_manager', '96000000-0000-0000-0000-000000000002', '96000000-0000-0000-0000-000000000003'),
  ('96000000-0000-0000-0000-000000000005', 'facility_manager', '96000000-0000-0000-0000-000000000002', '96000000-0000-0000-0000-000000000003'),
  ('96000000-0000-0000-0000-000000000011', 'teacher', '96000000-0000-0000-0000-000000000002', '96000000-0000-0000-0000-000000000003');

insert into sessions (user_id, active_role, active_school_id, token_hash, expires_at) values
  ('96000000-0000-0000-0000-000000000003', 'school_admin', '96000000-0000-0000-0000-000000000002', encode(digest('fm-devlist-admin-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('96000000-0000-0000-0000-000000000004', 'facility_manager', '96000000-0000-0000-0000-000000000002', encode(digest('fm-devlist-fm-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('96000000-0000-0000-0000-000000000005', 'facility_manager', '96000000-0000-0000-0000-000000000002', encode(digest('fm-devlist-unassigned-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('96000000-0000-0000-0000-000000000011', 'teacher', '96000000-0000-0000-0000-000000000002', encode(digest('fm-devlist-teacher-token', 'sha256'), 'hex'), now() + interval '1 hour');

insert into devices (id, school_id, type, name, location, status, registered_by) values
  ('96000000-0000-0000-0000-000000000006', '96000000-0000-0000-0000-000000000002', 'relay', 'ไฟห้อง 101', 'อาคาร 3 ชั้น 1', 'online', '96000000-0000-0000-0000-000000000003'),
  ('96000000-0000-0000-0000-000000000007', '96000000-0000-0000-0000-000000000002', 'pm25_sensor', 'PM2.5 อาคาร 3', 'อาคาร 3 ชั้น 1', 'online', '96000000-0000-0000-0000-000000000003'),
  ('96000000-0000-0000-0000-000000000008', '96000000-0000-0000-0000-000000000002', 'relay', 'ไฟอาคาร 5', 'อาคาร 5 ชั้น 1', 'offline', '96000000-0000-0000-0000-000000000003');

-- Admin assigns the facility manager to "อาคาร 3" only.
select set_facility_manager_building('fm-devlist-admin-token', '96000000-0000-0000-0000-000000000004', 'อาคาร 3');

-- 1: assigned facility manager sees only their own building's 2 devices
select is(
  (select count(*)::integer from list_devices_in_my_building('fm-devlist-fm-token')),
  2,
  'assigned facility manager sees exactly their own building''s devices'
);

-- 2: the device from the other building is excluded
select is(
  (select count(*)::integer from list_devices_in_my_building('fm-devlist-fm-token')
   where location = 'อาคาร 5 ชั้น 1'),
  0,
  'device from a different building is excluded'
);

-- 3: both device types (relay + sensor) are returned, not filtered by type
select is(
  (select count(distinct type)::integer from list_devices_in_my_building('fm-devlist-fm-token')),
  2,
  'both relay and sensor device types are returned for STK-9/STK-11 to filter as needed'
);

-- 4: real device status (online/offline) is exposed, not faked
select is(
  (select status::text from list_devices_in_my_building('fm-devlist-fm-token')
   where name = 'ไฟห้อง 101'),
  'online',
  'real device status is returned'
);

-- 5: unassigned facility manager (no building set) gets an empty list, not an error
select is(
  (select count(*)::integer from list_devices_in_my_building('fm-devlist-unassigned-token')),
  0,
  'facility manager with no assigned building gets an empty list'
);

-- 6: other roles are forbidden
select throws_ok(
  $$select * from list_devices_in_my_building('fm-devlist-teacher-token')$$,
  'P0001',
  'forbidden',
  'teacher role is forbidden from list_devices_in_my_building'
);

select * from finish();
rollback;
