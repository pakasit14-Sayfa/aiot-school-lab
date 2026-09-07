-- pgTAP Tests: ทะเบียนรายงาน (school_reports, report_requirements)
--
-- What matters here: the storage path is decided by the session and not by
-- the caller, a teacher sees only their own ฝ่าย's filings, "เกินกำหนด" is
-- derived from a requirement's due date rather than stored on a file, a
-- report sent back for revision must say why, and only the two roles the
-- register exists for may decide anything.

begin;

create extension if not exists pgtap with schema extensions;
select plan(28);

insert into packages (id, name, license_type)
values ('99120000-0000-0000-0000-000000000001', 'Report test package', 'perpetual');

insert into schools (id, package_id, name, school_code) values
  ('99220000-0000-0000-0000-000000000001', '99120000-0000-0000-0000-000000000001', 'Rep School A', 'REP-A'),
  ('99220000-0000-0000-0000-000000000002', '99120000-0000-0000-0000-000000000001', 'Rep School B', 'REP-B');

insert into users (
  id, school_id, email, password_hash, first_name, last_name, created_by
) values
  ('99520000-0000-0000-0000-000000000001', '99220000-0000-0000-0000-000000000001',
   'rep-admin@test.local', crypt('pass', gen_salt('bf')), 'Rep', 'Admin', '99520000-0000-0000-0000-000000000001'),
  ('99520000-0000-0000-0000-000000000002', '99220000-0000-0000-0000-000000000001',
   'rep-exec@test.local', crypt('pass', gen_salt('bf')), 'Rep', 'Executive', '99520000-0000-0000-0000-000000000001'),
  -- Member of ฝ่ายวิชาการ.
  ('99520000-0000-0000-0000-000000000003', '99220000-0000-0000-0000-000000000001',
   'rep-teacher@test.local', crypt('pass', gen_salt('bf')), 'Rep', 'Teacher', '99520000-0000-0000-0000-000000000001'),
  -- Member of nothing: must not see the other teacher's filing.
  ('99520000-0000-0000-0000-000000000004', '99220000-0000-0000-0000-000000000001',
   'rep-outsider@test.local', crypt('pass', gen_salt('bf')), 'Rep', 'Loner', '99520000-0000-0000-0000-000000000001'),
  ('99520000-0000-0000-0000-000000000005', '99220000-0000-0000-0000-000000000001',
   'rep-student@test.local', crypt('pass', gen_salt('bf')), 'Rep', 'Student', '99520000-0000-0000-0000-000000000001');

insert into user_roles (user_id, role, school_id, granted_by) values
  ('99520000-0000-0000-0000-000000000001', 'school_admin', '99220000-0000-0000-0000-000000000001', '99520000-0000-0000-0000-000000000001'),
  ('99520000-0000-0000-0000-000000000002', 'executive',    '99220000-0000-0000-0000-000000000001', '99520000-0000-0000-0000-000000000001'),
  ('99520000-0000-0000-0000-000000000003', 'teacher',      '99220000-0000-0000-0000-000000000001', '99520000-0000-0000-0000-000000000001'),
  ('99520000-0000-0000-0000-000000000004', 'teacher',      '99220000-0000-0000-0000-000000000001', '99520000-0000-0000-0000-000000000001'),
  ('99520000-0000-0000-0000-000000000005', 'student',      '99220000-0000-0000-0000-000000000001', '99520000-0000-0000-0000-000000000001');

