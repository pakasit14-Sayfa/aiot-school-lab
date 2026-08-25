-- ============================================================================
-- Super Admin Redesign — Phase 1 Migration
-- RPCs for Schools Management and Device Control under Custom Session Auth
-- ============================================================================

-- 1. List schools for Super Admin with aggregated metrics
create or replace function public.list_schools_for_super_admin(p_token text)
returns table (
  id uuid,
  school_code text,
  name text,
  province text,
  admin_email text,
  package_name text,
  status text,
  license_expires_at timestamptz,
  max_users integer,
  max_devices integer,
  created_at timestamptz,
  updated_at timestamptz,
  users_count integer,
  devices_total integer,
  devices_online integer,
  buildings_count integer,
  rooms_count integer,
  alerts_count integer,
  last_sync_at timestamptz
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
begin
  select * into v_actor from get_session_actor(p_token);
  if v_actor.user_id is null or v_actor.role != 'super_admin' then
    raise exception 'forbidden: super_admin role required';
  end if;

  return query
  with user_counts as (
    select ur.school_id as s_id, count(distinct ur.user_id)::integer as total_users
    from user_roles ur
    join users u on u.id = ur.user_id
    where u.status = 'active'
      and ur.school_id is not null
    group by ur.school_id
  ),
  device_stats as (
    select
      d.school_id as s_id,
      count(*)::integer as dev_total,
      count(*) filter (where d.status = 'online')::integer as dev_online,
      count(distinct nullif(trim(d.building), ''))::integer as bldg_total,
      count(distinct nullif(trim(d.room), ''))::integer as room_total,
      max(d.updated_at) as max_sync
    from devices d
    group by d.school_id
  ),
  alert_stats as (
    select
      d.school_id as s_id,
      count(*)::integer as active_alerts
    from sensor_alerts sa
    join devices d on d.id = sa.device_id
    where sa.status != 'resolved'
    group by d.school_id
  )
  select
    s.id,
    s.school_code::text,
    s.name::text,
    coalesce(s.province, '-')::text,
    coalesce(s.admin_email, '-')::text,
    coalesce(s.package_name, 'Basic')::text,
    s.status::text,
    s.license_expires_at,
    coalesce(s.max_users, 100),
    coalesce(s.max_devices, 100),
    s.created_at,
    s.updated_at,
    coalesce(uc.total_users, 0),
    coalesce(ds.dev_total, 0),
    coalesce(ds.dev_online, 0),
    coalesce(ds.bldg_total, 0),
    coalesce(ds.room_total, 0),
    coalesce(als.active_alerts, 0),
    ds.max_sync
  from schools s
  left join user_counts uc on uc.s_id = s.id
  left join device_stats ds on ds.s_id = s.id
  left join alert_stats als on als.s_id = s.id
  order by s.created_at desc;
end;
$$;

revoke all on function public.list_schools_for_super_admin(text) from public;
grant execute on function public.list_schools_for_super_admin(text) to anon, authenticated;

-- 2. Create school for Super Admin
create or replace function public.create_school_for_super_admin(
  p_token text,
  p_name text,
  p_province text default null,
  p_admin_email text default null,
  p_package_name text default 'Standard',
  p_max_users integer default 100,
  p_max_devices integer default 100,
  p_license_expires_at timestamptz default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_school_id uuid;
  v_package_id uuid;
  v_school_code text;
  v_attempt int := 0;
begin
  select * into v_actor from get_session_actor(p_token);
  if v_actor.user_id is null or v_actor.role != 'super_admin' then
    raise exception 'forbidden: super_admin role required';
  end if;

  if trim(coalesce(p_name, '')) = '' then
    raise exception 'school_name_required';
  end if;

  -- Resolve default package
  select id into v_package_id from packages limit 1;
  if v_package_id is null then
    insert into packages (name, license_type, max_users)
    values ('Standard Package', 'perpetual', 500)
    returning id into v_package_id;
  end if;

  -- Generate unique school code
  loop
    v_attempt := v_attempt + 1;
    v_school_code := 'SCH-' || to_char(now(), 'YYYYMM') || '-' || lpad(floor(random() * 9000 + 1000)::text, 4, '0');
    begin
      insert into schools (
        package_id,
        name,
        school_code,
        province,
        admin_email,
        package_name,
        status,
        max_users,
        max_devices,
        license_expires_at,
        created_at,
        updated_at
      ) values (
        v_package_id,
        trim(p_name),
        v_school_code,
        p_province,
        p_admin_email,
        coalesce(p_package_name, 'Standard'),
        'active',
        coalesce(p_max_users, 100),
        coalesce(p_max_devices, 100),
        coalesce(p_license_expires_at, now() + interval '365 days'),
        now(),
        now()
      )
      returning id into v_school_id;
      exit;
    exception when unique_violation then
      if v_attempt >= 5 then
        raise exception 'failed_to_generate_unique_school_code';
      end if;
    end;
  end loop;

  insert into audit_logs (school_id, user_id, acted_role, action, entity_type, entity_id, details)
  values (
    v_school_id,
    v_actor.user_id,
    v_actor.role,
    'school.create',
    'school',
    v_school_id::text,
    jsonb_build_object('name', p_name, 'school_code', v_school_code)
  );

  return jsonb_build_object(
    'id', v_school_id,
    'school_code', v_school_code,
    'name', p_name,
    'status', 'active'
  );
end;
$$;

revoke all on function public.create_school_for_super_admin(text, text, text, text, text, integer, integer, timestamptz) from public;
grant execute on function public.create_school_for_super_admin(text, text, text, text, text, integer, integer, timestamptz) to anon, authenticated;

-- 3. Update school for Super Admin
create or replace function public.update_school_for_super_admin(
  p_token text,
  p_school_id uuid,
  p_name text,
  p_province text default null,
  p_admin_email text default null,
  p_package_name text default null,
  p_max_users integer default null,
  p_max_devices integer default null,
  p_license_expires_at timestamptz default null
)
returns boolean
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
begin
  select * into v_actor from get_session_actor(p_token);
  if v_actor.user_id is null or v_actor.role != 'super_admin' then
    raise exception 'forbidden: super_admin role required';
  end if;

  update schools
  set
    name = coalesce(nullif(trim(p_name), ''), name),
    province = coalesce(p_province, province),
    admin_email = coalesce(p_admin_email, admin_email),
    package_name = coalesce(p_package_name, package_name),
    max_users = coalesce(p_max_users, max_users),
    max_devices = coalesce(p_max_devices, max_devices),
    license_expires_at = coalesce(p_license_expires_at, license_expires_at),
    updated_at = now()
  where id = p_school_id;

  if not found then
    raise exception 'school_not_found';
  end if;

  insert into audit_logs (school_id, user_id, acted_role, action, entity_type, entity_id, details)
  values (
    p_school_id,
    v_actor.user_id,
    v_actor.role,
    'school.update',
    'school',
    p_school_id::text,
    jsonb_build_object('name', p_name, 'admin_email', p_admin_email)
  );

  return true;
end;
$$;

revoke all on function public.update_school_for_super_admin(text, uuid, text, text, text, text, integer, integer, timestamptz) from public;
grant execute on function public.update_school_for_super_admin(text, uuid, text, text, text, text, integer, integer, timestamptz) to anon, authenticated;

-- 4. Set school status for Super Admin
create or replace function public.set_school_status_for_super_admin(
  p_token text,
  p_school_id uuid,
  p_status text
)
returns boolean
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
begin
  select * into v_actor from get_session_actor(p_token);
  if v_actor.user_id is null or v_actor.role != 'super_admin' then
    raise exception 'forbidden: super_admin role required';
  end if;

  update schools
  set
    status = p_status::user_status,
    updated_at = now()
  where id = p_school_id;

  if not found then
    raise exception 'school_not_found';
  end if;

  insert into audit_logs (school_id, user_id, acted_role, action, entity_type, entity_id, details)
  values (
    p_school_id,
    v_actor.user_id,
    v_actor.role,
    'school.set_status',
    'school',
    p_school_id::text,
    jsonb_build_object('new_status', p_status)
  );

  return true;
end;
$$;

revoke all on function public.set_school_status_for_super_admin(text, uuid, text) from public;
grant execute on function public.set_school_status_for_super_admin(text, uuid, text) to anon, authenticated;

-- 5. List Device Control Data for Super Admin (Aggregated Overview)
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

  -- 2. Devices
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
      'updated_at', d.updated_at
    ) order by d.updated_at desc nulls last
  ), '[]'::jsonb)
  into v_devices
  from devices d
  left join schools s on s.id = d.school_id;

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

