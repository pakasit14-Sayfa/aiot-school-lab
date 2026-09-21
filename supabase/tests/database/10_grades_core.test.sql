-- admin_token_patched
begin;

create extension if not exists pgtap with schema extensions;
select plan(13);

insert into packages (id, name, license_type)
values ('49100000-0000-0000-0000-000000000001', 'Grades test package', 'perpetual');

insert into schools (id, package_id, name, school_code)
values ('49200000-0000-0000-0000-000000000001', '49100000-0000-0000-0000-000000000001', 'Grades school', 'GRD-A');

insert into academic_years (id, school_id, name)
values ('49300000-0000-0000-0000-000000000001', '49200000-0000-0000-0000-000000000001', '2026');

insert into terms (id, academic_year_id, name)
values ('49400000-0000-0000-0000-000000000001', '49300000-0000-0000-0000-000000000001', 'Term 1/2026');

insert into users (
  id, school_id, email, password_hash, first_name, last_name, created_by
) values
  ('10900000-0000-0000-0000-000000000000', '49200000-0000-0000-0000-000000000001', 'admin10@pdpa.test', crypt('x', gen_salt('bf')), 'Admin', 'Patch', '10900000-0000-0000-0000-000000000000'),
  ('49500000-0000-0000-0000-000000000001', '49200000-0000-0000-0000-000000000001',
   'grd-teacher-a@pdpa.test', crypt('irrelevant', gen_salt('bf')), 'Teacher', 'A',
   '49500000-0000-0000-0000-000000000001'),
  ('49500000-0000-0000-0000-000000000002', '49200000-0000-0000-0000-000000000001',
   'grd-student-a1@pdpa.test', crypt('irrelevant', gen_salt('bf')), 'Student', 'One',
   '49500000-0000-0000-0000-000000000001'),
  ('49500000-0000-0000-0000-000000000003', '49200000-0000-0000-0000-000000000001',
   'grd-student-a2@pdpa.test', crypt('irrelevant', gen_salt('bf')), 'Student', 'Two',
   '49500000-0000-0000-0000-000000000001'),
  ('49500000-0000-0000-0000-000000000004', '49200000-0000-0000-0000-000000000001',
   'grd-admin-a@pdpa.test', crypt('irrelevant', gen_salt('bf')), 'Admin', 'A',
   '49500000-0000-0000-0000-000000000001');

insert into user_roles (user_id, role, school_id, granted_by) values
  ('10900000-0000-0000-0000-000000000000', 'school_admin', '49200000-0000-0000-0000-000000000001', '10900000-0000-0000-0000-000000000000'),
  ('49500000-0000-0000-0000-000000000001', 'teacher', '49200000-0000-0000-0000-000000000001', '49500000-0000-0000-0000-000000000001'),
  ('49500000-0000-0000-0000-000000000002', 'student', '49200000-0000-0000-0000-000000000001', '49500000-0000-0000-0000-000000000001'),
  ('49500000-0000-0000-0000-000000000003', 'student', '49200000-0000-0000-0000-000000000001', '49500000-0000-0000-0000-000000000001'),
  ('49500000-0000-0000-0000-000000000004', 'school_admin', '49200000-0000-0000-0000-000000000001', '49500000-0000-0000-0000-000000000001');

