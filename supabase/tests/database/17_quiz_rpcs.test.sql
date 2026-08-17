begin;

create extension if not exists pgtap with schema extensions;
select plan(11);

insert into packages (id, name, license_type)
values ('97100000-0000-0000-0000-000000000001', 'Quiz test package', 'perpetual');

insert into schools (id, package_id, name, school_code) values
  ('97200000-0000-0000-0000-000000000001', '97100000-0000-0000-0000-000000000001', 'Quiz school A', 'QZ-A');

insert into academic_years (id, school_id, name)
values ('97300000-0000-0000-0000-000000000001', '97200000-0000-0000-0000-000000000001', '2026');

insert into terms (id, academic_year_id, name)
values ('97400000-0000-0000-0000-000000000001', '97300000-0000-0000-0000-000000000001', 'Term 1/2026');

insert into users (
  id, school_id, email, password_hash, first_name, last_name, created_by
) values
  ('97500000-0000-0000-0000-000000000001', '97200000-0000-0000-0000-000000000001',
   'qz-teacher-a@pdpa.test', crypt('irrelevant', gen_salt('bf')), 'Teacher', 'A',
   '97500000-0000-0000-0000-000000000001'),
  ('97500000-0000-0000-0000-000000000002', '97200000-0000-0000-0000-000000000001',
   'qz-student-a1@pdpa.test', crypt('irrelevant', gen_salt('bf')), 'Student', 'One',
   '97500000-0000-0000-0000-000000000001'),
  ('97500000-0000-0000-0000-000000000003', '97200000-0000-0000-0000-000000000001',
   'qz-student-a2@pdpa.test', crypt('irrelevant', gen_salt('bf')), 'Student', 'Two',
   '97500000-0000-0000-0000-000000000001');

insert into user_roles (user_id, role, school_id, granted_by) values
  ('97500000-0000-0000-0000-000000000001', 'teacher', '97200000-0000-0000-0000-000000000001', '97500000-0000-0000-0000-000000000001'),
  ('97500000-0000-0000-0000-000000000002', 'student', '97200000-0000-0000-0000-000000000001', '97500000-0000-0000-0000-000000000001'),
  ('97500000-0000-0000-0000-000000000003', 'student', '97200000-0000-0000-0000-000000000001', '97500000-0000-0000-0000-000000000001');

