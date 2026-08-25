-- 20260826120000_enhance_list_lessons_counts.sql
-- Enhance list_lessons to include materials_count and sensor_links_count to avoid N+1 queries in lesson lists
-- Also ensure seed material example URLs that are not in storage are typed 'link'.

drop function if exists list_lessons(text, uuid);

create or replace function list_lessons(p_token text, p_course_id uuid)
returns table (
  lesson_id uuid,
  title varchar,
  status lesson_status,
  published_at timestamptz,
  updated_at timestamptz,
  materials_count bigint,
  sensor_links_count bigint
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_course courses%rowtype;
  v_is_teacher boolean := false;
  v_is_student boolean := false;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;

  select * into v_course from courses where id = p_course_id;
  if not found then raise exception 'course_not_found'; end if;
  if v_course.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;

  if v_actor.role = 'teacher' then
    v_is_teacher := exists (
      select 1 from course_teachers ct
      where ct.course_id = p_course_id and ct.teacher_id = v_actor.user_id
    );
    if not v_is_teacher then raise exception 'forbidden'; end if;
  elsif v_actor.role = 'student' then
    v_is_student := exists (
      select 1 from course_students cs
      where cs.course_id = p_course_id and cs.student_id = v_actor.user_id
    );
    if not v_is_student then raise exception 'forbidden'; end if;
  elsif v_actor.role <> 'school_admin' then
    raise exception 'forbidden';
  end if;

  return query
  select
    l.id,
    l.title,
    l.status,
    l.published_at,
    l.updated_at,
    (select count(*) from lesson_materials lm where lm.lesson_id = l.id) as materials_count,
    (select count(*) from lesson_sensor_links lsl where lsl.lesson_id = l.id) as sensor_links_count
  from lessons l
  where l.course_id = p_course_id
    and (v_is_student is not true or l.status = 'published')
  order by l.published_at nulls last, l.id;
end;
$$;

revoke all on function list_lessons(text, uuid) from public;
grant execute on function list_lessons(text, uuid) to anon, authenticated;

-- Fix seed material row if it was seeded as 'file' with external example.com url
update lesson_materials
set type = 'link'
where url = 'https://example.com/materials/pm25_manual.pdf'
  and type = 'file';
