# AIoT School Lab — Handoff Notes (2026-08-20)

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
- `apps/admin_app` — separate admin app.
- `packages/shared_core` — all business logic: Supabase client setup, auth,
  and one service class per domain (see below). Both apps depend on this.
- `packages/shared_ui` — shared widgets/design tokens.
- `supabase/` — migrations (45 files, `supabase/migrations/`), Edge Functions
  (`supabase/functions/`), config, and `seed.sql` (test data + test accounts).

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

**2. RLS is deny-all everywhere; RPC is the only door.** All 65 tables have
Row-Level Security **enabled** with **zero policies** defined. That's
deliberate — it means PostgREST's auto-generated `/rest/v1/<table>` endpoints
are unusable from the client no matter what key you hold. All reads and
writes happen through `SECURITY DEFINER` functions in the `public` schema,
called via `supabase.rpc('function_name', {...})`. **Never** add a table that
clients touch with `.from('table').select()` — that's not how this codebase
works, and it would silently return nothing because of RLS.

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
- Full list: `select email, role from ...` query at the bottom of `seed.sql`.

`isPrototypeRoute` in `apps/user_app/lib/main.dart` is `false` — the app goes
through real login (`RoleRouter` picks the home page from the real role in
the DB). Only flip it to `true` temporarily to browse a role's UI without
logging in (see `NOTES.md` in `teacher_redesign_prototype/` /
`student_redesign_prototype/` — **those NOTES.md files describe an early
"UI-only, not wired to backend" phase of the project and are now stale; most
of what they call "not connected" has since been wired to real RPCs. Trust
the code and `git log`, not those NOTES files, for current status.**

## Current status (as of commit `b7628f6`)

Both teacher-side and student-side UIs have been progressively wired from
mock data to real Supabase RPCs over many commits (see `git log --oneline`).
Rough state by role, based on which page files still import `shared_core`
services vs. still carry mock/TODO markers:

- **Teacher pages**: ~18 of 25 page files call real backend services.
  Remaining gaps / things to check before trusting a teacher page:
  `teacher_courses_page.dart`, `teacher_lesson_editor_page.dart`, and
  `teacher_redesign_prototype_page.dart` still had mock/TODO markers as of
  this writing.
- **Student pages**: ~13 of 24 page files call real backend services; no
  mock/TODO markers found in the rest, but that hasn't been runtime-verified
  for every page.

### Known issues not yet fixed

- `teacher_profile_page.dart` — some of the displayed stats appeared to be
  hardcoded rather than pulled from real data. Not yet root-caused to a
  specific line; needs a fresh look (grep for hardcoded numbers didn't
  immediately surface it in a 991-line file — may be computed client-side
  from a partial dataset rather than a literal constant).
- `teacher_exam_builder_page.dart` — image/video attachments on exam
  questions did not appear to persist / round-trip correctly. Needs
  reproduction with the local stack running to confirm current behavior.

### In progress at time of writing

Commit `b7628f6` ("wire lesson content, incident severity, and student
groups to real backend") added the lesson-materials upload/download Edge
Functions and migration described above (`20260823010000_lesson_material_upload.sql`,
`supabase/functions/lesson-material-upload/`,
`supabase/functions/lesson-material-download/`). This was being verified
end-to-end (teacher uploads a lesson attachment → student can view/download
it) when handed off — local Supabase is confirmed running and the app boots
and connects to it (`Supabase init completed` in console), but the actual
click-through UI verification via browser automation was not completed
before handoff. **Next step for whoever picks this up: drive that flow
manually or via browser automation and confirm the signed-URL upload/download
round-trip actually works, not just that the Edge Functions deploy.**

## Where to look next

- `docs/handoff/DATABASE_SCHEMA.md` — every table + every RPC, generated live.
- `supabase/seed.sql` — test data and accounts; also documents itself inline.
- `supabase/migrations/` — read in filename (timestamp) order for schema history.
- `packages/shared_core/lib/services/` — one file per feature; start here to
  find "what RPC backs this UI."
- `git log --oneline` — very actively committed, descriptive messages; the
  best source of "what's done" (more reliable than any stale NOTES.md).
