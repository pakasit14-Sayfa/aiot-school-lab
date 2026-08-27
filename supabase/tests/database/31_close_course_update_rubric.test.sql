-- =====================================================================
-- Test Suite: 31_close_course_update_rubric.test.sql
-- Verify close_course (real, previously fake-write UI) and update_rubric
-- (real, previously silently duplicated a row on every "edit").
-- =====================================================================

begin;

create extension if not exists pgtap with schema extensions;
select plan(12);

insert into packages (id, name, license_type)
values ('99f00000-0000-0000-0000-000000000001', 'Close course/update rubric test package', 'perpetual');

insert into schools (id, package_id, name, school_code) values
  ('9a000000-0000-0000-0000-000000000001', '99f00000-0000-0000-0000-000000000001', 'CCUR test school A', 'CCUR-A');

insert into academic_years (id, school_id, name)
values ('9a100000-0000-0000-0000-000000000001', '9a000000-0000-0000-0000-000000000001', '2026');

insert into terms (id, academic_year_id, name)
values ('9a200000-0000-0000-0000-000000000001', '9a100000-0000-0000-0000-000000000001', 'Term 1/2026');

insert into users (id, school_id, email, password_hash, first_name, last_name, created_by) values
  ('9a300000-0000-0000-0000-000000000001', '9a000000-0000-0000-0000-000000000001',
   'ccur-teacher-a@pdpa.test', crypt('irrelevant', gen_salt('bf')), 'Teacher', 'A',
   '9a300000-0000-0000-0000-000000000001'),
  ('9a300000-0000-0000-0000-000000000002', '9a000000-0000-0000-0000-000000000001',
   'ccur-teacher-b@pdpa.test', crypt('irrelevant', gen_salt('bf')), 'Teacher', 'B',
   '9a300000-0000-0000-0000-000000000001'),
  ('9a300000-0000-0000-0000-000000000003', '9a000000-0000-0000-0000-000000000001',
   'ccur-student-a@pdpa.test', crypt('irrelevant', gen_salt('bf')), 'Student', 'A',
   '9a300000-0000-0000-0000-000000000001');

insert into user_roles (user_id, role, school_id, granted_by) values
  ('9a300000-0000-0000-0000-000000000001', 'teacher', '9a000000-0000-0000-0000-000000000001', '9a300000-0000-0000-0000-000000000001'),
  ('9a300000-0000-0000-0000-000000000002', 'teacher', '9a000000-0000-0000-0000-000000000001', '9a300000-0000-0000-0000-000000000001'),
  ('9a300000-0000-0000-0000-000000000003', 'student', '9a000000-0000-0000-0000-000000000001', '9a300000-0000-0000-0000-000000000001');

