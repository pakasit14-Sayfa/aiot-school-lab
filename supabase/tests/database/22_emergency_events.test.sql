-- pgTAP Tests: Emergency Events RPCs (list_emergency_events, acknowledge_emergency_event, close_emergency_event)

begin;

create extension if not exists pgtap with schema extensions;
select plan(12);

insert into packages (id, name, license_type)
values ('88100000-0000-0000-0000-000000000001', 'Emergency test package', 'perpetual');

insert into schools (id, package_id, name, school_code) values
  ('88200000-0000-0000-0000-000000000001', '88100000-0000-0000-0000-000000000001', 'Emergency School A', 'EMG-A');

insert into users (
  id, school_id, email, password_hash, first_name, last_name, created_by
) values
  ('88500000-0000-0000-0000-000000000001', '88200000-0000-0000-0000-000000000001',
   'emg-teacher@test.local', crypt('pass', gen_salt('bf')), 'Emergency', 'Teacher', '88500000-0000-0000-0000-000000000001'),
  ('88500000-0000-0000-0000-000000000002', '88200000-0000-0000-0000-000000000001',
   'emg-exec@test.local', crypt('pass', gen_salt('bf')), 'Emergency', 'Executive', '88500000-0000-0000-0000-000000000001'),
  ('88500000-0000-0000-0000-000000000003', '88200000-0000-0000-0000-000000000001',
   'emg-student@test.local', crypt('pass', gen_salt('bf')), 'Emergency', 'Student', '88500000-0000-0000-0000-000000000001'),
  ('88500000-0000-0000-0000-000000000004', '88200000-0000-0000-0000-000000000001',
   'emg-admin@test.local', crypt('pass', gen_salt('bf')), 'Emergency', 'Admin', '88500000-0000-0000-0000-000000000001');

insert into user_roles (user_id, role, school_id, granted_by) values
  ('88500000-0000-0000-0000-000000000001', 'teacher', '88200000-0000-0000-0000-000000000001', '88500000-0000-0000-0000-000000000001'),
  ('88500000-0000-0000-0000-000000000002', 'executive', '88200000-0000-0000-0000-000000000001', '88500000-0000-0000-0000-000000000001'),
  ('88500000-0000-0000-0000-000000000003', 'student', '88200000-0000-0000-0000-000000000001', '88500000-0000-0000-0000-000000000001'),
  ('88500000-0000-0000-0000-000000000004', 'school_admin', '88200000-0000-0000-0000-000000000001', '88500000-0000-0000-0000-000000000001');

insert into sessions (user_id, active_role, active_school_id, token_hash, expires_at) values
  ('88500000-0000-0000-0000-000000000001', 'teacher', '88200000-0000-0000-0000-000000000001',
   encode(digest('emg-teacher-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('88500000-0000-0000-0000-000000000002', 'executive', '88200000-0000-0000-0000-000000000001',
   encode(digest('emg-exec-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('88500000-0000-0000-0000-000000000003', 'student', '88200000-0000-0000-0000-000000000001',
   encode(digest('emg-student-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('88500000-0000-0000-0000-000000000004', 'school_admin', '88200000-0000-0000-0000-000000000001',
   encode(digest('emg-admin-token', 'sha256'), 'hex'), now() + interval '1 hour');

-- Insert test emergency event
insert into emergency_events (id, school_id, location, status, warning_light_on)
values ('88800000-0000-0000-0000-000000000001'::uuid, '88200000-0000-0000-0000-000000000001', 'ห้องทดลอง 101', 'new', true);

-- 1. Test list_emergency_events
prepare teacher_list as select * from list_emergency_events('emg-teacher-token');
select is(
  (select count(*)::int from list_emergency_events('emg-teacher-token')),
  1,
  'Teacher can list emergency events'
);

select is(
  (select count(*)::int from list_emergency_events('emg-exec-token')),
  1,
  'Executive can list emergency events'
);

prepare student_list as select * from list_emergency_events('emg-student-token');
select throws_ok('student_list', 'forbidden', 'Student is forbidden from listing emergency events');

prepare admin_list as select * from list_emergency_events('emg-admin-token');
select is(
  (select count(*)::int from list_emergency_events('emg-admin-token')),
  1,
  'School Admin can list emergency events'
);

-- 2. Test acknowledge_emergency_event
prepare teacher_ack as select acknowledge_emergency_event('emg-teacher-token', '88800000-0000-0000-0000-000000000001');
select lives_ok('teacher_ack', 'Teacher can acknowledge emergency event');

select throws_ok('teacher_ack', 'event_already_acknowledged', 'Cannot acknowledge an already acknowledged emergency event');

-- Executive is ALLOWED to acknowledge as of migration
-- 20260831173000_widen_emergency_executive_access.sql, which deliberately
-- added 'executive' to the allow-list because director_emergency_page.dart
-- calls acknowledgeEmergencyEvent directly. This assertion used to expect
-- 'forbidden' and had been failing ever since that migration landed.
-- A second event is used so this does not collide with the teacher's
-- acknowledge above; it is inserted after the list assertions so their
-- expected counts stay correct.
insert into emergency_events (id, school_id, location, status, warning_light_on)
values ('88800000-0000-0000-0000-000000000002'::uuid, '88200000-0000-0000-0000-000000000001', 'ห้องทดลอง 102', 'new', true);

prepare exec_ack as select acknowledge_emergency_event('emg-exec-token', '88800000-0000-0000-0000-000000000002');
select lives_ok('exec_ack', 'Executive can acknowledge emergency event (widened 2026-08-31)');

-- 3. Test close_emergency_event
prepare teacher_close_empty as select close_emergency_event('emg-teacher-token', '88800000-0000-0000-0000-000000000001', '');
select throws_ok('teacher_close_empty', 'review_note_required', 'Empty review note throws review_note_required');

prepare student_close as select close_emergency_event('emg-student-token', '88800000-0000-0000-0000-000000000001', 'เรียบร้อย');
select throws_ok('student_close', 'forbidden', 'Student is forbidden from closing emergency event');

prepare teacher_close_valid as select close_emergency_event('emg-teacher-token', '88800000-0000-0000-0000-000000000001', 'ระงับเหตุเรียบร้อย ปลอดภัย');
select lives_ok('teacher_close_valid', 'Teacher can close emergency event with valid review_note');

select is(
  (select status::text from emergency_events where id = '88800000-0000-0000-0000-000000000001'),
  'closed',
  'Emergency event status is updated to closed'
);

select throws_ok('teacher_close_valid', 'event_already_closed', 'Cannot close an already closed emergency event');

select * from finish();
rollback;
