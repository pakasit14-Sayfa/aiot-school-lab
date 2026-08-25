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
| `agy-brief-school-admin-fake-fallback-data.md` | Fixed silent fake fallback data across all School Admin pages (Tier A & Tier B). Eliminated silent `catch (_) {}` swallowing errors and removed `if (data.isNotEmpty)` guards so genuine empty/zero-count schools show honest empty states instead of hardcoded mock numbers and fake people. **Tier A (Real Backend)**: `SchoolAdminDashboardPage` summary grid, open alert panel, and recent audit activity now load real data with error/retry/empty states; `SchoolBuildingsPage`, `SchoolStudentsPage`, `SchoolTeachersPage`, `SchoolDevicesPage`, `SchoolPermissionsPage`, `SchoolImportPage`, and `SchoolAlertsPage` now initialize with empty lists `[]` and render honest empty states for main entities and audit logs. **Tier B (No Backend - Product Scope)**: `SchoolSettingsPage`, `SchoolAdminProfilePage`, and `SchoolReportsPage` now display clear disclosure notices explaining development/preview status (following G-Score precedent) without silently inventing fake RPCs or pretending to persist changes. Dedicated widget tests (`school_admin_empty_and_error_states_test.dart`) and full test suite 100% passing (67/67 in `user_app`, 47/47 in `shared_core`). |
| `agy-brief-school-admin-root-shell-swap.md` | Replaced legacy `school_admin` landing shell with the new modern hub `SchoolAdminDashboardPage` in `role_router.dart`. Folded all 8 operational features into the new 20-item sidebar & mobile drawer & home management grid: `จัดการผู้ใช้` (`UserListPage`), `Consent Policy` (`ConsentPolicyAdminPage`), `พลังงานทั้งโรงเรียน` (`SchoolAdminEnergyPage`), `กล้อง CCTV` (`SchoolAdminCctvPage`), `ตั้งเวลาอุปกรณ์` (`SchoolAdminDeviceSchedulePage`), `รายงาน ESG` (`SchoolAdminEsgPage`), `ควบคุมไฟและน้ำ` (`SchoolAdminDeviceControlPage`), and `กล่องแจ้งเหตุการณ์` (`SchoolAdminIncidentInboxPage`). All 20 items + profile navigate cleanly without regression across desktop and mobile. 56/56 tests in `user_app` and 45/45 tests in `shared_core` passing, 0 analyzer issues. Legacy `dashboard/school_admin_dashboard.dart` retained in codebase. |
| `agy-brief-lesson-editor-data-loss-bug.md` | Fixed data loss bug in teacher lesson editor: `_loadFullLesson()` now calls `get_lesson` to load real content blocks, materials, and sensor links before rendering and before autosave can run (`_isLoading` guard). Enhanced `list_lessons` in `20260826120000_enhance_list_lessons_counts.sql` to return `materials_count` and `sensor_links_count` avoiding N+1 queries. Updated `seed.sql` and DB to type example URL material as `link`. User-friendly error message in student view on download failures. **Independently re-verified 2026-08-25**: rebuilt the app from latest code, re-ran the exact repro that previously destroyed lesson content (open existing published lesson, edit title, let autosave fire) — real content now survives intact. Full SQL probes (positive token, invalid token `invalid_session`, update round-trip preserving content body) passed 100%. 53/53 tests in `user_app` and 45/45 tests in `shared_core` passing, 0 analyzer issues. |
| `agy-brief-school-admin-redesign-phase2.md` | Ported and wired all 13 `school_admin/*` pages from the new design. **Batch 1 (7 reuse-heavy pages)** and **Batch 2 (6 new pages: dashboard hub, profile, buildings, reports, settings, scan)** — **ALL 13 PAGES DONE & WIRED**. 4 new RPCs in `20260826110000_school_admin_redesign_phase2_batch2.sql` (`list_school_buildings`, `list_school_rooms`, `get_school_admin_dashboard_summary`, `list_school_admin_audit_logs`) probe-tested with 100% pass across positive, negative garbage token, and role isolation probes. All 13 pages wired to `school_admin_dashboard.dart` drawer & InfoCards. 52/52 tests in `user_app` and 45/45 tests in `shared_core` passing, 0 analyzer issues. |
| `agy-brief-super-admin-redesign-phase1.md` | Ported `schools_page.dart` + `device_control_page.dart` into `apps/user_app/lib/pages/super_admin/` backed by 7 custom session RPCs in `20260826090000_super_admin_redesign_phase1.sql`, models & service in `shared_core`, and wired into `super_admin_dashboard.dart`. **Independently re-verified 2026-08-25**: all 7 RPCs live-tested with real tokens (super_admin positive, student negative on `create_school_for_super_admin`), full create→update→suspend school round trip, full approval-request→`decide_control_approval_request`→real `queue_device_command` dispatch round trip including the double-decide guard, real browser click-through of both pages with real data rendering (device/user/school counts matched DB). Found and fixed 2 process issues while verifying: (1) the migration file collided on timestamp `20260826080000` with an already-committed migration — renamed to `20260826090000`; (2) agy's own verification run left a real `control_approval_requests` + `device_commands` row in the shared dev DB uncleaned — deleted. Neither affects the RPC/UI code itself. |

## Done (commit found)

| Brief | Closing commit | Topic |
|---|---|---|
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
