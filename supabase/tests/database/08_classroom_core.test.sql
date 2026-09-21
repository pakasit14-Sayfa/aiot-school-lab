-- admin_token_patched
begin;

create extension if not exists pgtap with schema extensions;
select plan(14);

insert into packages (id, name, license_type)
values ('48100000-0000-0000-0000-000000000001', 'Classroom test package', 'perpetual');

insert into schools (id, package_id, name, school_code) values
  ('48200000-0000-0000-0000-000000000001', '48100000-0000-0000-0000-000000000001', 'Classroom school A', 'CLS-A'),
  ('48200000-0000-0000-0000-000000000002', '48100000-0000-0000-0000-000000000001', 'Classroom school B', 'CLS-B');

insert into academic_years (id, school_id, name)
values ('48300000-0000-0000-0000-000000000001', '48200000-0000-0000-0000-000000000001', '2026');

insert into terms (id, academic_year_id, name)
values ('48400000-0000-0000-0000-000000000001', '48300000-0000-0000-0000-000000000001', 'Term 1/2026');

insert into users (
  id, school_id, email, password_hash, first_name, last_name, created_by
) values
  ('08900000-0000-0000-0000-000000000000', '48200000-0000-0000-0000-000000000001', 'admin08@pdpa.test', crypt('x', gen_salt('bf')), 'Admin', 'Patch', '08900000-0000-0000-0000-000000000000'),
  ('48500000-0000-0000-0000-000000000001', '48200000-0000-0000-0000-000000000001',
   'cls-teacher-a@pdpa.test', crypt('irrelevant', gen_salt('bf')), 'Teacher', 'A',
   '48500000-0000-0000-0000-000000000001'),
  ('48500000-0000-0000-0000-000000000002', '48200000-0000-0000-0000-000000000001',
   'cls-student-a1@pdpa.test', crypt('irrelevant', gen_salt('bf')), 'Student', 'One',
   '48500000-0000-0000-0000-000000000001'),
  ('48500000-0000-0000-0000-000000000003', '48200000-0000-0000-0000-000000000001',
   'cls-student-a2@pdpa.test', crypt('irrelevant', gen_salt('bf')), 'Student', 'Two',
   '48500000-0000-0000-0000-000000000001'),
  ('48500000-0000-0000-0000-000000000004', '48200000-0000-0000-0000-000000000002',
   'cls-teacher-b@pdpa.test', crypt('irrelevant', gen_salt('bf')), 'Teacher', 'B',
   '48500000-0000-0000-0000-000000000004');

insert into user_roles (user_id, role, school_id, granted_by) values
  ('08900000-0000-0000-0000-000000000000', 'school_admin', '48200000-0000-0000-0000-000000000001', '08900000-0000-0000-0000-000000000000'),
  ('48500000-0000-0000-0000-000000000001', 'teacher', '48200000-0000-0000-0000-000000000001', '48500000-0000-0000-0000-000000000001'),
  ('48500000-0000-0000-0000-000000000002', 'student', '48200000-0000-0000-0000-000000000001', '48500000-0000-0000-0000-000000000001'),
  ('48500000-0000-0000-0000-000000000003', 'student', '48200000-0000-0000-0000-000000000001', '48500000-0000-0000-0000-000000000001'),
  ('48500000-0000-0000-0000-000000000004', 'teacher', '48200000-0000-0000-0000-000000000002', '48500000-0000-0000-0000-000000000004');

