-- =====================================================================
-- Test Suite: 29_school_admin_bulk_import.test.sql
-- Verify import_school_buildings_batch / import_school_rooms_batch /
-- import_school_devices_batch — role gating, duplicate/invalid-row
-- skipping without aborting the batch, and tenant isolation.
-- =====================================================================

begin;

create extension if not exists pgtap with schema extensions;
select plan(19);

insert into packages (id, name, license_type)
values ('99600000-0000-0000-0000-000000000001', 'Bulk import test package', 'perpetual');

insert into schools (id, package_id, name, school_code) values
  ('99700000-0000-0000-0000-000000000001', '99600000-0000-0000-0000-000000000001', 'Bulk import school A', 'IMP-A'),
  ('99700000-0000-0000-0000-000000000002', '99600000-0000-0000-0000-000000000001', 'Bulk import school B', 'IMP-B');

insert into users (
  id, school_id, email, password_hash, first_name, last_name, created_by
) values
  ('99800000-0000-0000-0000-000000000001', '99700000-0000-0000-0000-000000000001',
   'imp-admin-a@pdpa.test', crypt('irrelevant', gen_salt('bf')), 'Admin', 'A',
   '99800000-0000-0000-0000-000000000001'),
  ('99800000-0000-0000-0000-000000000002', '99700000-0000-0000-0000-000000000001',
   'imp-teacher-a@pdpa.test', crypt('irrelevant', gen_salt('bf')), 'Teacher', 'A',
   '99800000-0000-0000-0000-000000000001');

insert into user_roles (user_id, role, school_id, granted_by) values
  ('99800000-0000-0000-0000-000000000001', 'school_admin', '99700000-0000-0000-0000-000000000001', '99800000-0000-0000-0000-000000000001'),
  ('99800000-0000-0000-0000-000000000002', 'teacher', '99700000-0000-0000-0000-000000000001', '99800000-0000-0000-0000-000000000001');

