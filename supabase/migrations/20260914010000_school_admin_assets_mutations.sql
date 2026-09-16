-- School Admin: คำสั่งเขียนที่หน้าแอดมินโรงเรียนขาดอยู่ (2026-09-14)
--
-- ก่อนหน้านี้หน้าเหล่านี้มีปุ่ม "ยังไม่เปิดใช้งาน" เพราะไม่มี RPC รองรับ:
--   · อาคาร/ห้อง: แก้ไข ลบ กำหนดผู้รับผิดชอบอาคาร (มีแค่ import batch สร้าง)
--   · อุปกรณ์: แก้ไขข้อมูล (register_device สร้างได้ แต่แก้ไม่ได้)
--   · การแจ้งเตือน: รับทราบทั้งหมด (มีแค่ทีละรายการ)
--   · ปีการศึกษา/ภาคเรียน: สร้างไม่ได้เลยจากแอป — มาจาก seed เท่านั้น ทั้งที่
--     ทุกรายวิชาต้องผูกกับ term
-- ทุกตัวเป็น SECURITY DEFINER + get_session_actor + จำกัด school_admin/super_admin
-- + ขอบเขตโรงเรียนตัวเอง + audit_logs เหมือน RPC อื่นของเลนนี้

-- ── อาคาร ──────────────────────────────────────────────────────────────

create or replace function update_school_building(
  p_token text,
  p_building_id uuid,
  p_name text,
  p_code text,
  p_floors int default null,
  p_note text default null
)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_building buildings%rowtype;
  v_name text := trim(coalesce(p_name, ''));
  v_code text := trim(coalesce(p_code, ''));
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('school_admin', 'super_admin') then
    raise exception 'forbidden';
  end if;

  select * into v_building from buildings where id = p_building_id for update;
  if not found then raise exception 'building_not_found'; end if;
  if v_actor.role <> 'super_admin'
     and v_building.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;

  if v_name = '' or v_code = '' then raise exception 'missing_required_field'; end if;
  if p_floors is not null and p_floors < 1 then raise exception 'invalid_floors'; end if;
  if exists (
    select 1 from buildings
    where school_id = v_building.school_id and code = v_code and id <> p_building_id
  ) then
    raise exception 'duplicate_code';
  end if;

  update buildings
  set name = v_name,
      code = v_code,
      floors = coalesce(p_floors, floors),
      note = nullif(trim(coalesce(p_note, '')), ''),
      updated_at = now()
  where id = p_building_id;

  insert into audit_logs (school_id, user_id, acted_role, action, entity_type, entity_id, details)
  values (v_building.school_id, v_actor.user_id, v_actor.role, 'building.update',
          'buildings', p_building_id::text, jsonb_build_object('name', v_name, 'code', v_code));
end;
$$;

create or replace function delete_school_building(p_token text, p_building_id uuid)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_building buildings%rowtype;
  v_rooms int;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('school_admin', 'super_admin') then
    raise exception 'forbidden';
  end if;

  select * into v_building from buildings where id = p_building_id for update;
  if not found then raise exception 'building_not_found'; end if;
  if v_actor.role <> 'super_admin'
     and v_building.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;

  -- ลบอาคารที่ยังมีห้องไม่ได้ — ห้องผูก building_id อยู่ ต้องย้าย/ลบห้องก่อน
  select count(*) into v_rooms from rooms where building_id = p_building_id;
  if v_rooms > 0 then raise exception 'building_has_rooms'; end if;

  delete from buildings where id = p_building_id;

  insert into audit_logs (school_id, user_id, acted_role, action, entity_type, entity_id, details)
  values (v_building.school_id, v_actor.user_id, v_actor.role, 'building.delete',
          'buildings', p_building_id::text, jsonb_build_object('name', v_building.name));
end;
$$;

