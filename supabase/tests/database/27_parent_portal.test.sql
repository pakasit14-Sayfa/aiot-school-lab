-- =====================================================================
-- Test Suite: 27_parent_portal.test.sql
-- Verify parent portal RPCs: list_my_linked_students, list_my_student_grades
-- =====================================================================

begin;
create extension if not exists pgtap;
select plan(7);

-- Test 1: Function exists
select has_function('public', 'list_my_linked_students', ARRAY['text'], 'list_my_linked_students exists');
select has_function('public', 'list_my_student_grades', ARRAY['text', 'uuid'], 'list_my_student_grades exists');

-- Test 2: Anonymous execution throws invalid_session
select throws_ok(
  $$ select * from list_my_linked_students('invalid-token') $$,
  'invalid_session',
  'invalid token throws invalid_session'
);

select throws_ok(
  $$ select * from list_my_student_grades('invalid-token', gen_random_uuid()) $$,
  'invalid_session',
  'invalid token throws invalid_session for grades'
);

-- Test 3: Public permissions revoked
select ok(
  not has_function_privilege('public', 'public.list_my_student_grades(text,uuid)', 'EXECUTE'),
  'public cannot execute list_my_student_grades'
);

select ok(
  has_function_privilege('authenticated', 'public.list_my_student_grades(text,uuid)', 'EXECUTE'),
  'authenticated can execute list_my_student_grades'
);

select ok(
  has_function_privilege('authenticated', 'public.list_my_linked_students(text)', 'EXECUTE'),
  'authenticated can execute list_my_linked_students'
);

select * from finish();
rollback;
