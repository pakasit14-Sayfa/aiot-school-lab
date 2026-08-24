-- =====================================================================
-- Migration: 20260824120000_parent_executive_tier2_rpcs.sql
-- Description:
--   1. list_my_student_schedule(p_token, p_student_id) — Parent views child schedule
--   2. get_classrooms_overview(p_token) — Executive/Admin classrooms aggregate
--   3. list_all_school_schedules(p_token) — Executive/Admin school-wide schedules view
-- =====================================================================

create or replace function list_my_student_schedule(
  p_token text,
  p_student_id uuid
)
returns table (
  schedule_id uuid,
  course_id uuid,
  subject_name varchar,
  day_of_week smallint,
  start_time time,
  end_time time,
  room varchar
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
  if v_actor.role <> 'parent' then raise exception 'forbidden'; end if;

  if not exists (
    select 1 from parent_links pl
    where pl.parent_id = v_actor.user_id
      and pl.student_id = p_student_id
      and pl.status = 'approved'
  ) then
    raise exception 'forbidden';
  end if;

  return query
  select cs.id, c.id, c.subject_name, cs.day_of_week, cs.start_time, cs.end_time, cs.room
  from class_schedules cs
  join courses c on c.id = cs.course_id
  join course_students st on st.course_id = c.id
  where st.student_id = p_student_id
  order by cs.day_of_week, cs.start_time;
end;
$$;

revoke all on function list_my_student_schedule(text, uuid) from public;
grant execute on function list_my_student_schedule(text, uuid) to anon, authenticated;

create or replace function get_classrooms_overview(p_token text)
returns table (
  room_count bigint,
  course_count bigint,
  active_student_count bigint,
  assignments_due_this_week bigint
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_room_count bigint;
  v_course_count bigint;
  v_student_count bigint;
  v_assignments_count bigint;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('executive', 'school_admin') then
    raise exception 'forbidden';
  end if;

  select count(*) into v_room_count
  from rooms
  where school_id = v_actor.school_id;

  select count(*) into v_course_count
  from courses
  where school_id = v_actor.school_id;

  select count(distinct ur.user_id) into v_student_count
  from user_roles ur
  join users u on u.id = ur.user_id
  where ur.school_id = v_actor.school_id
    and ur.role = 'student'
    and u.status = 'active';

  select count(*) into v_assignments_count
  from assignments a
  join courses c on c.id = a.course_id
  where c.school_id = v_actor.school_id
    and a.due_at >= now()
    and a.due_at <= (now() + interval '7 days');

  return query select
    v_room_count,
    v_course_count,
    v_student_count,
    v_assignments_count;
end;
$$;

revoke all on function get_classrooms_overview(text) from public;
grant execute on function get_classrooms_overview(text) to anon, authenticated;

create or replace function list_all_school_schedules(p_token text)
returns table (
  schedule_id uuid,
  course_id uuid,
  subject_name varchar,
  day_of_week smallint,
  start_time time,
  end_time time,
  room varchar
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
  if v_actor.role not in ('executive', 'school_admin') then
    raise exception 'forbidden';
  end if;

  return query
  select cs.id, c.id, c.subject_name, cs.day_of_week, cs.start_time, cs.end_time, cs.room
  from class_schedules cs
  join courses c on c.id = cs.course_id
  where c.school_id = v_actor.school_id
  order by cs.day_of_week, cs.start_time;
end;
$$;

revoke all on function list_all_school_schedules(text) from public;
grant execute on function list_all_school_schedules(text) to anon, authenticated;
