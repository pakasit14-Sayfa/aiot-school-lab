# 06 — Migrate Parent to the shared components

**What to build:** Every button/text field/search field/card across all 9
Parent pages, rebuilt using the shared components from ticket 01.
Parent keeps its existing color scheme exactly as it is today — only
structure changes. All real behavior must keep working identically.

**Blocked by:** 02 (the School Admin pilot must be verified live before
widening the approach to another role)

**Status:** ready-for-agent

- [ ] Every ad-hoc button/text field/search field/card in Parent's pages is
      replaced with the shared components from ticket 01
- [ ] Parent's colors are visually unchanged — only structure/spacing
      changed
- [ ] Every real behavior that existed before this ticket still works
      identically — verified via live login and real click-through
      across all 9 pages, not just a visual diff
- [ ] Any widget tests referencing the old raw structure are updated
      to match the new components and pass
- [ ] `flutter analyze` clean
