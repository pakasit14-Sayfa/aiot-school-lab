# Brief for agy: wire real backend into the new Parent/Executive UI

Context: `parent_redesign_prototype/` and `executive_redesign_prototype/`
were fully replaced with the new `parent_portal_split` /
`director_dashboard_flutter` designs (commit `5d0343e`, verified live —
both roles log in and render correctly, 0 console errors). Both are still
100% mock data. This brief is the backend-wiring pass, split into 3 tiers
by how much backend work each page actually needs. Checked what already
exists in the DB/`shared_core` before writing any of this — don't
re-derive schema for things that already have a real RPC.

**Standing rule for this pass**: don't invent a schema/RPC name that
"sounds right" — grep `supabase/migrations/` and
`packages/shared_core/lib/services/` first. Everything cited below is a
real, already-migrated, already-granted function or service method,
verified via `\d`/`information_schema` against the live local DB — not
guessed.

## Tier 1 — direct reuse, no new backend needed

Just wire the page's UI to the existing service call instead of the mock
list/map. No migration required for any of these.

- **`director_overview_page.dart` / `director_dashboard.dart`** (ภาพรวม) —
  this is functionally the same dashboard the old `executive_dashboard_page.dart`
  already had wired before the replacement. Reuse the exact same 5 calls:
  `UserAdminService.countUsersByRole()`, `LessonService.listSchoolDevices()`,
  `IncidentService.getIncidentSummary()`,
  `UtilityService.getEnergyUsageSummary(period: ...)`,
  `UtilityService.getWaterUsageSummary(period: ...)`.
- **`director_environment_page.dart`** — `UtilityService` already has
  everything this page wants: `getEnergyUsageTrend()`, `getWaterUsageTrend()`,
  `getEnergyEfficiencyScore()`, `getWaterEfficiencyScore()`, on top of the
  summary calls above.
- **`director_notifications_page.dart`** — `NotificationService.listMyNotifications()`
  / `markNotificationRead()`. Straight swap, this exists for every role
  already.
- **`parent_dashboard_page.dart` / `parent_learning_page.dart`** (child
  switcher + grades) — `list_my_linked_students(p_token)` and
  `list_my_student_grades(p_token, p_student_id)` RPCs already exist
  (`supabase/migrations/20260824110000_parent_portal_rpcs.sql`, granted to
  `authenticated`) but **have zero Dart callers anywhere in the repo** —
  confirmed via grep, nothing wraps them. Add both to a new
  `packages/shared_core/lib/services/parent_portal_service.dart`
  (`listMyLinkedStudents()` / `listMyStudentGrades(studentId)`), same
  pattern as every other service file, then wire the two pages to it.

## Tier 2 — small new RPC needed, but mirrors an existing pattern exactly

Write the RPC the same way `list_my_student_grades` was written (session
check, role check, then verify an `approved` row in `parent_links` for
that specific student before returning anything) — don't design from
scratch, copy that function's shape.

- **`parent_schedule_page.dart` / `parent_academic_calendar_page.dart`** —
  `CalendarService.listMySchedule()` exists but is the *caller's own*
  schedule (works for a student calling about themselves). A parent needs
  their child's schedule instead. Add
  `list_my_student_schedule(p_token, p_student_id)` — same
  `parent_links` approved-check as `list_my_student_grades`, then join
  `class_schedules` → `courses` → `course_students` for that student.
  `class_schedules`/`set_class_schedule` already exist
  (`supabase/migrations/20260818010000_calendar.sql` per earlier session
  work) — this is a read-only addition on top of that.
- **`director_classrooms_page.dart`** (ห้องเรียนและรายวิชา) — this is a
  school-wide rooms/courses/assignment-load overview, not per-child. Real
  tables already exist (`rooms`, `courses`, `assignments`) — needs one new
  aggregate RPC scoped to `executive`/`school_admin`
  (`get_classrooms_overview(p_token)` or similar: room count, student
  count per grade band, assignments-due-this-week count). Check
  `list_course_quizzes`/`get_incident_summary` for the aggregate-query
  style already used elsewhere in this codebase before writing it.
- **`director_academic_calendar_page.dart`** — same `class_schedules`
  table, but executive needs a *read-only, all-courses* view, not the
  teacher/school_admin-scoped `set_class_schedule`. Add
  `list_all_school_schedules(p_token)` gated to `executive`/`school_admin`
  only, no write capability from this role.

## Tier 3 — genuinely new product scope, no backend, no UC found

