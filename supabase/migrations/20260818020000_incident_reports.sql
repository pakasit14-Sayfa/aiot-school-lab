-- =====================================================================
-- แจ้งเหตุฉุกเฉินผ่านแอป (Incident Report) — ตาม UC vault draft:
-- MVP-Planning/emergency-alert-app-proposal-v1.md (Approach A สำหรับขอบเขต
-- ครู) แยก entity เด็ดขาดจาก emergency_events (ปุ่มกายภาพเดิม) —
-- นักเรียนไม่มีสิทธิ์เปิดสัญญาณฉุกเฉินโดยตรงเด็ดขาด ต้องให้ครู/แอดมิน
-- "ยกระดับ" (escalate) เท่านั้นจึงจะสร้างแถวใน emergency_events จริง
-- =====================================================================

create type incident_category as enum ('sos', 'anomaly');
create type incident_status as enum (
  'new', 'acknowledged', 'in_progress', 'escalated', 'resolved', 'cancelled'
);
create type incident_resolution_type as enum ('resolved', 'cancelled');

create table incident_reports (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null,
  reporter_student_id uuid not null,
  category incident_category not null,
  room varchar,
  status incident_status not null default 'new',
  acknowledged_by uuid,
  acknowledged_at timestamptz,
  assigned_to uuid,
  escalated_to_emergency_event_id uuid,
  resolution_type incident_resolution_type,
  resolution_note text,
  closed_by uuid,
  closed_at timestamptz,
  created_at timestamptz not null default now()
);
comment on table incident_reports is 'เหตุที่นักเรียนแจ้งผ่านแอป — แยกจาก emergency_events (ปุ่มกายภาพ) เด็ดขาด เชื่อมกันได้ทางเดียวผ่าน escalated_to_emergency_event_id เมื่อครู/แอดมินยกระดับเท่านั้น';

create table incident_actions (
  id uuid primary key default gen_random_uuid(),
  incident_report_id uuid not null,
  actor_id uuid not null,
  action_type varchar not null,
  note text,
  created_at timestamptz not null default now()
);
comment on table incident_actions is 'Timeline การดำเนินการของแต่ละ incident — action_type: note | assign | status_change';

alter table incident_reports add constraint fk_incident_reports_school foreign key (school_id) references schools(id);
alter table incident_reports add constraint fk_incident_reports_reporter foreign key (reporter_student_id) references users(id);
alter table incident_reports add constraint fk_incident_reports_acknowledged_by foreign key (acknowledged_by) references users(id);
alter table incident_reports add constraint fk_incident_reports_assigned_to foreign key (assigned_to) references users(id);
alter table incident_reports add constraint fk_incident_reports_emergency_event foreign key (escalated_to_emergency_event_id) references emergency_events(id);
alter table incident_reports add constraint fk_incident_reports_closed_by foreign key (closed_by) references users(id);
alter table incident_actions add constraint fk_incident_actions_report foreign key (incident_report_id) references incident_reports(id);
alter table incident_actions add constraint fk_incident_actions_actor foreign key (actor_id) references users(id);

alter table incident_reports enable row level security;
alter table incident_actions enable row level security;

-- ---------------------------------------------------------------------
-- นักเรียน: สร้าง incident + ดูของตัวเอง
-- ---------------------------------------------------------------------

create or replace function get_my_student_room(p_token text)
returns table (room varchar, grade_level varchar)
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
  select sp.room, sp.grade_level
  from student_profiles sp
  where sp.student_id = v_actor.user_id
  order by sp.created_at desc
  limit 1;
end;
$$;

create or replace function create_incident_report(
  p_token text,
  p_category incident_category,
  p_room text default null
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

  insert into incident_reports (school_id, reporter_student_id, category, room, status)
  values (v_actor.school_id, v_actor.user_id, p_category, v_room, 'new')
  returning id into v_incident_id;

  insert into audit_logs (school_id, user_id, acted_role, action, entity_type, entity_id, details)
  values (v_actor.school_id, v_actor.user_id, v_actor.role, 'incident.create', 'incident_reports', v_incident_id::text,
          jsonb_build_object('category', p_category, 'room', v_room));

  select first_name || ' ' || last_name into v_reporter_name from users where id = v_actor.user_id;
  v_title := case p_category when 'sos' then 'แจ้งเหตุฉุกเฉิน (SOS)' else 'แจ้งเหตุผิดปกติ' end;
  v_body := coalesce(v_reporter_name, 'นักเรียน') || ' แจ้งเหตุจากห้อง ' || coalesce(v_room, 'ไม่ระบุ');

  -- Approach A: แจ้งเตือนครูที่สอนวิชาซึ่งมีนักเรียนลงทะเบียนอยู่ในห้อง
  -- เดียวกับที่แจ้งเหตุ (derive จาก course_teachers→course_students→
  -- student_profiles.room แทนการมีตารางเวรแยก)
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
      jsonb_build_object('incident_id', v_incident_id, 'category', p_category, 'room', v_room)
    );
  end loop;

  return query select v_incident_id;
