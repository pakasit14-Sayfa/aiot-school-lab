-- change_my_password · list/revoke_my_session · import users ด้วยรหัสชั่วคราว
-- (20260914020000)
begin;

create extension if not exists pgtap with schema extensions;
select plan(18);

insert into packages (id, name, license_type)
values ('59100000-0000-0000-0000-000000000001', 'Account package', 'perpetual');
insert into schools (id, package_id, name, school_code)
values ('59200000-0000-0000-0000-000000000001', '59100000-0000-0000-0000-000000000001', 'Account school', 'ACC-A');

insert into users (id, school_id, email, password_hash, first_name, last_name, created_by) values
  ('59500000-0000-0000-0000-000000000001', '59200000-0000-0000-0000-000000000001',
   'acc-admin@pdpa.test', crypt('OldPass123', gen_salt('bf')), 'Admin', 'A', '59500000-0000-0000-0000-000000000001'),
  ('59500000-0000-0000-0000-000000000002', '59200000-0000-0000-0000-000000000001',
   'acc-other@pdpa.test', crypt('x', gen_salt('bf')), 'Other', 'O', '59500000-0000-0000-0000-000000000001');
insert into user_roles (user_id, role, school_id, granted_by) values
  ('59500000-0000-0000-0000-000000000001', 'school_admin', '59200000-0000-0000-0000-000000000001', '59500000-0000-0000-0000-000000000001'),
  ('59500000-0000-0000-0000-000000000002', 'teacher',      '59200000-0000-0000-0000-000000000001', '59500000-0000-0000-0000-000000000001');

-- แอดมินมี 2 เครื่อง (2 เซสชัน) + คนอื่นมี 1
insert into sessions (id, user_id, active_role, active_school_id, token_hash, device_info, expires_at) values
  ('59800000-0000-0000-0000-000000000001', '59500000-0000-0000-0000-000000000001', 'school_admin',
   '59200000-0000-0000-0000-000000000001', encode(digest('acc-admin-laptop', 'sha256'), 'hex'), 'Laptop', now() + interval '1 hour'),
  ('59800000-0000-0000-0000-000000000002', '59500000-0000-0000-0000-000000000001', 'school_admin',
   '59200000-0000-0000-0000-000000000001', encode(digest('acc-admin-phone', 'sha256'), 'hex'), 'Phone', now() + interval '1 hour'),
  ('59800000-0000-0000-0000-000000000003', '59500000-0000-0000-0000-000000000002', 'teacher',
   '59200000-0000-0000-0000-000000000001', encode(digest('acc-other', 'sha256'), 'hex'), 'Other phone', now() + interval '1 hour');

-- ── sessions ──
select is((select count(*)::int from list_my_sessions('acc-admin-laptop')), 2, 'เห็นเซสชันของตัวเองทั้ง 2 เครื่อง');
select is((select is_current from list_my_sessions('acc-admin-laptop') where device_info='Laptop'), true, 'เครื่องที่เรียกถูกทำเครื่องหมายว่าเป็นเครื่องปัจจุบัน');
select is((select count(*)::int from list_my_sessions('acc-admin-laptop') where device_info='Other phone'), 0, 'ไม่เห็นเซสชันของคนอื่น');
select throws_ok($$ select revoke_my_session('acc-admin-laptop', '59800000-0000-0000-0000-000000000001') $$,
  'cannot_revoke_current_session', 'ถอนเครื่องปัจจุบันผ่านทางนี้ไม่ได้');
select throws_ok($$ select revoke_my_session('acc-admin-laptop', '59800000-0000-0000-0000-000000000003') $$,
  'session_not_found', 'ถอนเซสชันของคนอื่นไม่ได้ (ไม่บอกด้วยซ้ำว่ามี)');
select lives_ok($$ select revoke_my_session('acc-admin-laptop', '59800000-0000-0000-0000-000000000002') $$, 'ถอนเครื่องอื่นของตัวเองได้');
select is((select count(*)::int from get_session_actor('acc-admin-phone')), 0, 'เครื่องที่ถูกถอนใช้ token ต่อไม่ได้');

-- ── change password ──
select throws_ok($$ select change_my_password('acc-admin-laptop', 'WrongPass', 'NewPass12345') $$,
  'wrong_current_password', 'รหัสปัจจุบันผิดต้องถูกปฏิเสธ');
select throws_ok($$ select change_my_password('acc-admin-laptop', 'OldPass123', 'short') $$,
  'password_too_short', 'รหัสใหม่สั้นกว่า 8 ตัวต้องถูกปฏิเสธ');
update users set must_change_password = true where id = '59500000-0000-0000-0000-000000000001';
insert into sessions (id, user_id, active_role, active_school_id, token_hash, device_info, expires_at) values
  ('59800000-0000-0000-0000-000000000004', '59500000-0000-0000-0000-000000000001', 'school_admin',
   '59200000-0000-0000-0000-000000000001', encode(digest('acc-admin-tablet', 'sha256'), 'hex'), 'Tablet', now() + interval '1 hour');
select lives_ok($$ select change_my_password('acc-admin-laptop', 'OldPass123', 'NewPass12345') $$, 'เปลี่ยนรหัสด้วยรหัสปัจจุบันที่ถูกได้');
select is((select password_hash = crypt('NewPass12345', password_hash) from users where id='59500000-0000-0000-0000-000000000001'), true, 'รหัสใหม่ใช้ได้จริง');
select is((select must_change_password from users where id='59500000-0000-0000-0000-000000000001'), false, 'เปลี่ยนรหัสแล้ว must_change_password ถูกล้าง');
select is((select count(*)::int from get_session_actor('acc-admin-tablet')), 0, 'เซสชันอื่นหลุดหลังเปลี่ยนรหัส');
select is((select count(*)::int from get_session_actor('acc-admin-laptop')), 1, 'เครื่องที่เปลี่ยนรหัสยังใช้ต่อได้');

-- ── import users ──
select is(
  ((select import_school_users_batch_for_school_admin('acc-admin-laptop', 'student', '[
      {"email": "new1@acc.test", "first_name": "หนึ่ง", "student_code": "S001"},
      {"email": "acc-other@pdpa.test", "first_name": "ซ้ำ"},
      {"first_name": "ไม่มีอีเมล"}
    ]'::jsonb))->>'inserted_count')::int,
  1, 'นำเข้าได้ 1 จาก 3 (อีเมลซ้ำ + ไม่มีอีเมล ถูกข้าม)');
select is(
  (select jsonb_array_length(import_school_users_batch_for_school_admin('acc-admin-laptop', 'student', '[
      {"email": "new2@acc.test", "first_name": "สอง"}
    ]'::jsonb)->'credentials')),
  1, 'คืน credentials ให้ 1 รายการต่อบัญชีที่สร้าง');
select is((select must_change_password from users where email='new1@acc.test'), true,
  'บัญชีที่นำเข้าถูกบังคับเปลี่ยนรหัสก่อนใช้');
select is((select password_hash = crypt('Test1234!', password_hash) from users where email='new1@acc.test'), false,
  'รหัสไม่ใช่ Test1234! ที่เดาได้อีกต่อไป');

select * from finish();
rollback;
