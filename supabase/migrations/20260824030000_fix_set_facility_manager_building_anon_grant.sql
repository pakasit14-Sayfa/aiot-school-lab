-- set_facility_manager_building (20260814000000_facility_manager_building_scope.sql)
-- only granted execute to `authenticated`, missing `anon` — but my_first_app's
-- client never establishes a Supabase Auth session at all (it uses a custom
-- p_token/sessions-table system, always connecting as the `anon` PostgREST
-- role; see CLAUDE.md hard rule 1). Every sibling RPC in this file
-- (list_devices_in_my_building, etc.) grants to `anon, authenticated` both.
--
-- Net effect: nobody — not even a legitimate school_admin using the real
-- app — could ever call this RPC. Found while testing whether a
-- facility_manager could self-escalate their own building assignment
-- (they can't — role check is fine); the sanity check with a real
-- school_admin session failed too, with "permission denied for function",
-- which is what surfaced this as a functional bug rather than the RLS/role
-- error a blocked caller would normally get.

grant execute on function public.set_facility_manager_building(text, uuid, text) to anon;