insert into sessions (user_id, active_role, active_school_id, token_hash, expires_at) values
  ('08900000-0000-0000-0000-000000000000', 'school_admin', '48200000-0000-0000-0000-000000000001', encode(digest('admin-token-patched-08', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('48500000-0000-0000-0000-000000000001', 'teacher', '48200000-0000-0000-0000-000000000001',
   encode(digest('cls-teacher-a-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('48500000-0000-0000-0000-000000000002', 'student', '48200000-0000-0000-0000-000000000001',
   encode(digest('cls-student-a1-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('48500000-0000-0000-0000-000000000003', 'student', '48200000-0000-0000-0000-000000000001',
   encode(digest('cls-student-a2-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('48500000-0000-0000-0000-000000000004', 'teacher', '48200000-0000-0000-0000-000000000002',
   encode(digest('cls-teacher-b-token', 'sha256'), 'hex'), now() + interval '1 hour');

insert into devices (id, school_id, type, name, registered_by)
values ('48600000-0000-0000-0000-000000000001', '48200000-0000-0000-0000-000000000001',
        'pm25_sensor', 'Classroom PM2.5', '48500000-0000-0000-0000-000000000001');

-- 1. the school admin creates a course and assigns teacher A as owner
-- (D6, 20260919000000: teachers no longer create courses themselves)
create temporary table created_course as
select * from create_course('admin-token-patched-08', '48400000-0000-0000-0000-000000000001',
  'Environmental Science', 'M.3', 'Room 301', 'ห้องเรียนวิทยาศาสตร์สิ่งแวดล้อม'
, '48500000-0000-0000-0000-000000000001');

select is(
  (select count(*)::integer from created_course where course_id is not null),
  1,
  'teacher can create a course'
);

-- 2. course shows up in the teacher's own list
select is(
  (select count(*)::integer from list_my_courses('cls-teacher-a-token')
   where course_id = (select course_id from created_course)),
  1,
  'created course appears in the teacher''s course list'
);

-- 3. an unenrolled student sees nothing yet
select is(
  (select count(*)::integer from list_my_courses('cls-student-a2-token')),
  0,
  'an unenrolled student sees no courses'
);

-- 4. enroll student A1
select enroll_student('admin-token-patched-08', (select course_id from created_course),
  '48500000-0000-0000-0000-000000000002'
);

select is(
  (select count(*)::integer from list_my_courses('cls-student-a1-token')
   where course_id = (select course_id from created_course)),
  1,
  'enrolled student sees the course in their list'
);

select is(
  (select count(*)::integer from list_course_students(
    'cls-teacher-a-token', (select course_id from created_course)
  )),
  1,
  'teacher roster shows exactly the one enrolled student'
);

-- 5. teacher creates a draft lesson
create temporary table created_lesson as
select * from create_lesson(
  'cls-teacher-a-token', (select course_id from created_course),
  'Air Quality 101', '{"body": "intro"}'::jsonb
);

select is(
  (select count(*)::integer from created_lesson where lesson_id is not null),
  1,
  'teacher can create a draft lesson'
);

-- 6. draft lesson is invisible to the enrolled student
select is(
  (select count(*)::integer from list_lessons(
    'cls-student-a1-token', (select course_id from created_course)
  )),
  0,
  'a draft lesson is not visible to an enrolled student'
);

-- 7. publish it
select publish_lesson('cls-teacher-a-token', (select lesson_id from created_lesson));

select is(
  (select count(*)::integer from list_lessons(
    'cls-student-a1-token', (select course_id from created_course)
  )),
  1,
  'a published lesson becomes visible to an enrolled student'
);

-- 8. an unenrolled student cannot list lessons for the course at all
select throws_ok(
  $$select * from list_lessons(
    'cls-student-a2-token',
    (select course_id from created_course)
  )$$,
  'P0001', 'forbidden',
  'an unenrolled student cannot list a course''s lessons'
);

-- 9. link a real sensor window to the lesson (LRN-8)
select link_lesson_sensor(
  'cls-teacher-a-token', (select lesson_id from created_lesson),
  '48600000-0000-0000-0000-000000000001', 'pm25',
  now() - interval '1 day', now(), 'ค่าฝุ่นเมื่อวาน'
);

select is(
  (select jsonb_array_length(sensor_links) from get_lesson(
    'cls-teacher-a-token', (select lesson_id from created_lesson)
  )),
  1,
  'get_lesson returns the linked sensor window'
);

-- 10. student tracks progress then marks complete
select update_lesson_progress('cls-student-a1-token', (select lesson_id from created_lesson), 40);

select is(
  (select progress_pct from get_lesson(
    'cls-student-a1-token', (select lesson_id from created_lesson)
  )),
  40::numeric,
  'student progress is recorded'
);

select mark_lesson_complete('cls-student-a1-token', (select lesson_id from created_lesson));

select is(
  (select completed from get_lesson(
    'cls-student-a1-token', (select lesson_id from created_lesson)
  )),
  true,
  'student can mark a lesson complete'
);

-- 11. cross-school isolation
select throws_ok(
  $$select * from get_course(
    'cls-teacher-b-token',
    (select course_id from created_course)
  )$$,
  'P0001', 'forbidden',
  'a teacher from another school cannot read this course'
);

select throws_ok(
  $$select * from create_course('cls-student-a1-token', '48400000-0000-0000-0000-000000000001',
    'Should not work'
  , 'M.1', '1', null, '48500000-0000-0000-0000-000000000002')$$,
  'P0001', 'forbidden',
  'a student cannot create a course'
);

select * from finish();
rollback;
