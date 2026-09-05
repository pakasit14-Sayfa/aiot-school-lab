begin;

create extension if not exists pgtap with schema extensions;
select plan(58);

insert into packages (id, name, license_type)
values ('99100000-0000-0000-0000-000000000001', 'Learning tracks test package', 'perpetual');

insert into schools (id, package_id, name, school_code) values
  ('99200000-0000-0000-0000-000000000001', '99100000-0000-0000-0000-000000000001', 'Learning school A', 'TRACK-A'),
  ('99200000-0000-0000-0000-000000000002', '99100000-0000-0000-0000-000000000001', 'Learning school B', 'TRACK-B');

insert into users (id, school_id, email, password_hash, first_name, last_name, created_by) values
  ('99300000-0000-0000-0000-000000000001', '99200000-0000-0000-0000-000000000001', 'tracks-admin-a@pdpa.test', crypt('x', gen_salt('bf')), 'Admin', 'A', '99300000-0000-0000-0000-000000000001'),
  ('99300000-0000-0000-0000-000000000002', '99200000-0000-0000-0000-000000000001', 'tracks-executive-a@pdpa.test', crypt('x', gen_salt('bf')), 'Executive', 'A', '99300000-0000-0000-0000-000000000001'),
  ('99300000-0000-0000-0000-000000000003', '99200000-0000-0000-0000-000000000001', 'tracks-teacher-a@pdpa.test', crypt('x', gen_salt('bf')), 'Teacher', 'A', '99300000-0000-0000-0000-000000000001'),
  ('99300000-0000-0000-0000-000000000004', '99200000-0000-0000-0000-000000000002', 'tracks-admin-b@pdpa.test', crypt('x', gen_salt('bf')), 'Admin', 'B', '99300000-0000-0000-0000-000000000004'),
  ('99300000-0000-0000-0000-000000000005', '99200000-0000-0000-0000-000000000001', 'tracks-student-a@pdpa.test', crypt('x', gen_salt('bf')), 'Student', 'A', '99300000-0000-0000-0000-000000000001'),
  ('99300000-0000-0000-0000-000000000006', '99200000-0000-0000-0000-000000000002', 'tracks-student-b@pdpa.test', crypt('x', gen_salt('bf')), 'Student', 'B', '99300000-0000-0000-0000-000000000004'),
  ('99300000-0000-0000-0000-000000000007', null, 'tracks-super@pdpa.test', crypt('x', gen_salt('bf')), 'Super', 'Admin', '99300000-0000-0000-0000-000000000001'),
  ('99300000-0000-0000-0000-000000000008', null, 'tracks-null-school@pdpa.test', crypt('x', gen_salt('bf')), 'Null', 'School', '99300000-0000-0000-0000-000000000001');

insert into user_roles (user_id, role, school_id, granted_by) values
  ('99300000-0000-0000-0000-000000000001', 'school_admin', '99200000-0000-0000-0000-000000000001', '99300000-0000-0000-0000-000000000001'),
  ('99300000-0000-0000-0000-000000000002', 'executive', '99200000-0000-0000-0000-000000000001', '99300000-0000-0000-0000-000000000001'),
  ('99300000-0000-0000-0000-000000000003', 'teacher', '99200000-0000-0000-0000-000000000001', '99300000-0000-0000-0000-000000000001'),
  ('99300000-0000-0000-0000-000000000004', 'school_admin', '99200000-0000-0000-0000-000000000002', '99300000-0000-0000-0000-000000000004'),
  ('99300000-0000-0000-0000-000000000005', 'student', '99200000-0000-0000-0000-000000000001', '99300000-0000-0000-0000-000000000001'),
  ('99300000-0000-0000-0000-000000000006', 'student', '99200000-0000-0000-0000-000000000002', '99300000-0000-0000-0000-000000000004'),
  ('99300000-0000-0000-0000-000000000007', 'super_admin', null, '99300000-0000-0000-0000-000000000001');

