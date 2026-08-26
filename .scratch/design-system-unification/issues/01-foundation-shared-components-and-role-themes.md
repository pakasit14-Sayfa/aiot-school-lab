# 01 — Foundation: shared structural components + per-role theme files

**What to build:** A small shared component library (button, text field,
search field) whose visual *structure* — corner radius, spacing,
padding, icon placement, focus/pressed states — matches the quality
and feel of the teacher and student redesigns, but whose *colors* are
never hardcoded. Each component reads its colors from whichever role's
theme is active, so the same button looks structurally identical
everywhere while still rendering in that role's existing color scheme.

Alongside the components, create one theme file per role that will be
migrated (school_admin, super_admin, executive, parent), each holding
that role's *existing* colors unchanged — these are the "single place
to change a role's colors later" the plan settled on. Teacher and
student are not touched and get no new theme file; their current code
stays exactly as-is and only serves as the visual reference for what
the shared components should look and feel like.

Nothing consumes these components yet — this ticket is done when they
exist, are documented, and are verified in isolation (unit/widget
tests, or a small internal demo screen), not when a real page uses
them.

**Blocked by:** None — can start immediately.

**Status:** done, verified 2026-08-26

- [x] Shared button, text field, and search field components exist in
      the shared UI layer (`packages/shared_ui/lib/theme/`:
      `app_button.dart`, `app_text_field.dart`, `app_search_field.dart`),
      with structure driven by a shared `buildRoleTheme()` builder
      (`role_theme.dart`) — border radius, padding, and font weights are
      identical for every role, modeled on the teacher/student redesigns
- [x] None of the 3 components hardcode a color — each pulls from
      whichever role's `ThemeData` (built by `buildRoleTheme`) wraps it;
      verified by rendering the same components under two different
      `RoleColors` and asserting the button/field colors differ while
      the border radius and padding stay identical
- [x] One theme file exists per role being migrated: `SchoolAdminPalette`
      (both copies, kept in sync), `AppPalette` (super_admin),
      `AppPalette` (executive), and a newly-created `ParentPalette` —
      each has a `roleColors`/`theme`/`roleTheme` getter built from that
      role's *existing* color constants, no new hex values introduced
- [x] Teacher and student have zero code changes — confirmed via `git
      status`, neither directory appears in the diff
- [x] `packages/shared_ui/test/role_theme_test.dart` (4 tests) verifies
      color-agnostic wiring under 2 different role themes + a render
      smoke test + `AppSearchField`'s interactive clear-button behavior;
      full `shared_ui` suite (7 tests) and full `user_app` suite (89
      tests) both pass — nothing broke
- [x] `flutter analyze` clean on `shared_ui` and every touched app file
      (the only analyzer output anywhere in the app is 37 pre-existing,
      unrelated issues in files this ticket never touched)

**Note for the next ticket (02, the School Admin home-page pilot):**
migrating a page means *removing* its inline `InputDecoration`/
`ButtonStyle` overrides so it inherits from the wrapping `Theme`, not
swapping widget types one-for-one — see the doc comment on
`buildRoleTheme` for why. Each role's root page needs to wrap itself in
`Theme(data: <RolePalette>.theme, child: ...)` once before this takes
effect on that role's pages.
