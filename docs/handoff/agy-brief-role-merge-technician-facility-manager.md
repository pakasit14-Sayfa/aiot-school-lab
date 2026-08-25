# Brief for agy: remove `technician` and `facility_manager` as roles

## 🔴 URGENT — Checkpoint 1 is live and broke the app for everyone, do Checkpoint 2 now

Verified live after your Checkpoint 1 report: the enum rebuild itself is
correct (checked all 9 functions, seed, `profiles` view — all fine), but
every RPC in the 16-file list below that still contains a literal
`'technician'`/`'facility_manager'` string now **hard-errors for every
role**, not just those two. Postgres tries to cast the string literal to
`role_type` to do the `IN (...)` comparison, and since those labels no
longer exist in the enum, the cast itself throws before the role check
even runs. This is not "technician/facility_manager get denied" — it's
"school_admin, teacher, everyone gets HTTP 500."

Confirmed live with a real school_admin session token, post-Checkpoint-1:
```
create_device_schedule → ERROR: invalid input value for enum role_type: "technician"
list_device_schedules  → ERROR: invalid input value for enum role_type: "technician"
get_energy_efficiency_score → ERROR: invalid input value for enum role_type: "facility_manager"
```
Device Schedule, CCTV/Attendance, and Energy/ESG — 3 of the 4 features
built this session — are dead in the running app right now. Treat
Checkpoint 2 (below) as an active incident fix, not the next scheduled
step. Nothing else in this brief changes — the work was already fully
scoped, it just needs to happen immediately instead of after a pause.

Product decision (confirmed with user, not my call to second-guess): reduce
the 8-role system to 6. `technician`'s permissions become `super_admin`'s.
`facility_manager`'s permissions become `school_admin`'s. Reason given:
avoid adding operational workload onto teachers — this is a role
*consolidation*, not a permissions expansion for teacher.

This brief went through a "grilling" pass with the user resolving every
open decision explicitly — nothing below is a judgment call left to you.
If you hit something not covered here, flag it back rather than guessing.

## Work order — 3 checkpoints, report back after each one

Do not chain all three into one pass. Report back after each checkpoint
and wait before starting the next — if the enum rebuild has a problem,
we want to know before any RPC or UI work builds on top of it.

1. **Checkpoint 1: Part A, enum rebuild only.** Report back. I'll re-run
   the same RedTeam-style live-RPC verification I did for the earlier
   device-schedule/CCTV fixes before you move on.
2. **Checkpoint 2: Part A, the 16-file role-gate cleanup.** Report back.
3. **Checkpoint 3: Part B, Dart/UI.** Report back.

## Current state (verified live against local DB)

- `role_type` enum: `super_admin, school_admin, teacher, executive, student, parent, facility_manager, technician`
- 5 tables have a column typed `role_type`: `user_roles.role`, `sessions.active_role`, `audit_logs.acted_role`, `otp_codes.login_role`, `user_invitations.initial_role`
- Exactly **9 functions** have `role_type` directly in their signature (parameter or return column) — confirmed via `pg_depend` against `pg_type role_type`, not a grep guess:
  `accept_staff_invitation`, `auth_sign_in`, `auth_validate_session`, `auth_verify_login_otp`, `create_staff_invitation`, `get_session_actor`, `list_school_invitations`, `redeem_parent_binding_code`, `update_user_role`.
  Every other function that checks `v_actor.role = 'facility_manager'` etc. does so against a `record` variable inside the function *body* — Postgres doesn't track that as a type dependency, so those functions won't break from the type swap and don't need to be touched for the enum part (they still need their role-gate literals removed in Checkpoint 2, just not because of the enum).
- Live rows currently holding these two values: `user_roles` = 2 (the `facility@`/`technician@` seed accounts), `sessions.active_role` = 8, `audit_logs.acted_role` = 8. `otp_codes.login_role`/`user_invitations.initial_role` = 0 right now but guard them anyway.
- `technician_dashboard.dart` (75 lines) — checked the actual content: **100% stub**, every drawer item is `onTap: (_) {}`, both feature cards are `ComingSoonCard`. Nothing functional to preserve — just delete it.
- `facility_redesign_prototype/` (12 files) — real, built and wired this session. **Cherry-pick 2 pages into school_admin, drop the rest** (details in Part B).

## Part A — SQL: full enum rebuild (user chose this over deprecate-in-place)

Postgres has no `ALTER TYPE ... DROP VALUE`. To *actually* remove the two
labels (not just stop using them), the only path is: create a new type
with the 6 remaining values, migrate every column + function signature
over to it, drop the old type. Given it's only 9 functions (see above),
this is very doable in one migration if you do it mechanically rather
than retyping function bodies by hand.

New migration `supabase/migrations/20260826000000_merge_technician_facility_manager.sql`:

