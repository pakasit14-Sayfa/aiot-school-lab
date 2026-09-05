begin;

create extension if not exists pgtap with schema extensions;
select plan(50);

insert into packages (id, name, license_type)
values ('98100000-0000-0000-0000-000000000001', 'Incident inbox test package', 'perpetual');

insert into schools (id, package_id, name, school_code) values
  ('98200000-0000-0000-0000-000000000001', '98100000-0000-0000-0000-000000000001', 'Incident inbox school A', 'INBOX-A'),
  ('98200000-0000-0000-0000-000000000002', '98100000-0000-0000-0000-000000000001', 'Incident inbox school B', 'INBOX-B');

insert into users (
  id, school_id, email, password_hash, first_name, last_name, created_by
) values
  ('98300000-0000-0000-0000-000000000001', '98200000-0000-0000-0000-000000000001',
   'inbox-admin-a@pdpa.test', crypt('irrelevant', gen_salt('bf')), 'Admin', 'A',
   '98300000-0000-0000-0000-000000000001'),
  ('98300000-0000-0000-0000-000000000002', '98200000-0000-0000-0000-000000000001',
   'inbox-executive-a@pdpa.test', crypt('irrelevant', gen_salt('bf')), 'Executive', 'A',
   '98300000-0000-0000-0000-000000000001'),
  ('98300000-0000-0000-0000-000000000003', '98200000-0000-0000-0000-000000000001',
   'inbox-student-a@pdpa.test', crypt('irrelevant', gen_salt('bf')), 'Student', 'A',
   '98300000-0000-0000-0000-000000000001'),
  ('98300000-0000-0000-0000-000000000004', '98200000-0000-0000-0000-000000000002',
   'inbox-admin-b@pdpa.test', crypt('irrelevant', gen_salt('bf')), 'Admin', 'B',
   '98300000-0000-0000-0000-000000000004'),
  ('98300000-0000-0000-0000-000000000005', '98200000-0000-0000-0000-000000000002',
   'inbox-student-b@pdpa.test', crypt('irrelevant', gen_salt('bf')), 'Student', 'B',
   '98300000-0000-0000-0000-000000000004'),
  ('98300000-0000-0000-0000-000000000006', '98200000-0000-0000-0000-000000000001',
   'inbox-teacher-a@pdpa.test', crypt('irrelevant', gen_salt('bf')), 'Teacher', 'A',
   '98300000-0000-0000-0000-000000000001'),
  ('98300000-0000-0000-0000-000000000007', null,
   'inbox-super-admin@pdpa.test', crypt('irrelevant', gen_salt('bf')), 'Super', 'Admin',
   '98300000-0000-0000-0000-000000000001');

insert into user_roles (user_id, role, school_id, granted_by) values
  ('98300000-0000-0000-0000-000000000001', 'school_admin', '98200000-0000-0000-0000-000000000001', '98300000-0000-0000-0000-000000000001'),
  ('98300000-0000-0000-0000-000000000002', 'executive', '98200000-0000-0000-0000-000000000001', '98300000-0000-0000-0000-000000000001'),
  ('98300000-0000-0000-0000-000000000003', 'student', '98200000-0000-0000-0000-000000000001', '98300000-0000-0000-0000-000000000001'),
  ('98300000-0000-0000-0000-000000000004', 'school_admin', '98200000-0000-0000-0000-000000000002', '98300000-0000-0000-0000-000000000004'),
  ('98300000-0000-0000-0000-000000000005', 'student', '98200000-0000-0000-0000-000000000002', '98300000-0000-0000-0000-000000000004'),
  ('98300000-0000-0000-0000-000000000006', 'teacher', '98200000-0000-0000-0000-000000000001', '98300000-0000-0000-0000-000000000001'),
  ('98300000-0000-0000-0000-000000000007', 'super_admin', null, '98300000-0000-0000-0000-000000000001');

