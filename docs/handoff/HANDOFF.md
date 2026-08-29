# AIoT School Lab — Handoff Notes (updated 2026-08-25)

This file is written for another developer/AI picking up this codebase cold.
It covers what this project is, how it's built, the non-obvious patterns you
need to know before touching the database or auth, how to run it locally, and
what's currently in progress / broken.

See also: **[DATABASE_SCHEMA.md](./DATABASE_SCHEMA.md)** — full live dump of
every table's columns, foreign keys, and every RPC function's signature,
generated directly from the running local database (not hand-written, so it
can't drift from reality the way a hand-maintained doc would).

## What this is

AIoT School Lab — a school management app (Thai-language UI) covering
classes, assignments, grading, quizzes, lesson content, incident/emergency
reporting, parent-student binding, and IoT sensor data (air quality, water
utility metrics) from physical classroom devices. Multiple roles: teacher,
student, parent, facility manager, executive/admin.

## Repo layout

Flutter monorepo (melos workspace) at `~/my_first_app`:

- `apps/user_app` — the main app; all roles (teacher/student/parent/facility/
  executive) route through here based on the logged-in user's role.
- `apps/admin_app` — **an old, mostly-unused stub** (2 page files: a login
  gate + a placeholder dashboard body, one working "จัดการผู้ใช้" page).
  **This is not the real Super Admin app** — don't confuse it with the one
  below. Kept around mainly so its `admin_login_page.dart` still works if
  something links to it, but there's no active plan to build it out further.
- `packages/shared_core` — all business logic: Supabase client setup, auth,
  and one service class per domain (see below). Both apps depend on this.
- `packages/shared_ui` — shared widgets/design tokens.
- `supabase/` — migrations (61 files, `supabase/migrations/`), Edge Functions
  (`supabase/functions/`), config, and `seed.sql` (test data + test accounts).

**The real Super Admin app lives OUTSIDE this repo**, at `~/aiot_dev_dashboard`
(separate Flutter project, not part of this melos workspace, not git-tracked
as of this writing). It points at the same local Supabase instance
(`http://127.0.0.1:54321` — see `lib/config/supabase_config.dart` there) and
uses **real Supabase Auth** (`signInWithPassword`/`auth.users`), unlike this
repo's own custom session system — a completely different auth model running
against the same database. Run it with:
```bash
cd ~/aiot_dev_dashboard && flutter pub get && flutter run -d chrome --web-port=3000
```
**As of 2026-08-25: 26/26 pages wired to real backend data**, confirmed
via live login testing and a fresh audit specifically for leftover mock
fallbacks — the "4 of 27" figure above is stale, from before that work.
One dead file (`school_simple_page.dart`, an unused generic template) was
removed rather than wired up. See that repo's own
`docs/handoff/HANDOFF.md` for the detail. Don't trust the "Mock Preview"
banner language above either — it described an earlier state.

Remotes: pushes to both GitHub (`pakasit14-Sayfa/aiot-school-lab`) and GitLab
(`diliondev/aiot-school-lab`).

## Architecture — read this before writing any backend code

**1. This is NOT Supabase Auth.** There is no `auth.users`, no `auth.uid()`,
no JWT-based RLS. Login is fully custom:

- `users` table has its own `password_hash` (bcrypt via `crypt()`).
- Sign-in goes through the `auth-sign-in` Edge Function → validates
  credentials → may require a 2FA OTP step (`auth-verify-otp` Edge Function,
  email-delivered code) → on success, inserts a row into `sessions` and
  returns an opaque `session_token` string to the client.
- The client (`AuthService` in `shared_core`) stores that token
  (`session_token_storage.dart`) and passes it as the **first argument**
  (`p_token text`) to almost every RPC call from then on.
- Every RPC starts by calling `get_session_actor(p_token)` (or similar) to
  resolve who's calling and their role/school, then does its own authorization
  check in PL/pgSQL. There is no framework-level authorization — it's
  hand-written in every function.

**2. RLS is deny-all everywhere; RPC is the only door.** All 72 base tables
have Row-Level Security **enabled** with **zero policies** defined for this
app's own custom auth model. That's deliberate — it means PostgREST's
auto-generated `/rest/v1/<table>` endpoints are unusable from the client no
matter what key you hold. All reads and writes happen through `SECURITY
DEFINER` functions in the `public` schema, called via
`supabase.rpc('function_name', {...})`. **Never** add a table that clients
touch with `.from('table').select()` — that's not how this codebase works,
and it would silently return nothing because of RLS.

**Exception, added 2026-08-22 for `aiot_dev_dashboard`**: `devices`,
`schools`, `device_commands`, `sensor_readings`, `device_categories`,
`device_logs`, `control_approval_requests`, `users`, and `user_roles` now
also have real `authenticated`-role RLS policies (`is_super_admin()`/
`get_auth_school_id()`-based), plus two views (`profiles`, `alerts`) — this
is a **second, parallel security model** for the separate dashboard app
above, layered on top of the same tables. A security incident happened here
(see below) — read it before touching any of these policies.

**3. File uploads never touch client-side Storage calls directly.** Pattern
(see `course-file-upload`/`course-file-download` and the newer
`lesson-material-upload`/`lesson-material-download` Edge Functions):
  1. Client calls an Edge Function with `{ token, <parent_id>, file_name }`.
  2. Edge Function runs an `assert_*_access` RPC (service-role key) to check
     the caller is authorized (e.g. "is this user a teacher on this lesson's
     course?").
  3. Edge Function mints a Storage **signed upload URL** for a private
     bucket and returns `{ storage_path, token }`.
  4. Client uploads bytes directly to Storage using that signed URL.
  5. Download is symmetric: client calls the download Edge Function with
     `{ token, material_id }`, a `get_*_for_download` RPC checks membership
     (teacher of the course, OR student enrolled + lesson published), and the
     function returns a short-lived signed **download** URL.

If you're asked to add a new kind of file upload, copy this exact pattern —
it's now used twice (`course_files`, `lesson_materials`) and is the
established convention.

**4. Service-per-domain in `shared_core`.** `packages/shared_core/lib/services/`
has one file per feature area (auth, courses, assignments, grades, quizzes,
lessons, incidents, emergencies, calendar, notifications, rubrics, student
groups, utility/sensor costs, parent binding, invitations, password reset,
realtime, user admin). Each wraps its own RPCs; pages call the service, never
`supabase.rpc(...)` directly.

## Running it locally

```bash
cd ~/my_first_app

# 1. Docker Desktop must be running first (Supabase local stack runs in Docker).
open -a Docker   # then wait for the daemon: `docker info` succeeds

# 2. Start local Supabase (Postgres, Auth container [unused by app logic but
#    part of the stack], Storage, Edge Functions runtime, Studio, etc.)
npx supabase start
# → prints API_URL (http://127.0.0.1:54321), STUDIO_URL (http://127.0.0.1:54323),
#   DB_URL (postgresql://postgres:postgres@127.0.0.1:54322/postgres), and keys.
#   NOTE: there's no global `supabase` CLI installed — always invoke via `npx supabase`.

# 3. env.json at repo root already points at local Supabase — don't need to touch it
#    unless the local anon key rotates (compare against `supabase start` output).
cat env.json

# 4. Run the app (from apps/user_app), pointing at env.json two levels up:
cd apps/user_app
flutter run -d chrome --dart-define-from-file=../../env.json
# or: flutter run -d macos --dart-define-from-file=../../env.json
```

**Test accounts** (seeded by `supabase/seed.sql`, password `Test1234!` for
all of them):
- `teacher@aiot-school-lab.local`
- `student@aiot-school-lab.local`
- `parent@aiot-school-lab.local`
- `admin@aiot-school-lab.local` (super admin)
- `facility@aiot-school-lab.local`
- `schooladmin@`, `executive@`, `technician@` also exist (`user_roles`).
- Full list: `select email, role from ...` query at the bottom of `seed.sql`.

The same 8 accounts also exist in real `auth.users` (for `aiot_dev_dashboard`,
seeded by `20260823070000_seed_auth_users_for_local_dev.sql`), **same
password `Test1234!`**. These two password stores (`public.users.password_hash`
vs `auth.users.encrypted_password`) are independent — a migration
(`20260823120000_fix_seed_auth_password_drift.sql`) had to re-sync them once
already after they drifted apart from manual DB testing. If login into
`aiot_dev_dashboard` ever fails with correct-looking credentials, check this
first: `select encrypted_password = crypt('Test1234!', encrypted_password)
from auth.users;` should be all `t`.

`teacher@`/`schooladmin@`/`executive@`/`admin@` (super_admin) require a 2FA
OTP step after password — in local dev, the OTP code comes back directly in
the sign-in response as `dev_otp_code` (or check Mailpit at
`http://127.0.0.1:54324`), no real email needed.

`isPrototypeRoute` in `apps/user_app/lib/main.dart` is `false` — the app goes
through real login (`RoleRouter` picks the home page from the real role in
the DB). Only flip it to `true` temporarily to browse a role's UI without
logging in (see `NOTES.md` in `teacher_redesign_prototype/` /
`student_redesign_prototype/` — **those NOTES.md files describe an early
"UI-only, not wired to backend" phase of the project and are now stale; most
of what they call "not connected" has since been wired to real RPCs. Trust
the code and `git log`, not those NOTES files, for current status.**

## Production deploy drift incident (2026-08-28) — resolved, read this first

**Production (`smqoknnftgjyhrnzugar`, org `dilion.education2003@gmail.com`,
project `aiot-school-lab-cli`) had been frozen at the 2026-07-18 migration
snapshot for over a month** — every migration from `20260720000000`
onward (~78 files) and every Edge Function had simply never been
deployed there, despite local dev always running the full history. This
was invisible until today because production had no real users yet
(confirmed with the project owner before doing a bulk catch-up).

**How it was found**: debugging why the AIoT weather-sensor card on the
production app showed "ไม่มีข้อมูล" forever led to login itself being
broken — `auth-sign-in`'s Edge Function expects `auth_sign_in()` to
return an `auth_state` column (added 2026-07-21+), production's live
function predated that column, so it came back `undefined`, the function
silently fell into its "not authenticated" branch (HTTP 200,
`{"session": null}`, no `console.error` — nothing showed up in Edge
Function logs, which is what made this hard to find), and the app showed
a generic "invalid credentials" message for every account regardless of
password.

**Fixed 2026-08-28**: applied every pending migration to production and
deployed all 15 Edge Functions. Two migrations needed a hand fix first
because their target objects already existed on production from earlier
undocumented manual patches — same shape as the `gas_mq2_percent` enum
drift below: `20260721010000_relay_commands.sql` (table `device_commands`
pre-existed) and `20260826000000_merge_technician_facility_manager.sql`
(the `DELETE FROM users` for the two obsolete seed accounts hit an FK
from `user_roles` that a real production `user_roles` row for
`facility@aiot-school-lab.local` had and local dev's seed apparently
didn't — deleted those `user_roles` rows first, then replayed the
migration clean). `npx supabase db push` itself is unreliable in this
environment — it hangs indefinitely on the default Docker-based bundler
for Edge Function deploys, and mis-splits statements in at least one
multi-statement migration file (a `gen_random_bytes()` call that works
fine standalone reported "does not exist" under `db push` specifically).
Working alternative used throughout: `npx supabase db query --linked
--project-ref smqoknnftgjyhrnzugar --file <migration.sql>` per migration,
then manually recording it in `supabase_migrations.schema_migrations` so
`supabase migration list` stays accurate; for Edge Functions,
`npx supabase functions deploy <name> --project-ref smqoknnftgjyhrnzugar
--use-api` (the `--use-api` flag skips the hanging Docker bundler).

**Side effect worth knowing about**: `20260720000000_rotate_default_credentials.sql`
(previously undeployed, applied today) rotates any account still on the
password `Test1234!`/`ChangeMe123!` to a random, unknown value and
revokes its sessions. This means **every account that still had a
default password before today now has an unknown production password**
— `teacher@aiot-school-lab.local` and `student@aiot-school-lab.local`
were manually reset back to `Test1234!` after the fact (for continued
testing convenience), but any other seed account on a default password
was not and will need `issue_device_token`-style manual reset (`update
users set password_hash = crypt('<new password>', gen_salt('bf')) where
email = '...'`) before it can log in again.

**Also discovered, not yet fixed**: `auth_sign_in`'s RPC unconditionally
returns the plaintext OTP code (`otp_code`) in its response row, and the
`auth-sign-in` Edge Function only *withholds* that field from its own
JSON response when `isLocalDev()` is true — meaning the OTP is *not*
leaked to the client on production (confirmed: a real `mfa_required`
response from production has no `dev_otp_code` field), but anyone with
direct Postgres/service-role access to the RPC (not just the client
app) can read it straight out of the function's return value. Low
urgency given today's finding that this project has no real users yet,
but worth tightening — e.g. having the RPC itself omit `otp_code` outside
a local-only code path — before real users are on it.

**Update, same day**: the leaked `DEVICE_TOKEN` mentioned above **has now
been rotated** (new token issued directly via SQL, same shape as
`issue_device_token()` produces: `'dev_' || encode(gen_random_bytes(24),
'hex')`) — the old leaked value in git history is now inert. Git history
itself was **not** purged (out of scope for this session; the token
being dead makes that lower-priority, not unnecessary).

---

## Real hardware ingest wired up + sensor-freshness UI (2026-08-29)

**A second casualty of the same `DROP TYPE role_type CASCADE`** (see the
incident above) was found while getting the real board
(`เซนเซอร์ห้องทดลอง`, Adafruit Feather AIoT S3) posting straight to
`/rest/v1/rpc/sensor_ingest`: `anon`/`authenticated` both showed
`has_function_privilege(...) = false` for `sensor_ingest`, despite
`20260720010000_sensor_ingest_rpc.sql` granting it — a live 401 on the
board confirmed this wasn't just theoretical. Fixed with
`grant execute on function public.sensor_ingest(text, jsonb) to anon,
authenticated;`. Audited every other `SECURITY DEFINER` function in
`public` for the same symptom (zero grants to `anon`/`authenticated`/
`service_role`) — only `_check_threshold_violations()` matched, which is
correctly grant-less (pg_cron-only, not API-reachable) — so this was an
isolated second casualty, not a wider pattern still lurking.

The board's actual device token also didn't match what was stored
(`invalid_device_token`) — rather than debug which of "board has a stale
value" vs "board has a typo" it was, just rotated the token (see the
update above) and handed the new plaintext to the board's owner directly
outside the repo. **Real sensor data is now flowing end-to-end into
production** — confirmed live: `sensor_readings` receiving `pm25`,
`aqi`, `light_lux`, `temperature`, `humidity` from the real board at
roughly 1-second intervals (docs recommend batching to every 10–60s
instead — flagged to the board's owner, not yet changed on the firmware
side).

**Also added**: per-metric freshness status across every place the app
shows sensor data (`AiotWeatherSensorsCard` in both `teacher_redesign_prototype_page.dart`
and `student_redesign_prototype/widgets/aiot_weather_sensors_card.dart`,
the shared full `AiotDashboardPage`/`SensorGrid`/`SensorCard` in
`widgets/sensor_card.dart`, and the compact `_SensorSnapshotCard` "AIoT
Classroom" mini-card) — found live during this session that a
38-day-old seeded temperature/humidity reading rendered with an
identical green "ปกติ" badge to a genuinely-fresh PM2.5 reading on the
same card, with zero way to tell them apart. `SensorModel` now tracks
`metricUpdatedAt` per metric (not just one overall `updatedAt`) and
exposes `freshnessOf()`/`relativeTimeLabel()`/`overallFreshnessOf()`
(`packages/shared_core/lib/models/sensor_model.dart`). Each sensor tile
shows one badge, not two: the safety level (ปกติ/ไม่ปลอดภัย) when
live/delayed (≤10 min old), or "เซนเซอร์ไม่ทำงาน"/"ไม่มีข้อมูล" instead
when older — never both stacked, which read as contradictory (green
"ปกติ" next to red "เซนเซอร์ไม่ทำงาน" on the same row). The small green
pulse dot next to each card's "ข้อมูลเซนเซอร์สภาพอากาศ AIoT" header was
also hardcoded green regardless of data age — now reflects
`overallFreshnessOf()` (worst-of across the 4 displayed metrics, so one
dead sensor isn't masked by three healthy ones). Verified live by
literally cutting power to the real board mid-session and watching all
3 tiers transition correctly in real time: live → delayed (orange,
2–10 min) → offline (red, >10 min, confirmed at the 12-minute mark).

---

## Real board writing sensor_ingest directly + "remember this device" (2026-08-29, later same day)

**A real board (`เซนเซอร์ห้องทดลอง`, Adafruit Feather AIoT S3) started
posting straight to `/rest/v1/rpc/sensor_ingest`** (not through MQTT/the
Mac bridge — a second, independent ingestion path) and hit 401
`permission denied for function sensor_ingest`. Root cause: a *third*
casualty of the `DROP TYPE role_type CASCADE` from the incident above —
`anon`/`authenticated` had silently lost `EXECUTE` on `sensor_ingest`
too (confirmed via `has_function_privilege`), despite
`20260720010000_sensor_ingest_rpc.sql` granting it. Fixed with a direct
`grant execute on function public.sensor_ingest(text, jsonb) to anon,
authenticated;`. Audited every `SECURITY DEFINER` function in `public`
for the same symptom (zero grants to anon/authenticated/service_role) —
only `_check_threshold_violations()` matched, which is correctly
grant-less (pg_cron-only). The board's device token also didn't match
what was stored, so it was rotated (new plaintext handed to the board's
owner outside the repo, old one dead). Real board data is confirmed
flowing into `sensor_readings` at ~1/sec (docs recommend batching to
10–60s instead, not yet changed in the firmware).

**Also set up real OTP email delivery** — `RESEND_API_KEY` and
`RESEND_FROM_EMAIL` (`onboarding@resend.dev`, domain not yet verified)
are now real Supabase secrets on production. Caveat: Resend's
unverified-domain mode only delivers to the Resend account owner's own
email, so `teacher@aiot-school-lab.local`'s email was changed to a real
address for this to be testable end-to-end — every other seed account
is still on the `.local` domain and still can't receive real OTP mail
until either the domain gets verified or its email is swapped too. That
same account was also granted all 6 roles (`user_roles` rows added for
school_admin/super_admin/executive/student/parent, `teacher` already
there) specifically to make it easy to test every OTP-gated role from
one real, checkable inbox.

**Built "remember this device"** (migrations
`20260829000000_trusted_devices_remember_login.sql` and
`20260829010000_trusted_devices_account_wide.sql`) after live-testing
kept requiring a fresh OTP on every login — including every time a
multi-role account switched roles, which was the real complaint,
confirmed with the project owner. `trusted_devices` **already existed,
unused, since the very first migration** (`20260715000000`) — adapted
in place (renamed/extended its columns) instead of creating a
competing table. `auth_sign_in` / `auth_select_role` accept an optional
`p_device_trust_token`; if it matches a live, unexpired, unrevoked row
for that `user_id` (**account-wide, not scoped to the role/school that
earned it** — a token minted while verifying OTP as school_admin also
works for that same account signing in as executive, teacher, etc. —
this was a deliberate revision after the first pass scoped it per-role
and the owner said that wasn't what they wanted), it skips straight to
`authenticated` instead of issuing an OTP challenge. **The password
check always runs first, unconditionally** — a trust token only ever
shortens the OTP step, never substitutes for the password. On
successful OTP verification with `p_remember_device: true`,
`auth_verify_login_otp` mints a 30-day token and returns it; the client
(`DeviceTrustTokenStorage` in `packages/shared_core/lib/services/`,
same secure-storage pattern as `SessionTokenStorage`) stores one token
per email and sends it on future sign-in attempts. UI: a checkbox on
`packages/shared_ui/lib/pages/login_otp_page.dart`'s OTP screen,
**"จำเครื่องนี้ 30 วัน (ไม่ต้องกรอกรหัสยืนยันซ้ำ)"**.

**Gotcha for local testing of this flow**: the trust token is stored in
the browser (secure storage → web = browser storage tied to that
Chrome profile). `flutter run -d chrome` launches a **fresh temporary
Chrome profile every time the command is run from scratch** — killing
and re-running `flutter run` loses any remembered-device token even on
the same URL/port. Hot-restarting (`R` in the terminal, same running
`flutter run` process, same already-open browser tab) preserves it;
killing and relaunching does not.

---

## Current status (re-audited 2026-08-25 — supersedes everything below in this section)

**All 6 roles are fully wired to real backend data, no mock pages left
anywhere in the app.** This corrects the 2026-08-22 audit further down,
which is now stale in several places (it called executive "100% mock"
and facility_manager/parent "partially wired" — both claims are wrong
as of today). Kept the old audit below for history/methodology
reference, but don't trust its per-role claims over this summary.

- **`school_admin` — 20/20 menus real, and as of 2026-08-25 it has its own
  visual redesign too.** `role_router.dart` sends `school_admin` to
  `school_admin/school_admin_dashboard_page.dart` (new blue/indigo themed
  hub with a 12-item sidebar), not the old `dashboard/school_admin_dashboard.dart`
  shell anymore (that file still exists on disk, unreferenced — see the
  old-UI-file policy above). The hub folds in 12 newly-redesigned pages
  (students, teachers, permissions, import, buildings, devices, resources,
  reports, settings, scan, profile, alerts) plus 8 older-style pages that
  keep their original plain visual style but are fully wired to real data
  (user management, consent policy, energy/ESG reporting, CCTV
  access-grant management, automatic device scheduling via real `pg_cron`,
  manual device on/off control, and an incident/SOS inbox). Live-verified
  2026-08-25: real login lands directly on the new hub, all 8 folded-in
  items confirmed present and clicked through.
- **`super_admin` — 8/8 menus real, and as of 2026-08-26 it has its own
  visual redesign too.** `role_router.dart` sends `super_admin` to
  `super_admin/super_admin_hub_page.dart` (the new hub, blue-themed with
  8 quick-action cards + a matching drawer), not the old
  `dashboard/super_admin_dashboard.dart` shell anymore (that file still
  exists on disk, unreferenced — see the old-UI-file policy above). All
  8 real: school management (create/update/suspend), device control
  (multi-school overview, approval workflow, real `queue_device_command`
  dispatch), device inventory + QR codes, device diagnostics (real
  stopwatch-timed checks against real RPCs, honestly marked unmeasured
  where no real hardware backend exists), cross-school permissions/RBAC,
  cross-school alerts & audit logs, platform settings (Tier B — honest
  "not connected to backend" disclosure, no fake persistence), and
  cross-school user management. Live-verified 2026-08-26: real login
  lands directly on the new hub, all 8 cards present with real summary
  metrics, spot-checked 2 of the 3 most-recently-added pages.
- **`teacher`, `student`, `executive`, `parent` — fully wired via their
  `*_redesign_prototype/` folders**, which `role_router.dart` has routed
  to as the real (not preview-only) UI since the redesign work landed.
  Known, deliberately-disclosed (not hidden) gap: parent has no direct
  messaging/meeting-request feature (deferred, see "Deferred Features"
  below). (G-Score previously listed here as having no backend — the
  backend existed since `20260823030000_g_score.sql`, it just had no
  consuming page; `student_score_page.dart` now shows it for real, see
  2026-08-27 in WORK_LOG.md.)

- **`school_admin`'s "นำเข้าข้อมูล" (bulk import) is now real, all 5 data
  types, as of 2026-08-26** — was previously a facade (fake file picker,
  hardcoded preview rows) that, for นักเรียน/ครูและบุคลากร, actually wrote
  those hardcoded fake names into the real database on every click (found
  live, fixed, see `docs/handoff/WORK_LOG.md`). Real `.xlsx`/`.xls`/`.csv`
  parsing + public-CSV Google Sheets import, real per-row validation, and
  new backend (`import_school_buildings_batch`/`import_school_rooms_batch`/
  `import_school_devices_batch` in `20260826150000_school_admin_bulk_import.sql`
  — buildings/rooms/devices had no create RPC at all before this).
  Live-verified end-to-end for all 5 types with real fixture files.

- **Teacher's AIoT dashboard (`teacher_aiot_dashboard_page.dart`) is now
  real, as of 2026-08-26** — device sensor values, threshold save, and
  alert acknowledge were all fake (hardcoded numbers labeled "เรียลไทม์",
  buttons only mutated local state). Now wired to `sensor_latest`/
  `RealtimeService` for real per-device readings (honest "ยังไม่มีข้อมูล"
  when a device has no real data yet — true for every device locally,
  since no hardware is connected), and to new/widened RPCs in
  `20260826160000_teacher_aiot_thresholds.sql` for real threshold CRUD and
  alert list/acknowledge (teacher was added to the existing school_admin-
  only alert RPCs). The fake "UV index" metric was replaced with real
  light intensity (`light_lux`) per the project owner's request — UV was
  never a real trackable metric in this system. **Update 2026-08-27:
  the "no auto-alert" gap noted here is now closed** —
  `_check_threshold_violations()` (`pg_cron`, ticks every minute, same
  pattern as the device-schedule runner) inserts a real `sensor_alerts`
  row when a device's latest reading crosses an active threshold,
  de-duplicated against any still-open alert for that device+threshold
  (see `20260827030000_auto_threshold_alerts.sql`). The teacher **home
  page**'s own separate AIoT summary
  widgets (`_AiotWeatherSensorsCard`/`_SensorSnapshotCard`) had the same
  hardcoded-numbers bug — also fixed same day, real data + honest "ไม่มีข้อมูล"
  (neutral grey, not a misleading red "unsafe") when nothing has reported
  yet. The home page's **"การใช้น้ำ-ไฟ" (water/electricity) card was fixed
  too**, using already-existing real `UtilityService` RPCs (no new
  migration needed) for real weekly totals, a real 5-day chart, and a
  real week-over-week % trend. **CSV/Excel export on the dashboard page
  is also real as of 2026-08-27** (was the only piece left fake) — see
  WORK_LOG.md for the `file_picker` web-download bug found and fixed
  while building it (`file_picker` 8.3.7 has no web `saveFile()`
  implementation; `apps/user_app/lib/utils/web_download.dart` now
  handles real browser downloads via `dart:html` instead — relevant if
  any other page tries to reuse `FilePicker.platform.saveFile()` for a
  download on web, e.g. `school_import_page.dart`'s template download,
  which likely has the same latent bug, not yet independently verified).
  A wider
  audit of `teacher_redesign_prototype/` found 6 more fake-write bugs in
  other files — see `docs/handoff/WORK_LOG.md` for the full list.
  **Update 2026-08-27: all 6 are now fixed and independently
  live-verified** (`teacher_notifications_page.dart` mark-all-read,
  `teacher_profile_page.dart` stat fallbacks, `teacher_rubric_page.dart`
  edit-mode via a new `RubricService.updateRubric`, `teacher_grading_page
  .dart` create-worksheet, `teacher_courses_page.dart` close-course, and
  `teacher_exam_builder_page.dart`'s image/video attachments via a new
  `quiz-attachments` Storage bucket + `quiz-attachment-upload`/`-download`
  Edge Functions, verified end-to-end including the student-facing
  `student_pretest_posttest_page.dart` attachment viewer). **Update
  2026-08-27: the remaining known gaps are also closed** — real course
  join codes (`courses.join_code` + `get_or_create_course_join_code`/
  `regenerate_course_join_code`), a real "G-Score สะสม" card on
  `student_score_page.dart` (backend already existed, just wasn't
  wired to any page), real CSV/Excel export on the AIoT dashboard, and
  real `pg_cron`-driven auto-alerts from threshold violations — see
  `docs/handoff/WORK_LOG.md` for the two real bugs found and fixed
  while building these (a Postgres float→int rounding bug in the join
  code generator, and `file_picker`'s missing web `saveFile()`
  implementation).

**Role model**: 6 roles as of 2026-08-25 (`technician` and
`facility_manager` were merged into `super_admin`/`school_admin` — see
the dated entry further down). **A single account can now hold more
than one role** — "multi-role login" — see that section below.

---

*Everything from here to "Known issues not yet fixed" is the older
2026-08-22 audit, kept for its methodology notes but stale on per-role
status — read the summary above first.*

Both teacher-side and student-side UIs have been progressively wired from
mock data to real Supabase RPCs over many commits (see `git log --oneline`).

**Teacher (`teacher_redesign_prototype/`): effectively fully wired.** Of 25
files, 3 are not feature pages at all (`teacher_design_system_page.dart`,
`teacher_shared_widgets.dart`, `teacher_storybook_page.dart` — design-system/
component-showcase demos, not screens a real user reaches) and don't need
backend calls. **All 22 remaining feature pages make at least one genuine
`XService.method()` call.** Two of them
(`teacher_courses_page.dart`, `teacher_lesson_editor_page.dart`) still have
module-level variables literally named `mockTeacherCourses`/
`mockLessonsList` — these are **not mock data**, just a leftover-naming
initial/loading placeholder state that gets overwritten by a real service
call in `initState`/`_loadReal*()` before the user sees it (confirmed by
reading both call sites, not just grepping for the word "mock" — grepping
alone is misleading here, which is exactly why an earlier version of this
doc flagged them as gaps when they aren't). Worth a rename for clarity, not
a functional fix.

**Student (`student_redesign_prototype/` + `widgets/`): also effectively
fully wired**, once support files are excluded — of ~25 files: 3 are
non-page support files (`student_dashboard_models.dart` — models,
`student_redesign_palette.dart` — theme, `widgets.dart` — barrel export), 5
are presentational widgets correctly fed real data via constructor params
from an already-wired parent (`academy_continue_learning_card.dart`,
`academy_quick_actions.dart`, `academy_tasks_due_card.dart`,
`learning_progress_card.dart`, and `school_encouragement_card.dart` — the
last is intentionally static/quote-only by design, not data-driven), 1 is a
design-variant switcher container with nothing of its own to fetch
(`student_redesign_prototype_page.dart`), and 2 are **unused dead code**
(`student_course_catalog_carousel_page.dart`,
`student_course_catalog_streaming_page.dart` — only referenced from a
dev-preview picker in `main.dart`, not from the real navigation shell
`student_navigation_prototype.dart`, which uses
`student_course_catalog_minimal_page.dart` instead; worth deleting the two
unused ones rather than leaving them to confuse the next person). Every
other student page has real service calls, including
`student_qr_login_page.dart` (an earlier note here called this "UI-only,
needs a new pairing-session RPC flow" — that was true when written but is
now stale; it calls `TerminalPairingService` end-to-end since the AUTH-5 QR
pairing work).

**Methodology / honest limits of this re-audit**: checked for the presence
of at least one real `XService.method()` call per file, plus manually
read the ambiguous cases (the ones above) rather than trusting a keyword
grep alone — a plain "does this file contain TODO or the word mock" search
gives false positives (see the courses/lesson-editor case) and false
negatives (files calling services through a pattern a narrow regex misses).
This confirms **no page is entirely mock**, but it does **not** confirm every
field/button inside a large file (`teacher_courses_page.dart` is 4,872
lines, `teacher_redesign_prototype_page.dart` is 5,770) is wired — that
still needs the real "run it and click through" verification this project
otherwise insists on for any specific feature before trusting it end-to-end.
Executive and facility manager remain the real, confirmed gap — see below.

**2026-08-21 update, corrected 2026-08-22**: `teacher_knowledge_library_page.dart`,
`teacher_student_support_page.dart`, and `student_qr_login_page.dart` were
noted here as fully mock / needing new backend from scratch — all three are
now wired (student support case tracking + terminal/QR pairing RPCs were
built since that note was written; see the teacher-page audit above, both
files now call real services). Don't trust that specific claim anymore, but
keep the general lesson: **re-check "not wired yet" notes against the actual
code before repeating them**, this doc has been wrong about it twice now.

**Executive (`executive_redesign_prototype/executive_home_page.dart`) is
still 100% mock** (zero service calls) — confirmed again 2026-08-22. **Facility
manager is now partially wired**, not 100% mock as previously noted here:
of 12 files under `facility_redesign_prototype/`,
`facility_device_health_page.dart`, `facility_light_water_control_page.dart`,
and `facility_notifications_page.dart` have real service calls; the other 9
(including `facility_dashboard_page.dart`, the role's actual home page) do
not. Parent is partially wired (home page only).

### Super Admin Redesign (Phase 1 — completed 2026-08-25)
- Created migration `20260826090000_super_admin_redesign_phase1.sql` (7 RPCs):
  `list_schools_for_super_admin`, `create_school_for_super_admin`, `update_school_for_super_admin`,
  `suspend_school_for_super_admin`, `list_control_approval_requests_for_super_admin`,
  `decide_control_approval_request_for_super_admin`, `emergency_override_device_for_super_admin`.
- Added models in `shared_core/models/super_admin_model.dart` and `SchoolAdminPlatformService`.
- Replaced mock UI in `apps/user_app/lib/pages/super_admin/` (`super_admin_schools_page.dart`, `super_admin_device_control_page.dart`).
- Fully verified via DB probes and automated tests (44/44 in `shared_core`, 40/40 in `user_app`).

### School Admin Redesign (Phase 2 — Batch 1 completed 2026-08-25)
- Created migration `20260826100000_school_admin_redesign_phase2_alerts.sql` (4 RPCs):
  `list_school_alerts`, `acknowledge_sensor_alert_for_school_admin`, `resolve_sensor_alert_for_school_admin`,
  `import_school_users_batch_for_school_admin`.
- Preserved existing dual-auth RPCs for `aiot_dev_dashboard` by creating dedicated `*_for_school_admin` functions with `p_token text`.
- Added `SchoolSensorAlertRecord` model and unit tests in `shared_core`.
- Ported and wired 7 Batch 1 pages in `apps/user_app/lib/pages/school_admin/`:
  1. `school_students_page.dart` $\rightarrow$ `UserAdminService.getAllUsers()`
  2. `school_teachers_page.dart` $\rightarrow$ `UserAdminService.getAllUsers()`
  3. `school_permissions_page.dart` $\rightarrow$ `UserAdminService.getAllUsers()`
  4. `school_import_page.dart` $\rightarrow$ `UserAdminService.importSchoolUsersBatch()`
  5. `school_alerts_page.dart` $\rightarrow$ `IncidentService.listSchoolAlerts()`
  6. `school_resources_page.dart` $\rightarrow$ `UtilityService` (`getSchoolUtilityRates`)
  7. `school_devices_page.dart` $\rightarrow$ `RealtimeService.listSchoolDevices()`
- All 7 pages pass analyzer with 0 issues and all 40 `user_app` tests pass.

### School Admin Redesign (Phase 2 — Batch 2 completed 2026-08-25)
- Created migration `20260826110000_school_admin_redesign_phase2_batch2.sql` (4 RPCs):
  `list_school_buildings(p_token text)`, `list_school_rooms(p_token text, p_building_id uuid)`,
  `get_school_admin_dashboard_summary(p_token text)`, `list_school_admin_audit_logs(p_token text, p_limit int)`.
- All RPCs strictly follow session token pattern (`SELECT * INTO v_actor FROM get_session_actor(p_token); IF NOT FOUND THEN RAISE EXCEPTION 'invalid_session'; END IF;`) and were verified via positive probe, garbage token negative probe, and role isolation probe (all 12 probes passed).
- Added models in `packages/shared_core/lib/models/school_building_model.dart` and methods in `SchoolAdminPlatformService`.
- Ported and wired all 6 Batch 2 pages in `apps/user_app/lib/pages/school_admin/`:
  1. `school_buildings_page.dart` $\rightarrow$ `SchoolAdminPlatformService.fetchBuildings() / fetchRooms()`
  2. `school_admin_profile_page.dart` $\rightarrow$ `currentUserModel` and `SchoolAdminPlatformService.fetchAuditLogs()`
  3. `school_reports_page.dart` $\rightarrow$ `SchoolAdminPlatformService.fetchAuditLogs()`
  4. `school_settings_page.dart` $\rightarrow$ `SchoolAdminPlatformService.fetchDashboardSummary() / fetchAuditLogs()`
  5. `school_scan_page.dart` $\rightarrow$ QR scanner & terminal pairing
  6. `school_admin_dashboard_page.dart` $\rightarrow$ Modern responsive 12-item admin hub with dynamic summary metrics
- Wired all 6 Batch 2 pages into `apps/user_app/lib/pages/dashboard/school_admin_dashboard.dart` drawer & InfoCards.
- All 52 `user_app` tests pass, all 45 `shared_core` tests pass, 0 analyzer issues in `school_admin` codebase.

### Teacher Lesson Editor Data Loss Fix (completed 2026-08-25)
- Fixed silent data wiping bug where opening an existing lesson in `TeacherLessonEditorPage` loaded dummy single-heading placeholder blocks and empty materials, and autosave immediately overwrote the database content.
- `TeacherLessonEditorPage` now invokes `_loadFullLesson()` to fetch complete lesson details via `LessonService.getLesson()` (`get_lesson` RPC), deserializes structured `blocks` and fallback `body` text, loads real attached materials and sensor links, and keeps an `_isLoading` guard preventing premature autosaves.
- Enhanced `list_lessons` via migration `20260826120000_enhance_list_lessons_counts.sql` to return `materials_count` and `sensor_links_count` per lesson without N+1 queries.
- Fixed seed material row `f57f10d4...` type to `'link'`.
- Replaced raw 500 error string in `student_lesson_view_page.dart` with user-friendly Thai message.
- Verified 100% via SQL probes (positive token, negative fake token, update round-trip preserving content body) and automated tests (53/53 `user_app`, 45/45 `shared_core`).

### Known issues not yet fixed

*(`teacher_exam_builder_page.dart`'s image/video attachments and
`teacher_profile_page.dart`'s hardcoded stat fallbacks, both previously
listed here, were fixed and independently live-verified 2026-08-27 —
see `docs/handoff/WORK_LOG.md`.)*
- **`file_picker` 8.3.7's web `pickFiles()` is unreliable under browser
  automation (found 2026-08-27)**: its web implementation
  (`_internal/file_picker_web.dart`) removes the trigger
  `<input type=file>` from the DOM immediately after calling `.click()`,
  which breaks Chromium DevTools Protocol's file-chooser interception —
  confirmed this makes `page.waitForEvent('filechooser')` in Playwright
  never fire, for *every* `pickFiles()` call site tried, not just new
  ones (regression-tested `teacher_exam_builder_page.dart`'s image
  picker, which had worked earlier the same session, and it now fails
  identically). Real human users in a real browser are almost certainly
  unaffected — the DOM removal races a genuinely async native OS dialog,
  not something a live user's dialog interaction would ever notice — but
  this means **no file-picking flow in this app can be verified via
  Playwright automation** until `file_picker` is upgraded (8.3.7 → 12.1.1
  available, untested, likely has breaking API changes worth scoping
  separately) or replaced with a hand-rolled `dart:html` picker to match
  `apps/user_app/lib/utils/web_download.dart` (built the same day for the
  matching `saveFile()` web gap, see below). Any future work touching a
  `FilePicker.platform.pickFiles(...)` call site should budget for this —
  verify the upload *pipeline* (edge function → signed URL → RPC) via
  direct HTTP simulation instead of trying to automate the click.
- **`file_picker` 8.3.7's web `saveFile()` has no web implementation at
  all** (found 2026-08-27 building the AIoT dashboard CSV/Excel export)
  — falls through to the base class's
  `UnimplementedError('saveFile() has not been implemented.')`. Fixed
  for that one call site with `apps/user_app/lib/utils/web_download.dart`
  (a small `dart:html` blob-download helper). **Not yet checked whether
  any other page relies on `FilePicker.platform.saveFile()` for a
  download** — `school_import_page.dart`'s "download template" button is
  the most likely other user, worth a look before trusting it works.
- **Intermittent client-side redirect to the "สร้างบัญชี" (create-account/
  invitation) screen on the Nth post-login click (found 2026-08-27)**: after
  a fully successful login+OTP flow, some later click deep in the app
  (observed on both `school_admin` and `teacher`, on totally unrelated
  pages/actions — a sidebar nav click, a wheel-scroll, a dropdown open)
  randomly bounces the whole app back to the unauthenticated "มีรหัสเชิญ?"
  screen, as if the router momentarily read a null/stale auth state.
  Roughly 50% of attempts hit it in Playwright testing; a plain page reload
  after a successful login does **not** restore the session (confirmed no
  client-side session persistence — full login+OTP is required again),
  ruling out a token-expiry explanation (real session TTL is 7 days). Not
  reproducible on a fixed schedule or fixed action — looks like a real
  client-side race in the app's own auth-state stream, not something
  introduced this session (surfaced while building `teacher_attendance_page.dart`
  and wiring `school_teachers_page.dart`'s homeroom dropdown, but reproduced
  identically on plain sidebar navigation with no code changes involved).
  Not investigated further — treat any single Playwright run that lands here
  as a retry, not a real bug in whatever was just clicked.
- **Teacher home dashboard's own summary widgets are still mostly fake data
  (found 2026-08-27/28)** — distinct from the "7 teacher fake-write bugs"
  audit closed earlier, which covered pages navigated *to* from the
  dashboard, not the dashboard's own widgets. Status per item, backend
  availability checked against the real schema (not guessed):
  - `_ScheduleCard` ("ตารางสอนวันนี้") — **fixed 2026-08-28**, now calls
    real `CalendarService.listTeacherSchedules()` filtered to today.
  - `TeacherMock.reviewTasks` ("งานรอตรวจ") — **fixed 2026-08-28**, client-side
    aggregate (no cross-course RPC exists): all active courses →
    `list_assignments` → published ones → `list_submissions` → count
    `status == 'submitted'`. New gap found while fixing this: the
    dashboard's top alert banner (`_TeacherHero`) independently hardcodes
    the same "18 ชิ้น"/"3 คน" numbers — not yet wired to this real count.
  - `TeacherMock.students` ("นักเรียนที่ต้องติดตาม") — **fixed 2026-08-28**.
    User chose real auto-computed risk scoring over reusing the manual
    `student_support_cases` system. New `list_students_needing_attention`
    RPC flags students on ≥2 overdue assignments, avg confirmed grade
    < 50%, or ≥2 absences in 30 days (via `StudentSupportService
    .listAutoFlaggedStudents()`) — see `WORK_LOG.md` for full detail.
  - `_SubmissionBarChartCard`/`_StudentStatusDonutCard` — **fixed
    2026-08-28**. Bar chart renamed "สถานะส่งงานรายวิชา" (per-course, not
    per-room — `courses.room` is a physical lab code, not a class
    section) and computed client-side (`submitted / (assignments ×
    enrolled)` per course). Donut reuses `list_students_needing_attention`
    (no new RPC) to split the roster into ปกติ/ต้องติดตาม/ขาดส่งงานบ่อย.
  - `_SmartWiringLabCard` — **fixed 2026-08-28**. User chose the full
    option (real group + inspection workflow, not a scaled-down
    device-only version). New `wiring_groups`/`wiring_group_members`
    tables + `WiringGroupService`, a 4-state machine enforced in
    `set_wiring_group_status`, and a new "กลุ่มต่อสาย" management section
    in `teacher_aiot_lab_page.dart` — see `WORK_LOG.md` for full detail.
    This closes all 6 items of the teacher-dashboard fake-data audit.
  - Top KPI row + `_TeacherHero` banner — **fixed 2026-08-28**. Both reuse
    2 shared helpers (`_fetchPendingReviewTotal`/`_fetchFlaggedStudentTotal`)
    for the numbers items 2/3 already made real; the 4th KPI tile
    ("ห้องปกติ", which had no real backing anywhere) was relabeled
    "วิชาที่สอน" (real active-course count) rather than faked.
  - **Known gap**: `TeacherMock.lessons`/`.reviewTasks` are still directly
    referenced at ~3 other call sites in `teacher_redesign_prototype_page.dart`
    (not the shared `_ScheduleCard`/`_ReviewQueueCard` widgets, which are
    fixed) — likely other prototype breakpoint/variant layouts not reached
    by the default route, not independently confirmed dead.
  - `_TodayFocusCard`'s remaining 3 rows — **fixed 2026-08-28**. Each row
    got its own precisely-scoped real definition rather than reusing
    `_ReviewQueueCard`/`_StudentsWatchCard`'s numbers verbatim: "งานรอตรวจ"
    reuses `_fetchPendingReviewTotal()`; "นักเรียนไม่ส่งงาน" is a new,
    looser metric (`_fetchNotSubmittedStudentTotal()` — ≥1 unsubmitted
    published assignment, vs. "ต้องติดตาม"'s ≥2 threshold); "คาบถัดไป" is
    a new `_fetchNextPeriodLabel()` picking today's next not-yet-started
    schedule slot, honestly showing "ไม่มีคาบแล้ว" when none remain.
  - **Fixed 2026-08-28, found via a live screenshot, not part of the
    6-item list above**: `_ClassesCarousel`'s "ฉบับร่าง"/"เผยแพร่แล้ว" badge
    checked `course.status == 'published'`, but real `courses.status` is
    `active`/`closed` — the check could never be true, so every real
    course always showed "ฉบับร่าง". Now uses `course.isActive`. Also
    fixed a real `_SubmissionBarChartCard` overflow (`SizedBox(height: 140)`
    was ~2px too short for real 100% data) by bumping to 148.
- **`supabase_migrations.schema_migrations` tracking table doesn't match the
  files on disk** (53 tracked rows vs 61 files as of 2026-08-22). Several
  migrations this week were applied via `docker exec ... psql < file.sql`
  directly because `npx supabase migration up`/`--include-all` kept erroring
  on out-of-order/duplicate-version conflicts, which bypasses the CLI's
  tracking. Every migration file involved uses `create or replace`/`if not
  exists`/`on conflict`, so a full `npx supabase db reset` should converge to
  the same state and rebuild the tracking table cleanly — do that rather than
  hand-editing `schema_migrations`.
- `~/aiot_dev_dashboard` is 4/27 pages real, 23 mockup (see repo layout note
  above) — treat anything under `lib/pages/school_admin/*`,
  `devices_page.dart`, `permissions_page.dart`, `alerts_logs_page.dart`,
  `settings_page.dart`, `device_test_page.dart`, `scan_page.dart`,
  `kiosk_pairing_scanner_page.dart` as **not persisting data** until wired to
  a repository like `SchoolRepository`.
- `KioskPairingScannerPage` (in `~/aiot_dev_dashboard`) has no "Mock Preview"
  banner — it opens via a fullscreen `Navigator.push` outside both
  navigation shells that carry the banner elsewhere. Needs a live
  camera/device test before touching its layout, so left alone for now.

### Lesson-materials upload/download — verified (commit `26d0343`)

Commit `b7628f6` added the lesson-materials upload/download Edge Functions
and migration (`20260823010000_lesson_material_upload.sql`,
`supabase/functions/lesson-material-upload/`,
`supabase/functions/lesson-material-download/`). This was driven end-to-end
via `curl` (sign in as teacher → upload → register material → sign in as
student → download → diff bytes against the original) and two real bugs
were found and fixed in the process:

1. `get_lesson_material_for_download` declared `RETURNS TABLE(storage_path
   text, ...)` but returned `lesson_materials.url` (`varchar`) uncast —
   Postgres rejected the call with a type mismatch on every invocation.
2. The function's `EXECUTE` grant only covered `anon, authenticated`, but
   the Edge Function calls it with the **service-role** client — so it had
   no permission to call its own RPC and always failed.

Fixed in `26d0343`. Full upload→download round-trip is now confirmed
working, plus probes (student tries to upload, invalid session token,
missing required field) all correctly rejected.

**The same grant bug existed in the older `course_files` feature**
(`get_course_file_for_download`, same service-role-calls-ungranted-function
shape) — course file downloads were silently broken the same way. Fixed in
`908707e` (new migration `20260823020000_fix_course_file_download_grant.sql`,
not editing the original `20260731020000_course_files.sql` — see the "not
editing shipped migrations" rule in `CLAUDE.md`). Also verified end-to-end
with the same upload→download→byte-diff method.

**Takeaway for future Edge Functions in this codebase**: if a function
calls an RPC using the service-role client (the pattern used by every
upload/download function so far), that RPC's `grant execute ... to` list
**must include `service_role`**, not just `anon, authenticated`. This has
now bitten two features; check for it explicitly when adding a third.

### Submission review — wired to real data (commits `ef80971`, `c03955b`)

`teacher_submission_review_page.dart` (`TeacherSubmissionRosterPage`, opened
from `teacher_grading_page.dart` via "ตรวจงาน") was 100% mock. Changed:

| Piece | Before | After |
|---|---|---|
| Roster of students | Hardcoded `_mockSubmissions()` list of 5 fake names | `AssignmentService.listSubmissions(assignmentId)`, filtered to `status != 'not_submitted'` |
| Rubric | Hardcoded `_mockAssignmentRubric()` (2 fixed criteria) | Teacher picks from `RubricService.listMyRubrics()`, full criteria loaded via `RubricService.getRubric(id)` on selection — see "why a picker, not auto-linked" below |
| AI-suggested scores, anomaly warnings, "apply AI suggestion" button | Hardcoded fake data (`aiSuggestedLevelIndex`, `aiAnomalyNote`, etc.) presented as if a real AI ran | **Removed entirely.** No AI backend exists; showing this would fabricate output and mislead the teacher. |
| "I'm this student's parent (CoI)" checkbox | Manual checkbox, teacher self-reports | **Removed.** `create_grade` already auto-detects CoI server-side from `parent_links`; the Decision Log explicitly forbids a client-settable `coi_flag`. The checkbox was redundant and architecturally wrong. |
| Saving a score | `setState` only, nothing persisted | `GradeService.createGrade(...)` (new) or `updateGrade(...)` (re-scoring a draft), then a separate explicit `GradeService.confirmGrade(...)` step |
| Feedback text | `setState` only | `AssignmentService.giveFeedback(submissionId, body)` |
| "Already graded" status on page load | N/A (was all fake data) | **Deliberately not shown.** `grades` has no `assignment_id` column — a grade fetched via `GradeService.listCourseGrades(courseId)` can't be attributed to a specific assignment, so in a course with 2+ assignments the wrong grade could get displayed against this one. Left unsolved rather than guessed; needs an `assignment_id` column (new migration) to do properly. |

**Why a rubric picker instead of assignment→rubric auto-linking**:
`assignments.rubric_id` exists as a column in the schema, but no RPC
(`create_assignment`, `update_assignment`) ever sets it — there's no way to
actually link a rubric to an assignment through the app today. Building that
link (new migration adding a `p_rubric_id` param) was out of scope for this
pass, so the page asks the teacher to pick a rubric each time instead of
assuming a link that can't exist yet.

Verified against the real local DB end-to-end (not just `flutter analyze`):
created a rubric via `create_rubric`/`add_rubric_criterion`, then
`list_submissions` → `create_grade` → `give_feedback` → `confirm_grade`
against a real seeded submission, confirmed via `list_feedback`.
`flutter build web` passes.

### G-Score (LRN-11/LRN-12) — built from scratch (migration `20260823030000_g_score.sql`)

`teacher_gscore_confirm_page.dart` used to be an honest placeholder ("no
table/RPC exists yet for this"). It was true — there was no G-Score anything
in the schema. Built the whole thing this pass:

- **New table** `g_score_entries` (student_id, course_id, source
  `lesson_completed`/`assignment_on_time`, source_id, points, status
  `pending`/`confirmed`, confirmed_by/confirmed_at). Unique on
  `(student_id, source, source_id)` so a lesson/assignment can only ever
  award points once.
- **LRN-11 (auto-accumulate)**: hooked directly into the existing
  `mark_lesson_complete` and `submit_assignment` RPCs (both redefined via
  `create or replace function` in the new migration — the original migration
  files that first created them are untouched). A lesson awards 10 points
  the first time it's completed; an assignment awards 15 points only on the
  *first* submission and only if it lands before `due_at`. Point values are
  placeholder tuning, not from any spec.
- **LRN-12 (teacher confirms)**: `list_pending_g_score`/`confirm_g_score`,
  scoped to courses the teacher actually teaches (`course_teachers`).
  Students never see pending points — `list_my_g_score` filters
  `status = 'confirmed'`, same gate pattern as `list_my_grades`.
- `shared_core`: new `GScoreService` + `g_score_model.dart`
  (`PendingGScoreEntry`, `MyGScoreEntry`).

Verified against the real local DB end-to-end: completed a real lesson as
the seeded student (`mark_lesson_complete`) → confirmed a `g_score_entries`
row landed as `pending` → re-completing the same lesson did **not** create a
duplicate → teacher's `list_pending_g_score` showed it → student's
`list_my_g_score` returned empty *before* confirm and the entry *after* →
teacher's pending list emptied out → confirming the same entry twice
correctly raised `already_confirmed`. `flutter build web` passes.

**Not done**: a student-facing "my G-Score" display page (only the backend
+ teacher confirm UI exist so far — no page reads `listMyGScore()` yet).

### 2026-08-22 — `aiot_dev_dashboard` integration, security incident, and RBAC audit

Another AI agent working on this same repo ("agy") integrated
`~/aiot_dev_dashboard` (a separate, more mature Super Admin app — see repo
layout note above) against this project's shared local Supabase instance.
This introduced a real, verified security vulnerability, which was found,
reported, and fixed the same day — full trail below in case similar work
happens again.

**The vulnerability**: `20260823060000_admin_dev_dashboard_compatibility.sql`
and `20260823080000_super_admin_hardening_rls_and_health.sql` added
`anon`-permissive RLS policies (`using (true)`) and direct `grant ... to anon`
statements on `devices`, `schools`, `sensor_readings`, `device_commands`,
`users`, `user_roles`, plus two new views `profiles`/`alerts` also granted to
`anon` — all reachable with just the public anon key, no login. Confirmed
exploitable via real unauthenticated `curl` (not `docker exec` as postgres,
which bypasses RLS and gives a false-safe reading):
```bash
curl "http://127.0.0.1:54321/rest/v1/profiles?select=email,role,school_id" \
  -H "apikey: $ANON_KEY" -H "Authorization: Bearer $ANON_KEY"
# → 200, every user's email/name/role/school_id, no auth at all
```
A first fix pass (`20260823100000_close_anon_rls_holes.sql`) correctly
dropped the anon policies/grants on the 8 base tables and added proper
`authenticated`-only policies keyed on new `is_super_admin()`/
`get_auth_school_id()` `SECURITY DEFINER` helpers — but missed the
`profiles`/`alerts` **views**, which run with the view owner's privileges by
default and bypass the underlying tables' RLS entirely regardless of how
locked-down `users`/`sensor_alerts` are. Closed in
`20260823110000_close_anon_view_leak.sql` (`revoke all on
profiles/alerts from anon`). Re-verified with the same curl method — all
three surfaces (`/devices`, `/profiles`, `/alerts`) now return `401
permission denied` for anon.

**Follow-on findings from independently re-verifying self-reported fixes**
(pattern worth repeating: every "100% done"/"verified" claim this session,
when actually re-tested, had something incomplete):
- `is_super_admin()` had a hardcoded `or u.email =
  'admin@aiot-school-lab.local'` bypass independent of `user_roles` — a
  latent privilege-escalation path for anyone who ever gets that exact
  email. Removed in `20260823130000_fix_is_super_admin_email_bypass.sql`.
- A claimed "OTP error message fixed" migration actually edited
  `apps/user_app/lib/pages/login_page.dart` (wrong app — that flow doesn't
  even exist in `aiot_dev_dashboard`'s login, which is plain
  `signInWithPassword` with no OTP/Edge Function at all) and introduced a
  regression (an over-broad `'functionexception'` string match that would
  mislabel unrelated errors). Reverted; the real fix landed in
  `apps/admin_app/lib/pages/admin_login_page.dart` instead, since that's
  where the OTP-cooldown `FunctionException` genuinely is reproducible
  (`AuthService.signIn` → `auth-sign-in` Edge Function → this repo's own
  `auth_sign_in` RPC, which does have 2FA/rate-limiting).
- A claimed "banner added to 23 mockup pages" turned out to actually be
  correct on closer reading (the banner is injected by two shell wrappers,
  not per-file — grepping individual files for the banner string was the
  wrong check) — logged here as a reminder that "verify the claim" cuts
  both ways; not everything that looks wrong on a shallow check actually is.

**RBAC audit (task tracked as #77)** — tested cross-tenant/cross-role access
live for every role, using real login sessions and temporary throwaway test
data (created, tested, deleted each time — never left in the seed data):

| Role | Attack tried | Result |
|---|---|---|
| `school_admin` (aiot_dev_dashboard) | Read another school's `schools`/`devices` rows, by id and by broad select | Blocked (RLS) |
| `student` | Guess another student's `student_personal_tasks`/`incident_reports` id | Blocked (`forbidden`/`not_found`, ownership checks in RPC) |
| `teacher` | `get_course`/`list_course_students`/`list_assignments` on a course they don't teach | Blocked (`forbidden`) |
| `parent` | `grant_parent_consent`/`withdraw_parent_consent` using another parent's `parent_link_id` | Blocked (`approved_parent_link_required`) |
| `executive` | Check `count_school_users_by_role` for PII leakage | Clean — role+count only, no names/emails |
| `facility_manager` | `queue_device_command` on a device outside their assigned building | **Vulnerable — fixed** |

`queue_device_command` (`supabase/migrations/20260721010000_relay_commands.sql`)
only checked the target device's `school_id`, never the caller's `building`
for `facility_manager` — even though `list_devices_in_my_building` and
`sensor_latest` both correctly enforce that scope elsewhere (BR4: "อาคารที่
รับผิดชอบเท่านั้น"). A facility manager who knew/guessed a `device_id`
outside their building could queue a real command against it. Fixed in
`20260823140000_fix_facility_manager_device_command_scope.sql` (same
building-prefix check pattern as the other two functions); re-verified the
exploit now 403s, same-building control still works, and
`school_admin`/`super_admin`/`technician` (intentionally unrestricted by
building) are unaffected.

### 2026-08-24 — critical auth-bypass fix, full 9-table RLS role-check fix, complete RBAC audit

Continuation of the 2026-08-22 security work above. Two more real, verified
vulnerabilities found and closed the same day, plus the RBAC audit (tracked
internally as "#77") is now considered complete across both apps.

**Unauthenticated privilege escalation** (`20260824000000_fix_school_admin_batch_import_auth_bypass.sql`):
a follow-on migration from agy (`import_school_users_batch`,
`archive_school_device`, `archive_school_user`) had the same bug shape three
times — `if auth.uid() is not null then <check> else <nothing>` is fail-open,
not fail-closed. `auth.uid()` is NULL for `anon`, and all three had `grant
execute ... to anon`. Confirmed live: an unauthenticated request created a
real `super_admin` account with just the public anon key, no login at all.
Fixed by making the check unconditional and revoking `anon`'s execute grant.

**Missing role checks across 9 RLS policies** (`20260824020000_fix_school_member_rls_missing_role_checks.sql`)
— the bigger one. Every `school_user_isolated_*` policy added for
`aiot_dev_dashboard` (`devices`, `schools`, `thresholds`, `school_settings`,
`device_commands`, `device_logs`, `control_approval_requests`,
`sensor_readings`, `users`) checked `school_id` only, never role, under a
single `for all`. Confirmed live: `student@` — a plain student account —
successfully changed a real device's status via a direct PATCH to
`/rest/v1/devices`, and could read `password_hash` for every user in the
school via `.from('users').select('email,password_hash')`. Also found
auditing grants: `control_approval_requests` and `device_logs` had
`TRUNCATE` granted to `authenticated` — RLS does not apply to `TRUNCATE` in
Postgres, so any authenticated user could have wiped either table for every
school in one call. Fixed by splitting each policy into a school-scoped
SELECT (kept broad) and role-gated INSERT/UPDATE/DELETE
(`has_role('school_admin')`/`'technician'` depending on the table), a
column-level revoke on `users.password_hash`, and revoking `TRUNCATE`.

**Convention going forward**: any new RLS policy on a table shared with
`aiot_dev_dashboard` needs *two* checks, not one — school membership *and*
role for anything beyond SELECT. See the note at the top of
`DATABASE_SCHEMA.md`'s table list for which tables this applies to.

**Full RBAC audit results** — every role tested live against real login
sessions and disposable test data (created, tested, deleted each time):

| Area | Test | Result |
|---|---|---|
| `my_first_app` | student guesses another student's `student_personal_tasks`/`incident_reports` id | Blocked |
| `my_first_app` | teacher opens a course they don't teach | Blocked |
| `my_first_app` | parent uses another parent's `parent_link_id` | Blocked |
| `my_first_app` | executive's aggregate RPC leaks PII | Clean, role+count only |
| `my_first_app` | facility_manager controls a device outside their building | **Was vulnerable, fixed** (`queue_device_command`) |
| `aiot_dev_dashboard` | school_admin reads/writes another school's rows, all 9 RLS-fixed tables | Blocked, cross-checked against direct DB state each time |
| `aiot_dev_dashboard` | student writes `devices`/`device_commands` directly | **Was vulnerable, fixed** |
| `aiot_dev_dashboard` | teacher/facility write `devices`/`device_commands` | Blocked (as intended — only school_admin/technician/super_admin should) |
| `aiot_dev_dashboard` | technician writes `devices`/`device_commands` | Allowed (as intended) |

Also independently re-ran the pgTAP suite (`npx supabase test db`) rather
than trusting a self-report: found `03_auth_session_rate_limit.test.sql`
failing 2 subtests (`auth_sign_out_all` wasn't actually revoking sessions —
a real "log out everywhere" bug, security-relevant for a lost/stolen
device scenario), reported it, agy fixed it, re-ran independently a second
time and confirmed `Files=24, Tests=236, Result: PASS`.

Full remaining backlog (feature completeness, not security) written up in
`docs/handoff/agy-brief-full-remaining-backlog-2026-08-24.md`.

**RBAC audit continuation (2026-08-27)** — the above audit predates the
2026-08-25 role merge (`facility_manager`→`school_admin`,
`technician`→`super_admin`) and the ~20 migrations/68 RPCs added since,
so task #77 was re-opened to cover that gap rather than assumed still
current. Findings:

- **Role merge itself: clean.** `queue_device_command`/`list_school_devices`/
  `sensor_latest` no longer have any building-level restriction for
  `school_admin` — confirmed this is the *intended* outcome of "unified in
  the school_admin portal without per-building silos" (see Deferred
  Features #2 above), not a regression, and it's applied consistently
  across all three (no case where reads are building-scoped but writes
  aren't, or vice versa). No live `facility_manager`/`technician` string
  survived in any function body (checked all of `public.*`, `prokind='f'`)
  and the `role_type` enum is cleanly pruned to the 6 current roles — one
  harmless exception: `set_facility_manager_building` kept its old *name*
  (its logic already correctly checks `school_admin`/`super_admin`) —
  cosmetic, a rename would be nice but isn't a security issue, not done.
- **All 68 RPCs added/changed since 2026-08-24 statically reviewed** for
  the standard pattern (`get_session_actor` → role whitelist → `school_id`
  scoping from the actor, never from client input). Every one that should
  have the pattern has it; the handful that don't are pre-auth flows by
  design (`accept_staff_invitation`, `redeem_parent_binding_code`,
  `auth_select_role`, `auth_validate_session` — token-scoped, single-use,
  fail-closed on their own terms) or the pg_cron-only
  `_run_due_device_schedules` (confirmed `execute` revoked from
  `anon`/`authenticated`/`service_role`, only `postgres` can call it).
  Bulk-import functions (`import_school_*_batch`) all insert with
  `v_actor.school_id`, never a client-supplied school id — no cross-tenant
  injection path. `add_secondary_role`/`update_user_role` both block
  self-role-changes and block `school_admin` from granting/touching
  `super_admin`.
- **Live-verified, not just read**: minted real throwaway sessions (deleted
  after) for `student` and `school_admin` and fired real requests at
  `/rest/v1/rpc/...` — `student` → `create_school_for_super_admin`,
  `import_school_devices_batch`, and self-promoting via `update_user_role`
  all correctly `403`/`forbidden`; `school_admin` → granting another user
  `super_admin` via `add_secondary_role` correctly `forbidden_role_grant`;
  `student` calling the legacy `auth.uid()`-based `resolve_sensor_alert`
  (built for `aiot_dev_dashboard`, not this app) correctly `invalid_session`
  since this app's client never has a real Supabase Auth JWT.
- **No new vulnerabilities found** in this pass, unlike 2026-08-22/24 which
  each found and fixed a real one — the newer RPCs were mostly written
  after those fixes landed and evidently followed the corrected pattern.
  Task #77 is complete again as of this date.

## Deferred Features & Architecture Decisions (updated 2026-08-25)

### 1. Direct Parent-Teacher In-App Messaging (Deferred)
Direct 1-on-1 parent-teacher chat was intentionally deferred and not built into the app:
- **School Communication Norms**: Line Official Account (LINE OA) and broadcast announcement channels are universally preferred in Thai schools for general school-to-parent communications rather than building custom in-app chat from scratch.
- **Teacher Boundaries & Workload**: Teachers strongly oppose unstructured 24/7 personal chat channels where 40+ parents per classroom can message at all hours without school office mediation.
- **Sufficient Structured Channels**: The existing structured workflows — parent binding verification (`parent_binding_requests`), automated SOS/incident alerts, attendance tracking, and published grade/assignment reports — fulfill genuine communication needs without creating unmoderated chat debt or data retention overhead.

### 2. Role Merge (Technician → Super Admin, Facility Manager → School Admin)
To eliminate administrative fragmentation and multi-role friction:
- **Technician role merged into `super_admin`**: Device registration, firmware updates, and infrastructure-level diagnostics are managed by super admins.
- **Facility Manager role merged into `school_admin`**: School-wide energy monitoring, CCTV access management, device automation schedules, and relay switches are unified in the `school_admin` portal without per-building silos.
- The `UserRole` enum in `shared_core` was pruned to 6 canonical roles (`super_admin`, `school_admin`, `teacher`, `student`, `parent`, `executive`).

### 3. IoT Command Rate Limiting & Feedback (Hardening)
- `queue_device_command` enforces a sliding-window rate limit of **20 commands per device per minute** via `device_command_rate_limits`, throwing a clean `rate_limited` exception to protect physical relay hardware from command flooding.
- Command delivery acknowledgement relies on physical hardware firmware; the UI honestly presents "คำสั่งถูกส่งเข้าคิวแล้ว — รออุปกรณ์ตอบรับ" without faking instantaneous delivery.

### 4. Multi-role login (Phase 1, 2026-08-25)
One account can now hold more than one role at once (e.g. a teacher who
is also `school_admin`) — `add_secondary_role` RPC grants an additional
role without deleting the existing one (`update_user_role` still fully
replaces, for the ordinary single-role-change case; the two are
deliberately separate functions). At login, `auth_sign_in` returns
`role_selection_required` instead of auto-picking when an account has
2+ roles; the new `auth_select_role` RPC (backed by its own edge
function, `supabase/functions/auth-select-role/` — **must be registered
in `supabase/config.toml`** with `verify_jwt = false`, same as
`auth-sign-in`, or it 404s) validates the choice and runs the same
OTP-issuing path as a normal login for OTP-required roles. **No in-app
role switch, no "remember this device"** — both were deliberately
rejected after a pre-mortem: an in-app switch without re-authenticating
would let a session that only ever proved itself via a low-stakes role
slide into a high-stakes one without ever passing OTP for it; switching
roles means logging out and back in, so every switch is a real,
fully-authenticated `auth_sign_in` call. `teacher@aiot-school-lab.local`
is seeded with a second `school_admin` role as a permanent test fixture
for this feature — don't remove it.

### 5. Super Admin Redesign — Phase 1 (2026-08-25)
Integrated Super Admin platform capabilities directly into `apps/user_app` backed by custom session token RPCs (avoiding direct table reads and aligning with the monorepo's token-based security architecture):
- **Database Migration (`supabase/migrations/20260826090000_super_admin_redesign_phase1.sql`)**:
  - `list_schools_for_super_admin(p_token text)`: Aggregates real-time stats across all schools (users count, devices online/total, building/room counts, open alerts, last sync). Strict `super_admin` role enforcement.
  - `create_school_for_super_admin(...)`: Inserts school, auto-generates `SCH-YYYYMM-XXXX`, sets status to active, writes audit log.
  - `update_school_for_super_admin(...)`: Updates school metadata & quotas, writes audit log.
  - `set_school_status_for_super_admin(...)`: Updates status (`active` / `suspended` using `user_status` enum), writes audit log.
  - `list_device_control_data_for_super_admin(p_token text)`: Comprehensive device control JSON payload.
  - `create_control_approval_request(...)`: Submits approval request to real `control_approval_requests` table with status `'pending'`.
  - `decide_control_approval_request(...)`: Approves/rejects request; if approved, automatically queues command via `queue_device_command`.
- **Dart Layer (`packages/shared_core`)**:
  - `models/super_admin_model.dart`: Typed models for platform schools, device controls, approvals, permissions, and audit logs.
  - `services/school_admin_platform_service.dart`: Client service exposing typed RPC calls.
- **Frontend Pages (`apps/user_app/lib/pages/super_admin/`)**:
  - `super_admin_schools_page.dart`: Full-featured school management (search, filter, create, edit, suspend/activate, quota inspection).
  - `super_admin_device_control_page.dart`: Multi-school device overview, mode switching, emergency stop, and approval workflows.
  - `super_admin_dashboard.dart`: Dashboard cards and drawer navigation wired to the new pages.
- **Scope clarification**: These 2 pages (`schools_page` and `device_control_page`) were Phase 1's scope. The remaining 6 super_admin pages were ported in Phase 3 (2026-08-25/26, see section 12) — all 8 are now live. The other ~19 mockup pages in `aiot_dev_dashboard` belong to that separate app, not this one.
- **Independently re-verified 2026-08-25** (not just trusting agy's report): all 7 RPCs live-tested with real session tokens including a negative-role probe, a full school create→update→suspend round trip, and a full approval-request→decide→real `queue_device_command` dispatch round trip (confirmed a real row lands in `device_commands`, and the double-decide guard rejects a repeat decision). Real browser click-through of both pages, data matched the DB. Found and fixed 2 process issues that don't affect the code itself: a migration-timestamp collision with an already-committed migration (renamed `20260826080000`→`20260826090000`), and a real `control_approval_requests`/`device_commands` row agy's own testing left in the shared dev DB (deleted).

**Old-UI-file policy, decided 2026-08-25** (for this redesign effort and any similar one going forward): once a page's new design is live, verified, and fully replaces the old one, **delete the old file** — don't leave it sitting around (this is what happened with `facility_redesign_prototype/`, `technician_dashboard.dart`, `building_admin_dashboard.dart` during the role merge). Right now, three different states exist at once, don't conflate them:
1. **`dashboard/super_admin_dashboard.dart`** — **no longer the live entry point as of 2026-08-26** (`agy-brief-super-admin-root-shell-swap.md`, verified live). `role_router.dart` now sends `super_admin` straight to `super_admin/super_admin_hub_page.dart`, which has all 8 real menu items. The old shell file is retained on disk (unreferenced) per the "keep until verified, then delete" rule below — safe to delete now that the swap is verified, not yet done.
   **`dashboard/school_admin_dashboard.dart`** — **no longer the live entry point as of 2026-08-25** (`agy-brief-school-admin-root-shell-swap.md`, verified live). `role_router.dart` now sends `school_admin` straight to `school_admin/school_admin_dashboard_page.dart`, which has all 20 real menu items (12 redesigned pages + 8 old-style pages folded into its sidebar/drawer/quick-action grid). The old shell file is retained on disk (unreferenced) per the "keep until verified, then delete" rule below — safe to delete now that the swap is verified, not yet done.
2. **Already-dead files unrelated to this redesign** (`dashboard/parent_dashboard.dart`, `dashboard/executive_dashboard.dart`) — confirmed zero references anywhere, `role_router.dart` doesn't point to either. Safe to delete now, independent of the redesign timeline — nobody's waiting on them.
3. **Old-style pages still reachable from the new school_admin shell** (`school_admin_cctv_page.dart`, `school_admin_energy_page.dart`, `school_admin_esg_page.dart`, `school_admin_device_schedule_page.dart`, `school_admin_device_control_page.dart`, `school_admin_incident_inbox_page.dart` — these already have real backend data, just the older plain visual style, and haven't been redesigned) — keep exactly as-is until each gets its own Phase 3+ redesign replacement live and verified; don't delete or touch them preemptively. Same applies to `super_admin`'s 6 not-yet-touched sub-pages.

### 6. School Admin Redesign — Phase 2 Batch 1 (2026-08-25)
Ported the first batch of 7 reuse-heavy pages into `apps/user_app/lib/pages/school_admin/` backed by custom session RPCs in `20260826100000_school_admin_redesign_phase2_alerts.sql` and existing core services:
- **Backend & Models**:
  - Added `list_school_alerts`, `acknowledge_sensor_alert_for_school_admin`, `resolve_sensor_alert_for_school_admin`, and `import_school_users_batch_for_school_admin` custom session RPCs with strict `SELECT INTO ... IF NOT FOUND` validation.
  - Added `SchoolSensorAlertRecord` model and incident service methods (`listSchoolAlerts`, `acknowledgeSensorAlert`, `resolveSensorAlert`).
  - Added `importSchoolUsersBatch` to `UserAdminService`.
- **UI Pages & Navigation**:
  - Ported 7 pages (`school_students_page`, `school_teachers_page`, `school_permissions_page`, `school_import_page`, `school_alerts_page`, `school_resources_page`, `school_devices_page`), each wrapped in `Scaffold` for standalone/modal navigation support.
  - Fully wired into `school_admin_dashboard.dart` in both `AppDrawer` and interactive dashboard body cards.
- **Architectural Scope**:
  - `school_devices_page.dart` acts as an Asset Inventory / Hardware Directory, sitting alongside `school_admin_device_control_page.dart` (relay controls) and `school_admin_device_schedule_page.dart` (cron schedules).
- **Verification**:
  - 47/47 tests passed in `apps/user_app`, 44/44 tests passed in `packages/shared_core`.
  - Next: Batch 2 (genuinely new pages: dashboard, profile, buildings, reports, settings, scan).

### 7. School Admin Redesign — Phase 2 Batch 2 (2026-08-25)
Completed the remaining 6 new pages in `apps/user_app/lib/pages/school_admin/` backed by 4 session-based RPCs in `supabase/migrations/20260826110000_school_admin_redesign_phase2_batch2.sql`:
- **Backend & Models**:
  - `list_school_buildings(p_token text)` & `list_school_rooms(p_token text, p_building_id uuid)`: Dynamic hierarchical inspection of physical school spaces, active sensor nodes, and room capacities.
  - `get_school_admin_dashboard_summary(p_token text)`: Aggregated dashboard KPI counters and energy/incident summaries for the school admin.
  - `list_school_admin_audit_logs(p_token text, p_limit int)`: Recent security and administration audit log stream.
  - `packages/shared_core/lib/models/school_building_model.dart`: Typed models for `SchoolBuildingRecord` and `SchoolRoomRecord`.
- **UI Pages**:
  - `school_admin_dashboard_page.dart` (modern desktop sidebar + mobile drawer hub with interactive KPI cards, room status grid, quick actions, and recent activity).
  - `school_admin_profile_page.dart`, `school_buildings_page.dart`, `school_reports_page.dart`, `school_settings_page.dart`, and `school_scan_page.dart`.
- **Verification**:
  - Full positive, garbage token, and cross-school role isolation probes tested and passed 100%.

### 8. Teacher Lesson Editor Data Loss Fix (2026-08-25)
Fixed the critical data loss bug where editing a lesson wiped out blocks, materials, and sensor links:
- **Root Cause**: `_loadRealLessons()` populated state from `list_lessons` (summary-only) with empty dummy fields (`materials: []`, single dummy block). When the user modified any field, autosave fired `update_lesson` replacing existing database content with placeholders.
- **Fix**:
  - `teacher_lesson_editor_page.dart`: Added `_loadFullLesson()` which calls `get_lesson` to fetch complete blocks, materials, and sensor links before unlocking the editor (`_isLoading` guard prevents premature autosave).
  - `supabase/migrations/20260826120000_enhance_list_lessons_counts.sql`: Added `materials_count` and `sensor_links_count` to `list_lessons` to render badge counts efficiently without N+1 queries.
  - `student_lesson_view_page.dart`: Replaced raw 500 error display with user-friendly Thai guidance.
- **Verification**:
  - Re-tested with live edit + autosave cycle; content preserved 100%. All unit tests and SQL probes passed.

### 9. School Admin Root Shell Swap (2026-08-25)
Swapped the root route in `apps/user_app/lib/pages/role_router.dart` for `UserRole.schoolAdmin` from the legacy `SchoolAdminDashboard` (`dashboard/school_admin_dashboard.dart`) to the modern indigo/amber `SchoolAdminDashboardPage` (`school_admin/school_admin_dashboard_page.dart`):
- **Full 20-Item Navigation Coverage**:
  - Folded in all 8 existing operational features alongside the 12 core redesigned pages, bringing total navigation to 20 items:
    1. `แดชบอร์ดภาพรวม` (`_HomeDashboard`)
    2. `จัดการนักเรียน` (`SchoolStudentsPage`)
    3. `ครูและบุคลากร` (`SchoolTeachersPage`)
    4. `นำเข้าข้อมูล` (`SchoolImportPage`)
    5. `กำหนดสิทธิ์` (`SchoolPermissionsPage`)
    6. `อาคารและห้อง` (`SchoolBuildingsPage`)
    7. `อุปกรณ์` (`SchoolDevicesPage`)
    8. `การใช้ทรัพยากร` (`SchoolResourcesPage`)
    9. `สแกนคิวอาร์โค้ด` (`SchoolScanPage`)
    10. `การแจ้งเตือน` (`SchoolAlertsPage`)
    11. `รายงาน` (`SchoolReportsPage`)
    12. `ตั้งค่าโรงเรียน` (`SchoolSettingsPage`)
    13. `จัดการผู้ใช้` (`UserListPage` from `package:shared_ui`)
    14. `Consent Policy` (`ConsentPolicyAdminPage` from `package:shared_ui`)
    15. `พลังงานทั้งโรงเรียน` (`SchoolAdminEnergyPage`)
    16. `กล้อง CCTV` (`SchoolAdminCctvPage`)
    17. `ตั้งเวลาอุปกรณ์` (`SchoolAdminDeviceSchedulePage`)
    18. `รายงาน ESG` (`SchoolAdminEsgPage`)
    19. `ควบคุมไฟและน้ำ` (`SchoolAdminDeviceControlPage`)
    20. `กล่องแจ้งเหตุการณ์` (`SchoolAdminIncidentInboxPage`)
    21. `โปรไฟล์ผู้ใช้งาน` (`SchoolAdminProfilePage` via footer user card)
- **Responsive Layout & Visual Fixes**:
  - Added bounded constraint protections to desktop and mobile layout trees (`SizedBox.expand`, scoped `ScaffoldMessenger`, flexible text truncations).
  - Resolved `RenderFlex` overflow warnings in alert and activity rows.
- **Verification**:
  - Widget & screenshot tests (`school_admin_dashboard_page_test.dart`, `school_admin_screenshot_test.dart`) verify all 20 navigation paths, profile card, drawer toggling, and desktop/mobile responsiveness.
  - Legacy shell `dashboard/school_admin_dashboard.dart` is retained in the codebase for safety.

### 10. School Admin Silent Fake-Fallback Data Fix (2026-08-25)
Fixed silent mock fallbacks and unhandled zero-count empty states across all 13 School Admin redesign pages:
- **Root Cause Eliminated**:
  - Replaced silent `catch (_) {}` error swallowing with explicit error banners/cards with retry capabilities (`_HomeSummaryGrid`, `_HomeAlertPanel`, `_HomeRecentActivity`).
  - Removed `if (data.isNotEmpty)` state update guards so genuine empty/zero-count schools show honest Thai empty states instead of retaining mock rows/cards.
- **Tier A (Real Backend Available — UI Fixed)**:
  - `school_admin_dashboard_page.dart`: KPI summary grid, open alert panel, and recent audit activity now load real data from `get_school_admin_dashboard_summary`, `list_school_alerts`, and `list_school_admin_audit_logs`.
  - `school_buildings_page.dart`, `school_students_page.dart`, `school_teachers_page.dart`, `school_devices_page.dart`, `school_permissions_page.dart`, `school_import_page.dart`, and `school_alerts_page.dart`: Initialized with empty lists `[]` and render honest empty states for main entities and audit logs.
- **Tier B (No Backend Schema/RPC — Honest Disclosures)**:
  - `school_settings_page.dart`: Prominent amber notice explaining that school settings/security configurations are not yet connected to the backend; save actions warn user of preview mode.
  - `school_admin_profile_page.dart`: Notice explaining that extra fields (phone/employee-code/department) are pending backend support; save warns of preview mode.
  - `school_reports_page.dart`: Replaced fake download cards with an honest development notice banner; summary metrics pull real data from `fetchDashboardSummary()`.
- **Verification**:
  - Dedicated widget test suite `school_admin_empty_and_error_states_test.dart` (10/10 tests passed).
  - 100% tests passing across all suites (67/67 in `user_app`, 47/47 in `shared_core`).

### 11. Follow-up fixes after live user testing (2026-08-25)

User caught 3 more issues by clicking through the real app after section 10 shipped — fixed directly (small, well-understood, not worth a full agy-brief cycle):

- **`_AssignmentOverview` widget** (home page's "การมอบหมายและสิทธิ์" card, also duplicated numbers on the teachers page) was still 100% hardcoded (`'กำหนดแล้ว 32 ห้อง จาก 34 ห้อง'`, `'6 อาคาร'`, `'รอตรวจสอบสิทธิ์ 4 บัญชี'`) — missed by section 10's audit because it never attempted a fetch at all (no `try/catch` to grep for). Converted to a `StatefulWidget` that fetches real `fetchRooms()`/`fetchBuildings()`/`getAllUsers()` and shows real coverage counts (rooms with a homeroom teacher assigned, buildings with a manager assigned, active vs total user accounts), with proper loading/error states matching the section 10 pattern.
- **`school_students_page.dart`'s per-grade-level breakdown** ("จำนวนนักเรียนแต่ละระดับชั้น") was a hardcoded `const` list totaling exactly 1,250 students (ม.1–ม.6: 205/211/208/206/210/210) — same root number as the original bug report, just relocated. Also missed by section 10's grep (inline `const` inside a build method, not a `final List<_Class> _field = [...]` class field). Now computed by grouping the page's already-fetched real `_students` list by `level`.
- **`school_teachers_page.dart` showed 0 teachers** despite a real teacher account existing. Root cause: `list_school_users` picks a multi-role account's single `active_role` as whichever role was granted most recently (`order by granted_at desc`). The seeded `teacher@aiot-school-lab.local` test fixture also has `school_admin` granted later (multi-role login test data), so the RPC reported them as `school_admin` only, and the page's `role == UserRole.teacher` filter excluded them. Fixed by adding an `all_roles text[]` column to `list_school_users` (migration `20260826130000_list_school_users_all_roles.sql`, additive — existing `active_role` unchanged) and a `UserModel.hasRole(role)` helper that checks membership in `allRoles`, not just the single collapsed `role`. Updated `school_teachers_page.dart` and `school_students_page.dart` to use `hasRole` instead of `role ==` so a multi-role account still shows up in every role-filtered list it belongs to.
- Verified live: rebuilt, logged in as `schooladmin@aiot-school-lab.local`, confirmed the assignment card shows honest `0%`/`ยังไม่มี...` (real building/room count is 0), and the teachers page now shows the real teacher (1 คน, correctly bucketed under ฝ่ายวิชาการ). Full `school_admin` test suite (21 tests) + `shared_core` suite (47 tests) passing, `flutter analyze` clean.

### 12. Super Admin Phase 3 + Root Shell Swap (2026-08-25/26)

Ported the remaining 6 super_admin pages (`super_admin_hub_page.dart`,
`super_admin_devices_page.dart`, `super_admin_device_test_page.dart`,
`super_admin_permissions_page.dart`, `super_admin_alerts_logs_page.dart`,
`super_admin_settings_page.dart`) from `~/aiot_dev_dashboard`'s source
— all 8 super_admin pages (including Phase 1's 2) are now real. No new
migrations were needed for most of it; `list_school_alerts` already had
a super_admin cross-school bypass from earlier work.

**Independently re-verified, 3 issues found and fixed** (same day):
diagnostic latency numbers in the device test page were hardcoded, not
measured (fixed with real `Stopwatch()` timing around real RPC calls);
`super_admin_devices_page.dart` had the exact fake-building-name
fallback bug already fixed once that day in `school_devices_page.dart`
(fixed to `'ไม่ระบุ'`); and `list_school_admin_audit_logs` silently
showed a super_admin only 24 of 141 real audit log rows (17%) because
its `WHERE` clause relied on `al.school_id = v_actor.school_id`, which
is never `TRUE` when a super_admin's own `school_id` is `NULL` — fixed
via `20260826140000_super_admin_audit_logs_scope.sql` adding an
explicit `v_actor.role = 'super_admin'` bypass, verified live that
school_admin's own scope is unchanged.

**Root shell swap**: `super_admin_hub_page.dart` initially only linked
to 5 of the 8 pages (Devices/QR, Device Test, and Settings were
unreachable from it, only from the old shell) — added those 3 links to
both the quick-action cards and the drawer, verified live, then swapped
`role_router.dart`'s `super_admin` case from `SuperAdminDashboard` to
`SuperAdminHubPage`. Live-verified 2026-08-26: real login lands
directly on the new hub with real summary metrics, all 8 cards present
and spot-checked. Old shell `dashboard/super_admin_dashboard.dart`
retained, unreferenced, per the old-UI-file policy above.

## Where to look next

- `.scratch/design-system-unification/issues/` — 7 tickets (2026-08-26)
  to unify button/text-field/search-field *structure* across
  school_admin, super_admin, executive, and parent, using teacher/
  student's UI as the structural reference. Each role **keeps its own
  existing colors** — structure-only, not a color rewrite; teacher/
  student are never modified. **Ticket 01 (foundation) is done and
  verified** as of 2026-08-26: `buildRoleTheme()`/`RoleColors`/
  `AppButton`/`AppTextField`/`AppSearchField` live in
  `packages/shared_ui/lib/theme/`, and every migrating role now has a
  `roleColors`/`theme`/`roleTheme` getter built from its own existing
  colors (`SchoolAdminPalette`, `AppPalette` ×2, new `ParentPalette`).
  **Ticket 02 (School Admin home page, the pilot) is also done and
  verified** as of 2026-08-26: the home page's only widget
  (`_HomeDashboard`) is wrapped in `Theme(data: SchoolAdminPalette.theme,
  child: ...)`, live-verified real data + real navigation still work,
  and — critically — confirmed via screenshot that every *other*
  School Admin page (e.g. the students page) is untouched, still
  rendering with the old button/field structure. **Ticket 03 (School
  Admin's other 18 pages) is done and verified** as of 2026-08-26: every
  page's return in `school_admin_dashboard_page.dart`'s
  `_buildCurrentPage()` switch is wrapped in a `_themed()` helper (except
  the two shared_ui-owned pages, `UserListPage`/`ConsentPolicyAdminPage`,
  correctly left out since they're reused by other roles); 5 redundant
  bare `OutlineInputBorder()` overrides removed; 45 generic large
  content-wrapper containers converted to `Card` across 13 files — small
  chips/badges/stat tiles deliberately left at their original
  size-appropriate radius (user's explicit call, see ticket 03 file) and
  the 16 semantic button color overrides (red=delete, green=confirm,
  etc.) deliberately left untouched since they're content, not
  duplicated structure. Live-verified: logged in as school_admin,
  clicked through home/buildings/teachers/students/alerts, confirmed
  real seeded data + honest zero-states + working search-field filtering
  (typed a query, list live-filtered, clear button worked) survived the
  migration intact. Full school_admin test suite (22 tests) passes,
  `flutter analyze` clean. → 04/05/06 (Super Admin/Executive/Parent,
  each blocked by 02 only, not started) → 07 cleanup (blocked by
  03-06).
- `docs/handoff/DATABASE_SCHEMA.md` — every table + every RPC, generated live.
- `supabase/seed.sql` — test data and accounts; also documents itself inline.
- `supabase/migrations/` — read in filename (timestamp) order for schema history.
- `packages/shared_core/lib/services/` — one file per feature; start here to
  find "what RPC backs this UI."
- `git log --oneline` — very actively committed, descriptive messages; the
  best source of "what's done" (more reliable than any stale NOTES.md).