1. **Reassign data first**, before touching the type — same UPDATE set
   for all 5 columns (this is required now, not optional, since the
   rebuild removes the old labels entirely and every row must land on a
   value that still exists):
   ```sql
   update user_roles set role = 'super_admin' where role = 'technician';
   update user_roles set role = 'school_admin' where role = 'facility_manager';
   update sessions set active_role = 'super_admin' where active_role = 'technician';
   update sessions set active_role = 'school_admin' where active_role = 'facility_manager';
   update audit_logs set acted_role = 'super_admin' where acted_role = 'technician';
   update audit_logs set acted_role = 'school_admin' where acted_role = 'facility_manager';
   update otp_codes set login_role = 'super_admin' where login_role = 'technician';
   update otp_codes set login_role = 'school_admin' where login_role = 'facility_manager';
   update user_invitations set initial_role = 'super_admin' where initial_role = 'technician';
   update user_invitations set initial_role = 'school_admin' where initial_role = 'facility_manager';
   ```
   User confirmed: it's fine that this overwrites historical audit_logs/
   sessions rows directly (no snapshot/backup column needed) — the 8
   existing rows are local dev/seed data, not real school history, so
   there's no compliance concern yet.

2. **Capture the 9 functions' current definitions before dropping
   anything** — don't hand-retype them, pull the live source so nothing
   drifts from what's actually deployed:
   ```sql
   select proname, pg_get_functiondef(oid) from pg_proc
   where proname in (
     'accept_staff_invitation','auth_sign_in','auth_validate_session',
     'auth_verify_login_otp','create_staff_invitation','get_session_actor',
     'list_school_invitations','redeem_parent_binding_code','update_user_role'
   );
   ```
   Save that output — you'll replay these 9 `CREATE OR REPLACE FUNCTION`
   statements after the type swap, with `role_type` in each signature now
   resolving to the rebuilt 6-value type (same type *name*, new
   underlying type, so the text of these definitions doesn't need to
   change at all — just re-run them verbatim after step 3).

3. **Swap the type**:
   ```sql
   create type role_type_new as enum (
     'super_admin','school_admin','teacher','executive','student','parent'
   );

   alter table user_roles alter column role type role_type_new using role::text::role_type_new;
   alter table sessions alter column active_role type role_type_new using active_role::text::role_type_new;
   alter table audit_logs alter column acted_role type role_type_new using acted_role::text::role_type_new;
   alter table otp_codes alter column login_role type role_type_new using login_role::text::role_type_new;
   alter table user_invitations alter column initial_role type role_type_new using initial_role::text::role_type_new;

   drop type role_type cascade; -- cascades into the 9 functions captured in step 2, that's expected
   alter type role_type_new rename to role_type;
   ```

4. **Replay the 9 captured `CREATE OR REPLACE FUNCTION` statements** from
   step 2, unmodified, now against the rebuilt type.

5. **Revoke active sessions** for the `facility@`/`technician@` users so
   their next request forces a fresh login under the new role:
   `update sessions set revoked_at = now() where user_id = ... and revoked_at is null`.

6. Confirm after running:
   `select * from user_roles where user_id in (select id from users where email in ('facility@aiot-school-lab.local','technician@aiot-school-lab.local'))`
   shows `school_admin`/`super_admin` respectively — **but see Seed data
   below, these two accounts are getting deleted, not kept.** Confirming
   the reassignment worked is still useful as a sanity check before you
   delete them.

