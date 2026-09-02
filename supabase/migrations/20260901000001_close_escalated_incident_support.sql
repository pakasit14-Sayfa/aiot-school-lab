create or replace function close_incident_report(
  p_token text,
  p_id uuid,
  p_resolution_type incident_resolution_type,
  p_resolution_note text
)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_incident incident_reports%rowtype;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('teacher', 'school_admin', 'executive') then raise exception 'forbidden'; end if;

  select ir.* into v_incident
  from incident_reports ir
  where ir.id = p_id
    and ir.school_id = v_actor.school_id;
  if not found then raise exception 'not_found'; end if;
  
  if v_incident.status in ('resolved', 'cancelled') then
    raise exception 'incident_already_closed';
  end if;

  if trim(coalesce(p_resolution_note, '')) = '' then raise exception 'resolution_note_required'; end if;

  -- If it's escalated, we instead close the associated emergency event, which will auto-close this via our other trigger
  if v_incident.status = 'escalated' then
    if v_incident.escalated_to_emergency_event_id is not null then
      update emergency_events
      set status = 'closed',
          closed_at = now(),
          review_note = trim(p_resolution_note),
          warning_light_on = false
      where id = v_incident.escalated_to_emergency_event_id
        and status != 'closed';
        
      update incident_reports
      set status = 'resolved',
          resolution_type = 'resolved',
          resolution_note = 'ปิดอัตโนมัติจากการปิดเหตุฉุกเฉินโดยผู้บริหาร: ' || trim(p_resolution_note),
          closed_at = now(),
          closed_by = v_actor.user_id
      where escalated_to_emergency_event_id = v_incident.escalated_to_emergency_event_id
        and status = 'escalated';
        
      return;
    else
      -- Fallback if escalated but no ID (should not happen)
      raise exception 'incident_already_closed';
    end if;
  end if;

  -- Normal close flow for non-escalated
  update incident_reports
    set status = p_resolution_type::text::incident_status,
        resolution_type = p_resolution_type,
        resolution_note = p_resolution_note,
        closed_by = v_actor.user_id,
        closed_at = now()
    where id = p_id;

  insert into incident_actions (incident_report_id, actor_id, action_type, note)
  values (p_id, v_actor.user_id, 'status_change', 'closed: ' || p_resolution_type::text);

end;
$$;
