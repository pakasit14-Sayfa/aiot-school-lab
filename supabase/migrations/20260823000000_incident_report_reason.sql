-- =====================================================================
-- Add reason and severity support to incident_reports RPCs (INC-REASON)
-- =====================================================================

alter table incident_reports add column if not exists reason text;
alter table incident_reports add column if not exists severity text;

drop function if exists create_incident_report(text, incident_category, text);
drop function if exists create_incident_report(text, incident_category, text, text, text);

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

  for v_teacher in
    select distinct ct.teacher_id
    from course_teachers ct
    join courses c on c.id = ct.course_id
    join course_students cst on cst.course_id = c.id
    join student_profiles sp on sp.student_id = cst.student_id
    where c.school_id = v_actor.school_id and sp.room = v_room
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

drop function if exists list_my_incident_reports(text);

create or replace function list_my_incident_reports(p_token text)
returns table (
  id uuid,
  category incident_category,
  room varchar,
  status incident_status,
  created_at timestamptz,
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
  if v_actor.role <> 'student' then raise exception 'forbidden'; end if;

  return query
  select ir.id, ir.category, ir.room, ir.status, ir.created_at, ir.reason, ir.severity
  from incident_reports ir
  where ir.reporter_student_id = v_actor.user_id
  order by ir.created_at desc;
end;
$$;

drop function if exists get_incident_report(text, uuid);

create or replace function get_incident_report(p_token text, p_id uuid)
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
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role <> 'student' then raise exception 'forbidden'; end if;

  return query
  select ir.id, ir.category, ir.room, ir.status, ir.resolution_type, ir.resolution_note,
         ir.created_at, ir.acknowledged_at, ir.closed_at, ir.reason, ir.severity
  from incident_reports ir
  where ir.id = p_id and ir.reporter_student_id = v_actor.user_id;

  if not found then raise exception 'not_found'; end if;
end;
$$;
