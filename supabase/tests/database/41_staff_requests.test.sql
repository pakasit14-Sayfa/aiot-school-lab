-- pgTAP Tests: staff_requests (ขอเข้าพบ / ขอจัดประชุม / ขอไปราชการ) — two-tier
-- approval (หัวหน้าฝ่าย → ผอ.) from 20260907050000.
--
-- What matters here: only a real ฝ่าย head or an admin override may decide
-- the level-1 stage; the level-2 decision belongs to executive/admin only;
-- a requester who is their own department's head, or belongs to no
-- department, skips straight to level 2 rather than being auto-approved;
-- an approved ไปราชการ writes real, overwriting rows into
-- staff_attendance_records for every day in its range — the entire reason
-- this table exists — while a plain ขอเข้าพบ never touches attendance at
-- all; and none of this crosses a school_id boundary.

begin;

create extension if not exists pgtap with schema extensions;
select plan(54);

insert into packages (id, name, license_type)
values ('99920000-0000-0000-0000-000000000001', 'Staff requests test package', 'perpetual');

insert into schools (id, package_id, name, school_code) values
  ('99921000-0000-0000-0000-000000000001', '99920000-0000-0000-0000-000000000001', 'Requests School A', 'REQ-A'),
  ('99921000-0000-0000-0000-000000000002', '99920000-0000-0000-0000-000000000001', 'Requests School B', 'REQ-B');

insert into users (
  id, school_id, email, password_hash, first_name, last_name, created_by
) values
  ('99922000-0000-0000-0000-000000000001', '99921000-0000-0000-0000-000000000001',
   'req-admin@test.local', crypt('pass', gen_salt('bf')), 'Req', 'Admin', '99922000-0000-0000-0000-000000000001'),
  ('99922000-0000-0000-0000-000000000002', '99921000-0000-0000-0000-000000000001',
   'req-exec@test.local', crypt('pass', gen_salt('bf')), 'Req', 'Exec', '99922000-0000-0000-0000-000000000001'),
  -- Head of the one ฝ่าย below.
  ('99922000-0000-0000-0000-000000000003', '99921000-0000-0000-0000-000000000001',
   'req-head@test.local', crypt('pass', gen_salt('bf')), 'Req', 'Head', '99922000-0000-0000-0000-000000000001'),
  -- An ordinary member of that ฝ่าย.
  ('99922000-0000-0000-0000-000000000004', '99921000-0000-0000-0000-000000000001',
   'req-member@test.local', crypt('pass', gen_salt('bf')), 'Req', 'Member', '99922000-0000-0000-0000-000000000001'),
  -- Belongs to no department at all.
  ('99922000-0000-0000-0000-000000000005', '99921000-0000-0000-0000-000000000001',
   'req-lone@test.local', crypt('pass', gen_salt('bf')), 'Req', 'Lone', '99922000-0000-0000-0000-000000000001'),
  ('99922000-0000-0000-0000-000000000006', '99921000-0000-0000-0000-000000000001',
   'req-student@test.local', crypt('pass', gen_salt('bf')), 'Req', 'Student', '99922000-0000-0000-0000-000000000001'),
  -- School B: party to nothing created in School A.
  ('99922000-0000-0000-0000-000000000007', '99921000-0000-0000-0000-000000000002',
   'req-execb@test.local', crypt('pass', gen_salt('bf')), 'Req', 'ExecB', '99922000-0000-0000-0000-000000000007'),
  -- School B's own school_admin — specifically to prove the admin-override
  -- branch is scoped by school_id, not just by role.
  ('99922000-0000-0000-0000-000000000008', '99921000-0000-0000-0000-000000000002',
   'req-adminb@test.local', crypt('pass', gen_salt('bf')), 'Req', 'AdminB', '99922000-0000-0000-0000-000000000007');

