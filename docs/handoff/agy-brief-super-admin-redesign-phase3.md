# Brief for agy: super_admin redesign — Phase 3 (the remaining 6 pages)

## Where this fits

Phase 1 (done, verified) ported 2 pages: `schools_page.dart` →
`super_admin_schools_page.dart`, `device_control_page.dart` →
`super_admin_device_control_page.dart`, backed by 7 real RPCs
(`create_school_for_super_admin`, `update_school_for_super_admin`,
`set_school_status_for_super_admin`, `list_schools_for_super_admin`,
`list_device_control_data_for_super_admin`,
`create_control_approval_request`, `decide_control_approval_request`).
`dev_ui.dart` (shared widget helpers) was also ported to
`apps/user_app/lib/pages/super_admin/widgets/dev_ui.dart`.

**Not done yet, and not part of this brief**: swapping `role_router.dart`
so `super_admin` lands on a new hub shell instead of the old
`dashboard/super_admin_dashboard.dart` (3-item drawer: Schools, Device
Control, User Management). That's a separate, smaller brief once these
6 pages exist to fold in — same shape as
`agy-brief-school-admin-root-shell-swap.md`, don't attempt it here.

## Scope reality check — this is bigger than any prior batch

Source files, all in `/Users/sayfa/aiot_dev_dashboard/lib/pages/`
(same repo Phase 1's 2 pages came from):

| File | Lines | Target page name |
|---|---|---|
| `dev_dashboard_page.dart` | 1,203 | `super_admin_hub_page.dart` (or similar — this is the dashboard-hub equivalent of `school_admin_dashboard_page.dart`) |
| `devices_page.dart` | 3,031 | `super_admin_devices_page.dart` |
| `device_test_page.dart` | 2,441 | `super_admin_device_test_page.dart` |
| `permissions_page.dart` | 3,474 | `super_admin_permissions_page.dart` |
| `alerts_logs_page.dart` | 3,509 | `super_admin_alerts_logs_page.dart` |
| `settings_page.dart` | 1,677 | `super_admin_settings_page.dart` |

15,335 lines total — roughly 4x the size of school_admin's Phase 2
Batch 2 (6 pages). There's also `dev_navigation_shell.dart` (1,233
lines, the source app's own hub/sidebar shell — not ported yet) which
you'll want to reference for how the source design intended these
pages to be navigated between, but don't port it as-is; that's the
root-shell-swap brief's job later, not this one.

**Don't attempt all 6 in one pass.** Batch order, easiest/most-reused
first:

### Batch 1 — `permissions_page.dart` (highest reuse)
`list_school_users(p_token)` already returns **every user across every
school** when the caller is `super_admin` (see its `where v_actor.role =
'super_admin' or u.school_id is not distinct from v_actor.school_id`
clause) and, as of today, includes `all_roles text[]` per user (see
`20260826130000_list_school_users_all_roles.sql` and
`UserModel.hasRole()` in `shared_core`). `update_user_role` and
`add_secondary_role` already exist too. Check the source page's actual
UI against these before assuming anything new is needed — this is
likely the closest to zero-new-RPC of the 6.

### Batch 2 — `alerts_logs_page.dart`
`list_school_admin_audit_logs` and `list_school_alerts` exist but are
single-school-scoped (built for school_admin). Check whether a
super_admin variant needs a `p_school_id` filter param (null = all
schools) added to each, or whether new `_for_super_admin` wrappers make
more sense — **decide based on what's simpler, don't just copy the
`_for_super_admin` naming pattern reflexively if adding an optional
param to the existing function is cleaner and the school_admin caller
path is unaffected either way.**

### Batch 3 — `dev_dashboard_page.dart` (the hub)
Same pattern as `get_school_admin_dashboard_summary`: one aggregating
RPC (or several service calls combined client-side) pulling from
whatever Batches 1/2/4/5 end up building — don't design its numbers
before the pages under it exist, you'll just be guessing at a shape
that has to change later.

### Batch 4 — `devices_page.dart`
Cross-school device inventory. `list_device_control_data_for_super_admin`
(Phase 1) already returns device data for the control page — check
its actual return shape before assuming a new RPC; it may already
cover most of what an inventory list needs, same "check before
building" discipline as Phase 2's reuse table.

### Batch 5 — `device_test_page.dart`
Look hard at what this page actually claims to test before building
anything. If it implies live hardware diagnostics with no real device
firmware to talk to (check `queue_device_command`'s actual scope — it
dispatches real commands but there's no confirmed hardware ACK/heartbeat
path per HANDOFF.md section 3b's explicit "do not build this" note),
this is very likely Tier B (no real backend possible yet) — flag back
with what the page's fields actually claim before writing fake-looking
UI for something with no real backend to connect.

### Batch 6 — `settings_page.dart`
Checked `pg_proc` — no platform-wide settings RPC exists, same as
school_admin's settings page. This is Tier B from the start. Apply the
same honest-disclosure pattern from
`agy-brief-school-admin-fake-fallback-data.md` (see HANDOFF.md section
10) immediately — don't build a fake-looking settings form first and
fix it later, that's exactly the mistake that brief had to correct.

## Mandatory guardrails — every one of these was a real bug found this session, don't reintroduce any of them

1. **Every new RPC**: `SELECT * INTO v_actor FROM get_session_actor(p_token); IF NOT FOUND THEN RAISE EXCEPTION 'invalid_session'; END IF;` — never `v_actor := get_session_actor(p_token)`. Probe with a garbage token before reporting done, not just a valid one.
2. **Never gate a real-data replace on `isNotEmpty`.** `if (buildings.isNotEmpty) { setState(...) }` means a genuinely-empty real result never clears whatever placeholder was there before. Replace unconditionally once the fetch *completes* (success or a real empty list), and render a real empty state for the zero case.
3. **Never leave a `catch (_) {}` with no user-visible state.** Loading / error / empty-with-data / populated-with-data are four distinct states — a silent catch collapses error into whatever the initial placeholder was, which is exactly how the fake `'1,250'`/`'32 จาก 34 ห้อง'` bugs shipped and went unnoticed.
4. **Don't invent backend for something that doesn't have any.** If a page's data has no real RPC behind it (settings, device diagnostics without real hardware), say so honestly in the UI (banner/notice) rather than building a form that looks real but silently does nothing on save.
5. **Wire every new page into navigation as you build it**, don't leave "built but unreachable" pages for a report to claim as done — this happened twice already (Phase 2 Batch 1, and implicitly every page before the root-shell-swap made school_admin's new pages the actual landing experience).
6. **Role-filtered lists must use `UserModel.hasRole(role)`, not `user.role == role`**, if you're filtering `list_school_users` results by role anywhere in these pages — a multi-role account (the seeded `teacher@aiot-school-lab.local` test fixture has both `teacher` and `school_admin`) will otherwise silently vanish from role-filtered views. See section 11 of HANDOFF.md for the exact bug this caused on the school_admin side.
7. **Migration timestamp collisions are common right now** — check `ls supabase/migrations/ | tail -5` for the latest timestamp before creating a new one, don't guess.
8. **Don't touch the Supabase-Auth-based functions** (`acknowledge_sensor_alert`, `resolve_sensor_alert`, anything using `auth.uid()`/`is_super_admin()`/`has_role()`/`current_user_school_id()` instead of `get_session_actor(p_token)`) — those belong to `aiot_dev_dashboard`'s own separate security model layered on the same tables. Write new, separately-named `_for_super_admin` functions using `get_session_actor` instead, same as every other RPC in this codebase.

## What NOT to do

- Don't swap `role_router.dart`'s `super_admin` case yet — that's the follow-up brief once these pages exist.
- Don't touch the school_admin pages or their RPCs in this pass.
- Don't try to build all 6 pages before the first verification checkpoint — batch it, verify Batch 1 live (real login, real click-through, real garbage-token probes) before starting Batch 2, same discipline as every phase before this one.

## Verify

Same standard as every phase: real RPC calls with real session tokens
(super_admin positive, a non-super_admin role negative on every write
RPC), real browser click-through of each ported page with real seeded
data, honest empty/error states forced and confirmed (not just the
happy path), `flutter analyze` clean, existing test suites still
passing. Report back after each batch, not after all 6.
