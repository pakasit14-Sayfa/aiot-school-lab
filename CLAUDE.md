# AIoT School Lab — Project Instructions

School management app (Thai-language UI): classes, assignments, grading,
quizzes, lesson content, incident/emergency reporting, parent-student
binding, and IoT sensor data from physical classroom devices.

**Roles (6, as of 2026-08-25): `super_admin`, `school_admin`, `teacher`,
`executive`, `student`, `parent`.** There is no `facility_manager` or
`technician` role anymore — both were merged (`facility_manager` →
`school_admin`, `technician` → `super_admin`) on 2026-08-25; see
`docs/handoff/HANDOFF.md` for the migration details. **All 6 roles route
through their redesigned UI and are fully wired to real backend data** —
`role_router.dart` sends `student`/`teacher`/`executive`/`parent` to their
`*_redesign_prototype/` shell, `school_admin` to `school_admin/school_admin_dashboard_page.dart`
(new-design hub, 20 real menu items — swapped from the old `dashboard/school_admin_dashboard.dart`
shell on 2026-08-25, live-verified), `super_admin` to `super_admin/super_admin_hub_page.dart`
(new-design hub, 8 real menu items — swapped from the old `dashboard/super_admin_dashboard.dart`
shell on 2026-08-26, live-verified).
**A single account can hold more than one role** — see "Multi-role login"
in HANDOFF.md.

Full architecture writeup, "how to run," current status, and known issues:
**[docs/handoff/HANDOFF.md](docs/handoff/HANDOFF.md)**. Full live database
schema (every table, every RPC function signature): **[docs/handoff/DATABASE_SCHEMA.md](docs/handoff/DATABASE_SCHEMA.md)**
— regenerate this from the running local DB rather than hand-editing it (see
"Keeping this current" below). **Index of every `agy-brief-*.md` task and
its actual status: [docs/handoff/WORK_LOG.md](docs/handoff/WORK_LOG.md)**
— `docs/handoff/` has ~30 individual brief files with no other way to see
at a glance which are done vs still open; check this before re-reading
briefs one by one or re-doing work that's already finished.

There is also a separate Obsidian vault at `~/Documents/AIoT-School-Lab-Vault/`
covering product design, decisions, and the 173 use-case specs — that's
design/product knowledge, not code. This file and `docs/handoff/` cover the
codebase itself.

## Hard rules — read before touching the backend

1. **Not Supabase Auth.** No `auth.users`, no `auth.uid()`. Custom
   `sessions` table + opaque `session_token` string, validated via
   `get_session_actor(p_token)` inside every RPC. Client passes `p_token`
   as the first arg to nearly every `supabase.rpc(...)` call.
2. **RLS is deny-all on every table, zero policies.** Never write client
   code that calls `.from('table').select()` — it will silently return
   nothing. All reads/writes go through `SECURITY DEFINER` RPC functions.
   Adding a feature means adding an RPC, not exposing a table.
3. **File uploads go through signed URLs minted by Edge Functions**, never
   direct client Storage calls. Pattern: client → Edge Function (checks an
   `assert_*_access` RPC) → signed upload/download URL → client uses it
   directly. Copy the `lesson-material-upload`/`-download` or
   `course-file-upload`/`-download` functions as the template for any new
   upload feature. **Gotcha (bit both existing pairs, fixed in `26d0343`/
   `908707e`): any RPC called from the service-role client needs
   `grant execute ... to service_role` explicitly — it is not a member of
   `anon`/`authenticated` and gets no execute privilege from a grant to
   those roles alone.**
4. **One service class per domain** in `packages/shared_core/lib/services/`.
   Pages call the service; the service calls the RPC. Don't call
   `supabase.rpc(...)` directly from a page widget.
5. **No global `supabase` CLI** — always `npx supabase ...`.
6. **`NOTES.md` files inside `teacher_redesign_prototype/` and
   `student_redesign_prototype/` are stale** (describe an early UI-only
   mock phase). Trust `git log` and the actual code over those files for
   current status. **This applies doubly to this CLAUDE.md and to
   HANDOFF.md themselves** — both drifted badly behind real progress
   earlier in the project (see the 2026-08-25 note in HANDOFF.md's
   "Current status"). If a claim here contradicts what `role_router.dart`
   or a live login actually shows, trust the live system.

