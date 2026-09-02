# Brief for agy: `sensor_latest` — cross-school data leak + super_admin regression (live in production)

Found 2026-09-01/02 while auditing the sensor data pipeline end-to-end
(ingest → storage → read). The ingest side (`sensor_ingest`,
`sensor_readings`, `device_heartbeats`) is fine, unaffected, not part of
this brief. The **read** side, `sensor_latest`, has a live security bug.

## What happened

`supabase/migrations/20260901000003_parent_sensor_latest.sql` replaced
`sensor_latest(p_token, p_device_id)` to add `parent` role access. It's
**deployed to production right now** (confirmed via
`pg_get_functiondef` against the live DB) but was **never recorded in
`supabase_migrations.schema_migrations`** — a fresh `db reset` from the
migrations directory will silently produce a *different, older* function
than what's actually running today. Fix that too (see "What to do"
below): whatever the final correct version ends up being, it needs a
migration file that gets applied *and* recorded, the normal way.

## The bug — self-referential `coalesce` disables school scoping

Old (correct), from `20260720010000_sensor_ingest_rpc.sql`:
```sql
where (v_actor.role = 'super_admin' or d.school_id is not distinct from v_actor.school_id)
```

New (live now), from `20260901000003_parent_sensor_latest.sql`:
```sql
where d.school_id = coalesce(v_actor.school_id, d.school_id)
```

When `v_actor.school_id` is `null`, this reduces to `d.school_id =
d.school_id` — always true. Any caller whose session has no active
school context sees sensor readings from **every school in the
database** (26 schools currently) instead of being scoped or denied.
This is a real cross-tenant leak, not theoretical: confirmed 2 currently
active (unexpired, non-revoked) sessions right now with
`active_school_id is null` (both `super_admin`, via
`select ... from sessions where active_school_id is null and revoked_at
is null and expires_at > now()`).

## Compounding regression — `super_admin` silently dropped

The same new version's role gate:
```sql
if v_actor.role not in (
  'school_admin', 'teacher', 'executive', 'student', 'technician', 'parent'
) then
  raise exception 'forbidden';
end if;
```
no longer includes `super_admin` at all. So today, the 2 live
null-school super_admin sessions actually hit `forbidden` before ever
reaching the coalesce line — meaning **super_admin currently cannot call
`sensor_latest` at all**, a straight regression (the old code explicitly
let super_admin see every school by design, via the `role =
'super_admin' or ...` clause).

## Secondary: dead references to decommissioned roles

The new version also has a `facility_manager`-specific branch and keeps
`technician` in the allowed-role list. Per `CLAUDE.md`, both roles were
merged away on 2026-08-25 (`facility_manager` → `school_admin`,
`technician` → `super_admin`). Confirmed via `select role, count(*) from
user_roles group by role` — **zero users currently hold either role.**
Harmless today (dead code, unreachable), but whoever wrote this migration
(dated 2026-09-01, a week after the merge) didn't check `CLAUDE.md` first
— worth cleaning up while you're in this function so it doesn't confuse
the next person reading it.

## Note: the feature this migration was for isn't even wired to the UI yet

Grepped every parent-facing page —
`apps/user_app/lib/pages/parent_redesign_prototype/` — for
`sensor_latest`/`RealtimeService`: **zero matches.** The parent
dashboard's environment/sensor card is still 100% hardcoded fake data
(see [[aiot-school-lab-app]] memory / earlier audit). So this migration
shipped a live cross-tenant security regression for a feature that
nothing in the app actually calls yet — low urgency from a "did anyone
see leaked data" standpoint (nothing's driving traffic through the
vulnerable path from the parent side yet), but still a live hole and
still broke `super_admin` for real, so treat as a real fix, not a
someday-cleanup.

## What to do

Write a new migration that:
1. Restores real school scoping: `where (v_actor.role = 'super_admin' or
   d.school_id is not distinct from v_actor.school_id)` — keep
   `super_admin` seeing everything (that's intentional, not a bug).
2. Keeps `parent` in the allowed-role list (that part of the original
   intent was fine) — just don't let a null-school session for *any*
   role bypass scoping.
3. Decide with a real answer, not a punt, what a parent's `school_id`
   should resolve to when they have 0 or 2+ linked students (the
   original migration's own comment flagged this and then left it as
   the tautology bug instead of solving it) — likely: derive it from
   `parent_links`/the student's `school_id` rather than trusting
   `sessions.active_school_id` blindly, or require an explicit active
   student selection before allowing a sensor read. Whatever you land
   on, it must still deny (not leak) when ambiguous/absent, never `d
   .school_id = d.school_id`.
4. Either drop the dead `facility_manager` branch and `technician` role
   reference, or leave a one-line comment explaining why they're kept
   despite the 2026-08-25 merge — don't leave it unexplained.
5. Record the migration in `supabase_migrations.schema_migrations` after
   applying (`npx supabase db query --linked --project-ref
   smqoknnftgjyhrnzugar --file <path>`, then the usual insert — see any
   other migration this session for the exact pattern).

## Verification bar

- Re-run: `select role, count(*) from user_roles group by role;` and
  confirm `super_admin` count > 0 (2 currently) still works end-to-end —
  actually call `sensor_latest` as a super_admin session and confirm no
  `forbidden` exception.
- Re-run the null-school-session query and confirm a null-school caller
  (of any still-allowed role) gets either an empty result or a clean
  deny — never rows from a school that isn't theirs. If you can't force
  a non-super_admin null-school session to test live, at minimum prove
  it via `explain` / manual substitution that the WHERE clause can't
  degrade to a tautology for any input.
- Confirm the migration is both applied AND present in
  `schema_migrations` (`select * from supabase_migrations
  .schema_migrations where version = '<your timestamp>';` should return
  a row).

## Update on completion

Move this brief from "In progress" to "Done" in `WORK_LOG.md` with the
closing commit hash, per `CLAUDE.md`'s "Keeping this current" rule.