-- 6. Create Control Approval Request
create or replace function public.create_control_approval_request(
  p_token text,
  p_device_id uuid,
  p_command text,
  p_reason text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_device record;
  v_request_id uuid;
begin
  select * into v_actor from get_session_actor(p_token);
  if v_actor.user_id is null then
    raise exception 'invalid_or_expired_session';
  end if;

  select id, school_id, name into v_device from devices where id = p_device_id;
  if v_device.id is null then
    raise exception 'device_not_found';
  end if;

  -- School Admin can only request for their own school
  if v_actor.role != 'super_admin' and (v_actor.school_id is null or v_actor.school_id != v_device.school_id) then
    raise exception 'forbidden: cross-school request not permitted';
  end if;

  insert into control_approval_requests (
    school_id,
    device_id,
    command,
    requested_by,
    status,
    notes,
    created_at
  ) values (
    v_device.school_id,
    p_device_id,
    p_command,
    v_actor.user_id,
    'pending',
    p_reason,
    now()
  )
  returning id into v_request_id;

  insert into audit_logs (school_id, user_id, acted_role, action, entity_type, entity_id, details)
  values (
    v_device.school_id,
    v_actor.user_id,
    v_actor.role,
    'device.request_control_approval',
    'control_approval_request',
    v_request_id::text,
    jsonb_build_object('command', p_command, 'device_id', p_device_id, 'reason', p_reason)
  );

  return jsonb_build_object(
    'id', v_request_id,
    'status', 'pending',
    'device_id', p_device_id,
    'command', p_command
  );
end;
$$;

revoke all on function public.create_control_approval_request(text, uuid, text, text) from public;
grant execute on function public.create_control_approval_request(text, uuid, text, text) to anon, authenticated;

-- 7. Decide Control Approval Request (Approve or Reject)
create or replace function public.decide_control_approval_request(
  p_token text,
  p_request_id uuid,
  p_approved boolean,
  p_reason text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_req record;
  v_new_status text;
begin
  select * into v_actor from get_session_actor(p_token);
  if v_actor.user_id is null or v_actor.role != 'super_admin' then
    raise exception 'forbidden: super_admin role required to decide approval requests';
  end if;

  select * into v_req from control_approval_requests where id = p_request_id;
  if v_req.id is null then
    raise exception 'request_not_found';
  end if;

  if v_req.status != 'pending' then
    raise exception 'request_already_decided: status is %', v_req.status;
  end if;

  v_new_status := case when p_approved then 'approved' else 'rejected' end;

  update control_approval_requests
  set
    status = v_new_status,
    reviewed_by = v_actor.user_id,
    reviewed_at = now(),
    notes = coalesce(p_reason, notes)
  where id = p_request_id;

  -- If approved, dispatch real command via queue_device_command
  if p_approved and v_req.device_id is not null then
    perform queue_device_command(
      p_token,
      v_req.device_id,
      jsonb_build_object('action', v_req.command)
    );
  end if;

  insert into audit_logs (school_id, user_id, acted_role, action, entity_type, entity_id, details)
  values (
    v_req.school_id,
    v_actor.user_id,
    v_actor.role,
    'device.decide_control_approval',
    'control_approval_request',
    p_request_id::text,
    jsonb_build_object('decision', v_new_status, 'reason', p_reason)
  );

  return jsonb_build_object(
    'id', p_request_id,
    'status', v_new_status,
    'reviewed_by', v_actor.user_id,
    'reviewed_at', now()
  );
end;
$$;

revoke all on function public.decide_control_approval_request(text, uuid, boolean, text) from public;
grant execute on function public.decide_control_approval_request(text, uuid, boolean, text) to anon, authenticated;
