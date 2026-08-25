-- =====================================================================
-- Migration: Add list_teacher_schedules RPC
-- Allows teachers (and school_admin) to list class schedule slots for
-- their courses.
-- =====================================================================

create or replace function list_teacher_schedules(
  p_token text,
  p_course_id uuid default null
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
  if v_actor.role not in ('teacher', 'school_admin') then
    raise exception 'forbidden';
  end if;

  return query
  select cs.id, c.id, c.subject_name, cs.day_of_week, cs.start_time, cs.end_time, cs.room
  from class_schedules cs
  join courses c on c.id = cs.course_id
  where c.school_id = v_actor.school_id
    and (p_course_id is null or c.id = p_course_id)
    and (
      v_actor.role = 'school_admin'
      or exists (
        select 1 from course_teachers ct
        where ct.course_id = c.id and ct.teacher_id = v_actor.user_id
      )
    )
  order by cs.day_of_week, cs.start_time;
end;
$$;

revoke all on function list_teacher_schedules(text, uuid) from public;
grant execute on function list_teacher_schedules(text, uuid) to anon, authenticated;
