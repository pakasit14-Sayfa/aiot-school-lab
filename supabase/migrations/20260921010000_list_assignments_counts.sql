-- 20260921010000_list_assignments_counts.sql
-- The teacher's assignment list rendered "ส่งแล้ว 1/1 คน (100%)" as a
-- constant because list_assignments carried no counts. Add the three
-- numbers the redesigned list row shows (owner picked design A,
-- 2026-09-21): how many students have submitted, how many are enrolled,
-- how many of those submissions still wait for a grade, and how many
-- sensor datasets are pinned. Same auth as before; students still only
-- see published rows.
drop function if exists public.list_assignments(text, uuid);

create or replace function public.list_assignments(p_token text, p_course_id uuid)
returns table(
  assignment_id uuid, type assignment_type, title character varying,
  instructions text, is_group boolean, due_at timestamp with time zone,
  status publish_status, rubric_id uuid, rubric_title character varying,
  created_at timestamp with time zone,
  submitted_count integer, pending_grade_count integer,
  total_students integer, dataset_count integer
)
language plpgsql
security definer
set search_path to 'public', 'extensions'
as $function$
declare
  v_actor record;
  v_course courses%rowtype;
  v_is_student boolean := false;
  v_total integer;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;

  select * into v_course from courses where id = p_course_id;
  if not found then raise exception 'course_not_found'; end if;
  if v_course.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;

  if v_actor.role = 'teacher' then
    if not exists (
      select 1 from course_teachers ct
      where ct.course_id = p_course_id and ct.teacher_id = v_actor.user_id
    ) then raise exception 'forbidden'; end if;
  elsif v_actor.role = 'student' then
    v_is_student := true;
    if not exists (
      select 1 from course_students cs
      where cs.course_id = p_course_id and cs.student_id = v_actor.user_id
    ) then raise exception 'forbidden'; end if;
  elsif v_actor.role <> 'school_admin' then
    raise exception 'forbidden';
  end if;

  select count(*)::integer into v_total
  from course_students cs where cs.course_id = p_course_id;

  return query
  select a.id, a.type, a.title, a.instructions, coalesce(a.is_group, false),
    a.due_at, a.status, a.rubric_id, r.title, a.created_at,
    (select count(distinct s.student_id)::integer from submissions s where s.assignment_id = a.id),
    (select count(*)::integer from submissions s
       where s.assignment_id = a.id and s.status = 'submitted'),
    v_total,
    (select count(*)::integer from assignment_sensor_datasets d where d.assignment_id = a.id)
  from assignments a
  left join rubrics r on r.id = a.rubric_id
  where a.course_id = p_course_id
    and (v_is_student is not true or a.status = 'published')
  order by a.due_at nulls last, a.created_at;
end;
$function$;

revoke all on function public.list_assignments(text, uuid) from public;
grant execute on function public.list_assignments(text, uuid)
  to anon, authenticated, service_role;
