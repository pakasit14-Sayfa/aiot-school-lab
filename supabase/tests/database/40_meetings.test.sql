-- pgTAP Tests: ระบบประชุม (meetings, attendees, agenda, minutes, addenda,
-- resolutions, attachments, external attendees, attendance, notifications,
-- staff calendar) — schema from 20260907030000 + 20260907040000.
--
-- What matters here, per DECISIONS_2026-09-07.md: a one-on-one summons is
-- visible only to its two parties and school_admin (M1); it cannot be
-- declined, only accepted or postponed with a reason (M2); minutes go
-- draft → final and a finalised record can only be appended to, never
-- edited (M3); "ไม่ต้องมีบันทึก" and "ยังไม่ได้บันทึก" must stay two
-- different facts (M4); a summons consumes no meeting number so the
-- school's numbered series has no gaps (B); attendance is a three-state
-- fact taken once, defaulting to "not yet checked", never "everyone came"
-- (E); external guests are name + organisation only, no account (C).

begin;

create extension if not exists pgtap with schema extensions;
select plan(117);

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
   'mtg-student@test.local', crypt('pass', gen_salt('bf')), 'Mtg', 'Student', '99822000-0000-0000-0000-000000000001');

insert into user_roles (user_id, role, school_id, granted_by) values
  ('99822000-0000-0000-0000-000000000001', 'executive',    '99821000-0000-0000-0000-000000000001', '99822000-0000-0000-0000-000000000001'),
  ('99822000-0000-0000-0000-000000000002', 'school_admin', '99821000-0000-0000-0000-000000000001', '99822000-0000-0000-0000-000000000001'),
  ('99822000-0000-0000-0000-000000000003', 'teacher',      '99821000-0000-0000-0000-000000000001', '99822000-0000-0000-0000-000000000001'),
  ('99822000-0000-0000-0000-000000000004', 'teacher',      '99821000-0000-0000-0000-000000000001', '99822000-0000-0000-0000-000000000001'),
  ('99822000-0000-0000-0000-000000000005', 'teacher',      '99821000-0000-0000-0000-000000000001', '99822000-0000-0000-0000-000000000001'),
  ('99822000-0000-0000-0000-000000000006', 'student',      '99821000-0000-0000-0000-000000000001', '99822000-0000-0000-0000-000000000001');

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
   encode(digest('mtg-student-token', 'sha256'), 'hex'), now() + interval '1 hour');

insert into departments (id, school_id, name, kind, sort_order, created_by) values
  ('99823000-0000-0000-0000-000000000001', '99821000-0000-0000-0000-000000000001',
   'ฝ่ายทดสอบประชุม', 'administrative', 1, '99822000-0000-0000-0000-000000000001');

insert into department_members (department_id, user_id, is_head, assigned_by) values
  ('99823000-0000-0000-0000-000000000001', '99822000-0000-0000-0000-000000000003',
   true, '99822000-0000-0000-0000-000000000001'),
  ('99823000-0000-0000-0000-000000000001', '99822000-0000-0000-0000-000000000004',
   false, '99822000-0000-0000-0000-000000000001');

-- ---------------------------------------------------------------------------
-- create_meeting — validation
-- ---------------------------------------------------------------------------

select throws_ok(
  $$ select create_meeting('mtg-teacher1-token', 'ประชุมทดสอบ', 'group', '2027-03-10 09:00+07') $$,
  'forbidden',
  'a teacher cannot organise a meeting'
);

select throws_ok(
  $$ select create_meeting('mtg-exec-token', '   ', 'group', '2027-03-10 09:00+07') $$,
  'title_required',
  'a whitespace-only title is refused'
);

select throws_ok(
  $$ select create_meeting('mtg-exec-token', 'ประชุมทดสอบ', 'ad_hoc', '2027-03-10 09:00+07') $$,
  'invalid_meeting_type',
  'meeting_type is constrained to the three the schema knows'
);

select throws_ok(
  $$ select create_meeting('mtg-exec-token', 'ประชุมทดสอบ', 'group',
       '2027-03-10 09:00+07', '2027-03-10 08:00+07') $$,
  'invalid_time_range',
  'an end time at or before the start is refused'
);

select throws_ok(
  $$ select create_meeting('mtg-exec-token', 'เรียกพบสองคน', 'one_on_one',
       '2027-03-10 09:00+07', null, null, null, 'attendees', true,
       array['99822000-0000-0000-0000-000000000003',
             '99822000-0000-0000-0000-000000000004']::uuid[]) $$,
  'one_on_one_needs_exactly_one_person',
  'a summons naming two people is refused — it is exactly the director and one other'
);

