begin;
select plan(7);

-- Test 1: Tables exist
select has_table('public', 'learning_items', 'learning_items table exists');
select has_table('public', 'learning_simulators', 'learning_simulators table exists');

-- Test 2: Anon has no direct access
select ok(
  not has_table_privilege('anon', 'public.learning_items', 'SELECT'),
  'anon cannot select from learning_items'
);
select ok(
  not has_table_privilege('anon', 'public.learning_simulators', 'SELECT'),
  'anon cannot select from learning_simulators'
);

-- Test 3: Super Admin can read and write learning_items
set local role authenticated;
set local "request.jwt.claims" = '{"sub": "c9817872-6a48-461b-88fa-b722b55f454e", "role": "authenticated"}';

select ok(
  (select count(*) >= 1 from public.learning_items),
  'super admin can view all learning items'
);

-- Test 4: Regular student cannot insert new learning item (RLS violation)
reset role;

-- Setup test schools and student
insert into packages (id, name, license_type) values ('88000000-0000-0000-0000-000000000001', 'Test Pkg', 'perpetual') on conflict do nothing;
insert into schools (id, package_id, name, school_code) values ('88000000-0000-0000-0000-000000000002', '88000000-0000-0000-0000-000000000001', 'Test Sch A', 'SCH-TA') on conflict do nothing;
insert into schools (id, package_id, name, school_code) values ('88000000-0000-0000-0000-000000000003', '88000000-0000-0000-0000-000000000001', 'Test Sch B', 'SCH-TB') on conflict do nothing;

insert into users (id, school_id, email, password_hash, first_name, last_name)
values ('88000000-0000-0000-0000-000000000005', '88000000-0000-0000-0000-000000000003', 'student.tb@test.local', 'hash', 'Student', 'TB') on conflict do nothing;
insert into user_roles (user_id, role, school_id, granted_by)
values ('88000000-0000-0000-0000-000000000005', 'student', '88000000-0000-0000-0000-000000000003', '88000000-0000-0000-0000-000000000005') on conflict do nothing;

-- Create an item published strictly to School A
insert into public.learning_items (
  id, training_set, type, title, published, publish_to_all_schools, published_school_ids, created_by
) values (
  '88000000-0000-0000-0000-000000000099', 'KIT-TEST', 'lesson', 'School A Exclusive Lesson', true, false, ARRAY['88000000-0000-0000-0000-000000000002'::uuid], '88000000-0000-0000-0000-000000000005'
);

set local role authenticated;
set local "request.jwt.claims" = '{"sub": "88000000-0000-0000-0000-000000000005", "role": "authenticated"}';

-- Student attempting to insert should fail RLS
select throws_ok(
  $$ insert into public.learning_items (training_set, type, title, created_by) values ('KIT-X', 'lesson', 'Hacked Lesson', '88000000-0000-0000-0000-000000000005'::uuid) $$,
  '42501',
  null,
  'student cannot insert learning items'
);

-- Test 5: Student at School B cannot see School A exclusive lesson
select is(
  (select count(*)::integer from public.learning_items where id = '88000000-0000-0000-0000-000000000099'),
  0,
  'student at school B cannot see item published only to school A'
);

reset role;
select * from finish();
rollback;
