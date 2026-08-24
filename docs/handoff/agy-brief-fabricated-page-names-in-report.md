# Brief for agy: the "23/27" summary table listed 5 pages that don't exist

The QR scanner fix itself (both files, swapping to
`check_terminal_pairing_status`) was verified correct — real RPC call, real
data returned, `flutter analyze` clean. No issue with the actual code
change. The problem is the summary table in that same report.

## What's wrong

The "School Admin (14 หน้า)" list included: `school_device_detail`,
`school_device_logs`, `school_users`, `school_classes`,
`school_analytics`. None of these files exist:

```
find ~/aiot_dev_dashboard/lib/pages -iname "*school_device_detail*" \
  -o -iname "*school_users*" -o -iname "*school_classes*" \
  -o -iname "*school_analytics*" -o -iname "*school_device_logs*"
# → no output
```

Total file count in `lib/pages/` is 27, same as it's been all day — no new
pages were created. The real file list under `school_admin/` is 15 files,
and the table both invented 5 names that aren't there and left out real
ones that are (`school_admin_dashboard_page.dart`, `school_alerts_page.dart`,
`school_settings_page.dart`, `school_resources_page.dart` weren't
mentioned at all).

## Please don't do this

When listing which pages are done, list files that actually exist —
`find lib/pages -iname "*.dart"` or equivalent, not names that sound
plausible for what a school admin dashboard "should" have. This is
different from the earlier over-claims (a page reported as wired that
turned out to use a `static const` or a local list) — this is inventing
files. It undermines trust in the parts of the same report that *were*
accurate, which is a shame because the actual code fix this time was
correct.

## Ground truth: real file-by-file status as of this brief

For reference, here's the actual current state of all 27 files in
`lib/pages/`, independently verified today (each with a real read/write
call confirmed, most live-tested against the database):

**Confirmed fully working (23):** `admin_login_page.dart`,
`alerts_logs_page.dart`, `dev_dashboard_page.dart`,
`device_control_page.dart`, `device_test_page.dart`, `devices_page.dart`,
`kiosk_pairing_scanner_page.dart`, `permissions_page.dart`,
`schools_page.dart`, `settings_page.dart`,
`school_admin/school_admin_home_page.dart`,
`school_admin/school_admin_profile_page.dart`,
`school_admin/school_alerts_page.dart`,
`school_admin/school_buildings_page.dart`,
`school_admin/school_devices_page.dart`,
`school_admin/school_import_page.dart`,
`school_admin/school_permissions_page.dart`,
`school_admin/school_reports_page.dart`,
`school_admin/school_resources_page.dart` (read-only by design, no write
needed), `school_admin/school_scan_page.dart`,
`school_admin/school_settings_page.dart`,
`school_admin/school_students_page.dart`,
`school_admin/school_teachers_page.dart`.

**Fine, no backend of their own needed (2):** `scan_page.dart` (thin
redirect to `kiosk_pairing_scanner_page.dart`, inherits today's fix),
`school_admin/school_admin_dashboard_page.dart` (navigation shell around
the other school_admin pages).

**Partial (1):** `learning_platform_page.dart` — device
control/simulator commands are real (`device_commands` writes), but the
lesson/content list (`_items`, `_schools`) is still hardcoded. Not
re-verified today, carried over from the earlier finding.

**Dead code, not reachable, not a bug (1):** `school_admin/school_simple_page.dart`
— not referenced anywhere in the navigation, confirmed earlier today.

That's a real, complete 27/27 accounted for — 23 solid, 2 that were never
going to need their own database calls, 1 known partial, 1 harmless dead
file.
