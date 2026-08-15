begin;

create extension if not exists pgtap with schema extensions;
select plan(8);

insert into packages (id, name, license_type)
values ('93000000-0000-0000-0000-000000000001', 'FM scope test package', 'perpetual');

insert into schools (id, package_id, name, school_code) values
  ('93000000-0000-0000-0000-000000000002', '93000000-0000-0000-0000-000000000001', 'FM scope school', 'FMSCOPE');

insert into users (
  id, school_id, email, password_hash, first_name, last_name, created_by
) values
  (
    '93000000-0000-0000-0000-000000000003',
    '93000000-0000-0000-0000-000000000002',
    'fm-scope-admin@fmscope.test', crypt('irrelevant', gen_salt('bf')),
    'Admin', 'A', '93000000-0000-0000-0000-000000000003'
  ),
  (
    '93000000-0000-0000-0000-000000000004',
    '93000000-0000-0000-0000-000000000002',
    'fm-scope-fm@fmscope.test', crypt('irrelevant', gen_salt('bf')),
    'Facility', 'Manager', '93000000-0000-0000-0000-000000000003'
  ),
  (
    '93000000-0000-0000-0000-000000000005',
    '93000000-0000-0000-0000-000000000002',
    'fm-scope-unassigned@fmscope.test', crypt('irrelevant', gen_salt('bf')),
    'Unassigned', 'FM', '93000000-0000-0000-0000-000000000003'
  );

insert into user_roles (user_id, role, school_id, granted_by) values
  ('93000000-0000-0000-0000-000000000003', 'school_admin', '93000000-0000-0000-0000-000000000002', '93000000-0000-0000-0000-000000000003'),
  ('93000000-0000-0000-0000-000000000004', 'facility_manager', '93000000-0000-0000-0000-000000000002', '93000000-0000-0000-0000-000000000003'),
  ('93000000-0000-0000-0000-000000000005', 'facility_manager', '93000000-0000-0000-0000-000000000002', '93000000-0000-0000-0000-000000000003');

insert into sessions (user_id, active_role, active_school_id, token_hash, expires_at) values
  ('93000000-0000-0000-0000-000000000003', 'school_admin', '93000000-0000-0000-0000-000000000002', encode(digest('fm-scope-admin-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('93000000-0000-0000-0000-000000000004', 'facility_manager', '93000000-0000-0000-0000-000000000002', encode(digest('fm-scope-fm-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('93000000-0000-0000-0000-000000000005', 'facility_manager', '93000000-0000-0000-0000-000000000002', encode(digest('fm-scope-unassigned-token', 'sha256'), 'hex'), now() + interval '1 hour');

insert into devices (id, school_id, type, name, location, registered_by) values
  ('93000000-0000-0000-0000-000000000006', '93000000-0000-0000-0000-000000000002', 'pm25_sensor', 'PM2.5 อาคาร 3', 'อาคาร 3 ชั้น 1', '93000000-0000-0000-0000-000000000003'),
  ('93000000-0000-0000-0000-000000000007', '93000000-0000-0000-0000-000000000002', 'pm25_sensor', 'PM2.5 อาคาร 5', 'อาคาร 5 ชั้น 1', '93000000-0000-0000-0000-000000000003');

insert into sensor_readings (device_id, metric, ts, value) values
  ('93000000-0000-0000-0000-000000000006', 'pm25', now(), 10.5),
  ('93000000-0000-0000-0000-000000000007', 'pm25', now(), 88.0);

-- Admin assigns the manager to "อาคาร 3" only.
select set_facility_manager_building('fm-scope-admin-token', '93000000-0000-0000-0000-000000000004', 'อาคาร 3');

select is(
  (select building from users where id = '93000000-0000-0000-0000-000000000004'),
  'อาคาร 3',
  'set_facility_manager_building stores the assigned building'
);

select is(
  (select count(*)::integer from sensor_latest('fm-scope-fm-token')),
  1,
  'assigned facility manager only sees their own building''s summary row'
);

select is(
  (select location from sensor_latest('fm-scope-fm-token') limit 1),
  'อาคาร 3 ชั้น 1',
  'the one summary row returned is for the assigned building, not the other one'
);

select is(
  (select count(*)::integer from sensor_latest('fm-scope-unassigned-token')),
  0,
  'facility manager with no assigned building gets an empty result, not the whole school'
);

select throws_ok(
  $$select set_facility_manager_building('fm-scope-fm-token', '93000000-0000-0000-0000-000000000004', 'อาคาร 9')$$,
  'P0001', 'forbidden',
  'a facility manager cannot self-assign their own building'
);

select throws_ok(
  $$select sensor_latest('fm-scope-fm-token', '93000000-0000-0000-0000-000000000006')$$,
  'P0001', 'summary_only',
  'facility manager still cannot request per-device detail, only the building summary'
);

-- Re-assigning to a different building narrows the scope again.
select set_facility_manager_building('fm-scope-admin-token', '93000000-0000-0000-0000-000000000004', 'อาคาร 5');

select is(
  (select count(*)::integer from sensor_latest('fm-scope-fm-token')),
  1,
  'after reassignment, the manager sees only the newly assigned building'
);

select is(
  (select location from sensor_latest('fm-scope-fm-token') limit 1),
  'อาคาร 5 ชั้น 1',
  'reassignment result is the correct building''s row, confirming no stale cross-building leak'
);

select * from finish();
rollback;
