-- pgTAP Tests: staff_leave_attachments — file attachments for
-- staff_leave_requests (20260907060000).
--
-- What matters here: only the requester (it is their own leave) or an
-- admin override may attach or remove a file, scoped to the right school;
-- the storage path must sit under the school prefix the access-check
-- itself returned, never one the caller picks; visibility for reading the
-- register matches list_staff_leave_requests' own rule (requester, or
-- school_admin/executive/super_admin); and once a leave request has been
-- decided, an existing attachment becomes part of the record — new files
-- may still be added, but nothing may be removed.

begin;

create extension if not exists pgtap with schema extensions;
select plan(23);

insert into packages (id, name, license_type)
values ('99930000-0000-0000-0000-000000000001', 'Leave attachments test package', 'perpetual');

insert into schools (id, package_id, name, school_code) values
  ('99931000-0000-0000-0000-000000000001', '99930000-0000-0000-0000-000000000001', 'Leave Attach School A', 'LVA-A'),
  ('99931000-0000-0000-0000-000000000002', '99930000-0000-0000-0000-000000000001', 'Leave Attach School B', 'LVA-B');

insert into users (
  id, school_id, email, password_hash, first_name, last_name, created_by
) values
  ('99932000-0000-0000-0000-000000000001', '99931000-0000-0000-0000-000000000001',
   'lva-admin@test.local', crypt('pass', gen_salt('bf')), 'Lva', 'Admin', '99932000-0000-0000-0000-000000000001'),
  ('99932000-0000-0000-0000-000000000002', '99931000-0000-0000-0000-000000000001',
   'lva-teacher@test.local', crypt('pass', gen_salt('bf')), 'Lva', 'Teacher', '99932000-0000-0000-0000-000000000001'),
  -- Neither the requester nor an admin.
  ('99932000-0000-0000-0000-000000000003', '99931000-0000-0000-0000-000000000001',
   'lva-outsider@test.local', crypt('pass', gen_salt('bf')), 'Lva', 'Outsider', '99932000-0000-0000-0000-000000000001'),
  ('99932000-0000-0000-0000-000000000004', '99931000-0000-0000-0000-000000000001',
   'lva-exec@test.local', crypt('pass', gen_salt('bf')), 'Lva', 'Exec', '99932000-0000-0000-0000-000000000001'),
  -- School B: party to nothing created in School A.
  ('99932000-0000-0000-0000-000000000005', '99931000-0000-0000-0000-000000000002',
   'lva-outsiderb@test.local', crypt('pass', gen_salt('bf')), 'Lva', 'OutsiderB', '99932000-0000-0000-0000-000000000005');

insert into user_roles (user_id, role, school_id, granted_by) values
  ('99932000-0000-0000-0000-000000000001', 'school_admin', '99931000-0000-0000-0000-000000000001', '99932000-0000-0000-0000-000000000001'),
  ('99932000-0000-0000-0000-000000000002', 'teacher',      '99931000-0000-0000-0000-000000000001', '99932000-0000-0000-0000-000000000001'),
  ('99932000-0000-0000-0000-000000000003', 'teacher',      '99931000-0000-0000-0000-000000000001', '99932000-0000-0000-0000-000000000001'),
  ('99932000-0000-0000-0000-000000000004', 'executive',    '99931000-0000-0000-0000-000000000001', '99932000-0000-0000-0000-000000000001'),
  ('99932000-0000-0000-0000-000000000005', 'school_admin', '99931000-0000-0000-0000-000000000002', '99932000-0000-0000-0000-000000000005');

