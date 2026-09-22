# School creation and dialog recovery — 2026-09-22

## Verified production result

The authorized browser test created **โรงเรียนดิลิออน ทดสอบ** once:

- School code: `SCH-202609-9990`
- ID: `39a4d974-d125-4eab-96c2-1a801126790c`
- Created at: `2026-09-22 03:00:50.383333+00`
- Basic, active, maximum 30 users and 30 devices.
- Province `ข้อมูลทดสอบ` and contact `school-admin@dilion-test.invalid` are deliberate test placeholders, not real contact information.
- Canonical database read found one creation audit and zero users. Creating the school did not create an administrator account or send an invitation.
- After reloading, the browser displayed this school alongside `TEST01`.

## Cause and repair

After the successful write, the browser showed `_dependents.isEmpty` and its console reported a disposed `TextEditingController`. Do not retry creation to recover from this screen: the write already succeeded.

`showDialog` completes when popped, before its reverse transition unmounts the form's TextFields. The caller disposed all six controllers at that point. A focused field could rebuild while its controller was already disposed, producing the subsequent framework assertions.

The form now uses an explicit `DialogRoute`, preserving the root navigator and captured inherited themes, and waits for `route.completed` before disposing its controllers. The same lifecycle applies to create, edit, and cancel. No timeout or artificial delay is used.

Two regression tests exercise focused form submission and cancellation through the closing animation. The original code failed with `A TextEditingController was used after being disposed`; the repaired school-page suite passes all eight tests.

## Regression results

- `apps/user_app`: 923 passed, 8 existing screenshot-test failures (Windows lacks the hard-coded macOS output directory).
- `packages/shared_core`: 70 passed, no failures.
- `packages/shared_ui`: 16 passed, 1 existing ListTile/DecoratedBox assertion failure.
- Analyze: user_app 188 existing issues (7 warnings, 181 info, 0 errors); shared_core clean; shared_ui 4 existing info diagnostics.
- No increase over the pre-change failure counts. No database schema changes were needed.

## Live-browser verification limitation

The original creation and subsequent canonical/list verification were completed through the visible browser. After applying this fix, the local app server was rebuilt and returned HTTP 200. However, agy's Chrome tools timed out consecutively while waiting for the app, reading console messages, and attempting a fresh navigation (10:13–10:16 local time). The alternate computer-use channel exposed no browsers.

Consequently, post-fix live Cancel/Close verification is **not confirmed**. The passing automated regression is not a substitute for this remaining manual/browser check. No second school was submitted during verification. The local server is left running on port 8085 for continuation.

## Remaining scope

This is a dialog lifecycle fix, not a declaration that the whole school page meets every Definition of Done item. Administrator provisioning and real contact details remain separate work. The existing create/update reload path still needs a dedicated review of canonical-result validation and user-facing error handling.
