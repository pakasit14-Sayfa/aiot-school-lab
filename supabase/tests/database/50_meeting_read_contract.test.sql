-- pgTAP Tests: ระบบประชุม (meetings, attendees, agenda, minutes, addenda,
-- resolutions, attachments, external attendees, attendance, notifications,
-- staff calendar) — schema from 20260907030000 + 20260907040000.
--
-- What matters here, per DECISIONS_2026-09-07.md: a one-on-one summons is
-- visible only to its two parties and school_admin (M1); it cannot be
-- declined, only accepted or postponed with a reason (M2); minutes go
-- draft → final and a finalised record can only be appended to, never
-- edited (M3); "ไม่ต้องมีบันทึก" and "ยังไม่ได้บันทึก" must stay two
-- different facts (M4); a summons consumes no meeting number so the
-- school's numbered series has no gaps (B); attendance is a three-state
-- fact taken once, defaulting to "not yet checked", never "everyone came"
-- (E); external guests are name + organisation only, no account (C).

begin;

create extension if not exists pgtap with schema extensions;
select no_plan();

insert into packages (id, name, license_type)
values ('99820000-0000-0000-0000-000000000001', 'Meetings test package', 'perpetual');

insert into schools (id, package_id, name, school_code) values
  ('99821000-0000-0000-0000-000000000001', '99820000-0000-0000-0000-000000000001', 'Meeting School A', 'MTG-A'),
  ('99821000-0000-0000-0000-000000000002', '99820000-0000-0000-0000-000000000001', 'Meeting School B', 'MTG-B');

insert into users (
  id, school_id, email, password_hash, first_name, last_name, created_by
) values
  ('99822000-0000-0000-0000-000000000001', '99821000-0000-0000-0000-000000000001',
   'mtg-exec@test.local', crypt('pass', gen_salt('bf')), 'Mtg', 'Exec', '99822000-0000-0000-0000-000000000001'),
  ('99822000-0000-0000-0000-000000000002', '99821000-0000-0000-0000-000000000001',
   'mtg-admin@test.local', crypt('pass', gen_salt('bf')), 'Mtg', 'Admin', '99822000-0000-0000-0000-000000000001'),
  -- The one-on-one's subject, and a department member.
  ('99822000-0000-0000-0000-000000000003', '99821000-0000-0000-0000-000000000001',
   'mtg-teacher1@test.local', crypt('pass', gen_salt('bf')), 'Mtg', 'Teacher1', '99822000-0000-0000-0000-000000000001'),
  -- Second department member.
  ('99822000-0000-0000-0000-000000000004', '99821000-0000-0000-0000-000000000001',
   'mtg-teacher2@test.local', crypt('pass', gen_salt('bf')), 'Mtg', 'Teacher2', '99822000-0000-0000-0000-000000000001'),
  -- In neither department nor invited to the group meeting: the outsider.
  ('99822000-0000-0000-0000-000000000005', '99821000-0000-0000-0000-000000000001',
   'mtg-teacher3@test.local', crypt('pass', gen_salt('bf')), 'Mtg', 'Teacher3', '99822000-0000-0000-0000-000000000001'),
  ('99822000-0000-0000-0000-000000000006', '99821000-0000-0000-0000-000000000001',
   'mtg-student@test.local', crypt('pass', gen_salt('bf')), 'Mtg', 'Student', '99822000-0000-0000-0000-000000000001'),
  -- School B: exists only to prove tenant isolation, never a party to
  -- anything created in School A below.
  ('99822000-0000-0000-0000-000000000007', '99821000-0000-0000-0000-000000000002',
   'mtg-execb@test.local', crypt('pass', gen_salt('bf')), 'Mtg', 'ExecB', '99822000-0000-0000-0000-000000000007');

