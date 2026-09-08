begin;

create extension if not exists pgtap with schema extensions;
select plan(3);

insert into packages (id, name, license_type)
values ('98500000-0000-0000-0000-000000000001', 'Poll device commands test package', 'perpetual');

insert into schools (id, package_id, name, school_code)
values ('98500000-0000-0000-0000-000000000002', '98500000-0000-0000-0000-000000000001', 'Poll device commands school', 'POLL-A');

insert into users (
  id, school_id, email, password_hash, first_name, last_name, created_by
) values (
  '98500000-0000-0000-0000-000000000003', '98500000-0000-0000-0000-000000000002',
  'poll-registrar@pdpa.test', crypt('irrelevant', gen_salt('bf')), 'Registrar', 'A',
  '98500000-0000-0000-0000-000000000003'
);

insert into devices (
  id, school_id, type, name, status, registered_by, token_hash, last_seen_at
) values (
  '98500000-0000-0000-0000-000000000004', '98500000-0000-0000-0000-000000000002',
  'relay', 'Test relay', 'offline',
  '98500000-0000-0000-0000-000000000003',
  encode(digest('poll-commands-test-token', 'sha256'), 'hex'),
  now() - interval '11 days'
);

-- 1. an invalid device token fails closed, same as sensor_ingest
select throws_ok(
  $$select * from poll_device_commands('wrong-token')$$,
  'P0001', 'invalid_device_token',
  'a device token that matches no device is rejected'
);

select * from poll_device_commands('poll-commands-test-token');

-- 2. relay/camera devices only ever call this RPC (never sensor_ingest), so
-- it must be the one that keeps last_seen_at live for them. Found 2026-09-08:
-- it silently didn't, so those device types could never be told apart from
-- one that's actually gone dark.
select ok(
  (select last_seen_at from devices where id = '98500000-0000-0000-0000-000000000004') > now() - interval '1 minute',
  'a poll call updates last_seen_at to now, not just sensor_ingest'
);

-- 3. status flips to online too, consistent with sensor_ingest's behavior
select is(
  (select status::text from devices where id = '98500000-0000-0000-0000-000000000004'),
  'online',
  'a poll call also marks the device online'
);

select * from finish();
rollback;
