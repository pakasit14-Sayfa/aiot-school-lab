-- pgTAP Tests: Utility cost calculation & rate setting RPCs (AIO-5, AIO-6 & Water Utility)

begin;

create extension if not exists pgtap with schema extensions;
select plan(15);

insert into packages (id, name, license_type)
values ('88100000-0000-0000-0000-000000000001', 'Utility test package', 'perpetual');

insert into schools (id, package_id, name, school_code) values
  ('88200000-0000-0000-0000-000000000001', '88100000-0000-0000-0000-000000000001', 'Utility School A', 'UTL-A');

insert into school_settings (school_id) values ('88200000-0000-0000-0000-000000000001');

insert into users (
  id, school_id, email, password_hash, first_name, last_name, created_by
) values
  ('88500000-0000-0000-0000-000000000001', '88200000-0000-0000-0000-000000000001',
   'utl-admin@test.local', crypt('pass', gen_salt('bf')), 'School', 'Admin', '88500000-0000-0000-0000-000000000001'),
  ('88500000-0000-0000-0000-000000000002', '88200000-0000-0000-0000-000000000001',
   'utl-student@test.local', crypt('pass', gen_salt('bf')), 'Student', 'User', '88500000-0000-0000-0000-000000000001'),
  ('88500000-0000-0000-0000-000000000003', '88200000-0000-0000-0000-000000000001',
   'utl-executive@test.local', crypt('pass', gen_salt('bf')), 'Executive', 'User', '88500000-0000-0000-0000-000000000001'),
  ('88500000-0000-0000-0000-000000000004', '88200000-0000-0000-0000-000000000001',
   'utl-parent@test.local', crypt('pass', gen_salt('bf')), 'Parent', 'User', '88500000-0000-0000-0000-000000000001'),
  ('88500000-0000-0000-0000-000000000005', '88200000-0000-0000-0000-000000000001',
   'utl-sa@test.local', crypt('pass', gen_salt('bf')), 'Super', 'Admin', '88500000-0000-0000-0000-000000000001');

insert into user_roles (user_id, role, school_id, granted_by) values
  ('88500000-0000-0000-0000-000000000001', 'school_admin', '88200000-0000-0000-0000-000000000001', '88500000-0000-0000-0000-000000000001'),
  ('88500000-0000-0000-0000-000000000002', 'student', '88200000-0000-0000-0000-000000000001', '88500000-0000-0000-0000-000000000001'),
  ('88500000-0000-0000-0000-000000000003', 'executive', '88200000-0000-0000-0000-000000000001', '88500000-0000-0000-0000-000000000001'),
  ('88500000-0000-0000-0000-000000000004', 'parent', '88200000-0000-0000-0000-000000000001', '88500000-0000-0000-0000-000000000001'),
  ('88500000-0000-0000-0000-000000000005', 'super_admin', '88200000-0000-0000-0000-000000000001', '88500000-0000-0000-0000-000000000001');

