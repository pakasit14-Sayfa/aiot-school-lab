begin;
create extension if not exists pgtap with schema extensions;
select no_plan();

-- Isolated local fixtures; rollback removes users, sessions and grade entries.
create temp table qa_classroom as select
  gen_random_uuid() as package_id, gen_random_uuid() as school_a,
  gen_random_uuid() as school_b, gen_random_uuid() as year_a,
  gen_random_uuid() as year_b, gen_random_uuid() as old_year,
  gen_random_uuid() as term_a, gen_random_uuid() as term_b,
  gen_random_uuid() as old_term, gen_random_uuid() as course_a,
  gen_random_uuid() as course_b, gen_random_uuid() as old_course;
insert into packages(id,name,license_type)
select package_id,'Classroom summary QA','perpetual' from qa_classroom;
insert into schools(id,package_id,name,school_code)
select school_a,package_id,'Classroom QA A','CLASSROOM-QA-A' from qa_classroom
union all select school_b,package_id,'Classroom QA B','CLASSROOM-QA-B' from qa_classroom;

create temp table qa_classroom_users as
select gen_random_uuid() as id, v.name, v.role::role_type,
  case when v.name in ('execb','studentb') then q.school_b else q.school_a end as school_id
from qa_classroom q cross join (values
  ('exec','executive'),('admin','school_admin'),('teacher','teacher'),
  ('student1','student'),('student2','student'),('student3','student'),
  ('execb','executive'),('studentb','student')
) v(name,role);
insert into users(id,school_id,email,password_hash,first_name,last_name)
select id,school_id,id::text || '@classroom-qa.test','not-a-login-hash',name,'QA'
from qa_classroom_users;
insert into user_roles(user_id,role,school_id,granted_by)
select id,role,school_id,id from qa_classroom_users;
insert into sessions(user_id,active_role,active_school_id,token_hash,expires_at)
select id,role,school_id,encode(digest('classroom-qa-' || name,'sha256'),'hex'),
  now() + interval '1 hour' from qa_classroom_users;

insert into academic_years(id,school_id,name,start_date,end_date)
select year_a,school_a,'Current A',current_date-30,current_date+300 from qa_classroom
union all select year_b,school_b,'Current B',current_date-30,current_date+300 from qa_classroom
union all select old_year,school_a,'Old A',current_date-730,current_date-400 from qa_classroom;
insert into terms(id,academic_year_id,name)
select term_a,year_a,'Current A' from qa_classroom
union all select term_b,year_b,'Current B' from qa_classroom
union all select old_term,old_year,'Old A' from qa_classroom;
insert into student_profiles(student_id,academic_year_id,grade_level,room,created_by)
select u.id,case when u.school_id=q.school_b then q.year_b else q.year_a end,
  'M1',case when u.name='student3' then '2' else '1' end,u.id
from qa_classroom_users u cross join qa_classroom q where u.role='student';
insert into courses(id,school_id,term_id,subject_name,created_by)
select q.course_a,q.school_a,q.term_a,'Current A',u.id
from qa_classroom q join qa_classroom_users u on u.name='teacher'
union all select q.course_b,q.school_b,q.term_b,'Current B',u.id
from qa_classroom q join qa_classroom_users u on u.name='execb'
union all select q.old_course,q.school_a,q.old_term,'Old A',u.id
from qa_classroom q join qa_classroom_users u on u.name='teacher';
insert into grades(student_id,course_id,source_type,score,max_score,status)
select u.id,case v.course when 'old' then q.old_course when 'foreign' then q.course_b
  else q.course_a end,'manual',v.score,v.max_score,v.status::grade_status
from qa_classroom q cross join (values
  ('student1','current',1::numeric,2::numeric,'confirmed'),
  ('student1','current',100,100,'confirmed'),
  ('student2','current',null,100,'confirmed'),
  ('student2','current',0,0,'confirmed'),
  ('student2','current',90,100,'draft'),
  ('student2','old',1,100,'confirmed'),
  ('student2','foreign',2,100,'confirmed')
) v(name,course,score,max_score,status) join qa_classroom_users u on u.name=v.name;


-- Audit calls must actually execute; mere function existence is insufficient.
select lives_ok($$select * from list_school_classroom_work_activity('classroom-qa-exec')$$,'work activity RPC executes');
select lives_ok($$select * from list_school_classroom_work_details('classroom-qa-exec')$$,'work details RPC executes');
select lives_ok($$select * from list_school_support_cases_by_room('classroom-qa-exec')$$,'room support RPC executes');
select lives_ok($$select * from list_executive_students_needing_attention('classroom-qa-exec')$$,'automatic flags RPC executes');

create temp table qa_opened as
select * from open_executive_support_case_from_flag('classroom-qa-exec',
 (select id from qa_classroom_users where name='student1'),'ค้างส่งงาน','ค้างส่ง 2 งาน','ดูงานค้าง','urgent');
