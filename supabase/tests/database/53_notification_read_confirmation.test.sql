begin;

create extension if not exists pgtap with schema extensions;
select no_plan();

insert into packages (id, name, license_type)
values ('99820000-0000-0000-0000-000000000001', 'Meetings test package', 'perpetual');

insert into schools (id, package_id, name, school_code) values
  ('99821000-0000-0000-0000-000000000001', '99820000-0000-0000-0000-000000000001', 'Meeting School A', 'MTG-A'),
  ('99821000-0000-0000-0000-000000000002', '99820000-0000-0000-0000-000000000001', 'Meeting School B', 'MTG-B');

insert into users (
  id, school_id, email, password_hash, first_name, last_name, created_by
) values
  ('99822000-0000-0000-0000-000000000001', '99821000-0000-0000-0000-000000000001',
   'mtg-exec@test.local', crypt('pass', gen_salt('bf')), 'Mtg', 'Exec', '99822000-0000-0000-0000-000000000001'),
  ('99822000-0000-0000-0000-000000000002', '99821000-0000-0000-0000-000000000001',
   'mtg-admin@test.local', crypt('pass', gen_salt('bf')), 'Mtg', 'Admin', '99822000-0000-0000-0000-000000000001'),
  -- The one-on-one's subject, and a department member.
  ('99822000-0000-0000-0000-000000000003', '99821000-0000-0000-0000-000000000001',
   'mtg-teacher1@test.local', crypt('pass', gen_salt('bf')), 'Mtg', 'Teacher1', '99822000-0000-0000-0000-000000000001'),
  -- Second department member.
  ('99822000-0000-0000-0000-000000000004', '99821000-0000-0000-0000-000000000001',
   'mtg-teacher2@test.local', crypt('pass', gen_salt('bf')), 'Mtg', 'Teacher2', '99822000-0000-0000-0000-000000000001'),
  -- In neither department nor invited to the group meeting: the outsider.
  ('99822000-0000-0000-0000-000000000005', '99821000-0000-0000-0000-000000000001',
   'mtg-teacher3@test.local', crypt('pass', gen_salt('bf')), 'Mtg', 'Teacher3', '99822000-0000-0000-0000-000000000001'),
  ('99822000-0000-0000-0000-000000000006', '99821000-0000-0000-0000-000000000001',
   'mtg-student@test.local', crypt('pass', gen_salt('bf')), 'Mtg', 'Student', '99822000-0000-0000-0000-000000000001'),
  -- School B: exists only to prove tenant isolation, never a party to
  -- anything created in School A below.
  ('99822000-0000-0000-0000-000000000007', '99821000-0000-0000-0000-000000000002',
   'mtg-execb@test.local', crypt('pass', gen_salt('bf')), 'Mtg', 'ExecB', '99822000-0000-0000-0000-000000000007');

insert into user_roles (user_id, role, school_id, granted_by) values
  ('99822000-0000-0000-0000-000000000001', 'executive',    '99821000-0000-0000-0000-000000000001', '99822000-0000-0000-0000-000000000001'),
  ('99822000-0000-0000-0000-000000000002', 'school_admin', '99821000-0000-0000-0000-000000000001', '99822000-0000-0000-0000-000000000001'),
  ('99822000-0000-0000-0000-000000000003', 'teacher',      '99821000-0000-0000-0000-000000000001', '99822000-0000-0000-0000-000000000001'),
  ('99822000-0000-0000-0000-000000000004', 'teacher',      '99821000-0000-0000-0000-000000000001', '99822000-0000-0000-0000-000000000001'),
  ('99822000-0000-0000-0000-000000000005', 'teacher',      '99821000-0000-0000-0000-000000000001', '99822000-0000-0000-0000-000000000001'),
  ('99822000-0000-0000-0000-000000000006', 'student',      '99821000-0000-0000-0000-000000000001', '99822000-0000-0000-0000-000000000001'),
  ('99822000-0000-0000-0000-000000000007', 'executive',    '99821000-0000-0000-0000-000000000002', '99822000-0000-0000-0000-000000000007');

insert into sessions (user_id, active_role, active_school_id, token_hash, expires_at) values
  ('99822000-0000-0000-0000-000000000001', 'executive', '99821000-0000-0000-0000-000000000001',
   encode(digest('mtg-exec-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('99822000-0000-0000-0000-000000000002', 'school_admin', '99821000-0000-0000-0000-000000000001',
   encode(digest('mtg-admin-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('99822000-0000-0000-0000-000000000003', 'teacher', '99821000-0000-0000-0000-000000000001',
   encode(digest('mtg-teacher1-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('99822000-0000-0000-0000-000000000004', 'teacher', '99821000-0000-0000-0000-000000000001',
   encode(digest('mtg-teacher2-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('99822000-0000-0000-0000-000000000005', 'teacher', '99821000-0000-0000-0000-000000000001',
   encode(digest('mtg-teacher3-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('99822000-0000-0000-0000-000000000006', 'student', '99821000-0000-0000-0000-000000000001',
   encode(digest('mtg-student-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('99822000-0000-0000-0000-000000000007', 'executive', '99821000-0000-0000-0000-000000000002',
   encode(digest('mtg-execb-token', 'sha256'), 'hex'), now() + interval '1 hour');


insert into notifications(user_id,type,title)
select '99822000-0000-0000-0000-000000000001','meeting_invited','Inbox test ' || n from generate_series(1,120) n;
insert into notifications(id,user_id,type,title) values
('99829000-0000-0000-0000-000000000001','99822000-0000-0000-0000-000000000003','meeting_invited','Other user'),
('99829000-0000-0000-0000-000000000002','99822000-0000-0000-0000-000000000007','meeting_invited','Other school');
select throws_ok($$select mark_all_my_notifications_read('invalid')$$,'P0001','invalid_session','invalid token rejected');
select is(get_my_notification('mtg-exec-token','99829000-0000-0000-0000-000000000001'),null::jsonb,'cannot read another user');
select is(get_my_notification('mtg-exec-token','99829000-0000-0000-0000-000000000002'),null::jsonb,'cannot read another school user');
select mark_notification_read('mtg-exec-token',(select id from notifications where user_id='99822000-0000-0000-0000-000000000001' limit 1));
select ok((select get_my_notification('mtg-exec-token',id)->>'read_at' is not null from notifications where user_id='99822000-0000-0000-0000-000000000001' and read_at is not null limit 1),'exact read confirms persisted state');
select mark_all_my_notifications_read('mtg-exec-token');
select is((select count(*)::int from notifications where user_id='99822000-0000-0000-0000-000000000001' and read_at is null),0,'bulk covers more than list limit');
select is((select count(*)::int from notifications where user_id in ('99822000-0000-0000-0000-000000000003','99822000-0000-0000-0000-000000000007') and read_at is null),2,'bulk leaves other users and schools unchanged');
select lives_ok($$select mark_all_my_notifications_read('mtg-exec-token')$$,'bulk is idempotent');
select is((select sum(unread)::int from list_my_notification_categories('mtg-exec-token')),0,'canonical categories confirm all read');
select * from finish();
rollback;