Checked `information_schema.tables` and the UC vault — none of these have
*any* existing table or spec to build against. Don't design schema for
these yet. Same rule this session already applied to the calendar
feature earlier (`agy-brief` history, plan file `memoized-wiggling-bubble.md`):
when there's no UC and it's new scope, flag it and get product
confirmation on the actual workflow before writing migrations, don't
invent one from what the mock UI happens to show.

- **`parent_attendance_page.dart`** — there is no attendance/check-in
  table anywhere in the schema (checked: no `attendance`, `check_in`,
  `checkin` table exists). The mock shows a daily check-in/check-out
  timestamp ("เข้าโรงเรียน 07:41 u.") — where would that timestamp
  actually come from in reality? A kiosk scan? A teacher taking roll?
  Needs a real answer before any table gets designed.
- **`parent_messages_page.dart`** — no chat/messaging table exists at
  all. This is a real two-way parent↔teacher messaging feature, not a
  small add-on — needs its own UC-style spec (who can message whom, is it
  moderated, does it notify) before schema.
- **`director_meetings_page.dart`** (ประชุม/ขอพบ, incl. the teacher-picker
  dialog verified working in the browser test) — no meetings/scheduling
  table exists. Same as above, real new feature needing a spec pass
  first, not just a table.
- **`director_cctv_page.dart`** — `camera_access_grants` table already
  exists (who is allowed to view which `devices` camera, granted by
  whom, valid window) — that part **is** real and wireable (list/grant/
  revoke access). But there is no actual video streaming backend
  anywhere in this system. Wire the access-grant management half for
  real; the live-video-feed half of this page cannot be backed by
  anything that exists — flag it back rather than faking a video player
  against nothing.
- **`director_scan_page.dart`** — reads "สแกน QR/Barcode สำหรับสแกนครู-
  บุคลากร และชุดฝึก/อุปกรณ์" (scanning staff badges + equipment kits).
  This is **not** the existing student kiosk-pairing flow
  (`check_terminal_pairing_status` is for student terminal pairing only,
  wrong shape for this) — it's staff check-in + equipment/asset tracking,
  neither of which has any backing table. New scope, flag before
  building.
- **`director_reports_page.dart`** — a catalog of 10 report types. Some
  map cleanly to data that already exists (attendance summary — blocked
  on the Tier-3 attendance gap above; safety/incident report → real via
  `get_incident_summary`/`list_incident_reports`; utility report → real
  via `UtilityService`; environment report → real via `UtilityService`
  trend endpoints). Others have no backing data at all and aren't small:
  "รายงานงบประมาณและค่าใช้จ่าย" (budget/expenses — no financial tables
  exist anywhere), "รายงานผลการปฏิบัติงานครู" (staff performance
  reviews — no such table), "สรุปผลการประชุมฝ่ายบริหาร" (meeting
  minutes — depends on the meetings feature above existing first),
  "แผนดำเนินงาน IT" (IT roadmap — not really a data-backed report at
  all, more of a static document). Wire the ones with real data sources
  first; flag the rest back rather than mocking numbers that look real.

## Not covered here

`director_teachers_page.dart` and `director_emergency_page.dart` need a
closer look before I write their spec — `director_emergency_page.dart`
in particular: `get_incident_summary` (which the old executive dashboard
already used) only returns **aggregate counts by category, no
room/student identifiers, by design** (PDPA — checked the RPC directly).
The detailed per-incident inbox RPC (`list_incident_reports`) is
**hard-restricted to `teacher`/`school_admin` only** — `executive` is not
in its role check. If the new emergency page wants incident-level detail
(not just totals), that's an access-control decision (should executive
see individual incidents?), not a plumbing task — ask before extending
that RPC's allowed roles. Will follow up with a separate brief once I've
looked at what `director_teachers_page.dart` actually needs from staff
data.

## Verify (same discipline as every wiring pass this session)

Real login, real data, not `flutter analyze`/`flutter test`:
- Parent tier: log in as `parent@aiot-school-lab.local`, confirm the
  child switcher shows the real linked student, grades/schedule match
  what's actually in `grades`/`class_schedules` for that student — not
  just that *something* renders.
- Executive tier: log in as `executive@aiot-school-lab.local` (needs OTP
  — `dev_otp_code` comes back in the `auth-sign-in` response body locally),
  confirm dashboard numbers match a direct `psql` count of the same
  tables, not just that the cards aren't empty.
