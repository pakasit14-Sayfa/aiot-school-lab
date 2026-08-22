# 🚨 URGENT brief for agy: anon-open RLS policies leak the whole DB

Found while reviewing your "Daily Engineering & Audit Log" report (2026-08-22).
Confirmed exploitable **right now** against the shared local Supabase — not a
theoretical risk, tested with real unauthenticated `curl` requests using only
the public anon key:

```bash
ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"

curl "http://127.0.0.1:54321/rest/v1/devices?select=id,name,school_id&limit=3" \
  -H "apikey: $ANON_KEY" -H "Authorization: Bearer $ANON_KEY"
# → 200, real device names + school_id, no login at all

curl "http://127.0.0.1:54321/rest/v1/profiles?select=email,full_name,role,school_id&limit=5" \
  -H "apikey: $ANON_KEY" -H "Authorization: Bearer $ANON_KEY"
# → 200, email/name/role/school_id for every user in the DB — teacher,
#   student, executive, school_admin, super_admin — no login at all
```

## Root cause

Two migrations you added
(`20260823060000_admin_dev_dashboard_compatibility.sql`,
`20260823080000_super_admin_hardening_rls_and_health.sql`) grant `anon`
(unauthenticated) direct table access:

```sql
create policy anon_select_devices on public.devices for select to anon using (true);
create policy anon_select_schools on public.schools for select to anon using (true);
create policy anon_select_sensors on public.sensor_readings for select to anon using (true);
create policy anon_select_commands on public.device_commands for all to anon using (true);  -- read+write+delete, no auth
```

plus:

```sql
grant select, insert, update on public.users to anon, authenticated;
grant select, insert, update on public.user_roles to anon, authenticated;
```

`my_first_app` (the other app in this repo, `apps/user_app`) has exactly one
security model for its entire backend, documented in `CLAUDE.md`: **RLS
deny-all on every table, all access through RPC functions that check the
caller's identity themselves.** No table is ever meant to be readable via
`anon`/`authenticated` with a permissive policy — that's the whole reason
every RPC takes `p_token` and calls `get_session_actor(p_token)` internally
instead of relying on Supabase Auth + RLS. These 4 `using (true)` policies
punch a hole straight through that model for every table they touch, for
anyone holding the public anon key (which ships in the client, isn't secret).

The `profiles` view is a second, separate leak: Postgres views run with the
view owner's privileges by default (not the querying role's), so `grant
select on profiles to anon` exposes the full `users` table's email/name/
role/school_id through the view even though `users` itself still correctly
has zero RLS policies.

## What's actually needed vs. what's over-broad

Your `super_admin_all_*` / `school_user_isolated_*` policies (the ones using
`auth.uid()` and requiring `to authenticated`) are fine in principle — they
require a real Supabase Auth session, which is how `aiot_dev_dashboard` logs
in. **The problem is specifically the 4 `anon_select_*`/`anon_select_commands`
policies and the `users`/`user_roles` grants — nothing legitimately needs
those**, since `aiot_dev_dashboard` requires login anyway (its `AuthGate`
won't render the dashboard for a logged-out session), and its `profiles`
view access already covers what it needs from `users` without a direct grant.

## Fix (new migration, don't edit the two already-applied files)

```sql
-- Remove the anon-open (unauthenticated) policies entirely
drop policy if exists anon_select_devices on public.devices;
drop policy if exists anon_select_schools on public.schools;
drop policy if exists anon_select_sensors on public.sensor_readings;
drop policy if exists anon_select_commands on public.device_commands;

-- These grants were redundant even for aiot_dev_dashboard's own needs —
-- the `profiles` view already covers what it reads from `users`, and
-- nothing calls users/user_roles directly.
revoke select, insert, update on public.users from anon, authenticated;
revoke select, insert, update on public.user_roles from anon, authenticated;
```

Also worth checking: `device_categories`, `device_logs`,
`control_approval_requests` were created in `...060000...` without ever
running `alter table ... enable row level security` on them at all — RLS is
off by default in Postgres until explicitly enabled, so combined with
`grant ... to anon` on those three, they're currently **wide open with no
RLS at all**, not even a permissive policy — same practical effect as
`using (true)`. Enable RLS + add real `authenticated`-only policies there
too (or confirm intentionally public if `device_categories` really is just
a static lookup list — that one's low-risk, but `device_logs` and
`control_approval_requests` are not).

## How to verify the fix

Same method used to find the bug — real unauthenticated `curl`, not `docker
exec` as postgres (that bypasses RLS entirely and won't show you what's
actually exposed):

```bash
curl "http://127.0.0.1:54321/rest/v1/devices?limit=1" -H "apikey: $ANON_KEY" -H "Authorization: Bearer $ANON_KEY"
curl "http://127.0.0.1:54321/rest/v1/profiles?limit=1" -H "apikey: $ANON_KEY" -H "Authorization: Bearer $ANON_KEY"
```
Both should return `[]` (RLS blocking, no rows) after the fix, not real data.
Then confirm `aiot_dev_dashboard` still logs in and works normally with a
real (authenticated) session — the `authenticated`-role policies weren't
touched, so it should be unaffected.
