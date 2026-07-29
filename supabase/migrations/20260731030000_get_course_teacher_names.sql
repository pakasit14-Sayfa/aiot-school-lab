-- get_course previously omitted teacher names, forcing the student-facing
-- course detail header to fall back to placeholder demo text. Add an
-- aggregated teacher_names column so the real page header can be honest.

drop function if exists get_course(text, uuid);

create or replace function get_course(p_token text, p_course_id uuid)
returns table (
  course_id uuid,
  subject_name varchar,
  grade_level varchar,
  room varchar,
  description text,
  status course_status,
  term_id uuid,
  teacher_names text
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_course courses%rowtype;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;

  select * into v_course from courses where id = p_course_id;
  if not found then raise exception 'course_not_found'; end if;
  if v_course.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;

  if v_actor.role = 'teacher' and not exists (
    select 1 from course_teachers ct
    where ct.course_id = p_course_id and ct.teacher_id = v_actor.user_id
  ) then raise exception 'forbidden';
  elsif v_actor.role = 'student' and not exists (
    select 1 from course_students cs
    where cs.course_id = p_course_id and cs.student_id = v_actor.user_id
  ) then raise exception 'forbidden';
  elsif v_actor.role not in ('teacher', 'student', 'school_admin') then
    raise exception 'forbidden';
  end if;

  return query
  select
    v_course.id, v_course.subject_name, v_course.grade_level, v_course.room,
    v_course.description, v_course.status, v_course.term_id,
    (
      select string_agg(u.first_name || ' ' || u.last_name, ', ' order by u.first_name)
      from course_teachers ct
      join users u on u.id = ct.teacher_id
      where ct.course_id = v_course.id
    );
end;
$$;

revoke all on function get_course(text, uuid) from public;
grant execute on function get_course(text, uuid) to anon, authenticated;
