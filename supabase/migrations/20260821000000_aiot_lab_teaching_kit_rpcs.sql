-- =====================================================================
-- Migration: AIoT Lab Teaching Kit Schema & RPCs
-- Adds course_id to devices (teaching kit scope) and creates RPCs
-- for teachers to manage and monitor teaching kit devices.
-- =====================================================================

set search_path = public, extensions;

-- 1. Schema update: Add course_id to devices (nullable, for teaching kits only)
alter table devices add column if not exists course_id uuid references courses(id);

-- ---------------------------------------------------------------------
-- 2. list_teaching_kit_devices
-- Allows teachers to list teaching kit devices for courses they teach
-- (or school_admin for all courses in school).
-- ---------------------------------------------------------------------
create or replace function list_teaching_kit_devices(p_token text)
returns table (
  device_id uuid,
  name varchar,
  type device_type,
  location varchar,
  status device_status,
  course_id uuid,
  course_name varchar
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('teacher', 'school_admin') then
    raise exception 'forbidden';
  end if;

  return query
  select
    d.id as device_id,
    d.name,
    d.type,
    d.location,
    d.status,
    d.course_id,
    c.subject_name as course_name
  from devices d
  join courses c on c.id = d.course_id
  where d.school_id = v_actor.school_id
    and d.course_id is not null
    and (
      v_actor.role = 'school_admin'
      or exists (
        select 1 from course_teachers ct
        where ct.course_id = d.course_id
          and ct.teacher_id = v_actor.user_id
      )
    )
  order by c.subject_name, d.name;
end;
$$;

-- ---------------------------------------------------------------------
-- 3. queue_teaching_kit_command
-- Queue a command ONLY for a teaching kit device (course_id is not null)
-- bound to a course the teacher actually teaches.
-- DOES NOT modify queue_device_command.
-- ---------------------------------------------------------------------
create or replace function queue_teaching_kit_command(
  p_token text,
  p_device_id uuid,
  p_command jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_device record;
  v_command_id uuid;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('teacher', 'school_admin') then
    raise exception 'forbidden';
  end if;

  select * into v_device from devices where id = p_device_id;
  if not found then raise exception 'device_not_found'; end if;

  -- Device MUST be a teaching kit bound to a course
  if v_device.course_id is null then
    raise exception 'forbidden';
  end if;

  -- Scoped to school
  if v_actor.role <> 'super_admin' and v_device.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;

  -- Teacher MUST teach this course
  if v_actor.role = 'teacher' and not exists (
    select 1 from course_teachers
    where course_id = v_device.course_id
      and teacher_id = v_actor.user_id
  ) then
    raise exception 'forbidden';
  end if;

  insert into device_commands (device_id, command, created_by)
  values (p_device_id, p_command, v_actor.user_id)
  returning id into v_command_id;

  return v_command_id;
end;
$$;

-- ---------------------------------------------------------------------
-- 4. list_teaching_kit_command_history
-- Returns device control history for teaching kits taught by teacher.
-- ---------------------------------------------------------------------
create or replace function list_teaching_kit_command_history(
  p_token text,
  p_limit int default 20
)
returns table (
  command_id uuid,
  device_id uuid,
  device_name varchar,
  command jsonb,
  created_by_name text,
  created_at timestamptz,
  delivered_at timestamptz
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('teacher', 'school_admin') then
    raise exception 'forbidden';
  end if;

  return query
  select
    dc.id as command_id,
    d.id as device_id,
    d.name as device_name,
    dc.command,
    (u.first_name || ' ' || u.last_name)::text as created_by_name,
    dc.created_at,
    dc.delivered_at
  from device_commands dc
  join devices d on d.id = dc.device_id
  join users u on u.id = dc.created_by
  where d.school_id = v_actor.school_id
    and d.course_id is not null
    and (
      v_actor.role = 'school_admin'
      or exists (
        select 1 from course_teachers ct
        where ct.course_id = d.course_id
          and ct.teacher_id = v_actor.user_id
      )
    )
  order by dc.created_at desc
  limit greatest(1, least(p_limit, 100));
end;
$$;

-- Grants & Revokes
revoke all on function list_teaching_kit_devices(text) from public;
grant execute on function list_teaching_kit_devices(text) to anon, authenticated;

revoke all on function queue_teaching_kit_command(text, uuid, jsonb) from public;
grant execute on function queue_teaching_kit_command(text, uuid, jsonb) to anon, authenticated;

revoke all on function list_teaching_kit_command_history(text, int) from public;
grant execute on function list_teaching_kit_command_history(text, int) to anon, authenticated;