insert into sessions (user_id, active_role, active_school_id, token_hash, expires_at) values
  ('99300000-0000-0000-0000-000000000001', 'school_admin', '99200000-0000-0000-0000-000000000001', encode(digest('tracks-admin-a-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('99300000-0000-0000-0000-000000000002', 'executive', '99200000-0000-0000-0000-000000000001', encode(digest('tracks-executive-a-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('99300000-0000-0000-0000-000000000003', 'teacher', '99200000-0000-0000-0000-000000000001', encode(digest('tracks-teacher-a-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('99300000-0000-0000-0000-000000000004', 'school_admin', '99200000-0000-0000-0000-000000000002', encode(digest('tracks-admin-b-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('99300000-0000-0000-0000-000000000007', 'super_admin', '99200000-0000-0000-0000-000000000001', encode(digest('tracks-super-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('99300000-0000-0000-0000-000000000008', 'school_admin', null, encode(digest('tracks-null-school-token', 'sha256'), 'hex'), now() + interval '1 hour');

insert into academic_years (id, school_id, name, start_date, end_date) values
  ('99400000-0000-0000-0000-000000000001', '99200000-0000-0000-0000-000000000001', 'current A', current_date - 30, current_date + 30),
  ('99400000-0000-0000-0000-000000000002', '99200000-0000-0000-0000-000000000001', 'old A', current_date - 400, current_date - 300),
  ('99400000-0000-0000-0000-000000000003', '99200000-0000-0000-0000-000000000002', 'current B', current_date - 30, current_date + 30);

insert into student_profiles (student_id, academic_year_id, grade_level, room, created_by) values
  ('99300000-0000-0000-0000-000000000005', '99400000-0000-0000-0000-000000000001', 'ม.1', '1', '99300000-0000-0000-0000-000000000001'),
  ('99300000-0000-0000-0000-000000000005', '99400000-0000-0000-0000-000000000002', 'ม.2', '9', '99300000-0000-0000-0000-000000000001'),
  ('99300000-0000-0000-0000-000000000006', '99400000-0000-0000-0000-000000000003', 'ม.1', '1', '99300000-0000-0000-0000-000000000004');

select is((select count(*)::integer from pg_class where oid in ('public.learning_tracks'::regclass, 'public.learning_track_room_assignments'::regclass) and relrowsecurity), 2, 'both Learning tracks tables have RLS enabled');
select is((select count(*)::integer from pg_policies where schemaname = 'public' and tablename in ('learning_tracks', 'learning_track_room_assignments')), 0, 'Learning tracks tables remain deny-all with no RLS policies');
select is((select count(*)::integer from pg_proc p cross join lateral aclexplode(coalesce(p.proacl, acldefault('f', p.proowner))) a where p.oid = any(array['public.list_learning_tracks(text)'::regprocedure,'public.create_learning_track(text,text,text)'::regprocedure,'public.update_learning_track(text,uuid,text,text,integer)'::regprocedure,'public.delete_learning_track(text,uuid)'::regprocedure,'public.list_learning_track_rooms(text)'::regprocedure,'public.set_learning_track_room(text,text,text,uuid)'::regprocedure,'public.get_learning_track_overview(text)'::regprocedure]) and a.grantee = 0 and a.privilege_type = 'EXECUTE'), 0, 'page RPCs grant no EXECUTE to PUBLIC');
select is((select count(*)::integer from pg_proc p cross join lateral aclexplode(coalesce(p.proacl, acldefault('f', p.proowner))) a where p.oid = any(array['public.list_learning_tracks(text)'::regprocedure,'public.create_learning_track(text,text,text)'::regprocedure,'public.update_learning_track(text,uuid,text,text,integer)'::regprocedure,'public.delete_learning_track(text,uuid)'::regprocedure,'public.list_learning_track_rooms(text)'::regprocedure,'public.set_learning_track_room(text,text,text,uuid)'::regprocedure,'public.get_learning_track_overview(text)'::regprocedure]) and a.grantee = 'anon'::regrole and a.privilege_type = 'EXECUTE'), 7, 'anon can execute exactly the seven Learning tracks RPCs');
select is((select count(*)::integer from pg_proc p cross join lateral aclexplode(coalesce(p.proacl, acldefault('f', p.proowner))) a where p.oid = any(array['public.list_learning_tracks(text)'::regprocedure,'public.create_learning_track(text,text,text)'::regprocedure,'public.update_learning_track(text,uuid,text,text,integer)'::regprocedure,'public.delete_learning_track(text,uuid)'::regprocedure,'public.list_learning_track_rooms(text)'::regprocedure,'public.set_learning_track_room(text,text,text,uuid)'::regprocedure,'public.get_learning_track_overview(text)'::regprocedure]) and a.grantee = 'authenticated'::regrole and a.privilege_type = 'EXECUTE'), 7, 'authenticated can execute exactly the seven Learning tracks RPCs');
select is((select count(*)::integer from pg_proc p cross join lateral aclexplode(coalesce(p.proacl, acldefault('f', p.proowner))) a where p.oid = any(array['public.list_learning_tracks(text)'::regprocedure,'public.create_learning_track(text,text,text)'::regprocedure,'public.update_learning_track(text,uuid,text,text,integer)'::regprocedure,'public.delete_learning_track(text,uuid)'::regprocedure,'public.list_learning_track_rooms(text)'::regprocedure,'public.set_learning_track_room(text,text,text,uuid)'::regprocedure,'public.get_learning_track_overview(text)'::regprocedure]) and a.grantee = 'service_role'::regrole and a.privilege_type = 'EXECUTE'), 0, 'Learning tracks RPCs do not grant unnecessary EXECUTE to service_role');

set local role anon;
select results_eq($$select (select count(*) from learning_tracks)::bigint, (select count(*) from learning_track_room_assignments)::bigint$$, $$values (0::bigint, 0::bigint)$$, 'anon direct reads see no rows through deny-all RLS');
select throws_ok($$insert into learning_tracks (school_id, name, created_by) values ('99200000-0000-0000-0000-000000000001', 'blocked', '99300000-0000-0000-0000-000000000001')$$, '42501', null, 'anon direct track insert is denied by RLS');
select throws_ok($$insert into learning_track_room_assignments (school_id, academic_year_id, grade_level, room, track_id, assigned_by) values ('99200000-0000-0000-0000-000000000001', '99400000-0000-0000-0000-000000000001', 'x', 'x', gen_random_uuid(), '99300000-0000-0000-0000-000000000001')$$, '42501', null, 'anon direct assignment insert is denied by RLS');
reset role;

select throws_ok($$select list_learning_tracks(null)$$, 'P0001', 'invalid_session', 'list rejects a missing token');
select throws_ok($$select list_learning_tracks('invalid-tracks-token')$$, 'P0001', 'invalid_session', 'list rejects an invalid token');
select throws_ok($$select create_learning_track(null, 'x', '#7C3AED')$$, 'P0001', 'invalid_session', 'create rejects a missing token');
select throws_ok($$select create_learning_track('invalid-tracks-token', 'x', '#7C3AED')$$, 'P0001', 'invalid_session', 'create rejects an invalid token');
select throws_ok($$select update_learning_track(null, gen_random_uuid(), 'x', '#7C3AED', 0)$$, 'P0001', 'invalid_session', 'update rejects a missing token');
select throws_ok($$select update_learning_track('invalid-tracks-token', gen_random_uuid(), 'x', '#7C3AED', 0)$$, 'P0001', 'invalid_session', 'update rejects an invalid token');
select throws_ok($$select delete_learning_track(null, gen_random_uuid())$$, 'P0001', 'invalid_session', 'delete rejects a missing token');
select throws_ok($$select delete_learning_track('invalid-tracks-token', gen_random_uuid())$$, 'P0001', 'invalid_session', 'delete rejects an invalid token');
select throws_ok($$select list_learning_track_rooms(null)$$, 'P0001', 'invalid_session', 'room list rejects a missing token');
select throws_ok($$select list_learning_track_rooms('invalid-tracks-token')$$, 'P0001', 'invalid_session', 'room list rejects an invalid token');
select throws_ok($$select set_learning_track_room(null, 'ม.1', '1', null)$$, 'P0001', 'invalid_session', 'room assignment rejects a missing token');
select throws_ok($$select set_learning_track_room('invalid-tracks-token', 'ม.1', '1', null)$$, 'P0001', 'invalid_session', 'room assignment rejects an invalid token');

select throws_ok($$select list_learning_tracks('tracks-teacher-a-token')$$, 'P0001', 'forbidden', 'teacher cannot list tracks');
select throws_ok($$select create_learning_track('tracks-teacher-a-token', 'x', '#7C3AED')$$, 'P0001', 'forbidden', 'teacher cannot create tracks');
select throws_ok($$select update_learning_track('tracks-teacher-a-token', gen_random_uuid(), 'x', '#7C3AED', 0)$$, 'P0001', 'forbidden', 'teacher cannot update tracks');
select throws_ok($$select delete_learning_track('tracks-teacher-a-token', gen_random_uuid())$$, 'P0001', 'forbidden', 'teacher cannot delete tracks');
select throws_ok($$select list_learning_track_rooms('tracks-teacher-a-token')$$, 'P0001', 'forbidden', 'teacher cannot list track rooms');
select throws_ok($$select set_learning_track_room('tracks-teacher-a-token', 'ม.1', '1', null)$$, 'P0001', 'forbidden', 'teacher cannot assign rooms');
select throws_ok($$select create_learning_track('tracks-executive-a-token', 'x', '#7C3AED')$$, 'P0001', 'forbidden', 'executive cannot create tracks (read-only widening only)');
select throws_ok($$select create_learning_track('tracks-super-token', 'x', '#7C3AED')$$, 'P0001', 'forbidden', 'super admin cannot create tracks (read-only widening only)');
select throws_ok($$select list_learning_track_rooms('tracks-executive-a-token')$$, 'P0001', 'forbidden', 'executive cannot list track rooms (room list is school_admin-only)');
select throws_ok($$select list_learning_track_rooms('tracks-super-token')$$, 'P0001', 'forbidden', 'super admin cannot list track rooms (room list is school_admin-only)');

select is((select count(*)::integer from list_learning_tracks('tracks-null-school-token')), 0, 'null active school list fails closed with no rows');
select is((select count(*)::integer from list_learning_track_rooms('tracks-null-school-token')), 0, 'null active school room list fails closed with no rows');
select is((select count(*)::integer from list_learning_tracks('tracks-executive-a-token')), 0, 'executive exact active-school read begins empty');
select is((select count(*)::integer from list_learning_tracks('tracks-super-token')), 0, 'super admin exact active-school read begins empty without widening');
select throws_ok($$select create_learning_track('tracks-admin-a-token', '   ', '#7C3AED')$$, 'P0001', 'name_required', 'create rejects a blank name');

create temporary table created_a as select create_learning_track('tracks-admin-a-token', 'วิทย์-คณิต', '#7C3AED') as id;
select results_eq(
  $$select school_id::text, name::text, color::text, sort_order, created_by::text from learning_tracks where id = (select id from created_a)$$,
  $$values ('99200000-0000-0000-0000-000000000001'::text, 'วิทย์-คณิต'::text, '#7C3AED'::text, 0, '99300000-0000-0000-0000-000000000001'::text)$$,
  'create writes trimmed canonical fields in the actor school with actor creator'
);
create temporary table created_a_second as select create_learning_track('tracks-admin-a-token', 'สายภาษา', '#0284C7') as id;
select is((select sort_order from learning_tracks where id = (select id from created_a_second)), 1, 'create assigns the next school-local sort order');
select throws_ok($$select create_learning_track('tracks-admin-a-token', 'วิทย์-คณิต', '#7C3AED')$$, '23505', null, 'duplicate name in the same school is rejected');
create temporary table created_b as select create_learning_track('tracks-admin-b-token', 'วิทย์-คณิต', '#7C3AED') as id;
select ok((select id is not null from created_b), 'the same track name is isolated and allowed in another school');
select results_eq($$select (select count(*) from list_learning_tracks('tracks-admin-a-token'))::integer, (select count(*) from list_learning_tracks('tracks-admin-b-token'))::integer$$, $$values (2, 1)$$, 'track lists are isolated to each active school');

select throws_ok($$select update_learning_track('tracks-admin-a-token', (select id from created_b), 'hacked', '#DC2626', 9)$$, 'P0001', 'track_not_found', 'cross-school update is denied');
select is((select name::text from learning_tracks where id = (select id from created_b)), 'วิทย์-คณิต', 'cross-school update leaves the other-school row unchanged');
select throws_ok($$select delete_learning_track('tracks-admin-a-token', (select id from created_b))$$, 'P0001', 'track_not_found', 'cross-school delete is denied');
select ok(exists(select 1 from learning_tracks where id = (select id from created_b)), 'cross-school delete leaves the other-school row unchanged');

select update_learning_track('tracks-admin-a-token', (select id from created_a), 'วิทย์แก้ไข', '#059669', 4);
select results_eq($$select name::text, color::text, sort_order from learning_tracks where id = (select id from created_a)$$, $$values ('วิทย์แก้ไข'::text, '#059669'::text, 4)$$, 'update changes exactly name, color, and sort order');
select results_eq($$select grade_level::text, room::text, student_count from list_learning_track_rooms('tracks-admin-a-token')$$, $$values ('ม.1'::text, '1'::text, 1::bigint)$$, 'room list uses real students from the current academic year only');

select lives_ok($$select set_learning_track_room('tracks-admin-a-token', 'ม.1', '1', (select id from created_a))$$, 'school admin can assign a same-school track to a real current-year room');
select results_eq($$select grade_level::text, room::text, student_count, track_id::text, track_name::text from list_learning_track_rooms('tracks-admin-a-token')$$, $$values ('ม.1'::text, '1'::text, 1::bigint, (select id::text from created_a), 'วิทย์แก้ไข'::text)$$, 'canonical room refetch returns the assignment and real count');
select throws_ok($$select set_learning_track_room('tracks-admin-a-token', 'ม.1', '1', (select id from created_b))$$, 'P0001', 'track_not_found', 'room assignment rejects a cross-school track');
select lives_ok($$select set_learning_track_room('tracks-admin-a-token', 'ม.1', '1', null)$$, 'school admin can clear a room assignment');
select is((select count(*)::integer from learning_track_room_assignments where academic_year_id = '99400000-0000-0000-0000-000000000001' and grade_level = 'ม.1' and room = '1'), 0, 'clear removes the canonical room assignment');

select throws_ok($$select create_learning_track('tracks-null-school-token', 'x', '#7C3AED')$$, '23502', null, 'create fails closed when the active school is null');
select throws_ok($$select update_learning_track('tracks-null-school-token', (select id from created_a), 'hacked', '#DC2626', 9)$$, 'P0001', 'track_not_found', 'update fails closed when the active school is null');
select throws_ok($$select delete_learning_track('tracks-null-school-token', (select id from created_a))$$, 'P0001', 'track_not_found', 'delete fails closed when the active school is null');
select throws_ok($$select set_learning_track_room('tracks-null-school-token', 'ม.1', '1', null)$$, 'P0001', 'no_academic_year', 'room assignment fails closed when the active school is null');

select set_learning_track_room('tracks-admin-a-token', 'ม.1', '1', (select id from created_a));
select lives_ok($$select delete_learning_track('tracks-admin-a-token', (select id from created_a))$$, 'school admin can delete an own-school track');
select is((select count(*)::integer from learning_track_room_assignments where track_id = (select id from created_a)), 0, 'track delete cascades its room assignments');

select * from finish();
rollback;
