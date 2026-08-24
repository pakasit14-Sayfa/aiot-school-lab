# Brief for agy: wire the actual pages — backend exists but nothing calls it yet

Verified the Tier 1/2 backend work live: the 3 new RPCs
(`list_my_student_schedule`, `get_classrooms_overview`,
`list_all_school_schedules`) and the 2 already-existing ones
(`list_my_linked_students`, `list_my_student_grades`) are all correct and
secure — real data, correct role gating, correct `parent_links`
ownership check, verified with real curl calls against real seeded data,
not just the pgTAP suite. `ParentPortalService`/`ExecutiveService` wrap
them correctly too. **None of that is the problem.**

The problem: grepped every page under `parent_redesign_prototype/` and
`executive_redesign_prototype/` for `Service.`/`supabase.`/`.rpc(` —
**zero matches, everywhere.** Not one page calls `ParentPortalService` or
`ExecutiveService`, and none of the *already-existing* services
(`UserAdminService`, `LessonService`, `IncidentService`, `UtilityService`,
`NotificationService`) that the Tier-1 brief said to reuse got wired
either. The last report said this work was "เสร็จสมบูรณ์แล้ว" — the
backend layer is, but the app still shows 100% mock data end to end.
This brief is just the wiring pass, in one place, all remaining pages.

## Parent pages

- **`parent_dashboard_page.dart`** — currently a `StatelessWidget`, no
  `initState`, all data passed inline in `build()`. Needs converting to
  `StatefulWidget` first (same async-load-in-initState pattern as every
  other real page in this app), then: `ParentPortalService.listMyLinkedStudents()`
  for the child switcher, `ParentPortalService.listMyStudentGrades(studentId)`
  for GPA/grade-based cards. Attendance/environment-sensor cards on this
  page are Tier 3 (no backend, see the earlier brief) — leave those mock,
  don't touch.
- **`parent_learning_page.dart`** (already `StatefulWidget`) —
  `listMyStudentGrades(studentId)`, same call as above, once a child is
  selected.
- **`parent_schedule_page.dart`**, **`parent_academic_calendar_page.dart`**
  (both already `StatefulWidget`) — `ParentPortalService.listMyStudentSchedule(studentId)`.
  Both pages want the same data (weekly class schedule), just check
  whether they're actually two different views of it or the same list
  filtered differently before writing the fetch twice.

All three parent pages need the child (`studentId`) selected somewhere
first — `listMyLinkedStudents()` should probably live one level up
(`ParentNavigationShell` or a shared state holder) so the selected child
persists across tabs instead of every page re-picking independently.
Check how the shell currently passes state between tabs (`parent_navigation_shell.dart`)
before deciding where this lives.

## Executive pages

- **`director_overview_page.dart`** — this is the page actually shown by
  `director_navigation_shell.dart` for the "ภาพรวม" tab (`import '../pages/director_overview_page.dart' as overview;`,
  used at both call sites in the shell). Wire the 5 calls from the old
  (pre-replacement) `executive_dashboard_page.dart`:
  `UserAdminService.countUsersByRole()`, `LessonService.listSchoolDevices()`,
  `IncidentService.getIncidentSummary()`,
  `UtilityService.getEnergyUsageSummary()`, `UtilityService.getWaterUsageSummary()`.
  **Don't bother with `director_dashboard.dart`** — checked the shell's
  imports, that file is never referenced anywhere, it's dead code left
  over from the source project, same as `school_simple_page.dart` was
  earlier this session.
- **`director_environment_page.dart`** — `UtilityService.getEnergyUsageTrend()`,
  `getWaterUsageTrend()`, `getEnergyEfficiencyScore()`, `getWaterEfficiencyScore()`,
  plus the two summary calls above.
- **`director_notifications_page.dart`** — `NotificationService.listMyNotifications()` /
  `markNotificationRead()`.
- **`director_classrooms_page.dart`** — `ExecutiveService.getClassroomsOverview()`.
- **`director_academic_calendar_page.dart`** — `ExecutiveService.listAllSchoolSchedules()`.

## The other thing from last time: the flaky widget test

`apps/user_app/test/school_admin_dashboard_test.dart` — I ran it myself
and it fails (`find.text('รายงาน ESG')` finds 0 widgets on the 3rd drawer
reopen). I also verified the actual production code in a real browser
(headless Chromium, real login, real clicks) and it works correctly —
all 4 drawer items show the right snackbar/close behavior with 0 console
errors. So this looks like a test-harness timing issue (possibly the
`SnackBar`'s 2-second duration interacting with `scaffoldState.openDrawer()`
being called again too soon, or a stale `ScaffoldState` reference — same
family of issue as the `03_auth_session_rate_limit.test.sql` bug from
earlier this session), not a product bug. Either fix the test's timing/
reopening approach, or if you can't pin it down quickly, leave a comment
noting it's a known-flaky harness issue and move on — don't spend a long
time chasing a test bug when the underlying feature is already verified
correct.

## Verify

Same as always — real login, real data, not `flutter analyze`/`flutter test`:
- Log in as `parent@aiot-school-lab.local`, confirm the child switcher
  shows the real linked student (not a mock name), confirm grades/
  schedule shown match a direct `psql` query against `grades`/
  `class_schedules` for that exact student — not just that cards aren't
  empty.
- Log in as `executive@aiot-school-lab.local` (OTP needed —
  `dev_otp_code` in the `auth-sign-in` response body locally), confirm
  every number on ภาพรวม/สิ่งแวดล้อม/ห้องเรียนและรายวิชา matches a direct
  count from the DB, not a plausible-looking number.
