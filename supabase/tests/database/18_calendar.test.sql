begin;

create extension if not exists pgtap with schema extensions;
select plan(9);

insert into packages (id, name, license_type)
values ('98100000-0000-0000-0000-000000000001', 'Calendar test package', 'perpetual');

insert into schools (id, package_id, name, school_code) values
  ('98200000-0000-0000-0000-000000000001', '98100000-0000-0000-0000-000000000001', 'Calendar school A', 'CAL-A');

insert into academic_years (id, school_id, name)
values ('98300000-0000-0000-0000-000000000001', '98200000-0000-0000-0000-000000000001', '2026');

insert into terms (id, academic_year_id, name)
values ('98400000-0000-0000-0000-000000000001', '98300000-0000-0000-0000-000000000001', 'Term 1/2026');

insert into users (
  id, school_id, email, password_hash, first_name, last_name, created_by
) values
  ('98500000-0000-0000-0000-000000000001', '98200000-0000-0000-0000-000000000001',
   'cal-teacher-a@pdpa.test', crypt('irrelevant', gen_salt('bf')), 'Teacher', 'A',
   '98500000-0000-0000-0000-000000000001'),
  ('98500000-0000-0000-0000-000000000002', '98200000-0000-0000-0000-000000000001',
   'cal-student-a1@pdpa.test', crypt('irrelevant', gen_salt('bf')), 'Student', 'One',
   '98500000-0000-0000-0000-000000000001'),
  ('98500000-0000-0000-0000-000000000003', '98200000-0000-0000-0000-000000000001',
   'cal-student-a2@pdpa.test', crypt('irrelevant', gen_salt('bf')), 'Student', 'Two',
   '98500000-0000-0000-0000-000000000001');

insert into user_roles (user_id, role, school_id, granted_by) values
  ('98500000-0000-0000-0000-000000000001', 'teacher', '98200000-0000-0000-0000-000000000001', '98500000-0000-0000-0000-000000000001'),
  ('98500000-0000-0000-0000-000000000002', 'student', '98200000-0000-0000-0000-000000000001', '98500000-0000-0000-0000-000000000001'),
  ('98500000-0000-0000-0000-000000000003', 'student', '98200000-0000-0000-0000-000000000001', '98500000-0000-0000-0000-000000000001');

insert into sessions (user_id, active_role, active_school_id, token_hash, expires_at) values
  ('98500000-0000-0000-0000-000000000001', 'teacher', '98200000-0000-0000-0000-000000000001',
   encode(digest('cal-teacher-a-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('98500000-0000-0000-0000-000000000002', 'student', '98200000-0000-0000-0000-000000000001',
   encode(digest('cal-student-a1-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('98500000-0000-0000-0000-000000000003', 'student', '98200000-0000-0000-0000-000000000001',
   encode(digest('cal-student-a2-token', 'sha256'), 'hex'), now() + interval '1 hour');

create temporary table created_course as
select * from create_course(
  'cal-teacher-a-token', '98400000-0000-0000-0000-000000000001',
  'Calendar Science', 'M.3', 'Room 501', 'วิชาทดสอบตารางเรียน'
);

select enroll_student(
  'cal-teacher-a-token',
  (select course_id from created_course),
  '98500000-0000-0000-0000-000000000002'
);

-- 1. teacher sets a class schedule slot
select is(
  (select count(*)::integer from set_class_schedule(
    'cal-teacher-a-token', (select course_id from created_course),
    1::smallint, '09:00'::time, '10:00'::time, 'Room 501'
  ) where schedule_id is not null),
  1,
  'teacher can set a class schedule slot'
);

-- 2. end_time before start_time is rejected
select throws_ok(
  $$select set_class_schedule(
    'cal-teacher-a-token', (select course_id from created_course),
    2::smallint, '10:00'::time, '09:00'::time, 'Room 501'
  )$$,
  'P0001', 'end_time_must_be_after_start_time',
  'end_time before start_time is rejected'
);

-- 3. enrolled student sees the schedule
select is(
  (select count(*)::integer from list_my_schedule('cal-student-a1-token')),
  1,
  'enrolled student sees the class schedule'
);

-- 4. unenrolled student in the same school sees nothing
select is(
  (select count(*)::integer from list_my_schedule('cal-student-a2-token')),
  0,
  'unenrolled student sees no schedule slots'
);

-- 5. student creates a personal task
create temporary table created_task as
select * from create_personal_task('cal-student-a1-token', 'ทบทวนบทที่ 3', 'อ่านก่อนสอบ', now() + interval '2 days');

select is(
  (select count(*)::integer from created_task where task_id is not null),
  1,
  'student can create a personal task'
);

-- 6. the task appears in the owner's list
select is(
  (select count(*)::integer from list_my_personal_tasks('cal-student-a1-token')),
  1,
  'the personal task appears in the owner''s list'
);

-- 7. a different student sees zero personal tasks (private, not shared)
select is(
  (select count(*)::integer from list_my_personal_tasks('cal-student-a2-token')),
  0,
  'another student cannot see the first student''s personal tasks'
);

-- 8. a different student cannot toggle the first student's task
select throws_ok(
  $$select toggle_personal_task('cal-student-a2-token', (select task_id from created_task), true)$$,
  'P0001', 'forbidden',
  'another student cannot toggle someone else''s personal task'
);

-- 9. the owner can toggle their own task done
select toggle_personal_task('cal-student-a1-token', (select task_id from created_task), true);
select is(
  (select done from list_my_personal_tasks('cal-student-a1-token') limit 1),
  true,
  'the owner can mark their own task done'
);

select * from finish();
rollback;