insert into sessions (user_id, active_role, active_school_id, token_hash, expires_at) values
  ('99800000-0000-0000-0000-000000000001', 'school_admin', '99700000-0000-0000-0000-000000000001',
   encode(digest('imp-admin-a-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('99800000-0000-0000-0000-000000000002', 'teacher', '99700000-0000-0000-0000-000000000001',
   encode(digest('imp-teacher-a-token', 'sha256'), 'hex'), now() + interval '1 hour');

-- Functions exist
select has_function('public', 'import_school_buildings_batch', ARRAY['text', 'jsonb'], 'import_school_buildings_batch exists');
select has_function('public', 'import_school_rooms_batch', ARRAY['text', 'jsonb'], 'import_school_rooms_batch exists');
select has_function('public', 'import_school_devices_batch', ARRAY['text', 'jsonb'], 'import_school_devices_batch exists');

-- Public execute revoked
select ok(
  not has_function_privilege('public', 'public.import_school_buildings_batch(text,jsonb)', 'EXECUTE'),
  'public cannot execute import_school_buildings_batch'
);
select ok(
  not has_function_privilege('public', 'public.import_school_rooms_batch(text,jsonb)', 'EXECUTE'),
  'public cannot execute import_school_rooms_batch'
);
select ok(
  not has_function_privilege('public', 'public.import_school_devices_batch(text,jsonb)', 'EXECUTE'),
  'public cannot execute import_school_devices_batch'
);

-- Role rejection: a teacher token cannot call any of the three
select throws_ok(
  $$ select import_school_buildings_batch('imp-teacher-a-token', '[]'::jsonb) $$,
  'forbidden: school_admin or super_admin role required',
  'teacher cannot call import_school_buildings_batch'
);
select throws_ok(
  $$ select import_school_rooms_batch('imp-teacher-a-token', '[]'::jsonb) $$,
  'forbidden: school_admin or super_admin role required',
  'teacher cannot call import_school_rooms_batch'
);
select throws_ok(
  $$ select import_school_devices_batch('imp-teacher-a-token', '[]'::jsonb) $$,
  'forbidden: school_admin or super_admin role required',
  'teacher cannot call import_school_devices_batch'
);

-- Buildings: one valid row + one duplicate code in the same batch
select results_eq(
  $$
    select (import_school_buildings_batch('imp-admin-a-token', '[
      {"name": "อาคารทดสอบ A", "code": "IMP-BLD-A", "floors": 3},
      {"name": "อาคารซ้ำ", "code": "IMP-BLD-A", "floors": 2}
    ]'::jsonb)->>'inserted_count')::int
  $$,
  $$ select 1 $$,
  'buildings batch inserts only the first of two duplicate-code rows'
);

select is(
  (select count(*)::int from buildings where school_id = '99700000-0000-0000-0000-000000000001' and code = 'IMP-BLD-A'),
  1,
  'exactly one building row landed for school A'
);

select is(
  (select count(*)::int from buildings where school_id = '99700000-0000-0000-0000-000000000002' and code = 'IMP-BLD-A'),
  0,
  'the building did not leak into school B (tenant isolation)'
);

-- Rooms: one valid row referencing the just-created building + one with an unknown building_code
select results_eq(
  $$
    select (import_school_rooms_batch('imp-admin-a-token', '[
      {"name": "ห้องทดสอบ 101", "code": "IMP-ROOM-101", "building_code": "IMP-BLD-A", "floor": "1", "capacity": 30},
      {"name": "ห้องอ้างอิงผิด", "code": "IMP-ROOM-999", "building_code": "NOT-EXIST", "floor": "1", "capacity": 30}
    ]'::jsonb)->>'inserted_count')::int
  $$,
  $$ select 1 $$,
  'rooms batch inserts only the row with a real building_code'
);

select is(
  (
    select (import_school_rooms_batch('imp-admin-a-token', '[
      {"name": "อีกห้อง", "code": "IMP-ROOM-102", "building_code": "NOT-EXIST-2", "floor": "1", "capacity": 30}
    ]'::jsonb)->'skipped'->0->>'reason')
  ),
  'building_not_found',
  'a room row with an unknown building_code is skipped with reason building_not_found, not silently accepted'
);

-- Devices: one valid + one invalid device_type + one duplicate serial_no
select results_eq(
  $$
    select (import_school_devices_batch('imp-admin-a-token', '[
      {"name": "เซนเซอร์ทดสอบ", "type": "pm25_sensor", "location": "ห้อง 101", "serial_no": "IMP-SN-001"},
      {"name": "ชนิดผิด", "type": "not_a_real_type", "location": "ห้อง 102"},
      {"name": "ซ้ำ serial", "type": "pm25_sensor", "location": "ห้อง 103", "serial_no": "IMP-SN-001"}
    ]'::jsonb)->>'inserted_count')::int
  $$,
  $$ select 1 $$,
  'devices batch inserts only the one fully-valid row out of three'
);

select is(
  (select count(*)::int from devices where school_id = '99700000-0000-0000-0000-000000000001' and serial_no = 'IMP-SN-001'),
  1,
  'exactly one device row landed with the expected serial_no'
);

-- A kit_code-only row (ชุดฝึก use case) still inserts as a device
select results_eq(
  $$
    select (import_school_devices_batch('imp-admin-a-token', '[
      {"name": "ชุดฝึก AIoT ห้อง 101", "type": "relay", "kit_code": "IMP-KIT-001"}
    ]'::jsonb)->>'inserted_count')::int
  $$,
  $$ select 1 $$,
  'a training-kit row (kit_code, no serial_no) inserts as a device'
);

select is(
  (select kit_code from devices where school_id = '99700000-0000-0000-0000-000000000001' and name = 'ชุดฝึก AIoT ห้อง 101'),
  'IMP-KIT-001',
  'the kit_code was stored on the inserted device row'
);

-- Invalid session still rejected
select throws_ok(
  $$ select import_school_buildings_batch('not-a-real-token', '[]'::jsonb) $$,
  'invalid_session',
  'an invalid token is rejected for import_school_buildings_batch'
);

select * from finish();
rollback;