select throws_ok(
  $$ select create_meeting('mtg-exec-token', 'ประชุมไม่มีใครมา', 'group',
       '2027-03-10 09:00+07') $$,
  'attendees_required',
  'a group meeting with nobody invited is refused'
);

-- ---------------------------------------------------------------------------
-- create_meeting — the real meetings this file's later tests use
-- ---------------------------------------------------------------------------

select lives_ok(
  $$ select create_meeting('mtg-exec-token', 'เรียกพบครูเทสต์วัน', 'one_on_one',
       '2027-03-10 09:00+07', null, null, null, 'school', true,
       array['99822000-0000-0000-0000-000000000003']::uuid[]) $$,
  'the director summons teacher1 — visibility ''school'' asked for is overridden'
);

select is(
  (select visibility from meetings where title = 'เรียกพบครูเทสต์วัน'),
  'attendees'::varchar,
  'a summons is never school-visible, whatever the caller asked for'
);

select is(
  (select meeting_no from meetings where title = 'เรียกพบครูเทสต์วัน'),
  null,
  'a summons takes no meeting number'
);

select is(
  (select count(*)::int from meeting_attendees
    where meeting_id = (select id from meetings where title = 'เรียกพบครูเทสต์วัน')),
  2,
  'exactly the organiser and the one person summoned'
);

select lives_ok(
  $$ select create_meeting('mtg-exec-token', 'ประชุมทั้งคณะเทสต์', 'school_wide',
       '2027-03-10 13:00+07') $$,
  'a school-wide meeting is created'
);

select is(
  (select meeting_no from meetings where title = 'ประชุมทั้งคณะเทสต์'),
  1,
  'the first numbered meeting of the year gets no. 1 — the summons above did not consume one'
);

select is(
  (select count(*)::int from meeting_attendees
    where meeting_id = (select id from meetings where title = 'ประชุมทั้งคณะเทสต์')),
  5,
  'school-wide expands to every teacher/school_admin/executive but the organiser (student excluded)'
);

select lives_ok(
  $$ select create_meeting('mtg-admin-token', 'ประชุมฝ่ายทดสอบ', 'group',
       '2027-03-10 15:00+07', null, null, null, 'attendees', true,
       null, array['99823000-0000-0000-0000-000000000001']::uuid[]) $$,
  'a department-scoped group meeting is created'
);

select is(
  (select meeting_no from meetings where title = 'ประชุมฝ่ายทดสอบ'),
  2,
  'the second numbered meeting of the year gets no. 2'
);

select is(
  (select count(*)::int from meeting_attendees
    where meeting_id = (select id from meetings where title = 'ประชุมฝ่ายทดสอบ')),
  3,
  'organiser + the two department members, expanded at creation time'
);

select lives_ok(
  $$ select create_meeting('mtg-exec-token', 'ประชุมที่จะยกเลิก', 'group',
       '2027-03-10 16:00+07', null, null, null, 'attendees', true,
       array['99822000-0000-0000-0000-000000000005']::uuid[]) $$,
  'a throwaway meeting is created to test cancellation'
);

select lives_ok(
  $$ select create_meeting('mtg-exec-token', 'ประชุมที่จะปิด', 'group',
       '2027-03-10 17:00+07', null, null, null, 'attendees', true,
       array['99822000-0000-0000-0000-000000000005']::uuid[]) $$,
  'a throwaway meeting is created to test completion'
);

select lives_ok(
  $$ select create_meeting('mtg-exec-token', 'ประชุมไม่มีบันทึก', 'group',
       '2027-03-10 18:00+07', null, null, null, 'attendees', false,
       array['99822000-0000-0000-0000-000000000005']::uuid[]) $$,
  'a meeting the school marked as needing no record is created'
);

select is(
  (select minutes_expected from meetings where title = 'ประชุมไม่มีบันทึก'),
  false,
  'minutes_expected is honoured as false'
);

select is(
  (select minutes_status from list_meetings('mtg-exec-token')
    where title = 'ประชุมไม่มีบันทึก'),
  null,
  '"ไม่ต้องมีบันทึก" (minutes_expected=false) still reads as no record, not a fake status'
);

-- ---------------------------------------------------------------------------
-- Who can see what — _can_see_meeting via list_meetings
-- ---------------------------------------------------------------------------

