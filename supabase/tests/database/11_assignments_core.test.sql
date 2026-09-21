-- admin_token_patched
begin;

create extension if not exists pgtap with schema extensions;
select plan(24);

insert into packages (id, name, license_type)
values ('49100000-0000-0000-0000-000000000001', 'Assignments test package', 'perpetual');

insert into schools (id, package_id, name, school_code) values
  ('49200000-0000-0000-0000-000000000001', '49100000-0000-0000-0000-000000000001', 'Assignments school A', 'ASG-A'),
  ('49200000-0000-0000-0000-000000000002', '49100000-0000-0000-0000-000000000001', 'Assignments school B', 'ASG-B');

insert into academic_years (id, school_id, name)
values ('49300000-0000-0000-0000-000000000001', '49200000-0000-0000-0000-000000000001', '2026');

insert into terms (id, academic_year_id, name)
values ('49400000-0000-0000-0000-000000000001', '49300000-0000-0000-0000-000000000001', 'Term 1/2026');

insert into users (
  id, school_id, email, password_hash, first_name, last_name, created_by
) values
  ('11900000-0000-0000-0000-000000000000', '49200000-0000-0000-0000-000000000001', 'admin11@pdpa.test', crypt('x', gen_salt('bf')), 'Admin', 'Patch', '11900000-0000-0000-0000-000000000000'),
  ('49500000-0000-0000-0000-000000000001', '49200000-0000-0000-0000-000000000001',
   'asg-teacher-a@pdpa.test', crypt('irrelevant', gen_salt('bf')), 'Teacher', 'A',
   '49500000-0000-0000-0000-000000000001'),
  ('49500000-0000-0000-0000-000000000002', '49200000-0000-0000-0000-000000000001',
   'asg-student-a1@pdpa.test', crypt('irrelevant', gen_salt('bf')), 'Student', 'One',
   '49500000-0000-0000-0000-000000000001'),
  ('49500000-0000-0000-0000-000000000003', '49200000-0000-0000-0000-000000000001',
   'asg-student-a2@pdpa.test', crypt('irrelevant', gen_salt('bf')), 'Student', 'Two',
   '49500000-0000-0000-0000-000000000001'),
  ('49500000-0000-0000-0000-000000000004', '49200000-0000-0000-0000-000000000002',
   'asg-teacher-b@pdpa.test', crypt('irrelevant', gen_salt('bf')), 'Teacher', 'B',
   '49500000-0000-0000-0000-000000000004');

insert into user_roles (user_id, role, school_id, granted_by) values
  ('11900000-0000-0000-0000-000000000000', 'school_admin', '49200000-0000-0000-0000-000000000001', '11900000-0000-0000-0000-000000000000'),
  ('49500000-0000-0000-0000-000000000001', 'teacher', '49200000-0000-0000-0000-000000000001', '49500000-0000-0000-0000-000000000001'),
  ('49500000-0000-0000-0000-000000000002', 'student', '49200000-0000-0000-0000-000000000001', '49500000-0000-0000-0000-000000000001'),
  ('49500000-0000-0000-0000-000000000003', 'student', '49200000-0000-0000-0000-000000000001', '49500000-0000-0000-0000-000000000001'),
  ('49500000-0000-0000-0000-000000000004', 'teacher', '49200000-0000-0000-0000-000000000002', '49500000-0000-0000-0000-000000000004');