insert into user_roles (user_id, role, school_id, granted_by) values
  ('99922000-0000-0000-0000-000000000001', 'school_admin', '99921000-0000-0000-0000-000000000001', '99922000-0000-0000-0000-000000000001'),
  ('99922000-0000-0000-0000-000000000002', 'executive',    '99921000-0000-0000-0000-000000000001', '99922000-0000-0000-0000-000000000001'),
  ('99922000-0000-0000-0000-000000000003', 'teacher',      '99921000-0000-0000-0000-000000000001', '99922000-0000-0000-0000-000000000001'),
  ('99922000-0000-0000-0000-000000000004', 'teacher',      '99921000-0000-0000-0000-000000000001', '99922000-0000-0000-0000-000000000001'),
  ('99922000-0000-0000-0000-000000000005', 'teacher',      '99921000-0000-0000-0000-000000000001', '99922000-0000-0000-0000-000000000001'),
  ('99922000-0000-0000-0000-000000000006', 'student',      '99921000-0000-0000-0000-000000000001', '99922000-0000-0000-0000-000000000001'),
  ('99922000-0000-0000-0000-000000000007', 'executive',    '99921000-0000-0000-0000-000000000002', '99922000-0000-0000-0000-000000000007'),
  ('99922000-0000-0000-0000-000000000008', 'school_admin', '99921000-0000-0000-0000-000000000002', '99922000-0000-0000-0000-000000000007');

