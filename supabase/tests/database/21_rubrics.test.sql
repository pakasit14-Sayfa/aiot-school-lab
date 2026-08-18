-- pgTAP Tests: Rubric management RPCs (create_rubric, list_my_rubrics, get_rubric, add_rubric_criterion)

begin;

create extension if not exists pgtap with schema extensions;
select plan(7);

insert into packages (id, name, license_type)
values ('77100000-0000-0000-0000-000000000001', 'Rubric test package', 'perpetual');

insert into schools (id, package_id, name, school_code) values
  ('77200000-0000-0000-0000-000000000001', '77100000-0000-0000-0000-000000000001', 'Rubric School A', 'RUB-A');

insert into users (
  id, school_id, email, password_hash, first_name, last_name, created_by
) values
  ('77500000-0000-0000-0000-000000000001', '77200000-0000-0000-0000-000000000001',
   'rub-teacher@test.local', crypt('pass', gen_salt('bf')), 'Rubric', 'Teacher', '77500000-0000-0000-0000-000000000001'),
  ('77500000-0000-0000-0000-000000000002', '77200000-0000-0000-0000-000000000001',
   'rub-student@test.local', crypt('pass', gen_salt('bf')), 'Rubric', 'Student', '77500000-0000-0000-0000-000000000001');

insert into user_roles (user_id, role, school_id, granted_by) values
  ('77500000-0000-0000-0000-000000000001', 'teacher', '77200000-0000-0000-0000-000000000001', '77500000-0000-0000-0000-000000000001'),
  ('77500000-0000-0000-0000-000000000002', 'student', '77200000-0000-0000-0000-000000000001', '77500000-0000-0000-0000-000000000001');

insert into sessions (user_id, active_role, active_school_id, token_hash, expires_at) values
  ('77500000-0000-0000-0000-000000000001', 'teacher', '77200000-0000-0000-0000-000000000001',
   encode(digest('rub-teacher-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('77500000-0000-0000-0000-000000000002', 'student', '77200000-0000-0000-0000-000000000001',
   encode(digest('rub-student-token', 'sha256'), 'hex'), now() + interval '1 hour');

-- Test 1: create_rubric by teacher
prepare test_create_rubric as
  select create_rubric(
    'rub-teacher-token',
    'เกณฑ์ประเมินโครงงาน AIoT',
    'รายละเอียดเกณฑ์ประเมิน',
    '[{"name": "ความคิดสร้างสรรค์", "max_score": 10}, {"name": "การต่อวงจร", "max_score": 10}]'::jsonb
  );
select lives_ok('test_create_rubric', 'create_rubric creates new rubric with criteria');

-- Test 2: Student cannot create rubric
prepare test_student_create_rubric as
  select create_rubric('rub-student-token', 'Rubric ปลอม');
select throws_ok('test_student_create_rubric', 'forbidden', 'Student cannot create rubric');

-- Test 3: Title required
prepare test_empty_title as
  select create_rubric('rub-teacher-token', '');
select throws_ok('test_empty_title', 'title_required', 'Empty title throws exception');

-- Test 4: list_my_rubrics
prepare test_list_rubrics as
  select count(*) from list_my_rubrics('rub-teacher-token');
select results_eq('test_list_rubrics', array[1::bigint], 'list_my_rubrics returns 1 rubric');

-- Test 5: get_rubric
select is(
  (select title from get_rubric(
    'rub-teacher-token',
    (select id from rubrics where school_id = '77200000-0000-0000-0000-000000000001' limit 1)
  )),
  'เกณฑ์ประเมินโครงงาน AIoT',
  'get_rubric returns correct rubric title'
);

-- Test 6: add_rubric_criterion
prepare test_add_criterion as
  select add_rubric_criterion(
    'rub-teacher-token',
    (select id from rubrics where school_id = '77200000-0000-0000-0000-000000000001' limit 1),
    'การนำเสนอผลงาน',
    'ประเมินการพูดและการตอบคำถาม',
    10
  );
select lives_ok('test_add_criterion', 'add_rubric_criterion adds new criterion');

-- Test 7: verify criteria count is now 3
select is(
  (select (jsonb_array_length(criteria)) from get_rubric(
    'rub-teacher-token',
    (select id from rubrics where school_id = '77200000-0000-0000-0000-000000000001' limit 1)
  )),
  3,
  'get_rubric returns 3 criteria after add_rubric_criterion'
);

select * from finish();
rollback;
