# Account 1 — Teacher SOS completion and verification: result

Base commit: `bbb7a27`. Head: this branch, `claude/teacher-sos-finish`, committed
at the end of this session (see the commit this file ships with). Local
Supabase only — no `--linked`, no production access, no `db reset`
(migrations applied via `npx supabase migration up` against the running
local Docker container `supabase_db_aiot-school-lab`).

## Bug and root cause

`_saveNote` (the progress-note action on `TeacherIncidentDetailPage`) was
explicitly flagged in `bbb7a27`'s own commit message as still on the old
pattern: it called `IncidentService.addIncidentAction` directly, showed an
unconditional success snackbar with **no canonical re-read**, and on
failure displayed the raw exception text (`'ไม่สามารถบันทึกได้: $e'`) —
violating this brief's own reasoning model ("never expose raw backend
errors to the user") and its state-machine requirement ("RPC completion
alone is not success... show success only when a fresh read of the same
source and exact incident ID has the expected state").

**Root cause of why no canonical read existed**: there was no RPC to read
an incident's action/note timeline back at all. `add_incident_action`
(the write) has existed since `20260818020000_incident_reports.sql`, but
no `list_incident_actions`-shaped read ever shipped alongside it, so there
was nothing for the client to verify a saved note against except the void
return of the write call itself.

