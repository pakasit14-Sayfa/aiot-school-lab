-- thresholds/school_settings/sensor_alerts have RLS enabled but zero policies
-- and zero grants to `authenticated` — meaning aiot_dev_dashboard's
-- settings_page.dart, school_settings_page.dart, and school_alerts_page.dart
-- (which all call .from() on these tables) are completely broken at runtime
-- for a real logged-in user, even reading their own school's data.
-- Confirmed live: schooladmin@ got "permission denied for table thresholds"
-- (etc.) on all three, 403, no grant at all.
--
-- Also worth noting while fixing this: settings_page.dart's threshold-save
-- code does `.update({...}).eq('metric', 'pm25')` with **no school_id
-- filter at all** in the client code — the school-scoped RLS policy below
-- is what actually prevents that update from touching another school's
-- threshold row, not the app code. Don't relax this policy without fixing
-- that client-side gap first.

grant select, insert, update on public.thresholds to authenticated;
grant select, insert, update on public.school_settings to authenticated;
grant select, update on public.sensor_alerts to authenticated;

create policy super_admin_all_thresholds on public.thresholds
  for all to authenticated
  using (public.is_super_admin());
create policy school_user_isolated_thresholds on public.thresholds
  for all to authenticated
  using (school_id = public.get_auth_school_id())
  with check (school_id = public.get_auth_school_id());

create policy super_admin_all_school_settings on public.school_settings
  for all to authenticated
  using (public.is_super_admin());
create policy school_user_isolated_school_settings on public.school_settings
  for all to authenticated
  using (school_id = public.get_auth_school_id())
  with check (school_id = public.get_auth_school_id());

create policy super_admin_all_sensor_alerts on public.sensor_alerts
  for all to authenticated
  using (public.is_super_admin());
create policy school_user_isolated_sensor_alerts on public.sensor_alerts
  for all to authenticated
  using (device_id in (select id from public.devices where school_id = public.get_auth_school_id()));