insert into user_roles (user_id, role, school_id, granted_by) values
  ('99822000-0000-0000-0000-000000000001', 'executive',    '99821000-0000-0000-0000-000000000001', '99822000-0000-0000-0000-000000000001'),
  ('99822000-0000-0000-0000-000000000002', 'school_admin', '99821000-0000-0000-0000-000000000001', '99822000-0000-0000-0000-000000000001'),
  ('99822000-0000-0000-0000-000000000003', 'teacher',      '99821000-0000-0000-0000-000000000001', '99822000-0000-0000-0000-000000000001'),
  ('99822000-0000-0000-0000-000000000004', 'teacher',      '99821000-0000-0000-0000-000000000001', '99822000-0000-0000-0000-000000000001'),
  ('99822000-0000-0000-0000-000000000005', 'teacher',      '99821000-0000-0000-0000-000000000001', '99822000-0000-0000-0000-000000000001'),
  ('99822000-0000-0000-0000-000000000006', 'student',      '99821000-0000-0000-0000-000000000001', '99822000-0000-0000-0000-000000000001'),
  ('99822000-0000-0000-0000-000000000007', 'executive',    '99821000-0000-0000-0000-000000000002', '99822000-0000-0000-0000-000000000007');

insert into sessions (user_id, active_role, active_school_id, token_hash, expires_at) values
  ('99822000-0000-0000-0000-000000000001', 'executive', '99821000-0000-0000-0000-000000000001',
   encode(digest('mtg-exec-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('99822000-0000-0000-0000-000000000002', 'school_admin', '99821000-0000-0000-0000-000000000001',
   encode(digest('mtg-admin-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('99822000-0000-0000-0000-000000000003', 'teacher', '99821000-0000-0000-0000-000000000001',
   encode(digest('mtg-teacher1-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('99822000-0000-0000-0000-000000000004', 'teacher', '99821000-0000-0000-0000-000000000001',
   encode(digest('mtg-teacher2-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('99822000-0000-0000-0000-000000000005', 'teacher', '99821000-0000-0000-0000-000000000001',
   encode(digest('mtg-teacher3-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('99822000-0000-0000-0000-000000000006', 'student', '99821000-0000-0000-0000-000000000001',
   encode(digest('mtg-student-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('99822000-0000-0000-0000-000000000007', 'executive', '99821000-0000-0000-0000-000000000002',
   encode(digest('mtg-execb-token', 'sha256'), 'hex'), now() + interval '1 hour');

insert into departments (id, school_id, name, kind, sort_order, created_by) values
  ('99823000-0000-0000-0000-000000000001', '99821000-0000-0000-0000-000000000001',
   'ฝ่ายทดสอบประชุม', 'administrative', 1, '99822000-0000-0000-0000-000000000001');

insert into department_members (department_id, user_id, is_head, assigned_by) values
  ('99823000-0000-0000-0000-000000000001', '99822000-0000-0000-0000-000000000003',
   true, '99822000-0000-0000-0000-000000000001'),
  ('99823000-0000-0000-0000-000000000001', '99822000-0000-0000-0000-000000000004',
   false, '99822000-0000-0000-0000-000000000001');


select create_meeting('mtg-exec-token', 'private-contract-fixture', 'one_on_one',
 '2027-03-10 09:00+07', null, null, null, 'attendees', true,
 array['99822000-0000-0000-0000-000000000003']::uuid[]);
-- The unrelated colleague now holds executive too.
insert into user_roles(user_id, role, school_id, granted_by) values
 ('99822000-0000-0000-0000-000000000005','executive','99821000-0000-0000-0000-000000000001','99822000-0000-0000-0000-000000000001');
update sessions set active_role='executive' where token_hash=encode(digest('mtg-teacher3-token','sha256'),'hex');
select is((select count(*)::int from list_staff_calendar('mtg-teacher3-token') where title='private-contract-fixture'),0,
 'an unrelated executive cannot see a one-on-one on the calendar');
create temporary table contract_private as select id from meetings where title='private-contract-fixture';
select is(jsonb_array_length(list_meeting_records('mtg-teacher3-token')),0,'private meeting is absent from unrelated executive register');
select throws_ok(format('select get_meeting_detail(%L,%L::uuid)','mtg-teacher3-token',(select id from contract_private)),
 'P0001','forbidden','private detail rejects unrelated executive');
select throws_ok(format('select get_meeting_detail(%L,%L::uuid)','mtg-execb-token',(select id from contract_private)),
 'P0001','forbidden','detail rejects another school');
select throws_ok($$select list_meeting_records('mtg-student-token')$$,'P0001','forbidden','register rejects student role');
select is(get_meeting_detail('mtg-exec-token',(select id from contract_private))->'meeting'->>'can_manage','true','creator can manage');
select is(get_meeting_detail('mtg-teacher1-token',(select id from contract_private))->'meeting'->>'can_manage','false','subject cannot manage');
select is(get_meeting_detail('mtg-admin-token',(select id from contract_private))->'meeting'->>'can_manage','true','school admin can manage private record');
select is(get_meeting_detail('mtg-exec-token',(select id from contract_private))->'meeting'->>'meeting_no',null,'summons has no meeting number');
select is(get_meeting_detail('mtg-exec-token',(select id from contract_private))->'attendees'->0->>'attended',null,'new attendee is unchecked');
select save_meeting_minutes_draft('mtg-exec-token',(select id from contract_private),'canonical draft');
select is(get_meeting_detail('mtg-teacher1-token',(select id from contract_private))->'minutes','null'::jsonb,'subject cannot read draft');
select finalize_meeting_minutes('mtg-exec-token',(select id from contract_private));
create temporary table read_count as select count(*) n from audit_logs where action='meeting_minutes.read'
 and user_id='99822000-0000-0000-0000-000000000003';
select is(get_meeting_detail('mtg-teacher1-token',(select id from contract_private))->'minutes'->>'body','canonical draft','subject can read final');
select is((select count(*) from audit_logs where action='meeting_minutes.read'
 and user_id='99822000-0000-0000-0000-000000000003'),(select n+1 from read_count),'detail read audits private final exactly once');
create temporary table contract_group as select create_meeting('mtg-exec-token','group-contract-fixture','group',
 '2027-03-11 09:00+07',null,null,null,'attendees',false,array['99822000-0000-0000-0000-000000000003']::uuid[]) id;
select is(get_meeting_detail('mtg-exec-token',(select id from contract_group))->'meeting'->>'meeting_no','1','group receives first annual number');
select is(get_meeting_detail('mtg-exec-token',(select id from contract_group))->'meeting'->>'meeting_year','2570','number uses Buddhist year');
select is(get_meeting_detail('mtg-exec-token',(select id from contract_group))->'meeting'->>'minutes_expected','false','no minutes is explicit');
select add_meeting_external_attendee('mtg-exec-token',(select id from contract_group),'External Guest','Test Org');
select set_meeting_attendance('mtg-exec-token',(select id from contract_group),array['99822000-0000-0000-0000-000000000001']::uuid[],array[]::uuid[]);
select is((select a->>'attended' from jsonb_array_elements(get_meeting_detail('mtg-exec-token',(select id from contract_group))->'attendees') a
 where a->>'user_id'='99822000-0000-0000-0000-000000000003'),'false','unselected staff is confirmed absent');
select is(get_meeting_detail('mtg-exec-token',(select id from contract_group))->'external_attendees'->0->>'attended','false','unselected guest is confirmed absent');
select isnt(get_meeting_detail('mtg-exec-token',(select id from contract_group))->'meeting'->>'attendance_taken_at',null,'attendance timestamp returned');
select ok(has_function_privilege('anon','public.get_meeting_detail(text,uuid)','EXECUTE'),'anon RPC access uses custom sessions');
select ok(not has_function_privilege('service_role','public.get_meeting_detail(text,uuid)','EXECUTE'),'general details are not a service role entry point');
select ok(has_function_privilege('service_role','public.assert_meeting_attachment_upload_access(text,uuid)','EXECUTE'),'upload Edge Function can assert access');
select ok(has_function_privilege('service_role','public.get_meeting_attachment_for_download(text,uuid)','EXECUTE'),'download Edge Function can assert access');
select * from finish();
rollback;
