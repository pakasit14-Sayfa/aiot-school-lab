begin;

create extension if not exists pgtap with schema extensions;
select plan(9);

insert into packages (id, name, license_type)
values ('50100000-0000-0000-0000-000000000001', 'Posts test package', 'perpetual');

insert into schools (id, package_id, name, school_code) values
  ('50200000-0000-0000-0000-000000000001', '50100000-0000-0000-0000-000000000001', 'Posts school A', 'PST-A'),
  ('50200000-0000-0000-0000-000000000002', '50100000-0000-0000-0000-000000000001', 'Posts school B', 'PST-B');

insert into academic_years (id, school_id, name)
values ('50300000-0000-0000-0000-000000000001', '50200000-0000-0000-0000-000000000001', '2026');

insert into terms (id, academic_year_id, name)
values ('50400000-0000-0000-0000-000000000001', '50300000-0000-0000-0000-000000000001', 'Term 1/2026');

insert into users (
  id, school_id, email, password_hash, first_name, last_name, created_by
) values
  ('50500000-0000-0000-0000-000000000001', '50200000-0000-0000-0000-000000000001',
   'pst-teacher-a@pdpa.test', crypt('irrelevant', gen_salt('bf')), 'Teacher', 'A',
   '50500000-0000-0000-0000-000000000001'),
  ('50500000-0000-0000-0000-000000000002', '50200000-0000-0000-0000-000000000001',
   'pst-student-a1@pdpa.test', crypt('irrelevant', gen_salt('bf')), 'Student', 'One',
   '50500000-0000-0000-0000-000000000001'),
  ('50500000-0000-0000-0000-000000000003', '50200000-0000-0000-0000-000000000001',
   'pst-student-a2@pdpa.test', crypt('irrelevant', gen_salt('bf')), 'Student', 'Two',
   '50500000-0000-0000-0000-000000000001'),
  ('50500000-0000-0000-0000-000000000004', '50200000-0000-0000-0000-000000000002',
   'pst-teacher-b@pdpa.test', crypt('irrelevant', gen_salt('bf')), 'Teacher', 'B',
   '50500000-0000-0000-0000-000000000004');

insert into user_roles (user_id, role, school_id, granted_by) values
  ('50500000-0000-0000-0000-000000000001', 'teacher', '50200000-0000-0000-0000-000000000001', '50500000-0000-0000-0000-000000000001'),
  ('50500000-0000-0000-0000-000000000002', 'student', '50200000-0000-0000-0000-000000000001', '50500000-0000-0000-0000-000000000001'),
  ('50500000-0000-0000-0000-000000000003', 'student', '50200000-0000-0000-0000-000000000001', '50500000-0000-0000-0000-000000000001'),
  ('50500000-0000-0000-0000-000000000004', 'teacher', '50200000-0000-0000-0000-000000000002', '50500000-0000-0000-0000-000000000004');

insert into sessions (user_id, active_role, active_school_id, token_hash, expires_at) values
  ('50500000-0000-0000-0000-000000000001', 'teacher', '50200000-0000-0000-0000-000000000001',
   encode(digest('pst-teacher-a-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('50500000-0000-0000-0000-000000000002', 'student', '50200000-0000-0000-0000-000000000001',
   encode(digest('pst-student-a1-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('50500000-0000-0000-0000-000000000003', 'student', '50200000-0000-0000-0000-000000000001',
   encode(digest('pst-student-a2-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('50500000-0000-0000-0000-000000000004', 'teacher', '50200000-0000-0000-0000-000000000002',
   encode(digest('pst-teacher-b-token', 'sha256'), 'hex'), now() + interval '1 hour');

create temporary table created_course as
select * from create_course(
  'pst-teacher-a-token', '50400000-0000-0000-0000-000000000001',
  'Environmental Science', 'M.3', 'Room 301', 'ห้องเรียนวิทยาศาสตร์สิ่งแวดล้อม'
);

select enroll_student(
  'pst-teacher-a-token',
  (select course_id from created_course),
  '50500000-0000-0000-0000-000000000002'
);

-- 1. an unenrolled student cannot post
select throws_ok(
  $$select * from create_post(
    'pst-student-a2-token',
    (select course_id from created_course),
    'ไม่ควรโพสต์ได้'
  )$$,
  'P0001', 'forbidden',
  'a non-member cannot post to the course'
);

-- 2. the teacher creates a pinned announcement
create temporary table teacher_post as
select * from create_post(
  'pst-teacher-a-token', (select course_id from created_course),
  '[ประกาศ] เตรียมรายงานผลค่าฝุ่น PM2.5'
);

select is(
  (select count(*)::integer from teacher_post where post_id is not null),
  1,
  'a teacher can post to their own course'
);

-- 3. the enrolled student posts a question
create temporary table student_post as
select * from create_post(
  'pst-student-a1-token', (select course_id from created_course),
  'สอบถามเรื่องกราฟ CO2 ย้อนหลังครับ'
);

select is(
  (select count(*)::integer from student_post where post_id is not null),
  1,
  'an enrolled student can post to the course'
);

-- 4. both posts appear via list_posts
select is(
  (select count(*)::integer from list_posts(
    'pst-teacher-a-token', (select course_id from created_course)
  )),
  2,
  'list_posts returns every post in the course'
);

-- 5. an unenrolled student cannot list posts
select throws_ok(
  $$select * from list_posts(
    'pst-student-a2-token',
    (select course_id from created_course)
  )$$,
  'P0001', 'forbidden',
  'a non-member cannot list posts'
);

-- 6. an unrelated student cannot reply
select throws_ok(
  $$select * from create_reply(
    'pst-student-a2-token',
    (select post_id from teacher_post),
    'ไม่ควรตอบได้'
  )$$,
  'P0001', 'forbidden',
  'a non-member cannot reply to a post'
);

-- 7. the teacher replies to the student's question
select create_reply(
  'pst-teacher-a-token', (select post_id from student_post),
  'ไปดูในแท็บบทเรียนได้เลยครับ'
);

select is(
  (select jsonb_array_length(replies) from list_posts(
    'pst-student-a1-token', (select course_id from created_course)
  ) where post_id = (select post_id from student_post)),
  1,
  'a reply appears nested under its post'
);

-- 8. cross-school teacher cannot list this course's posts
select throws_ok(
  $$select * from list_posts(
    'pst-teacher-b-token',
    (select course_id from created_course)
  )$$,
  'P0001', 'forbidden',
  'a teacher from another school cannot list this course''s posts'
);

-- 9. a pinned post always sorts first, regardless of creation order
update course_posts set is_pinned = true where id = (select post_id from student_post);

select is(
  (select post_id from list_posts(
    'pst-teacher-a-token', (select course_id from created_course)
  ) limit 1),
  (select post_id from student_post),
  'a pinned post sorts before unpinned posts'
);

select * from finish();
rollback;
