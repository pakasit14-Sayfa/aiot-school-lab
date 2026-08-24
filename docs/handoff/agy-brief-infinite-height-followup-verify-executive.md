# Follow-up: re-verify the "9 files / 16 points already safe" claim — I couldn't confirm it myself

Your last report said `parent_learning_page.dart` was fixed with
`IntrinsicHeight` (3 spots) and the other 9 files/16 `CrossAxisAlignment.stretch`
occurrences were audited and confirmed already safe (bounded height via
`SizedBox`/`IntrinsicHeight`/safe `Column(stretch)`).

I independently verified the `parent_learning_page.dart` fix — real
login, real click, real screenshot, page renders correctly now. Confirmed.

I could **not** verify the "other 9 files are safe" half of the claim.
I tried to log into `executive@aiot-school-lab.local` in a real browser
to click through `director_overview_page.dart` (the highest-risk file —
7 of the 16 occurrences are in this one file) and hit a persistent
`rate_limited` response from `auth_sign_in()` even immediately after
`truncate auth_login_rate_limits, auth_login_ip_rate_limits;` — the
tables were empty (`select * from auth_login_rate_limits` → 0 rows) but
calling `auth_sign_in()` directly still returned `auth_state = 'rate_limited'`.
Didn't chase it further since it's a side investigation, not the main
task — but it means the executive-side files in your audit are currently
**unverified by me**, not confirmed-safe by me. Please check.

## What to do

1. If you know why `auth_sign_in()` returns `rate_limited` with an empty
   rate-limit table (something not keyed by `email_hash`/`ip_hash`
   alone?), fix or note it — this blocks testing the executive account
   at all right now, independent of the layout bug work.
2. Re-verify the 7 occurrences in `director_overview_page.dart` plus the
   remaining ones in `director_meetings_page.dart`, `director_settings_page.dart`,
   `director_learning_page.dart`, `director_environment_page.dart`
   the same way the original bug was found: `flutter run -d web-server`
   in **debug mode** (not `flutter build web` — release mode swallows
   the "BoxConstraints forces an infinite height" assertion silently,
   that's exactly why this stayed hidden the first time), real login,
   click into every tab, capture the actual console output.
3. If they're genuinely all safe, that's a fine outcome — just want the
   claim backed by an actual driven screenshot/console log per file this
   time, not a code-read audit. This exact class of claim ("audited,
   confirmed safe") is the one that missed the original bug in
   `parent_learning_page.dart`, so a code-only re-audit isn't enough
   evidence on its own.

The 4 `parent_redesign_prototype` files (`parent_dashboard_page.dart`,
`parent_attendance_page.dart`, `parent_settings_page.dart`,
`parent_academic_calendar_page.dart`) don't have this login-blocking
problem — parent login worked fine when I tested. If you get to those
before resolving the executive rate-limit issue, verify those first and
report separately.
