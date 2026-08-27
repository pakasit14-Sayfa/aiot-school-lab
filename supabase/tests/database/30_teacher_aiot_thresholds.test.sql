-- =====================================================================
-- Test Suite: 30_teacher_aiot_thresholds.test.sql
-- Verify list_thresholds / set_threshold (new) and the teacher-widened
-- list_school_alerts / acknowledge_sensor_alert_for_school_admin.
-- =====================================================================

begin;

create extension if not exists pgtap with schema extensions;
select plan(11);

insert into packages (id, name, license_type)
values ('99900000-0000-0000-0000-000000000001', 'Teacher AIoT test package', 'perpetual');

insert into schools (id, package_id, name, school_code) values
  ('99a00000-0000-0000-0000-000000000001', '99900000-0000-0000-0000-000000000001', 'AIoT test school A', 'AIOT-A'),
  ('99a00000-0000-0000-0000-000000000002', '99900000-0000-0000-0000-000000000001', 'AIoT test school B', 'AIOT-B');

insert into users (
  id, school_id, email, password_hash, first_name, last_name, created_by
) values
  ('99b00000-0000-0000-0000-000000000001', '99a00000-0000-0000-0000-000000000001',
   'aiot-teacher-a@pdpa.test', crypt('irrelevant', gen_salt('bf')), 'Teacher', 'A',
   '99b00000-0000-0000-0000-000000000001'),
  ('99b00000-0000-0000-0000-000000000002', '99a00000-0000-0000-0000-000000000001',
   'aiot-student-a@pdpa.test', crypt('irrelevant', gen_salt('bf')), 'Student', 'A',
   '99b00000-0000-0000-0000-000000000001');

insert into user_roles (user_id, role, school_id, granted_by) values
  ('99b00000-0000-0000-0000-000000000001', 'teacher', '99a00000-0000-0000-0000-000000000001', '99b00000-0000-0000-0000-000000000001'),
  ('99b00000-0000-0000-0000-000000000002', 'student', '99a00000-0000-0000-0000-000000000001', '99b00000-0000-0000-0000-000000000001');

insert into sessions (user_id, active_role, active_school_id, token_hash, expires_at) values
  ('99b00000-0000-0000-0000-000000000001', 'teacher', '99a00000-0000-0000-0000-000000000001',
   encode(digest('aiot-teacher-a-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('99b00000-0000-0000-0000-000000000002', 'student', '99a00000-0000-0000-0000-000000000001',
   encode(digest('aiot-student-a-token', 'sha256'), 'hex'), now() + interval '1 hour');

-- Functions exist
select has_function('public', 'list_thresholds', ARRAY['text'], 'list_thresholds exists');
select has_function('public', 'set_threshold', ARRAY['text', 'metric_type', 'numeric', 'numeric', 'boolean'], 'set_threshold exists');

-- Student is rejected by both new RPCs
select throws_ok(
  $$ select list_thresholds('aiot-student-a-token') $$,
  'forbidden: teacher, school_admin or super_admin role required',
  'student cannot call list_thresholds'
);
select throws_ok(
  $$ select set_threshold('aiot-student-a-token', 'light_lux'::metric_type, 100, 800, true) $$,
  'forbidden: teacher, school_admin or super_admin role required',
  'student cannot call set_threshold'
);

-- Teacher can set a threshold, and a second call upserts rather than duplicating
select set_threshold('aiot-teacher-a-token', 'light_lux'::metric_type, 100, 800, true);
select set_threshold('aiot-teacher-a-token', 'light_lux'::metric_type, 150, 750, true);

select is(
  (select count(*)::int from thresholds where school_id = '99a00000-0000-0000-0000-000000000001' and metric = 'light_lux' and device_id is null),
  1,
  'set_threshold called twice for the same metric upserts, does not duplicate'
);

select is(
  (select max_value::int from thresholds where school_id = '99a00000-0000-0000-0000-000000000001' and metric = 'light_lux' and device_id is null),
  750,
  'the second set_threshold call is the one that stuck (real update, not insert-only)'
);

-- Teacher can read it back via list_thresholds
select is(
  (select count(*)::int from list_thresholds('aiot-teacher-a-token')),
  1,
  'teacher can list the threshold they just set'
);

-- Tenant isolation: school B's teacher sees none of school A's thresholds
insert into users (id, school_id, email, password_hash, first_name, last_name, created_by) values
  ('99b00000-0000-0000-0000-000000000003', '99a00000-0000-0000-0000-000000000002',
   'aiot-teacher-b@pdpa.test', crypt('irrelevant', gen_salt('bf')), 'Teacher', 'B',
   '99b00000-0000-0000-0000-000000000003');
insert into user_roles (user_id, role, school_id, granted_by) values
  ('99b00000-0000-0000-0000-000000000003', 'teacher', '99a00000-0000-0000-0000-000000000002', '99b00000-0000-0000-0000-000000000003');
insert into sessions (user_id, active_role, active_school_id, token_hash, expires_at) values
  ('99b00000-0000-0000-0000-000000000003', 'teacher', '99a00000-0000-0000-0000-000000000002',
   encode(digest('aiot-teacher-b-token', 'sha256'), 'hex'), now() + interval '1 hour');

select is(
  (select count(*)::int from list_thresholds('aiot-teacher-b-token')),
  0,
  'a teacher in a different school does not see school A''s threshold'
);

-- Alerts: teacher can list (widened role check) and acknowledge
insert into devices (id, school_id, type, name, status, registered_by) values
  ('99c00000-0000-0000-0000-000000000001', '99a00000-0000-0000-0000-000000000001', 'light_sensor', 'AIoT test light sensor', 'online', '99b00000-0000-0000-0000-000000000001');

insert into sensor_alerts (id, threshold_id, device_id, metric, value, status)
select '99d00000-0000-0000-0000-000000000001',
  (select id from thresholds where school_id = '99a00000-0000-0000-0000-000000000001' and metric = 'light_lux' and device_id is null),
  '99c00000-0000-0000-0000-000000000001', 'light_lux', 900, 'new';

select throws_ok(
  $$ select list_school_alerts('aiot-student-a-token', NULL) $$,
  'forbidden: teacher, school_admin or super_admin role required',
  'student still cannot list alerts'
);

select is(
  (select count(*)::int from list_school_alerts('aiot-teacher-a-token', NULL)),
  1,
  'teacher can list the alert in their own school'
);

select acknowledge_sensor_alert_for_school_admin('aiot-teacher-a-token', '99d00000-0000-0000-0000-000000000001');

select is(
  (select status::text from sensor_alerts where id = '99d00000-0000-0000-0000-000000000001'),
  'acknowledged',
  'teacher acknowledging the alert really updates sensor_alerts.status'
);

select * from finish();
rollback;
