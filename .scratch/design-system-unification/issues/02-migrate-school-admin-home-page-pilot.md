# 02 — Migrate School Admin's home page (pilot)

**What to build:** Just School Admin's home/landing view (the summary
cards, quick-action grid, and any buttons/search/inputs on that one
screen — not the 18 other School Admin pages behind it) rebuilt using
the shared components from ticket 01. Colors stay exactly as they are
today (brown/gold/cream) — only structure changes. Every real behavior
on this page (the summary metrics, quick-action navigation, anything
that reads real data) must keep working identically.

This is the deliberate pilot: small enough to validate that ticket 01's
components actually work correctly on a real, live page before rolling
the same approach out further. Don't start any other migration ticket
until this one is verified live.

**Blocked by:** 01

**Status:** done, verified 2026-08-26

- [x] School Admin's home page (`_HomeDashboard` in
      `school_admin_dashboard_page.dart`) wrapped in
      `Theme(data: SchoolAdminPalette.theme, child: ...)` at its single
      call site (`_selectedIndex == 0`); the home page's only structural
      override (a `FilledButton.icon`'s explicit `style:` duplicating
      what the theme now provides) was removed so it inherits from the
      theme instead — every other button on the page had no override to
      begin with and picked up the new structure automatically
- [x] Colors on this page are visually unchanged (still brown/gold/
      cream) — confirmed via screenshot, only button/field structure
      (corner radius, padding) changed
- [x] Real behavior verified live: logged in as
      `schooladmin@aiot-school-lab.local`, home page still shows real
      summary metrics matching the DB (1 student, 1 teacher, 0/0
      buildings, 9 devices/8 online), quick-action cards still navigate
      correctly
- [x] Existing widget tests (`school_admin_dashboard_page_test.dart`,
      `school_admin_screenshot_test.dart`,
      `school_admin_empty_and_error_states_test.dart` — 21 tests total)
      pass unchanged, no updates needed
- [x] `flutter analyze` clean
- [x] Confirmed no other School Admin page was touched: screenshotted
      the students page (a different `_selectedIndex`) side-by-side —
      still renders with the old, unmigrated button/field structure,
      proving the `Theme(...)` wrap is correctly scoped to only the
      home page and doesn't leak into the rest of the hub
- [x] **Scope addition, 2026-08-26 (same day, user request after
      reviewing the button fix live):** cards added as a 4th shared
      component alongside button/text-field/search-field. `buildRoleTheme`
      already defined an unused `cardTheme`; the 3 card-shell classes on
      this page (`_SectionCard`, `_HomeSummaryCard`, `_ManagementCard`)
      were migrated from their own hardcoded `BoxDecoration` (3 separate
      `circular(18)`/`circular(22)`/`circular(23)` values, all slightly
      different from each other) to the real `Card` widget /
      `Theme.of(context).cardTheme`, unifying all 3 to one radius.
      `_ManagementCard` needed `Material`+`InkWell` kept (not swapped to
      `Card`) since it needs a real tap ripple — only its
      color/radius/border values now come from the ambient theme instead
      of being hardcoded 3 times. All content/layout inside each card
      (title, subtitle, icons) is unchanged. Re-verified: 21 tests still
      pass, `flutter analyze` clean, live screenshot confirms real data
      and layout intact.

**Note for tickets 03+:** cards are now in scope for every future
migration ticket too, not just buttons/text fields/search fields —
update each ticket's "what to build" to include card shells before
starting it.
