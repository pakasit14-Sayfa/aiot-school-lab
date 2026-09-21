-- 20260921020000_assignment_dataset_unlink_and_close.sql
-- Two gaps the redesigned teacher flow (2026-09-21) needs:
--   * unlink_assignment_sensor_dataset — a pinned dataset could be added
--     but never removed (the label typed on the phone was garbage, and
--     the only way out was to delete the assignment).
--   * unpublish_assignment — "ปิดรับงาน": takes a published assignment back
--     to draft so students stop seeing/submitting it. Submissions and
--     grades already made are untouched.
-- Both: course teacher only, same guard as link_assignment_sensor_dataset.

create or replace function public.unlink_assignment_sensor_dataset(
  p_token text, p_dataset_id uuid
) returns void
language plpgsql security definer set search_path = public, extensions
as $$
declare
  v_actor record;
  v_assignment_id uuid;
  v_course_id uuid;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role <> 'teacher' then raise exception 'forbidden'; end if;

  select d.assignment_id, a.course_id into v_assignment_id, v_course_id
  from assignment_sensor_datasets d join assignments a on a.id = d.assignment_id
  where d.id = p_dataset_id;
  if not found then raise exception 'dataset_not_found'; end if;
  if not exists (
    select 1 from course_teachers ct
    where ct.course_id = v_course_id and ct.teacher_id = v_actor.user_id
  ) then raise exception 'forbidden'; end if;

  delete from assignment_sensor_datasets where id = p_dataset_id;
end;
$$;
revoke all on function public.unlink_assignment_sensor_dataset(text, uuid) from public;
grant execute on function public.unlink_assignment_sensor_dataset(text, uuid) to anon, authenticated;

create or replace function public.unpublish_assignment(p_token text, p_assignment_id uuid)
returns void
language plpgsql security definer set search_path = public, extensions
as $$
declare
  v_actor record;
  v_course_id uuid;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role <> 'teacher' then raise exception 'forbidden'; end if;

  select course_id into v_course_id from assignments where id = p_assignment_id;
  if not found then raise exception 'assignment_not_found'; end if;
  if not exists (
    select 1 from course_teachers ct
    where ct.course_id = v_course_id and ct.teacher_id = v_actor.user_id
  ) then raise exception 'forbidden'; end if;

  update assignments set status = 'draft' where id = p_assignment_id;
end;
$$;
revoke all on function public.unpublish_assignment(text, uuid) from public;
grant execute on function public.unpublish_assignment(text, uuid) to anon, authenticated;
