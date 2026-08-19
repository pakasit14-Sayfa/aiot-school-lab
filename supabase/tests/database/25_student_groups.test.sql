begin;
select plan(4);

-- Test 1: Verify list_student_groups throws invalid_session with empty token
select throws_ok(
  $$ select * from list_student_groups('', '00000000-0000-0000-0000-000000000001'::uuid) $$,
  'invalid_session',
  'list_student_groups requires valid session token'
);

-- Test 2: Verify create_student_group throws invalid_session with invalid token
select throws_ok(
  $$ select create_student_group('invalid-token', '00000000-0000-0000-0000-000000000001'::uuid, 'กลุ่มทดสอบ') $$,
  'invalid_session',
  'create_student_group requires valid session token'
);

-- Test 3: Verify delete_student_group throws invalid_session with invalid token
select throws_ok(
  $$ select delete_student_group('invalid-token', '00000000-0000-0000-0000-000000000001'::uuid) $$,
  'invalid_session',
  'delete_student_group requires valid session token'
);

-- Test 4: Verify rename_student_group throws invalid_session with invalid token
select throws_ok(
  $$ select rename_student_group('invalid-token', '00000000-0000-0000-0000-000000000001'::uuid, 'ชื่อใหม่') $$,
  'invalid_session',
  'rename_student_group requires valid session token'
);

select * from finish();
rollback;