-- ผู้รับผิดชอบอาคาร = ข้อความชื่อใน buildings.manager_name (คอลัมน์ที่
-- list_school_buildings อ่านอยู่แล้ว) — ส่ง null/ว่าง เพื่อล้าง
create or replace function set_school_building_manager(
  p_token text,
  p_building_id uuid,
  p_manager_name text
)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_building buildings%rowtype;
  v_name text := nullif(trim(coalesce(p_manager_name, '')), '');
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('school_admin', 'super_admin') then
    raise exception 'forbidden';
  end if;

  select * into v_building from buildings where id = p_building_id for update;
  if not found then raise exception 'building_not_found'; end if;
  if v_actor.role <> 'super_admin'
     and v_building.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;

  update buildings set manager_name = v_name, updated_at = now()
  where id = p_building_id;

  insert into audit_logs (school_id, user_id, acted_role, action, entity_type, entity_id, details)
  values (v_building.school_id, v_actor.user_id, v_actor.role, 'building.set_manager',
          'buildings', p_building_id::text, jsonb_build_object('manager_name', v_name));
end;
$$;

-- ── ห้อง ───────────────────────────────────────────────────────────────

create or replace function update_school_room(
  p_token text,
  p_room_id uuid,
  p_name text,
  p_code text,
  p_floor text default null,
  p_room_type text default null,
  p_capacity int default null
)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_room rooms%rowtype;
  v_name text := trim(coalesce(p_name, ''));
  v_code text := trim(coalesce(p_code, ''));
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('school_admin', 'super_admin') then
    raise exception 'forbidden';
  end if;

  select * into v_room from rooms where id = p_room_id for update;
  if not found then raise exception 'room_not_found'; end if;
  if v_actor.role <> 'super_admin'
     and v_room.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;

  if v_name = '' or v_code = '' then raise exception 'missing_required_field'; end if;
  if p_capacity is not null and p_capacity < 1 then raise exception 'invalid_capacity'; end if;
  if exists (
    select 1 from rooms
    where school_id = v_room.school_id and code = v_code and id <> p_room_id
  ) then
    raise exception 'duplicate_code';
  end if;

  update rooms
  set name = v_name,
      code = v_code,
      floor = coalesce(nullif(trim(coalesce(p_floor, '')), ''), floor),
      room_type = coalesce(nullif(trim(coalesce(p_room_type, '')), ''), room_type),
      capacity = coalesce(p_capacity, capacity),
      updated_at = now()
  where id = p_room_id;

  insert into audit_logs (school_id, user_id, acted_role, action, entity_type, entity_id, details)
  values (v_room.school_id, v_actor.user_id, v_actor.role, 'room.update',
          'rooms', p_room_id::text, jsonb_build_object('name', v_name, 'code', v_code));
end;
$$;

create or replace function delete_school_room(p_token text, p_room_id uuid)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_room rooms%rowtype;
  v_devices int;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('school_admin', 'super_admin') then
    raise exception 'forbidden';
  end if;

  select * into v_room from rooms where id = p_room_id for update;
  if not found then raise exception 'room_not_found'; end if;
  if v_actor.role <> 'super_admin'
     and v_room.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;

  -- devices.room เป็นข้อความชื่อห้อง (ไม่ใช่ FK) — ถ้ายังมีอุปกรณ์ชี้มาที่ชื่อนี้
  -- ให้ย้ายอุปกรณ์ก่อน จะได้ไม่เหลืออุปกรณ์ที่อ้างห้องที่ไม่มีแล้ว
  select count(*) into v_devices
  from devices
  where school_id = v_room.school_id and btrim(room) = btrim(v_room.name);
  if v_devices > 0 then raise exception 'room_has_devices'; end if;

  delete from rooms where id = p_room_id;

  insert into audit_logs (school_id, user_id, acted_role, action, entity_type, entity_id, details)
  values (v_room.school_id, v_actor.user_id, v_actor.role, 'room.delete',
          'rooms', p_room_id::text, jsonb_build_object('name', v_room.name));