select is(
  (select bool_or(title = 'เรียกพบครูเทสต์วัน') from list_meetings('mtg-teacher1-token')),
  true,
  'the summoned teacher sees their own summons'
);

select is(
  (select bool_or(title = 'เรียกพบครูเทสต์วัน') from list_meetings('mtg-admin-token')),
  true,
  'school_admin sees the summons too — they administer the system (M1)'
);

select is(
  (select coalesce(bool_or(title = 'เรียกพบครูเทสต์วัน'), false)
     from list_meetings('mtg-teacher3-token')),
  false,
  'a teacher who is neither party nor admin does not see the summons'
);

select is(
  (select bool_or(title = 'ประชุมฝ่ายทดสอบ') from list_meetings('mtg-teacher1-token')),
  true,
  'a department member sees the group meeting they were expanded into'
);

select is(
  (select coalesce(bool_or(title = 'ประชุมฝ่ายทดสอบ'), false)
     from list_meetings('mtg-teacher3-token')),
  false,
  'someone outside the department does not see it'
);

select is(
  (select bool_or(title = 'ประชุมทั้งคณะเทสต์') from list_meetings('mtg-teacher3-token')),
  true,
  'a school-wide meeting is visible to staff even without an explicit invite'
);

select throws_ok(
  $$ select * from list_meetings('mtg-student-token') $$,
  'forbidden',
  'a student cannot read the meeting register'
);

-- ---------------------------------------------------------------------------
-- respond_to_meeting
-- ---------------------------------------------------------------------------

select throws_ok(
  $$ select respond_to_meeting('mtg-teacher3-token',
       (select id from meetings where title = 'ประชุมฝ่ายทดสอบ'), 'accepted') $$,
  'not_an_attendee',
  'someone never invited cannot respond'
);

select throws_ok(
  $$ select respond_to_meeting('mtg-teacher1-token',
       (select id from meetings where title = 'ประชุมฝ่ายทดสอบ'), 'maybe') $$,
  'invalid_response',
  'an unrecognised response is refused'
);

select throws_ok(
  $$ select respond_to_meeting('mtg-teacher1-token',
       (select id from meetings where title = 'เรียกพบครูเทสต์วัน'), 'declined') $$,
  'cannot_decline_summons',
  'a summons cannot be declined (M2) — only accepted or postponed'
);

select throws_ok(
  $$ select respond_to_meeting('mtg-teacher1-token',
       (select id from meetings where title = 'ประชุมฝ่ายทดสอบ'),
       'postpone_requested') $$,
  'reason_required',
  'asking to postpone a meeting needs a reason'
);

select lives_ok(
  $$ select respond_to_meeting('mtg-teacher1-token',
       (select id from meetings where title = 'ประชุมฝ่ายทดสอบ'), 'accepted') $$,
  'a real attendee accepts'
);

select is(
  (select response from meeting_attendees
    where meeting_id = (select id from meetings where title = 'ประชุมฝ่ายทดสอบ')
      and user_id = '99822000-0000-0000-0000-000000000003'),
  'accepted',
  'the response is recorded'
);

select lives_ok(
  $$ select respond_to_meeting('mtg-teacher1-token',
       (select id from meetings where title = 'เรียกพบครูเทสต์วัน'),
       'postpone_requested', 'ติดสอนคาบสุดท้าย') $$,
  'the summoned teacher asks to postpone instead, with a reason'
);

-- ---------------------------------------------------------------------------
-- Agenda
-- ---------------------------------------------------------------------------

select throws_ok(
  $$ select set_meeting_agenda_item('mtg-teacher1-token',
       (select id from meetings where title = 'ประชุมฝ่ายทดสอบ'), 'วาระที่ 1') $$,
  'forbidden',
  'a non-organiser, non-admin attendee cannot set the agenda'
);

select throws_ok(
  $$ select set_meeting_agenda_item('mtg-admin-token',
       (select id from meetings where title = 'ประชุมฝ่ายทดสอบ'), '  ') $$,
  'title_required',
  'a blank agenda title is refused'
);

select lives_ok(
  $$ select set_meeting_agenda_item('mtg-admin-token',
       (select id from meetings where title = 'ประชุมฝ่ายทดสอบ'), 'วาระทดสอบ', 1) $$,
  'the organiser adds a real agenda item'
);