insert into sessions (user_id, active_role, active_school_id, token_hash, expires_at) values
  ('9a300000-0000-0000-0000-000000000001', 'teacher', '9a000000-0000-0000-0000-000000000001',
   encode(digest('ccur-teacher-a-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('9a300000-0000-0000-0000-000000000002', 'teacher', '9a000000-0000-0000-0000-000000000001',
   encode(digest('ccur-teacher-b-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('9a300000-0000-0000-0000-000000000003', 'student', '9a000000-0000-0000-0000-000000000001',
   encode(digest('ccur-student-a-token', 'sha256'), 'hex'), now() + interval '1 hour');

insert into courses (id, school_id, term_id, subject_name, created_by) values
  ('9a400000-0000-0000-0000-000000000001', '9a000000-0000-0000-0000-000000000001', '9a200000-0000-0000-0000-000000000001', 'CCUR test course', '9a300000-0000-0000-0000-000000000001');

-- Functions exist
select has_function('public', 'close_course', ARRAY['text', 'uuid'], 'close_course exists');
select has_function('public', 'update_rubric', ARRAY['text', 'uuid', 'text', 'text', 'jsonb'], 'update_rubric exists');

-- Student cannot close a course
select throws_ok(
  $$ select close_course('ccur-student-a-token', '9a400000-0000-0000-0000-000000000001') $$,
  'forbidden: teacher, school_admin or super_admin role required',
  'student cannot call close_course'
);

-- A teacher who doesn't own the course cannot close it
select throws_ok(
  $$ select close_course('ccur-teacher-b-token', '9a400000-0000-0000-0000-000000000001') $$,
  'forbidden: not your course',
  'a different teacher cannot close someone else''s course'
);

-- The owning teacher can close it for real
select close_course('ccur-teacher-a-token', '9a400000-0000-0000-0000-000000000001');

select is(
  (select status::text from courses where id = '9a400000-0000-0000-0000-000000000001'),
  'closed',
  'close_course really updates courses.status in the database'
);

select isnt(
  (select closed_at from courses where id = '9a400000-0000-0000-0000-000000000001'),
  null,
  'closed_at is set'
);

-- Closing an already-closed course is rejected, not silently "successful"
select throws_ok(
  $$ select close_course('ccur-teacher-a-token', '9a400000-0000-0000-0000-000000000001') $$,
  'course_already_closed',
  'closing an already-closed course raises instead of pretending to succeed again'
);

-- update_rubric: create, then update in place / add / drop
select create_rubric('ccur-teacher-a-token', 'CCUR rubric', 'desc', '[{"name":"A","max_score":10},{"name":"B","max_score":5}]'::jsonb);

select is(
  (select count(*)::int from rubric_criteria rc join rubrics r on r.id = rc.rubric_id where r.title = 'CCUR rubric'),
  2,
  'seed rubric has 2 criteria before the update'
);

-- Pull the real ids to build the update payload
select update_rubric(
  'ccur-teacher-a-token',
  (select id from rubrics where title = 'CCUR rubric'),
  'CCUR rubric (edited)',
  'new desc',
  (
    select jsonb_build_array(
      jsonb_build_object('id', (select rc.id from rubric_criteria rc join rubrics r on r.id = rc.rubric_id where r.title = 'CCUR rubric' and rc.name = 'A'), 'name', 'A (edited)', 'max_score', 20),
      jsonb_build_object('name', 'C new', 'max_score', 8)
    )
  )
);

select is(
  (select title from rubrics where id = (select id from rubrics where title = 'CCUR rubric (edited)')),
  'CCUR rubric (edited)',
  'update_rubric really updates the title (not a duplicate insert)'
);

select is(
  (select count(*)::int from rubrics where title in ('CCUR rubric', 'CCUR rubric (edited)')),
  1,
  'exactly one rubric row exists after the update — editing did not create a duplicate (the original bug)'
);

select is(
  (select count(*)::int from rubric_criteria rc join rubrics r on r.id = rc.rubric_id where r.title = 'CCUR rubric (edited)'),
  2,
  'criterion A was updated in place and criterion B was dropped (no scores reference it), C was added: 2 total'
);

-- Protect criteria that have real grade_criterion_scores from being deleted
insert into grades (id, student_id, course_id, source_type, status) values
  ('9a500000-0000-0000-0000-000000000001', '9a300000-0000-0000-0000-000000000003', '9a400000-0000-0000-0000-000000000001', 'manual', 'draft');
insert into grade_criterion_scores (grade_id, criterion_id, score)
select '9a500000-0000-0000-0000-000000000001', rc.id, 15
from rubric_criteria rc join rubrics r on r.id = rc.rubric_id
where r.title = 'CCUR rubric (edited)' and rc.name = 'A (edited)';

select update_rubric(
  'ccur-teacher-a-token',
  (select id from rubrics where title = 'CCUR rubric (edited)'),
  'CCUR rubric (edited again)',
  'desc',
  '[]'::jsonb
);

select is(
  (select count(*)::int from rubric_criteria rc join rubrics r on r.id = rc.rubric_id where r.title = 'CCUR rubric (edited again)' and rc.name = 'A (edited)'),
  1,
  'a criterion with a real grade_criterion_scores row survives even when dropped from the update payload'
);

select * from finish();
rollback;
