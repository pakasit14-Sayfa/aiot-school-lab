# Claude Account 1 — Teacher SOS completion and verification brief

## Mission and ownership

Work only on the teacher SOS/incident detail slice, starting from commit `bbb7a27` on branch `claude/teacher-sos-finish`. Read `CLAUDE.md`, `docs/handoff/DATA_CONNECTION_METHODOLOGY.md`, and `docs/handoff/CLAUDE_TEACHER_STUDENT_HANDOFF.md` before editing. Account 2 owns student notifications and their database producer; do not edit those files.

Owned paths:

- `apps/user_app/lib/pages/teacher_redesign_prototype/teacher_incident_inbox_page.dart`
- `apps/user_app/lib/pages/teacher_redesign_prototype/controllers/staff_emergency_actions.dart`
- teacher-SOS tests you add under `apps/user_app/test/`
- a new account-specific result report (do not edit shared handoff/status documents)

Do not touch generated plugin files, `pubspec.lock`, `apps/admin_app/`, shared status documents, production, or another account's branch.

## Required reasoning model

Treat a mutation as this state machine:

`idle → submitting → RPC accepted/rejected → canonical read → confirmed/unconfirmed → UI result`

RPC completion alone is not success. Show success only when a fresh read of the same source and exact incident ID has the expected state. A write rejection is `failed`; a successful write followed by missing/mismatched/unreadable state is `unconfirmed`. Never turn an error into an empty state and never expose raw backend errors to the user.

For every bug, prove the behavior at the lowest stable seam and at the page seam:

1. Write a test that fails for the intended reason.
2. Make the smallest production change.
3. Rerun the focused test.
4. Rerun every earlier SOS test.
5. Run analyzer and relevant database regressions.
6. Perform browser acceptance last; automated green does not replace it.

If the red test passes before the change, the test does not prove the bug. If a test fails due to missing Supabase initialization, overflow, stale finder, or global state instead of the intended behavior, fix the harness before judging production code.

## Work to complete

1. Review all constructors/call sites of `TeacherIncidentDetailPage` and the shared `StaffEmergencyActions` lifecycle. Ensure a detail route cannot use a disposed controller.
2. Finish `_saveNote`, which is explicitly still on the old pattern. It must use a service/RPC path, hold a per-target busy lock, retain entered text on failure/unconfirmed result, reload the exact incident detail, and confirm the new action exists before showing success. If no safe canonical read exists, add the smallest school-scoped SECURITY DEFINER RPC through the domain service; do not query a table from the page or weaken RLS.
3. Add page-level widget tests with injected dependencies so tests do not require a live global Supabase instance.
4. Verify existing acknowledge/escalate/close behavior against the matrix below and fix any actual mismatch without broad refactoring.

## Mandatory test matrix

| Action | Confirmed success | Write failure | Canonical mismatch/read failure | Concurrency/input |
|---|---|---|---|---|
| Acknowledge | exact incident becomes `acknowledged`/supported in-progress state; page exits or refreshes only after confirmation | stable Thai failure; page stays usable | say request sent but not confirmed; never success | duplicate click causes one write; control disabled while pending |
| Escalate | exact incident becomes `escalated` | stable Thai failure | distinct unconfirmed message | duplicate click blocked |
| Close normal | `resolved` and `cancelled` choices reach RPC unchanged and exact status is confirmed | dialog stays open; note/choice retained | dialog stays open; no success | blank note blocked; cancel blocked during submit; spinner/disabled state visible |
| Close escalated | only supported `resolved` path is selectable and confirmed | same safe failure behavior | same unconfirmed behavior | false-alarm choice disabled with explanation |
| Save note | canonical detail contains the new note/action for exact incident | editor remains open with text | no success; text retained and retry possible | blank note and duplicate submit blocked |
| Load/retry | real list/detail renders | prior confirmed content remains with retry banner | error never appears as `ยังไม่มีข้อมูล` | stale earlier request cannot replace newer response |

Also cover wrong role, cross-school incident ID, missing/invalid session token, null active school, and no unauthorized action/audit change after rejected mutations in pgTAP when the affected RPC is changed.

## Verification commands

Run from `apps/user_app`:

```powershell
flutter analyze lib/pages/teacher_redesign_prototype/teacher_incident_inbox_page.dart lib/pages/teacher_redesign_prototype/controllers/staff_emergency_actions.dart
flutter test test/staff_emergency_actions_test.dart
flutter test <new_teacher_detail_widget_test.dart>
```

Run from the repository root when database code changes:

```powershell
npx supabase migration up
npx supabase test db supabase/tests/database/19_incident_reports.test.sql
npx supabase test db supabase/tests/database/22_emergency_events.test.sql
```

Then rerun all teacher/SOS tests together and the full Flutter suite once. Record exact passed/failed/total counts and failing test names. Do not say failures are pre-existing unless reproduced on base commit `bbb7a27` in a clean comparison worktree.

Browser acceptance must use local Supabase: login as a supported teacher fixture; open list and detail; exercise acknowledge, escalate, resolved, false alarm when permitted, failure/retry, save note, refresh, back navigation, and empty state. Confirm persistence after a full page reload. Do not create fixtures by raw runtime table inserts.

## Completion gate and report

Do not call this complete until focused tests, cumulative SOS tests, analyzer, relevant pgTAP, and browser acceptance are all recorded. If browser or DB is unavailable, stop at “code complete, acceptance pending.”

Write `docs/handoff/CLAUDE_ACCOUNT_1_TEACHER_SOS_RESULT.md` containing: base/head commit; files changed; bug and root cause; red evidence; test commands and exact counts; browser scenarios and results; database target explicitly marked local; remaining failures classified with evidence; and any work not done. Commit only owned files and push only `claude/teacher-sos-finish` after user approval.

## Suggested skills

Use the receiving environment's diagnosing-bugs skill for unexpected failures, TDD for each behavior seam, implement for scoped changes, and review against base `bbb7a27` before commit.