select lives_ok(
  $$ select set_meeting_agenda_item('mtg-admin-token',
       (select id from meetings where title = 'ประชุมฝ่ายทดสอบ'), 'วาระทดสอบ (แก้ไข)', 1, null, null,
       (select id from meeting_agenda_items where title = 'วาระทดสอบ')) $$,
  'the same item is updated by id rather than duplicated'
);

select is(
  (select count(*)::int from meeting_agenda_items
    where meeting_id = (select id from meetings where title = 'ประชุมฝ่ายทดสอบ')),
  1,
  'still exactly one item — the update path did not insert a second row'
);

select throws_ok(
  $$ select delete_meeting_agenda_item('mtg-teacher1-token',
       (select id from meeting_agenda_items where title = 'วาระทดสอบ (แก้ไข)')) $$,
  'forbidden',
  'a non-organiser cannot delete the agenda item'
);

select lives_ok(
  $$ select delete_meeting_agenda_item('mtg-admin-token',
       (select id from meeting_agenda_items where title = 'วาระทดสอบ (แก้ไข)')) $$,
  'the organiser deletes it'
);

-- ---------------------------------------------------------------------------
-- Minutes: draft → final → addenda only
-- ---------------------------------------------------------------------------

select throws_ok(
  $$ select save_meeting_minutes_draft('mtg-exec-token',
       (select id from meetings where title = 'ประชุมไม่มีบันทึก'), 'เนื้อหา') $$,
  'minutes_not_expected',
  'a meeting marked as needing no record does not get one by accident (M4)'
);

select throws_ok(
  $$ select save_meeting_minutes_draft('mtg-teacher1-token',
       (select id from meetings where title = 'ประชุมฝ่ายทดสอบ'), 'เนื้อหา') $$,
  'forbidden',
  'a non-organiser, non-admin cannot record minutes'
);

select throws_ok(
  $$ select save_meeting_minutes_draft('mtg-admin-token',
       (select id from meetings where title = 'ประชุมฝ่ายทดสอบ'), '   ') $$,
  'body_required',
  'a blank draft body is refused'
);

select lives_ok(
  $$ select save_meeting_minutes_draft('mtg-admin-token',
       (select id from meetings where title = 'ประชุมฝ่ายทดสอบ'), 'ร่างบันทึกการประชุม') $$,
  'the organiser saves a real draft'
);

select is(
  (select body from get_meeting_minutes('mtg-teacher1-token',
     (select id from meetings where title = 'ประชุมฝ่ายทดสอบ'))),
  null,
  'a draft is invisible to an attendee who is not its recorder'
);

select is(
  (select body from get_meeting_minutes('mtg-admin-token',
     (select id from meetings where title = 'ประชุมฝ่ายทดสอบ'))),
  'ร่างบันทึกการประชุม',
  'but visible to the person who wrote it'
);

select throws_ok(
  $$ select finalize_meeting_minutes('mtg-teacher1-token',
       (select id from meetings where title = 'ประชุมฝ่ายทดสอบ')) $$,
  'forbidden',
  'a non-organiser cannot finalise the minutes'
);

select lives_ok(
  $$ select finalize_meeting_minutes('mtg-admin-token',
       (select id from meetings where title = 'ประชุมฝ่ายทดสอบ')) $$,
  'the organiser finalises them'
);

select throws_ok(
  $$ select finalize_meeting_minutes('mtg-admin-token',
       (select id from meetings where title = 'ประชุมฝ่ายทดสอบ')) $$,
  'minutes_already_final',
  'finalising an already-final record is refused — there is no update path (M3)'
);

select is(
  (select body from get_meeting_minutes('mtg-teacher1-token',
     (select id from meetings where title = 'ประชุมฝ่ายทดสอบ'))),
  'ร่างบันทึกการประชุม',
  'once final, an attendee who could not see the draft now can'
);

-- One-on-one minutes, to exercise the recorder-vs-subject addendum split and
-- the read-audit rule.

select lives_ok(
  $$ select save_meeting_minutes_draft('mtg-exec-token',
       (select id from meetings where title = 'เรียกพบครูเทสต์วัน'),
       'บันทึกการเรียกพบ') $$,
  'the director drafts the summons record'
);

select lives_ok(
  $$ select finalize_meeting_minutes('mtg-exec-token',
       (select id from meetings where title = 'เรียกพบครูเทสต์วัน')) $$,
  'and finalises it'
);

select throws_ok(
  $$ select add_meeting_minute_addendum('mtg-exec-token',
       (select id from meetings where title = 'ประชุมที่จะยกเลิก'), 'ข้อความ') $$,
  'minutes_not_final',
  'an addendum needs a finalised record to attach to'
);

