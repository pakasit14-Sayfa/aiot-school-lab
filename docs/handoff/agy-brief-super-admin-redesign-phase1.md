# Brief for agy: super_admin redesign — Phase 1 (the 2 pages that already connect)

Source design: `/Users/sayfa/Downloads/aiot_dev_dashboard` (a friend's copy
of the separate admin-app project). User wants the whole 23-page design
eventually ported into `my_first_app`'s `super_admin` (and `school_admin`)
dashboards, replacing the current plain InfoCard-list style. **This is a
large, multi-phase job — this brief covers Phase 1 only: the 2 pages that
already talk to a real backend.** The other 21 pages are 100% hardcoded UI
mockups with zero Supabase calls (confirmed via a full audit of all 23
files) — each of those needs new tables + RPCs designed from scratch and
will come as separate, later briefs. Don't attempt them in this pass.

## Why start here

`schools_page.dart` and `device_control_page.dart` are the only 2 of the
23 files with real `supabase.rpc(`/`supabase.from(` calls. Porting them
first gives a working, verified pattern to copy for every later phase,
instead of guessing at conventions from scratch 21 times.

## 1. `schools_page.dart` — mostly a straight port

Reads/writes: `schools`, `profiles` (a view over `users`+`user_roles`,
added by the existing `20260823060000_admin_dev_dashboard_compatibility.sql`
compatibility migration), `devices`, `alerts` (a view over
`sensor_alerts`, same migration). **All 4 already match my_first_app's
real schema** — confirmed column-by-column. No new migration needed for
this page specifically.

**The catch**: this page calls `supabase.from(...)` directly (Supabase
Auth style, like the rest of `aiot_dev_dashboard`), which **only works
because of that one compatibility migration's direct-`authenticated`-role
RLS policies** — a second, parallel security model layered on top of
`my_first_app`'s normal deny-all-RLS/RPC-only convention (see
`CLAUDE.md` hard rule 2 and its "Exception, added 2026-08-22" note).
Porting this page as-is into `my_first_app`'s `super_admin` dashboard
means it would run under `my_first_app`'s custom session system, not
Supabase Auth — **the direct `.from()` calls won't carry the right
identity there**. Two options, pick based on what's less rewrite:
- (a) Wrap every `.from(...)` call this page makes into a proper
  `SECURITY DEFINER` RPC taking `p_token` (the normal `my_first_app`
  convention) — e.g. `list_schools_for_super_admin(p_token)`,
  `create_school(p_token, ...)`, `update_school(p_token, p_school_id, ...)`,
  `set_school_status(p_token, p_school_id, p_status)`. Role-gate
  `super_admin` only, same `get_session_actor` pattern as every other
  RPC in this codebase.
- (b) Keep the page's internal structure/UI as close to the original as
  possible, just swap its data layer (`SchoolRepository`) for calls into
  a new `packages/shared_core/lib/services/school_admin_platform_service.dart`
  that wraps the RPCs from (a).

Go with (a)+(b) together — new RPCs, new thin service wrapper, same UI.

## 2. `device_control_page.dart` — needs real schema fixes first

This one **looks** wired but isn't safely portable as-is — its
`DeviceControlRepository` expects columns/RPCs that don't exist in
`my_first_app`'s real database:

- `device_commands` — repository expects `status`, `payload`,
  `requested_at`, `completed_at`, `error_message`, `school_id`,
  `requested_by`. Real table is only `(id, device_id, command jsonb,
  created_by, created_at, delivered_at)`. **Don't alter the real table
  to match the mockup** — go the other way: adapt the new RPC layer to
  work with the real, already-in-use schema (device_schedules and every
  other feature already depend on `device_commands` staying as-is).
- `control_approval_requests` — repository expects `control_scope`,
  `requested_action`, `reason`, `target_device_ids` (array), `expires_at`,
  `decided_by`, `decided_at`, `decision_note`. Real table only has a
  single `device_id`, `command` (text), `reviewed_by`, `reviewed_at`,
  `notes`. Same rule — adapt the RPC to the real table, don't widen the
  table to match a mockup's assumptions until there's a confirmed real
  need for multi-device batch approval (which is a bigger feature
  decision, flag back rather than assuming).
- `create_control_approval_request` / `decide_control_approval_request`
  RPCs **do not exist at all** — need to be written from scratch against
  the real `control_approval_requests` shape.
- `grantOperatorRole()` does `.from('profiles').update(...)` — `profiles`
  is a multi-table join view, **not updatable directly in Postgres**.
  This call would fail today even in the original project. Replace with
  a proper RPC that updates the underlying `user_roles` table instead
  (reuse `add_secondary_role`/`update_user_role` patterns already in
  `my_first_app` rather than inventing a third role-grant mechanism).

**Recommended approach**: build `create_control_approval_request(p_token,
p_device_id, p_command, p_reason)` and
`decide_control_approval_request(p_token, p_request_id, p_decision,
p_note)` RPCs against the *real* `control_approval_requests` columns,
`super_admin`-gated. Emergency-stop / power / mode commands go through
the existing `queue_device_command` RPC (already rate-limited, already
correct) rather than a new bespoke insert path — don't duplicate that
logic.

## What NOT to do in this phase

- Don't touch any of the 21 mock-only pages yet.
- Don't widen `device_commands`/`control_approval_requests` to match the
  mockup's imagined columns — adapt the new code to the real schema.
- Don't build `kiosk_pairing_scanner_page.dart` — it's referenced in the
  page list the user was given but **does not exist** in the friend's
  project at all. Flag this back rather than guessing what it should do.

## Verify

Same standard as every feature this session:
1. Real RPC calls with a real `super_admin` session token — list/create/
   update a school, confirm a non-`super_admin` token gets `forbidden`.
2. Real device command through the ported page → confirm a row lands in
   `device_commands` with the real column shape, and that the existing
   20-per-minute rate limit (`device_command_rate_limits`) still applies
   to commands sent this new way.
3. `create_control_approval_request` → `decide_control_approval_request`
   round trip with real data, both approve and reject paths.
4. Real browser click-through of both ported pages inside
   `my_first_app`, logged in as `admin@aiot-school-lab.local`.

Report back when this phase is done — the next brief (school_admin's 14
mock pages, prioritized) depends on the RPC/service conventions this
phase establishes.
