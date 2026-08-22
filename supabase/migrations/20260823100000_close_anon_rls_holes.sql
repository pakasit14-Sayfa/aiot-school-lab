-- =====================================================================
-- Security Fix: Remove Insecure Anon RLS Policies, Enable RLS on 100% Tables,
-- and Establish Robust Security-Definer Multi-Tenancy Isolation
-- =====================================================================

-- 1. Helper Security Definer Functions (Fast & Bypasses RLS recursion)
create or replace function public.is_super_admin(p_uid uuid default auth.uid())
returns boolean as $$
  select exists (
    select 1 from public.users u
    left join public.user_roles ur on ur.user_id = u.id
    where u.id = p_uid and (ur.role = 'super_admin' or u.email = 'admin@aiot-school-lab.local')
  );
$$ language sql security definer stable set search_path = public;

create or replace function public.get_auth_school_id(p_uid uuid default auth.uid())
returns uuid as $$
  select school_id from public.users where id = p_uid;
$$ language sql security definer stable set search_path = public;

-- 2. Drop the 4 insecure anon bypass policies
drop policy if exists anon_select_devices on public.devices;
drop policy if exists anon_select_schools on public.schools;
drop policy if exists anon_select_sensors on public.sensor_readings;
drop policy if exists anon_select_commands on public.device_commands;

-- 3. Revoke unnecessary table grants from anon role
revoke all on public.users from anon;
revoke all on public.user_roles from anon;
revoke all on public.devices from anon;
revoke all on public.schools from anon;
revoke all on public.device_commands from anon;
revoke all on public.sensor_readings from anon;
revoke all on public.control_approval_requests from anon;
revoke all on public.device_logs from anon;

-- Ensure authenticated role retains necessary permissions
grant select, insert, update on public.users to authenticated;
grant select, insert, update on public.user_roles to authenticated;
grant select, insert, update on public.profiles to authenticated;
grant select, insert, update on public.alerts to authenticated;
grant select, insert, update on public.devices to authenticated;
grant select, insert, update on public.schools to authenticated;
grant select, insert, update on public.device_commands to authenticated;
grant select, insert, update on public.sensor_readings to authenticated;
grant select, insert, update on public.device_heartbeats to authenticated;
grant select, insert, update on public.control_approval_requests to authenticated;
grant select, insert, update on public.device_logs to authenticated;
grant select, insert, update on public.device_categories to authenticated;

-- 4. Enable RLS on 100% of tables
alter table public.users enable row level security;
alter table public.user_roles enable row level security;
alter table public.schools enable row level security;
alter table public.devices enable row level security;
alter table public.device_commands enable row level security;
alter table public.sensor_readings enable row level security;
alter table public.device_categories enable row level security;
alter table public.device_logs enable row level security;
alter table public.control_approval_requests enable row level security;

-- 5. Establish Clean Multi-Tenancy RLS Policies

-- Users
drop policy if exists super_admin_all_users on public.users;
drop policy if exists school_user_isolated_users on public.users;
create policy super_admin_all_users on public.users
  for all to authenticated
  using (public.is_super_admin(auth.uid()));
create policy school_user_isolated_users on public.users
  for select to authenticated
  using (id = auth.uid() or school_id = public.get_auth_school_id(auth.uid()));

-- User Roles
drop policy if exists super_admin_all_user_roles on public.user_roles;
drop policy if exists school_user_isolated_user_roles on public.user_roles;
create policy super_admin_all_user_roles on public.user_roles
  for all to authenticated
  using (public.is_super_admin(auth.uid()));
create policy school_user_isolated_user_roles on public.user_roles
  for select to authenticated
  using (user_id = auth.uid() or user_id in (select u.id from public.users u where u.school_id = public.get_auth_school_id(auth.uid())));

-- Schools
drop policy if exists super_admin_all_schools on public.schools;
drop policy if exists school_user_isolated_schools on public.schools;
create policy super_admin_all_schools on public.schools
  for all to authenticated
  using (public.is_super_admin(auth.uid()));
create policy school_user_isolated_schools on public.schools
  for all to authenticated
  using (id = public.get_auth_school_id(auth.uid()));

-- Devices
drop policy if exists super_admin_all_devices on public.devices;
drop policy if exists school_user_isolated_devices on public.devices;
create policy super_admin_all_devices on public.devices
  for all to authenticated
  using (public.is_super_admin(auth.uid()));
create policy school_user_isolated_devices on public.devices
  for all to authenticated
  using (school_id = public.get_auth_school_id(auth.uid()));

-- Device Commands
drop policy if exists super_admin_all_commands on public.device_commands;
drop policy if exists school_user_isolated_commands on public.device_commands;
create policy super_admin_all_commands on public.device_commands
  for all to authenticated
  using (public.is_super_admin(auth.uid()));
create policy school_user_isolated_commands on public.device_commands
  for all to authenticated
  using (device_id in (select id from public.devices where school_id = public.get_auth_school_id(auth.uid())));

-- Sensor Readings
drop policy if exists super_admin_all_sensors on public.sensor_readings;
drop policy if exists school_user_isolated_sensors on public.sensor_readings;
create policy super_admin_all_sensors on public.sensor_readings
  for all to authenticated
  using (public.is_super_admin(auth.uid()));
create policy school_user_isolated_sensors on public.sensor_readings
  for all to authenticated
  using (device_id in (select id from public.devices where school_id = public.get_auth_school_id(auth.uid())));

-- Device Categories
drop policy if exists authenticated_read_categories on public.device_categories;
drop policy if exists super_admin_write_categories on public.device_categories;
create policy authenticated_read_categories on public.device_categories
  for select to authenticated using (true);
create policy super_admin_write_categories on public.device_categories
  for all to authenticated
  using (public.is_super_admin(auth.uid()));

-- Device Logs
drop policy if exists super_admin_all_device_logs on public.device_logs;
drop policy if exists school_user_isolated_device_logs on public.device_logs;
create policy super_admin_all_device_logs on public.device_logs
  for all to authenticated
  using (public.is_super_admin(auth.uid()));
create policy school_user_isolated_device_logs on public.device_logs
  for all to authenticated
  using (school_id = public.get_auth_school_id(auth.uid()));

-- Control Approval Requests
drop policy if exists super_admin_all_control_approvals on public.control_approval_requests;
drop policy if exists school_user_isolated_control_approvals on public.control_approval_requests;
create policy super_admin_all_control_approvals on public.control_approval_requests
  for all to authenticated
  using (public.is_super_admin(auth.uid()));
create policy school_user_isolated_control_approvals on public.control_approval_requests
  for all to authenticated
  using (school_id = public.get_auth_school_id(auth.uid()));