select throws_ok(
  $$ select add_meeting_minute_addendum('mtg-teacher3-token',
       (select id from meetings where title = 'เรียกพบครูเทสต์วัน'), 'ข้อความ') $$,
  'forbidden',
  'someone who is neither the recorder nor a party to the summons cannot add one'
);

select lives_ok(
  $$ select add_meeting_minute_addendum('mtg-exec-token',
       (select id from meetings where title = 'เรียกพบครูเทสต์วัน'),
       'หมายเหตุเพิ่มเติมจากผู้บันทึก') $$,
  'the recorder appends a note'
);

select lives_ok(
  $$ select add_meeting_minute_addendum('mtg-teacher1-token',
       (select id from meetings where title = 'เรียกพบครูเทสต์วัน'),
       'คำชี้แจงของครูที่ถูกเรียกพบ') $$,
  'the summoned teacher appends their own statement — a right nobody else has'
);

select is(
  (select author_kind from list_meeting_minute_addenda('mtg-exec-token',
     (select id from meetings where title = 'เรียกพบครูเทสต์วัน'))
    where body = 'หมายเหตุเพิ่มเติมจากผู้บันทึก'),
  'recorder',
  'the director''s addendum is tagged as the recorder''s'
);

select is(
  (select author_kind from list_meeting_minute_addenda('mtg-exec-token',
     (select id from meetings where title = 'เรียกพบครูเทสต์วัน'))
    where body = 'คำชี้แจงของครูที่ถูกเรียกพบ'),
  'subject',
  'the teacher''s own statement is tagged as the subject''s, distinctly'
);

select lives_ok(
  $$ select get_meeting_minutes('mtg-teacher1-token',
       (select id from meetings where title = 'เรียกพบครูเทสต์วัน')) $$,
  'the summoned teacher reads the finalised record of their own summons'
);

select is(
  (select count(*)::int from audit_logs
    where entity_type = 'meeting_minutes' and action = 'meeting_minutes.read'
      and user_id = '99822000-0000-0000-0000-000000000003'),
  1,
  'the teacher reading their own summons record is logged (a group meeting''s reads are not, by design)'
);

select is(
  (select count(*)::int from audit_logs
    where entity_type = 'meeting_minutes' and action = 'meeting_minutes.read'),
  1,
  'only the one_on_one read was logged — the group meeting''s finalised-minutes reads earlier are not, by design'
);

select throws_ok(
  $$ select cancel_meeting_minutes('mtg-exec-token',
       (select id from meetings where title = 'เรียกพบครูเทสต์วัน'), 'เหตุผล') $$,
  'forbidden',
  'the director who organised it still cannot void it — only school_admin/super_admin may (this is a check, not the organiser''s call)'
);

select throws_ok(
  $$ select cancel_meeting_minutes('mtg-admin-token',
       (select id from meetings where title = 'ประชุมฝ่ายทดสอบ'), '') $$,
  'reason_required',
  'voiding a record still requires saying why'
);

select lives_ok(
  $$ select cancel_meeting_minutes('mtg-admin-token',
       (select id from meetings where title = 'ประชุมฝ่ายทดสอบ'), 'ประชุมถูกยกเลิกภายหลัง') $$,
  'school_admin voids the group meeting''s record, with a reason'
);

select is(
  (select cancel_reason from meeting_minutes
    where meeting_id = (select id from meetings where title = 'ประชุมฝ่ายทดสอบ')),
  'ประชุมถูกยกเลิกภายหลัง',
  'the text stays in place with the reason attached — cancelled, not deleted'
);

-- ---------------------------------------------------------------------------
-- Resolutions
-- ---------------------------------------------------------------------------

select throws_ok(
  $$ select create_meeting_resolution('mtg-teacher1-token',
       (select id from meetings where title = 'ประชุมฝ่ายทดสอบ'), 'มติทดสอบ') $$,
  'forbidden',
  'a non-organiser cannot record a resolution'
);

select throws_ok(
  $$ select create_meeting_resolution('mtg-admin-token',
       (select id from meetings where title = 'ประชุมฝ่ายทดสอบ'), '  ') $$,
  'body_required',
  'an empty resolution body is refused'
);

