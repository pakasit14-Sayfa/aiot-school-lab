begin;

create extension if not exists pgtap with schema extensions;
set search_path = public, extensions;

select plan(8);

insert into packages (id, name, license_type)
values ('69100000-0000-0000-0000-000000000001', 'DS package', 'perpetual');
insert into schools (id, package_id, name, school_code) values
  ('69200000-0000-0000-0000-000000000001', '69100000-0000-0000-0000-000000000001', 'DS school', 'DS-A');
insert into users (id, school_id, email, password_hash, first_name, last_name, created_by) values
  ('69500000-0000-0000-0000-000000000001', '69200000-0000-0000-0000-000000000001', 'ds-teacher@pdpa.test', crypt('x', gen_salt('bf')), 'Tea', 'Cher', '69500000-0000-0000-0000-000000000001');
insert into user_roles (user_id, role, school_id, granted_by) values
  ('69500000-0000-0000-0000-000000000001', 'teacher', '69200000-0000-0000-0000-000000000001', '69500000-0000-0000-0000-000000000001');
insert into sessions (user_id, active_role, active_school_id, token_hash, expires_at) values
  ('69500000-0000-0000-0000-000000000001', 'teacher', '69200000-0000-0000-0000-000000000001', encode(digest('ds-teacher', 'sha256'), 'hex'), now() + interval '1 hour');
insert into devices (id, school_id, type, name, registered_by) values
  ('69600000-0000-0000-0000-000000000001', '69200000-0000-0000-0000-000000000001', 'air_quality_sensor', 'ห้องทดลอง', '69500000-0000-0000-0000-000000000001');

-- 3,000 readings, one every 3 s, over 2.5 h on 2026-08-29 — the prod shape
insert into sensor_readings (device_id, metric, ts, value)
select '69600000-0000-0000-0000-000000000001', 'temperature',
       '2026-08-29 02:48:00+00'::timestamptz + (g * interval '3 seconds'),
       25 + (g % 10)
from generate_series(0, 2999) g;

-- 1. 30-day window: no longer cut to the first 1,000 rows
select cmp_ok(
  (select count(*)::int from sensor_history('ds-teacher', '69600000-0000-0000-0000-000000000001', 'temperature', '2026-08-01+00', '2026-08-31+00')),
  '<=', 1000, 'ผลไม่เกิน 1,000 จุด (ค่าเริ่มต้น)'
);
select cmp_ok(
  (select count(*)::int from sensor_history('ds-teacher', '69600000-0000-0000-0000-000000000001', 'temperature', '2026-08-01+00', '2026-08-31+00')),
  '>=', 900, 'แต่ก็ไม่ย่อจนเหลือน้อยเกินไป (ความละเอียดตามช่วงข้อมูลจริง ไม่ใช่ช่วงที่ขอ)'
);

-- 2. the whole span survives: last point is near the last reading, not 50 min in
select ok(
  (select max(ts) from sensor_history('ds-teacher', '69600000-0000-0000-0000-000000000001', 'temperature', '2026-08-01+00', '2026-08-31+00'))
    >= '2026-08-29 05:17:00+00'::timestamptz,
  'จุดสุดท้ายอยู่ท้ายชุดข้อมูล ไม่ใช่ถูกตัดที่ 1,000 แถวแรก'
);

-- 3. averages stay in range
select ok(
  (select bool_and(value between 25 and 34) from sensor_history('ds-teacher', '69600000-0000-0000-0000-000000000001', 'temperature', '2026-08-01+00', '2026-08-31+00')),
  'ค่าเฉลี่ยต่อ bucket อยู่ในช่วงของค่าจริง'
);

-- 4. p_max_points is honoured
select cmp_ok(
  (select count(*)::int from sensor_history('ds-teacher', '69600000-0000-0000-0000-000000000001', 'temperature', '2026-08-01+00', '2026-08-31+00', 100)),
  '<=', 100, 'p_max_points = 100 ให้ไม่เกิน 100 จุด'
);

-- 5. small result sets come back raw (no averaging) — 10 readings in a 30 s window
select is(
  (select count(*)::int from sensor_history('ds-teacher', '69600000-0000-0000-0000-000000000001', 'temperature', '2026-08-29 02:48:00+00', '2026-08-29 02:48:27+00')),
  10, 'ชุดเล็กกว่า max คืนค่าดิบครบทุกจุด'
);
select is(
  (select value from sensor_history('ds-teacher', '69600000-0000-0000-0000-000000000001', 'temperature', '2026-08-29 02:48:00+00', '2026-08-29 02:48:27+00') order by ts limit 1),
  25::numeric, 'ค่าดิบไม่ถูกปัด/เฉลี่ย'
);

-- 6. empty window
select is(
  (select count(*)::int from sensor_history('ds-teacher', '69600000-0000-0000-0000-000000000001', 'temperature', '2026-09-01+00', '2026-09-30+00')),
  0, 'ช่วงที่ไม่มีข้อมูลคืน 0 แถว'
);

select * from finish();
rollback;
