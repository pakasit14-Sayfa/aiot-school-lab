-- CRITICAL: every "school_user_isolated_*" RLS policy added for
-- aiot_dev_dashboard (devices, schools, thresholds, school_settings,
-- device_commands, device_logs, control_approval_requests, sensor_readings,
-- users) only checked `school_id = get_auth_school_id()` — never the
-- caller's role. `for all` means this covers SELECT/INSERT/UPDATE/DELETE
-- in one condition. Any authenticated user belonging to a school — a plain
-- student, no special role at all — had the same write access as
-- school_admin on all of these.
--
-- Confirmed live: student@ successfully changed a real device's status via
-- a direct PATCH to /rest/v1/devices, completely bypassing
-- queue_device_command's role check (reverted immediately after
-- confirming). Also confirmed: student@ could read `password_hash` for
-- every user in the school via `.from('users').select('email,password_hash')`
-- — every seeded test account's bcrypt hash, fully exposed.
--
-- Also found while auditing grants: `control_approval_requests` and
-- `device_logs` had TRUNCATE granted to `authenticated`. RLS policies do
-- NOT apply to TRUNCATE in Postgres — any authenticated user, any role,
-- could have wiped either table entirely for every school. Revoked below,
-- not exercised live (too destructive to "confirm" by actually doing it).
--
-- Fix, table by table: split each blanket `for all` policy into a SELECT
-- policy scoped by school membership (kept broad — viewing is generally
-- fine for dashboard use) and separate INSERT/UPDATE/DELETE policies that
-- additionally require has_role('school_admin') (or 'technician' where the
-- existing UI/RPC surface already treats that role as privileged). Plus:
-- users.password_hash gets a column-level revoke (no non-owner role should
-- ever read it directly — only get_session_actor()/auth_sign_in() touch it,
-- both SECURITY DEFINER and thus unaffected by this), and sensor_readings
-- loses INSERT/UPDATE entirely for authenticated — telemetry is written by
-- the device ingest path (service_role), never by a logged-in dashboard user.

-- =====================================================================
-- 1. users.password_hash — column-level revoke, most severe finding
-- =====================================================================
revoke select on public.users from authenticated;
grant select (id, school_id, email, student_code, first_name, last_name, status, created_by, created_at, building)
  on public.users to authenticated;
-- (password_hash and must_change_password intentionally excluded)

-- =====================================================================
-- 2. devices — write bypass of queue_device_command's role check
-- =====================================================================
drop policy if exists school_user_isolated_devices on public.devices;

create policy school_read_devices on public.devices
  for select to authenticated
  using (school_id = public.get_auth_school_id());

create policy school_admin_insert_devices on public.devices
  for insert to authenticated
  with check (
    school_id = public.get_auth_school_id()
    and (public.has_role('school_admin') or public.has_role('technician'))
  );

create policy school_admin_update_devices on public.devices
  for update to authenticated
  using (
    school_id = public.get_auth_school_id()
    and (public.has_role('school_admin') or public.has_role('technician'))
  )
  with check (
    school_id = public.get_auth_school_id()
    and (public.has_role('school_admin') or public.has_role('technician'))
  );

create policy school_admin_delete_devices on public.devices
  for delete to authenticated
  using (
    school_id = public.get_auth_school_id()
    and (public.has_role('school_admin') or public.has_role('technician'))
  );

-- =====================================================================
-- 3. schools — editing school info is admin-only
-- =====================================================================
drop policy if exists school_user_isolated_schools on public.schools;

create policy school_read_schools on public.schools
  for select to authenticated
  using (id = public.get_auth_school_id());

create policy school_admin_update_schools on public.schools
  for update to authenticated
  using (id = public.get_auth_school_id() and public.has_role('school_admin'))
  with check (id = public.get_auth_school_id() and public.has_role('school_admin'));

-- (no insert/delete policy for regular members — creating/deleting a
-- school row is a super_admin-only action, already covered by
-- super_admin_all_schools)

-- =====================================================================
-- 4. thresholds — sensor alert limits, admin-only to change
-- =====================================================================
drop policy if exists school_user_isolated_thresholds on public.thresholds;

create policy school_read_thresholds on public.thresholds
  for select to authenticated
  using (school_id = public.get_auth_school_id());

