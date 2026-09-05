# Teacher/Student Completion Decision Map

Goal: make Teacher SOS and Student Notifications integration-ready with reproducible local evidence, cumulative regression, honest UI states, and no production writes. Base: `bbb7a27`; coordination branch: `agent/publish-current-work`.

## branch-hygiene: Establish Safe Parallel Ownership

Blocked by: none
Status: resolved
Type: Grilling

### Question

How can two Claude accounts work without overwriting each other?

### Answer

Teacher owns `claude/teacher-sos-finish`. Student continues from `7869d32` on `claude/student-notifications-finish-v2`; do not use obsolete remote candidate `424b50e`. Separate worktrees, commits, and result reports. Student alone owns local migration/DB-test execution while both sessions are active. Neither edits shared status docs; the integrator owns final docs and schema reconciliation.

## teacher-finish: Complete Teacher SOS Behavior

Blocked by: branch-hygiene
Status: open
Type: Prototype

### Question

Does every teacher SOS action persist and confirm the exact canonical incident before reporting success?

### Answer

Follow `docs/handoff/CLAUDE_ACCOUNT_1_TEACHER_SOS_TESTING.md`. Finish `_saveNote`; verify acknowledge/escalate/close, resolution type, retained input, per-target busy lock, stable errors, stale-load protection, role/school isolation, and page-level widget tests. Run focused analyzer/tests and local incident/emergency pgTAP. Deliver `CLAUDE_ACCOUNT_1_TEACHER_SOS_RESULT.md`; browser acceptance may not be claimed until actually performed.

## student-corrections: Repair Student Candidate V2

Blocked by: branch-hygiene
Status: open
Type: Prototype

### Question

Can candidate `7869d32` meet the Student brief without unverifiable claims or unnecessary churn?

### Answer

Use `docs/handoff/CLAUDE_ACCOUNT_2_STUDENT_NOTIFICATIONS_TESTING.md` and the review findings: test real parent wiring in addition to extracted widgets; cover all filters/back navigation; complete recipient/security cases; resolve the null-active-school rule explicitly against product behavior; use exact `ยังไม่มีข้อมูล`; handle modal load errors; remove unused seams and formatting-only churn; clean marked local fixtures; finish lesson/grade/error/empty browser flows; record the real commit hash. Re-run focused Flutter (current evidence 17/17) and notification pgTAP (31/31), then update the account result honestly.

## branch-reviews: Accept or Reject Each Candidate

Blocked by: teacher-finish, student-corrections
Status: open
Type: Research

### Question

Does each branch satisfy both repository standards and its assigned brief?

### Answer

Review each branch separately against its base and result report. Verify changed paths, `git diff --check`, scoped analyzer, focused tests, pgTAP counts, browser evidence, no raw table calls, no fake-success path, no leaked raw errors, no fabricated UI data, and local-only database identity. Reproduce any “pre-existing failure” on the base before accepting it. Reject the branch if evidence is prose-only or completion gates remain open.

## integration-merge: Combine Accepted Work Safely

Blocked by: branch-reviews
Status: open
Type: Prototype

### Question

Can both accepted branches merge without changing unrelated user work or behavior?

### Answer

Create an integration branch from the latest `agent/publish-current-work`. Merge Teacher first, run Teacher focused tests, then merge Student and rerun Teacher plus Student focused tests. Preserve generated plugin changes, `pubspec.lock`, `apps/admin_app/`, and stash. Resolve conflicts by behavior and ownership, never by choosing an entire side blindly. No force push.

## cumulative-regression: Prove New Work Did Not Break Old Work

Blocked by: integration-merge
Status: open
Type: Research

### Question

Do the new teacher/student flows preserve every previously verified flow?

### Answer

Run in layers: (1) Teacher SOS unit/widget tests; (2) Student notification/navigation/home tests; (3) DB `10_grades_core`, `11_assignments_core`, `19_incident_reports`, `22_emergency_events`, `35_student_learning_notifications`; (4) the five connected School Admin page suites; (5) affected Parent/shared-navigation tests; (6) full Flutter and full pgTAP once. After every new failure, compare with the pre-merge integration base. Record exact passed/failed/total counts and names; do not hide flaky or stale tests.

## browser-acceptance: Verify Real Local User Journeys

Blocked by: cumulative-regression
Status: open
Type: Prototype

### Question

Do real teacher and student interactions work after reload, not only in injected tests?

### Answer

Use local Supabase and supported RPC-created fixtures. Teacher: load/error/retry/empty, acknowledge, escalate, resolved/cancelled rules, save note, duplicate click, back and full reload. Student: assignment/lesson/grade producer, correct recipient only, filters, mark-read persistence, badge/card refresh through all three entry points, true empty account, error/retry, back and full reload. After Student acceptance, repeat Teacher smoke; after Teacher acceptance, repeat Student smoke. Any failed old scenario returns to its owning ticket.

## documentation-gate: Make Repository State Reproducible

Blocked by: cumulative-regression, browser-acceptance
Status: open
Type: Research

### Question

Can a fresh agent reproduce the accepted result from Git alone?

### Answer

Integrator regenerates `DATABASE_SCHEMA.md` from the live local catalog, then updates `HANDOFF.md`, `WORK_LOG.md`, and `task_plan.md` with final commit hashes, exact test counts, browser coverage, known failures, and remaining risk. Remove stale “not committed”/“complete” claims. Do not include secrets, runtime session tokens, local fixture IDs, or production-write claims without independently verified evidence.

## release-decision: Reach the Goal

Blocked by: documentation-gate
Status: open
Type: Grilling

### Question

Is the integrated work ready to merge into the main delivery branch?

### Answer

Ready only when both feature matrices pass, cumulative regressions are classified, local browser acceptance is complete, empty cards say `ยังไม่มีข้อมูล`, mutations confirm canonical state, security fails closed, schema/docs match reality, and the worktree contains no unintended files. Commit and push the integration branch for review. Production migration/deployment is a separate user-authorized decision and is not part of this map.

## Operational gates

- **Gate A — branch accepted:** owned diff only + focused tests + honest result report.
- **Gate B — integration accepted:** both focused suites pass after each merge.
- **Gate C — regression accepted:** prior pages retested; failures base-classified.
- **Gate D — browser accepted:** real local flows persist through reload.
- **Gate E — delivery accepted:** schema/docs regenerated, reviewed, committed, and pushed with user approval.

## Progress model

- Teacher accepted: 25%
- Student accepted: 25%
- Integration and cumulative regression: 25%
- Browser, documentation, and delivery gates: 25%

Percentages are earned only when the corresponding gate has evidence; code existing without acceptance does not earn the full block.

## Next steps

Two tickets are unblocked and may run in parallel: `teacher-finish`, `student-corrections`.

Teacher session:

```text
Read docs/handoff/TEACHER_STUDENT_COMPLETION_MAP.md and claim ticket teacher-finish. Follow docs/handoff/CLAUDE_ACCOUNT_1_TEACHER_SOS_TESTING.md. Work only on claude/teacher-sos-finish from bbb7a27; local only; commit but do not push without approval.
```

Student session:

```text
Read docs/handoff/TEACHER_STUDENT_COMPLETION_MAP.md and claim ticket student-corrections. Follow docs/handoff/CLAUDE_ACCOUNT_2_STUDENT_NOTIFICATIONS_TESTING.md and the corrections in the map. Continue claude/student-notifications-finish-v2 from 7869d32; local only; commit but do not push without approval.
```
