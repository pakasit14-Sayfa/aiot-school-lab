-- list_lesson_progress — per-student progress of one lesson for its teacher.
--
-- Students have written lesson_progress via update_lesson_progress /
-- mark_lesson_complete since the lesson viewer shipped, but nothing ever read
-- it back for the teacher: the "สถิติบทเรียนรายคน" screen in the teacher
-- lesson editor was a placeholder saying the feature was under development.
--
-- Returns one row per enrolled student (left join), so a student who never
-- opened the lesson shows progress 0 / opened=false rather than vanishing.

create or replace function public.list_lesson_progress(p_token text, p_lesson_id uuid)
returns table (
  student_id uuid,
  first_name varchar,
  last_name varchar,
  email varchar,
  progress_pct numeric,
  completed boolean,
  completed_at timestamptz,
  updated_at timestamptz
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_lesson lessons%rowtype;
  v_course courses%rowtype;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;

  select * into v_lesson from lessons where id = p_lesson_id;
  if not found then raise exception 'lesson_not_found'; end if;

  select * into v_course from courses where id = v_lesson.course_id;
  if not found then raise exception 'lesson_not_found'; end if;
  if v_course.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;

  if v_actor.role = 'teacher' and not exists (
    select 1 from course_teachers ct
    where ct.course_id = v_course.id and ct.teacher_id = v_actor.user_id
  ) then raise exception 'forbidden';
  elsif v_actor.role not in ('teacher', 'school_admin') then
    raise exception 'forbidden';
  end if;

  return query
  select u.id, u.first_name, u.last_name, u.email,
         coalesce(lp.progress_pct, 0)::numeric,
         coalesce(lp.completed, false),
         lp.completed_at,
         lp.updated_at
  from course_students cs
  join users u on u.id = cs.student_id
  left join lesson_progress lp
    on lp.lesson_id = p_lesson_id and lp.student_id = cs.student_id
  where cs.course_id = v_course.id
  order by u.first_name, u.last_name;
end;
$$;

grant execute on function public.list_lesson_progress(text, uuid) to anon, authenticated, service_role;
