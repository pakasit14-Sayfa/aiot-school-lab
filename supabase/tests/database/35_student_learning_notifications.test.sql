begin;

create extension if not exists pgtap with schema extensions;
select plan(15);

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
  ('49500000-0000-0000-0000-000000000001', 'teacher', '49200000-0000-0000-0000-000000000001', '49500000-0000-0000-0000-000000000001'),
  ('49500000-0000-0000-0000-000000000002', 'student', '49200000-0000-0000-0000-000000000001', '49500000-0000-0000-0000-000000000001'),
  ('49500000-0000-0000-0000-000000000003', 'student', '49200000-0000-0000-0000-000000000001', '49500000-0000-0000-0000-000000000001'),
  ('49500000-0000-0000-0000-000000000004', 'teacher', '49200000-0000-0000-0000-000000000002', '49500000-0000-0000-0000-000000000004');

insert into sessions (user_id, active_role, active_school_id, token_hash, expires_at) values
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
select * from create_course(
  'asg-teacher-a-token', '49400000-0000-0000-0000-000000000001',
  'Environmental Science', 'M.3', 'Room 301', 'ห้องเรียนวิทยาศาสตร์สิ่งแวดล้อม'
);

select enroll_student(
  'asg-teacher-a-token',
  (select course_id from created_course),
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
select * from finish();
rollback;

