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
insert into devices(id, school_id, type, name, status, registered_by, device_code, kit_code) values
('99826000-0000-0000-0000-000000000001','99821000-0000-0000-0000-000000000001','light_sensor','Actual school A device','offline','99822000-0000-0000-0000-000000000001','DEV-A','KIT-A'),
('99826000-0000-0000-0000-000000000002','99821000-0000-0000-0000-000000000002','light_sensor','Private school B device','online','99822000-0000-0000-0000-000000000007','DEV-B','KIT-B');
select is(get_school_device_by_code('mtg-exec-token',' DEV-A ')->>'name','Actual school A device','executive resolves real code after trimming');
select is(get_school_device_by_code('mtg-exec-token','KIT-A')->>'status','offline','kit code returns actual status, not ready-to-borrow');
select is(get_school_device_by_code('mtg-exec-token','99826000-0000-0000-0000-000000000001')->>'device_code','DEV-A','UUID identity supported');
select is(get_school_device_by_code('mtg-exec-token','unknown'),null::jsonb,'unknown code is absent');
select is(get_school_device_by_code('mtg-exec-token','DEV-B'),null::jsonb,'other-school code is hidden');
select is(get_school_device_by_code('mtg-execb-token','DEV-B')->>'name','Private school B device','other school can read its own device');
select throws_ok($$select get_school_device_by_code('mtg-student-token','DEV-A')$$,'P0001','forbidden','student cannot use staff scanner');
select throws_ok($$select get_school_device_by_code('bad-token','DEV-A')$$,'P0001','invalid_session','invalid session rejected');
select throws_ok($$select get_school_device_by_code('mtg-exec-token',' ')$$,'P0001','code_required','empty code rejected');
select is(get_school_device_by_code('mtg-teacher1-token','DEV-A')->>'name','Actual school A device','teacher reads same-school identity');
-- A kit code can collide with another device code: never silently choose one.
insert into devices(id, school_id, type, name, status, registered_by, device_code) values
('99826000-0000-0000-0000-000000000003','99821000-0000-0000-0000-000000000001','light_sensor','Ambiguous fixture','offline','99822000-0000-0000-0000-000000000001','KIT-A');
select throws_ok($$select get_school_device_by_code('mtg-exec-token','KIT-A')$$,'P0001','ambiguous_device_code','ambiguous code never selects an arbitrary device');
select ok(has_function_privilege('anon','get_school_device_by_code(text,text)','EXECUTE'),'custom session anonymous transport allowed');
select ok(not has_function_privilege('service_role','get_school_device_by_code(text,text)','EXECUTE'),'no service-role transport grant needed');
select * from finish();
rollback;
