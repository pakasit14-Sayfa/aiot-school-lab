-- Verify the School Admin device-schedule RPC contract end to end.

begin;

create extension if not exists pgtap with schema extensions;
select plan(14);

insert into packages (id, name, license_type)
values ('99800000-0000-0000-0000-000000000001', 'Device schedule test package', 'perpetual');

insert into schools (id, package_id, name, school_code) values
  ('98a00000-0000-0000-0000-000000000001', '99800000-0000-0000-0000-000000000001', 'Schedule test school A', 'SCHEDULE-A'),
  ('98a00000-0000-0000-0000-000000000002', '99800000-0000-0000-0000-000000000001', 'Schedule test school B', 'SCHEDULE-B');

insert into users (id, school_id, email, password_hash, first_name, last_name, created_by) values
  ('98b00000-0000-0000-0000-000000000001', '98a00000-0000-0000-0000-000000000001', 'schedule-admin-a@pdpa.test', crypt('irrelevant', gen_salt('bf')), 'Admin', 'A', '98b00000-0000-0000-0000-000000000001'),
  ('98b00000-0000-0000-0000-000000000002', '98a00000-0000-0000-0000-000000000002', 'schedule-admin-b@pdpa.test', crypt('irrelevant', gen_salt('bf')), 'Admin', 'B', '98b00000-0000-0000-0000-000000000002'),
  ('98b00000-0000-0000-0000-000000000003', '98a00000-0000-0000-0000-000000000001', 'schedule-student-a@pdpa.test', crypt('irrelevant', gen_salt('bf')), 'Student', 'A', '98b00000-0000-0000-0000-000000000001');

insert into user_roles (user_id, role, school_id, granted_by) values
  ('98b00000-0000-0000-0000-000000000001', 'school_admin', '98a00000-0000-0000-0000-000000000001', '98b00000-0000-0000-0000-000000000001'),
  ('98b00000-0000-0000-0000-000000000002', 'school_admin', '98a00000-0000-0000-0000-000000000002', '98b00000-0000-0000-0000-000000000002'),
  ('98b00000-0000-0000-0000-000000000003', 'student', '98a00000-0000-0000-0000-000000000001', '98b00000-0000-0000-0000-000000000001');

insert into sessions (user_id, active_role, active_school_id, token_hash, expires_at) values
  ('98b00000-0000-0000-0000-000000000001', 'school_admin', '98a00000-0000-0000-0000-000000000001', encode(digest('schedule-admin-a-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('98b00000-0000-0000-0000-000000000002', 'school_admin', '98a00000-0000-0000-0000-000000000002', encode(digest('schedule-admin-b-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('98b00000-0000-0000-0000-000000000003', 'student', '98a00000-0000-0000-0000-000000000001', encode(digest('schedule-student-a-token', 'sha256'), 'hex'), now() + interval '1 hour');

insert into devices (id, school_id, type, name, location, status, registered_by)
values ('98c00000-0000-0000-0000-000000000001', '98a00000-0000-0000-0000-000000000001', 'light_sensor', 'Schedule test device', 'Room 101', 'online', '98b00000-0000-0000-0000-000000000001');

select has_function('public', 'create_device_schedule', array['text', 'uuid', 'text', 'jsonb', 'smallint[]', 'time without time zone'], 'create_device_schedule exists');
select has_function('public', 'list_device_schedules', array['text', 'uuid'], 'list_device_schedules exists');
select has_function('public', 'toggle_device_schedule', array['text', 'uuid', 'boolean'], 'toggle_device_schedule exists');
select has_function('public', 'delete_device_schedule', array['text', 'uuid'], 'delete_device_schedule exists');

select throws_ok(
  $$ select * from list_device_schedules('schedule-student-a-token', null) $$,
  'forbidden',
  'student cannot list device schedules'
);
select throws_ok(
  $$ select create_device_schedule('schedule-student-a-token', '98c00000-0000-0000-0000-000000000001', 'Blocked', '{"action":"on"}'::jsonb, array[1]::smallint[], '08:00'::time) $$,
  'forbidden',
  'student cannot create a device schedule'
);

create temporary table created_schedule_ids (id uuid primary key);
insert into created_schedule_ids (id)
select create_device_schedule(
  'schedule-admin-a-token',
  '98c00000-0000-0000-0000-000000000001',
  'Open before class',
  '{"action":"on"}'::jsonb,
  array[1,2,3,4,5]::smallint[],
  '08:00'::time
);

select ok((select id is not null from created_schedule_ids), 'create returns a real schedule id');
select is((select count(*)::int from list_device_schedules('schedule-admin-a-token', null)), 1, 'school admin lists the created schedule');
select is((select label from list_device_schedules('schedule-admin-a-token', null)), 'Open before class', 'list returns canonical persisted data');

select toggle_device_schedule('schedule-admin-a-token', (select id from created_schedule_ids), false);
select is((select enabled from list_device_schedules('schedule-admin-a-token', null)), false, 'toggle persists the disabled state');

select is((select count(*)::int from list_device_schedules('schedule-admin-b-token', null)), 0, 'another school cannot list the schedule');
select throws_ok(
  format('select toggle_device_schedule(%L, %L::uuid, true)', 'schedule-admin-b-token', (select id from created_schedule_ids)),
  'forbidden',
  'another school cannot toggle the schedule'
);

select delete_device_schedule('schedule-admin-a-token', (select id from created_schedule_ids));
select is((select count(*)::int from list_device_schedules('schedule-admin-a-token', null)), 0, 'delete removes the schedule from the canonical list');
select is((select count(*)::int from audit_logs where entity_type = 'device_schedules' and user_id = '98b00000-0000-0000-0000-000000000001'), 3, 'create, toggle, and delete each write an audit log');

select * from finish();
rollback;
