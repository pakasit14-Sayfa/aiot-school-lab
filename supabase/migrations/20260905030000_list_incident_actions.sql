-- Canonical read for the teacher SOS "save progress note" seam: lets the
-- client confirm a note/action was actually persisted for the exact
-- incident, instead of trusting add_incident_action's void return alone.
-- Same authorization shape as get_incident_report_for_staff (same-school
-- teacher/school_admin/executive only).

create or replace function public.list_incident_actions(p_token text, p_id uuid)
returns table (
  id uuid,
  action_type varchar,
  note text,
  actor_name text,
  created_at timestamptz
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then
    raise exception 'invalid_session';
  end if;

  if v_actor.role not in ('teacher', 'school_admin', 'executive') then
    raise exception 'forbidden';
  end if;

  if not exists (
    select 1 from incident_reports ir
    where ir.id = p_id and ir.school_id = v_actor.school_id
  ) then
    raise exception 'not_found';
  end if;

  return query
  select
    ia.id,
    ia.action_type,
    ia.note,
    trim(concat_ws(' ', u.first_name, u.last_name)) as actor_name,
    ia.created_at
  from incident_actions ia
  join users u on u.id = ia.actor_id
  where ia.incident_report_id = p_id
  order by ia.created_at desc;
end;
$$;

revoke all on function public.list_incident_actions(text, uuid) from public;
grant execute on function public.list_incident_actions(text, uuid) to anon, authenticated;
