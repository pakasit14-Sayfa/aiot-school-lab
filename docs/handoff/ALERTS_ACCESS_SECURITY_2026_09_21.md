# Alerts view access correction — 2026-09-21

## Verified problem and change

Production project `smqoknnftgjyhrnzugar` exposed `public.alerts` as a
postgres-owned view without `security_invoker`. Authenticated readers bypassed
the existing school policies on its underlying `sensor_alerts` and `devices`.
The new regression reproduced seven failures out of 18 assertions before the
change: school A/B, an unmapped identity and missing identity could read alerts
outside their allowed scope.

Migration `20260921100000_alerts_view_invoker_security.sql` sets only
`security_invoker = true`. It was applied to production atomically with its
migration ledger entry. View definition and grants remained unchanged.
Post-deployment definition MD5: `3eca690af8f936ededb3a44be61502b1`.
No existing alert data was deleted or modified by the migration.

## Actual access model (live database, not inferred from migrations)

The blanket description that every table has deny-all RLS does **not** apply
to these two tables in production. Both have RLS enabled and authenticated
school-scoped policies plus a super-admin exception. Keep those policies: this
database also serves Supabase Auth clients.

- Authenticated Supabase identities use existing `get_auth_school_id()` and
  `is_super_admin()` policies when selecting the view.
- School identities see their own school's alerts. Unmapped/missing identities
  see no rows. Super admins retain cross-school access.
- `anon` has no direct SELECT grant on the view. The real REST endpoint returned
  HTTP 401 / PostgreSQL `42501`, permission denied for view alerts.
- The main application uses opaque session tokens with `list_school_alerts`,
  `acknowledge_sensor_alert_for_school_admin`,
  `resolve_sensor_alert_for_school_admin`, and `acknowledge_all_school_alerts`.
  These SECURITY DEFINER RPCs were not changed.

An `UNRESTRICTED` label on a view alone is not a verification result. A view does
not have its own table RLS policies; verify invoker options, underlying policies
and actual access. The dashboard/advisor label has not been checked after refresh.

## Validation

- `72_alerts_view_invoker.test.sql`: 18 assertions; seven failed before the fix,
  all passed with the candidate inside a rolled-back transaction, and all passed
  again against the deployed definition. Every fixture transaction rolled back.
- Covers two-school isolation (including an explicit foreign-school filter),
  unmapped/missing identity, both super-admin access paths, anonymous denial,
  invalid opaque token, main-app read, and acknowledgement followed by canonical
  read. It does not exhaustively retest every alert mutation.
- Full Flutter regression: shared_core 70 passed; shared_ui 16 passed / one
  existing failure; user_app 921 passed / eight existing failures. Counts match
  the pre-change baseline at `e822a0f`; no Dart source changed.
- Analyze: shared_core clean; shared_ui four existing informational issues;
  user_app 188 existing issues (seven warnings, 181 informational), no errors.
- Browser clicking was unavailable in this environment. The separate Dev
  Dashboard source was not available in the tracked checkout, so its UI behavior
  is not verified. The database test emulates its Supabase Auth access model.

## agy trial and supervision

Requested model: `gemini-3.8-flash-high`; conversation
`f69d6416-a92c-4211-8d96-33b8f713b33b`. Read-only assignment allowed six specified
main-app source files, with no shell, edits, database, browser or delegation.
Observed 12 `view_file` calls on those six files and no source changes. A report
was emitted, but the final result was ERROR with a provider HTTP 500, despite
process exit code zero. Do not count that as a clean successful run.

The supervisor checked the report against source and the live database. RPC
references were correct within the six-file scope. A realtime subscription to
`table: 'alerts'` in super_admin_device_control_page is not a direct SELECT and
does not prove realtime on the view works. agy did not verify Dev Dashboard.
Keep agy at bounded read-only level and split subsequent assignments into smaller
file sets; do not expand privileges based on this run.

## Remaining scope

Verify both application UIs when browser access is available. This ticket does
not address other views, all security-advisor findings, or overall database CPU
load. Do not revert to owner-executed view access as a routine rollback: it would
reopen the reproduced cross-school disclosure.
