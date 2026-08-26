# Brief for agy: make the new super_admin hub the actual landing page

## Same idea as school_admin's root-shell-swap, but the gap runs the opposite direction

For `school_admin`, the new hub (`SchoolAdminDashboardPage`) already had a
complete 12-item sidebar, and the *old* shell had 8 extra operational
items that needed folding in before the swap. For `super_admin`, it's
reversed: **the old shell (`dashboard/super_admin_dashboard.dart`) only
has 3 items — all 3 already exist in the new hub — but the new hub
(`super_admin_hub_page.dart`) only actually links to 5 of the 8 real
pages that exist today.** Read this before touching `role_router.dart`.

## Confirmed by reading the actual navigation code, not guessing

`dashboard/super_admin_dashboard.dart`'s entire drawer: จัดการโรงเรียน
(→`SuperAdminSchoolsPage`), ควบคุมและอนุมัติอุปกรณ์
(→`SuperAdminDeviceControlPage`), จัดการผู้ใช้ (→`/users` route). That's
it — 3 items, and all 3 already have a working equivalent link inside
`super_admin_hub_page.dart` (Schools and Device Control appear in both
the summary-metrics cards and the quick-action cards; Users is the
5th quick-action card, `Navigator.pushNamed(context, '/users')`). **So
unlike school_admin, there is nothing old to fold in this time.**

But grepping every `Navigator.push` in `super_admin_hub_page.dart`
turns up exactly 5 distinct destinations: `SuperAdminSchoolsPage`,
`SuperAdminDeviceControlPage`, `SuperAdminPermissionsPage`,
`SuperAdminAlertsLogsPage`, and the `/users` route. **`SuperAdminDevicesPage`
(ทะเบียนและ QR Code), `SuperAdminDeviceTestPage` (ทดสอบอุปกรณ์), and
`SuperAdminSettingsPage` (ตั้งค่า) — 3 of the 8 real, working, already-
built Phase 3 pages — have zero links anywhere in the hub.** They're
only reachable today via the *old* shell's... wait, they're not even
there either — the old shell only ever had 3 items and was never
updated when Phase 3 added the other 5 pages. Check
`apps/user_app/lib/pages/dashboard/super_admin_dashboard.dart`'s
current drawer yourself before starting — if Phase 3's own wiring pass
already added them there and I'm looking at a stale read, adjust
accordingly, but as of this brief being written, only 3 items exist in
the old shell drawer and only 5 in the new hub, and the union of "old
shell + new hub" still leaves `SuperAdminDevicesPage`,
`SuperAdminDeviceTestPage`, and `SuperAdminSettingsPage` completely
unreachable from a fresh login either way — the only reason a real user
can find them at all right now is that `super_admin_dashboard.dart`
was directly edited during Phase 3 to add InfoCard/drawer entries for
all 8 (confirmed: `grep "SuperAdmin.*Page(" dashboard/super_admin_dashboard.dart`
shows 8 distinct page references). So today, before this swap, all 8
are reachable **only through the old shell**, not through the new hub.

## The fix, in order

1. **Add the 3 missing links to `super_admin_hub_page.dart` first.**
   Same visual pattern as the existing 5 (a quick-action card in
   `_buildQuickActionCards()` is the simplest fit — that section
   already has room for a 6th item in its 3-column grid). Wire:
   - `SuperAdminDevicesPage` — "ทะเบียนและ QR Code (Devices & QR)"
   - `SuperAdminDeviceTestPage` — "ทดสอบอุปกรณ์ (Device Diagnostics)"
   - `SuperAdminSettingsPage` — "ตั้งค่าระบบส่วนกลาง (Settings)"
2. **Verify live**: log in as `admin@aiot-school-lab.local` through the
   *old* shell (don't swap yet), manually navigate to the new hub via
   whatever entry point exists today (or temporarily route to it for
   testing), and click all 8 destinations from inside the hub itself —
   confirm each opens the correct real page with real data, not just
   that a button exists.
3. **Only then** change `role_router.dart`'s `super_admin` case from
   `const SuperAdminDashboard()` to `const SuperAdminHubPage()`.
4. Leave `dashboard/super_admin_dashboard.dart` in place, unreferenced,
   same as `school_admin`'s old shell — don't delete until this is
   verified live post-swap, per the standing old-UI-file policy in
   HANDOFF.md.

## Guardrails (same list as every phase, still applies)

- **Don't parallelize this with other super_admin/school_admin work.**
- **A green analyzer run does not prove navigation works.** Click
  through all 8 destinations for real, from the actual new hub, after
  the swap — not just before.
- This exact failure mode — a page built and reachable from the *old*
  shell, but silently unreachable once a new hub becomes the landing
  page — is precisely what would happen here if the 3 missing links
  aren't added before the swap. Don't repeat it in either direction.
- If you find the old shell drawer actually already has more than 3
  items when you check it fresh (i.e. this brief's read of it is
  stale), re-verify the actual gap yourself rather than trusting this
  document's specific counts — the *principle* (union of old+new must
  cover all 8 real pages before swapping) is what matters, not the
  exact numbers written here.

## What NOT to do

- Don't touch `school_admin`'s shell, RPCs, or pages in this pass.
- Don't delete `dashboard/super_admin_dashboard.dart` until the swap
  is verified live.
- Don't change any backend/RPC in this pass — this is UI navigation
  wiring only.

## Verify

Real login as `admin@aiot-school-lab.local`, real browser click-through
of all 8 destinations from the new hub post-swap (Schools, Device
Control, Devices/QR, Device Test, Permissions, Alerts & Logs, Settings,
Users), confirm each opens without error and shows real data.
`flutter analyze` clean, existing test suites (including
`super_admin_dashboard_test.dart` and the Phase 3 page tests) still
passing. Report back with the actual click-through list.