## Running locally

```bash
open -a Docker              # Docker Desktop must be running first
npx supabase start          # local Postgres/Storage/Edge Functions/Studio
cd apps/user_app
flutter run -d chrome --dart-define-from-file=../../env.json
```

Test accounts (seeded, password `Test1234!` for all): `teacher@aiot-school-lab.local`,
`student@aiot-school-lab.local`, `parent@aiot-school-lab.local`,
`schooladmin@aiot-school-lab.local`, `admin@aiot-school-lab.local`, `executive@aiot-school-lab.local`.

These same 8 accounts also exist in real `auth.users` (seeded by
`20260823070000_seed_auth_users_for_local_dev.sql`) with the same
`Test1234!` password, for `aiot_dev_dashboard` — the separate admin app in
this repo that uses actual Supabase Auth instead of `my_first_app`'s custom
session system (see hard rule 1). **Gotcha, found via real login testing:**
this password only lives in the migration file — if anyone changes it
directly in the DB (`docker exec`/Studio) while testing, it silently drifts
from what a fresh `db reset` reproduces. Verify with:
`select encrypted_password = crypt('Test1234!', encrypted_password) from auth.users;`
— should be all `t`.

## If you received this codebase as a zip file

This repo is normally shared as a full folder copy (zip), not a GitLab
invite. If that's how you got this:

1. **Check `.git/` is present**: run `git status` in the project root. If it
   shows a branch and commit history, git tracking survived the transfer —
   keep using it normally.
2. **Work on your own branch**, don't commit straight to whatever branch you
   received: `git checkout -b <your-name>-work`.
3. **Commit as you go**, even though there's nowhere to push:
   `git add -A && git commit -m "..."`. This is what makes it possible for
   the original owner to merge your changes back cleanly later, instead of
   diffing two folder snapshots by hand.
4. **When sending work back**, zip the whole project folder again — make
   sure `.git/` is included (don't use a "skip hidden files" zip option, and
   don't add `.git` to an exclude list). Losing `.git/` loses all commit
   history you made in step 3, and the owner is back to a blind file diff.
5. The owner will merge your branch back with
   `git remote add <you> <path-to-your-copy> && git fetch <you> && git merge <you>/<your-branch>`
   — so a clean, real commit history from you is what makes that painless.

## Keeping this current — mandatory, not optional, part of finishing any task

**This is not a "nice to have" — it caused a real problem 2026-08-25**: a
Claude session read this file and `HANDOFF.md` mid-project and got the
project's status completely wrong (thought `facility_manager` still
existed, thought the redesigned UI pages were still unwired mockups)
because whoever did that work never updated these docs. The project
owner had to notice and point it out. Don't repeat this — if you (agy,
or any Claude session) finish a task that changes what's true about this
project, updating the docs below is part of *finishing the task*, not a
separate follow-up someone else does later.

- `docs/handoff/HANDOFF.md` — update the "Current status" / "Known issues"
  sections when they materially change; don't let it rot into another stale
  NOTES.md.
- `docs/handoff/WORK_LOG.md` — the index of every `agy-brief-*.md` file
  and its status. When you finish a brief, move it from "In progress" to
  "Done" here **with the commit hash**, in the same commit/session as the
  work itself. When you start a new one, add it to "In progress" first.
  This file is the only reason someone doesn't have to open all ~30
  brief files one by one to know what's already done — keep it honest.
- `docs/handoff/DATABASE_SCHEMA.md` — regenerate, don't hand-edit, after any
  migration. It was generated with:
  ```bash
  docker exec -i supabase_db_aiot-school-lab psql -U postgres -d postgres -A -F"|" -c "..."
  ```
  (queries against `information_schema.columns`, `information_schema
  .table_constraints`/`key_column_usage`/`constraint_column_usage` for FKs,
  and `pg_proc`/`pg_namespace` for RPC signatures — see git history of that
  file for the exact SQL.)
