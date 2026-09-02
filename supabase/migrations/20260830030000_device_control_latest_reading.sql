-- Migration: 20260830030000_device_control_latest_reading.sql
-- Description: RedTeam finding — the Super Admin Device Control page
-- (super_admin_device_control_page.dart) hardcoded `reading: '-'` for
-- every device because list_device_control_data_for_super_admin
-- (20260826090000_super_admin_redesign_phase1.sql) never returned any
-- telemetry, even though real per-device readings already exist in
-- sensor_readings (device_id, metric, value, ts — populated by the live
-- sensor_ingest / gateway-sensor-ingest paths). This migration adds each
-- device's single most recent sensor_readings row (any metric) to the
-- devices array so the page can show a real value instead of a
-- placeholder. Only additive fields (reading_metric/reading_value/
-- reading_ts) — every previously-returned key is unchanged, so the other
-- three pages that also call this RPC (super_admin_scan_page.dart,
-- super_admin_device_test_page.dart, super_admin_devices_page.dart) are
-- unaffected.

create or replace function public.list_device_control_data_for_super_admin(p_token text)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_schools jsonb;
  v_devices jsonb;
  v_commands jsonb;
  v_approvals jsonb;
  v_permissions jsonb;
  v_logs jsonb;
begin
  select * into v_actor from get_session_actor(p_token);
  if v_actor.user_id is null or v_actor.role != 'super_admin' then
    raise exception 'forbidden: super_admin role required';
  end if;

  -- 1. Schools
  select coalesce(jsonb_agg(
    jsonb_build_object(
      'database_id', s.id,
      'school_code', s.school_code,
      'name', s.name,
      'province', coalesce(s.province, 'ไม่ระบุจังหวัด'),
      'package_name', coalesce(s.package_name, 'Basic'),
      'status', s.status,
      'total_devices', coalesce(d_stats.total, 0),
      'online_devices', coalesce(d_stats.online_cnt, 0),
      'open_alerts', coalesce(a_stats.open_cnt, 0)
    ) order by s.name
  ), '[]'::jsonb)
  into v_schools
  from schools s
  left join (
    select school_id, count(*) as total, count(*) filter (where status = 'online') as online_cnt
    from devices group by school_id
  ) d_stats on d_stats.school_id = s.id
  left join (
    select d.school_id, count(*) as open_cnt
    from sensor_alerts sa
    join devices d on d.id = sa.device_id
    where sa.status != 'resolved'
    group by d.school_id
  ) a_stats on a_stats.school_id = s.id;

  -- 2. Devices — now includes each device's latest real sensor reading
  -- (reading_metric/reading_value/reading_ts), sourced from sensor_readings
  -- instead of leaving the client to fabricate a placeholder.
  select coalesce(jsonb_agg(
    jsonb_build_object(
      'database_id', d.id,
      'school_id', d.school_id,
      'school_name', coalesce(s.name, '-'),
      'category_code', coalesce(d.category_code, d.type::text),
      'device_code', coalesce(d.device_code, d.serial_no, d.id::text),
      'name', d.name,
      'building', coalesce(d.building, '-'),
      'room', coalesce(d.room, '-'),
      'status', d.status,
      'online', (d.status = 'online'),
      'metadata', coalesce(d.metadata, '{}'::jsonb),
      'updated_at', d.updated_at,
      'reading_metric', latest.metric,
      'reading_value', latest.value,
      'reading_ts', latest.ts
    ) order by d.updated_at desc nulls last
  ), '[]'::jsonb)
  into v_devices
  from devices d
  left join schools s on s.id = d.school_id
  left join lateral (
    select sr.metric::text as metric, sr.value, sr.ts
    from sensor_readings sr
    where sr.device_id = d.id
    order by sr.ts desc
    limit 1
  ) latest on true;

  -- 3. Commands
  select coalesce(jsonb_agg(
    jsonb_build_object(
      'id', dc.id,
      'device_id', dc.device_id,
      'command', dc.command,
      'created_by', dc.created_by,
      'created_at', dc.created_at,
      'delivered_at', dc.delivered_at
    ) order by dc.created_at desc
  ), '[]'::jsonb)
  into v_commands
  from (
    select * from device_commands order by created_at desc limit 100
  ) dc;

  -- 4. Approvals
  select coalesce(jsonb_agg(
    jsonb_build_object(
      'id', car.id,
      'school_id', car.school_id,
      'school_name', coalesce(s.name, '-'),
      'device_id', car.device_id,
      'device_name', coalesce(d.name, '-'),
      'command', car.command,
      'requested_by', car.requested_by,
      'requester_name', coalesce(trim(u_req.first_name || ' ' || u_req.last_name), u_req.email, 'ผู้ใช้งาน'),
      'status', car.status,
      'reviewed_by', car.reviewed_by,
      'reviewer_name', coalesce(trim(u_rev.first_name || ' ' || u_rev.last_name), u_rev.email),
      'reviewed_at', car.reviewed_at,
      'notes', car.notes,
      'created_at', car.created_at
    ) order by car.created_at desc
  ), '[]'::jsonb)
  into v_approvals
  from (
    select * from control_approval_requests order by created_at desc limit 100
  ) car
  left join schools s on s.id = car.school_id
  left join devices d on d.id = car.device_id
  left join users u_req on u_req.id = car.requested_by
  left join users u_rev on u_rev.id = car.reviewed_by;

  -- 5. Permissions
  select coalesce(jsonb_agg(
    jsonb_build_object(
      'email', u.email,
      'full_name', trim(u.first_name || ' ' || u.last_name),
      'role', ur.role::text,
      'school_id', ur.school_id,
      'school_name', coalesce(s.name, 'ทุกโรงเรียน')
    ) order by ur.role::text, u.email
  ), '[]'::jsonb)
  into v_permissions
  from user_roles ur
  join users u on u.id = ur.user_id
  left join schools s on s.id = ur.school_id
  where u.status = 'active';

  -- 6. Logs
  select coalesce(jsonb_agg(
    jsonb_build_object(
      'id', dl.id,
      'device_id', dl.device_id,
      'school_id', dl.school_id,
      'event_type', dl.event_type,
      'message', dl.message,
      'metadata', dl.metadata,
      'created_at', dl.created_at
    ) order by dl.created_at desc
  ), '[]'::jsonb)
  into v_logs
  from (
    select * from device_logs order by created_at desc limit 20
  ) dl;

  return jsonb_build_object(
    'schools', v_schools,
    'devices', v_devices,
    'commands', v_commands,
    'approvals', v_approvals,
    'permissions', v_permissions,
    'logs', v_logs,
    'current_user_id', v_actor.user_id,
    'current_role', v_actor.role::text,
    'current_school_id', v_actor.school_id
  );
end;
$$;

revoke all on function public.list_device_control_data_for_super_admin(text) from public;
grant execute on function public.list_device_control_data_for_super_admin(text) to anon, authenticated;