create policy school_admin_write_thresholds on public.thresholds
  for all to authenticated
  using (school_id = public.get_auth_school_id() and public.has_role('school_admin'))
  with check (school_id = public.get_auth_school_id() and public.has_role('school_admin'));

-- =====================================================================
-- 5. school_settings — utility rates + PDPA consent, admin-only
-- =====================================================================
drop policy if exists school_user_isolated_school_settings on public.school_settings;

create policy school_read_school_settings on public.school_settings
  for select to authenticated
  using (school_id = public.get_auth_school_id());

create policy school_admin_write_school_settings on public.school_settings
  for all to authenticated
  using (school_id = public.get_auth_school_id() and public.has_role('school_admin'))
  with check (school_id = public.get_auth_school_id() and public.has_role('school_admin'));

-- =====================================================================
-- 6. device_commands — issuing a command is what queue_device_command
--    already gates by role (+ building, for facility_manager); direct
--    table access must not be looser than that. facility_manager is
--    intentionally left out here — they go through the RPC, which does
--    the building-scope check RLS can't easily replicate on this table.
-- =====================================================================
drop policy if exists school_user_isolated_commands on public.device_commands;

create policy school_read_commands on public.device_commands
  for select to authenticated
  using (
    device_id in (select id from public.devices where school_id = public.get_auth_school_id())
  );

create policy school_admin_insert_commands on public.device_commands
  for insert to authenticated
  with check (
    device_id in (select id from public.devices where school_id = public.get_auth_school_id())
    and (public.has_role('school_admin') or public.has_role('technician'))
  );

create policy school_admin_update_commands on public.device_commands
  for update to authenticated
  using (
    device_id in (select id from public.devices where school_id = public.get_auth_school_id())
    and (public.has_role('school_admin') or public.has_role('technician'))
  )
  with check (
    device_id in (select id from public.devices where school_id = public.get_auth_school_id())
    and (public.has_role('school_admin') or public.has_role('technician'))
  );

-- =====================================================================
-- 7. device_logs — revoke TRUNCATE (bypasses RLS entirely), then split
-- =====================================================================
revoke truncate on public.device_logs from authenticated;

drop policy if exists school_user_isolated_device_logs on public.device_logs;

create policy school_read_device_logs on public.device_logs
  for select to authenticated
  using (school_id = public.get_auth_school_id());

create policy school_admin_write_device_logs on public.device_logs
  for insert to authenticated
  with check (
    school_id = public.get_auth_school_id()
    and (public.has_role('school_admin') or public.has_role('technician') or public.has_role('facility_manager'))
  );

create policy school_admin_update_device_logs on public.device_logs
  for update to authenticated
  using (school_id = public.get_auth_school_id() and public.has_role('school_admin'))
  with check (school_id = public.get_auth_school_id() and public.has_role('school_admin'));

-- =====================================================================
-- 8. control_approval_requests — revoke TRUNCATE, split request vs approve
-- =====================================================================
revoke truncate on public.control_approval_requests from authenticated;

drop policy if exists school_user_isolated_control_approvals on public.control_approval_requests;

create policy school_read_control_approvals on public.control_approval_requests
  for select to authenticated
  using (school_id = public.get_auth_school_id());

create policy school_request_control_approvals on public.control_approval_requests
  for insert to authenticated
  with check (
    school_id = public.get_auth_school_id()
    and (
      public.has_role('school_admin') or public.has_role('technician')
      or public.has_role('facility_manager') or public.has_role('teacher')
    )
  );

create policy school_admin_decide_control_approvals on public.control_approval_requests
  for update to authenticated
  using (school_id = public.get_auth_school_id() and public.has_role('school_admin'))
  with check (school_id = public.get_auth_school_id() and public.has_role('school_admin'));

-- =====================================================================
-- 9. sensor_readings — telemetry, never written by a dashboard user
-- =====================================================================
revoke insert, update on public.sensor_readings from authenticated;

drop policy if exists school_user_isolated_sensors on public.sensor_readings;

create policy school_read_sensor_readings on public.sensor_readings
  for select to authenticated
  using (
    device_id in (select id from public.devices where school_id = public.get_auth_school_id())
  );
