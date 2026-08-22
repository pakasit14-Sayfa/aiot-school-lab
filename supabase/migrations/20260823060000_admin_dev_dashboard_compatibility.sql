-- =====================================================================
-- Compatibility Migration for AIoT Dev Dashboard & School Admin Portal
-- =====================================================================

-- 1. Create Compatibility View for `profiles`
create or replace view profiles as
select 
  u.id,
  u.email,
  trim(coalesce(u.first_name, '') || ' ' || coalesce(u.last_name, '')) as full_name,
  ur.role::text as role,
  (u.status = 'active') as is_active,
  u.school_id,
  u.created_at,
  u.created_at as updated_at
from users u
left join user_roles ur on ur.user_id = u.id;

-- 2. Create device_categories table if not exists
create table if not exists device_categories (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  code text unique,
  description text,
  icon text,
  created_at timestamptz default now()
);

-- Seed basic device categories if empty
insert into device_categories (name, code, description, icon)
values 
  ('เซนเซอร์วัดคุณภาพอากาศ (PM2.5 / CO2)', 'AIR_QUALITY', 'อุปกรณ์ตรวจวัดสิ่งแวดล้อมและคุณภาพอากาศ', 'air_rounded'),
  ('เซนเซอร์วัดการใช้พลังงานและน้ำ', 'ENERGY_WATER', 'มิเตอร์ไฟฟ้าอัจฉริยะและมาตรวัดน้ำ', 'bolt_rounded'),
  ('รีเลย์และสวิตช์ควบคุม', 'RELAY_CONTROL', 'ชุดควบคุมไฟ พัดลม และอุปกรณ์ไฟฟ้า', 'power_settings_new_rounded'),
  ('ชุดฝึก AIoT และ Microcontroller', 'AIOT_KIT', 'บอร์ด Maker Feather AIoT S3 และ Mini PC', 'memory_rounded')
on conflict (code) do nothing;

-- 3. Create device_logs table
create table if not exists device_logs (
  id uuid primary key default gen_random_uuid(),
  device_id uuid references devices(id) on delete set null,
  school_id uuid references schools(id) on delete cascade,
  event_type text not null,
  message text,
  metadata jsonb default '{}'::jsonb,
  created_at timestamptz default now()
);

-- 4. Create control_approval_requests table
create table if not exists control_approval_requests (
  id uuid primary key default gen_random_uuid(),
  school_id uuid references schools(id) on delete cascade,
  device_id uuid references devices(id) on delete cascade,
  command text not null,
  requested_by uuid references users(id) on delete cascade,
  status text not null default 'pending',
  reviewed_by uuid references users(id) on delete set null,
  reviewed_at timestamptz,
  notes text,
  created_at timestamptz default now()
);

-- 5. Create Compatibility View for `alerts`
create or replace view alerts as
select 
  sa.id,
  d.school_id,
  sa.device_id,
  'sensor'::text as alert_type,
  sa.metric::text as title,
  ('แจ้งเตือนค่า ' || sa.metric::text || ' เกินเกณฑ์: ' || sa.value::text) as message,
  'warning'::text as severity,
  sa.status::text as status,
  sa.triggered_at as created_at
from sensor_alerts sa
left join devices d on d.id = sa.device_id;

-- Grants for views and tables
grant select on profiles to anon, authenticated;
grant select, insert, update on device_categories to anon, authenticated;
grant select, insert on device_logs to anon, authenticated;
grant select, insert, update on control_approval_requests to anon, authenticated;
grant select on alerts to anon, authenticated;

-- 6. Add school and device metadata columns
alter table public.schools add column if not exists province text default 'กรุงเทพมหานคร';
alter table public.schools add column if not exists admin_email text default 'schooladmin@aiot-school-lab.local';
alter table public.schools add column if not exists package_name text default 'Pro Package';
alter table public.schools add column if not exists license_expires_at timestamptz default (now() + interval '365 days');
alter table public.schools add column if not exists max_users int default 500;
alter table public.schools add column if not exists max_devices int default 100;
alter table public.schools add column if not exists updated_at timestamptz default now();

alter table public.devices add column if not exists category_code text;
alter table public.devices add column if not exists device_code text;
alter table public.devices add column if not exists building text;
alter table public.devices add column if not exists room text;
alter table public.devices add column if not exists metadata jsonb default '{}'::jsonb;
alter table public.devices add column if not exists updated_at timestamptz default now();

grant select, insert, update on public.devices to anon, authenticated;
grant select, insert, update on public.schools to anon, authenticated;
grant select, insert, update on public.device_commands to anon, authenticated;
grant select, insert, update on public.sensor_readings to anon, authenticated;
grant select, insert, update on public.device_heartbeats to anon, authenticated;
