-- admin_token_patched
-- PBL-7 (2026-09-18): กราฟของนักเรียน — สร้าง/ดู/ลบ ภายในขอบเขตข้อมูลที่เรียนได้
begin;

create extension if not exists pgtap with schema extensions;
select plan(13);

insert into packages (id, name, license_type)
values ('66100000-0000-0000-0000-000000000001', 'CH package', 'perpetual');
insert into schools (id, package_id, name, school_code) values
  ('66200000-0000-0000-0000-000000000001', '66100000-0000-0000-0000-000000000001', 'CH school A', 'CH-A'),
  ('66200000-0000-0000-0000-000000000002', '66100000-0000-0000-0000-000000000001', 'CH school B', 'CH-B');
insert into academic_years (id, school_id, name)
values ('66300000-0000-0000-0000-000000000001', '66200000-0000-0000-0000-000000000001', '2026');
insert into terms (id, academic_year_id, name)
values ('66400000-0000-0000-0000-000000000001', '66300000-0000-0000-0000-000000000001', 'Term 1/2026');
insert into users (id, school_id, email, password_hash, first_name, last_name, created_by) values
  ('66900000-0000-0000-0000-000000000000', '66200000-0000-0000-0000-000000000001', 'admin66@pdpa.test', crypt('x', gen_salt('bf')), 'Admin', 'Patch', '66900000-0000-0000-0000-000000000000'),
  ('66500000-0000-0000-0000-000000000001', '66200000-0000-0000-0000-000000000001', 'ch-teacher@pdpa.test', crypt('x', gen_salt('bf')), 'Tea', 'Cher', '66500000-0000-0000-0000-000000000001'),
  ('66500000-0000-0000-0000-000000000002', '66200000-0000-0000-0000-000000000001', 'ch-s1@pdpa.test', crypt('x', gen_salt('bf')), 'Stu', 'One', '66500000-0000-0000-0000-000000000001'),
  ('66500000-0000-0000-0000-000000000003', '66200000-0000-0000-0000-000000000001', 'ch-s2@pdpa.test', crypt('x', gen_salt('bf')), 'Stu', 'Two', '66500000-0000-0000-0000-000000000001');
insert into user_roles (user_id, role, school_id, granted_by) values
  ('66900000-0000-0000-0000-000000000000', 'school_admin', '66200000-0000-0000-0000-000000000001', '66900000-0000-0000-0000-000000000000'),
  ('66500000-0000-0000-0000-000000000001', 'teacher', '66200000-0000-0000-0000-000000000001', '66500000-0000-0000-0000-000000000001'),
  ('66500000-0000-0000-0000-000000000002', 'student', '66200000-0000-0000-0000-000000000001', '66500000-0000-0000-0000-000000000001'),
  ('66500000-0000-0000-0000-000000000003', 'student', '66200000-0000-0000-0000-000000000001', '66500000-0000-0000-0000-000000000001');