insert into sessions (user_id, active_role, active_school_id, token_hash, expires_at) values
  ('98300000-0000-0000-0000-000000000001', 'school_admin', '98200000-0000-0000-0000-000000000001', encode(digest('inbox-admin-a-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('98300000-0000-0000-0000-000000000002', 'executive', '98200000-0000-0000-0000-000000000001', encode(digest('inbox-executive-a-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('98300000-0000-0000-0000-000000000003', 'student', '98200000-0000-0000-0000-000000000001', encode(digest('inbox-student-a-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('98300000-0000-0000-0000-000000000004', 'school_admin', '98200000-0000-0000-0000-000000000002', encode(digest('inbox-admin-b-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('98300000-0000-0000-0000-000000000005', 'student', '98200000-0000-0000-0000-000000000002', encode(digest('inbox-student-b-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('98300000-0000-0000-0000-000000000006', 'teacher', '98200000-0000-0000-0000-000000000001', encode(digest('inbox-teacher-a-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('98300000-0000-0000-0000-000000000007', 'super_admin', null, encode(digest('inbox-super-admin-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('98300000-0000-0000-0000-000000000001', 'school_admin', null, encode(digest('inbox-null-school-token', 'sha256'), 'hex'), now() + interval '1 hour');

create temporary table regular_incident as
select * from create_incident_report(
  'inbox-student-a-token', 'anomaly', 'A-101', 'ประตูชำรุด', 'medium'
);

create temporary table escalated_incident as
select * from create_incident_report(
  'inbox-student-a-token', 'sos', 'A-102', 'นักเรียนหมดสติ', 'high'
);

create temporary table other_school_incident as
select * from create_incident_report(
  'inbox-student-b-token', 'anomaly', 'B-201', 'พื้นเปียก', 'low'
);

select has_function(
  'public',
  'get_incident_report_for_staff',
  array['text', 'uuid'],
  'staff-facing incident detail RPC exists'
);

select is(
  (select count(*)::integer from list_incident_reports('inbox-admin-a-token', null)),
  2,
  'school admin inbox contains only incidents from the active school'
);

select results_eq(
  $$
    select room::text, reason, severity
    from get_incident_report_for_staff(
      'inbox-admin-a-token',
      (select incident_id from regular_incident)
    )
  $$,
  $$values ('A-101'::text, 'ประตูชำรุด'::text, 'medium'::text)$$,
  'school admin receives canonical incident detail fields'
);

select is(
  (
    select count(*)::integer
    from get_incident_report_for_staff(
      'inbox-executive-a-token',
      (select incident_id from regular_incident)
    )
  ),
  1,
  'executive in the same school can read incident detail'
);

select is(
  (
    select count(*)::integer
    from get_incident_report_for_staff(
      'inbox-teacher-a-token',
      (select incident_id from regular_incident)
    )
  ),
  1,
  'teacher in the same school can read incident detail'
);

select throws_ok(
  $$
    select get_incident_report_for_staff(
      'inbox-super-admin-token',
      (select incident_id from regular_incident)
    )
  $$,
  'P0001', 'forbidden',
  'super admin is not widened into the staff detail RPC'
);

select throws_ok(
  $$
    select get_incident_report_for_staff(
      'inbox-null-school-token',
      (select incident_id from regular_incident)
    )
  $$,
  'P0001', 'not_found',
  'staff detail fails closed when the active school is null'
);

select throws_ok(
  $$select list_incident_reports('inbox-super-admin-token', null)$$,
  'P0001', 'forbidden',
  'super admin is not widened into the incident inbox list'
);

select is(
  (
    select count(*)::integer
    from list_incident_reports('inbox-null-school-token', null)
  ),
  0,
  'incident list exposes no data when the active school is null'
);

select throws_ok(
  $$select list_incident_reports('invalid-inbox-token', null)$$,
  'P0001', 'invalid_session',
  'incident list rejects an invalid session'
);

select throws_ok(
  $$select list_incident_reports(null, null)$$,
  'P0001', 'invalid_session',
  'incident list rejects a missing session token'
);

select throws_ok(
  $$
    select get_incident_report_for_staff(
      'inbox-student-a-token',
      (select incident_id from regular_incident)
    )
  $$,
  'P0001', 'forbidden',
  'student cannot call the staff detail RPC'
);

select throws_ok(
  $$
    select get_incident_report_for_staff(
      'inbox-admin-b-token',
      (select incident_id from regular_incident)
    )
  $$,
  'P0001', 'not_found',
  'staff from another school cannot read incident detail'
);

select throws_ok(
  $$
    select get_incident_report_for_staff(
      'invalid-inbox-token',
      (select incident_id from regular_incident)
    )
  $$,
  'P0001', 'invalid_session',
  'invalid session is rejected by the staff detail RPC'
);

select throws_ok(
  $$
    select get_incident_report_for_staff(
      null,
      (select incident_id from regular_incident)
    )
  $$,
  'P0001', 'invalid_session',
  'staff detail rejects a missing session token'
);

select lives_ok(
  $$
    select acknowledge_incident_report(
      'inbox-admin-a-token',
      (select incident_id from regular_incident)
    )
  $$,
  'school admin can acknowledge an incident in their school'
);

select is(
  (
    select status::text
    from get_incident_report_for_staff(
      'inbox-admin-a-token',
      (select incident_id from regular_incident)
    )
  ),
  'acknowledged',
  'acknowledge is visible in a canonical refetch'
);

select throws_ok(
  $$select acknowledge_incident_report('inbox-admin-b-token', (select incident_id from regular_incident))$$,
  'P0001', 'not_found',
  'staff cannot acknowledge an incident from another school'
);

select throws_ok(
  $$select acknowledge_incident_report('inbox-student-a-token', (select incident_id from regular_incident))$$,
  'P0001', 'forbidden',
  'student cannot acknowledge an incident'
);

select throws_ok(
  $$select acknowledge_incident_report('invalid-inbox-token', (select incident_id from regular_incident))$$,
  'P0001', 'invalid_session',
  'acknowledge rejects an invalid session'
);

select throws_ok(
  $$select acknowledge_incident_report(null, (select incident_id from regular_incident))$$,
  'P0001', 'invalid_session',
  'acknowledge rejects a missing session token'
);

select throws_ok(
  $$select acknowledge_incident_report('inbox-super-admin-token', (select incident_id from regular_incident))$$,
  'P0001', 'forbidden',
  'super admin is not widened into acknowledge'
);

select throws_ok(
  $$select acknowledge_incident_report('inbox-null-school-token', (select incident_id from other_school_incident))$$,
  'P0001', 'not_found',
  'acknowledge fails closed when the active school is null'
);

select is(
  (
    select status::text from incident_reports
    where id = (select incident_id from other_school_incident)
  ),
  'new',
  'acknowledge with a null active school leaves incident status unchanged'
);

select is(
  (
    select count(*)::integer from incident_actions
    where incident_report_id = (select incident_id from other_school_incident)
  ),
  0,
  'acknowledge with a null active school writes no incident action'
);

select is(
  (
    select count(*)::integer from audit_logs
    where action = 'incident.acknowledge'
      and entity_id = (select incident_id::text from other_school_incident)
  ),
  0,
  'acknowledge with a null active school writes no audit log'
);

select is(
  (
    select count(*)::integer from incident_actions
    where incident_report_id = (select incident_id from regular_incident)
      and note = 'acknowledged'
  ),
  1,
  'acknowledge writes one incident action'
);

select is(
  (
    select count(*)::integer from audit_logs
    where action = 'incident.acknowledge'
      and entity_id = (select incident_id::text from regular_incident)
  ),
  1,
  'acknowledge writes one audit log'
);

select throws_ok(
  $$
    select acknowledge_incident_report(
      'inbox-admin-a-token',
      (select incident_id from regular_incident)
    )
  $$,
  'P0001', 'already_acknowledged',
  'a repeated acknowledge is rejected truthfully'
);

select lives_ok(
  $$
    select close_incident_report(
      'inbox-admin-a-token',
      (select incident_id from regular_incident),
      'resolved',
      'ซ่อมประตูเรียบร้อย'
    )
  $$,
  'school admin can close a regular incident'
);

select results_eq(
  $$
    select status::text, resolution_note
    from get_incident_report_for_staff(
      'inbox-admin-a-token',
      (select incident_id from regular_incident)
    )
  $$,
  $$values ('resolved'::text, 'ซ่อมประตูเรียบร้อย'::text)$$,
  'regular close is visible in a canonical refetch'
);

select is(
  (
    select count(*)::integer from incident_actions
    where incident_report_id = (select incident_id from regular_incident)
      and note = 'closed: resolved'
  ),
  1,
  'regular close writes one incident action'
);

select is(
  (
    select count(*)::integer from audit_logs
    where action = 'incident.close'
      and entity_id = (select incident_id::text from regular_incident)
  ),
  1,
  'regular close writes one audit log'
);

select throws_ok(
  $$select close_incident_report('inbox-admin-b-token', (select incident_id from regular_incident), 'resolved', 'wrong school')$$,
  'P0001', 'not_found',
  'staff cannot close an incident from another school'
);

select throws_ok(
  $$select close_incident_report('inbox-student-a-token', (select incident_id from regular_incident), 'resolved', 'wrong role')$$,
  'P0001', 'forbidden',
  'student cannot close an incident'
);

select throws_ok(
  $$select close_incident_report('invalid-inbox-token', (select incident_id from regular_incident), 'resolved', 'invalid session')$$,
  'P0001', 'invalid_session',
  'close rejects an invalid session'
);

select throws_ok(
  $$select close_incident_report(null, (select incident_id from regular_incident), 'resolved', 'missing token')$$,
  'P0001', 'invalid_session',
  'close rejects a missing session token'
);

select throws_ok(
  $$select close_incident_report('inbox-super-admin-token', (select incident_id from regular_incident), 'resolved', 'not widened')$$,
  'P0001', 'forbidden',
  'super admin is not widened into close'
);

select throws_ok(
  $$select close_incident_report('inbox-null-school-token', (select incident_id from other_school_incident), 'resolved', 'null active school')$$,
  'P0001', 'not_found',
  'close fails closed when the active school is null'
);

select is(
  (
    select status::text from incident_reports
    where id = (select incident_id from other_school_incident)
  ),
  'new',
  'close with a null active school leaves incident status unchanged'
);

select is(
  (
    select count(*)::integer from incident_actions
    where incident_report_id = (select incident_id from other_school_incident)
  ),
  0,
  'close with a null active school writes no incident action'
);

select is(
  (
    select count(*)::integer from audit_logs
    where action = 'incident.close'
      and entity_id = (select incident_id::text from other_school_incident)
  ),
  0,
  'close with a null active school writes no audit log'
);

select throws_ok(
  $$
    select close_incident_report(
      'inbox-admin-a-token',
      (select incident_id from regular_incident),
      'resolved',
      'ปิดซ้ำ'
    )
  $$,
  'P0001', 'incident_already_closed',
  'a repeated close is rejected truthfully'
);

select escalate_incident_report(
  'inbox-admin-a-token',
  (select incident_id from escalated_incident)
);

select lives_ok(
  $$
    select close_incident_report(
      'inbox-admin-a-token',
      (select incident_id from escalated_incident),
      'resolved',
      'ส่งนักเรียนถึงห้องพยาบาลแล้ว'
    )
  $$,
  'school admin can close an escalated incident'
);

select is(
  (
    select ee.status::text
    from incident_reports ir
    join emergency_events ee on ee.id = ir.escalated_to_emergency_event_id
    where ir.id = (select incident_id from escalated_incident)
  ),
  'closed',
  'closing an escalated incident closes the linked emergency event'
);

select is(
  (
    select status::text from incident_reports
    where id = (select incident_id from escalated_incident)
  ),
  'resolved',
  'closing an escalated incident resolves the incident report'
);

select is(
  (
    select count(*)::integer from incident_actions
    where incident_report_id = (select incident_id from escalated_incident)
      and note = 'closed: resolved'
  ),
  1,
  'escalated close writes one incident action'
);

select is(
  (
    select count(*)::integer from audit_logs
    where action = 'incident.close'
      and entity_id = (select incident_id::text from escalated_incident)
      and details ->> 'closed_via_emergency' = 'true'
  ),
  1,
  'escalated close writes one audit log'
);

select is(
  (
    select count(*)::integer
    from pg_proc p
    cross join lateral aclexplode(
      coalesce(p.proacl, acldefault('f', p.proowner))
    ) acl
    where p.oid = any(array[
      'public.list_incident_reports(text,incident_status)'::regprocedure,
      'public.get_incident_report(text,uuid)'::regprocedure,
      'public.get_incident_report_for_staff(text,uuid)'::regprocedure,
      'public.acknowledge_incident_report(text,uuid)'::regprocedure,
      'public.close_incident_report(text,uuid,incident_resolution_type,text)'::regprocedure
    ])
      and acl.grantee = 0
      and acl.privilege_type = 'EXECUTE'
  ),
  0,
  'incident inbox RPCs do not grant EXECUTE to PUBLIC'
);

select is(
  (
    select count(*)::integer
    from pg_proc p
    cross join lateral aclexplode(
      coalesce(p.proacl, acldefault('f', p.proowner))
    ) acl
    where p.oid = any(array[
      'public.list_incident_reports(text,incident_status)'::regprocedure,
      'public.get_incident_report(text,uuid)'::regprocedure,
      'public.get_incident_report_for_staff(text,uuid)'::regprocedure,
      'public.acknowledge_incident_report(text,uuid)'::regprocedure,
      'public.close_incident_report(text,uuid,incident_resolution_type,text)'::regprocedure
    ])
      and acl.grantee = 'service_role'::regrole
      and acl.privilege_type = 'EXECUTE'
  ),
  0,
  'incident inbox RPCs do not grant EXECUTE to service_role'
);

select * from finish();
rollback;