select throws_ok(
  $$ select create_meeting_resolution('mtg-admin-token',
       (select id from meetings where title = 'ประชุมฝ่ายทดสอบ'), 'มติทดสอบ',
       '99822000-0000-0000-0000-000000000005') $$,
  'assignee_not_an_attendee',
  'you cannot make someone responsible for a meeting they were never in'
);

select lives_ok(
  $$ select create_meeting_resolution('mtg-admin-token',
       (select id from meetings where title = 'ประชุมฝ่ายทดสอบ'), 'มติทดสอบมอบหมาย',
       '99822000-0000-0000-0000-000000000003', current_date + 7) $$,
  'a real resolution is assigned to a real attendee'
);

select lives_ok(
  $$ select create_meeting_resolution('mtg-admin-token',
       (select id from meetings where title = 'ประชุมฝ่ายทดสอบ'), 'มติทดสอบเลยกำหนด',
       null, current_date - 1) $$,
  'an unassigned, already-overdue resolution is recorded for the overdue check below'
);

select is(
  (select bool_or(type = 'meeting_resolution_assigned' and title = 'ได้รับมอบหมายจากที่ประชุม')
     from notifications where user_id = '99822000-0000-0000-0000-000000000003'),
  true,
  'the assignee is told — a resolution nobody hears about is one nobody acts on'
);

select throws_ok(
  $$ select set_meeting_resolution_status('mtg-teacher2-token',
       (select id from meeting_resolutions where body = 'มติทดสอบมอบหมาย'), 'done') $$,
  'forbidden',
  'someone who is neither the assignee, the organiser, nor an admin cannot close it'
);

select throws_ok(
  $$ select set_meeting_resolution_status('mtg-teacher1-token',
       (select id from meeting_resolutions where body = 'มติทดสอบมอบหมาย'), 'somewhere_else') $$,
  'invalid_status',
  'status is constrained to the three the schema knows'
);

select lives_ok(
  $$ select set_meeting_resolution_status('mtg-teacher1-token',
       (select id from meeting_resolutions where body = 'มติทดสอบมอบหมาย'), 'done') $$,
  'the assignee reports their own resolution done'
);

select is(
  (select is_overdue from list_meeting_resolutions('mtg-admin-token')
    where body = 'มติทดสอบมอบหมาย'),
  false,
  'a done resolution is not overdue even though its due date has not passed yet — status wins'
);

select is(
  (select is_overdue from list_meeting_resolutions('mtg-admin-token')
    where body = 'มติทดสอบเลยกำหนด'),
  true,
  'an open resolution past its due date is overdue'
);

select is(
  (select count(*)::int from list_meeting_resolutions('mtg-teacher1-token', null, true)),
  1,
  'p_mine_only filters to resolutions assigned to the caller'
);

-- ---------------------------------------------------------------------------
-- Attachments
-- ---------------------------------------------------------------------------

select throws_ok(
  $$ select assert_meeting_attachment_upload_access('mtg-teacher3-token',
       (select id from meetings where title = 'ประชุมฝ่ายทดสอบ')) $$,
  'forbidden',
  'someone who cannot see the meeting cannot be given upload access to it'
);

select is(
  (select assert_meeting_attachment_upload_access('mtg-teacher1-token',
     (select id from meetings where title = 'ประชุมฝ่ายทดสอบ'))),
  '99821000-0000-0000-0000-000000000001'::uuid,
  'any real attendee may attach a document, not only the organiser'
);

select throws_ok(
  $$ select register_meeting_attachment('mtg-teacher1-token',
       (select id from meetings where title = 'ประชุมฝ่ายทดสอบ'),
       '99821000-0000-0000-0000-000000000002/wrong-school.pdf', 'x.pdf', 100) $$,
  'invalid_storage_path',
  'a path under another school''s prefix is refused'
);

select throws_ok(
  $$ select register_meeting_attachment('mtg-teacher1-token',
       (select id from meetings where title = 'ประชุมฝ่ายทดสอบ'),
       '99821000-0000-0000-0000-000000000001/a.pdf', '   ', 100) $$,
  'file_required',
  'a blank file name is refused'
);

select lives_ok(
  $$ select register_meeting_attachment('mtg-teacher1-token',
       (select id from meetings where title = 'ประชุมฝ่ายทดสอบ'),
       '99821000-0000-0000-0000-000000000001/minutes-support.pdf',
       'เอกสารประกอบวาระ.pdf', 2048) $$,
  'a real attachment is registered by an attendee'
);

