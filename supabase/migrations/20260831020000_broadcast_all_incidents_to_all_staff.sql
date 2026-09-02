-- =====================================================================
-- Extend the SOS-only broadcast fix (20260831010000) to every incident
-- category. Same root cause as SOS: this school has zero courses set
-- up, so the old course/room-matched routing reached nobody for
-- "แจ้งเหตุผิดปกติ" reports either. User's explicit decision: treat
-- every incident category exactly like SOS — notify/allow every
-- teacher/school_admin/executive at the school, no narrower matching.
-- This makes the old course/room-matched EXISTS-subquery unreachable
-- (teacher already gets full access unconditionally now), so it's
-- dropped rather than left as dead code.
-- =====================================================================

create or replace function create_incident_report(
  p_token text,
  p_category incident_category,
  p_room text default null,
  p_reason text default null,
  p_severity text default null
)
returns table (incident_id uuid)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_room text;
  v_incident_id uuid;
  v_reporter_name text;
  v_teacher record;
  v_title varchar;
  v_body text;
  v_sev text := coalesce(p_severity, case when p_category = 'sos' then 'high' else 'low' end);
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role <> 'student' then raise exception 'forbidden'; end if;

  select coalesce(p_room, sp.room) into v_room
  from student_profiles sp
  where sp.student_id = v_actor.user_id
  order by sp.created_at desc
  limit 1;
  if v_room is null then v_room := p_room; end if;

  insert into incident_reports (school_id, reporter_student_id, category, room, status, reason, severity)
  values (v_actor.school_id, v_actor.user_id, p_category, v_room, 'new', p_reason, v_sev)
  returning id into v_incident_id;

  insert into audit_logs (school_id, user_id, acted_role, action, entity_type, entity_id, details)
  values (v_actor.school_id, v_actor.user_id, v_actor.role, 'incident.create', 'incident_reports', v_incident_id::text,
          jsonb_build_object('category', p_category, 'room', v_room, 'reason', p_reason, 'severity', v_sev));

  select first_name || ' ' || last_name into v_reporter_name from users where id = v_actor.user_id;
  v_title := case p_category when 'sos' then 'แจ้งเหตุฉุกเฉิน (SOS)' else 'แจ้งเหตุผิดปกติ' end;
  v_body := coalesce(v_reporter_name, 'นักเรียน') || ' แจ้งเหตุ (' ||
            case v_sev when 'high' then '🔴 เหตุใหญ่' when 'medium' then '🟠 เหตุปานกลาง' else '🟢 เหตุเล็ก' end ||
            case when p_reason is not null and p_reason <> '' then ': ' || p_reason else '' end ||
            ') จากห้อง ' || coalesce(v_room, 'ไม่ระบุ');

  -- ทุกประเภทเหตุ (ไม่ใช่แค่ SOS) กระจายให้ครู/แอดมินโรงเรียน/ผู้บริหาร
  -- ทุกคนในโรงเรียน — ตามคำสั่งผู้ใช้ (2026-08-31): "ทำเหมือน SOS เลย"
  for v_teacher in
    select distinct ur.user_id as teacher_id
    from user_roles ur
    where ur.school_id = v_actor.school_id
      and ur.role in ('teacher', 'school_admin', 'executive')
  loop
    insert into notifications (user_id, type, title, body, payload)
    values (
      v_teacher.teacher_id, 'incident_report', v_title, v_body,
      jsonb_build_object('incident_id', v_incident_id, 'category', p_category, 'room', v_room, 'reason', p_reason, 'severity', v_sev)
    );
  end loop;

  return query select v_incident_id;
end;
$$;

