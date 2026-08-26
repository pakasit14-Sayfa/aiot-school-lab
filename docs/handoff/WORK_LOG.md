# Work Log — index of every agy brief, one place to check status

This file exists because `docs/handoff/` accumulated 28 separate
`agy-brief-*.md` files with no single index — checking "what's been done"
meant opening files one by one. This is that index. **For the current
state of the app (what's wired, what's mock, what role does what), read
`HANDOFF.md` instead — this file is a task log, not a status doc.**

Status is cross-checked against `git log`, not guessed. **"✅ Done
(commit)"** means a specific commit closing that brief was found.
**"⚠️ Unclear"** means no clear closing commit was found in the log —
don't assume it's done, check the brief file itself and grep recent
commits before trusting either way. **"🔄 In progress"** means it's the
active/current work as of this writing.

## In progress

*None currently active.*

## Done (uncommitted / ready for commit)

| Brief | Topic |
|---|---|
| `agy-brief-super-admin-root-shell-swap.md` | Added the 3 missing links (`SuperAdminDevicesPage`, `SuperAdminDeviceTestPage`, `SuperAdminSettingsPage`) to `super_admin_hub_page.dart`'s quick-action cards and drawer (now 8/8), then swapped `role_router.dart`'s `super_admin` case to `SuperAdminHubPage`. **Independently re-verified 2026-08-26**: real login as `admin@aiot-school-lab.local` lands directly on the new hub (confirmed via screenshot), all 8 quick-action cards present with real summary metrics matching the DB, clicked into 2 of the 3 newly-added pages (Devices & QR, Settings) and confirmed real data + honest Tier B disclosure on Settings. Old shell `dashboard/super_admin_dashboard.dart` retained, unreferenced, per policy. `flutter analyze` clean, 24/24 super_admin tests passing. |
| `agy-brief-super-admin-redesign-phase3.md` + `agy-brief-super-admin-phase3-followup-fixes.md` | The remaining 6 super_admin pages (dev_dashboard, devices, device_test, permissions, alerts_logs, settings), ~15,300 source lines. Reported done 2026-08-25; independent re-verification found 3 issues (fake diagnostic latency numbers, a reintroduced fake-building-name fallback, and `list_school_admin_audit_logs` silently showing super_admin only 17% of real rows) — **all 3 fixed and independently re-verified live** the same day: real `Stopwatch()` timing around real RPC calls in the device test page, `'ไม่ระบุ'` fallback matching the school_admin fix, and `20260826140000_super_admin_audit_logs_scope.sql` giving super_admin the full cross-school view while leaving school_admin's own scope provably unchanged. Navigation wiring, root-shell-untouched constraint, and most backend reuse (permissions/alerts/hub) were correct from the start, no new migrations needed for those. `flutter analyze` clean. |
| (no brief file — found and fixed directly, 2026-08-26) | `school_admin`'s "นำเข้าข้อมูล" (bulk import) page was found to be a facade during a routine spot-check: the file picker never opened a real OS dialog, the preview grid was hardcoded fake sample rows regardless of what "file" was picked, and — critically — for นักเรียน/ครูและบุคลากร the import button called a **real** RPC that inserted those hardcoded fake names into the real database every time (proven live, then cleaned up). Rebuilt for real, all 5 data types: `file_picker` (already a dep) + new `excel`/`csv`/`http` packages in `shared_core` power real `.xlsx`/`.xls`/`.csv` parsing and public "Publish to web" Google Sheets CSV import (`packages/shared_core/lib/services/school_import_service.dart`); real per-row validation (required fields, duplicate-code-in-file, building→room cross-reference) drives the same preview grid UI. New migration `20260826150000_school_admin_bulk_import.sql` adds `import_school_buildings_batch`/`import_school_rooms_batch`/`import_school_devices_batch` (buildings/rooms/devices had **zero** backend before this — not even single-item creation existed) mirroring the existing `import_school_users_batch_for_school_admin` pattern; `ชุดฝึก` reuses the devices RPC since a "kit" is just `devices.kit_code`, not a separate table. New pgTAP suite `29_school_admin_bulk_import.test.sql` (19/19 pass). Independently verified live end-to-end for all 5 data types: built real CSV fixtures with deliberately-bad rows, uploaded through the real UI via Playwright's `filechooser` event (not a mock), confirmed the preview reflected real parsed content, confirmed only valid rows reached the RPC (bad email / missing name / nonexistent building-reference / invalid device-type rows all correctly excluded with real skip reasons), confirmed the exact expected rows landed in the database, then cleaned up all test data. Grounded in UC-12 (`AIoT-School-Lab-Vault/UC-Descriptions/Extended_School_Admin_Use_Cases.md`) for the นักเรียน/ครูและบุคลากร validation rules; no UC exists for the other 3 types, which were designed fresh following this project's existing RPC conventions. |

## Done (commit found)

