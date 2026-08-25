# Brief for agy: make the new school_admin design the actual landing page — high blast radius, read this whole thing before starting

## Why this brief exists

You reported the lesson-editor data-loss fix as done — I independently
re-verified it live (rebuilt the app, re-ran the exact repro that used to
destroy lesson content, confirmed content now survives an edit) and it
checks out. Good work, no action needed there.

Separately, the user asked directly whether `schooladmin@aiot-school-lab.local`
now lands on the new design after login. I tested live (not from your
report) and it does **not** — logging in still lands on the old plain
`InfoCard` shell (`dashboard/school_admin_dashboard.dart`). Your own
follow-up correctly diagnosed this and proposed replacing the root shell.
That diagnosis is right. This brief is that work, with the scope corrected
and some guardrails added because **this specific change has a much bigger
blast radius than anything in Phase 1/2** — it's the entry point every
school_admin session goes through, not one more page in a drawer.

## What "done" means

After login, `schooladmin@aiot-school-lab.local` sees
`SchoolAdminDashboardPage` (the blue/indigo themed hub with the 12-item
sidebar) immediately — not the old `InfoCard` list. Every menu item that
currently works in the old shell still works from the new one. Nothing
that's reachable today becomes unreachable.

## Scope correction — it's 8 items to fold in, not 5

I grepped the old shell's drawer directly rather than estimate. The new
hub's sidebar (`school_admin_dashboard_page.dart`, `_MenuItemData` list,
line ~31-42) currently has exactly these 12, hardcoded:

หน้าหลัก, จัดการนักเรียน, ครูและบุคลากร, นำเข้าข้อมูล, กำหนดสิทธิ์,
อาคารและห้อง, อุปกรณ์, การใช้ทรัพยากร, สแกนคิวอาร์โค้ด, การแจ้งเตือน,
รายงาน, ตั้งค่าโรงเรียน

The old shell's drawer (`dashboard/school_admin_dashboard.dart`, lines
~36-230) has these, in order — cross-check against the list above, **8 of
them have no equivalent in the new sidebar**:

| Old drawer item | Target | In new sidebar already? |
|---|---|---|
| Dashboard โรงเรียน | no-op (`onTap: (_) {}` — already dead, skip) | — |
| **จัดการผู้ใช้** | `Navigator.pushNamed(ctx, '/users')` | ❌ missing |
| **Consent Policy** | (check what this pushes — I didn't trace it, you need to) | ❌ missing |
| **พลังงานทั้งโรงเรียน** | `school_admin_energy_page.dart` | ❌ missing |
| **กล้อง CCTV** | `school_admin_cctv_page.dart` | ❌ missing |
| **ตั้งเวลาอุปกรณ์** | `school_admin_device_schedule_page.dart` | ❌ missing |
| **รายงาน ESG** | `school_admin_esg_page.dart` | ❌ missing |
| **ควบคุมไฟและน้ำ** | `school_admin_device_control_page.dart` | ❌ missing |
| **กล่องแจ้งเหตุการณ์** | `school_admin_incident_inbox_page.dart` | ❌ missing |
| ข้อมูลนักเรียน | `school_students_page.dart` | ✅ "จัดการนักเรียน" |
| ครูและบุคลากร | `school_teachers_page.dart` | ✅ |
| กำหนดสิทธิ์บุคลากร | `school_permissions_page.dart` | ✅ "กำหนดสิทธิ์" |
| นำเข้าข้อมูล | `school_import_page.dart` | ✅ |
| การแจ้งเตือนเซนเซอร์ & ระบบ | `school_alerts_page.dart` | ✅ "การแจ้งเตือน" |
| การใช้ทรัพยากร | `school_resources_page.dart` | ✅ |
| คลังอุปกรณ์ IoT | `school_devices_page.dart` | ✅ "อุปกรณ์" |
| อาคารและห้องเรียน | `school_buildings_page.dart` | ✅ "อาคารและห้อง" |
| รายงานและสถิติ | `school_reports_page.dart` | ✅ "รายงาน" |
| ตั้งค่าโรงเรียน | `school_settings_page.dart` | ✅ |
| สแกน QR Code | `school_scan_page.dart` | ✅ |
| ศูนย์กลางแดชบอร์ดใหม่ | `school_admin_dashboard_page.dart` (this becomes the shell itself, drop the menu entry) | — |
| โปรไฟล์ผู้ดูแล | `school_admin_profile_page.dart` | (already reachable via the user card in the new sidebar — confirm) |

**Confirmed missing: จัดการผู้ใช้ (`/users`), Consent Policy, พลังงานทั้งโรงเรียน,
กล้อง CCTV, ตั้งเวลาอุปกรณ์, รายงาน ESG, ควบคุมไฟและน้ำ, กล่องแจ้งเหตุการณ์
— 8 items, not 5/6.** Add all 8 to the `_MenuItemData` list and wire each
to its target the same way the existing 12 are wired (find wherever
`onSelect(index)` maps to a page body — extend that switch/index mapping
too, the sidebar list and the body-switch have to stay in sync).

## The swap itself

1. In `apps/user_app/lib/pages/role_router.dart`, change the `school_admin`
   case from `const SchoolAdminDashboard()` to
   `const SchoolAdminDashboardPage()` — but **only after** step 2 below is
   done and verified, not before.
2. Fold in the 8 missing items (previous section) into
   `SchoolAdminDashboardPage`'s sidebar + drawer + body-switch, in both
   `_DesktopSidebar` and `_MobileDrawer` (there are two separate nav lists
   in this file per the earlier grep — desktop and mobile — don't fix one
   and miss the other).
3. Old shell file `dashboard/school_admin_dashboard.dart` — do **not**
   delete it yet. Leave it in place, just unreferenced from
   `role_router.dart`, until this is live-verified. Delete only after
   verification passes (matches the existing old-UI-file policy in
   HANDOFF.md).

## Guardrails — why this brief exists instead of a plain "go ahead"

This is the **root landing page for an entire role**, not one more leaf
page. A mistake here means school_admin can't log in at all, not just
"one page is missing." Treat it accordingly:

- **Don't parallelize this with anything else.** No other school_admin or
  super_admin work in flight at the same time as this swap.
- **Verify live before reporting done, not just `flutter analyze` +
  widget tests.** Specifically: log in as `schooladmin@aiot-school-lab.local`
  for real, and click through **all 20 old menu items' targets**
  (not just the 8 you added) from the new shell to confirm nothing
  regressed. A green analyzer run does not prove navigation works.
- **Batch 1 already taught us "built but unreachable" is a real failure
  mode in this exact file** — new pages existed but nothing linked to
  them. Don't repeat that in reverse (link exists, but points at a
  removed/renamed widget, or the desktop list gets the fix and the mobile
  drawer doesn't).
- If `Consent Policy`'s target isn't obvious from a quick grep, don't
  guess what it does — flag it back rather than silently dropping it or
  misrouting it.

## What NOT to do

- Don't touch `super_admin`'s shell in this pass — same problem exists
  there (2/8 pages ported, root shell still old) but it's smaller scope
  and not requested yet. Separate brief later.
- Don't delete `dashboard/school_admin_dashboard.dart` until the swap is
  verified live.
- Don't change any backend/RPC in this pass — this is UI navigation
  wiring only.

## Verify

Real login as `schooladmin@aiot-school-lab.local`, real browser
click-through of **every one of the 20 old menu targets plus the 12
existing new-design pages** from the new shell — 32 destinations total,
confirm each opens without error. `flutter analyze` clean.
`flutter test` clean. Report back with the actual click-through list, not
just "all pages reachable."
