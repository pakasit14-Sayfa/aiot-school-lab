begin;

create extension if not exists pgtap with schema extensions;
select plan(4);

insert into packages (id, name, license_type)
values ('98700000-0000-0000-0000-000000000001', 'Quiz questions test package', 'perpetual');

insert into schools (id, package_id, name, school_code)
values ('98700000-0000-0000-0000-000000000002', '98700000-0000-0000-0000-000000000001', 'Quiz questions school', 'QUIZ-A');

insert into academic_years (id, school_id, name)
values ('98700000-0000-0000-0000-000000000008', '98700000-0000-0000-0000-000000000002', '2026');

insert into terms (id, academic_year_id, name)
values ('98700000-0000-0000-0000-000000000009', '98700000-0000-0000-0000-000000000008', 'Term 1/2026');

insert into users (
  id, school_id, email, password_hash, first_name, last_name, created_by
) values
  ('98700000-0000-0000-0000-000000000003', '98700000-0000-0000-0000-000000000002',
   'quiz-teacher@pdpa.test', crypt('irrelevant', gen_salt('bf')), 'Teacher', 'A',
   '98700000-0000-0000-0000-000000000003'),
  ('98700000-0000-0000-0000-000000000004', '98700000-0000-0000-0000-000000000002',
   'quiz-other-teacher@pdpa.test', crypt('irrelevant', gen_salt('bf')), 'Teacher', 'B',
   '98700000-0000-0000-0000-000000000003');

insert into user_roles (user_id, role, school_id, granted_by) values
  ('98700000-0000-0000-0000-000000000003', 'teacher', '98700000-0000-0000-0000-000000000002', '98700000-0000-0000-0000-000000000003'),
  ('98700000-0000-0000-0000-000000000004', 'teacher', '98700000-0000-0000-0000-000000000002', '98700000-0000-0000-0000-000000000003');

insert into sessions (user_id, active_role, active_school_id, token_hash, expires_at) values
  ('98700000-0000-0000-0000-000000000003', 'teacher', '98700000-0000-0000-0000-000000000002', encode(digest('quiz-teacher-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('98700000-0000-0000-0000-000000000004', 'teacher', '98700000-0000-0000-0000-000000000002', encode(digest('quiz-other-teacher-token', 'sha256'), 'hex'), now() + interval '1 hour');

create temporary table created_course as
select * from create_course(
  'quiz-teacher-token', '98700000-0000-0000-0000-000000000009',
  'Quiz Questions Course', 'ม.1', 'Room 101', null
);

create temporary table created_quiz as
select * from create_quiz(
  'quiz-teacher-token', (select course_id from created_course),
  'pre_test', 'Pretest 1'
);

create temporary table created_question as
select * from add_quiz_question(
  'quiz-teacher-token', (select quiz_id from created_quiz),
  'multiple_choice', 'What is 1+1?', 2,
  '[{"text": "1", "is_correct": false}, {"text": "2", "is_correct": true}]'::jsonb
);

-- 1. the teacher who owns the course sees the real question, not a
-- permanent empty list (the old bug: no RPC existed to list questions at
-- all, so every quiz showed "0 ข้อ" regardless of real content)
select is(
  (select count(*)::int from list_quiz_questions('quiz-teacher-token', (select quiz_id from created_quiz))),
  1,
  'the owning teacher sees the real question'
);

-- 2. real choices come back with their real is_correct flag
select is(
  (select (choices->0->>'is_correct')::boolean from list_quiz_questions('quiz-teacher-token', (select quiz_id from created_quiz)) where question_id = (select question_id from created_question)),
  false,
  'the first real choice is correctly marked not-correct'
);

-- 3. a teacher who does not teach this course is forbidden
select throws_ok(
  format($$select * from list_quiz_questions('quiz-other-teacher-token', %L)$$, (select quiz_id from created_quiz)),
  'P0001', 'forbidden',
  'a teacher who does not own the course cannot list its quiz questions'
);

-- 4. an invalid token fails closed
select throws_ok(
  format($$select * from list_quiz_questions(null, %L)$$, (select quiz_id from created_quiz)),
  'P0001', 'invalid_session',
  'a missing token cannot list quiz questions'
);

select * from finish();
rollback;
