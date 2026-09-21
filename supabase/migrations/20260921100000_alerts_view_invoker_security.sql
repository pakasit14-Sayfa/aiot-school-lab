-- alerts is a compatibility view for Supabase Auth clients. Its postgres
-- owner previously bypassed sensor_alerts/devices RLS for every authenticated
-- reader. Preserve the view shape and grants, but enforce the caller's existing
-- table policies (school-scoped readers and the super-admin exception).
-- The main app's p_token SECURITY DEFINER RPCs remain unchanged.
alter view public.alerts set (security_invoker = true);