insert into sessions (user_id, active_role, active_school_id, token_hash, expires_at) values
  ('99932000-0000-0000-0000-000000000001', 'school_admin', '99931000-0000-0000-0000-000000000001',
   encode(digest('lva-admin-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('99932000-0000-0000-0000-000000000002', 'teacher', '99931000-0000-0000-0000-000000000001',
   encode(digest('lva-teacher-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('99932000-0000-0000-0000-000000000003', 'teacher', '99931000-0000-0000-0000-000000000001',
   encode(digest('lva-outsider-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('99932000-0000-0000-0000-000000000004', 'executive', '99931000-0000-0000-0000-000000000001',
   encode(digest('lva-exec-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('99932000-0000-0000-0000-000000000005', 'school_admin', '99931000-0000-0000-0000-000000000002',
   encode(digest('lva-outsiderb-token', 'sha256'), 'hex'), now() + interval '1 hour');

select lives_ok(
  $$ select request_staff_leave('lva-teacher-token', 'sick', current_date, current_date,
       'ไข้หวัดใหญ่') $$,
  'the teacher files a real sick-leave request'
);

-- ---------------------------------------------------------------------------
-- assert_staff_leave_attachment_upload_access
-- ---------------------------------------------------------------------------

select throws_ok(
  $$ select assert_staff_leave_attachment_upload_access('lva-outsider-token',
       (select id from staff_leave_requests where reason = 'ไข้หวัดใหญ่')) $$,
  'forbidden',
  'someone who is neither the requester nor an admin cannot attach a file'
);

select is(
  (select assert_staff_leave_attachment_upload_access('lva-teacher-token',
     (select id from staff_leave_requests where reason = 'ไข้หวัดใหญ่'))),
  '99931000-0000-0000-0000-000000000001'::uuid,
  'the requester may attach — it is their own leave'
);

select is(
  (select assert_staff_leave_attachment_upload_access('lva-admin-token',
     (select id from staff_leave_requests where reason = 'ไข้หวัดใหญ่'))),
  '99931000-0000-0000-0000-000000000001'::uuid,
  'school_admin may attach on the requester''s behalf'
);

select throws_ok(
  $$ select assert_staff_leave_attachment_upload_access('lva-outsiderb-token',
       (select id from staff_leave_requests where reason = 'ไข้หวัดใหญ่')) $$,
  'forbidden',
  'an admin of an unrelated school gets no override here either'
);

-- ---------------------------------------------------------------------------
-- register_staff_leave_attachment
-- ---------------------------------------------------------------------------

select throws_ok(
  $$ select register_staff_leave_attachment('lva-teacher-token',
       (select id from staff_leave_requests where reason = 'ไข้หวัดใหญ่'),
       '99931000-0000-0000-0000-000000000002/wrong-school.pdf', 'x.pdf', 100) $$,
  'invalid_storage_path',
  'a path under another school''s prefix is refused'
);

select throws_ok(
  $$ select register_staff_leave_attachment('lva-teacher-token',
       (select id from staff_leave_requests where reason = 'ไข้หวัดใหญ่'),
       '99931000-0000-0000-0000-000000000001/a.pdf', '   ', 100) $$,
  'file_required',
  'a blank file name is refused'
);

select lives_ok(
  $$ select register_staff_leave_attachment('lva-teacher-token',
       (select id from staff_leave_requests where reason = 'ไข้หวัดใหญ่'),
       '99931000-0000-0000-0000-000000000001/cert-1.pdf',
       'ใบรับรองแพทย์.pdf', 204800) $$,
  'the requester registers a real medical certificate'
);

select is(
  (select file_type from staff_leave_attachments where file_name = 'ใบรับรองแพทย์.pdf'),
  'pdf'::varchar,
  'the file type is derived from the extension by the server'
);

-- ---------------------------------------------------------------------------
-- list_staff_leave_attachments
-- ---------------------------------------------------------------------------

select throws_ok(
  $$ select * from list_staff_leave_attachments('lva-outsider-token',
       (select id from staff_leave_requests where reason = 'ไข้หวัดใหญ่')) $$,
  'forbidden',
  'someone who is neither the requester nor school staff-facing cannot browse it'
);

select is(
  (select count(*)::int from list_staff_leave_attachments('lva-teacher-token',
     (select id from staff_leave_requests where reason = 'ไข้หวัดใหญ่'))),
  1,
  'the requester sees their own attachment'
);

select is(
  (select count(*)::int from list_staff_leave_attachments('lva-exec-token',
     (select id from staff_leave_requests where reason = 'ไข้หวัดใหญ่'))),
  1,
  'the director, who reviews leave-adjacent decisions school-wide, also sees it'
);

select throws_ok(
  $$ select * from list_staff_leave_attachments('lva-outsiderb-token',
       (select id from staff_leave_requests where reason = 'ไข้หวัดใหญ่')) $$,
  'forbidden',
  'an admin of another school cannot browse it either'
);

-- ---------------------------------------------------------------------------
-- get_staff_leave_attachment_for_download
-- ---------------------------------------------------------------------------

select throws_ok(
  $$ select get_staff_leave_attachment_for_download('lva-outsider-token',
       (select id from staff_leave_attachments where file_name = 'ใบรับรองแพทย์.pdf')) $$,
  'forbidden',
  'an outsider cannot be handed a download URL for it'
);

select is(
  (select file_name from get_staff_leave_attachment_for_download('lva-teacher-token',
     (select id from staff_leave_attachments where file_name = 'ใบรับรองแพทย์.pdf'))),
  'ใบรับรองแพทย์.pdf'::varchar,
  'the requester can be handed one'
);

select is(
  (select file_name from get_staff_leave_attachment_for_download('lva-admin-token',
     (select id from staff_leave_attachments where file_name = 'ใบรับรองแพทย์.pdf'))),
  'ใบรับรองแพทย์.pdf'::varchar,
  'so can school_admin'
);

-- ---------------------------------------------------------------------------
-- remove_staff_leave_attachment — allowed while pending, blocked after
-- ---------------------------------------------------------------------------

select lives_ok(
  $$ select register_staff_leave_attachment('lva-teacher-token',
       (select id from staff_leave_requests where reason = 'ไข้หวัดใหญ่'),
       '99931000-0000-0000-0000-000000000001/throwaway.pdf',
       'ทิ้งไฟล์นี้.pdf', 100) $$,
  'a second, throwaway file is registered to test removal'
);

select throws_ok(
  $$ select remove_staff_leave_attachment('lva-outsider-token',
       (select id from staff_leave_attachments where file_name = 'ทิ้งไฟล์นี้.pdf')) $$,
  'forbidden',
  'an outsider cannot remove a file that is not theirs to manage'
);

select lives_ok(
  $$ select remove_staff_leave_attachment('lva-teacher-token',
       (select id from staff_leave_attachments where file_name = 'ทิ้งไฟล์นี้.pdf')) $$,
  'the requester removes it while the request is still pending'
);

select is(
  (select count(*)::int from staff_leave_attachments where file_name = 'ทิ้งไฟล์นี้.pdf'),
  0,
  'it is really gone'
);

select lives_ok(
  $$ select review_staff_leave_request('lva-admin-token',
       (select id from staff_leave_requests where reason = 'ไข้หวัดใหญ่'), true, 'อนุมัติ') $$,
  'school_admin approves the leave request'
);

select lives_ok(
  $$ select register_staff_leave_attachment('lva-teacher-token',
       (select id from staff_leave_requests where reason = 'ไข้หวัดใหญ่'),
       '99931000-0000-0000-0000-000000000001/follow-up.pdf',
       'เอกสารเพิ่มเติมภายหลัง.pdf', 100) $$,
  'a follow-up document may still be added after the decision'
);

select throws_ok(
  $$ select remove_staff_leave_attachment('lva-teacher-token',
       (select id from staff_leave_attachments where file_name = 'ใบรับรองแพทย์.pdf')) $$,
  'already_reviewed',
  'but nothing may be removed once the request has been decided — the original certificate stays part of the record'
);

rollback;
