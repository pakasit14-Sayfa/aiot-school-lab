# Brief for agy: `parent_attendance_page.dart` still has 3 spots of leftover mock, contradicting the real data above them

Verified live: logged in as parent, opened "การมาเรียน". The top status
badge correctly says **"ยังไม่มีประวัติการเช็คชื่อวันนี้"** (real, wired
correctly to `_attendanceRecords`) — but scrolling down hits sections
that still show fully fabricated data, directly contradicting that badge.
This is the same "some of the page is real, most of the visible content
still isn't" pattern from the very first pass on this app back when
`parent_dashboard_page.dart` had a hardcoded GPA fallback — same fix
needed here, in 3 places this time.

## 1. `_buildTodayTimeline()` — 100% hardcoded, not connected to anything

```dart
Widget _buildTodayTimeline() {
  const timeline = [
    _TimelineItem(time: '07:41', title: 'เข้าโรงเรียน', ...),
    _TimelineItem(time: '08:26', title: 'ถึงอาคารเรียน', ...),
    _TimelineItem(time: '08:30', title: 'เข้าเรียนคาบแรก', detail: 'ภาษาไทย · ห้อง ม.2/1', ...),
    _TimelineItem(time: '09:30', title: 'คาบปัจจุบัน', detail: 'คณิตศาสตร์ · กำลังเรียน', ...),
  ];
```

No `if`, no empty check, no reference to `_attendanceRecords` at all —
always renders these exact 4 fake timestamps regardless of what's
actually in the database. This is the specific pattern the original
brief said not to build: a fabricated arrival-clock-time
("เข้าโรงเรียน 07:41") that doesn't correspond to anything
`attendance_records` actually stores (the schema only has per-period
`present`/`late`/`absent`/`excused` + `marked_at` = when the *teacher*
clicked the button, not when the student walked in).

**Fix**: there's no real backend concept this timeline can honestly
map to — don't try to synthesize one from `marked_at` timestamps (that
would just be a different flavor of the same fabrication). Either
remove this section, or replace it with something the data actually
supports: today's per-period statuses from `_attendanceRecords` filtered
to `class_date == today`, shown as a simple list (course name → status),
not a clock-time narrative.

## 2. `_buildClassAttendanceCard()` / `classAttendance` — same problem, but this one *should* just be wired

```dart
final List<_ClassAttendance> classAttendance = const [ ... ];
```

Also hardcoded, also unconditional. Unlike the timeline above, this
section ("การเข้าเรียนแต่ละคาบวันนี้" — today's per-period attendance)
maps directly to real data that already exists: filter
`_attendanceRecords` to today's `class_date` and render those. This one
just needs actual wiring, not a redesign.

## 3. `_buildHistoryCard()` — silently fakes history when there's no real data yet

```dart
final displayHistory = _attendanceRecords.isNotEmpty
    ? _attendanceRecords.map((rec) => ...).toList()
    : history;   // <- hardcoded const list with fake dates/times, e.g. "21 ส.ค. 2569" checkIn "07:41"
```

The real-data branch is correct and fine. The problem is the fallback:
when a real student genuinely has zero attendance records (true right
now for the seeded test student, and true for real students before
their first day gets marked), this silently shows fabricated historical
entries with plausible-looking dates and times instead of an honest
empty state. Replace the `: history` fallback with a proper empty state
(e.g. "ยังไม่มีประวัติการมาเรียน" — same honest-empty-state pattern
already used correctly for the top status badge and for
`ConsentPolicyAdminPage`'s "ยังไม่มี Consent Policy ของโรงเรียน").
Delete the unused `history` const list entirely once nothing references
it — don't leave dead mock data sitting in the file for the next person
to accidentally wire back in.

## Separate, smaller thing found in the same pass: RPC error handling

Not part of this page, but found while testing it — all 6 RPCs in
`20260824130000_attendance_and_cctv_rpcs.sql` (`mark_attendance`,
`list_course_attendance`, `list_my_student_attendance`,
`list_camera_access_grants`, `grant_camera_access`,
`revoke_camera_access`) use:

```sql
v_actor := get_session_actor(p_token);
```

`get_session_actor` is a `RETURNS TABLE(...)` function — when the token
is invalid/expired, it returns **zero rows**, which leaves `v_actor`
unassigned. Confirmed live: calling any of these 6 with a garbage token
returns `HTTP 500` with `"record \"v_actor\" is not assigned yet"` —
leaking an internal Postgres error instead of the clean
`invalid_session` every other RPC in this codebase returns for the same
case. Not a data-exposure bug (nothing leaks, it just errors), but
inconsistent and leaks implementation detail. Fix: same pattern as
every other RPC —

```sql
select * into v_actor from get_session_actor(p_token);
if not found then raise exception 'invalid_session'; end if;
```

Copy this exact fix into all 6 functions in that migration file (new
migration, don't edit the already-applied one — same rule as always).

## Verify

Real browser, real login as `parent@aiot-school-lab.local`:
1. Student with zero attendance records today → today's-timeline section
   shows real (or removed) content, not the 07:41/08:26/08:30/09:30 fake
   sequence; history card shows an honest empty state, not fake dated
   entries.
2. Have a teacher mark a real attendance record for today via
   `mark_attendance`, reload the parent page → today's per-period card
   and history card both reflect it.
3. Re-run the invalid-token probe on all 6 RPCs, confirm clean
   `invalid_session` / `403`-equivalent instead of `HTTP 500`.