insert into sessions (user_id, active_role, active_school_id, token_hash, expires_at) values
  ('99520000-0000-0000-0000-000000000001', 'school_admin', '99220000-0000-0000-0000-000000000001',
   encode(digest('rep-admin-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('99520000-0000-0000-0000-000000000002', 'executive', '99220000-0000-0000-0000-000000000001',
   encode(digest('rep-exec-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('99520000-0000-0000-0000-000000000003', 'teacher', '99220000-0000-0000-0000-000000000001',
   encode(digest('rep-teacher-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('99520000-0000-0000-0000-000000000004', 'teacher', '99220000-0000-0000-0000-000000000001',
   encode(digest('rep-loner-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('99520000-0000-0000-0000-000000000005', 'student', '99220000-0000-0000-0000-000000000001',
   encode(digest('rep-student-token', 'sha256'), 'hex'), now() + interval '1 hour');

-- Two ฝ่าย, so a requirement has a denominator bigger than one.
insert into departments (id, school_id, name, kind, sort_order, created_by) values
  ('99320000-0000-0000-0000-000000000001', '99220000-0000-0000-0000-000000000001',
   'ฝ่ายวิชาการ', 'administrative', 1, '99520000-0000-0000-0000-000000000001'),
  ('99320000-0000-0000-0000-000000000002', '99220000-0000-0000-0000-000000000001',
   'ฝ่ายกิจการนักเรียน', 'administrative', 2, '99520000-0000-0000-0000-000000000001');

insert into department_members (department_id, user_id, is_head, assigned_by) values
  ('99320000-0000-0000-0000-000000000001', '99520000-0000-0000-0000-000000000003',
   true, '99520000-0000-0000-0000-000000000001');

-- ---------------------------------------------------------------------------
-- Upload access
-- ---------------------------------------------------------------------------

select is(
  (select assert_school_report_upload_access(
     'rep-teacher-token', '99320000-0000-0000-0000-000000000001')),
  '99220000-0000-0000-0000-000000000001'::uuid,
  'a member of the ฝ่าย may file for it, and the school comes from the session'
);

select throws_ok(
  $$ select assert_school_report_upload_access(
       'rep-loner-token', '99320000-0000-0000-0000-000000000001') $$,
  'not_a_member',
  'somebody outside the ฝ่าย cannot file on its behalf'
);

select lives_ok(
  $$ select assert_school_report_upload_access(
       'rep-admin-token', '99320000-0000-0000-0000-000000000002') $$,
  'school_admin may file for any ฝ่าย'
);

select throws_ok(
  $$ select assert_school_report_upload_access(
       'rep-student-token', null) $$,
  'forbidden',
  'a student cannot file a school report'
);

-- ---------------------------------------------------------------------------
-- register_school_report
-- ---------------------------------------------------------------------------

select throws_ok(
  $$ select register_school_report(
       'rep-teacher-token', 'รายงานวิชาการ', 'monthly',
       '99220000-0000-0000-0000-000000000002/whatever.pdf', 'r.pdf', 100,
       '99320000-0000-0000-0000-000000000001') $$,
  'invalid_storage_path',
  'a path under another school''s prefix is refused'
);

select throws_ok(
  $$ select register_school_report(
       'rep-teacher-token', '   ', 'monthly',
       '99220000-0000-0000-0000-000000000001/a.pdf', 'a.pdf', 100,
       '99320000-0000-0000-0000-000000000001') $$,
  'title_required',
  'a whitespace-only title is refused'
);

select throws_ok(
  $$ select register_school_report(
       'rep-teacher-token', 'รายงาน', 'ทุกเดือน',
       '99220000-0000-0000-0000-000000000001/a.pdf', 'a.pdf', 100,
       '99320000-0000-0000-0000-000000000001') $$,
  'invalid_report_type',
  'report_type is constrained to the six the schema knows'
);

select lives_ok(
  $$ select register_school_report(
       'rep-teacher-token', 'รายงานการมาเรียนประจำเดือน', 'monthly',
       '99220000-0000-0000-0000-000000000001/aaa-attendance.pdf',
       'attendance.pdf', 2400000,
       '99320000-0000-0000-0000-000000000001',
       null, 'สรุปการมาเรียน', current_date, current_date) $$,
  'a member of the ฝ่าย files a report'
);

select is(
  (select file_type from list_school_reports('rep-exec-token')),
  'pdf',
  'file_type is derived from the extension by the server'
);

select is(
  (select file_type from school_reports where file_name = 'attendance.pdf'),
  'pdf'::varchar,
  'and stored, so the filter has something to match'
);

select is(
  (select status from list_school_reports('rep-exec-token')),
  'submitted',
  'a new filing starts as submitted, not approved'
);

select is(
  (select submitter_position from list_school_reports('rep-exec-token')),
  null,
  'a position nobody recorded is null rather than an invented ตำแหน่ง'
);

-- ---------------------------------------------------------------------------
-- Who can see what
-- ---------------------------------------------------------------------------

select is(
  (select count(*)::int from list_school_reports('rep-exec-token')),
  1,
  'the director sees the register'
);

select is(
  (select count(*)::int from list_school_reports('rep-teacher-token')),
  1,
  'the submitter sees their own filing'
);

select is(
  (select count(*)::int from list_school_reports('rep-loner-token')),
  0,
  'a teacher outside the ฝ่าย sees nothing of it'
);

select throws_ok(
  $$ select * from list_school_reports('rep-student-token') $$,
  'forbidden',
  'a student cannot read the register'
);

select throws_ok(
  $$ select * from get_school_report_for_download(
       'rep-loner-token',
       (select id from school_reports where file_name = 'attendance.pdf')) $$,
  'forbidden',
  'and cannot be handed a signed URL for it either'
);

select is(
  (select file_name from get_school_report_for_download(
     'rep-exec-token',
     (select id from school_reports where file_name = 'attendance.pdf'))),
  'attendance.pdf'::varchar,
  'the director can be handed one'
);

-- ---------------------------------------------------------------------------
-- Review
-- ---------------------------------------------------------------------------

select throws_ok(
  $$ select review_school_report('rep-teacher-token',
       (select id from school_reports where file_name = 'attendance.pdf'),
       'approved') $$,
  'forbidden',
  'a teacher cannot approve a report'
);

select throws_ok(
  $$ select review_school_report('rep-exec-token',
       (select id from school_reports where file_name = 'attendance.pdf'),
       'needs_revision') $$,
  'note_required',
  'sending a report back without saying why is refused'
);

select lives_ok(
  $$ select review_school_report('rep-exec-token',
       (select id from school_reports where file_name = 'attendance.pdf'),
       'approved', 'ครบถ้วน') $$,
  'the director approves it'
);

select throws_ok(
  $$ select delete_school_report('rep-teacher-token',
       (select id from school_reports where file_name = 'attendance.pdf')) $$,
  'already_reviewed',
  'the submitter cannot withdraw a filing after it has been decided'
);

-- ---------------------------------------------------------------------------
-- Requirements — the source of "3/6" and of เกินกำหนด
-- ---------------------------------------------------------------------------

select throws_ok(
  $$ select create_report_requirement(
       'rep-admin-token', 'รายงานประจำเดือน', 'monthly', array[]::uuid[]) $$,
  'departments_required',
  'a requirement nobody is asked for is refused — it would be 0/0 forever'
);

select throws_ok(
  $$ select create_report_requirement(
       'rep-exec-token', 'รายงานประจำเดือน', 'monthly',
       array['99320000-0000-0000-0000-000000000001']::uuid[]) $$,
  'forbidden',
  'the director reviews reports but does not set the schedule'
);

select lives_ok(
  $$ select create_report_requirement(
       'rep-admin-token', 'รายงานประจำเดือน สิงหาคม', 'monthly',
       array['99320000-0000-0000-0000-000000000001',
             '99320000-0000-0000-0000-000000000002']::uuid[],
       current_date - 1) $$,
  'school_admin creates a requirement asking two ฝ่าย, due yesterday'
);

select is(
  (select expected_count || '/' || filed_count
     from list_report_requirements('rep-exec-token')),
  '2/0',
  'the denominator is the ฝ่าย actually asked, and nothing has been filed against it'
);

select is(
  (select is_overdue from list_report_requirements('rep-exec-token')),
  true,
  'เกินกำหนด is derived from the requirement''s due date, not stored on a file'
);

select is(
  (select overdue_requirements from get_school_report_summary('rep-exec-token')),
  1,
  'and the summary counts it the same way'
);

rollback;
