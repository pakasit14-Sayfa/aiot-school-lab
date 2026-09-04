begin;

create extension if not exists pgtap with schema extensions;
select plan(13);

insert into packages (id, name, license_type)
values ('99100000-0000-0000-0000-000000000001', 'Incident test package', 'perpetual');

insert into schools (id, package_id, name, school_code) values
  ('99200000-0000-0000-0000-000000000001', '99100000-0000-0000-0000-000000000001', 'Incident school A', 'INC-A');

insert into academic_years (id, school_id, name)
values ('99300000-0000-0000-0000-000000000001', '99200000-0000-0000-0000-000000000001', '2026');

insert into terms (id, academic_year_id, name)
values ('99400000-0000-0000-0000-000000000001', '99300000-0000-0000-0000-000000000001', 'Term 1/2026');

insert into users (
  id, school_id, email, password_hash, first_name, last_name, created_by
) values
  ('99500000-0000-0000-0000-000000000001', '99200000-0000-0000-0000-000000000001',
   'inc-teacher-scope@pdpa.test', crypt('irrelevant', gen_salt('bf')), 'Teacher', 'InScope',
   '99500000-0000-0000-0000-000000000001'),
  ('99500000-0000-0000-0000-000000000002', '99200000-0000-0000-0000-000000000001',
   'inc-teacher-outscope@pdpa.test', crypt('irrelevant', gen_salt('bf')), 'Teacher', 'OutScope',
   '99500000-0000-0000-0000-000000000001'),
  ('99500000-0000-0000-0000-000000000003', '99200000-0000-0000-0000-000000000001',
   'inc-student-a@pdpa.test', crypt('irrelevant', gen_salt('bf')), 'Student', 'A',
   '99500000-0000-0000-0000-000000000001'),
  ('99500000-0000-0000-0000-000000000004', '99200000-0000-0000-0000-000000000001',
   'inc-student-b@pdpa.test', crypt('irrelevant', gen_salt('bf')), 'Student', 'B',
   '99500000-0000-0000-0000-000000000001');

insert into user_roles (user_id, role, school_id, granted_by) values
  ('99500000-0000-0000-0000-000000000001', 'teacher', '99200000-0000-0000-0000-000000000001', '99500000-0000-0000-0000-000000000001'),
  ('99500000-0000-0000-0000-000000000002', 'teacher', '99200000-0000-0000-0000-000000000001', '99500000-0000-0000-0000-000000000001'),
  ('99500000-0000-0000-0000-000000000003', 'student', '99200000-0000-0000-0000-000000000001', '99500000-0000-0000-0000-000000000001'),
  ('99500000-0000-0000-0000-000000000004', 'student', '99200000-0000-0000-0000-000000000001', '99500000-0000-0000-0000-000000000001');

insert into sessions (user_id, active_role, active_school_id, token_hash, expires_at) values
  ('99500000-0000-0000-0000-000000000001', 'teacher', '99200000-0000-0000-0000-000000000001',
   encode(digest('inc-teacher-scope-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('99500000-0000-0000-0000-000000000002', 'teacher', '99200000-0000-0000-0000-000000000001',
   encode(digest('inc-teacher-outscope-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('99500000-0000-0000-0000-000000000003', 'student', '99200000-0000-0000-0000-000000000001',
   encode(digest('inc-student-a-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('99500000-0000-0000-0000-000000000004', 'student', '99200000-0000-0000-0000-000000000001',
   encode(digest('inc-student-b-token', 'sha256'), 'hex'), now() + interval '1 hour');

create temporary table created_course as
select * from create_course(
  'inc-teacher-scope-token', '99400000-0000-0000-0000-000000000001',
  'Incident Science', 'M.5', 'Room 502', 'วิชาทดสอบแจ้งเหตุ'
);

select enroll_student(
  'inc-teacher-scope-token',
  (select course_id from created_course),
  '99500000-0000-0000-0000-000000000003'
);

insert into student_profiles (student_id, academic_year_id, grade_level, room, created_by)
values ('99500000-0000-0000-0000-000000000003', '99300000-0000-0000-0000-000000000001', 'ม.5', 'ม.5/2', '99500000-0000-0000-0000-000000000001');

-- 1. student A's room is resolved from student_profiles
select is(
  (select room from get_my_student_room('inc-student-a-token')),
  'ม.5/2',
  'the student''s real homeroom is resolved from student_profiles'
);

-- 2. student A creates an SOS incident report
create temporary table created_incident as
select * from create_incident_report('inc-student-a-token', 'sos');

select is(
  (select count(*)::integer from created_incident where incident_id is not null),
  1,
  'student can create an incident report'
);

-- 3. student B (unrelated) sees zero of student A's reports
select is(
  (select count(*)::integer from list_my_incident_reports('inc-student-b-token')),
  0,
  'another student cannot see the first student''s incident reports'
);

-- 4. a student cannot call the teacher/admin inbox RPC at all
select throws_ok(
  $$select list_incident_reports('inc-student-a-token', null)$$,
  'P0001', 'forbidden',
  'a student cannot call list_incident_reports'
);

-- 5. broadcast policy lets every teacher in the school see the incident
select is(
  (select count(*)::integer from list_incident_reports('inc-teacher-outscope-token', null)),
  1,
  'every teacher in the school sees the broadcast incident'
);

-- 6. the in-scope teacher sees the report
select is(
  (select count(*)::integer from list_incident_reports('inc-teacher-scope-token', null)),
  1,
  'a teacher in the room scope sees the incident report'
);

-- 7. any teacher in the school can acknowledge the broadcast incident
select lives_ok(
  $$select acknowledge_incident_report('inc-teacher-outscope-token', (select incident_id from created_incident))$$,
  'any teacher in the school can acknowledge the broadcast incident'
);

-- 8. the acknowledgement is persisted
select is(
  (select status from list_my_incident_reports('inc-student-a-token') limit 1),
  'acknowledged',
  'the report status becomes acknowledged'
);

-- 9. acknowledging again fails — optimistic lock, only the first caller wins
select throws_ok(
  $$select acknowledge_incident_report('inc-teacher-scope-token', (select incident_id from created_incident))$$,
  'P0001', 'already_acknowledged',
  'a second acknowledge attempt is rejected'
);

-- 10. the reporting student cannot escalate their own report
select throws_ok(
  $$select escalate_incident_report('inc-student-a-token', (select incident_id from created_incident))$$,
  'P0001', 'forbidden',
  'a student cannot escalate an incident report'
);

-- 11. the in-scope teacher escalates — creates a real emergency_events row
select escalate_incident_report('inc-teacher-scope-token', (select incident_id from created_incident));
select is(
  (select count(*)::integer from emergency_events where location = 'ม.5/2' and warning_light_on = true),
  1,
  'escalating creates a real emergency_events row'
);

-- 12. closing an escalated incident closes its emergency and resolves it
select close_incident_report(
  'inc-teacher-scope-token', (select incident_id from created_incident), 'resolved', 'สรุปผล'
);
select is(
  (select status from list_my_incident_reports('inc-student-a-token') limit 1),
  'resolved',
  'closing an escalated incident resolves the linked report'
);

-- 13. the aggregate summary has no PII — just category/count/avg-response
select is(
  (select total_count from get_incident_summary('inc-teacher-scope-token') where category = 'sos'),
  1,
  'the aggregate summary counts the sos incident correctly'
);

select * from finish();
rollback;
