-- บอร์ดที่เพิ่งบูตต้องบอกแอปได้ว่ารีเลย์ทุกช่อง OFF แม้ไม่มีคำสั่งให้ ack
begin;

create extension if not exists pgtap with schema extensions;
select plan(8);

insert into packages (id, name, license_type)
values ('99b10000-0000-0000-0000-000000000001', 'Relay boot package', 'perpetual');
insert into schools (id, package_id, name, school_code)
values ('99b20000-0000-0000-0000-000000000001',
        '99b10000-0000-0000-0000-000000000001', 'Relay boot school', 'RBS-A');
insert into users (id, school_id, email, password_hash, first_name, last_name, created_by)
values ('99b30000-0000-0000-0000-000000000001', '99b20000-0000-0000-0000-000000000001',
        'rbs-admin@test.local', crypt('x', gen_salt('bf')), 'Rbs', 'Admin',
        '99b30000-0000-0000-0000-000000000001');
insert into user_roles (user_id, role, school_id, granted_by)
values ('99b30000-0000-0000-0000-000000000001', 'school_admin',
        '99b20000-0000-0000-0000-000000000001', '99b30000-0000-0000-0000-000000000001');
insert into sessions (id, user_id, active_role, active_school_id, token_hash, expires_at)
values ('99b40000-0000-0000-0000-000000000001', '99b30000-0000-0000-0000-000000000001',
        'school_admin', '99b20000-0000-0000-0000-000000000001',
        encode(digest('rbs-admin-token', 'sha256'), 'hex'), now() + interval '1 hour');

insert into devices (id, school_id, type, name, status, token_hash, last_seen_at, registered_by)
values ('99b50000-0000-0000-0000-000000000001', '99b20000-0000-0000-0000-000000000001',
        'relay', 'บอร์ดรีเลย์', 'offline',
        encode(digest('rbs-device-token', 'sha256'), 'hex'),
        now() - interval '2 days', '99b30000-0000-0000-0000-000000000001');

-- เคสจริง: ก่อนไฟดับ แอปจำไว้ว่าช่อง 1 (วาล์วน้ำ) เปิดอยู่ จากคำสั่งที่ ack แล้ว
insert into device_commands (id, device_id, command, created_by, delivered_at, acked_at, ack_status)
values ('99b60000-0000-0000-0000-000000000001', '99b50000-0000-0000-0000-000000000001',
        '{"relay": 1, "state": "ON"}', '99b30000-0000-0000-0000-000000000001',
        now() - interval '1 day', now() - interval '1 day', 'ok');
insert into device_relay_states (device_id, relay_no, state, updated_at, updated_by_command_id)
values ('99b50000-0000-0000-0000-000000000001', 1, true, now() - interval '1 day',
        '99b60000-0000-0000-0000-000000000001');

-- ── บอร์ดบูตขึ้นมา รีเลย์ OFF หมด ──────────────────────────────────────────
select is(
  report_relay_states('rbs-device-token',
    '[{"relay":1,"state":false},{"relay":2,"state":false},
      {"relay":3,"state":false},{"relay":4,"state":false}]'::jsonb),
  4,
  'รายงาน 4 ช่อง ต้องนับได้ 4'
);

select is(
  (select state from device_relay_states
    where device_id = '99b50000-0000-0000-0000-000000000001' and relay_no = 1),
  false,
  'ช่อง 1 ที่แอปจำว่าเปิดอยู่ ต้องกลายเป็นปิดตามที่บอร์ดรายงานหลังบูต'
);

select is(
  (select updated_by_command_id from device_relay_states
    where device_id = '99b50000-0000-0000-0000-000000000001' and relay_no = 1),
  null,
  'สถานะที่บอร์ดรายงานเอง ต้องไม่อ้างคำสั่งเก่าที่ไม่เกี่ยวแล้ว'
);

select is(
  (select count(*)::int from device_relay_states
    where device_id = '99b50000-0000-0000-0000-000000000001'),
  4,
  'ช่อง 2-4 ที่ไม่เคยมีแถว ต้องถูกสร้างขึ้น'
);

-- แอปอ่านผ่าน list_device_relay_states ต้องเห็นค่าใหม่
select is(
  (select count(*)::int from list_device_relay_states('rbs-admin-token',
     '99b50000-0000-0000-0000-000000000001') where state = true),
  0,
  'แอปต้องไม่เห็นช่องไหนเปิดอยู่อีก'
);

-- รายงานตัวไปด้วยในตัว
select ok(
  (select last_seen_at > now() - interval '5 seconds' from devices
    where id = '99b50000-0000-0000-0000-000000000001'),
  'การรายงานสถานะนับเป็นการเห็นอุปกรณ์ด้วย'
);

-- ── ป้องกันของผิด ─────────────────────────────────────────────────────────
select throws_ok(
  $$ select report_relay_states('wrong-token', '[{"relay":1,"state":false}]') $$,
  'invalid_device_token',
  'token ผิด ต้องเขียนอะไรไม่ได้'
);

select throws_like(
  $$ select report_relay_states('rbs-device-token', '[{"relay":"1","state":"off"}]') $$,
  'invalid_states%',
  'relay เป็น string / state เป็น string ต้องไม่ผ่าน — กันเฟิร์มแวร์ส่งผิดชนิดเงียบ ๆ'
);

select * from finish();
rollback;