| Brief | Closing commit | Topic |
|---|---|---|
| `agy-brief-school-admin-fake-fallback-data.md` | `08bc0b2` | Fixed silent fake fallback data across all School Admin pages (Tier A & Tier B) — silent `catch (_) {}` and `if (data.isNotEmpty)` guards were hiding both fetch errors and genuinely-empty real results behind hardcoded mock data. |
| `agy-brief-school-admin-root-shell-swap.md` | `08bc0b2` | Replaced legacy `school_admin` landing shell with the new hub `SchoolAdminDashboardPage` in `role_router.dart`, folding in all 8 old operational menu items so nothing already working got lost. |
| `agy-brief-lesson-editor-data-loss-bug.md` | `08bc0b2` | Fixed data loss bug in teacher lesson editor — opening an existing lesson loaded a placeholder instead of real content, and autosave then overwrote the real body with it. |
| `agy-brief-school-admin-redesign-phase2.md` | `08bc0b2` | Ported and wired all 13 `school_admin/*` pages from the new design (Batch 1 reuse-heavy + Batch 2 new). |
| `agy-brief-super-admin-redesign-phase1.md` | `08bc0b2` | Ported `schools_page.dart` + `device_control_page.dart` into the new design, backed by 7 real RPCs. |
| `agy-brief-multi-role-fix-and-followups.md` (no separate brief file — fixed directly, not from a written brief) | `08bc0b2` | 3 issues found via live user testing after the fake-fallback-data fix shipped: `_AssignmentOverview` widget, `school_students_page.dart`'s per-grade breakdown, and `school_teachers_page.dart` showing 0 teachers despite a real one existing (multi-role `list_school_users` scoping bug — see HANDOFF.md section 11). |
| `agy-brief-multi-role-login-phase1.md` | `cf8de5b` | One account, multiple roles, choose at login |
| `agy-brief-post-role-merge-remediation.md` | `b4ce6ad` | SOS teacher-visibility gap, teacher class schedule UI, device command rate limit |
| `agy-brief-role-merge-technician-facility-manager.md` | `2012849` | Merged `technician`→`super_admin`, `facility_manager`→`school_admin`, 8→6 roles |
| `agy-brief-school-admin-remaining-4-features.md` | `c24a7c1` | Energy/ESG, CCTV grants, device pg_cron scheduling, device control |
| `agy-brief-attendance-and-cctv-access-grants.md` | `c24a7c1` | Real attendance marking + CCTV access-grant management |
| `agy-brief-parent-attendance-leftover-mock.md` | `180dc04` | Removed 3 leftover-mock sections in parent attendance page |
| `agy-brief-infinite-height-followup-verify-executive.md` | `c4b3df4` | Verified the RenderFlex overflow fix on 4 executive pages |
| `agy-brief-infinite-height-row-crash-10-files.md` | `5a413bc` | `Row(crossAxisAlignment: stretch)` crash across 10 ported pages |
| `agy-brief-parent-executive-backend-wiring.md` | `5a413bc` | Wired real backend into ported parent/executive UI |
| `agy-brief-wire-parent-executive-ui-to-backend.md` | `5a413bc` | Same effort, backend existed but nothing called it yet |
| `agy-brief-fix-kong-internal-host-signed-url.md` | `b4d6271` | Signed download URLs leaked the Docker-internal `kong:8000` host |
| `agy-brief-learning-platform-page-fully-mock.md` | `355c6ae` | `learning_platform_page.dart` — was 100% mock, corrected an earlier wrong "partial" claim |
| `agy-brief-fabricated-page-names-in-report.md` | `dad8b65` | A status report listed 5 pages that don't exist — corrected |
| `agy-brief-qr-pairing-decision-readonly-status.md` | `6892f05` | Product decision: QR pairing scanners are read-only status, not control |
| `agy-brief-remaining-fake-features-2026-08-24.md` | `e248ba2` | 5 fake/missing features found finishing a page-by-page audit |
| `agy-brief-redteam-super-admin-findings.md` | `7ab0f6e` | RedTeam pass on `aiot_dev_dashboard`, incl. a migration-collision fix |
| `agy-brief-URGENT-security-rls-anon-open.md` | `d24b1b5` | Anon-open RLS policies were leaking the whole DB |
| `agy-brief-qr-pairing-wrong-rpc.md` | superseded by `6892f05` | An earlier "fix" called the wrong RPC — resolved by the read-only decision instead |
| `agy-brief-qr-pairing-fixes.md` | `b3e349d` | 3 fixes for AUTH-5 terminal QR pairing |
| `agy-brief-question-dev-dashboard-15pct.md` | superseded | Asked why `aiot_dev_dashboard` was only ~15% real — answered later when it reached 26/26 (see that app's own `docs/handoff/HANDOFF.md`) |

## ⚠️ Unclear — verify before trusting either way

| Brief | Why it's unclear |
|---|---|
| `agy-brief-fix-alerts-logs-fake-writes.md` | No commit found that clearly closes this — `alerts_logs_page.dart` fake local writes may still be open. Check the file directly. |
| `agy-brief-fix-school-admin-home-hardcoded-stats.md` | Only found a commit that *expands* the fix notes (`595bbb4`), not one confirming it landed. Check `school_admin_home_page.dart`... *note: this may refer to the old `dashboard/` school_admin, which has since been fully rewired — could already be moot.* |
| `agy-brief-ci-pipeline-real-cause.md` | Only the brief-writing commit found, no fix commit. CI pipeline status unverified. |
| `agy-brief-kiosk-pairing-admin-architectural-mismatch.md` | No closing commit found — may still be an open architectural question, not a code fix. |
| `agy-brief-school-admin-dashboard-dead-drawer-buttons.md` | No direct closing commit, but `school_admin_dashboard.dart` was fully rewired to 8/8 real menus in `c24a7c1` — likely moot/superseded rather than genuinely open. Not independently re-verified. |
| `agy-brief-full-remaining-backlog-2026-08-24.md` | A large backlog list, not a single fixable item — items from it fed into later work (role merge, remediation) but the file itself was never "closed" as a whole. Treat as a reference list, not a tracked task. |

## Adding to this log

When you write a new `agy-brief-*.md`, add it to "In progress" here. When
you verify it's actually done (real RPC/browser test, not just agy's
say-so), move it to "Done" with the commit hash. Don't mark something
Done from a report alone.
