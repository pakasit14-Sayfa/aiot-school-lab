begin;

create extension if not exists pgtap with schema extensions;
select plan(8);

insert into packages (id, name, license_type)
values ('51100000-0000-0000-0000-000000000001', 'Files test package', 'perpetual');

insert into schools (id, package_id, name, school_code) values
  ('51200000-0000-0000-0000-000000000001', '51100000-0000-0000-0000-000000000001', 'Files school A', 'FIL-A'),
  ('51200000-0000-0000-0000-000000000002', '51100000-0000-0000-0000-000000000001', 'Files school B', 'FIL-B');

insert into academic_years (id, school_id, name)
values ('51300000-0000-0000-0000-000000000001', '51200000-0000-0000-0000-000000000001', '2026');

insert into terms (id, academic_year_id, name)
values ('51400000-0000-0000-0000-000000000001', '51300000-0000-0000-0000-000000000001', 'Term 1/2026');

insert into users (
  id, school_id, email, password_hash, first_name, last_name, created_by
) values
  ('51500000-0000-0000-0000-000000000001', '51200000-0000-0000-0000-000000000001',
   'fil-teacher-a@pdpa.test', crypt('irrelevant', gen_salt('bf')), 'Teacher', 'A',
   '51500000-0000-0000-0000-000000000001'),
  ('51500000-0000-0000-0000-000000000002', '51200000-0000-0000-0000-000000000001',
   'fil-student-a1@pdpa.test', crypt('irrelevant', gen_salt('bf')), 'Student', 'One',
   '51500000-0000-0000-0000-000000000001'),
  ('51500000-0000-0000-0000-000000000003', '51200000-0000-0000-0000-000000000001',
   'fil-student-a2@pdpa.test', crypt('irrelevant', gen_salt('bf')), 'Student', 'Two',
   '51500000-0000-0000-0000-000000000001'),
  ('51500000-0000-0000-0000-000000000004', '51200000-0000-0000-0000-000000000002',
   'fil-teacher-b@pdpa.test', crypt('irrelevant', gen_salt('bf')), 'Teacher', 'B',
   '51500000-0000-0000-0000-000000000004');

insert into user_roles (user_id, role, school_id, granted_by) values
  ('51500000-0000-0000-0000-000000000001', 'teacher', '51200000-0000-0000-0000-000000000001', '51500000-0000-0000-0000-000000000001'),
  ('51500000-0000-0000-0000-000000000002', 'student', '51200000-0000-0000-0000-000000000001', '51500000-0000-0000-0000-000000000001'),
  ('51500000-0000-0000-0000-000000000003', 'student', '51200000-0000-0000-0000-000000000001', '51500000-0000-0000-0000-000000000001'),
  ('51500000-0000-0000-0000-000000000004', 'teacher', '51200000-0000-0000-0000-000000000002', '51500000-0000-0000-0000-000000000004');

insert into sessions (user_id, active_role, active_school_id, token_hash, expires_at) values
  ('51500000-0000-0000-0000-000000000001', 'teacher', '51200000-0000-0000-0000-000000000001',
   encode(digest('fil-teacher-a-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('51500000-0000-0000-0000-000000000002', 'student', '51200000-0000-0000-0000-000000000001',
   encode(digest('fil-student-a1-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('51500000-0000-0000-0000-000000000003', 'student', '51200000-0000-0000-0000-000000000001',
   encode(digest('fil-student-a2-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('51500000-0000-0000-0000-000000000004', 'teacher', '51200000-0000-0000-0000-000000000002',
   encode(digest('fil-teacher-b-token', 'sha256'), 'hex'), now() + interval '1 hour');

create temporary table created_course as
select * from create_course(
  'fil-teacher-a-token', '51400000-0000-0000-0000-000000000001',
  'Environmental Science', 'M.3', 'Room 301', 'ห้องเรียนวิทยาศาสตร์สิ่งแวดล้อม'
);

select enroll_student(
  'fil-teacher-a-token',
  (select course_id from created_course),
  '51500000-0000-0000-0000-000000000002'
);

-- 1. a student cannot mint upload access
select throws_ok(
  $$select assert_course_upload_access(
    'fil-student-a1-token',
    (select course_id from created_course)
  )$$,
  'P0001', 'forbidden',
  'a student cannot obtain upload access'
);

-- 2. the teacher can register a file after a (simulated) successful upload
create temporary table registered_file as
select * from register_course_file(
  'fil-teacher-a-token', (select course_id from created_course),
  (select course_id from created_course)::text || '/lab-manual.pdf',
  'lab-manual.pdf', 204800
);

select is(
  (select count(*)::integer from registered_file where file_id is not null),
  1,
  'a teacher can register a file for their own course'
);

-- 3. an unenrolled student cannot register a file (upload access denied)
select throws_ok(
  $$select * from register_course_file(
    'fil-student-a2-token',
    (select course_id from created_course),
    'x/should-not-work.pdf', 'should-not-work.pdf', 100
  )$$,
  'P0001', 'forbidden',
  'a student cannot register a file'
);

-- 4. the enrolled student sees the file via list_course_files
select is(
  (select count(*)::integer from list_course_files(
    'fil-student-a1-token', (select course_id from created_course)
  )),
  1,
  'an enrolled student can list the course''s files'
);

-- 5. an unenrolled student cannot list files
select throws_ok(
  $$select * from list_course_files(
    'fil-student-a2-token',
    (select course_id from created_course)
  )$$,
  'P0001', 'forbidden',
  'a non-member cannot list a course''s files'
);

-- 6. the enrolled student can resolve a signed-download lookup
select is(
  (select file_name from get_course_file_for_download(
    'fil-student-a1-token', (select file_id from registered_file)
  )),
  'lab-manual.pdf',
  'an enrolled student can resolve the file for download'
);

-- 7. an unenrolled student cannot resolve the download path
select throws_ok(
  $$select * from get_course_file_for_download(
    'fil-student-a2-token',
    (select file_id from registered_file)
  )$$,
  'P0001', 'forbidden',
  'a non-member cannot resolve a download path'
);

-- 8. cross-school isolation
select throws_ok(
  $$select * from list_course_files(
    'fil-teacher-b-token',
    (select course_id from created_course)
  )$$,
  'P0001', 'forbidden',
  'a teacher from another school cannot list this course''s files'
);

select * from finish();
rollback;
