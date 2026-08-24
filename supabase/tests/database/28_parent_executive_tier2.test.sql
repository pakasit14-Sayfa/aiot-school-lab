-- =====================================================================
-- Test Suite: 28_parent_executive_tier2.test.sql
-- Verify Tier 2 RPCs: list_my_student_schedule, get_classrooms_overview, list_all_school_schedules
-- =====================================================================

begin;
create extension if not exists pgtap;
select plan(8);

-- Test 1: Functions exist
select has_function('public', 'list_my_student_schedule', ARRAY['text', 'uuid'], 'list_my_student_schedule exists');
select has_function('public', 'get_classrooms_overview', ARRAY['text'], 'get_classrooms_overview exists');
select has_function('public', 'list_all_school_schedules', ARRAY['text'], 'list_all_school_schedules exists');

-- Test 2: Anonymous / invalid token throws invalid_session
select throws_ok(
  $$ select * from list_my_student_schedule('invalid-token', gen_random_uuid()) $$,
  'invalid_session',
  'invalid token throws invalid_session for schedule'
);

select throws_ok(
  $$ select * from get_classrooms_overview('invalid-token') $$,
  'invalid_session',
  'invalid token throws invalid_session for classrooms overview'
);

-- Test 3: Public permissions revoked
select ok(
  not has_function_privilege('public', 'public.list_my_student_schedule(text,uuid)', 'EXECUTE'),
  'public cannot execute list_my_student_schedule'
);

select ok(
  not has_function_privilege('public', 'public.get_classrooms_overview(text)', 'EXECUTE'),
  'public cannot execute get_classrooms_overview'
);

select ok(
  not has_function_privilege('public', 'public.list_all_school_schedules(text)', 'EXECUTE'),
  'public cannot execute list_all_school_schedules'
);

select * from finish();
rollback;