**Report back after this checkpoint** with: confirmation `drop type ...
cascade` only took down the 9 expected functions (not more — if
something else depended on `role_type` that wasn't in the pg_depend
query above, that's new information, flag it), and that all 9 replayed
cleanly.

## Part A continued — role-gate cleanup (Checkpoint 2)

`CREATE OR REPLACE FUNCTION` every RPC that has `'technician'` or
`'facility_manager'` in a role-gate. Don't edit the old migration files —
same rule as always. These 16 files contain the literals:

```
supabase/migrations/20260720010000_sensor_ingest_rpc.sql
supabase/migrations/20260721010000_relay_commands.sql
supabase/migrations/20260721020400_sensor_read_scope.sql
supabase/migrations/20260814000000_facility_manager_building_scope.sql
supabase/migrations/20260817000000_facility_manager_device_list.sql
supabase/migrations/20260818020000_incident_reports.sql
supabase/migrations/20260819010000_utility_costs.sql
supabase/migrations/20260823080100_utility_usage_trend.sql
supabase/migrations/20260823090000_utility_efficiency_score.sql
supabase/migrations/20260823140000_fix_facility_manager_device_command_scope.sql
supabase/migrations/20260824020000_fix_school_member_rls_missing_role_checks.sql
supabase/migrations/20260824030000_fix_set_facility_manager_building_anon_grant.sql
supabase/migrations/20260824070000_sensor_alert_actions.sql
supabase/migrations/20260824140000_fix_session_actor_attendance_cctv.sql
supabase/migrations/20260825090000_device_schedules_pg_cron.sql
```

For every `IF v_actor.role = 'facility_manager' THEN <building-scope
sub-check> END IF;` block (the pattern in
`create_device_schedule`/`list_device_schedules`/`toggle_device_schedule`/
`delete_device_schedule` in `20260825090000`, and the original in
`20260814000000`/`20260817000000`/`20260823140000`) — **delete the whole
sub-check, don't port it to school_admin.** User confirmed: school_admin
should see/control every building at once, no per-building filter, no new
picker UI. school_admin's existing tenant check (`school_id =
v_actor.school_id`) is already the right scope.

`users.building` column: leave it in place (still a harmless generic OUT
param in a couple of session RPCs), just stop reading it for any
access-control decision anywhere.

**Report back after this checkpoint** with a probe re-run (garbage token
→ clean `invalid_session`; student token on the affected RPCs →
`forbidden`) so nothing regressed to a raw 500, same as the earlier
device-schedule/CCTV verification round.

## Part B — Dart (Checkpoint 3)

- `packages/shared_core/lib/models/user_model.dart` — remove
  `UserRole.facilityManager`/`.technician` enum members, `.value`,
  `.label`, `fromString` cases. Run `flutter analyze` immediately after —
  Dart enum switch exhaustiveness will surface every other file that
  pattern-matches on `UserRole` and needs a case removed; that's the
  reliable way to find all call sites, don't grep them all manually
  first.
- `apps/user_app/lib/pages/role_router.dart` — remove the
  `facilityManager`/`technician` switch cases entirely.
- Delete `apps/user_app/lib/pages/dashboard/technician_dashboard.dart`.
- Port `facility_light_water_control_page.dart` →
  `apps/user_app/lib/pages/school_admin/school_admin_device_control_page.dart`
  and `facility_incident_inbox_page.dart` →
  `apps/user_app/lib/pages/school_admin/school_admin_incident_inbox_page.dart`.
  Both currently filter by the caller's `building` — **strip that filter
  entirely, no replacement UI** — school_admin sees/controls every device
  and every incident in their school in one list. Wire both into
  `school_admin_dashboard.dart`'s drawer + menu (goes from 6 to 8 items).
- Found while verifying Checkpoint 2: `list_devices_in_my_building` (the
  RPC that populates the device list on
  `facility_light_water_control_page.dart`, i.e. the page you're keeping)
  no longer filters by building — correct, matches the "no building
  filter" decision — but the name still says otherwise, on both the SQL
  function and its Dart wrapper. Since you're already touching this page,
  rename both while you're in there rather than leaving a name that lies
  about what the code does:
  - SQL: rename `list_devices_in_my_building` → `list_school_devices` (new
    `CREATE OR REPLACE FUNCTION` in this checkpoint's migration, then
    `DROP FUNCTION public.list_devices_in_my_building(text)` — same
    body, just the new name; drop the grants on the old name too).
  - Dart: `packages/shared_core/lib/services/realtime_service.dart` —
    rename `listMyBuildingDevices()` → `listSchoolDevices()`, update the
    RPC call inside it, and fix the doc comment above it (currently says
    "อาคารที่ผู้ดูแลอาคารรับผิดชอบ" — no longer true, no one's scoped to
    a building anymore).
  - Update the one real call site:
    `school_admin_device_control_page.dart` (post-port) —
    `RealtimeService.listMyBuildingDevices()` → `.listSchoolDevices()`.
- Delete the remaining 10 files + `NOTES.md` in `facility_redesign_prototype/`
  — check for lingering imports from the 2 kept pages into
  `facility_shared_widgets.dart` before deleting that one; port whatever
  it still needs into the new school_admin page files instead.
- `packages/shared_core/lib/services/realtime_service.dart` has a comment
  referencing the old facility_manager device-list migration — update the
  comment, the function itself is role-agnostic, no logic change needed.

**Report back after this checkpoint** with: real device on/off command
landing in `device_commands` from the new page, real incident inbox
showing real `incident_reports` rows school-wide (not building-filtered),
and a clean `flutter analyze`.

## Seed data

Delete both seed rows — `facility@aiot-school-lab.local` and
`technician@aiot-school-lab.local` — from `supabase/seed.sql` entirely.
User confirmed: don't keep them reassigned as extra logins,
`schooladmin@aiot-school-lab.local` and `admin@aiot-school-lab.local`
already cover those roles and keeping the old emails around with
different roles than their names suggest is just confusing. Update
`CLAUDE.md`'s "Test accounts" list (currently names `facility@...`
explicitly) to drop that mention.

## Final verify (after all 3 checkpoints)

1. `grep -rn "'technician'\|'facility_manager'" supabase/migrations/2026*`
   — should only match this new migration's own SQL literals (the
   reassignment UPDATEs), nothing else.
2. `grep -rn "facilityManager\|UserRole.technician" apps/ packages/` —
   empty.
3. `flutter analyze` — 0 new errors.
4. Fresh `npx supabase db reset` (picks up the deleted seed rows) — the
   8 seeded accounts become 6, all still log in correctly.

Flag back rather than guessing if you hit a role-gate whose intent isn't
obvious from the surrounding code — better to ask than to quietly widen
or narrow an access boundary on a guess.
