-- Keep incident mutations auditable and expose RPCs only to API roles.

create or replace function public.close_incident_report(
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
  v_closed_incident_id uuid;
  v_resolution_note text;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('teacher', 'school_admin', 'executive') then
    raise exception 'forbidden';
  end if;

  select ir.* into v_incident
  from incident_reports ir
  where ir.id = p_id
    and ir.school_id = v_actor.school_id;
  if not found then raise exception 'not_found'; end if;

  if v_incident.status in ('resolved', 'cancelled') then
    raise exception 'incident_already_closed';
  end if;

  v_resolution_note := trim(coalesce(p_resolution_note, ''));
  if v_resolution_note = '' then raise exception 'resolution_note_required'; end if;

  if v_incident.status = 'escalated' then
    if v_incident.escalated_to_emergency_event_id is null then
      raise exception 'incident_already_closed';
    end if;

    update emergency_events
    set status = 'closed',
        closed_at = now(),
        review_note = v_resolution_note,
        warning_light_on = false
    where id = v_incident.escalated_to_emergency_event_id
      and status != 'closed';

    for v_closed_incident_id in
      update incident_reports
      set status = 'resolved',
          resolution_type = 'resolved',
          resolution_note = 'ปิดอัตโนมัติจากการปิดเหตุฉุกเฉินโดยผู้บริหาร: ' || v_resolution_note,
          closed_at = now(),
          closed_by = v_actor.user_id
      where escalated_to_emergency_event_id = v_incident.escalated_to_emergency_event_id
        and status = 'escalated'
      returning id
    loop
      insert into incident_actions (incident_report_id, actor_id, action_type, note)
      values (v_closed_incident_id, v_actor.user_id, 'status_change', 'closed: resolved');

      insert into audit_logs (
        school_id, user_id, acted_role, action, entity_type, entity_id, details
      ) values (
        v_actor.school_id,
        v_actor.user_id,
        v_actor.role,
        'incident.close',
        'incident_reports',
        v_closed_incident_id::text,
        jsonb_build_object(
          'resolution_type', 'resolved',
          'resolution_note', v_resolution_note,
          'closed_via_emergency', true
        )
      );
    end loop;

    return;
  end if;

  update incident_reports
  set status = p_resolution_type::text::incident_status,
      resolution_type = p_resolution_type,
      resolution_note = v_resolution_note,
      closed_by = v_actor.user_id,
      closed_at = now()
  where id = p_id;

  insert into incident_actions (incident_report_id, actor_id, action_type, note)
  values (p_id, v_actor.user_id, 'status_change', 'closed: ' || p_resolution_type::text);

  insert into audit_logs (
    school_id, user_id, acted_role, action, entity_type, entity_id, details
  ) values (
    v_actor.school_id,
    v_actor.user_id,
    v_actor.role,
    'incident.close',
    'incident_reports',
    p_id::text,
    jsonb_build_object(
      'resolution_type', p_resolution_type::text,
      'resolution_note', v_resolution_note,
      'closed_via_emergency', false
    )
  );
end;
$$;

revoke all on function public.list_incident_reports(text, incident_status) from public;
revoke all on function public.get_incident_report(text, uuid) from public;
revoke all on function public.get_incident_report_for_staff(text, uuid) from public;
revoke all on function public.acknowledge_incident_report(text, uuid) from public;
revoke all on function public.close_incident_report(text, uuid, incident_resolution_type, text) from public;

grant execute on function public.list_incident_reports(text, incident_status)
  to anon, authenticated, service_role;
grant execute on function public.get_incident_report(text, uuid)
  to anon, authenticated, service_role;
grant execute on function public.get_incident_report_for_staff(text, uuid)
  to anon, authenticated, service_role;
grant execute on function public.acknowledge_incident_report(text, uuid)
  to anon, authenticated, service_role;
grant execute on function public.close_incident_report(text, uuid, incident_resolution_type, text)
  to anon, authenticated, service_role;