end;
$$;

-- ── อุปกรณ์ ────────────────────────────────────────────────────────────

-- แก้ข้อมูลที่แอดมินโรงเรียนดูแล: ชื่อ ที่ตั้ง อาคาร ห้อง สถานะที่ตั้งเอง
-- (maintenance/offline) — ไม่แตะ token/serial/type ซึ่งเป็นของฝั่งลงทะเบียน
create or replace function update_school_device(
  p_token text,
  p_device_id uuid,
  p_name text,
  p_location text default null,
  p_building text default null,
  p_room text default null,
  p_status device_status default null
)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_device devices%rowtype;
  v_name text := trim(coalesce(p_name, ''));
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('school_admin', 'super_admin') then
    raise exception 'forbidden';
  end if;

  select * into v_device from devices where id = p_device_id for update;
  if not found then raise exception 'device_not_found'; end if;
  if v_actor.role <> 'super_admin'
     and v_device.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;
  if v_name = '' then raise exception 'missing_required_field'; end if;

  update devices
  set name = v_name,
      location = nullif(trim(coalesce(p_location, '')), ''),
      building = nullif(trim(coalesce(p_building, '')), ''),
      room = nullif(trim(coalesce(p_room, '')), ''),
      status = coalesce(p_status, status),
      updated_at = now()
  where id = p_device_id;

  insert into audit_logs (school_id, user_id, acted_role, action, entity_type, entity_id, details)
  values (v_device.school_id, v_actor.user_id, v_actor.role, 'device.update',
          'devices', p_device_id::text,
          jsonb_build_object('name', v_name, 'status', p_status::text));
end;
$$;

-- ── การแจ้งเตือน ───────────────────────────────────────────────────────

-- รับทราบทุกรายการที่ยังเป็น 'new' ของโรงเรียนตัวเอง — เงื่อนไขเดียวกับ
-- acknowledge_sensor_alert_for_school_admin แต่ทำทีเดียว คืนจำนวนที่เปลี่ยน
create or replace function acknowledge_all_school_alerts(p_token text)
returns int
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_count int;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('school_admin', 'super_admin') then
    raise exception 'forbidden';
  end if;
  if v_actor.school_id is null then raise exception 'no_active_school'; end if;

  with changed as (
    update sensor_alerts a
    set status = 'acknowledged',
        acknowledged_by = v_actor.user_id,
        acknowledged_at = now()
    from devices d
    where d.id = a.device_id
      and d.school_id = v_actor.school_id
      and a.status = 'new'
    returning a.id
  )
  select count(*) into v_count from changed;

  insert into audit_logs (school_id, user_id, acted_role, action, entity_type, entity_id, details)
  values (v_actor.school_id, v_actor.user_id, v_actor.role, 'sensor_alert.acknowledge_all',
          'sensor_alerts', v_actor.school_id::text, jsonb_build_object('count', v_count));

  return v_count;
end;
$$;

-- ── ปีการศึกษา / ภาคเรียน ───────────────────────────────────────────────

create or replace function create_academic_year(
  p_token text,
  p_name text,
  p_start_date date default null,
  p_end_date date default null
)
returns uuid
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_name text := trim(coalesce(p_name, ''));
  v_id uuid;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('school_admin', 'super_admin') then
    raise exception 'forbidden';
  end if;
  if v_actor.school_id is null then raise exception 'no_active_school'; end if;
  if v_name = '' then raise exception 'missing_required_field'; end if;
  if p_start_date is not null and p_end_date is not null and p_end_date < p_start_date then
    raise exception 'invalid_date_range';
  end if;
  if exists (select 1 from academic_years where school_id = v_actor.school_id and name = v_name) then
    raise exception 'duplicate_name';
  end if;

  insert into academic_years (school_id, name, start_date, end_date)
  values (v_actor.school_id, v_name, p_start_date, p_end_date)
  returning id into v_id;

  insert into audit_logs (school_id, user_id, acted_role, action, entity_type, entity_id, details)
  values (v_actor.school_id, v_actor.user_id, v_actor.role, 'academic_year.create',
          'academic_years', v_id::text, jsonb_build_object('name', v_name));
  return v_id;
