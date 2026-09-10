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

select is((select count(*)::int from list_school_classroom_learning_summary('classroom-qa-exec')),2,'only own-school rooms');
select is((select student_count from list_school_classroom_learning_summary('classroom-qa-exec') where room='1'),2::bigint,'students counted once across grade entries');
select is((select scored_student_count from list_school_classroom_learning_summary('classroom-qa-exec') where room='1'),1::bigint,'only valid confirmed current-year own-school scores count');
select is((select ungraded_student_count from list_school_classroom_learning_summary('classroom-qa-exec') where room='1'),1::bigint,'draft and invalid grades remain ungraded');
select is((select avg_grade_percent from list_school_classroom_learning_summary('classroom-qa-exec') where room='1'),75::numeric,'average normalizes each valid entry to percent');
select is((select avg_grade_percent from list_school_classroom_learning_summary('classroom-qa-exec') where room='2'),null::numeric,'no grades stays unknown');
select is((select ungraded_student_count from list_school_classroom_learning_summary('classroom-qa-exec') where room='2'),1::bigint,'no-grade room keeps ungraded student');
select is((select count(*)::int from list_school_classroom_learning_summary('classroom-qa-execb')),1,'other executive sees own room only');
select is((select avg_grade_percent from list_school_classroom_learning_summary('classroom-qa-execb')),null::numeric,'same room label cannot borrow another school scores');
select is((select count(*)::int from list_school_classroom_learning_summary('classroom-qa-admin')),2,'school admin can read');
select throws_ok($$select list_school_classroom_learning_summary('classroom-qa-teacher')$$,'P0001','forbidden','teacher cannot read school summary');
select throws_ok($$select list_school_classroom_learning_summary('classroom-qa-student1')$$,'P0001','forbidden','student cannot read school summary');
select throws_ok($$select list_school_classroom_learning_summary('classroom-qa-invalid')$$,'P0001','invalid_session','invalid session rejected');
insert into grades(student_id,course_id,source_type,score,max_score,status)
select u.id,q.course_a,'manual',0,100,'confirmed' from qa_classroom q
join qa_classroom_users u on u.name='student3';
select is((select avg_grade_percent from list_school_classroom_learning_summary('classroom-qa-exec') where room='2'),0::numeric,'real zero is a score');
select is((select scored_student_count from list_school_classroom_learning_summary('classroom-qa-exec') where room='2'),1::bigint,'real zero counts as graded');
select ok(has_function_privilege('anon','public.list_school_classroom_learning_summary(text)','EXECUTE'),'custom-session client may call RPC');
select ok(has_function_privilege('authenticated','public.list_school_classroom_learning_summary(text)','EXECUTE'),'authenticated may call RPC');
select ok(not has_function_privilege('service_role','public.list_school_classroom_learning_summary(text)','EXECUTE'),'no service-role execution grant');
select * from finish();
rollback;
