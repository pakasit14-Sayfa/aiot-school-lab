# Claude handoff: teacher SOS and student notifications

Date: 2026-09-05. Status: **work in progress, not production-ready**.
The user requests that Claude on another machine finish this work. Do not start another implementation agent automatically.

## Start here

Read `CLAUDE.md`, `docs/handoff/HANDOFF.md`, `docs/handoff/WORK_LOG.md`, and `docs/handoff/DATA_CONNECTION_METHODOLOGY.md`. Read actual code before trusting old status claims. School Admin Learning tracks is committed at `8a6b4f8`; Incident inbox corrections are at `f073049`. This handoff covers a different, partial teacher/student slice, not completion of all their pages.

Use custom session tokens and domain service classes; no Supabase Auth substitution, client table reads, new permissive RLS, or raw runtime fixture inserts. Use `npx supabase`, append-only migrations, and local DB only. Do not reset a populated database or change production. Do not commit credentials or `env.json`.

## Implemented draft to review

- `apps/user_app/lib/pages/teacher_redesign_prototype/controllers/staff_emergency_actions.dart`: injected write/read seam for incident versus hardware events, pending guard, canonical status confirmation, distinct rejected/unconfirmed outcomes, safe disposal.
- `apps/user_app/lib/pages/teacher_redesign_prototype/teacher_incident_inbox_page.dart`: hero/list acknowledge and close use that seam. Removed unconditional success after caught errors. Loading now preserves prior data on failure, shows a retry banner, and ignores stale requests. This is NOT a claim that the separate incident detail widget is fixed.
- `apps/user_app/test/staff_emergency_actions_test.dart`: 8 helper tests. These do not constitute real teacher page click-through coverage.
- `apps/user_app/lib/pages/notifications_page.dart`: injectable load/mark-read, working filters, honest `ยังไม่มีข้อมูล` state, stable Thai errors/retry, duplicate mark guard, canonical read-state confirmation. No fake notifications.
- `apps/user_app/test/student_notifications_page_test.dart`: 5 widget tests for filters, empty/error/retry and mark-read outcomes.
- `supabase/migrations/20260905010000_student_learning_notifications.sql`: internal SECURITY DEFINER status-change trigger, same-school active recipients, enrolled students for published assignments/lessons, grade owner for confirmed grades; per-source dedup index; direct execution revoked from PUBLIC/anon/authenticated/service_role. Does not replace publication RPCs. Applied successfully to this workstation's local database, not production or the other machine.
- `supabase/tests/database/35_student_learning_notifications.test.sql`: 15 rollback tests using learning RPCs, publication/confirmation, dedup, isolation, invalid access and read persistence.

## Evidence from this workstation

Commands below were actually rerun on 2026-09-05:

```powershell
# From apps/user_app
flutter analyze lib/pages/notifications_page.dart lib/pages/teacher_redesign_prototype/controllers/staff_emergency_actions.dart lib/pages/teacher_redesign_prototype/teacher_incident_inbox_page.dart
flutter test test/staff_emergency_actions_test.dart test/student_notifications_page_test.dart
flutter test
# From repo root
npx supabase test db supabase/tests/database/35_student_learning_notifications.test.sql
```

- Scoped analyzer: no issues.
- Targeted Flutter: 13 passed, 0 failed (8 + 5).
- Targeted DB: 15 passed, 0 failed. Earlier pre-migration run failed 7/15; after migration all 15 passed.
- Full Flutter: **196 passed, 26 failed (222 total), exit 1**. Do not call this regression-green. Observed failures include executive emergency tests without initialized Supabase, executive overview tests, and super-admin navigation finders (missing/ambiguous targets). Full failure-by-failure baseline comparison has NOT been performed, so do not label all 26 pre-existing. Raw combined output was not saved as an artifact; rerun with a log on the receiving machine.
- Full DB regression for this slice, REST smoke, real browser click-through, pinned-SDK validation and hardware/device testing: NOT completed.

## Ordered work for Claude

1. Check branch/status/toolchain and read this diff. Preserve other people's changes. Configure this machine's ignored environment file using its own local Supabase configuration; a Git pull does not transfer a running DB, credentials, or runtime test accounts. Verify the local target, then apply pending migrations with `npx supabase migration up`. Do not use `--linked` or `db reset`.
2. Review the producer migration for authorization, duplicate recipients, lifecycle behavior and compatibility with live learning RPCs. Current triggers fire on UPDATE OF status only; explicitly check whether any supported RPC inserts directly as published/confirmed and add coverage/fix if required. Add missing ACL/rollback/tenant negative tests as needed. Regenerate `DATABASE_SCHEMA.md` from the receiving machine's live local catalog after migration; this snapshot update remains pending.
3. Finish teacher SOS detail actions (`_acknowledge`, escalation and close in the detail widget in the same inbox file). Verify every supported source and exact ID, busy handling, safe errors, canonical confirmation and keeping user input on failure. Add page-level success/failure/loading/retry tests; current helper tests alone are insufficient. Existing direct-table realtime streams in shared services were not changed; audit their behavior under deny-all RLS before claiming live updates work. Do not weaken RLS to fix them.
4. Verify the student shell's notification badge/icon mapping and refresh when returning from the inbox. Confirm actual navigation reaches this NotificationsPage. End-to-end: teacher publishes assignment/lesson or confirms score -> correct student receives one notification -> read state persists after reload; unrelated students/schools receive none. No invented notification content or optimistic success.
5. Rerun relevant grades/assignments/incidents/emergency DB tests, all prior School Admin regression tests, and full Flutter. Capture exact counts and classify failures against the base commit in an isolated worktree if needed. Do not change or drop assertions just to get green.
6. Perform browser acceptance for teacher and student with supported runtime RPC fixture creation. Test error/retry, empty state, permissions, and back navigation. After each newly connected page, rerun already-connected pages, including parent flows when shared code changes. The user explicitly requires cumulative regression and `ยังไม่มีข้อมูล` on genuinely empty cards; errors must not masquerade as empty data.
7. Update HANDOFF/WORK_LOG/task_plan with verified results and remaining gaps, regenerate schema, review the scoped diff, then commit. Do not claim all teacher/student pages done or invent a readiness percentage. Ask before a further push unless the user authorizes it.

## Transfer boundaries

Generated Linux/macOS/Windows plugin files, `apps/user_app/pubspec.lock`, and untracked `apps/admin_app/` are excluded from this transfer; preserve them on this workstation. Existing Learning tracks documentation corrections are carried forward without reinterpreting their historical evidence. No stash is applied. Local-only master plans under `C:/tmp` are not prerequisites: this document is self-contained for the current slice. RAM of about 1 GB was from a different machine; measure the receiving machine instead of assuming that constraint.

## Suggested skills

Use the receiving agent's equivalents of implement, TDD and code review. Use diagnosis for failing tests. Keep changes scoped and evidence-based; browser verification remains a separate required acceptance step.
