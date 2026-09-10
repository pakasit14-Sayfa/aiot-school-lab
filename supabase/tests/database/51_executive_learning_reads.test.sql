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


insert into academic_years(id,school_id,name,start_date,end_date) values
 ('99824000-0000-0000-0000-000000000001','99821000-0000-0000-0000-000000000001','QA year',current_date-30,current_date+300);
insert into user_roles(user_id,role,school_id,granted_by) values
 ('99822000-0000-0000-0000-000000000003','student','99821000-0000-0000-0000-000000000001','99822000-0000-0000-0000-000000000002'),
 ('99822000-0000-0000-0000-000000000007','student','99821000-0000-0000-0000-000000000002','99822000-0000-0000-0000-000000000007');
insert into student_profiles(student_id,academic_year_id,grade_level,room,created_by) values
 ('99822000-0000-0000-0000-000000000003','99824000-0000-0000-0000-000000000001','ม.1','1','99822000-0000-0000-0000-000000000002'),
 ('99822000-0000-0000-0000-000000000006','99824000-0000-0000-0000-000000000001','ม.1','1','99822000-0000-0000-0000-000000000002');
select is((select sum(unknown_count)::int from list_school_homeroom_attendance('mtg-exec-token',current_date)),2,'no records means two unchecked, not absent');
insert into homeroom_attendance_records(student_id,academic_year_id,grade_level,room,class_date,status,marked_by) values
 ('99822000-0000-0000-0000-000000000006','99824000-0000-0000-0000-000000000001','ม.1','1',current_date,'present','99822000-0000-0000-0000-000000000003');
select is((select sum(present_count)::int from list_school_homeroom_attendance('mtg-exec-token',current_date)),1,'only recorded attendance counts as present');
select is((select sum(unknown_count)::int from list_school_homeroom_attendance('mtg-exec-token',current_date)),1,'remaining student stays unknown');
select is((select sum(absent_count)::int from list_school_homeroom_attendance('mtg-exec-token',current_date)),0,'unknown is not absent');
select is((select sum(student_count)::int from list_school_homeroom_attendance('mtg-execb-token',current_date)),1,'other school sees only its own student');
select is((select sum(unknown_count)::int from list_school_homeroom_attendance('mtg-exec-token',current_date-1)),2,'date filter does not borrow records from today');
select throws_ok($$select list_school_homeroom_attendance('mtg-teacher1-token',current_date)$$,'P0001','forbidden','teacher cannot read school-wide student attendance');
select throws_ok($$select list_school_homeroom_attendance('bad-token',current_date)$$,'P0001','invalid_session','invalid token rejected');
select lives_ok($$select * from list_learning_track_rooms('mtg-exec-token')$$,'executive may read rooms without admin role');
insert into student_support_cases(id,school_id,student_id,title,created_by) values
 ('99825000-0000-0000-0000-000000000001','99821000-0000-0000-0000-000000000001','99822000-0000-0000-0000-000000000006','School A case','99822000-0000-0000-0000-000000000003'),
 ('99825000-0000-0000-0000-000000000002','99821000-0000-0000-0000-000000000002','99822000-0000-0000-0000-000000000007','School B private case','99822000-0000-0000-0000-000000000007');
insert into student_support_interventions(case_id,action_type,notes,recorded_by) values
 ('99825000-0000-0000-0000-000000000001','observation','A notes','99822000-0000-0000-0000-000000000003'),
 ('99825000-0000-0000-0000-000000000002','observation','B notes','99822000-0000-0000-0000-000000000007');
select is((select count(*)::int from list_student_support_cases('mtg-exec-token')),1,'executive cases remain school-scoped');
select is((select notes from list_student_support_interventions('mtg-exec-token','99825000-0000-0000-0000-000000000001')),'A notes','executive reads real intervention notes');
select throws_ok($$select * from list_student_support_interventions('mtg-exec-token','99825000-0000-0000-0000-000000000002')$$,'P0001','forbidden','executive cannot read other-school case history');
select throws_ok($$select * from list_student_support_interventions('mtg-teacher1-token','99825000-0000-0000-0000-000000000002')$$,'P0001','forbidden','teacher cannot read other-school case history');
select ok(has_function_privilege('anon','public.list_school_homeroom_attendance(text,date)','EXECUTE'),'attendance supports the custom-session anon client');
create temp table bug3_track as select create_learning_track('mtg-admin-token','Empty track QA','#123456') as id;
select is((select room_count from get_learning_track_overview('mtg-exec-token')),0::bigint,'an empty track has no phantom classroom');
select is((select student_count from get_learning_track_overview('mtg-exec-token')),0::bigint,'an empty track has no students');
select is((select avg_grade_percent from get_learning_track_overview('mtg-exec-token')),null::numeric,'an empty track has no fabricated score');
select set_learning_track_room('mtg-admin-token','ม.1','1',(select id from bug3_track));
select is((select room_count from get_learning_track_overview('mtg-exec-token')),1::bigint,'populated track counts its real classroom once');
select is((select student_count from get_learning_track_overview('mtg-exec-token')),2::bigint,'populated track counts registered students');
select * from finish();
rollback;
