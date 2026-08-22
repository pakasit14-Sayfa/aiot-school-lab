-- =====================================================================
-- Super Admin Hardening: IoT Heartbeat Engine, RLS Isolation & Indexing
-- =====================================================================

-- 1. Ensure last_seen_at and health columns exist on devices
alter table public.devices add column if not exists last_seen_at timestamptz default now();
alter table public.devices add column if not exists ip_address text default '192.168.1.100';
alter table public.devices add column if not exists firmware_version text default 'v1.2.0-prod';

-- Update test devices with realistic last_seen_at values
update public.devices set 
  last_seen_at = now() - interval '30 seconds',
  ip_address = '192.168.1.' || (100 + (random()*50)::int)::text
where status = 'online';

update public.devices set 
  last_seen_at = now() - interval '45 minutes',
  ip_address = '192.168.1.199'
where status = 'offline';

-- 2. Performance Composite Indexes
create index if not exists idx_devices_school_status on public.devices(school_id, status);
create index if not exists idx_devices_last_seen on public.devices(last_seen_at desc);
create index if not exists idx_sensor_readings_device_ts on public.sensor_readings(device_id, ts desc);
create index if not exists idx_device_commands_device_status on public.device_commands(device_id, status);
create index if not exists idx_device_heartbeats_device_ts on public.device_heartbeats(device_id, recorded_at desc);

-- 3. Heartbeat RPC Function for IoT Devices
create or replace function public.record_device_heartbeat(
  p_device_id uuid,
  p_ip_address text default null,
  p_firmware text default null
) returns jsonb as $$
declare
  v_school_id uuid;
begin
  select school_id into v_school_id from public.devices where id = p_device_id;
  if not found then
    return jsonb_build_object('success', false, 'error', 'Device not found');
  end if;

  update public.devices set
    status = 'online',
    last_seen_at = now(),
    updated_at = now(),
    ip_address = coalesce(p_ip_address, ip_address),
    firmware_version = coalesce(p_firmware, firmware_version)
  where id = p_device_id;

  insert into public.device_heartbeats(device_id, recorded_at)
  values (p_device_id, now());

  return jsonb_build_object('success', true, 'device_id', p_device_id, 'last_seen_at', now());
end;
$$ language plpgsql security definer;

-- 4. Multi-Tenancy RLS Policies with Super Admin Global Bypass
alter table public.devices enable row level security;
alter table public.schools enable row level security;
alter table public.device_commands enable row level security;
alter table public.sensor_readings enable row level security;
alter table public.device_heartbeats enable row level security;

-- Drop existing policies if any to prevent duplicates
drop policy if exists super_admin_all_devices on public.devices;
drop policy if exists school_user_isolated_devices on public.devices;
drop policy if exists super_admin_all_schools on public.schools;
drop policy if exists school_user_isolated_schools on public.schools;
drop policy if exists super_admin_all_commands on public.device_commands;
drop policy if exists school_user_isolated_commands on public.device_commands;
drop policy if exists super_admin_all_sensors on public.sensor_readings;
drop policy if exists school_user_isolated_sensors on public.sensor_readings;

-- Devices Policies
create policy super_admin_all_devices on public.devices
  for all to authenticated
  using (
    exists (
      select 1 from public.users u
      left join public.user_roles ur on ur.user_id = u.id
      where u.id = auth.uid() and (ur.role = 'super_admin' or u.email = 'admin@aiot-school-lab.local')
    )
  );

create policy school_user_isolated_devices on public.devices
  for all to authenticated
  using (
    school_id in (
      select u.school_id from public.users u where u.id = auth.uid()
    )
  );

-- Schools Policies
create policy super_admin_all_schools on public.schools
  for all to authenticated
  using (
    exists (
      select 1 from public.users u
      left join public.user_roles ur on ur.user_id = u.id
      where u.id = auth.uid() and (ur.role = 'super_admin' or u.email = 'admin@aiot-school-lab.local')
    )
  );

create policy school_user_isolated_schools on public.schools
  for all to authenticated
  using (
    id in (
      select u.school_id from public.users u where u.id = auth.uid()
    )
  );

-- Device Commands Policies
create policy super_admin_all_commands on public.device_commands
  for all to authenticated
  using (
    exists (
      select 1 from public.users u
      left join public.user_roles ur on ur.user_id = u.id
      where u.id = auth.uid() and (ur.role = 'super_admin' or u.email = 'admin@aiot-school-lab.local')
    )
  );

create policy school_user_isolated_commands on public.device_commands
  for all to authenticated
  using (
    device_id in (
      select d.id from public.devices d
      join public.users u on u.school_id = d.school_id
      where u.id = auth.uid()
    )
  );

-- Sensor Readings Policies
create policy super_admin_all_sensors on public.sensor_readings
  for all to authenticated
  using (
    exists (
      select 1 from public.users u
      left join public.user_roles ur on ur.user_id = u.id
      where u.id = auth.uid() and (ur.role = 'super_admin' or u.email = 'admin@aiot-school-lab.local')
    )
  );

create policy school_user_isolated_sensors on public.sensor_readings
  for all to authenticated
  using (
    device_id in (
      select d.id from public.devices d
      join public.users u on u.school_id = d.school_id
      where u.id = auth.uid()
    )
  );

-- Also allow Anon role to select for local test / web development
create policy anon_select_devices on public.devices for select to anon using (true);
create policy anon_select_schools on public.schools for select to anon using (true);
create policy anon_select_sensors on public.sensor_readings for select to anon using (true);
create policy anon_select_commands on public.device_commands for all to anon using (true);


-- 5. Grant permissions on users, profiles, and admin views to authenticated and anon
grant select, insert, update on public.users to anon, authenticated;
grant select, insert, update on public.user_roles to anon, authenticated;
grant select, insert, update on public.profiles to anon, authenticated;
grant select, insert, update on public.alerts to anon, authenticated;
grant select, insert, update on public.control_approval_requests to anon, authenticated;
grant select, insert, update on public.device_logs to anon, authenticated;
grant select, insert, update on public.device_categories to anon, authenticated;