insert into sessions (user_id, active_role, active_school_id, token_hash, expires_at) values
  ('97500000-0000-0000-0000-000000000001', 'teacher', '97200000-0000-0000-0000-000000000001',
   encode(digest('qz-teacher-a-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('97500000-0000-0000-0000-000000000002', 'student', '97200000-0000-0000-0000-000000000001',
   encode(digest('qz-student-a1-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('97500000-0000-0000-0000-000000000003', 'student', '97200000-0000-0000-0000-000000000001',
   encode(digest('qz-student-a2-token', 'sha256'), 'hex'), now() + interval '1 hour');

create temporary table created_course as
select * from create_course(
  'qz-teacher-a-token', '97400000-0000-0000-0000-000000000001',
  'Quiz Science', 'M.3', 'Room 401', 'วิชาทดสอบแบบทดสอบ'
);

select enroll_student(
  'qz-teacher-a-token',
  (select course_id from created_course),
  '97500000-0000-0000-0000-000000000002'
);

create temporary table created_quiz as
select * from create_quiz(
  'qz-teacher-a-token', (select course_id from created_course),
  'pre_test', 'แบบทดสอบก่อนเรียน บทที่ 1'
);

select is(
  (select count(*)::integer from created_quiz where quiz_id is not null),
  1,
  'teacher can create a draft quiz'
);

-- publish rejected without any questions
select throws_ok(
  $$select publish_quiz('qz-teacher-a-token', (select quiz_id from created_quiz))$$,
  'P0001', 'quiz_has_no_questions',
  'cannot publish a quiz with zero questions'
);

create temporary table created_question as
select * from add_quiz_question(
  'qz-teacher-a-token', (select quiz_id from created_quiz),
  'multiple_choice', 'PM2.5 ย่อมาจากอะไร', 2,
  '[{"text": "ฝุ่นละอองขนาดเล็ก", "is_correct": true}, {"text": "ก๊าซพิษ", "is_correct": false}]'::jsonb
);

-- publish rejected: this question type now has a correct choice, but let's also test
-- the missing-correct-choice case with a second question first
select add_quiz_question(
  'qz-teacher-a-token', (select quiz_id from created_quiz),
  'true_false', 'ฝุ่น PM2.5 มองเห็นด้วยตาเปล่าได้ง่าย', 1,
  '[{"text": "จริง", "is_correct": false}, {"text": "เท็จ", "is_correct": false}]'::jsonb
);

select throws_ok(
  $$select publish_quiz('qz-teacher-a-token', (select quiz_id from created_quiz))$$,
  'P0001', 'question_missing_correct_choice',
  'cannot publish when a question has no correct choice marked'
);

-- fix the second question then publish should succeed
update quiz_choices set is_correct = true
where question_id = (
  select id from quiz_questions
  where quiz_id = (select quiz_id from created_quiz) and question = 'ฝุ่น PM2.5 มองเห็นด้วยตาเปล่าได้ง่าย'
)
and choice_text = 'เท็จ';

select lives_ok(
  $$select publish_quiz('qz-teacher-a-token', (select quiz_id from created_quiz))$$,
  'publish succeeds once every objective question has a correct choice'
);

-- unenrolled student cannot list quizzes for the course at all
select throws_ok(
  $$select * from list_course_quizzes(
    'qz-student-a2-token', (select course_id from created_course)
  )$$,
  'P0001', 'forbidden',
  'an unenrolled student cannot list a course''s quizzes'
);

-- enrolled student sees the published quiz
select is(
  (select count(*)::integer from list_course_quizzes(
    'qz-student-a1-token', (select course_id from created_course)
  )),
  1,
  'enrolled student sees the published quiz'
);

-- get_quiz_for_student never exposes is_correct
select ok(
  not (
    select bool_or(choices::text like '%is_correct%')
    from get_quiz_for_student('qz-student-a1-token', (select quiz_id from created_quiz))
  ),
  'get_quiz_for_student never includes is_correct in the choices payload'
);

create temporary table started_attempt as
select * from start_quiz_attempt('qz-student-a1-token', (select quiz_id from created_quiz));

select is(
  (select count(*)::integer from started_attempt where attempt_id is not null),
  1,
  'student can start a quiz attempt'
);

-- calling start_quiz_attempt again reuses the same in-progress attempt
select is(
  (select attempt_id from start_quiz_attempt('qz-student-a1-token', (select quiz_id from created_quiz))),
  (select attempt_id from started_attempt),
  'starting an attempt twice without submitting reuses the same attempt (idempotent)'
);

select save_quiz_answer(
  'qz-student-a1-token', (select attempt_id from started_attempt),
  (select id from quiz_questions where quiz_id = (select quiz_id from created_quiz) and question like 'PM2.5%'),
  jsonb_build_object('choice_id', (
    select id from quiz_choices where question_id = (
      select id from quiz_questions where quiz_id = (select quiz_id from created_quiz) and question like 'PM2.5%'
    ) and is_correct = true
  ))
);

select is(
  (select auto_score from submit_quiz_attempt('qz-student-a1-token', (select attempt_id from started_attempt))),
  2::numeric,
  'submit_quiz_attempt auto-grades the correct multiple_choice answer (2 points)'
);

select throws_ok(
  $$select save_quiz_answer(
    'qz-student-a1-token', (select attempt_id from started_attempt),
    (select id from quiz_questions where quiz_id = (select quiz_id from created_quiz) limit 1),
    '{}'::jsonb
  )$$,
  'P0001', 'attempt_already_submitted',
  'cannot save an answer on an already-submitted attempt'
);

select * from finish();
rollback;
