# AIoT School Lab — Handoff Notes (updated 2026-08-24)

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
Only **4 of its 27 pages are wired to a real backend repository**
(`dev_dashboard_page.dart`, `device_control_page.dart`,
`learning_platform_page.dart`, `schools_page.dart`) — the rest, including
every page under `lib/pages/school_admin/*`, are UI-only mockups with no
persistence (a "โหมดจำลอง UI (Mock Preview)" banner is shown on the ones
routed through `dev_navigation_shell.dart`/`school_admin_dashboard_page.dart`,
which covers all of them except `KioskPairingScannerPage`, which opens via a
separate fullscreen dialog outside both shells and has no banner yet).

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

## Current status (re-audited 2026-08-22, see methodology note below)

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

### Known issues not yet fixed

- `teacher_profile_page.dart` — some of the displayed stats appeared to be
  hardcoded rather than pulled from real data. Not yet root-caused to a
  specific line; needs a fresh look (grep for hardcoded numbers didn't
  immediately surface it in a 991-line file — may be computed client-side
  from a partial dataset rather than a literal constant).
- `teacher_exam_builder_page.dart` — image/video attachments on exam
  questions did not appear to persist / round-trip correctly. Needs
  reproduction with the local stack running to confirm current behavior.
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

## Where to look next

- `docs/handoff/DATABASE_SCHEMA.md` — every table + every RPC, generated live.
- `supabase/seed.sql` — test data and accounts; also documents itself inline.
- `supabase/migrations/` — read in filename (timestamp) order for schema history.
- `packages/shared_core/lib/services/` — one file per feature; start here to
  find "what RPC backs this UI."
- `git log --oneline` — very actively committed, descriptive messages; the
  best source of "what's done" (more reliable than any stale NOTES.md).
