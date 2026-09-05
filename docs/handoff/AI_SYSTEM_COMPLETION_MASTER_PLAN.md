# AIoT School Lab — AI System Completion Master Plan

Purpose: one compact control document for planning, delegating, reviewing, merging, and proving the six-role app. Detailed task instructions remain in linked briefs; this file owns sequence, decisions, and acceptance gates.

## readiness-baseline: Evidence-Based Starting Point

Blocked by: none
Status: resolved
Type: Research

### Question

How ready is each role before the next execution cycle?

### Answer

These are planning estimates, not release claims:

| Role | Verified readiness | Primary gap |
|---|---:|---|
| Parent | 85–90% | final shared regression, mobile/live-environment acceptance |
| Teacher | 60–70% | `_saveNote`, page-level SOS tests, complete browser acceptance |
| Student | 60–70% | candidate V2 corrections, integration, remaining browser/security matrix |
| Executive | 50–60% | remaining mock data and unstable/unclassified page tests |
| School Admin | 25% | only 5/20 pages completed under the cumulative connection pass |
| Super Admin | 50–60% | no full page-by-page data audit; navigation/full-suite failures remain |

Overall verified readiness is approximately 55–60%. Percent is earned by evidence gates, not by page count or visual completeness alone.

## reasoning-loop: How Every Agent Must Think

Blocked by: none
Status: resolved
Type: Grilling

### Question

What reasoning process prevents fake completion and repeated regressions?

### Answer

Use this loop for every card, action, and page:

1. **Observe:** reproduce the current UI and capture the exact incorrect behavior.
2. **Trace:** follow `route → page → controller/service → RPC → latest migration → table` and read the whole relevant file.
3. **Define truth:** state the canonical persisted result, authorized actors, school/user scope, empty state, error state, and duplicate-action behavior.
4. **Prove red:** add a failing test for the intended defect. Fix the harness if it fails for setup, timer, overflow, stale finder, or missing Supabase initialization instead.
5. **Design the smallest seam:** keep domain logic behind one service/controller interface; inject only dependencies that production and committed tests consume.
6. **Implement:** make the smallest scoped change; append migrations rather than editing applied history.
7. **Confirm canonical state:** after a write, reload the same entity and exact ID before showing success. Distinguish rejected from unconfirmed.
8. **Regress cumulatively:** rerun the changed page, every previously connected page, affected shared roles, and security tests.
9. **Accept in browser:** use supported local RPC-created fixtures; verify back navigation and full reload persistence.
10. **Record honestly:** exact commands/counts, target environment, remaining gaps, commit, and cleanup. Never promote prose-only evidence.

Any failure returns to step 1. An agent may not skip to documentation or percentage updates while an earlier gate is red.

## architecture-rules: Design Boundaries

Blocked by: reasoning-loop
Status: resolved
Type: Grilling

### Question

What design must all fixes preserve?

### Answer

- Custom `sessions` token, never substitute Supabase Auth for the main app.
- RLS deny-all; pages never access tables directly. Use scoped SECURITY DEFINER RPCs through domain services.
- UI state distinguishes loading, confirmed data, genuine empty (`ยังไม่มีข้อมูล`), retryable error, submitting, rejected, and unconfirmed.
- No demo/sample fallback that can be mistaken for real data; no raw backend error text.
- Per-target mutation locks prevent duplicate writes without freezing unrelated rows.
- Stale async responses cannot replace newer canonical state; mounted/disposed lifecycle is tested.
- A shared label/badge and its content use the same named truth condition.
- File uploads use signed URLs and access-assertion RPCs.
- Migrations are append-only with unique timestamps, explicit grants/revokes, audit behavior, tenant tests, and schema regeneration.
- Avoid broad rewrites, unused constructor seams, formatting churn, and giant controllers/interfaces.

## agent-orchestration: How Agents Are Called and Controlled

Blocked by: reasoning-loop, architecture-rules
Status: resolved
Type: Grilling

### Question

How should multiple AI accounts work quickly without corrupting the result?

### Answer

The primary/integrator is the sole owner of this map, shared status docs, final schema reconciliation, merge order, and readiness percentage. Worker agents receive one bounded ticket each.

Before dispatch, the integrator records: ticket, base commit, branch, owned paths, forbidden paths, local-only environment, test matrix, expected result report, and whether commit/push is authorized. Each agent uses a separate worktree and branch. Two agents may run Flutter work concurrently; only one owns migration/DB tests at a time. No two agents edit the same production file or shared status document.

Required worker output:

- one scoped commit;
- account-specific result report;
- red evidence and root cause;
- exact analyzer/test/browser commands and counts;
- DB target and fixture cleanup statement;
- remaining work and blockers;
- no push, merge, production write, force operation, or scope expansion without explicit authority.

After return, never trust the summary alone. The integrator fetches the branch without merging, confirms the base and changed paths, reruns focused tests, reviews Standards and Spec independently, and rejects incomplete or unsupported claims. Accepted branches merge one at a time, with cumulative regression after each merge.

Agent invocation template:

