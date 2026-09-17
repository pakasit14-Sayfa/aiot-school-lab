-- ทางเข้าที่ขาดหาย (2026-09-17): School Admin สร้าง/ลบกิจกรรมปฏิทิน · ครูยื่น/ยกเลิกคำขอ
begin;

create extension if not exists pgtap with schema extensions;
select plan(10);

insert into packages (id, name, license_type)
values ('64100000-0000-0000-0000-000000000001', 'EV package', 'perpetual');
insert into schools (id, package_id, name, school_code) values
  ('64200000-0000-0000-0000-000000000001', '64100000-0000-0000-0000-000000000001', 'EV school A', 'EV-A'),
  ('64200000-0000-0000-0000-000000000002', '64100000-0000-0000-0000-000000000001', 'EV school B', 'EV-B');
insert into users (id, school_id, email, password_hash, first_name, last_name, created_by) values
  ('64500000-0000-0000-0000-000000000001', '64200000-0000-0000-0000-000000000001', 'ev-admin@pdpa.test', crypt('x', gen_salt('bf')), 'Admin', 'A', '64500000-0000-0000-0000-000000000001'),
  ('64500000-0000-0000-0000-000000000002', '64200000-0000-0000-0000-000000000001', 'ev-teacher@pdpa.test', crypt('x', gen_salt('bf')), 'Tea', 'Cher', '64500000-0000-0000-0000-000000000001'),
  ('64500000-0000-0000-0000-000000000003', '64200000-0000-0000-0000-000000000002', 'ev-admin-b@pdpa.test', crypt('x', gen_salt('bf')), 'Admin', 'B', '64500000-0000-0000-0000-000000000003');
insert into user_roles (user_id, role, school_id, granted_by) values
  ('64500000-0000-0000-0000-000000000001', 'school_admin', '64200000-0000-0000-0000-000000000001', '64500000-0000-0000-0000-000000000001'),
  ('64500000-0000-0000-0000-000000000002', 'teacher',      '64200000-0000-0000-0000-000000000001', '64500000-0000-0000-0000-000000000001'),
  ('64500000-0000-0000-0000-000000000003', 'school_admin', '64200000-0000-0000-0000-000000000002', '64500000-0000-0000-0000-000000000003');
insert into sessions (user_id, active_role, active_school_id, token_hash, expires_at) values
  ('64500000-0000-0000-0000-000000000001', 'school_admin', '64200000-0000-0000-0000-000000000001', encode(digest('ev-admin', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('64500000-0000-0000-0000-000000000002', 'teacher',      '64200000-0000-0000-0000-000000000001', encode(digest('ev-teacher', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('64500000-0000-0000-0000-000000000003', 'school_admin', '64200000-0000-0000-0000-000000000002', encode(digest('ev-admin-b', 'sha256'), 'hex'), now() + interval '1 hour');

-- ── กิจกรรมปฏิทิน ──
create temporary table ev as
select create_school_event('ev-admin', 'กีฬาสี', current_date + 7, current_date + 8, 'สนาม', null, 'activity') as id;
select is((select count(*)::int from list_calendar_events('ev-teacher') where title='กีฬาสี'), 1, 'ครูเห็นกิจกรรมที่แอดมินสร้างในปฏิทิน');
select throws_ok($$ select delete_school_event('ev-teacher', (select id from ev)) $$, 'forbidden', 'ครูลบกิจกรรมไม่ได้');
select throws_ok($$ select delete_school_event('ev-admin-b', (select id from ev)) $$, 'forbidden', 'แอดมินโรงเรียนอื่นลบไม่ได้');
select lives_ok($$ select delete_school_event('ev-admin', (select id from ev)) $$, 'แอดมินโรงเรียนเดียวกันลบได้');
select is((select count(*)::int from school_events where id = (select id from ev)), 0, 'แถวหายจริง');
select throws_ok($$ select delete_school_event('ev-admin', (select id from ev)) $$, 'event_not_found', 'ลบซ้ำบอกว่าไม่พบ');

-- ── คำขอของครู ──
create temporary table rq as
select create_staff_request('ev-teacher', 'official_duty', 'อบรม AIoT', current_date + 3, current_date + 4, 'รายละเอียด', 'กทม.') as id;
select is((select status from list_staff_requests('ev-teacher') where request_id = (select id from rq)), 'pending_executive', 'ครูเห็นคำขอของตัวเอง (ไม่มีฝ่าย → ข้ามไปรอ ผอ. ทันที)');
select is((select count(*)::int from list_staff_requests('ev-admin')), 1, 'แอดมินเห็นคำขอในคิว');
select lives_ok($$ select cancel_staff_request('ev-teacher', (select id from rq)) $$, 'ครูยกเลิกคำขอตัวเองได้');
select is((select status from list_staff_requests('ev-teacher') where request_id = (select id from rq)), 'cancelled', 'สถานะเป็นยกเลิก');

select * from finish();
rollback;
