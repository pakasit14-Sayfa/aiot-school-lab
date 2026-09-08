begin;

create extension if not exists pgtap with schema extensions;
select plan(4);

insert into packages (id, name, license_type)
values ('98400000-0000-0000-0000-000000000001', 'Sensor ingest test package', 'perpetual');

insert into schools (id, package_id, name, school_code)
values ('98400000-0000-0000-0000-000000000002', '98400000-0000-0000-0000-000000000001', 'Sensor ingest school', 'SENS-A');

insert into users (
  id, school_id, email, password_hash, first_name, last_name, created_by
) values (
  '98400000-0000-0000-0000-000000000003', '98400000-0000-0000-0000-000000000002',
  'sensor-registrar@pdpa.test', crypt('irrelevant', gen_salt('bf')), 'Registrar', 'A',
  '98400000-0000-0000-0000-000000000003'
);

insert into devices (
  id, school_id, type, name, status, registered_by, token_hash, last_seen_at
) values (
  '98400000-0000-0000-0000-000000000004', '98400000-0000-0000-0000-000000000002',
  'pm25_sensor', 'Test PM2.5 sensor', 'offline',
  '98400000-0000-0000-0000-000000000003',
  encode(digest('sensor-ingest-test-token', 'sha256'), 'hex'),
  now() - interval '11 days'
);

-- 1. an invalid device token fails closed
select throws_ok(
  $$select sensor_ingest('wrong-token', '[]'::jsonb)$$,
  'P0001', 'invalid_device_token',
  'a device token that matches no device is rejected'
);

select sensor_ingest(
  'sensor-ingest-test-token',
  '[{"metric": "pm25", "value": 12.5}]'::jsonb
);

-- 2. status flips to online, same behavior as before this fix
select is(
  (select status::text from devices where id = '98400000-0000-0000-0000-000000000004'),
  'online',
  'a successful ingest marks the device online'
);

-- 3. last_seen_at must actually move — this is the bug this migration fixes.
-- Found 2026-09-08: a live production sensor streamed readings every ~15s for
-- days while devices.last_seen_at stayed frozen at its registration-time
-- value because sensor_ingest updated status but never touched the column.
select ok(
  (select last_seen_at from devices where id = '98400000-0000-0000-0000-000000000004') > now() - interval '1 minute',
  'a successful ingest updates last_seen_at to now, not just status'
);

-- 4. the reading itself still lands, unaffected by the last_seen_at fix
select is(
  (select count(*)::int from sensor_readings where device_id = '98400000-0000-0000-0000-000000000004'),
  1,
  'the sensor reading is still recorded'
);

select * from finish();
rollback;
