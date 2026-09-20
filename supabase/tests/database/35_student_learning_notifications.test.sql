-- admin_token_patched
begin;

create extension if not exists pgtap with schema extensions;
select plan(32);

insert into packages (id, name, license_type)
values ('49100000-0000-0000-0000-000000000001', 'Assignments test package', 'perpetual');

insert into schools (id, package_id, name, school_code) values
  ('49200000-0000-0000-0000-000000000001', '49100000-0000-0000-0000-000000000001', 'Assignments school A', 'ASG-A'),
  ('49200000-0000-0000-0000-000000000002', '49100000-0000-0000-0000-000000000001', 'Assignments school B', 'ASG-B');

insert into academic_years (id, school_id, name)
values ('49300000-0000-0000-0000-000000000001', '49200000-0000-0000-0000-000000000001', '2026');

insert into terms (id, academic_year_id, name)
values ('49400000-0000-0000-0000-000000000001', '49300000-0000-0000-0000-000000000001', 'Term 1/2026');

insert into users (
  id, school_id, email, password_hash, first_name, last_name, created_by
) values
  ('35900000-0000-0000-0000-000000000000', '49200000-0000-0000-0000-000000000001', 'admin35@pdpa.test', crypt('x', gen_salt('bf')), 'Admin', 'Patch', '35900000-0000-0000-0000-000000000000'),
  ('49500000-0000-0000-0000-000000000001', '49200000-0000-0000-0000-000000000001',
   'asg-teacher-a@pdpa.test', crypt('irrelevant', gen_salt('bf')), 'Teacher', 'A',
   '49500000-0000-0000-0000-000000000001'),
  ('49500000-0000-0000-0000-000000000002', '49200000-0000-0000-0000-000000000001',
   'asg-student-a1@pdpa.test', crypt('irrelevant', gen_salt('bf')), 'Student', 'One',
   '49500000-0000-0000-0000-000000000001'),
  ('49500000-0000-0000-0000-000000000003', '49200000-0000-0000-0000-000000000001',
   'asg-student-a2@pdpa.test', crypt('irrelevant', gen_salt('bf')), 'Student', 'Two',
   '49500000-0000-0000-0000-000000000001'),
  ('49500000-0000-0000-0000-000000000004', '49200000-0000-0000-0000-000000000002',
   'asg-teacher-b@pdpa.test', crypt('irrelevant', gen_salt('bf')), 'Teacher', 'B',
   '49500000-0000-0000-0000-000000000004');

insert into user_roles (user_id, role, school_id, granted_by) values
  ('35900000-0000-0000-0000-000000000000', 'school_admin', '49200000-0000-0000-0000-000000000001', '35900000-0000-0000-0000-000000000000'),
  ('49500000-0000-0000-0000-000000000001', 'teacher', '49200000-0000-0000-0000-000000000001', '49500000-0000-0000-0000-000000000001'),
  ('49500000-0000-0000-0000-000000000002', 'student', '49200000-0000-0000-0000-000000000001', '49500000-0000-0000-0000-000000000001'),
  ('49500000-0000-0000-0000-000000000003', 'student', '49200000-0000-0000-0000-000000000001', '49500000-0000-0000-0000-000000000001'),
  ('49500000-0000-0000-0000-000000000004', 'teacher', '49200000-0000-0000-0000-000000000002', '49500000-0000-0000-0000-000000000004');