insert into sessions (user_id, active_role, active_school_id, token_hash, expires_at) values
  ('10900000-0000-0000-0000-000000000000', 'school_admin', '49200000-0000-0000-0000-000000000001', encode(digest('admin-token-patched-10', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('49500000-0000-0000-0000-000000000001', 'teacher', '49200000-0000-0000-0000-000000000001',
   encode(digest('grd-teacher-a-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('49500000-0000-0000-0000-000000000002', 'student', '49200000-0000-0000-0000-000000000001',
   encode(digest('grd-student-a1-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('49500000-0000-0000-0000-000000000003', 'student', '49200000-0000-0000-0000-000000000001',
   encode(digest('grd-student-a2-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('49500000-0000-0000-0000-000000000004', 'school_admin', '49200000-0000-0000-0000-000000000001',
   encode(digest('grd-admin-a-token', 'sha256'), 'hex'), now() + interval '1 hour');

-- teacher A is student A2's approved parent (CoI setup)
insert into parent_binding_codes (
  id, school_id, student_id, code_hash, expires_at, issued_by, status, redeemed_by, redeemed_at
) values (
  '49700000-0000-0000-0000-000000000001',
  '49200000-0000-0000-0000-000000000001',
  '49500000-0000-0000-0000-000000000003',
  encode(digest('grd-coi-binding-code', 'sha256'), 'hex'),
  now() + interval '7 days',
  '49500000-0000-0000-0000-000000000004',
  'redeemed',
  '49500000-0000-0000-0000-000000000001',
  now()
);

insert into parent_links (
  id, student_id, parent_id, relationship, binding_code_id, status, approved_by, approved_at
) values (
  '49600000-0000-0000-0000-000000000001',
  '49500000-0000-0000-0000-000000000003',
  '49500000-0000-0000-0000-000000000001',
  'father',
  '49700000-0000-0000-0000-000000000001',
  'approved',
  '49500000-0000-0000-0000-000000000004',
  now()
);

create temporary table created_course as
select * from create_course('admin-token-patched-10', '49400000-0000-0000-0000-000000000001',
  'Grades Test Course'
, 'M.1', '1', null, '49500000-0000-0000-0000-000000000001');

select enroll_student('admin-token-patched-10', (select course_id from created_course), '49500000-0000-0000-0000-000000000002');
select enroll_student('admin-token-patched-10', (select course_id from created_course), '49500000-0000-0000-0000-000000000003');

-- 1. teacher grades a normal student (no CoI)
create temporary table grade_a1 as
select * from create_grade(
  'grd-teacher-a-token', '49500000-0000-0000-0000-000000000002',
  (select course_id from created_course), 18, 20
);

select is(
  (select count(*)::integer from grade_a1 where grade_id is not null), 1,
  'teacher can create a grade for a normal student'
);

select is(
  (select coi_flag from grades where id = (select grade_id from grade_a1)), false,
  'a grade for an unrelated student is not CoI-flagged'
);

-- 2. draft grade is invisible to the student
select is(
  (select count(*)::integer from list_my_grades('grd-student-a1-token')), 0,
  'a draft grade is not visible to the student yet'
);

-- 3. confirm makes it visible
select confirm_grade('grd-teacher-a-token', (select grade_id from grade_a1));

select is(
  (select count(*)::integer from list_my_grades('grd-student-a1-token')), 1,
  'a confirmed grade becomes visible to the student'
);

-- 4. teacher grades their own child (CoI)
create temporary table grade_a2 as
select * from create_grade(
  'grd-teacher-a-token', '49500000-0000-0000-0000-000000000003',
  (select course_id from created_course), 15, 20
);

select is(
  (select coi_flag from grades where id = (select grade_id from grade_a2)), true,
  'grading an approved parent-linked student auto-flags CoI'
);

select is(
  (select coi_review_status from grades where id = (select grade_id from grade_a2)), 'pending',
  'a CoI-flagged grade starts as pending review'
);

select is(
  (select count(*)::integer from audit_logs
   where action = 'grade.coi_detected' and entity_id = (select grade_id from grade_a2)::text),
  1,
  'CoI detection is written to the audit log'
);

-- 5. teacher can still confirm a CoI-flagged grade (Decision Log allows it)
select confirm_grade('grd-teacher-a-token', (select grade_id from grade_a2));

select is(
  (select status from grades where id = (select grade_id from grade_a2)), 'confirmed',
  'a teacher can confirm their own child''s grade despite the CoI flag'
);

select is(
  (select count(*)::integer from list_my_grades('grd-student-a2-token')), 1,
  'the CoI-flagged confirmed grade is now visible to the student'
);

-- 6. school admin CoI review inbox
select is(
  (select count(*)::integer from list_pending_coi_grades('grd-admin-a-token')
   where grade_id = (select grade_id from grade_a2)),
  1,
  'the CoI-flagged grade appears in the admin review inbox before review'
);

select throws_ok(
  $$select review_coi_grade('grd-teacher-a-token', (select grade_id from grade_a2 limit 1))$$,
  'P0001', 'forbidden',
  'a teacher cannot review a CoI-flagged grade'
);

select review_coi_grade('grd-admin-a-token', (select grade_id from grade_a2));

select is(
  (select count(*)::integer from list_pending_coi_grades('grd-admin-a-token')
   where grade_id = (select grade_id from grade_a2)),
  0,
  'the grade leaves the admin review inbox once reviewed'
);

-- 7. a student cannot create a grade
select throws_ok(
  $$select * from create_grade(
    'grd-student-a1-token', '49500000-0000-0000-0000-000000000002',
    (select course_id from created_course), 20, 20
  )$$,
  'P0001', 'forbidden',
  'a student cannot create a grade'
);

select * from finish();
rollback;