end;
$$;

create or replace function list_my_incident_reports(p_token text)
returns table (
  id uuid,
  category incident_category,
  room varchar,
  status incident_status,
  created_at timestamptz,
  acknowledged_at timestamptz,
  closed_at timestamptz
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
  select ir.id, ir.category, ir.room, ir.status, ir.created_at, ir.acknowledged_at, ir.closed_at
  from incident_reports ir
  where ir.reporter_student_id = v_actor.user_id
  order by ir.created_at desc;
end;
$$;

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
  closed_at timestamptz
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
         ir.created_at, ir.acknowledged_at, ir.closed_at
  from incident_reports ir
  where ir.id = p_id and ir.reporter_student_id = v_actor.user_id;

  if not found then raise exception 'not_found'; end if;
end;
$$;

-- ---------------------------------------------------------------------
-- ครู/แอดมิน: inbox + จัดการเหตุ (ยังไม่มี UI ต่อ — RPC พร้อมสำหรับอนาคต)
-- ขอบเขตครู (Approach A): เห็นเฉพาะ incident ที่ room ตรงกับห้องของ
-- นักเรียนที่ลงทะเบียนในวิชาที่ตนสอน — บล็อกตั้งแต่ระดับ query ไม่ใช่
-- แค่ซ่อนปุ่ม
-- ---------------------------------------------------------------------

create or replace function list_incident_reports(p_token text, p_status incident_status default null)
returns table (
  id uuid,
  category incident_category,
  room varchar,
  status incident_status,
  reporter_name varchar,
  created_at timestamptz,
  acknowledged_at timestamptz
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
  if v_actor.role not in ('teacher', 'school_admin') then raise exception 'forbidden'; end if;

  return query
  select ir.id, ir.category, ir.room, ir.status,
         (u.first_name || ' ' || u.last_name)::varchar, ir.created_at, ir.acknowledged_at
  from incident_reports ir
  join users u on u.id = ir.reporter_student_id
  where ir.school_id = v_actor.school_id
    and (p_status is null or ir.status = p_status)
    and (
      v_actor.role = 'school_admin'
      or exists (
        select 1
        from course_teachers ct
        join course_students cst on cst.course_id = ct.course_id
        join student_profiles sp on sp.student_id = cst.student_id
        where ct.teacher_id = v_actor.user_id and sp.room = ir.room
      )
    )
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
  if v_actor.role not in ('teacher', 'school_admin') then raise exception 'forbidden'; end if;

  select ir.* into v_incident
  from incident_reports ir
  where ir.id = p_id
    and ir.school_id = v_actor.school_id
    and (
      v_actor.role = 'school_admin'
      or exists (
        select 1
        from course_teachers ct
        join course_students cst on cst.course_id = ct.course_id
        join student_profiles sp on sp.student_id = cst.student_id
        where ct.teacher_id = v_actor.user_id and sp.room = ir.room
      )
    );
  if not found then raise exception 'not_found'; end if;

  -- optimistic lock: ครูคนแรกที่ UPDATE สำเร็จเท่านั้นที่ได้สิทธิ์รับเรื่อง
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
  if v_actor.role not in ('teacher', 'school_admin') then raise exception 'forbidden'; end if;

  select ir.* into v_incident
  from incident_reports ir
  where ir.id = p_id
    and ir.school_id = v_actor.school_id
    and (
      v_actor.role = 'school_admin'
      or exists (
        select 1
        from course_teachers ct
        join course_students cst on cst.course_id = ct.course_id
        join student_profiles sp on sp.student_id = cst.student_id
        where ct.teacher_id = v_actor.user_id and sp.room = ir.room
      )
    );
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
  if v_actor.role not in ('teacher', 'school_admin') then raise exception 'forbidden'; end if;

  select ir.* into v_incident
  from incident_reports ir
  where ir.id = p_id
    and ir.school_id = v_actor.school_id
    and (
      v_actor.role = 'school_admin'
      or exists (
        select 1
        from course_teachers ct
        join course_students cst on cst.course_id = ct.course_id
        join student_profiles sp on sp.student_id = cst.student_id
        where ct.teacher_id = v_actor.user_id and sp.room = ir.room
      )
    );
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
  if v_actor.role not in ('teacher', 'school_admin') then raise exception 'forbidden'; end if;

  select ir.* into v_incident
  from incident_reports ir
  where ir.id = p_id
    and ir.school_id = v_actor.school_id
    and (
      v_actor.role = 'school_admin'
      or exists (
        select 1
        from course_teachers ct
        join course_students cst on cst.course_id = ct.course_id
        join student_profiles sp on sp.student_id = cst.student_id
        where ct.teacher_id = v_actor.user_id and sp.room = ir.room
      )
    );
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
  if v_actor.role not in ('teacher', 'school_admin') then raise exception 'forbidden'; end if;

  select ir.* into v_incident
  from incident_reports ir
  where ir.id = p_id
    and ir.school_id = v_actor.school_id
    and (
      v_actor.role = 'school_admin'
      or exists (
        select 1
        from course_teachers ct
        join course_students cst on cst.course_id = ct.course_id
        join student_profiles sp on sp.student_id = cst.student_id
        where ct.teacher_id = v_actor.user_id and sp.room = ir.room
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
  values (p_id, v_actor.user_id, 'status_change', 'closed: ' || p_resolution_type::text);

  insert into audit_logs (school_id, user_id, acted_role, action, entity_type, entity_id, details)
  values (v_actor.school_id, v_actor.user_id, v_actor.role, 'incident.close', 'incident_reports', p_id::text,
          jsonb_build_object('resolution_type', p_resolution_type));
end;
$$;

-- ---------------------------------------------------------------------
-- ผู้บริหาร/ผู้ดูแลอาคาร: สรุปแบบไม่ระบุตัวตน — ห้ามมีชื่อ/ห้อง/รหัส
-- นักเรียนในผลลัพธ์เด็ดขาด (แม้แต่ field เดียว)
-- ---------------------------------------------------------------------

create or replace function get_incident_summary(p_token text)
returns table (
  category incident_category,
  total_count integer,
  avg_response_seconds numeric
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
  if v_actor.role not in ('teacher', 'school_admin', 'executive', 'facility_manager', 'super_admin') then
    raise exception 'forbidden';
  end if;

  return query
  select ir.category, count(*)::integer,
         avg(extract(epoch from (ir.acknowledged_at - ir.created_at)))
  from incident_reports ir
  where v_actor.role = 'super_admin' or ir.school_id = v_actor.school_id
  group by ir.category;
end;
$$;

revoke all on function get_my_student_room(text) from public;
revoke all on function create_incident_report(text, incident_category, text) from public;
revoke all on function list_my_incident_reports(text) from public;
revoke all on function get_incident_report(text, uuid) from public;
revoke all on function list_incident_reports(text, incident_status) from public;
revoke all on function acknowledge_incident_report(text, uuid) from public;
revoke all on function assign_incident_report(text, uuid, uuid) from public;
revoke all on function add_incident_action(text, uuid, text) from public;
revoke all on function escalate_incident_report(text, uuid) from public;
revoke all on function close_incident_report(text, uuid, incident_resolution_type, text) from public;
revoke all on function get_incident_summary(text) from public;

grant execute on function get_my_student_room(text) to anon, authenticated;
grant execute on function create_incident_report(text, incident_category, text) to anon, authenticated;
grant execute on function list_my_incident_reports(text) to anon, authenticated;
grant execute on function get_incident_report(text, uuid) to anon, authenticated;
grant execute on function list_incident_reports(text, incident_status) to anon, authenticated;
grant execute on function acknowledge_incident_report(text, uuid) to anon, authenticated;
grant execute on function assign_incident_report(text, uuid, uuid) to anon, authenticated;
grant execute on function add_incident_action(text, uuid, text) to anon, authenticated;
grant execute on function escalate_incident_report(text, uuid) to anon, authenticated;
grant execute on function close_incident_report(text, uuid, incident_resolution_type, text) to anon, authenticated;
grant execute on function get_incident_summary(text) to anon, authenticated;