create or replace function list_incident_reports(p_token text, p_status incident_status default null)
returns table (
  id uuid,
  category incident_category,
  room varchar,
  status incident_status,
  reporter_name varchar,
  created_at timestamptz,
  acknowledged_at timestamptz,
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
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('teacher', 'school_admin', 'executive') then raise exception 'forbidden'; end if;

  return query
  select ir.id, ir.category, ir.room, ir.status,
         (u.first_name || ' ' || u.last_name)::varchar, ir.created_at, ir.acknowledged_at,
         ir.reason, ir.severity
  from incident_reports ir
  join users u on u.id = ir.reporter_student_id
  where ir.school_id = v_actor.school_id
    and (p_status is null or ir.status = p_status)
  order by
    case ir.category when 'sos' then 0 else 1 end,
    ir.created_at asc;
end;
$$;

create or replace function acknowledge_incident_report(p_token text, p_id uuid)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_incident incident_reports%rowtype;
  v_updated int;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('teacher', 'school_admin', 'executive') then raise exception 'forbidden'; end if;

  select ir.* into v_incident
  from incident_reports ir
  where ir.id = p_id
    and ir.school_id = v_actor.school_id;
  if not found then raise exception 'not_found'; end if;

  update incident_reports
    set status = 'acknowledged', acknowledged_by = v_actor.user_id, acknowledged_at = now()
    where id = p_id and acknowledged_by is null;
  get diagnostics v_updated = row_count;
  if v_updated = 0 then raise exception 'already_acknowledged'; end if;

  insert into incident_actions (incident_report_id, actor_id, action_type, note)
  values (p_id, v_actor.user_id, 'status_change', 'acknowledged');

  insert into audit_logs (school_id, user_id, acted_role, action, entity_type, entity_id)
  values (v_actor.school_id, v_actor.user_id, v_actor.role, 'incident.acknowledge', 'incident_reports', p_id::text);
end;
$$;

create or replace function assign_incident_report(p_token text, p_id uuid, p_assignee_id uuid)
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
  if v_incident.status in ('escalated', 'resolved', 'cancelled') then
    raise exception 'incident_already_closed';
  end if;

  update incident_reports set assigned_to = p_assignee_id where id = p_id;

  insert into incident_actions (incident_report_id, actor_id, action_type, note)
  values (p_id, v_actor.user_id, 'assign', null);

  insert into audit_logs (school_id, user_id, acted_role, action, entity_type, entity_id, details)
  values (v_actor.school_id, v_actor.user_id, v_actor.role, 'incident.assign', 'incident_reports', p_id::text,
          jsonb_build_object('assigned_to', p_assignee_id));
end;
$$;

create or replace function add_incident_action(p_token text, p_id uuid, p_note text)
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
  if v_incident.status in ('escalated', 'resolved', 'cancelled') then
    raise exception 'incident_already_closed';
  end if;
  if trim(coalesce(p_note, '')) = '' then raise exception 'note_required'; end if;

  insert into incident_actions (incident_report_id, actor_id, action_type, note)
  values (p_id, v_actor.user_id, 'note', p_note);

  update incident_reports set status = 'in_progress' where id = p_id and status = 'acknowledged';

  insert into audit_logs (school_id, user_id, acted_role, action, entity_type, entity_id)
  values (v_actor.school_id, v_actor.user_id, v_actor.role, 'incident.action_note', 'incident_reports', p_id::text);
end;
$$;

create or replace function escalate_incident_report(p_token text, p_id uuid)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_incident incident_reports%rowtype;
  v_event_id uuid;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('teacher', 'school_admin', 'executive') then raise exception 'forbidden'; end if;

  select ir.* into v_incident
  from incident_reports ir
  where ir.id = p_id
    and ir.school_id = v_actor.school_id;
  if not found then raise exception 'not_found'; end if;
  if v_incident.status in ('escalated', 'resolved', 'cancelled') then
    raise exception 'incident_already_closed';
  end if;

  insert into emergency_events (school_id, source_device_id, location, status, warning_light_on)
  values (v_actor.school_id, null, v_incident.room, 'new', true)
  returning id into v_event_id;

  update incident_reports
    set status = 'escalated', escalated_to_emergency_event_id = v_event_id
    where id = p_id;

  insert into incident_actions (incident_report_id, actor_id, action_type, note)
  values (p_id, v_actor.user_id, 'status_change', 'escalated');

  insert into audit_logs (school_id, user_id, acted_role, action, entity_type, entity_id, details)
  values (v_actor.school_id, v_actor.user_id, v_actor.role, 'incident.escalate', 'incident_reports', p_id::text,
          jsonb_build_object('emergency_event_id', v_event_id));
end;
$$;

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
  if v_incident.status in ('escalated', 'resolved', 'cancelled') then
    raise exception 'incident_already_closed';
  end if;
  if trim(coalesce(p_resolution_note, '')) = '' then raise exception 'resolution_note_required'; end if;

  update incident_reports
    set status = p_resolution_type::text::incident_status,
        resolution_type = p_resolution_type,
        resolution_note = p_resolution_note,
        closed_by = v_actor.user_id,
        closed_at = now()
    where id = p_id;

  insert into incident_actions (incident_report_id, actor_id, action_type, note)
  values (p_id, v_actor.user_id, 'status_change', 'closed: ' || p_resolution_type::text);

  insert into audit_logs (school_id, user_id, acted_role, action, entity_type, entity_id, details)
  values (v_actor.school_id, v_actor.user_id, v_actor.role, 'incident.close', 'incident_reports', p_id::text,
          jsonb_build_object('resolution_type', p_resolution_type));
end;
$$;

grant execute on function create_incident_report(text, incident_category, text, text, text) to anon, authenticated;
grant execute on function list_incident_reports(text, incident_status) to anon, authenticated;
grant execute on function acknowledge_incident_report(text, uuid) to anon, authenticated;
grant execute on function assign_incident_report(text, uuid, uuid) to anon, authenticated;
grant execute on function add_incident_action(text, uuid, text) to anon, authenticated;
grant execute on function escalate_incident_report(text, uuid) to anon, authenticated;
grant execute on function close_incident_report(text, uuid, incident_resolution_type, text) to anon, authenticated;
