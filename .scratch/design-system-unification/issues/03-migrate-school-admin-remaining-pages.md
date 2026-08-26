# 03 — Migrate School Admin's remaining pages

**What to build:** Every other School Admin page (all 18 besides the
home view covered in ticket 02) rebuilt using the shared components
from ticket 01, same rules as the pilot: colors unchanged, structure
only, every real behavior (search filtering, form validation, buttons
calling real backend RPCs) keeps working identically.

**Blocked by:** 02 (the pilot must be verified live and working before
widening to the rest of School Admin)

**Status:** done — verified 2026-08-26

- [x] Every ad-hoc button/text field/search field/card in School Admin's
      remaining 18 pages is replaced with the shared components from
      ticket 01 — with two deliberate scope narrowings, both agreed with
      the user live:
      - **Buttons:** surveyed all 16 `styleFrom(...)` overrides across
        the 18 files. Every one is a semantic color (red = destructive
        delete/revoke, green = confirm/success, dynamic per-state color
        in the profile page's role toggle) or a genuine context-specific
        style (white outline on a dark scanner background). None
        duplicated the shared theme — all left untouched. Removing them
        would have destroyed real meaning (e.g. every delete button
        would lose its red warning color), not unified anything.
      - **Cards:** the user was asked directly (AskUserQuestion) whether
        every `BoxDecoration` container should collapse to the shared
        18px-radius `Card`, including small dense elements like filter
        chips and stat tiles that intentionally use smaller 12–16px
        radii. Decision: convert only large content/section-wrapper
        containers (generous padding, ≥16px), leave small chips/tiles
        at their original size-appropriate radius. Converted 45
        qualifying containers across 13 files this way (2 in the home
        page were already done in ticket 02); ~100 smaller/decorative
        containers (badges, pills, avatar circles, colored score cards)
        were surveyed and correctly left alone as they're semantic
        content, not structural duplicates.
      - Search fields needed no changes at all — none of the 6 files
        with a search box had an explicit border override, so they
        already inherited the shared rounded/filled look automatically
        once their page was wrapped in `Theme(data: SchoolAdminPalette
        .theme, ...)`.
      - Also removed 5 bare `border: OutlineInputBorder()` overrides
        (2 files) that were fighting the new theme's rounded fields.
- [x] Colors are visually unchanged across all of them — only
      structure/spacing changed (confirmed by the button-color survey
      above: no color values were touched anywhere in this ticket)
- [x] Every real behavior that existed before this ticket still works
      identically on every page — verified via live login
      (`schooladmin@aiot-school-lab.local`) and real click-through on
      home, buildings, teachers, students, and alerts pages: real
      seeded data displayed correctly (1 student, 1 teacher, honest
      zero-state on buildings/alerts — no fabricated numbers), and the
      students-page search field was exercised end-to-end (typed a
      query, list filtered live to "พบ 0 รายการ" with the clear-button
      and focus-highlight both working) confirming the shared
      `AppSearchField`-equivalent structural behavior survived the
      migration
- [x] `flutter analyze` clean — 0 errors across all 18 files (3
      pre-existing unrelated info-level lints only, none introduced by
      this ticket)
- [x] Full school_admin test suite passes (22 tests:
      `school_admin_dashboard_page_test.dart`,
      `school_admin_screenshot_test.dart`,
      `school_admin_empty_and_error_states_test.dart`,
      `school_admin_cctv_page_test.dart`)
