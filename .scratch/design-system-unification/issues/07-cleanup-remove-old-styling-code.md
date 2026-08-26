# 07 — Cleanup: remove old per-role styling code

**What to build:** With School Admin (both the pilot and the rest),
Super Admin, Executive, and Parent all migrated to the shared
components, remove what's now dead: any leftover ad-hoc
`TextField`/button styling code that duplicated what the shared
components now do, and confirm nothing outside the 4 migrated roles
still references code paths that were only kept around for the old
styling. Teacher and student are explicitly out of scope and must be
left completely untouched — they were never migrated and have nothing
to clean up.

**Blocked by:** 03, 04, 05, 06

**Status:** ready-for-agent

- [ ] No leftover unused ad-hoc button/text-field/search-field styling
      code remains in the 4 migrated roles' pages
- [ ] Confirmed via grep/analyzer that nothing still references the
      removed code
- [ ] Teacher and student files are unchanged — diff confirms zero
      modifications to either
- [ ] Full app test suite passes, `flutter analyze` clean
- [ ] Final live click-through of all 4 migrated roles confirms no
      regression from the cleanup pass itself
