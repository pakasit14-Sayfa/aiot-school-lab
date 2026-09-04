-- Staff-facing incident detail for the school-scoped incident inbox.

create or replace function public.get_incident_report_for_staff(
  p_token text,
  p_id uuid
)
returns table (
  id uuid,
  category incident_category,
  room varchar,
  status incident_status,
  resolution_type incident_resolution_type,
  resolution_note text,
  created_at timestamptz,
  acknowledged_at timestamptz,
  closed_at timestamptz,
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
  if not found then
    raise exception 'invalid_session';
  end if;

  if v_actor.role not in ('teacher', 'school_admin', 'executive') then
    raise exception 'forbidden';
  end if;

  return query
  select
    ir.id,
    ir.category,
    ir.room,
    ir.status,
    ir.resolution_type,
    ir.resolution_note,
    ir.created_at,
    ir.acknowledged_at,
    ir.closed_at,
    ir.reason,
    ir.severity
  from incident_reports ir
  where ir.id = p_id
    and ir.school_id = v_actor.school_id;

  if not found then
    raise exception 'not_found';
  end if;
end;
$$;

revoke all on function public.get_incident_report_for_staff(text, uuid) from public;
grant execute on function public.get_incident_report_for_staff(text, uuid)
  to anon, authenticated, service_role;
