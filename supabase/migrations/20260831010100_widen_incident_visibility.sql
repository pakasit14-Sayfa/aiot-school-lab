-- Allow executive and super_admin roles to view, acknowledge, and close incident reports in their school

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
  if v_actor.role not in ('teacher', 'school_admin', 'executive', 'super_admin') then raise exception 'forbidden'; end if;

  return query
  select ir.id, ir.category, ir.room, ir.status,
         (u.first_name || ' ' || u.last_name)::varchar, ir.created_at, ir.acknowledged_at,
         ir.reason, ir.severity
  from incident_reports ir
  join users u on u.id = ir.reporter_student_id
  where (v_actor.role = 'super_admin' or ir.school_id = v_actor.school_id)
    and (p_status is null or ir.status = p_status)
    and (
      v_actor.role in ('school_admin', 'executive', 'super_admin')
      or exists (
        select 1
        from course_teachers ct
        join courses c on c.id = ct.course_id
        left join course_students cst on cst.course_id = c.id
        left join student_profiles sp on sp.student_id = cst.student_id
        where ct.teacher_id = v_actor.user_id
          and (
            cst.student_id = ir.reporter_student_id
            or (ir.room is not null and c.room = ir.room)
            or (ir.room is not null and sp.room = ir.room)
          )
      )
    )
  order by
    case ir.category when 'sos' then 0 else 1 end,
    ir.created_at desc;
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
  if v_actor.role not in ('teacher', 'school_admin', 'executive', 'super_admin') then raise exception 'forbidden'; end if;

  select ir.* into v_incident
  from incident_reports ir
  where ir.id = p_id
    and (v_actor.role = 'super_admin' or ir.school_id = v_actor.school_id)
    and (
      v_actor.role in ('school_admin', 'executive', 'super_admin')
      or exists (
        select 1
        from course_teachers ct
        join courses c on c.id = ct.course_id
        left join course_students cst on cst.course_id = c.id
        left join student_profiles sp on sp.student_id = cst.student_id
        where ct.teacher_id = v_actor.user_id
          and (
            cst.student_id = ir.reporter_student_id
            or (ir.room is not null and c.room = ir.room)
            or (ir.room is not null and sp.room = ir.room)
          )
      )
    );
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
  if v_actor.role not in ('teacher', 'school_admin', 'executive', 'super_admin') then raise exception 'forbidden'; end if;

  select ir.* into v_incident
  from incident_reports ir
  where ir.id = p_id
    and (v_actor.role = 'super_admin' or ir.school_id = v_actor.school_id)
    and (
      v_actor.role in ('school_admin', 'executive', 'super_admin')
      or exists (
        select 1
        from course_teachers ct
        join courses c on c.id = ct.course_id
        left join course_students cst on cst.course_id = c.id
        left join student_profiles sp on sp.student_id = cst.student_id
        where ct.teacher_id = v_actor.user_id
          and (
            cst.student_id = ir.reporter_student_id
            or (ir.room is not null and c.room = ir.room)
            or (ir.room is not null and sp.room = ir.room)
          )
      )
    );
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
  values (p_id, v_actor.user_id, 'close', p_resolution_type::text || ': ' || p_resolution_note);

  insert into audit_logs (school_id, user_id, acted_role, action, entity_type, entity_id, details)
  values (v_actor.school_id, v_actor.user_id, v_actor.role, 'incident.close', 'incident_reports', p_id::text,
          jsonb_build_object('resolution_type', p_resolution_type, 'resolution_note', p_resolution_note));
end;
$$;

grant execute on function list_incident_reports(text, incident_status) to anon, authenticated;
grant execute on function acknowledge_incident_report(text, uuid) to anon, authenticated;
grant execute on function close_incident_report(text, uuid, incident_resolution_type, text) to anon, authenticated;