insert into sessions (user_id, active_role, active_school_id, token_hash, expires_at) values
  ('88500000-0000-0000-0000-000000000001', 'school_admin', '88200000-0000-0000-0000-000000000001',
   encode(digest('utl-admin-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('88500000-0000-0000-0000-000000000002', 'student', '88200000-0000-0000-0000-000000000001',
   encode(digest('utl-student-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('88500000-0000-0000-0000-000000000003', 'executive', '88200000-0000-0000-0000-000000000001',
   encode(digest('utl-executive-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('88500000-0000-0000-0000-000000000004', 'parent', '88200000-0000-0000-0000-000000000001',
   encode(digest('utl-parent-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('88500000-0000-0000-0000-000000000005', 'super_admin', '88200000-0000-0000-0000-000000000001',
   encode(digest('utl-sa-token', 'sha256'), 'hex'), now() + interval '1 hour');

-- Test 1: get_school_utility_rates returns defaults initially
select results_eq(
  $$ select electricity_rate_thb, is_electricity_default, water_rate_thb, is_water_default from get_school_utility_rates('utl-admin-token') $$,
  $$ values (4.50::numeric, true, 18.00::numeric, true) $$,
  'get_school_utility_rates returns default rates (4.50 elec, 18.00 water) initially'
);

-- Test 2: parent role is forbidden from get_school_utility_rates
select throws_ok(
  $$ select get_school_utility_rates('utl-parent-token') $$,
  'forbidden',
  'get_school_utility_rates raises forbidden for parent role'
);

-- Test 3: parent role is forbidden from get_energy_usage_summary
select throws_ok(
  $$ select get_energy_usage_summary('utl-parent-token', 'month') $$,
  'forbidden',
  'get_energy_usage_summary raises forbidden for parent role'
);

-- Test 4: parent role is forbidden from get_water_usage_summary
select throws_ok(
  $$ select get_water_usage_summary('utl-parent-token', 'month') $$,
  'forbidden',
  'get_water_usage_summary raises forbidden for parent role'
);

-- Test 5: invalid token raises invalid_session
select throws_ok(
  $$ select get_energy_usage_summary('invalid-token', 'month') $$,
  'invalid_session',
  'get_energy_usage_summary raises invalid_session for invalid token'
);

-- Test 6: set_school_utility_rates fails for student role (forbidden)
select throws_ok(
  $$ select set_school_utility_rates('utl-student-token', 5.00, 20.00) $$,
  'forbidden',
  'set_school_utility_rates raises forbidden for student role'
);

-- Test 7: set_school_utility_rates fails for non-positive rate
select throws_ok(
  $$ select set_school_utility_rates('utl-admin-token', -1.00, 20.00) $$,
  'invalid_utility_rate',
  'set_school_utility_rates raises invalid_utility_rate for negative electricity rate'
);

-- Test 8: set_school_utility_rates succeeds for school_admin
select lives_ok(
  $$ select set_school_utility_rates('utl-admin-token', 5.20, 22.50) $$,
  'school_admin can set utility rates'
);

-- Test 9: get_school_utility_rates returns updated custom rates
select results_eq(
  $$ select electricity_rate_thb, is_electricity_default, water_rate_thb, is_water_default from get_school_utility_rates('utl-admin-token') $$,
  $$ values (5.20::numeric, false, 22.50::numeric, false) $$,
  'get_school_utility_rates returns configured custom rates'
);

-- Test 10: get_energy_usage_summary returns row structure & disclaimer
select isnt_empty(
  $$ select * from get_energy_usage_summary('utl-executive-token', 'month') $$,
  'get_energy_usage_summary returns energy usage summary for executive'
);

select results_eq(
  $$ select disclaimer from get_energy_usage_summary('utl-executive-token', 'month') $$,
  $$ values ('ค่าบริการประมาณการเพื่อการบริหารจัดการภายใน ไม่ใช่ใบแจ้งหนี้จริงจากผู้ให้บริการ'::text) $$,
  'get_energy_usage_summary contains AIO-6 BR1 estimate disclaimer'
);

-- Test 12: get_water_usage_summary returns row structure & disclaimer
select isnt_empty(
  $$ select * from get_water_usage_summary('utl-executive-token', 'month') $$,
  'get_water_usage_summary returns water usage summary for executive'
);

select results_eq(
  $$ select disclaimer from get_water_usage_summary('utl-executive-token', 'month') $$,
  $$ values ('ค่าบริการประมาณการเพื่อการบริหารจัดการภายใน ไม่ใช่ใบแจ้งหนี้จริงจากผู้ให้บริการ'::text) $$,
  'get_water_usage_summary contains estimate disclaimer'
);

-- Seed dummy meter device and reading to verify calculation math
do $$
declare
  v_dev_elec uuid;
  v_dev_water uuid;
begin
  insert into devices (school_id, name, type, location, status, registered_by)
  values ('88200000-0000-0000-0000-000000000001', 'Test Energy Meter', 'energy_meter', 'Building A', 'online', '88500000-0000-0000-0000-000000000001')
  returning id into v_dev_elec;

  insert into devices (school_id, name, type, location, status, registered_by)
  values ('88200000-0000-0000-0000-000000000001', 'Test Water Meter', 'water_meter', 'Building A', 'online', '88500000-0000-0000-0000-000000000001')
  returning id into v_dev_water;

  insert into sensor_readings (device_id, metric, ts, value)
  values 
    (v_dev_elec, 'energy_kwh', now(), 100.0),
    (v_dev_water, 'water_m3', now(), 10.0);
end $$;

-- Test 15: energy summary calculates cost (100 kWh * 5.20 = 520.00 THB)
select results_eq(
  $$ select total_kwh, electricity_rate_thb, estimated_cost_thb from get_energy_usage_summary('utl-admin-token', 'month') $$,
  $$ values (100.0::numeric, 5.20::numeric, 520.00::numeric) $$,
  'get_energy_usage_summary correctly calculates 100 kWh * 5.20 = 520.00 THB'
);

-- Test 16: water summary calculates cost (10 m3 * 22.50 = 225.00 THB)
select results_eq(
  $$ select total_m3, water_rate_thb, estimated_cost_thb from get_water_usage_summary('utl-admin-token', 'month') $$,
  $$ values (10.0::numeric, 22.50::numeric, 225.00::numeric) $$,
  'get_water_usage_summary correctly calculates 10 m3 * 22.50 = 225.00 THB'
);

select * from finish();
rollback;
