# AIoT School Lab — Project Instructions

School management app (Thai-language UI): classes, assignments, grading,
quizzes, lesson content, incident/emergency reporting, parent-student
binding, and IoT sensor data from physical classroom devices. Roles:
teacher, student, parent, facility manager, executive/admin.

Full architecture writeup, "how to run," current status, and known issues:
**[docs/handoff/HANDOFF.md](docs/handoff/HANDOFF.md)**. Full live database
schema (every table, every RPC function signature): **[docs/handoff/DATABASE_SCHEMA.md](docs/handoff/DATABASE_SCHEMA.md)**
— regenerate this from the running local DB rather than hand-editing it (see
"Keeping this current" below).

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
   upload feature.
4. **One service class per domain** in `packages/shared_core/lib/services/`.
   Pages call the service; the service calls the RPC. Don't call
   `supabase.rpc(...)` directly from a page widget.
5. **No global `supabase` CLI** — always `npx supabase ...`.
6. **`NOTES.md` files inside `teacher_redesign_prototype/` and
   `student_redesign_prototype/` are stale** (describe an early UI-only
   mock phase). Trust `git log` and the actual code over those files for
   current status.

## Running locally

```bash
open -a Docker              # Docker Desktop must be running first
npx supabase start          # local Postgres/Storage/Edge Functions/Studio
cd apps/user_app
flutter run -d chrome --dart-define-from-file=../../env.json
```

Test accounts (seeded, password `Test1234!` for all): `teacher@aiot-school-lab.local`,
`student@aiot-school-lab.local`, `parent@aiot-school-lab.local`,
`admin@aiot-school-lab.local`, `facility@aiot-school-lab.local`.

## Keeping this current

- `docs/handoff/HANDOFF.md` — update the "Current status" / "Known issues"
  sections when they materially change; don't let it rot into another stale
  NOTES.md.
- `docs/handoff/DATABASE_SCHEMA.md` — regenerate, don't hand-edit, after any
  migration. It was generated with:
  ```bash
  docker exec -i supabase_db_aiot-school-lab psql -U postgres -d postgres -A -F"|" -c "..."
  ```
  (queries against `information_schema.columns`, `information_schema
  .table_constraints`/`key_column_usage`/`constraint_column_usage` for FKs,
  and `pg_proc`/`pg_namespace` for RPC signatures — see git history of that
  file for the exact SQL.)