```text
Read CLAUDE.md, docs/handoff/DATA_CONNECTION_METHODOLOGY.md, and docs/handoff/AI_SYSTEM_COMPLETION_MASTER_PLAN.md. Work ticket <slug> from base <commit> on branch <branch>. Own only <paths>; do not touch <forbidden paths>. Local Supabase only. Follow the ticket test matrix and reasoning-loop. Write <result report>, commit owned files, and stop before push unless authorized. Do not claim completion without every gate's evidence.
```

## teacher-student-program: Raise Teacher and Student to 90–95%

Blocked by: agent-orchestration
Status: in-progress
Type: Prototype

### Question

Can Teacher SOS and Student Notifications pass complete local acceptance and merge cleanly?

### Answer

Canonical execution map: `docs/handoff/TEACHER_STUDENT_COMPLETION_MAP.md`. Teacher uses `CLAUDE_ACCOUNT_1_TEACHER_SOS_TESTING.md`; Student corrects `claude/student-notifications-finish-v2` using `CLAUDE_ACCOUNT_2_STUDENT_NOTIFICATIONS_TESTING.md`. Do not merge obsolete candidate `424b50e`. Finish worker reviews, merge Teacher then Student, rerun both after each merge, complete local Chrome acceptance, regenerate schema, and update shared docs through the integrator.

## school-admin-program: Complete Pages 6–20

Blocked by: teacher-student-program
Status: open
Type: Prototype

### Question

Can School Admin move from 5/20 verified pages to all 20 without breaking earlier pages?

### Answer

Use `task_plan.md` order, beginning with Permissions. Work one page per commit. Every page must cover loading, data, exact empty, error/retry, mutation write→canonical refetch, failure/no fake success, role/tenant isolation, analyzer, pgTAP/REST where applicable, desktop/mobile Chrome, and every earlier School Admin test. Split later tickets into batches only after file ownership proves non-overlapping.

## executive-program: Remove Remaining Executive Uncertainty

Blocked by: teacher-student-program
Status: open
Type: Research

### Question

Which live Executive pages still contain mocks, unsafe actions, or unstable tests?

### Answer

Audit every route from `DirectorNavigationShell`, including whole-file searches for `DirectorMockData`, fake fallbacks, local-only mutations, inline realtime streams, and direct table access. First establish a clean per-file test baseline; then connect/fix page-by-page with canonical reads and role-scoped RPCs. Do not classify full-suite failures as pre-existing until reproduced on the fixed base.

## super-admin-program: Verify All Eight Live Menus

Blocked by: school-admin-program, executive-program
Status: open
Type: Research

### Question

Do all eight live Super Admin menu items use real scoped data and survive navigation/regression?

### Answer

Audit the live `SuperAdminNavigationShell`, not the obsolete dashboard. Fix missing/ambiguous navigation finders, then verify each menu's data source, writes, global-versus-school scope, audit trail, empty/error states, and browser reload. Super Admin widening must be explicit per RPC; never infer access from its power level.

## parent-regression: Preserve the Strongest Role

Blocked by: teacher-student-program, school-admin-program, executive-program, super-admin-program
Status: open
Type: Research

### Question

Did shared changes preserve all seven Parent pages and multi-child selection?

### Answer

Rerun the complete Parent suite and browser smoke for all seven pages, child switching both directions, leave flow, genuine empty child, wrong-child/cross-school isolation, and mobile layout. Parent requires regression, not a rewrite, unless evidence finds a new defect.

## integrated-release: Reach 90% Verified Readiness

Blocked by: parent-regression
Status: open
Type: Grilling

### Question

Is the six-role integration ready for a release candidate?

### Answer

Require scoped and full analyzer/build, all targeted pgTAP/REST, cumulative widget suites, six-role Chrome smoke, security/tenant audit, regenerated schema, clean fixture inventory, updated HANDOFF/WORK_LOG/task_plan, reviewed diff, clean intended worktree, and explicit known-failure ledger. Merge/push the release candidate only after approval. Production deployment and migration are separate user-authorized tickets.

## Program sequence

1. Current parallel pair: Teacher finish + Student corrections.
2. Integrator review and Teacher→Student merge with reciprocal regression.
3. Next parallel pair: School Admin pages 6–12 + Executive audit/fixes.
4. Next parallel pair: School Admin pages 13–20 + Super Admin audit/fixes.
5. Cross-role integration, Parent regression, six-role browser acceptance.
6. Schema/docs/security review and release decision.

## Global completion gates

- **G1 Truth:** no undisclosed fake data or fake success.
- **G2 Persistence:** every enabled write survives canonical reload.
- **G3 Security:** missing/invalid/wrong-role/cross-tenant access fails closed without side effects.
- **G4 Regression:** every newly completed page reruns all earlier relevant pages.
- **G5 Browser:** real local user journeys pass on desktop and required mobile widths.
- **G6 Reproducibility:** schema, docs, commit hashes, test counts, and cleanup match reality.
- **G7 Delivery:** reviewed integration branch; production remains separately authorized.

## Next steps

Currently active: `teacher-student-program`. Its two worker tickets are `teacher-finish` and `student-corrections` in `TEACHER_STUDENT_COMPLETION_MAP.md`. Do not start later role programs until the integrator resolves this ticket or explicitly changes dependency order.
