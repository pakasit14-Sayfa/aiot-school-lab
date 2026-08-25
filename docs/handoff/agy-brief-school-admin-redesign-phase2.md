# Brief for agy: school_admin redesign — Phase 2 (13 pages)

## 🔴 Fix these 2 things before Batch 1 is actually done — found during independent re-verification 2026-08-25

**1. All 4 new RPCs in `20260826100000_school_admin_redesign_phase2_alerts.sql`
had the "unassigned record" bug** — `v_actor := get_session_actor(p_token)`
(direct assignment) instead of `SELECT INTO ... IF NOT FOUND`, causing a
raw `record "v_actor" is not assigned yet` Postgres error on any invalid
token instead of a clean `invalid_session`. **Already fixed directly**
(re-applied the migration with the standard `SELECT * INTO v_actor FROM
get_session_actor(p_token); IF NOT FOUND THEN RAISE EXCEPTION
'invalid_session'; END IF;` pattern every other RPC in this codebase
uses) — no action needed on this one, just flagging so the same mistake
doesn't repeat in Batch 2. **Always probe with a garbage/invalid token,
not just a valid one** — a happy-path-only test won't catch this class
of bug, which is exactly how it slipped through here.

**2. None of the 7 Batch 1 pages are reachable from the real app.**
`school_admin_dashboard.dart` has no drawer/menu entry pointing to any
of `school_students_page.dart`, `school_teachers_page.dart`,
`school_permissions_page.dart`, `school_import_page.dart`,
`school_alerts_page.dart`, `school_resources_page.dart`,
`school_devices_page.dart` — confirmed via grep, and `main.dart` has no
routes for them either. The backend wiring is correct, but a logged-in
school_admin cannot open any of these pages today. **Before doing
anything else**: wire drawer + menu entries for all 7 into
`school_admin_dashboard.dart`.

**Open question to answer, don't guess**: `school_devices_page.dart` (new
design) covers device inventory — `school_admin` already has
`school_admin_device_control_page.dart` and
`school_admin_device_schedule_page.dart` live today, covering overlapping
ground. Decide: does the new page **replace** one/both of those (per the
"old-UI-file policy" in `HANDOFF.md` — delete the old one once the new
one is verified live), or does it **sit alongside** them as a separate
inventory view? Flag back with your read of the two designs' actual
scope rather than picking one silently — this determines whether old
files get deleted as part of this batch or stay untouched.

Source design: `/Users/sayfa/Downloads/อันใหม่ /AIOT_SCHOOL_ADMIN_NEW/lib/pages/school_admin/`
(a cleaned, school_admin-only copy — same content as the school_admin
subset of `/Users/sayfa/Downloads/aiot_dev_dashboard`, just without the
dev/super_admin files mixed in). 13 files, confirmed **0% backend calls,
100% hardcoded UI** in an earlier full audit: `school_admin_dashboard_page.dart`,
`school_admin_profile_page.dart`, `school_alerts_page.dart`,
`school_buildings_page.dart`, `school_devices_page.dart`,
`school_import_page.dart`, `school_permissions_page.dart`,
`school_reports_page.dart`, `school_resources_page.dart`,
`school_scan_page.dart`, `school_settings_page.dart`,
`school_students_page.dart`, `school_teachers_page.dart`.

## Read this before starting — most of this is reuse, not new work

That earlier audit checked the mockup files in isolation and correctly
found zero backend calls *in those files* — but it didn't cross-check
against what `my_first_app` **already has** under different page names.
It has a lot. Checked this myself before writing this brief:

