-- pgTAP Tests: ลงเวลาปฏิบัติงานของบุคลากร (staff attendance + staff leave)
--
-- What matters here: lateness has a configured basis or check-in refuses,
-- a day nobody recorded reads as `no_record` rather than `absent`, approved
-- leave wins over a missing check-in, only school_admin can assert someone's
-- attendance or decide a leave request, and a teacher sees only their own
-- leave.

begin;

create extension if not exists pgtap with schema extensions;
select plan(25);

insert into packages (id, name, license_type)
values ('99110000-0000-0000-0000-000000000001', 'Attendance test package', 'perpetual');

insert into schools (id, package_id, name, school_code) values
  ('99210000-0000-0000-0000-000000000001', '99110000-0000-0000-0000-000000000001', 'Att School A', 'ATT-A'),
  ('99210000-0000-0000-0000-000000000002', '99110000-0000-0000-0000-000000000001', 'Att School B', 'ATT-B');

insert into users (
  id, school_id, email, password_hash, first_name, last_name, created_by
) values
  ('99510000-0000-0000-0000-000000000001', '99210000-0000-0000-0000-000000000001',
   'att-admin@test.local', crypt('pass', gen_salt('bf')), 'Att', 'Admin', '99510000-0000-0000-0000-000000000001'),
  ('99510000-0000-0000-0000-000000000002', '99210000-0000-0000-0000-000000000001',
   'att-exec@test.local', crypt('pass', gen_salt('bf')), 'Att', 'Executive', '99510000-0000-0000-0000-000000000001'),
  ('99510000-0000-0000-0000-000000000003', '99210000-0000-0000-0000-000000000001',
   'att-teacher@test.local', crypt('pass', gen_salt('bf')), 'Att', 'Teacher', '99510000-0000-0000-0000-000000000001'),
  ('99510000-0000-0000-0000-000000000004', '99210000-0000-0000-0000-000000000001',
   'att-teacher2@test.local', crypt('pass', gen_salt('bf')), 'Att', 'Teachertwo', '99510000-0000-0000-0000-000000000001'),
  ('99510000-0000-0000-0000-000000000005', '99210000-0000-0000-0000-000000000001',
   'att-student@test.local', crypt('pass', gen_salt('bf')), 'Att', 'Student', '99510000-0000-0000-0000-000000000001'),
  ('99510000-0000-0000-0000-000000000006', '99210000-0000-0000-0000-000000000002',
   'att-outsider@test.local', crypt('pass', gen_salt('bf')), 'Att', 'Outsider', '99510000-0000-0000-0000-000000000006');

insert into user_roles (user_id, role, school_id, granted_by) values
  ('99510000-0000-0000-0000-000000000001', 'school_admin', '99210000-0000-0000-0000-000000000001', '99510000-0000-0000-0000-000000000001'),
  ('99510000-0000-0000-0000-000000000002', 'executive',    '99210000-0000-0000-0000-000000000001', '99510000-0000-0000-0000-000000000001'),
  ('99510000-0000-0000-0000-000000000003', 'teacher',      '99210000-0000-0000-0000-000000000001', '99510000-0000-0000-0000-000000000001'),
  ('99510000-0000-0000-0000-000000000004', 'teacher',      '99210000-0000-0000-0000-000000000001', '99510000-0000-0000-0000-000000000001'),
  ('99510000-0000-0000-0000-000000000005', 'student',      '99210000-0000-0000-0000-000000000001', '99510000-0000-0000-0000-000000000001'),
  ('99510000-0000-0000-0000-000000000006', 'teacher',      '99210000-0000-0000-0000-000000000002', '99510000-0000-0000-0000-000000000006');