insert into sessions (user_id, active_role, active_school_id, token_hash, expires_at) values
  ('99922000-0000-0000-0000-000000000001', 'school_admin', '99921000-0000-0000-0000-000000000001',
   encode(digest('sr-admin-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('99922000-0000-0000-0000-000000000002', 'executive', '99921000-0000-0000-0000-000000000001',
   encode(digest('sr-exec-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('99922000-0000-0000-0000-000000000003', 'teacher', '99921000-0000-0000-0000-000000000001',
   encode(digest('sr-head-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('99922000-0000-0000-0000-000000000004', 'teacher', '99921000-0000-0000-0000-000000000001',
   encode(digest('sr-member-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('99922000-0000-0000-0000-000000000005', 'teacher', '99921000-0000-0000-0000-000000000001',
   encode(digest('sr-lone-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('99922000-0000-0000-0000-000000000006', 'student', '99921000-0000-0000-0000-000000000001',
   encode(digest('sr-student-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('99922000-0000-0000-0000-000000000007', 'executive', '99921000-0000-0000-0000-000000000002',
   encode(digest('sr-execb-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('99922000-0000-0000-0000-000000000008', 'school_admin', '99921000-0000-0000-0000-000000000002',
   encode(digest('sr-adminb-token', 'sha256'), 'hex'), now() + interval '1 hour');

insert into departments (id, school_id, name, kind, sort_order, created_by) values
  ('99923000-0000-0000-0000-000000000001', '99921000-0000-0000-0000-000000000001',
   'ฝ่ายทดสอบคำขอ', 'administrative', 1, '99922000-0000-0000-0000-000000000001');

insert into department_members (department_id, user_id, is_head, assigned_by) values
  ('99923000-0000-0000-0000-000000000001', '99922000-0000-0000-0000-000000000003',
   true, '99922000-0000-0000-0000-000000000001'),
  ('99923000-0000-0000-0000-000000000001', '99922000-0000-0000-0000-000000000004',
   false, '99922000-0000-0000-0000-000000000001');

-- ---------------------------------------------------------------------------
-- create_staff_request — validation and routing
-- ---------------------------------------------------------------------------

select throws_ok(
  $$ select create_staff_request('sr-student-token', 'meet_request', 'ขอเข้าพบ', current_date) $$,
  'forbidden',
  'a student cannot file a staff request'
);

select throws_ok(
  $$ select create_staff_request('sr-exec-token', 'meet_request', 'ขอเข้าพบ', current_date) $$,
  'forbidden',
  'the director cannot file one either — they are the fixed level-2 approver'
);

select throws_ok(
  $$ select create_staff_request('sr-member-token', 'sabbatical', 'พักร้อนยาว', current_date) $$,
  'invalid_request_type',
  'request_type is constrained to the three the schema knows'
);

select throws_ok(
  $$ select create_staff_request('sr-member-token', 'meet_request', '   ', current_date) $$,
  'subject_required',
  'a blank subject is refused'
);

select throws_ok(
  $$ select create_staff_request('sr-member-token', 'meet_request', 'ขอเข้าพบ',
       current_date, current_date - 1) $$,
  'invalid_date_range',
  'an end date before the start is refused'
);

select throws_ok(
  $$ select create_staff_request('sr-member-token', 'meet_request', 'ขอเข้าพบหลายวัน',
       current_date, current_date + 2) $$,
  'single_day_only',
  'a meet_request spanning several days is refused — it is a single event, not a range'
);

select throws_ok(
  $$ select create_staff_request('sr-head-token', 'meeting_request', 'ขอจัดประชุมหลายวัน',
       current_date, current_date + 1) $$,
  'single_day_only',
  'the same rule applies to meeting_request'
);

select throws_ok(
  $$ select create_staff_request('sr-lone-token', 'official_duty', 'ไปราชการยาวเกินไป',
       current_date, current_date + 91) $$,
  'range_too_long',
  'an official_duty request spanning more than 90 days is refused'
);

select lives_ok(
  $$ select create_staff_request('sr-member-token', 'official_duty', 'ไปราชการพอดีเพดาน',
       current_date, current_date + 90) $$,
  'exactly 90 days is still allowed — the cap is a ceiling, not off-by-one'
);

select lives_ok(
  $$ select create_staff_request('sr-member-token', 'meet_request', 'ขอเข้าพบผอ.เรื่องทดสอบ',
       current_date + 3) $$,
  'a ฝ่าย member with a real head files a request'
);

select is(
  (select status from staff_requests where subject = 'ขอเข้าพบผอ.เรื่องทดสอบ'),
  'pending_head',
  'it starts at level 1 — the member has a real head to route to'
);

select lives_ok(
  $$ select create_staff_request('sr-head-token', 'meeting_request', 'ขอจัดประชุมฝ่าย',
       current_date + 5) $$,
  'the ฝ่าย head files their own request'
);

select is(
  (select status from staff_requests where subject = 'ขอจัดประชุมฝ่าย'),
  'pending_executive',
  'a head has nobody above them at level 1 — it starts at level 2 directly, not auto-approved'
);

select lives_ok(
  $$ select create_staff_request('sr-lone-token', 'official_duty', 'ไปราชการอบรม',
       current_date + 1, current_date + 3, 'อบรม AIoT', 'ศูนย์ฝึกอบรมจังหวัด') $$,
  'a teacher with no department files an official-duty request spanning 3 days'
);

select is(
  (select status from staff_requests where subject = 'ไปราชการอบรม'),
  'pending_executive',
  'nobody to route level 1 to — also starts at level 2 directly'
);

select is(
  (select bool_or(type = 'staff_request_pending_head') from notifications
    where user_id = '99922000-0000-0000-0000-000000000003'),
  true,
  'the real head is notified of the request routed to them'
);

select is(
  (select bool_or(type = 'staff_request_pending_executive' and body = 'ขอจัดประชุมฝ่าย')
     from notifications where user_id = '99922000-0000-0000-0000-000000000002'),
  true,
  'the director is notified directly when level 1 is skipped'
);

-- ---------------------------------------------------------------------------
-- review_staff_request — level 1 (หัวหน้าฝ่าย)
-- ---------------------------------------------------------------------------

select throws_ok(
  $$ select review_staff_request('sr-member-token',
       (select id from staff_requests where subject = 'ขอเข้าพบผอ.เรื่องทดสอบ'), true) $$,
  'forbidden',
  'the requester cannot approve their own level-1 stage'
);

select throws_ok(
  $$ select review_staff_request('sr-lone-token',
       (select id from staff_requests where subject = 'ขอเข้าพบผอ.เรื่องทดสอบ'), true) $$,
  'forbidden',
  'someone who is not this ฝ่าย''s head cannot decide it'
);

select lives_ok(
  $$ select review_staff_request('sr-head-token',
       (select id from staff_requests where subject = 'ขอเข้าพบผอ.เรื่องทดสอบ'), true, 'เห็นชอบ') $$,
  'the real head approves it'
);

select is(
  (select status from staff_requests where subject = 'ขอเข้าพบผอ.เรื่องทดสอบ'),
  'pending_executive',
  'approval at level 1 advances it to level 2, not straight to approved'
);

select is(
  (select head_decision from staff_requests where subject = 'ขอเข้าพบผอ.เรื่องทดสอบ'),
  'approved',
  'the head''s own decision is recorded distinctly from the overall status'
);

select throws_ok(
  $$ select review_staff_request('sr-head-token',
       (select id from staff_requests where subject = 'ขอเข้าพบผอ.เรื่องทดสอบ'), true) $$,
  'forbidden',
  'once advanced to level 2, the level-1 head has no authority over it any more — not even to re-approve'
);

select lives_ok(
  $$ select create_staff_request('sr-member-token', 'meeting_request', 'ขอจัดประชุมกลุ่มเล็ก',
       current_date + 4) $$,
  'the member files a second request, to test the school_admin override'
);

select lives_ok(
  $$ select review_staff_request('sr-admin-token',
       (select id from staff_requests where subject = 'ขอจัดประชุมกลุ่มเล็ก'), true) $$,
  'school_admin may decide a level-1 stage without being that ฝ่าย''s head'
);

select lives_ok(
  $$ select create_staff_request('sr-member-token', 'meet_request', 'ขอเข้าพบเรื่องจะถูกปฏิเสธ',
       current_date + 2) $$,
  'a third request is filed, to be rejected at level 1'
);

select lives_ok(
  $$ select review_staff_request('sr-head-token',
       (select id from staff_requests where subject = 'ขอเข้าพบเรื่องจะถูกปฏิเสธ'), false,
       'ไม่จำเป็นในตอนนี้') $$,
  'the head rejects it instead, with a reason'
);

select is(
  (select status from staff_requests where subject = 'ขอเข้าพบเรื่องจะถูกปฏิเสธ'),
  'rejected',
  'a level-1 rejection is terminal — it never reaches the director'
);

select is(
  (select bool_or(type = 'staff_request_rejected') from notifications
    where user_id = '99922000-0000-0000-0000-000000000004'),
  true,
  'the requester is told it was rejected'
);

select throws_ok(
  $$ select review_staff_request('sr-head-token',
       (select id from staff_requests where subject = 'ขอเข้าพบเรื่องจะถูกปฏิเสธ'), true) $$,
  'already_reviewed',
  'a request already settled (rejected) cannot be decided again, in either direction'
);

-- ---------------------------------------------------------------------------
-- review_staff_request — level 2 (ผอ.)
-- ---------------------------------------------------------------------------

select throws_ok(
  $$ select review_staff_request('sr-head-token',
       (select id from staff_requests where subject = 'ขอเข้าพบผอ.เรื่องทดสอบ'), true) $$,
  'forbidden',
  'a ฝ่าย head has no authority at level 2 — only the director or an admin'
);

select lives_ok(
  $$ select review_staff_request('sr-exec-token',
       (select id from staff_requests where subject = 'ขอเข้าพบผอ.เรื่องทดสอบ'), true, 'อนุมัติ') $$,
  'the director approves the meet_request at level 2'
);

select is(
  (select status from staff_requests where subject = 'ขอเข้าพบผอ.เรื่องทดสอบ'),
  'approved',
  'both stages decided — the request is now fully approved'
);

select is(
  (select count(*)::int from staff_attendance_records
    where user_id = '99922000-0000-0000-0000-000000000004'),
  0,
  'an approved meet_request never touches attendance — only official_duty does'
);

-- Simulate a day the requester had already checked in for, to prove the
-- automatic write really overwrites rather than skipping an existing row.
insert into staff_attendance_records (school_id, user_id, work_date, status, source, recorded_by)
values (
  '99921000-0000-0000-0000-000000000001', '99922000-0000-0000-0000-000000000005',
  current_date + 1, 'present', 'self', '99922000-0000-0000-0000-000000000005'
);

select lives_ok(
  $$ select review_staff_request('sr-exec-token',
       (select id from staff_requests where subject = 'ไปราชการอบรม'), true) $$,
  'the director approves the 3-day official-duty request'
);

select is(
  (select status from staff_requests where subject = 'ไปราชการอบรม'),
  'approved',
  'and the request itself is marked approved'
);

select is(
  (select count(*)::int from staff_attendance_records
    where user_id = '99922000-0000-0000-0000-000000000005'
      and work_date between current_date + 1 and current_date + 3
      and status = 'official_duty'),
  3,
  'all three days of the approved trip are now official_duty — the entire point of this table'
);

select is(
  (select status from staff_attendance_records
    where user_id = '99922000-0000-0000-0000-000000000005' and work_date = current_date + 1),
  'official_duty',
  'the day that already had a real check-in is overwritten, not left as present'
);

select is(
  (select source from staff_attendance_records
    where user_id = '99922000-0000-0000-0000-000000000005' and work_date = current_date + 2),
  'admin',
  'a freshly-created day is sourced as admin-entered, matching the manual record_staff_attendance path'
);

-- ---------------------------------------------------------------------------
-- cancel_staff_request
-- ---------------------------------------------------------------------------

select lives_ok(
  $$ select create_staff_request('sr-lone-token', 'meet_request', 'ขอเข้าพบแล้วจะยกเลิก',
       current_date + 6) $$,
  'a request is filed purely to be withdrawn'
);

select throws_ok(
  $$ select cancel_staff_request('sr-member-token',
       (select id from staff_requests where subject = 'ขอเข้าพบแล้วจะยกเลิก')) $$,
  'forbidden',
  'someone other than the requester (or an admin) cannot withdraw it'
);

select lives_ok(
  $$ select cancel_staff_request('sr-lone-token',
       (select id from staff_requests where subject = 'ขอเข้าพบแล้วจะยกเลิก')) $$,
  'the requester withdraws their own, still-pending request'
);

select throws_ok(
  $$ select cancel_staff_request('sr-lone-token',
       (select id from staff_requests where subject = 'ขอเข้าพบแล้วจะยกเลิก')) $$,
  'already_reviewed',
  'a already-cancelled request cannot be cancelled again'
);

-- ---------------------------------------------------------------------------
-- list_staff_requests — scope and the pending_for_me queue
-- ---------------------------------------------------------------------------

select throws_ok(
  $$ select * from list_staff_requests('sr-student-token') $$,
  'forbidden',
  'a student cannot browse the register'
);

select is(
  (select coalesce(bool_or(subject = 'ขอจัดประชุมกลุ่มเล็ก'), false)
     from list_staff_requests('sr-lone-token')),
  false,
  'a plain teacher does not see another teacher''s unrelated request'
);

select is(
  (select bool_or(subject = 'ขอจัดประชุมกลุ่มเล็ก') from list_staff_requests('sr-head-token')),
  true,
  'the ฝ่าย head sees their department''s requests even when not the requester'
);

select is(
  (select count(*)::int from list_staff_requests('sr-exec-token')),
  (select count(*)::int from staff_requests where school_id = '99921000-0000-0000-0000-000000000001'),
  'the director sees every request in the school'
);

select is(
  (select coalesce(bool_or(subject = 'ขอเข้าพบเรื่องจะถูกปฏิเสธ'), false)
     from list_staff_requests('sr-head-token', null, null, true)),
  false,
  'pending_for_me excludes a request already decided — it is no longer actionable'
);

select is(
  (select count(*)::int from list_staff_requests('sr-exec-token', 'pending_executive')),
  (select count(*)::int from staff_requests where status = 'pending_executive'
    and school_id = '99921000-0000-0000-0000-000000000001'),
  'p_status filters the register down to the stage asked for'
);

select is(
  (select count(*)::int from list_staff_requests('sr-lone-token', null, 'official_duty')),
  1,
  'p_request_type filters to just the caller''s own official-duty filing'
);

-- ---------------------------------------------------------------------------
-- Cross-school isolation
-- ---------------------------------------------------------------------------

select is(
  (select count(*)::int from list_staff_requests('sr-execb-token')),
  0,
  'an executive of an unrelated school sees none of School A''s requests'
);

select throws_ok(
  $$ select review_staff_request('sr-execb-token',
       (select id from staff_requests where subject = 'ขอจัดประชุมฝ่าย'), true) $$,
  'forbidden',
  'nor may they decide one, despite passing the executive role check'
);

select throws_ok(
  $$ select cancel_staff_request('sr-execb-token',
       (select id from staff_requests where subject = 'ขอจัดประชุมฝ่าย')) $$,
  'forbidden',
  'nor withdraw one on someone else''s behalf across schools'
);

select throws_ok(
  $$ select cancel_staff_request('sr-adminb-token',
       (select id from staff_requests where subject = 'ขอจัดประชุมฝ่าย')) $$,
  'forbidden',
  'a school_admin''s override is scoped to their own school — being school_admin somewhere is not enough'
);

rollback;