select throws_ok(
  $$ select get_meeting_attachment_for_download('mtg-teacher3-token',
       (select id from meeting_attachments where file_name = 'เอกสารประกอบวาระ.pdf')) $$,
  'forbidden',
  'someone who cannot see the meeting cannot be handed a download URL for it'
);

select is(
  (select file_name from get_meeting_attachment_for_download('mtg-admin-token',
     (select id from meeting_attachments where file_name = 'เอกสารประกอบวาระ.pdf'))),
  'เอกสารประกอบวาระ.pdf'::varchar,
  'the organiser can be handed one'
);

select is(
  (select count(*)::int from list_meeting_attachments('mtg-teacher1-token',
     (select id from meetings where title = 'ประชุมฝ่ายทดสอบ'))),
  1,
  'the attendee sees the attachment in the meeting''s file list'
);

-- ---------------------------------------------------------------------------
-- External attendees — name + organisation, no account
-- ---------------------------------------------------------------------------

select throws_ok(
  $$ select add_meeting_external_attendee('mtg-teacher1-token',
       (select id from meetings where title = 'ประชุมฝ่ายทดสอบ'), 'บุคคลภายนอก') $$,
  'forbidden',
  'a non-organiser cannot add an external guest'
);

select throws_ok(
  $$ select add_meeting_external_attendee('mtg-admin-token',
       (select id from meetings where title = 'ประชุมฝ่ายทดสอบ'), '   ') $$,
  'name_required',
  'a nameless external guest is refused'
);

select lives_ok(
  $$ select add_meeting_external_attendee('mtg-admin-token',
       (select id from meetings where title = 'ประชุมฝ่ายทดสอบ'),
       'ศึกษานิเทศก์ทดสอบ', 'สพม. เขตทดสอบ', 'ศึกษานิเทศก์') $$,
  'a real external guest — name and organisation, nothing else — is recorded'
);

select is(
  (select attended from list_meeting_external_attendees('mtg-admin-token',
     (select id from meetings where title = 'ประชุมฝ่ายทดสอบ'))
    where full_name = 'ศึกษานิเทศก์ทดสอบ'),
  null,
  'attendance for a guest nobody has checked yet is null, not false'
);

select throws_ok(
  $$ select remove_meeting_external_attendee('mtg-teacher1-token',
       (select id from meeting_external_attendees where full_name = 'ศึกษานิเทศก์ทดสอบ')) $$,
  'forbidden',
  'a non-organiser cannot remove an external guest either'
);

-- ---------------------------------------------------------------------------
-- Attendance — one call, one person, once
-- ---------------------------------------------------------------------------

select is(
  (select attended from meeting_attendees
    where meeting_id = (select id from meetings where title = 'ประชุมฝ่ายทดสอบ')
      and user_id = '99822000-0000-0000-0000-000000000003'),
  null,
  'before anyone checks, a real attendee''s attendance is null — not "came", not "absent"'
);

select throws_ok(
  $$ select set_meeting_attendance('mtg-teacher1-token',
       (select id from meetings where title = 'ประชุมฝ่ายทดสอบ'),
       array['99822000-0000-0000-0000-000000000003']::uuid[]) $$,
  'forbidden',
  'a non-organiser cannot take attendance'
);

select lives_ok(
  $$ select set_meeting_attendance('mtg-admin-token',
       (select id from meetings where title = 'ประชุมฝ่ายทดสอบ'),
       array['99822000-0000-0000-0000-000000000003']::uuid[],
       array[(select id from meeting_external_attendees
                where full_name = 'ศึกษานิเทศก์ทดสอบ')]::uuid[]) $$,
  'the organiser checks attendance once'
);

select is(
  (select attended from meeting_attendees
    where meeting_id = (select id from meetings where title = 'ประชุมฝ่ายทดสอบ')
      and user_id = '99822000-0000-0000-0000-000000000003'),
  true,
  'the one marked present is true'
);

select is(
  (select attended from meeting_attendees
    where meeting_id = (select id from meetings where title = 'ประชุมฝ่ายทดสอบ')
      and user_id = '99822000-0000-0000-0000-000000000004'),
  false,
  'everyone else on the meeting is now false — not left null'
);

select is(
  (select attended from meeting_external_attendees
    where full_name = 'ศึกษานิเทศก์ทดสอบ'),
  true,
  'the external guest marked present is true too'
);

select isnt(
  (select attendance_taken_at from meetings
    where title = 'ประชุมฝ่ายทดสอบ'),
  null,
  'the meeting records when attendance was taken'
);

