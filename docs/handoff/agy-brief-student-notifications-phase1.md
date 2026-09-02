# Brief for agy: student notifications, phase 1 — 3 real trigger points

Found during a student notification-mechanism audit (2026-08-31, see
[[aiot-school-lab-app]] for the broader session context): the student
notification pipeline (`NotificationService.listMyNotifications()` →
`list_my_notifications` RPC → `notifications` table) is **100% correctly
wired** — real, scoped, no fake data in the plumbing itself. The problem
is upstream: **grep of every migration confirms exactly one code path
in the entire backend ever inserts into `notifications`**
(`create_incident_report`, and per today's earlier fix, it only targets
`teacher`/`school_admin`/`executive` — never a student). No feature
anywhere ever creates a notification *for* a student. Their inbox is
real but permanently empty by construction, not by bug.

**Two RPC names in the original ask were close but not exact** — verified
against the actual migrations, use these:

- ~~`submit_grade`~~ → **`confirm_grade(p_token, p_grade_id)`**
  (`supabase/migrations/20260730010000_grades_core.sql:136`) — sets
  `grades.status = 'confirmed'`, the real moment a grade becomes final.
- ~~`close_assignment`~~ → **`publish_assignment(p_token, p_assignment_id)`**
  (`supabase/migrations/20260731000000_assignments_core.sql:94`) — the
  real moment an assignment becomes visible to students (assignments
  start `status = 'draft'`).
- `upload_lesson_material` was roughly right — the real function is
  **`add_lesson_material(p_token, p_lesson_id, p_type, p_title, p_url,
  p_sort_order)`** (`supabase/migrations/20260724000000_classroom_core.sql:538`).
  There's also **`publish_lesson(p_token, p_lesson_id)`** (line 506,
  same file) — probably the better trigger point than material-add,
  since a lesson can gain several materials while still in `draft` and
  invisible to students; a notification per material-add could spam.
  Decide which one actually represents "new content became visible" —
  likely `publish_lesson`, but confirm by checking whether a lesson can
  receive materials after it's already published (if so, material-add
  on an *already-published* lesson might also deserve its own
  notification — read `update_lesson`/`add_lesson_material`'s current
  behavior before assuming).

## Scope for this phase — 3 triggers, not a general notification framework

1. **Grade confirmed** → notify `grades.student_id` (single student, no
   join needed) when `confirm_grade` runs.
2. **Assignment published** → notify every student in
   `course_students` for that `assignments.course_id`, when
   `publish_assignment` runs.
3. **Lesson published** (or material added to an already-published
   lesson — see above) → same `course_students` join on
   `lessons.course_id`.

For (2) and (3), the exact "loop over course_students, insert one
notification per row" pattern already exists as a real, working
reference — it's the pattern `create_incident_report` used *before*
today's broadcast-to-everyone fix (see
[[aiot-school-lab-sos-broadcast-fix]] for why it was widened for
incidents specifically — that reasoning does **not** apply here,
grades/assignments/lessons should stay narrowly targeted to the actual
enrolled students, don't broadcast school-wide). Check `git log -p` on
`supabase/migrations/20260826035000_widen_incident_teacher_visibility.sql`
if you want the exact join shape as a starting template
(`course_students cst ... where cst.course_id = ...`).

## `type` field — fix the existing mismatch while you're in this area

`student_navigation_prototype.dart`'s `_iconForNotification()`
(around line 84) switches on `case 'incident':` but the real value
inserted by `create_incident_report` is `'incident_report'` — they've
never matched, so incident notifications always fall through to the
generic megaphone icon instead of the intended warning icon. Fix the
case label to `'incident_report'`. While adding the 3 new triggers
above, pick clear `type` values for them (suggest `'grade_confirmed'`,
`'assignment_published'`, `'lesson_published'`) and extend this same
switch (and any equivalent icon-mapping in other roles' notification UI
if one exists by then) to cover them with sensible icons — don't leave
new types falling through to the generic default the way `incident`
did.

## Separate, more urgent bug in the same file — fix this too, don't skip it

`notifications_page.dart` (`_buildNotificationList()`, line ~163-166):

```dart
final displayItems = notifications.isNotEmpty
    ? notifications
    : _getDemoNotifications();  // 4 hardcoded fake notifications incl. a fake "92/100" exam score
```

No disclosure badge, nothing — every student with an empty (i.e. every
student, until this brief ships) inbox currently sees 4 fully-invented
notifications with zero indication they're fake. This is unrelated to
the 3 triggers above but was found in the same audit and is worse in
severity (an honesty bug affecting 100% of students right now, not a
missing feature). Delete `_getDemoNotifications()` and its usage
entirely — show the existing honest `_buildEmptyState()` when the real
list is empty, same as the bell-icon dropdown preview elsewhere in this
same page family already does correctly (`student_navigation_prototype.dart`'s
`_showGlassNotificationModal`, shows "ยังไม่มีการแจ้งเตือน" honestly —
use that as the reference for what "empty" should look like here too).

## Verification bar

Same as every closed brief in `WORK_LOG.md` — see
[[aiot-school-lab-app]] methodology doc at
`docs/handoff/DATA_CONNECTION_METHODOLOGY.md` for the full checklist.
Specifically for this brief: live-test each of the 3 triggers against a
real seeded student+course+grade/assignment/lesson, confirm a real row
lands in `notifications` with the right `user_id`(s), confirm the
student's bell/inbox actually shows it, clean up test data after.

## Update on completion

Move this brief from "In progress" to "Done" in `WORK_LOG.md` with the
closing commit hash, per `CLAUDE.md`'s "Keeping this current" rule.