insert into sessions (user_id, active_role, active_school_id, token_hash, expires_at) values
  ('35900000-0000-0000-0000-000000000000', 'school_admin', '49200000-0000-0000-0000-000000000001', encode(digest('admin-token-patched-35', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('49500000-0000-0000-0000-000000000001', 'teacher', '49200000-0000-0000-0000-000000000001',
   encode(digest('asg-teacher-a-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('49500000-0000-0000-0000-000000000002', 'student', '49200000-0000-0000-0000-000000000001',
   encode(digest('asg-student-a1-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('49500000-0000-0000-0000-000000000003', 'student', '49200000-0000-0000-0000-000000000001',
   encode(digest('asg-student-a2-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('49500000-0000-0000-0000-000000000004', 'teacher', '49200000-0000-0000-0000-000000000002',
   encode(digest('asg-teacher-b-token', 'sha256'), 'hex'), now() + interval '1 hour');

insert into devices (id, school_id, type, name, registered_by)
values ('49600000-0000-0000-0000-000000000001', '49200000-0000-0000-0000-000000000001',
        'pm25_sensor', 'Assignment PM2.5', '49500000-0000-0000-0000-000000000001');

create temporary table created_course as
select * from create_course('admin-token-patched-35', '49400000-0000-0000-0000-000000000001',
  'Environmental Science', 'M.3', 'Room 301', 'ห้องเรียนวิทยาศาสตร์สิ่งแวดล้อม'
, '49500000-0000-0000-0000-000000000001');

select enroll_student('admin-token-patched-35', (select course_id from created_course),
  '49500000-0000-0000-0000-000000000002'
);


create temporary table note_assignment as select * from create_assignment(
 'asg-teacher-a-token',(select course_id from created_course),'homework','Notification fixture','body');
select is((select count(*)::int from list_my_notifications('asg-student-a1-token')),0,'draft creates no notification');
select publish_assignment('asg-teacher-a-token',(select assignment_id from note_assignment));
select is((select count(*)::int from list_my_notifications('asg-student-a1-token') where type='assignment_published'),1,'enrolled student gets published assignment');
select is((select count(*)::int from list_my_notifications('asg-student-a2-token')),0,'unenrolled student gets nothing');
select publish_assignment('asg-teacher-a-token',(select assignment_id from note_assignment));
select is((select count(*)::int from list_my_notifications('asg-student-a1-token') where type='assignment_published'),1,'retry does not duplicate publication');
create temporary table note_lesson as select * from create_lesson('asg-teacher-a-token',(select course_id from created_course),'Notification lesson','{}'::jsonb);
select publish_lesson('asg-teacher-a-token',(select lesson_id from note_lesson));
select is((select count(*)::int from list_my_notifications('asg-student-a1-token') where type='lesson_published'),1,'published lesson reaches enrolled student');
select publish_lesson('asg-teacher-a-token',(select lesson_id from note_lesson));
select is((select count(*)::int from list_my_notifications('asg-student-a1-token') where type='lesson_published'),1,'lesson retry is deduplicated');
create temporary table note_grade as select * from create_grade('asg-teacher-a-token','49500000-0000-0000-0000-000000000002',(select course_id from created_course),80,100);
select is((select count(*)::int from list_my_notifications('asg-student-a1-token') where type='grade_confirmed'),0,'draft grade stays private');
select confirm_grade('asg-teacher-a-token',(select grade_id from note_grade));
select is((select count(*)::int from list_my_notifications('asg-student-a1-token') where type='grade_confirmed'),1,'confirmed grade notifies its owner');
select confirm_grade('asg-teacher-a-token',(select grade_id from note_grade));
select is((select count(*)::int from list_my_notifications('asg-student-a1-token') where type='grade_confirmed'),1,'grade retry does not duplicate');
select is((select count(*)::int from list_my_notifications('asg-teacher-b-token')),0,'other school receives no learning notifications');
select throws_ok($q$select publish_assignment('asg-student-a1-token',(select assignment_id from note_assignment))$q$,'P0001','forbidden','student cannot publish');
select throws_ok($q$select publish_lesson('asg-teacher-b-token',(select lesson_id from note_lesson))$q$,'P0001','forbidden','other school cannot publish');
select throws_ok($q$select * from list_my_notifications(null)$q$,'P0001','invalid_session','missing token is denied');
select mark_notification_read('asg-student-a1-token',(select id from list_my_notifications('asg-student-a1-token') where type='grade_confirmed'));
select ok((select read_at is not null from list_my_notifications('asg-student-a1-token') where type='grade_confirmed'),'read persists through RPC refetch');
select is((select count(*)::int from list_my_notifications('asg-student-a2-token')),0,'other student still has no notifications');

-- =====================================================================
-- Additional coverage: recipient edge cases, mark-read ownership and
-- idempotency, producer rejection, and direct-access security.
-- =====================================================================

insert into users (
  id, school_id, email, password_hash, first_name, last_name, created_by
) values
  ('49500000-0000-0000-0000-000000000005', '49200000-0000-0000-0000-000000000001',
   'asg-student-a3@pdpa.test', crypt('irrelevant', gen_salt('bf')), 'Student', 'Three',
   '49500000-0000-0000-0000-000000000001'),
  ('49500000-0000-0000-0000-000000000006', '49200000-0000-0000-0000-000000000001',
   'asg-student-a4-suspended@pdpa.test', crypt('irrelevant', gen_salt('bf')), 'Student', 'Four',
   '49500000-0000-0000-0000-000000000001');

update users set status = 'suspended' where id = '49500000-0000-0000-0000-000000000006';

insert into user_roles (user_id, role, school_id, granted_by) values
  ('49500000-0000-0000-0000-000000000005', 'student', '49200000-0000-0000-0000-000000000001', '49500000-0000-0000-0000-000000000001'),
  ('49500000-0000-0000-0000-000000000006', 'student', '49200000-0000-0000-0000-000000000001', '49500000-0000-0000-0000-000000000001');

insert into sessions (user_id, active_role, active_school_id, token_hash, expires_at) values
  ('49500000-0000-0000-0000-000000000005', 'student', '49200000-0000-0000-0000-000000000001',
   encode(digest('asg-student-a3-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('49500000-0000-0000-0000-000000000006', 'student', '49200000-0000-0000-0000-000000000001',
   encode(digest('asg-student-a4-token', 'sha256'), 'hex'), now() + interval '1 hour');

select enroll_student('admin-token-patched-35', (select course_id from created_course), '49500000-0000-0000-0000-000000000005');
select enroll_student('admin-token-patched-35', (select course_id from created_course), '49500000-0000-0000-0000-000000000006');

-- Recipients: a grade notifies only its own student, never another enrolled classmate
select is((select count(*)::int from list_my_notifications('asg-student-a3-token') where type='grade_confirmed'),0,'other enrolled student receives no notification for a classmates grade');

-- Recipients: a suspended (inactive) enrolled student never receives learning notifications
create temporary table note_assignment2 as select * from create_assignment(
 'asg-teacher-a-token',(select course_id from created_course),'homework','Second notification fixture','body');
select publish_assignment('asg-teacher-a-token',(select assignment_id from note_assignment2));
select is((select count(*)::int from list_my_notifications('asg-student-a4-token')),0,'suspended enrolled student receives no notification');
select is((select count(*)::int from list_my_notifications('asg-student-a3-token') where type='assignment_published'),1,'active enrolled student still receives the second assignment');

-- Producer: the publishing teacher is never a recipient of their own action
select is((select count(*)::int from list_my_notifications('asg-teacher-a-token')),0,'publishing teacher receives no learning notification for their own action');

-- Producer: a rejected mutation attempt never fires the trigger
create temporary table note_assignment3 as select * from create_assignment(
 'asg-teacher-a-token',(select course_id from created_course),'homework','Never published fixture','body');
select throws_ok(
  $q$select publish_assignment('asg-student-a1-token',(select assignment_id from note_assignment3))$q$,
  'P0001','forbidden','student cannot publish someone elses draft assignment'
);
select is((select count(*)::int from list_my_notifications('asg-student-a1-token') where payload->>'learning_source_id' = (select assignment_id from note_assignment3)::text),0,'rejected publish attempt creates no notification');

-- Security: missing/invalid token cannot mark notifications read
select throws_ok($q$select mark_notification_read(null,(select id from list_my_notifications('asg-student-a1-token') where type='grade_confirmed'))$q$,'P0001','invalid_session','missing token cannot mark notifications read');
select throws_ok($q$select mark_notification_read('not-a-real-token',(select id from list_my_notifications('asg-student-a1-token') where type='grade_confirmed'))$q$,'P0001','invalid_session','invalid token cannot mark notifications read');
select throws_ok($q$select * from list_my_notifications('not-a-real-token')$q$,'P0001','invalid_session','invalid non-null token is rejected the same as a missing one for list_my_notifications');

-- Security: a null active_school_id session still reads its own notifications (no unintended school-scoping to bypass)
update sessions set active_school_id = null where user_id = '49500000-0000-0000-0000-000000000002';
select is((select count(*)::int from list_my_notifications('asg-student-a1-token') where type='grade_confirmed'),1,'null active school does not block reading own notifications');

-- Ownership: another student cannot mark someone elses notification as read
select mark_notification_read('asg-student-a3-token',(select id from list_my_notifications('asg-student-a1-token') where type='assignment_published' and payload->>'learning_source_id' = (select assignment_id from note_assignment)::text));
select is((select bool_and(read_at is null) from list_my_notifications('asg-student-a1-token') where type='assignment_published' and payload->>'learning_source_id' = (select assignment_id from note_assignment)::text),true,'another student cannot mark someone elses notification as read');

-- Idempotency: a duplicate mark-read call does not re-mutate an already-read notification
select mark_notification_read('asg-student-a1-token',(select id from list_my_notifications('asg-student-a1-token') where type='grade_confirmed'));
create temporary table grade_read_once as select read_at from list_my_notifications('asg-student-a1-token') where type='grade_confirmed';
select mark_notification_read('asg-student-a1-token',(select id from list_my_notifications('asg-student-a1-token') where type='grade_confirmed'));
select is((select read_at from list_my_notifications('asg-student-a1-token') where type='grade_confirmed'),(select read_at from grade_read_once),'duplicate mark-read does not change an already-read timestamp');

-- Security: direct table access to notifications is denied by default (RLS deny-all, no grants)
select ok(not has_table_privilege('anon','public.notifications','SELECT'),'anon cannot select notifications directly');
select ok(not has_table_privilege('authenticated','public.notifications','SELECT'),'authenticated cannot select notifications directly');

-- Security: the internal notification trigger function cannot be invoked directly by any client-facing role
select ok(not has_function_privilege('anon','public._notify_learning_status_change()','EXECUTE'),'anon cannot execute the internal notification trigger function');
select ok(not has_function_privilege('authenticated','public._notify_learning_status_change()','EXECUTE'),'authenticated cannot execute the internal notification trigger function');
select ok(not has_function_privilege('service_role','public._notify_learning_status_change()','EXECUTE'),'service_role cannot execute the internal notification trigger function');

select * from finish();
rollback;