end;
$$;

create or replace function create_term(
  p_token text,
  p_academic_year_id uuid,
  p_name text,
  p_start_date date default null,
  p_end_date date default null
)
returns uuid
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_year academic_years%rowtype;
  v_name text := trim(coalesce(p_name, ''));
  v_id uuid;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('school_admin', 'super_admin') then
    raise exception 'forbidden';
  end if;

  select * into v_year from academic_years where id = p_academic_year_id;
  if not found then raise exception 'academic_year_not_found'; end if;
  if v_actor.role <> 'super_admin'
     and v_year.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;
  if v_name = '' then raise exception 'missing_required_field'; end if;
  if p_start_date is not null and p_end_date is not null and p_end_date < p_start_date then
    raise exception 'invalid_date_range';
  end if;
  if exists (select 1 from terms where academic_year_id = p_academic_year_id and name = v_name) then
    raise exception 'duplicate_name';
  end if;

  insert into terms (academic_year_id, name, start_date, end_date)
  values (p_academic_year_id, v_name, p_start_date, p_end_date)
  returning id into v_id;

  insert into audit_logs (school_id, user_id, acted_role, action, entity_type, entity_id, details)
  values (v_year.school_id, v_actor.user_id, v_actor.role, 'term.create',
          'terms', v_id::text, jsonb_build_object('name', v_name, 'academic_year', v_year.name));
  return v_id;
end;
$$;

-- ปีการศึกษาของโรงเรียนตัวเอง (list_terms มีอยู่แล้วแต่คืนเฉพาะภาคเรียน)
create or replace function list_academic_years(p_token text)
returns table (id uuid, name varchar, start_date date, end_date date, terms_count bigint)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('school_admin', 'super_admin', 'teacher', 'executive') then
    raise exception 'forbidden';
  end if;
  return query
    select ay.id, ay.name, ay.start_date, ay.end_date,
           (select count(*) from terms t where t.academic_year_id = ay.id)
    from academic_years ay
    where ay.school_id = v_actor.school_id
    order by ay.name desc;
end;
$$;

revoke all on function update_school_building(text, uuid, text, text, int, text) from public;
revoke all on function delete_school_building(text, uuid) from public;
revoke all on function set_school_building_manager(text, uuid, text) from public;
revoke all on function update_school_room(text, uuid, text, text, text, text, int) from public;
revoke all on function delete_school_room(text, uuid) from public;
revoke all on function update_school_device(text, uuid, text, text, text, text, device_status) from public;
revoke all on function acknowledge_all_school_alerts(text) from public;
revoke all on function create_academic_year(text, text, date, date) from public;
revoke all on function create_term(text, uuid, text, date, date) from public;
revoke all on function list_academic_years(text) from public;

grant execute on function update_school_building(text, uuid, text, text, int, text) to anon, authenticated, service_role;
grant execute on function delete_school_building(text, uuid) to anon, authenticated, service_role;
grant execute on function set_school_building_manager(text, uuid, text) to anon, authenticated, service_role;
grant execute on function update_school_room(text, uuid, text, text, text, text, int) to anon, authenticated, service_role;
grant execute on function delete_school_room(text, uuid) to anon, authenticated, service_role;
grant execute on function update_school_device(text, uuid, text, text, text, text, device_status) to anon, authenticated, service_role;
grant execute on function acknowledge_all_school_alerts(text) to anon, authenticated, service_role;
grant execute on function create_academic_year(text, text, date, date) to anon, authenticated, service_role;
grant execute on function create_term(text, uuid, text, date, date) to anon, authenticated, service_role;
grant execute on function list_academic_years(text) to anon, authenticated, service_role;