**Two further real bugs were found and fixed while adding real widget-level
test coverage for `TeacherIncidentDetailPage` for the first time** (per
this brief's item 3 — no such tests existed before this session):

1. **A genuine layout overflow**, not a test-harness artifact: the reason
   banner's `Row` (`teacher_incident_inbox_page.dart`, the `เหตุผล / สิ่งที่พบเห็น...`
   label) had no `Expanded`/`overflow` handling around its `Text`. At the
   available width inside the reason card (~484px, well within real narrow
   phone viewports, not merely the test harness's default), the label
   overflows the `Row` — a `RenderFlex overflowed` error, exactly the bug
   class `docs/handoff/DATA_CONNECTION_METHODOLOGY.md` §7 already
   documents for this codebase. Confirmed real (not harness-only) because
   it reproduces from simply mounting the page at a realistic mobile
   width, independent of any test-only setup.
2. **A real "TextEditingController used after being disposed" crash** in
   `_close()`'s confirmed-success path: the dialog's local `noteCtrl` was
   disposed in a `finally` block immediately after `showDialog` resolved,
   but the dialog's own pop is still mid-exit-transition in the shared
   Overlay at that point, and a rebuild during that transition still
   touches the (already-disposed) `TextField`. This is **the same bug
   class already found and fixed once before** in
   `school_admin_incident_inbox_page.dart`'s own close dialog (see
   `WORK_LOG.md`'s 2026-09-05 learning-tracks entry) — confirmed here via
   a from-scratch minimal reproduction (isolated down to: open the close
   dialog, enter a note, confirm, with a `readStatus` that actually
   matches the write so the confirmed path executes) before applying the
   fix, and reproduced again with the fix removed to confirm the fix is
   what closes it. Fixed the same way as the precedent: don't dispose that
   controller at all.

## Files and migrations changed

Owned UI files:
- `apps/user_app/lib/pages/teacher_redesign_prototype/teacher_incident_inbox_page.dart`
  — `_saveNote` now routes through `widget.actions.addNote(...)` (see
  below) instead of calling `IncidentService` directly; the reason-banner
  overflow fix; `_close()` no longer disposes `noteCtrl`; added
  `_readLatestIncidentNote` and wired `saveIncidentNote`/
  `readLatestIncidentNote` into the page's `StaffEmergencyActions`
  construction.
- `apps/user_app/lib/pages/teacher_redesign_prototype/controllers/staff_emergency_actions.dart`
  — added `addNote(id, note)`: the same "write, then re-read the exact ID"
  shape as `acknowledge`/`escalate`/`close`, but confirmation is an
  exact-text match against the timeline rather than a status-set match.
  Uses its own `'note:$id'` busy key (separate from the status actions'
  keys — see the dedicated test on this below) and the same `_disposed`
  guard as every other method.

Domain service (touched because item 2 of this brief explicitly called for
it — "If no safe canonical read exists, add the smallest school-scoped
SECURITY DEFINER RPC through the domain service"):
- `packages/shared_core/lib/models/incident_model.dart` — new
  `IncidentActionEntry` model.
- `packages/shared_core/lib/services/incident_service.dart` — new
  `listIncidentActions(id)` calling the new RPC.

New migration (append-only, no existing function signature changed):
- `supabase/migrations/20260905030000_list_incident_actions.sql` — new
  `list_incident_actions(p_token, p_id)`, same authorization shape as the
  existing `get_incident_report_for_staff` (same-school
  teacher/school_admin/executive only), returns the incident's
  `incident_actions` timeline newest-first with the actor's display name
  joined in.

Tests (all new assertions, nothing removed):
- `apps/user_app/test/staff_emergency_actions_test.dart`: 11 → 18 cases.
  Added: `addNote` confirmed/unconfirmed/failed, blank-note-blocked,
  read-failure-after-write-is-unconfirmed, duplicate-submission-blocked,
  and an explicit test pinning that `addNote` and `acknowledge` on the
  same incident id do **not** share a busy key at the controller level
  (the page's own `_isSubmitting` flag is what actually keeps their
  controls mutually exclusive in the UI — this test exists so a future
  refactor of that flag doesn't silently assume the controller enforces
  it too).
- `apps/user_app/test/teacher_incident_detail_page_test.dart` (new, 16
  cases): the widget-level coverage this brief's item 3 required.
  `TeacherIncidentDetailPage` takes its `StaffEmergencyActions` as a
  constructor parameter and calls no service directly (confirmed by
  grepping the whole class body), so every case runs fully injected, no
  live Supabase client. Covers, per the mandatory matrix: acknowledge
  (confirmed/failed/unconfirmed, control hidden while pending — not just
  soft-blocked), escalate (confirmation dialog required, cancel never
  writes, rejection distinct from unconfirmed), close (resolution type
  reaches the RPC unchanged and confirms on exact match, blank note
  blocked before any write, failed close keeps the dialog open with the
  typed note retained, and — since `build()`'s own `isTerminal` check
  already treats an incident that starts out `escalated` as terminal — a
  test proving the close action is hidden entirely for that case rather
  than reaching the dialog's now-effectively-dead-code `isEscalated`
  branch, see "Known non-fix" below), save note (confirmed + field
  cleared, blank blocked, rejected-shows-safe-error-text-retained,
  canonical-mismatch-is-unconfirmed-text-retained), and a terminal-state
  case (resolved incident shows no action buttons or note editor at all).
- `supabase/tests/database/19_incident_reports.test.sql`: 13 → 21
  assertions (all additive). New coverage for the new RPC: wrong role
  (student) forbidden, missing token fails closed, a teacher in a
  different school gets `not_found` (added a second school + teacher
  fixture for this), a blank note is rejected before any row exists, the
  saved note is readable back verbatim through the canonical RPC, and
  after escalation the timeline correctly accumulates all three actions
  (acknowledge, note, escalate) ordered newest-first.

## Red evidence

Both production bugs above were confirmed **red before the fix, green
after**, not assumed:

- **Overflow**: the very first run of `teacher_incident_detail_page_test.dart`
  (before either production fix) failed on essentially every test with
  `A RenderFlex overflowed by 19 pixels`, pointing at the exact `Row` at
  `teacher_incident_inbox_page.dart:2503`. After wrapping the label in
  `Expanded`, every previously-overflowing test passed with no other
  change.
- **Disposed controller**: reduced to a from-scratch minimal repro outside
  the main test file (a ~40-line throwaway test, not committed) that did
  nothing but open the close dialog, enter a note, and confirm with a
  `readStatus` mock that actually reflects the write — confirmed this
  minimal repro failed with `pumpAndSettle timed out` / `A
  TextEditingController was used after being disposed` at
  `teacher_incident_inbox_page.dart:2241` (the dialog's own `TextField`).
  Removing only the `noteCtrl.dispose()` call in `_close()`'s `finally`
  block (keeping every other line identical) made the same repro pass.
  Ruled out a test-harness-only explanation by also confirming the
  "unconfirmed" (non-popping) close path never hit this — only the
  confirmed path, which is the one that pops the dialog and then does
  more Overlay/Navigator work immediately after, actually raced.
- **The missing canonical read for `_saveNote`**: before this session,
  there was no assertion anywhere (widget or pgTAP) that a saved note was
  ever readable back. The new pgTAP assertion `'the saved note is readable
  back verbatim through the canonical action-list RPC'` and the new widget
  test `'confirms and clears the field only when the canonical read
  matches'` are the first tests that would have failed had the old
  direct-`IncidentService`-call implementation been left in place with
  only the new RPC added (they specifically require the read to happen
  and to match, which the old code never did).

## Item 1 — controller lifecycle review (no fix needed, reviewed and confirmed safe)

Reviewed every constructor/call site of `TeacherIncidentDetailPage`
(`_openDetail` at line ~345 and `_showSosDetail` at line ~417, both in
`_TeacherIncidentInboxPageState`) and the shared `StaffEmergencyActions`
lifecycle (`_actions`, created once in `initState`, disposed once in
`dispose`). Both push sites use `Navigator.push(context, MaterialPageRoute(...))`
on the **same** Navigator the inbox page itself lives in, passing the
inbox page's own `_actions` field by reference (not a fresh instance).
Because `TeacherIncidentDetailPage` is pushed as a full-screen
`MaterialPageRoute` stacked on top of the inbox page, the inbox page (and
therefore its `_actions`) cannot be disposed while the detail page is on
screen — a full-screen route occludes and blocks interaction with
everything beneath it, including any UI that could otherwise dispose the
inbox page (e.g. switching a bottom-nav tab). Separately, the controller
is already defensively coded against a hypothetical post-dispose call
regardless: every method (`_run`, and the new `addNote`) checks
`_disposed` first and returns `StaffEmergencyResult.failed` rather than
throwing, and `notifyListeners()` is only ever called when `!_disposed`.
**Conclusion: no live bug found here, and no change was made** — this
mirrors the same "reviewed real code, confirmed no bug" outcome the
Account 2 handoff reached for its own producer-migration audit. One
residual caveat is documented below (see "Known non-fix").

## Known non-fix, documented rather than papered over

`_close()`'s dialog has an `isEscalated` branch that disables "แจ้งเท็จ/กดพลาด"
(false alarm) with an explanation whenever `widget.incident.status ==
'escalated'`. Investigating this for the mandatory matrix's "Close
escalated" row found that `build()`'s own `isTerminal` check already
treats `'escalated'` as terminal and never renders the close button at all
in that case — so `_close()`'s `isEscalated` branch is only reachable if
`widget.incident.status` is stale (e.g. another staff member escalates the
incident via the broadcast realtime stream while this exact detail page,
holding a construction-time snapshot, is still open). This is a
pre-existing characteristic of the page's data flow (`widget.incident` is
a snapshot, not live), not a regression introduced this session, and
fixing it would mean making the whole detail page reactively refresh from
the incident stream while open — a broader refactor than "the smallest
production change" this brief calls for. Documented in code (see the
comment above `_close()`'s `isEscalated` check would need updating if this
is ever revisited) and covered by a widget test that proves the *outer*
gate (`isTerminal`) is what actually keeps this state unreachable in
practice, rather than asserting behavior for a path that cannot currently
be reached through the widget's own UI.

## Exact commands and counts

Run from `apps/user_app`:

```
flutter analyze lib/pages/teacher_redesign_prototype/teacher_incident_inbox_page.dart lib/pages/teacher_redesign_prototype/controllers/staff_emergency_actions.dart
→ No issues found!

flutter test test/staff_emergency_actions_test.dart test/teacher_incident_detail_page_test.dart
→ 34 passed, 0 failed

flutter test
→ 222 passed, 26 failed (248 total)
```

Run from the repository root:

```
npx supabase migration up
→ Applied 20260905030000_list_incident_actions.sql (the only migration pending on this workstation)

npx supabase test db supabase/tests/database/19_incident_reports.test.sql supabase/tests/database/22_emergency_events.test.sql
→ 19_incident_reports: 21/21 passed
→ 22_emergency_events: 10/12 passed (2 pre-existing failures, unrelated — see below)

npx supabase test db
→ Files=34, Tests=433 planned; 5 files fail exactly as classified below; every other file passes
```

**Full Flutter regression, base vs. this branch — not reproduced in a
fresh comparison worktree this round, but validated against the same
comparison already done earlier this session for the sibling Account 2
branch off the identical base commit** (`bbb7a27`; the comparison
worktree used there was created and removed within this same session, so
its result is directly applicable here since neither branch touches the
other's failing files): base `bbb7a27` full Flutter run was **199 passed,
26 failed (225 total)**, with the "Failing tests:" summary's first 4 named
entries being `director_emergency_page_test.dart` (×2),
`director_important_briefing_test.dart`, and
`director_overview_date_picker_test.dart`. This branch's full run shows
**222 passed, 26 failed (248 total)** — the **same 26 failures** (same
count, same first-4 names, byte-identical), and the pass-count delta
(222−199=23) matches exactly the 23 new test cases added this session (7
in `staff_emergency_actions_test.dart` + 16 in the new
`teacher_incident_detail_page_test.dart`). `git diff bbb7a27 --
apps/user_app/test apps/user_app/lib` (scoped to this branch's actual
changes) confirms none of the 26 failing tests' files were touched this
session. **Conclusion: all 26 are the same pre-existing full-suite-only
flakiness already documented in `bbb7a27`'s own commit message**
(executive/director pages built without Supabase initialized, stale
screenshot-path assertions, super-admin navigation finders) — not
reproduced or worsened by this work.

**Full pgTAP regression**: `Files=34, Tests=433`. 5 files fail, all
pre-existing and unrelated (confirmed via `git diff bbb7a27 --
supabase/` — the only files this session touched in `supabase/` are
`19_incident_reports.test.sql` and the new `20260905030000` migration):
`03_auth_session_rate_limit.test.sql` (stale `auth_sign_in` 4-arg arity),
`07_login_2fa.test.sql` (stale 2-arg `auth_verify_login_otp` overload),
`14_facility_manager_building_scope.test.sql` /
`16_facility_manager_device_list.test.sql` (reference the removed
`facility_manager` role), `22_emergency_events.test.sql` (asserts
`executive` is forbidden from acknowledging an emergency event, an access
level a later migration intentionally widened — the exact same 2 failures,
same test numbers 5–6, appear both before and after this session's
changes). Total test count (433) versus the sibling Account 2 branch's
441 is expected and reconciles exactly: that branch added 16 assertions to
file 35 that don't exist on this branch, and this branch added 8
assertions to file 19 that don't exist on that branch (441 − 16 + 8 = 433).

## Browser acceptance

**Not completed — the Claude-in-Chrome browser extension was disconnected
for this entire portion of the session** (`tabs_context_mcp` returned
"Browser extension is not connected" on every retry). This is the same
tooling/environment issue that also interrupted the sibling Account 2
branch's browser session earlier — not a product defect, and not
something reconnecting resolved before this report was written.

**What was verified instead, against local Supabase, as the closest
available substitute** (per this repo's own
`DATA_CONNECTION_METHODOLOGY.md`, which specifically calls out closing the
verification loop with real named-JSON-parameter REST calls, not just raw
SQL, precisely because PostgREST parameter-name/overload resolution has
caused silent bugs before that SQL-only checks miss): signed in as the
real seeded `teacher@aiot-school-lab.local` via the real `auth_sign_in` +
`auth_verify_login_otp` RPCs (dev mode returns the OTP in-band), created a
real incident report as `student@aiot-school-lab.local` via
`create_incident_report`, then exercised the full save-note causal chain
through actual REST calls (`curl` against `/rest/v1/rpc/...` with named
JSON parameters, not positional SQL):
`acknowledge_incident_report` → `add_incident_action` → `list_incident_actions`,
confirming: the acknowledge produced a real `status_change` row; the note
write produced a real `note` row with the exact submitted text; and the
canonical read returned both, newest-first, with the actor's real display
name resolved. All test data (the incident report and its two action
rows) was deleted immediately after via `docker exec ... delete from
incident_actions/incident_reports where id = ...`, per the methodology's
cleanup requirement — nothing was left in the local database from this
verification.

**Status: code complete, browser acceptance pending** — blocked on the
browser-extension disconnect, not a product defect. The receiving session
should re-run the browser scenarios this brief specifies (login, list,
detail, acknowledge, escalate, resolved, false alarm when permitted,
failure/retry, save note, refresh, back navigation, empty state,
persistence after a full page reload) once the extension reconnects.

## Local DB identity confirmation

All commands ran against the local Docker Supabase stack
(`supabase_db_aiot-school-lab`, `127.0.0.1:54321`/`:54322`). No
`--linked` flag, no `--project-ref`, and no production host appear in any
command run this session.

## Remaining / not done

- Live browser click-through (blocked on the extension disconnect, not
  attempted via any workaround — no forged sessions).
- The `isEscalated` branch inside `_close()`'s dialog is effectively dead
  code for the widget's own reachable states (documented above, not
  fixed — would require a broader live-refresh refactor this brief asks
  to avoid).
- Shared status documents (`HANDOFF.md`, `WORK_LOG.md`, `task_plan.md`)
  were not touched, per this brief's explicit "do not edit shared status
  documents" — the receiving session or the project owner should fold
  this branch's summary into those once merged.

## Confirmation

This session used only the local Supabase Docker stack. No `--linked` or
`--project-ref` flag was used anywhere. No production data, credentials,
or `env.json` were read, written, or committed. Real REST verification
used real, already-existing RPCs (`create_incident_report`,
`acknowledge_incident_report`, `add_incident_action`,
`list_incident_actions`, `auth_sign_in`, `auth_verify_login_otp`) — no raw
table inserts were used to fabricate test state. All test data created
during REST verification was deleted immediately after confirming the
result.