insert into sessions (user_id, active_role, active_school_id, token_hash, expires_at) values
  ('66900000-0000-0000-0000-000000000000', 'school_admin', '66200000-0000-0000-0000-000000000001', encode(digest('admin-token-patched-66', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('66500000-0000-0000-0000-000000000001', 'teacher', '66200000-0000-0000-0000-000000000001', encode(digest('ch-teacher', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('66500000-0000-0000-0000-000000000002', 'student', '66200000-0000-0000-0000-000000000001', encode(digest('ch-s1', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('66500000-0000-0000-0000-000000000003', 'student', '66200000-0000-0000-0000-000000000001', encode(digest('ch-s2', 'sha256'), 'hex'), now() + interval '1 hour');
insert into devices (id, school_id, type, name, registered_by) values
  ('66600000-0000-0000-0000-000000000001', '66200000-0000-0000-0000-000000000001', 'pm25_sensor', 'ฝุ่นหน้าห้อง', '66500000-0000-0000-0000-000000000001'),
  ('66600000-0000-0000-0000-000000000002', '66200000-0000-0000-0000-000000000002', 'pm25_sensor', 'อุปกรณ์โรงเรียน B', '66500000-0000-0000-0000-000000000001');

create temporary table c as
select * from create_course('admin-token-patched-66', '66400000-0000-0000-0000-000000000001', 'AIoT', 'ม.1', '101', 'x', '66500000-0000-0000-0000-000000000001');
select enroll_student('admin-token-patched-66', (select course_id from c), '66500000-0000-0000-0000-000000000002');
-- s2 ลงทะเบียนวิชา แต่ยังไม่มีชุดข้อมูลให้เรียน
create temporary table a as
select assignment_id from create_assignment('ch-teacher', (select course_id from c), 'homework', 'วิเคราะห์ฝุ่น');
select link_assignment_sensor_dataset('ch-teacher', (select assignment_id from a), '66600000-0000-0000-0000-000000000001', 'pm25', '2026-09-10 00:00+07', '2026-09-11 00:00+07', 'ฝุ่น 1 วัน');
select publish_assignment('ch-teacher', (select assignment_id from a));

-- ── รายการที่ชาร์ตได้ ──
select is((select count(*)::int from list_my_sensor_datasets('ch-s1')), 1, 's1 เห็นชุดข้อมูลของใบงานที่ครูผูก');
select is((select device_name from list_my_sensor_datasets('ch-s1') limit 1), 'ฝุ่นหน้าห้อง'::varchar, 'มีชื่ออุปกรณ์มาด้วย (นักเรียนเรียก list_school_devices ไม่ได้)');
select is((select count(*)::int from list_my_sensor_datasets('ch-s2')), 0, 'นักเรียนที่ไม่ได้อยู่ในวิชา ไม่เห็นอะไร');

-- ── สร้างในขอบเขต ──
create temporary table ch as
select create_chart('ch-s1', '66600000-0000-0000-0000-000000000001', 'pm25', '2026-09-10 08:00+07', '2026-09-10 12:00+07', 'line', (select course_id from c), '  ช่วงเช้าฝุ่นสูง  ') as id;
select is((select annotation from charts where id = (select id from ch)), 'ช่วงเช้าฝุ่นสูง', 'บันทึกกราฟได้ (annotation ตัดช่องว่าง)');
select is((select count(*)::int from list_my_charts('ch-s1')), 1, 's1 เห็นกราฟของตัวเอง');
select is((select count(*)::int from list_my_charts('ch-s2')), 0, 's2 ไม่เห็นกราฟของ s1');

-- ── นอกขอบเขต ──
select throws_ok($$ select create_chart('ch-s1', '66600000-0000-0000-0000-000000000001', 'pm25', '2026-09-09 08:00+07', '2026-09-10 12:00+07') $$, 'learning_dataset_required', 'ช่วงเวลากว้างกว่าที่ครูให้ → ปฏิเสธ');
select throws_ok($$ select create_chart('ch-s1', '66600000-0000-0000-0000-000000000001', 'temperature', '2026-09-10 08:00+07', '2026-09-10 12:00+07') $$, 'learning_dataset_required', 'ค่าอื่นที่ครูไม่ได้ให้ → ปฏิเสธ');
select throws_ok($$ select create_chart('ch-s2', '66600000-0000-0000-0000-000000000001', 'pm25', '2026-09-10 08:00+07', '2026-09-10 12:00+07') $$, 'learning_dataset_required', 'นักเรียนไม่มีชุดข้อมูล → ปฏิเสธ');
select throws_ok($$ select create_chart('ch-teacher', '66600000-0000-0000-0000-000000000002', 'pm25', '2026-09-10 08:00+07', '2026-09-10 12:00+07') $$, 'forbidden', 'อุปกรณ์โรงเรียนอื่น → ปฏิเสธ แม้เป็นครู');
select throws_ok($$ select create_chart('ch-s1', '66600000-0000-0000-0000-000000000001', 'pm25', '2026-09-10 12:00+07', '2026-09-10 08:00+07') $$, 'invalid_time_range', 'เวลาย้อนกลับ → ปฏิเสธ');

-- ── ลบ ──
select throws_ok($$ select delete_chart('ch-s2', (select id from ch)) $$, 'forbidden', 'คนอื่นลบไม่ได้');
select lives_ok($$ select delete_chart('ch-s1', (select id from ch)) $$, 'เจ้าของลบได้');

select * from finish();
rollback;
