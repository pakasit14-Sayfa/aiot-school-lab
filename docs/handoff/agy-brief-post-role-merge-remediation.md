# Brief for agy: remediation plan from the post-role-merge Pre-Mortem/RedTeam

Four items, in priority order. Each has its own "done" criteria — don't
bundle them into one commit, report back after each one so findings (especially
item 1, which could change scope) are caught before you build on top of them.

## 1. 🔴 Verify the SOS/incident scope gap for teachers — do this first

This is a **verification task, not a build task** — don't write any fix
until you've confirmed the gap is real. `create_incident_report` derives
which teachers see a student's SOS via `course_teachers` → `course_students`
→ `student_profiles.room` ("Approach A" from the original incident-reports
design). The suspected gap: a student enrolled in an elective course whose
teacher isn't tied to the student's home room might create an incident that
zero teachers can see.

### Step 1 — reproduce with real data
1. Create a disposable test student with `student_profiles.room` set to
   some room (e.g. `'test-room-A'`).
2. Enroll them in a course whose `course_teachers` entry is a teacher who
   is **not** also teaching any course tied to `'test-room-A'` — i.e. a
   genuine elective-teacher mismatch case.
3. Sign in as that student, call `create_incident_report` for real.
4. Sign in as every teacher in the school, call `list_incident_reports`
   for each, confirm whether **any** of them see the new incident.
5. Clean up the disposable student/course-enrollment/incident afterward.

### Step 2 — if it reproduces (report the exact query/role-gate that's failing before touching anything)

Prepared fallback, so you're not blocked waiting on a design decision if
this confirms broken: add an **on-duty teacher visibility** path —
`list_incident_reports` for role `teacher` should also return incidents
where the caller has an active/general duty flag, independent of the
room-derivation chain. Simplest version: extend the existing school_admin
"sees everything in the school" pattern to a new, narrower on-duty concept
— a boolean or a `duty_teacher_ids` list a school_admin can maintain (new
tiny table, e.g. `incident_duty_teachers(school_id, user_id)`), OR — if
you find the room-derivation just has an incomplete join (missing elective
courses in the join condition) — the simpler fix is likely just widening
that join, not a whole new on-duty concept. Check which one the actual
failure looks like before picking an approach; don't build the on-duty
table if it turns out to be a one-line join fix.

### Step 3 — if it does NOT reproduce
Report that clearly too — a verified-safe finding is still useful, means
this item closes without a code change.

## 2. 🔴 Teacher-side class schedule UI

`set_class_schedule`/`remove_class_schedule` RPCs already exist
(`supabase/migrations/20260818010000_calendar.sql`) but **no Dart service
wrapper exists yet** — checked `packages/shared_core/lib/services/calendar_service.dart`,
it only has `listMySchedule()` (read-only) and the personal-task methods.
This is bigger than "just add a page":

1. Add to `CalendarService`: `setClassSchedule({required courseId, required dayOfWeek, required startTime, required endTime, String? room})` and `removeClassSchedule(String scheduleId)`, wrapping the existing RPCs.
2. New page `teacher_class_schedule_page.dart` in `teacher_redesign_prototype/`:
   list of the teacher's own courses, per-course a simple day/time/room
   form + list of existing schedule entries with delete. Reuse
   `CourseService.listMyCourses()` (or whatever the teacher's existing
   course-listing call is — check `teacher_exam_builder_page.dart` for
   the pattern, it already lists the teacher's own courses) for the
   course picker.
3. Wire into the teacher navigation.

**Verify**: teacher sets a schedule entry for a real course → open the
student app in a separate session for an enrolled student → confirm the
entry shows up in `student_calendar_page.dart`'s real-schedule section,
not just personal tasks.

## 3a. 🟡 Rate-limit on `queue_device_command`

New migration, same pattern as `auth_login_rate_limits`: a
`device_command_rate_limits(device_id, window_started_at, attempt_count,
blocked_until)` table, checked/updated at the top of `queue_device_command`
before the insert into `device_commands`. Pick a reasonable threshold
(e.g. 20 commands/device/minute — this is a relay/pump, not something
that needs rapid toggling) and block with a clean `rate_limited` exception
past that, not a raw error.

**Verify**: script 25 real `queue_device_command` calls against the same
device in quick succession, confirm the ~21st+ call gets `rate_limited`
cleanly, not a raw DB error, and that a legitimate single command still
works before/after the burst.

## 3b. Device ACK/heartbeat — do not build this

Flagging explicitly so it's not silently attempted: this needs real IoT
device firmware changes to report command execution status back, which is
outside app/backend scope entirely — it's a hardware/firmware
conversation, not a coding task for this repo. Leave as-is; the UI's
existing "ยังไม่มีการยืนยันสถานะจริงจากอุปกรณ์กลับมา" disclosure is the
correct honest state for now.

## 4. Parent-teacher messaging — no code, just document it

Add a section to `docs/handoff/HANDOFF.md` (my_first_app): "Parent-teacher
messaging/meeting requests — explicitly deferred when the parent redesign
was built (decision: build attendance/learning visibility first, messaging
later). No RPC, no UI, not started. No target date set — flag to the user
if this comes up as a real ask before picking it up." This is just so it
doesn't quietly disappear as an untracked gap.

## Verify (per item, not all at once)

Same standard as every feature this session: real RPC calls with real
session tokens and/or real browser click-through, not
`flutter analyze`/`flutter test` alone. Report back after each numbered
item before starting the next.