insert into sessions (user_id, active_role, active_school_id, token_hash, expires_at) values
  ('99510000-0000-0000-0000-000000000001', 'school_admin', '99210000-0000-0000-0000-000000000001',
   encode(digest('att-admin-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('99510000-0000-0000-0000-000000000002', 'executive', '99210000-0000-0000-0000-000000000001',
   encode(digest('att-exec-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('99510000-0000-0000-0000-000000000003', 'teacher', '99210000-0000-0000-0000-000000000001',
   encode(digest('att-teacher-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('99510000-0000-0000-0000-000000000004', 'teacher', '99210000-0000-0000-0000-000000000001',
   encode(digest('att-teacher2-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('99510000-0000-0000-0000-000000000005', 'student', '99210000-0000-0000-0000-000000000001',
   encode(digest('att-student-token', 'sha256'), 'hex'), now() + interval '1 hour');

-- ---------------------------------------------------------------------------
-- Work hours must exist before lateness means anything
-- ---------------------------------------------------------------------------

select is(
  (select count(*)::int from get_staff_work_hours('att-admin-token')),
  0,
  'a school with no configured hours returns no row, not a default 08:00'
);

select throws_ok(
  $$ select staff_check_in('att-teacher-token') $$,
  'work_hours_not_configured',
  'check-in refuses while lateness has no basis'
);

select throws_ok(
  $$ select set_staff_work_hours('att-teacher-token', '08:00', '16:00', 15) $$,
  'forbidden',
  'a teacher cannot set the school work hours'
);

select throws_ok(
  $$ select set_staff_work_hours('att-exec-token', '08:00', '16:00', 15) $$,
  'forbidden',
  'executive reads the figures, it does not set the rules behind them'
);

select throws_ok(
  $$ select set_staff_work_hours('att-admin-token', '16:00', '08:00', 0) $$,
  'invalid_work_hours',
  'an end before the start is refused'
);

-- Hours wide enough that the test never straddles them: check-in must land as
-- 'present' whatever time of day the suite runs.
select lives_ok(
  $$ select set_staff_work_hours('att-admin-token', '00:00', '23:59', 1439) $$,
  'school_admin sets the work hours'
);

select is(
  (select late_grace_minutes from get_staff_work_hours('att-teacher-token')),
  1439,
  'a teacher can read the hours — you cannot know you are late otherwise'
);

-- ---------------------------------------------------------------------------
-- Check in / out
-- ---------------------------------------------------------------------------

select is(
  (select staff_check_in('att-teacher-token')),
  'present',
  'a check-in inside the grace window is present'
);

select throws_ok(
  $$ select staff_check_in('att-teacher-token') $$,
  'already_checked_in',
  'a second check-in the same day is refused rather than overwriting the first'
);

select lives_ok(
  $$ select staff_check_out('att-teacher-token') $$,
  'the same person can check out'
);

select throws_ok(
  $$ select staff_check_out('att-teacher2-token') $$,
  'not_checked_in',
  'checking out without checking in is refused'
);

select throws_ok(
  $$ select staff_check_in('att-student-token') $$,
  'forbidden',
  'a student is not staff and cannot check in'
);

-- Narrow the window and confirm lateness is actually derived, not assumed.
select set_staff_work_hours('att-admin-token', '00:00', '23:59', 0);

select is(
  (select staff_check_in('att-teacher2-token')),
  case when (now() at time zone 'Asia/Bangkok')::time <= '00:00'::time
       then 'present' else 'late' end,
  'lateness is derived from the configured start plus grace, not guessed'
);

-- ---------------------------------------------------------------------------
-- Reading the day
-- ---------------------------------------------------------------------------

select is(
  (select count(*)::int from list_staff_attendance('att-exec-token')),
  4,
  'the day lists staff only — the student is excluded'
);

select is(
  (select status from list_staff_attendance('att-exec-token')
    where user_id = '99510000-0000-0000-0000-000000000001'),
  'no_record',
  'somebody nobody recorded is no_record, never absent'
);

select throws_ok(
  $$ select * from list_staff_attendance('att-student-token') $$,
  'forbidden',
  'a student cannot read who came to work'
);

select is(
  (select no_record_count from get_staff_attendance_summary('att-exec-token')),
  2,
  'the summary counts no_record separately from absent'
);

select is(
  (select work_hours_configured from get_staff_attendance_summary('att-exec-token')),
  true,
  'the summary states whether lateness was knowable at all'
);

-- ---------------------------------------------------------------------------
-- Admin-recorded attendance
-- ---------------------------------------------------------------------------

select throws_ok(
  $$ select record_staff_attendance('att-exec-token',
       '99510000-0000-0000-0000-000000000003', current_date, 'absent') $$,
  'forbidden',
  'executive cannot assert that somebody was absent'
);

select throws_ok(
  $$ select record_staff_attendance('att-admin-token',
       '99510000-0000-0000-0000-000000000005', current_date, 'absent') $$,
  'not_staff',
  'a student cannot be given a staff attendance record'
);

select throws_ok(
  $$ select record_staff_attendance('att-admin-token',
       '99510000-0000-0000-0000-000000000006', current_date, 'absent') $$,
  'forbidden',
  'a staff member of another school cannot be recorded'
);

-- ---------------------------------------------------------------------------
-- Leave
-- ---------------------------------------------------------------------------

select lives_ok(
  $$ select request_staff_leave('att-teacher-token', 'sick',
       current_date, current_date, 'ไข้') $$,
  'a teacher can request leave for themselves'
);

select is(
  (select count(*)::int from list_staff_leave_requests('att-teacher2-token')),
  0,
  'a teacher sees only their own leave, not a colleague''s'
);

select throws_ok(
  $$ select review_staff_leave_request('att-teacher2-token',
       (select id from staff_leave_requests
         where school_id = '99210000-0000-0000-0000-000000000001' limit 1),
       true) $$,
  'forbidden',
  'a teacher cannot approve leave'
);

-- Approved leave must beat the check-in that already exists for that person.
select review_staff_leave_request(
  'att-admin-token',
  (select id from staff_leave_requests
    where school_id = '99210000-0000-0000-0000-000000000001' limit 1),
  true);

select is(
  (select status from list_staff_attendance('att-exec-token')
    where user_id = '99510000-0000-0000-0000-000000000003'),
  'leave',
  'approved leave covering the day wins when the day is read back'
);

rollback;