insert into sessions (user_id, active_role, active_school_id, token_hash, expires_at) values
  ('11900000-0000-0000-0000-000000000000', 'school_admin', '49200000-0000-0000-0000-000000000001', encode(digest('admin-token-patched-11', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('49500000-0000-0000-0000-000000000001', 'teacher', '49200000-0000-0000-0000-000000000001',
   encode(digest('asg-teacher-a-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('49500000-0000-0000-0000-000000000002', 'student', '49200000-0000-0000-0000-000000000001',
   encode(digest('asg-student-a1-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('49500000-0000-0000-0000-000000000003', 'student', '49200000-0000-0000-0000-000000000001',
   encode(digest('asg-student-a2-token', 'sha256'), 'hex'), now() + interval '1 hour'),
  ('49500000-0000-0000-0000-000000000004', 'teacher', '49200000-0000-0000-0000-000000000002',
   encode(digest('asg-teacher-b-token', 'sha256'), 'hex'), now() + interval '1 hour');

insert into devices (id, school_id, type, name, registered_by)
values ('49600000-0000-0000-0000-000000000001', '49200000-0000-0000-0000-000000000001',
        'pm25_sensor', 'Assignment PM2.5', '49500000-0000-0000-0000-000000000001');

create temporary table created_course as
select * from create_course('admin-token-patched-11', '49400000-0000-0000-0000-000000000001',
  'Environmental Science', 'M.3', 'Room 301', 'ห้องเรียนวิทยาศาสตร์สิ่งแวดล้อม'
, '49500000-0000-0000-0000-000000000001');

select enroll_student('admin-token-patched-11', (select course_id from created_course),
  '49500000-0000-0000-0000-000000000002'
);

-- 1. teacher creates a draft assignment
create temporary table created_assignment as
select * from create_assignment(
  'asg-teacher-a-token', (select course_id from created_course),
  'homework', 'สำรวจคุณภาพอากาศ', 'บันทึกค่าฝุ่น PM2.5 ตลอดสัปดาห์'
);

select is(
  (select count(*)::integer from created_assignment where assignment_id is not null),
  1,
  'teacher can create a draft assignment'
);

-- 2. draft is invisible to the enrolled student
select is(
  (select count(*)::integer from list_assignments(
    'asg-student-a1-token', (select course_id from created_course)
  )),
  0,
  'a draft assignment is not visible to an enrolled student'
);

-- 3. publish it
select publish_assignment('asg-teacher-a-token', (select assignment_id from created_assignment));

select is(
  (select count(*)::integer from list_assignments(
    'asg-student-a1-token', (select course_id from created_course)
  )),
  1,
  'a published assignment becomes visible to an enrolled student'
);

-- 4. an unenrolled student cannot list assignments for the course at all
select throws_ok(
  $$select * from list_assignments(
    'asg-student-a2-token',
    (select course_id from created_course)
  )$$,
  'P0001', 'forbidden',
  'an unenrolled student cannot list a course''s assignments'
);

-- 5. link a real sensor window to the assignment
select link_assignment_sensor_dataset(
  'asg-teacher-a-token', (select assignment_id from created_assignment),
  '49600000-0000-0000-0000-000000000001', 'pm25',
  now() - interval '7 day', now(), 'ค่าฝุ่นสัปดาห์นี้'
);

select is(
  (select jsonb_array_length(sensor_datasets) from get_assignment(
    'asg-teacher-a-token', (select assignment_id from created_assignment)
  )),
  1,
  'get_assignment returns the linked sensor dataset'
);

-- 6. student submits the assignment (version 1)
create temporary table first_submission as
select * from submit_assignment(
  'asg-student-a1-token', (select assignment_id from created_assignment), 'ค่าเฉลี่ย PM2.5 คือ 32'
);

select is(
  (select version from first_submission),
  1,
  'first submission is version 1'
);

-- 7. resubmit (version 2)
select submit_assignment(
  'asg-student-a1-token', (select assignment_id from created_assignment), 'แก้ไข: ค่าเฉลี่ย PM2.5 คือ 30'
);

select is(
  (select count(*)::integer from list_my_submission_versions(
    'asg-student-a1-token', (select assignment_id from created_assignment)
  )),
  2,
  'resubmission creates a second version, both retained in history'
);

-- 8. teacher's roster view shows the latest version's content
select is(
  (select latest_content from list_submissions(
    'asg-teacher-a-token', (select assignment_id from created_assignment)
  ) where student_id = '49500000-0000-0000-0000-000000000002'),
  'แก้ไข: ค่าเฉลี่ย PM2.5 คือ 30',
  'teacher roster shows the latest submitted version'
);

-- 9. teacher gives feedback
create temporary table given_feedback as
select * from give_feedback(
  'asg-teacher-a-token', (select submission_id from first_submission), 'ทำได้ดีมาก ลองเพิ่มกราฟด้วย'
);

select is(
  (select count(*)::integer from given_feedback where feedback_id is not null),
  1,
  'teacher can give feedback on a submission'
);

-- 10. the owning student can see the feedback
select is(
  (select count(*)::integer from list_feedback(
    'asg-student-a1-token', (select submission_id from first_submission)
  )),
  1,
  'the owning student can see their feedback'
);

-- 11. a different, unrelated student cannot see this feedback
select throws_ok(
  $$select * from list_feedback(
    'asg-student-a2-token',
    (select submission_id from first_submission)
  )$$,
  'P0001', 'forbidden',
  'a student who does not own the submission cannot see its feedback'
);

-- 12. cross-school isolation
select throws_ok(
  $$select * from get_assignment(
    'asg-teacher-b-token',
    (select assignment_id from created_assignment)
  )$$,
  'P0001', 'forbidden',
  'a teacher from another school cannot read this assignment'
);

-- 13. a student cannot create an assignment
select throws_ok(
  $$select * from create_assignment(
    'asg-student-a1-token',
    (select course_id from created_course),
    'homework', 'Should not work'
  )$$,
  'P0001', 'forbidden',
  'a student cannot create an assignment'
);

-- 14. a student cannot submit to a course they are not enrolled in (via an unpublished-lookalike check: try wrong assignment id path is covered by list; here check unenrolled submit is forbidden)
select throws_ok(
  $$select * from submit_assignment(
    'asg-student-a2-token',
    (select assignment_id from created_assignment),
    'พยายามส่งทั้งที่ไม่ได้ลงทะเบียน'
  )$$,
  'P0001', 'forbidden',
  'an unenrolled student cannot submit an assignment'
);

-- 15. an unrelated teacher cannot give feedback on this submission
select throws_ok(
  $$select * from give_feedback(
    'asg-teacher-b-token',
    (select submission_id from first_submission),
    'ไม่ควรทำได้'
  )$$,
  'P0001', 'forbidden',
  'a teacher from another school cannot give feedback on this submission'
);

-- 20260921010000 — per-assignment counts for the teacher's list row
select is(
  (select total_students from list_assignments('asg-teacher-a-token', (select course_id from created_course)) limit 1),
  1, 'total_students = enrolled count');
select is(
  (select submitted_count from list_assignments('asg-teacher-a-token', (select course_id from created_course)) limit 1),
  1, 'submitted_count counts a student once even after resubmitting');
select is(
  (select dataset_count from list_assignments('asg-teacher-a-token', (select course_id from created_course)) limit 1),
  1, 'dataset_count reflects the dataset pinned in step 5');
select cmp_ok(
  (select pending_grade_count from list_assignments('asg-teacher-a-token', (select course_id from created_course)) limit 1),
  '<=', 1, 'pending_grade_count never exceeds submitted students');

-- 20260921020000 — unlink a pinned dataset; unpublish back to draft
select is(
  (select dataset_count from list_assignments('asg-teacher-a-token', (select course_id from created_course)) limit 1),
  1, 'one dataset pinned before unlink');
select unlink_assignment_sensor_dataset('asg-teacher-a-token',
  (select id from assignment_sensor_datasets where assignment_id = (select assignment_id from created_assignment) limit 1));
select is(
  (select dataset_count from list_assignments('asg-teacher-a-token', (select course_id from created_course)) limit 1),
  0, 'dataset unlinked');
select throws_ok(
  $$ select unpublish_assignment('asg-teacher-b-token', (select assignment_id from created_assignment)) $$,
  'forbidden', 'another school''s teacher cannot unpublish');
select unpublish_assignment('asg-teacher-a-token', (select assignment_id from created_assignment));
select is(
  (select count(*)::integer from list_assignments('asg-student-a1-token', (select course_id from created_course))),
  0, 'after unpublish the student no longer sees it');
select is(
  (select count(*)::integer from list_my_submission_versions('asg-student-a1-token', (select assignment_id from created_assignment))),
  2, 'existing submissions survive unpublish');

select * from finish();
rollback;