-- ---------------------------------------------------------------------------
-- cancel_meeting / complete_meeting
-- ---------------------------------------------------------------------------

select throws_ok(
  $$ select cancel_meeting('mtg-teacher3-token',
       (select id from meetings where title = 'ประชุมที่จะยกเลิก'), 'ไม่พร้อม') $$,
  'forbidden',
  'an attendee who is not the organiser or an admin cannot cancel'
);

select throws_ok(
  $$ select cancel_meeting('mtg-exec-token',
       (select id from meetings where title = 'ประชุมที่จะยกเลิก'), '') $$,
  'reason_required',
  'cancelling still requires saying why'
);

select lives_ok(
  $$ select cancel_meeting('mtg-exec-token',
       (select id from meetings where title = 'ประชุมที่จะยกเลิก'), 'ห้องประชุมไม่ว่าง') $$,
  'the organiser cancels, with a reason'
);

select is(
  (select status from meetings where title = 'ประชุมที่จะยกเลิก'),
  'cancelled',
  'the status reflects it'
);

select is(
  (select bool_or(type = 'meeting_cancelled') from notifications
    where user_id = '99822000-0000-0000-0000-000000000005'),
  true,
  'the attendee who cleared their timetable for it is told it is off'
);

select is(
  (select count(*)::int from list_meetings('mtg-exec-token', null, null, 'cancelled')),
  1,
  'p_status filters the register to just the cancelled one'
);

select throws_ok(
  $$ select complete_meeting('mtg-teacher3-token',
       (select id from meetings where title = 'ประชุมที่จะปิด')) $$,
  'forbidden',
  'a non-organiser cannot mark a meeting complete'
);

select lives_ok(
  $$ select complete_meeting('mtg-exec-token',
       (select id from meetings where title = 'ประชุมที่จะปิด')) $$,
  'the organiser marks it complete'
);

select is(
  (select status from meetings where title = 'ประชุมที่จะปิด'),
  'completed',
  'the status reflects completion'
);

-- ---------------------------------------------------------------------------
-- Notifications: categorised, and filterable by category
-- ---------------------------------------------------------------------------

insert into notifications (user_id, type, title, body)
values ('99822000-0000-0000-0000-000000000003', 'system_maintenance',
        'แจ้งปิดปรับปรุงระบบ', 'ทดสอบหมวดอื่น');

select is(
  (select public._notification_category('meeting_invite')),
  'meeting',
  'a meeting-prefixed type is categorised as meeting'
);

select is(
  (select public._notification_category('system_maintenance')),
  'other',
  'an unrecognised type falls to other rather than being hidden'
);

select is(
  (select bool_or(category = 'meeting')
     from list_my_notification_categories('mtg-teacher1-token')),
  true,
  'the category listing includes meeting for someone who was actually invited to one'
);

select is(
  (select count(*)::int from list_my_notifications_in_category(
     'mtg-teacher1-token', 'other')),
  1,
  'filtering to ''other'' returns only the one uncategorised notification'
);

select is(
  (select bool_and(category = 'meeting') from list_my_notifications_in_category(
     'mtg-teacher1-token', 'meeting')),
  true,
  'filtering to ''meeting'' never leaks the other-category row in'
);

-- ---------------------------------------------------------------------------
-- Staff calendar — meetings and school_events together
-- ---------------------------------------------------------------------------

insert into school_events (school_id, title, location, start_date, end_date)
values ('99821000-0000-0000-0000-000000000001', 'กิจกรรมทดสอบปฏิทิน', 'สนามโรงเรียน',
        '2027-03-10', '2027-03-10');

select throws_ok(
  $$ select * from list_staff_calendar('mtg-student-token') $$,
  'forbidden',
  'a student has no staff calendar'
);

select is(
  (select bool_or(kind = 'summons' and title = 'เรียกพบครูเทสต์วัน')
     from list_staff_calendar('mtg-teacher1-token')),
  true,
  'a summons appears on the calendar tagged as a summons, not a plain meeting'
);

select is(
  (select bool_or(kind = 'meeting' and title = 'ประชุมฝ่ายทดสอบ')
     from list_staff_calendar('mtg-teacher1-token')),
  true,
  'a group meeting appears tagged as a meeting'
);

select is(
  (select bool_or(kind = 'school_event' and title = 'กิจกรรมทดสอบปฏิทิน')
     from list_staff_calendar('mtg-teacher1-token')),
  true,
  'the existing school_events calendar is merged in, not replaced'
);

rollback;
