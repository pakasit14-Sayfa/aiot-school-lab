-- Migration: 20260819163000_student_groups_and_incident_rpc_fix.sql
-- Description: Fix list_incident_reports RPC severity type (text); Add student_groups RPCs with role & course ownership security guards.

-- 1. Drop existing list_incident_reports to allow changing return columns, then recreate with reason text & severity text
drop function if exists list_incident_reports(text, incident_status);

create or replace function list_incident_reports(p_token text, p_status incident_status default null)
returns table (
  id uuid,
  category incident_category,
  room varchar,
  status incident_status,
  reporter_name varchar,
  created_at timestamptz,
  acknowledged_at timestamptz,
  reason text,
  severity text
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
  if v_actor.role not in ('teacher', 'school_admin') then raise exception 'forbidden'; end if;

  return query
  select ir.id, ir.category, ir.room, ir.status,
         (u.first_name || ' ' || u.last_name)::varchar as reporter_name,
         ir.created_at, ir.acknowledged_at, ir.reason, ir.severity
  from incident_reports ir
  join users u on u.id = ir.reporter_student_id
  where ir.school_id = v_actor.school_id
    and (p_status is null or ir.status = p_status)
    and (
      v_actor.role = 'school_admin'
      or exists (
        select 1
        from course_teachers ct
        join course_students cst on cst.course_id = ct.course_id
        join student_profiles sp on sp.student_id = cst.student_id
        where ct.teacher_id = v_actor.user_id and sp.room = ir.room
      )
    )
  order by
    case ir.category when 'sos' then 0 else 1 end,
    ir.created_at asc;
end;
$$;

revoke all on function list_incident_reports(text, incident_status) from public;
grant execute on function list_incident_reports(text, incident_status) to anon, authenticated;

-- 2. Student Groups RPCs with Role & Tenant Security Guards

-- list_student_groups: ดึงกลุ่มนักเรียนในวิชา (Role guard: teacher, school_admin, หรือ student ที่เรียนในวิชานี้)
create or replace function list_student_groups(p_token text, p_course_id uuid)
returns table (
  id uuid,
  course_id uuid,
  name varchar,
  created_at timestamptz,
  members jsonb
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

  -- Security Guard: ต้องเป็น school_admin หรือ ครูผู้สอนวิชานี้ หรือ นักเรียนที่ลงเรียนวิชานี้
  if v_actor.role <> 'school_admin' and not exists (
    select 1 from course_teachers ct where ct.course_id = p_course_id and ct.teacher_id = v_actor.user_id
  ) and not exists (
    select 1 from course_students cs where cs.course_id = p_course_id and cs.student_id = v_actor.user_id
  ) then
    raise exception 'forbidden';
  end if;

  return query
  select sg.id, sg.course_id, sg.name, sg.created_at,
         coalesce(
           jsonb_agg(
             jsonb_build_object(
               'student_id', gm.student_id,
               'first_name', u.first_name,
               'last_name', u.last_name,
               'student_code', u.student_code
             )
           ) filter (where gm.student_id is not null),
           '[]'::jsonb
         ) as members
  from student_groups sg
  left join group_members gm on gm.group_id = sg.id
  left join users u on u.id = gm.student_id
  where sg.course_id = p_course_id
  group by sg.id, sg.course_id, sg.name, sg.created_at
  order by sg.created_at asc;
end;
$$;

revoke all on function list_student_groups(text, uuid) from public;
grant execute on function list_student_groups(text, uuid) to anon, authenticated;

-- create_student_group: สร้างกลุ่มนักเรียนใหม่ในวิชา (Role guard & Course ownership check)
create or replace function create_student_group(p_token text, p_course_id uuid, p_name text)
returns uuid
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_new_id uuid;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('teacher', 'school_admin') then raise exception 'forbidden'; end if;

  if v_actor.role <> 'school_admin' and not exists (
    select 1 from course_teachers ct where ct.course_id = p_course_id and ct.teacher_id = v_actor.user_id
  ) then
    raise exception 'forbidden';
  end if;

  insert into student_groups (course_id, name, created_by)
  values (p_course_id, p_name, v_actor.user_id)
  returning id into v_new_id;

  return v_new_id;
end;
$$;

revoke all on function create_student_group(text, uuid, text) from public;
grant execute on function create_student_group(text, uuid, text) to anon, authenticated;

-- rename_student_group: เปลี่ยนชื่อกลุ่มนักเรียน (Role guard & Group/Course ownership check)
create or replace function rename_student_group(p_token text, p_group_id uuid, p_name text)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_course_id uuid;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('teacher', 'school_admin') then raise exception 'forbidden'; end if;

  select course_id into v_course_id from student_groups where id = p_group_id;
  if not found then raise exception 'not_found'; end if;

  if v_actor.role <> 'school_admin' and not exists (
    select 1 from course_teachers ct where ct.course_id = v_course_id and ct.teacher_id = v_actor.user_id
  ) then
    raise exception 'forbidden';
  end if;

  update student_groups set name = p_name where id = p_group_id;
end;
$$;

revoke all on function rename_student_group(text, uuid, text) from public;
grant execute on function rename_student_group(text, uuid, text) to anon, authenticated;

-- delete_student_group: ลบกลุ่มนักเรียน (Role guard & Group/Course ownership check)
create or replace function delete_student_group(p_token text, p_group_id uuid)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_course_id uuid;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('teacher', 'school_admin') then raise exception 'forbidden'; end if;

  select course_id into v_course_id from student_groups where id = p_group_id;
  if not found then raise exception 'not_found'; end if;

  if v_actor.role <> 'school_admin' and not exists (
    select 1 from course_teachers ct where ct.course_id = v_course_id and ct.teacher_id = v_actor.user_id
  ) then
    raise exception 'forbidden';
  end if;

  delete from group_members where group_id = p_group_id;
  delete from student_groups where id = p_group_id;
end;
$$;

revoke all on function delete_student_group(text, uuid) from public;
grant execute on function delete_student_group(text, uuid) to anon, authenticated;

-- add_group_member: เพิ่มนักเรียนเข้ากลุ่ม (Role guard & Group/Course ownership check)
create or replace function add_group_member(p_token text, p_group_id uuid, p_student_id uuid)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_course_id uuid;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('teacher', 'school_admin') then raise exception 'forbidden'; end if;

  select course_id into v_course_id from student_groups where id = p_group_id;
  if not found then raise exception 'not_found'; end if;

  if v_actor.role <> 'school_admin' and not exists (
    select 1 from course_teachers ct where ct.course_id = v_course_id and ct.teacher_id = v_actor.user_id
  ) then
    raise exception 'forbidden';
  end if;

  insert into group_members (group_id, student_id)
  values (p_group_id, p_student_id)
  on conflict (group_id, student_id) do nothing;
end;
$$;

revoke all on function add_group_member(text, uuid, uuid) from public;
grant execute on function add_group_member(text, uuid, uuid) to anon, authenticated;

-- remove_group_member: นำนักเรียนออกจากกลุ่ม (Role guard & Group/Course ownership check)
create or replace function remove_group_member(p_token text, p_group_id uuid, p_student_id uuid)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_course_id uuid;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('teacher', 'school_admin') then raise exception 'forbidden'; end if;

  select course_id into v_course_id from student_groups where id = p_group_id;
  if not found then raise exception 'not_found'; end if;

  if v_actor.role <> 'school_admin' and not exists (
    select 1 from course_teachers ct where ct.course_id = v_course_id and ct.teacher_id = v_actor.user_id
  ) then
    raise exception 'forbidden';
  end if;

  delete from group_members
  where group_id = p_group_id and student_id = p_student_id;
end;
$$;

revoke all on function remove_group_member(text, uuid, uuid) from public;
grant execute on function remove_group_member(text, uuid, uuid) to anon, authenticated;