select ok((select created from qa_opened),'opens a case through executive RPC');
select is((select count(*)::int from list_student_support_cases('classroom-qa-exec',null,null) c join qa_opened o on c.case_id=o.case_id),1,'new case readable through canonical list');
select is((select count(*)::int from list_school_support_cases_by_room('classroom-qa-exec') c join qa_opened o on c.case_id=o.case_id where grade_level='M1' and room='1'),1,'new case appears in correct room');
select is((select count(*)::int from list_student_support_interventions('classroom-qa-exec',(select case_id from qa_opened))),0,'new case has no fabricated help history');
select lives_ok($$select * from add_student_support_intervention('classroom-qa-teacher',(select case_id from qa_opened),'observation','QA first assistance')$$,'teacher can add first assistance');
select is((select count(*)::int from list_student_support_interventions('classroom-qa-exec',(select case_id from qa_opened)) where notes='QA first assistance'),1,'executive reads actual first assistance');
select is((select intervention_count from list_student_support_cases('classroom-qa-exec',null,null) c join qa_opened o on c.case_id=o.case_id),1::bigint,'case history count updates');
select is((select case_id from open_executive_support_case_from_flag('classroom-qa-exec',
 (select id from qa_classroom_users where name='student1'),'ค้างส่งงาน','ค้างส่ง 2 งาน','ดูงานค้าง','urgent')),(select case_id from qa_opened),'exact repeat returns same case');
select throws_ok($$select * from list_student_support_interventions('classroom-qa-execb',(select case_id from qa_opened))$$,'P0001','forbidden','other school cannot read case history');
select throws_ok($$select * from open_executive_support_case_from_flag('classroom-qa-teacher',(select id from qa_classroom_users where name='student1'),'test','test','','normal')$$,'P0001','forbidden','teacher denied executive creation');
-- Same underlying reason with a changing counter should not create another active case.
select is((select case_id from open_executive_support_case_from_flag('classroom-qa-exec',
 (select id from qa_classroom_users where name='student1'),'ค้างส่งงาน','ค้างส่ง 3 งาน','ดูงานค้าง','urgent')),(select case_id from qa_opened),'same signal with changed detail does not duplicate active case');

-- Per-assignment roster must show submitted and pending enrolled students.
update courses set grade_level='M1',room='1' where id=(select course_a from qa_classroom);
insert into course_students(course_id,student_id)
select q.course_a,u.id from qa_classroom q join qa_classroom_users u on u.name in ('student1','student2');
create temp table qa_assignment as
with added as (insert into assignments(course_id,type,title,status,created_by)
select q.course_a,'homework','Audit assignment','published',u.id from qa_classroom q join qa_classroom_users u on u.name='teacher'
returning id) select id from added;
insert into submissions(assignment_id,student_id)
select a.id,u.id from qa_assignment a join qa_classroom_users u on u.name='student1';
select is((select count(*)::int from list_school_assignment_roster('classroom-qa-exec',(select id from qa_assignment))),2,'roster has both enrolled students');
select is((select count(*)::int from list_school_assignment_roster('classroom-qa-exec',(select id from qa_assignment)) where submission_status='submitted'),1,'roster reports actual submission');
select is((select count(*)::int from list_school_assignment_roster('classroom-qa-exec',(select id from qa_assignment)) where submission_status='ยังไม่ส่ง'),1,'roster reports missing submission');
select throws_ok($$select * from list_school_assignment_roster('classroom-qa-execb',(select id from qa_assignment))$$,'P0001','forbidden','foreign school cannot read roster');
select throws_ok($$select * from list_school_assignment_roster('classroom-qa-teacher',(select id from qa_assignment))$$,'P0001','forbidden','teacher cannot call executive roster');
select lives_ok($$select * from get_classrooms_overview('classroom-qa-exec')$$,'executive can call get_classrooms_overview');
select lives_ok($$select * from list_homeroom_assignments('classroom-qa-exec')$$,'executive can call list_homeroom_assignments');
select lives_ok($$select * from list_learning_track_rooms('classroom-qa-exec')$$,'executive can call list_learning_track_rooms');
select lives_ok($$select * from get_learning_track_overview('classroom-qa-exec')$$,'executive can call get_learning_track_overview');
select lives_ok($$select * from list_all_school_schedules('classroom-qa-exec')$$,'executive can call list_all_school_schedules');
select lives_ok($$select * from list_meeting_records('classroom-qa-exec')$$,'executive can call list_meeting_records');
select lives_ok($$select * from list_staff_directory('classroom-qa-exec')$$,'executive can call list_staff_directory');
select lives_ok($$select * from list_departments('classroom-qa-exec')$$,'executive can call list_departments');
select lives_ok($$select * from get_staff_attendance_summary('classroom-qa-exec')$$,'executive can call get_staff_attendance_summary');
select lives_ok($$select * from list_staff_leave_requests('classroom-qa-exec')$$,'executive can call list_staff_leave_requests');
select lives_ok($$select * from list_camera_access_grants('classroom-qa-exec')$$,'executive can call list_camera_access_grants');
select lives_ok($$select * from list_school_reports('classroom-qa-exec')$$,'executive can call list_school_reports');
select lives_ok($$select * from get_school_report_summary('classroom-qa-exec')$$,'executive can call get_school_report_summary');
select lives_ok($$select * from list_report_requirements('classroom-qa-exec')$$,'executive can call list_report_requirements');
select lives_ok($$select * from list_my_notifications('classroom-qa-exec')$$,'executive can call list_my_notifications');
select lives_ok($$select * from list_my_notification_categories('classroom-qa-exec')$$,'executive can call list_my_notification_categories');
select lives_ok($$select * from list_school_homeroom_attendance('classroom-qa-exec',current_date)$$,'executive daily attendance executes');
select lives_ok($$select * from list_calendar_events('classroom-qa-exec',null)$$,'executive school calendar executes');

select * from finish();
rollback;
