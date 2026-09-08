-- list_assignments only returned id/type/title/due_at/status. The Dart page
-- consuming it (teacher_assignment_editor_page.dart) had no way to know a
-- real rubric was attached (rubric_id/rubric_title), what the real
-- instructions were (so re-opening an assignment to edit it showed a blank
-- instructions field, risking silently overwriting real saved instructions
-- with blank on save), or whether it was group work — so it filled all of
-- these in with fabricated placeholder text instead. rubric_id/instructions/
-- is_group all already exist on assignments; this just returns them plus
-- the rubric's real title via a join, instead of leaving the caller to
-- invent something.
-- Postgres refuses CREATE OR REPLACE when the output column list of a
-- RETURNS TABLE function changes ("cannot change return type") — drop first.
drop function if exists public.list_assignments(text, uuid);

create or replace function public.list_assignments(p_token text, p_course_id uuid)
returns table(
  assignment_id uuid, type assignment_type, title character varying,
  instructions text, is_group boolean, due_at timestamp with time zone,
  status publish_status, rubric_id uuid, rubric_title character varying,
  created_at timestamp with time zone
)
language plpgsql
security definer
set search_path to 'public', 'extensions'
as $function$
declare
  v_actor record;
  v_course courses%rowtype;
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

  return query
  select a.id, a.type, a.title, a.instructions, coalesce(a.is_group, false),
    a.due_at, a.status, a.rubric_id, r.title, a.created_at
  from assignments a
  left join rubrics r on r.id = a.rubric_id
  where a.course_id = p_course_id
    and (v_is_student is not true or a.status = 'published')
  order by a.due_at nulls last, a.created_at;
end;
$function$;

-- DROP FUNCTION resets grants to whatever the current default ACL implies,
-- which included an unwanted implicit PUBLIC grant when tested locally —
-- revoke it and restore the exact same 4-role grant every other RPC in
-- this project uses (auth enforced inside the function body via p_token,
-- not via role grants, but keep the grant surface consistent regardless).
revoke all on function public.list_assignments(text, uuid) from public;
grant execute on function public.list_assignments(text, uuid)
  to anon, authenticated, service_role;
