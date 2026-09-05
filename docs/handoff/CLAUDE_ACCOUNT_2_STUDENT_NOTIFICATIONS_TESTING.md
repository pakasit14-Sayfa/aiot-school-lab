# Claude Account 2 — Student notifications completion and verification brief

## Mission and ownership

Work only on student notifications and their learning-event producer, starting from commit `bbb7a27` on branch `claude/student-notifications-finish`. Read `CLAUDE.md`, `docs/handoff/DATA_CONNECTION_METHODOLOGY.md`, and `docs/handoff/CLAUDE_TEACHER_STUDENT_HANDOFF.md` before editing. Account 1 owns teacher SOS; do not edit teacher incident files.

Owned paths:

- `apps/user_app/lib/pages/notifications_page.dart`
- `apps/user_app/lib/pages/student_redesign_prototype/widgets/student_navigation_prototype.dart`
- `apps/user_app/lib/pages/student_redesign_prototype/widgets/student_variant_school_home.dart`
- notification tests under `apps/user_app/test/`
- `supabase/migrations/20260905010000_student_learning_notifications.sql` only through a new append-only corrective migration if necessary
- `supabase/tests/database/35_student_learning_notifications.test.sql`
- regenerated `docs/handoff/DATABASE_SCHEMA.md`
- a new account-specific result report (do not edit other shared status documents)

Do not touch generated plugin files, `pubspec.lock`, `apps/admin_app/`, teacher SOS files, production, or another account's branch. Never rewrite an applied migration; add a later migration for corrections.

## Required reasoning model

Verify the complete causal chain, not isolated widgets:

`teacher mutation RPC → committed status transition → trigger → correct notification row → student list RPC → UI/badge → mark-read RPC → canonical reload`

Each arrow must have evidence. A notification shown from injected fake data proves UI rendering only; it does not prove the producer. A pgTAP row proves database behavior only; it does not prove navigation/badge refresh. A returned RPC future does not prove persisted state. Only report end-to-end success after all layers pass.

For every change use red-green-regression:

1. Add or identify a test that fails for the intended behavior.
2. Confirm the failure is not setup/global-state noise.
3. Make the smallest fix.
4. Rerun the focused test plus all previously connected notification tests.
5. Test isolation/security and browser behavior.

Never fabricate notification cards. Genuine empty data must show the exact heading `ยังไม่มีข้อมูล`. A load error must show retry/error and preserve cached data; it must not masquerade as an empty inbox.

## Work to complete

1. Add widget tests for all three refresh-on-return call sites: student shell unread badge and both school-home notification entry points. Prove navigation is awaited and canonical unread/latest data reloads after the inbox pops. Tests must inject services/controllers; do not initialize real Supabase merely to make a widget test pass.
2. Verify `NotificationsPage` routing, filters, mark-read pending guard, cached-data behavior, stale-request protection, icon/type mapping, back navigation, and exact empty/error states.
3. Audit the learning producer migration against actual `publish_assignment`, `publish_lesson`, and `confirm_grade` implementations. Prove they update status and trigger exactly once. If terminal-state inserts are supported anywhere, add explicit coverage and a corrective migration rather than assumptions.
4. Validate recipient rules: enrolled active students in the same school for published assignments/lessons; exact active student owner in the same school for confirmed grades; no teacher/parent/other course/other school/inactive user recipients; no duplicate after repeated transitions.
5. Verify mark-read is authorized for the notification owner only and persists after a fresh list call. Rejected operations must not mutate rows.
6. Apply migrations only to local Supabase and regenerate `DATABASE_SCHEMA.md` from that live local catalog. Do not use linked/production commands.

## Mandatory test matrix

| Layer | Required cases |
|---|---|
| Producer | draft/no-op transition produces none; first publish/confirm produces one; repeat transition/retry remains one; rollback or failed teacher mutation produces none |
| Recipients | enrolled same-school active student receives; unenrolled, wrong-school, inactive and unrelated user receive none; grade goes only to its student |
| Security | missing/invalid token, wrong role, cross-school ID and null active school fail closed; direct table access remains denied; internal trigger function is not executable by PUBLIC/anon/authenticated/service_role |
| Inbox | load, filter by unread/assignment/grade/announcement, exact honest empty state, error+retry, cached rows retained during reload, stale request ignored |
| Mark read | owner can mark; exact row becomes read after canonical reload; failure/mismatch remains unread; duplicate click performs one mutation; another student cannot mark it |
| Navigation/badge | each of 3 entry points waits for inbox return; badge/latest card refreshes immediately; mounted/disposed safety; inbox route opens the actual production page |
| Regression | grades, assignments and learning tracks still behave identically after notification producer changes |

## Verification commands

Run from `apps/user_app`:

```powershell
flutter analyze lib/pages/notifications_page.dart lib/pages/student_redesign_prototype/widgets/student_navigation_prototype.dart lib/pages/student_redesign_prototype/widgets/student_variant_school_home.dart
flutter test test/student_notifications_page_test.dart
flutter test <new_student_navigation_notification_test.dart> <new_student_school_home_notification_test.dart>
```

Run from repository root:

```powershell
npx supabase migration up
npx supabase test db supabase/tests/database/10_grades_core.test.sql
npx supabase test db supabase/tests/database/11_assignments_core.test.sql
npx supabase test db supabase/tests/database/35_student_learning_notifications.test.sql
```

Run relevant Learning tracks tests if producer changes touch course enrollment/publication behavior. Then run the full DB and Flutter suites once. Record exact counts and names. Do not label failures pre-existing without reproducing them on base `bbb7a27` in a clean comparison worktree. Fix test oracles only when current schema/product rules prove the oracle stale; never remove assertions just to get green.

Browser acceptance on local Supabase must prove: publish assignment, publish lesson and confirm grade through supported RPC/UI; correct student receives each once; other student receives none; filters work; open/mark read updates badge after back navigation; full reload preserves read state; empty account says `ยังไม่มีข้อมูล`; network/error path offers retry without fake empty content. Use supported RPC fixture workflows, not raw runtime inserts.

## Completion gate and report

Do not call this complete until focused UI tests, targeted pgTAP, cumulative grades/assignments/notification regressions, analyzer, schema regeneration, and browser acceptance are recorded. If login/MFA/DNS blocks browser acceptance, report the exact blocker and stop at “code complete, acceptance pending.” Do not work around authentication by forging production sessions.

Write `docs/handoff/CLAUDE_ACCOUNT_2_STUDENT_NOTIFICATIONS_RESULT.md` containing: base/head commit; files and migrations; causal-chain evidence for every arrow; red test evidence; exact commands/counts; local DB identity; browser results; security/tenant evidence; schema regeneration; remaining failures. Commit only owned files and push only `claude/student-notifications-finish` after user approval.

## Suggested skills

Use the receiving environment's diagnosing-bugs skill for regressions, TDD for widget/RPC seams, implement for scoped work, and review against base `bbb7a27` before commit.