| New-design page | Reuse this instead of building new |
|---|---|
| `school_students_page.dart` / `school_teachers_page.dart` | `list_school_users(p_token)` (already wrapped in `UserAdminService`, used by the existing "จัดการผู้ใช้" page) — filter client-side by role, or add a `p_role` param if you'd rather filter server-side. Don't design a new students/teachers table or RPC. |
| `school_permissions_page.dart` | `update_user_role` / `add_secondary_role` / `count_school_users_by_role` — all exist and are exactly this domain. |
| `school_import_page.dart` | `import_school_users_batch(p_school_id, p_role, p_users jsonb)` already exists and takes exactly the shape a CSV-import feature needs (parse client-side, build the jsonb array, call it). The mockup's "no real upload capability" gap is likely just missing UI wiring to this, not a missing RPC. |
| `school_alerts_page.dart` | **Partial reuse only, and read this carefully before touching `acknowledge_sensor_alert`/`resolve_sensor_alert`.** There is **no RPC or service method that lists `sensor_alerts` for a school** — checked directly against `pg_proc` and grepped every service in `shared_core`, confirmed zero results. `IncidentService.listSchoolAlerts()` does not exist. You need one new, small RPC: `list_school_alerts(p_token, p_status default null)` — role-gate `school_admin`/`super_admin`, tenant-scoped via `devices.school_id` (same join pattern `list_schools_for_super_admin` already uses).<br><br>**The existing `acknowledge_sensor_alert(p_alert_id uuid)` / `resolve_sensor_alert(p_alert_id uuid, p_note text)` do NOT take `p_token` — checked their bodies, they use `auth.uid()`/`is_super_admin()`/`has_role()`/`current_user_school_id()`. This is not a bug or something to "fix" — they belong to the separate, deliberate Supabase-Auth-based security model built for `aiot_dev_dashboard` (see `HANDOFF.md`'s "Exception, added 2026-08-22" note). Do NOT add a `p_token` overload to these two functions** — `aiot_dev_dashboard` calls them for real today; changing their signature or behavior risks breaking that app. Instead, **write two new, separately-named functions** for `my_first_app`'s own use, following the `_for_super_admin` naming Phase 1 already established — e.g. `acknowledge_sensor_alert_for_school_admin(p_token, p_alert_id)` / `resolve_sensor_alert_for_school_admin(p_token, p_alert_id, p_note)` — same `get_session_actor(p_token)` auth pattern as every other RPC in this codebase, same underlying `UPDATE public.sensor_alerts` logic, just authenticated the `my_first_app` way instead of via `auth.uid()`. Add `listSchoolAlerts()` / `acknowledgeSensorAlert()` / `resolveSensorAlert()` wrappers for these three new RPCs to `IncidentService` (don't create a new service file). |
| `school_resources_page.dart` | `get_school_utility_rates` / `set_school_utility_rates` + the existing `UtilityService` already powering `school_admin_energy_page.dart` and `school_admin_esg_page.dart` — likely the same underlying data, different presentation. |
| `school_devices_page.dart` | `list_school_devices` (same RPC already used by `school_admin_device_control_page.dart`/`school_admin_device_schedule_page.dart`) — this new page may just be a different table/list view over devices `my_first_app` already fully manages. Check whether it needs to be a new page at all, or whether the 3 existing device-related school_admin pages already cover this and the new design is just a nicer inventory list on top of the same data. |
| `school_buildings_page.dart` | `get_classrooms_overview(p_token)` exists — check what it actually returns before assuming a new `buildings`/`rooms` domain is needed from scratch; there's also a `20260824080000_buildings_and_rooms.sql` migration already in the schema. |

**Before writing any new RPC for any of these 7, check the existing
one's real return shape and confirm whether it already covers what the
new page's UI needs.** Only design something new if there's a genuine
gap after checking — don't assume "the mockup was empty" means "nothing
exists," that was true of the mockup, not of `my_first_app`.

## Batch 2 — the 6 remaining pages, start now that Batch 1 is verified done

Confirmed 2026-08-25: Batch 1 (7 pages) is fully done — RPC bug fixed,
all 7 wired into the drawer, real browser click-through confirmed real
data renders (students page tested directly). Proceed with these 6:

- `school_admin_dashboard_page.dart` — this new design's own hub/home
  screen. Don't give it its own bespoke RPC — have it aggregate calls to
  whatever services back the individual pages below (same pattern
  `list_device_control_data_for_super_admin` used in Phase 1: one
  endpoint, several existing data sources combined). A single new
  `get_school_admin_dashboard_summary(p_token)` that pulls counts from
  the *other* RPCs' underlying tables is reasonable; don't duplicate
  their logic.
- `school_admin_profile_page.dart` — the logged-in admin's own profile +
  activity log. Profile data itself already exists (`users` table,
  `admin_update_user_profile`); the activity-log half may be new — check
  whether `audit_logs` filtered to this user's own actions already
  covers it before building a separate log table.
- `school_buildings_page.dart` — `get_classrooms_overview(p_token)`
  already exists and there's a `20260824080000_buildings_and_rooms.sql`
  migration in the schema — **check its actual return shape first**
  (`select proname, pg_get_functiondef(oid) from pg_proc where
  proname='get_classrooms_overview'`) against what the new page's UI
  needs before deciding whether it's a straight reuse, needs a thin
  wrapper, or genuinely needs new columns/RPC. Don't assume either way
  without checking — this one's the least certain of the 6.
- `school_reports_page.dart` — check what "reports" actually means here
  (the mockup's literal field lists will show this) before designing —
  don't guess a schema.
- `school_settings_page.dart` — check for overlap with `get_school_utility_rates`/`set_school_utility_rates`
  and any existing school-level settings RPC before assuming a new
  settings table.
- `school_scan_page.dart` — the mockup uses `mobile_scanner` to decode a
  QR/barcode locally but does nothing with the result (no lookup, no
  persistence). Figure out what it's meant to scan *into* — likely
  overlaps with the existing AUTH-5 terminal/QR pairing flow already
  built for teacher/student (`TerminalPairingService`) — check that
  before inventing a new scan-to-something flow.

**Same 2 mistakes from Batch 1, don't repeat them**: (1) every new RPC
must use `SELECT * INTO v_actor FROM get_session_actor(p_token); IF NOT
FOUND THEN RAISE EXCEPTION 'invalid_session'; END IF;` — probe with a
garbage token before reporting done, not just a valid one. (2) wire each
page into `school_admin_dashboard.dart`'s drawer as you go, don't leave
UI-complete-but-unreachable pages for a report to claim as "done."

## What NOT to do

- Don't touch `super_admin`'s Phase 3 pages (`dev_dashboard_page.dart`,
  `devices_page.dart`, `permissions_page.dart`, `alerts_logs_page.dart`,
  `device_test_page.dart`, `settings_page.dart`) — separate phase, comes
  after this one.
- Don't delete or replace the *existing* school_admin pages
  (`school_admin_cctv_page.dart`, `school_admin_energy_page.dart`, etc.)
  as part of this — they already work, keep them running until their
  specific new-design replacement is verified, per the "old-UI-file
  policy" in `HANDOFF.md`.
- Don't widen any existing table/RPC's shape to match the mockup's
  imagined fields (same rule as Phase 1) — adapt the new UI's data
  layer to the real shape.

## Work order

Batch 1 (students, teachers, permissions, import, alerts, resources,
devices) is done — see "Batch 2" section above for the remaining 6
(dashboard, profile, buildings, reports, settings, scan). Report back
after Batch 2, same as Batch 1 — those 6 need actual design decisions
(flag back anything unclear rather than guessing a schema).

## Verify

Same standard as every phase: real RPC calls with real session tokens
(`super_admin`/`school_admin` positive, a non-admin role negative on at
least the write RPCs), real browser click-through of each ported page
with real seeded data, `flutter analyze` clean. For the reuse-heavy
batch specifically, also confirm the *existing* pages that already used
these RPCs (e.g. the current user-management page, the current
energy/ESG pages) still work identically after this — reusing an RPC
from a new call site shouldn't change its behavior, but verify rather
than assume.
