# Brief for agy: silent fake-data fallbacks across school_admin Phase 2 pages

## Why this brief exists

The user spotted a mobile screenshot of the new school_admin home page
showing "1,250 นักเรียนทั้งหมด, 86 ครูและบุคลากร, 6/42 อาคาร/ห้อง, 154/18
อุปกรณ์" — numbers that don't exist anywhere in the real seeded DB (real
counts: 1 student, 1 teacher, 0 buildings, 9 devices). I traced this to
code, then audited every Phase 2 page for the same pattern. It's
systemic, not a one-off: **7 of the 13 redesigned pages silently show
hardcoded mockup data — sometimes as an error fallback, sometimes
permanently — with zero visual indication it isn't real.** A school_admin
using this app today cannot tell fake numbers from real ones just by
looking.

## The pattern, and why it's worse than a normal bug

Two variants, both root-caused:

**Variant 1 — silent catch + fake fallback on error.** `try { await
real_fetch(); ... } catch (_) {}` — any failure (expired session, network
blip, RPC error) is swallowed with no user-visible state, and whatever
was already in the widget (often a hardcoded mock initializer) just stays
on screen looking like real data.

**Variant 2 — `if (data.isNotEmpty)` gating the replace.** The fetched
real data only overwrites the hardcoded mock list *if it's non-empty*.
This means a **genuinely correct empty result** (e.g. a school that really
has 0 buildings yet) is treated identically to a failed fetch — the fake
mock rows stay forever, because "0 real buildings" never satisfies
`isNotEmpty` and the mock never gets cleared. This isn't even
error-triggered; it's wrong on the happy path.

**Do not fix this by making the fallback numbers look more "realistic"
or removing the try/catch.** Fix it by making the three real states —
loading, error, genuinely-empty — visually distinct from each other and
from populated real data. This codebase already has the right pattern
elsewhere: HANDOFF.md documents that G-Score has no backend at all for
teacher/student "and the UI says so directly rather than faking numbers."
Match that standard everywhere below.

## Tier A — real backend already exists, fix is UI-only

These already call a working RPC (`fetchDashboardSummary`,
`fetchBuildings`, `fetchRooms`, `fetchAuditLogs`, `listSchoolAlerts`,
`listSchoolDevices`, `getAllUsers`) — the backend is fine, only the
display logic around loading/error/empty needs fixing.

- **`school_admin_dashboard_page.dart`** (`_HomeSummaryGridState`,
  ~line 1042-1098): remove the `: '1,250'` / `: '86'` / `: '6 / 42'` /
  `: '154 / 18'` literals. Add a real loading flag (`_loading = true` in
  `initState`, set false after `_loadSummary()` resolves either way).
  While loading: skeleton/shimmer or `--`. On error (catch block currently
  empty): set an `_error` flag, show a small inline "โหลดข้อมูลไม่สำเร็จ"
  with a retry button, not fake numbers. Zero real counts render as `0`,
  not as an error state.
- **`school_buildings_page.dart`** (~line 26-72): same
  loading/error/empty split for both `_buildings` and `_rooms`. Critically,
  **remove the `if (buildings.isNotEmpty)` / `if (rooms.isNotEmpty)`
  guards** — replace with unconditional `_buildings = buildings;` (or
  clear-and-repopulate) once the fetch *completes*, regardless of length.
  An empty real result should render as an empty-state illustration
  ("ยังไม่มีอาคารในระบบ" + a way to add one), not as 3 fake buildings named
  after people who don't exist.
- **`school_admin_profile_page.dart`** (`_loadLogs`, ~line 58-85),
  **`school_reports_page.dart`** (`_loadReportData`, ~line 25-43),
  **`school_settings_page.dart`** (`_loadSettings`, ~line 65-92),
  **`school_alerts_page.dart`**, **`school_devices_page.dart`**,
  **`school_permissions_page.dart`**, **`school_import_page.dart`**
  (all have a secondary `_logs`/activity-log list following this exact
  pattern): remove the `isNotEmpty` gate on the logs replace, same as
  buildings/rooms. An admin with zero real audit log entries yet should
  see "ยังไม่มีกิจกรรม" — not a fabricated "เข้าสู่ระบบผ่านระบบกลาง" entry
  timestamped "วันนี้ 09:20 น." that never happened.

## Tier B — no backend exists at all yet, this is a product-scope question, not a quick fix

Checked `pg_proc` directly — there is **no RPC for school settings,
extended admin-profile fields, or generated reports**. Don't invent a
schema and RPC for these silently as part of a "just fix the fallback"
pass — that's a bigger decision than this brief covers. For now, apply
the same G-Score-style honest disclosure instead of deleting the feature
or leaving it fake:

- **`school_settings_page.dart`**: `_phoneController`, `_addressController`,
  `_directorController`, and all 13 boolean toggles
  (`_emailNotifications`, `_deviceOfflineAlert`, etc.) + 3 numeric
  thresholds (`_autoLogoutMinutes`, etc.) are permanently hardcoded, never
  fetched, and — check this — **confirm whether "save" actually persists
  them anywhere or just calls `setState` locally**. If there's no real
  persistence either, add a visible "การตั้งค่านี้ยังไม่เชื่อมระบบหลังบ้าน
  จะไม่ถูกบันทึกจริง" notice rather than letting an admin believe they
  changed a real setting.
- **`school_admin_profile_page.dart`**: phone/employee-code/position/
  department fields — same treatment, or wire them to real `users` table
  columns if those columns already exist (check schema first — office
  phone/position may genuinely not have columns yet, in which case this
  is Tier B too, not a quick wire-up).
- **`school_reports_page.dart`**: the `_recent` "4 downloadable reports"
  list (PDF/Excel, "พร้อมดาวน์โหลด") is 100% fake — no report-generation
  or storage backend exists. Don't leave a "ready to download" button that
  produces nothing. Either disable/hide this section with an honest
  "ระบบสร้างรายงานยังไม่พร้อมใช้งาน" notice, or flag back if you think a
  minimal real version (e.g. server-side CSV export of already-real data
  like the buildings/devices list) is small enough to build now — don't
  build it without confirming scope first.

## What NOT to do

- Don't just delete the mock data and leave blank space with no
  loading/empty/error handling — that trades one bad UX for another.
- Don't silently build new backend/RPCs for the Tier B items without
  flagging back — that's new scope, not a bugfix.
- Don't touch Batch 1's *primary* data paths (students/teachers/alerts/
  devices/permissions/import main lists) — those are already verified
  real and working; this brief is only about the secondary log panels and
  the Tier A/B items listed above.

## Verify

For each Tier A page: force a real empty state (a school/course with
genuinely zero of the relevant records — the real seeded school already
has 0 buildings, use that) and confirm it renders an honest empty state,
not fake rows. Then force a real fetch failure (revoke the session token
mid-load, or similar) and confirm it renders an honest error state, not
fake rows either. Real populated data should still render correctly
(regression-check against Batch 1's already-verified pages). For Tier B:
confirm the disclosure text actually appears and doesn't look like a
real, working feature. `flutter analyze` clean, `flutter test` clean.
