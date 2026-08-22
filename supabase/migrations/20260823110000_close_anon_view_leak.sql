-- 20260823100000_close_anon_rls_holes.sql revoked anon's grants on the
-- underlying tables (users, devices, schools, ...) but never touched the
-- `profiles`/`alerts` VIEWS defined in 20260823060000_admin_dev_dashboard_compatibility.sql.
-- Views run with the view owner's privileges by default in Postgres, not
-- the querying role's — so they bypass the underlying tables' RLS
-- entirely regardless of how locked-down `users`/`sensor_alerts` are.
--
-- Confirmed still exploitable after the "fix" migration via real
-- unauthenticated curl: GET /rest/v1/profiles returned every user's
-- email/name/role/school_id with just the public anon key, no login.
-- `alerts` has the identical structural exposure (anon had SELECT +
-- INSERT + UPDATE on it) but reads empty right now only because
-- sensor_alerts has 0 rows — not because it's actually blocked.

revoke all on public.profiles from anon;
revoke all on public.alerts from anon;

-- authenticated (aiot_dev_dashboard's real logged-in users) keeps access —
-- not touching that grant, matches what 20260823100000 did for every
-- other table.
