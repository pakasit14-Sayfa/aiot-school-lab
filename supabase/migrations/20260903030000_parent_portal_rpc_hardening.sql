-- Additive hardening for Parent portal RPCs.
-- This migration intentionally follows the earlier calendar/leave migrations so
-- databases that already recorded those versions receive the corrected
-- signatures, authorization, and deny-all policy state.

set search_path = public, extensions;

-- Custom sessions are authoritative. Remove Supabase Auth policies introduced
-- by an earlier migration; Parent reads stay behind SECURITY DEFINER RPCs.
drop policy if exists "Parents can view attendance of linked students"
  on attendance_records;
drop policy if exists "Parents can view assignments of their linked students courses"
  on assignments;
drop policy if exists "Parents can view submissions of their linked students"
  on submissions;

-- Reconcile the event-type constraint even when the column predated migrations.
alter table school_events
  add column if not exists event_type text not null default 'activity',
  add column if not exists description text;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conrelid = 'public.school_events'::regclass
      and conname = 'school_events_event_type_check'
  ) then
    alter table school_events
      add constraint school_events_event_type_check
      check (event_type in (
        'holiday', 'public_holiday', 'exam', 'activity', 'study'
      )) not valid;
  end if;
end;
$$;

alter table school_events
  validate constraint school_events_event_type_check;

drop function if exists list_my_student_assignments(text, uuid);

create function list_my_student_assignments(
  p_token text,
  p_student_id uuid
)
returns table (
  assignment_id uuid,
  course_name varchar,
  title text,
  due_at timestamptz,
  status text
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
  if v_actor.role <> 'parent' then raise exception 'forbidden'; end if;

  if not exists (
    select 1
    from parent_links pl
    where pl.parent_id = v_actor.user_id
      and pl.student_id = p_student_id
      and pl.status = 'approved'
  ) then
    raise exception 'forbidden';
  end if;

  return query
    select
      a.id,
      c.subject_name::varchar,
      a.title::text,
      a.due_at,
      coalesce(s.status::text, 'pending')
    from assignments a
    join courses c on c.id = a.course_id
    join course_students cs on cs.course_id = c.id
    left join submissions s
      on s.assignment_id = a.id
     and s.student_id = p_student_id
    where cs.student_id = p_student_id
      and a.status = 'published'
    order by a.due_at asc nulls last;
end;
$$;

revoke all on function list_my_student_assignments(text, uuid) from public;
grant execute on function list_my_student_assignments(text, uuid)
  to anon, authenticated;

drop function if exists list_school_events(text);
drop function if exists list_school_events(text, uuid);

create function list_school_events(
  p_token text,
  p_student_id uuid default null
)
returns table (
  event_id uuid,
  title varchar,
  location varchar,
  start_date date
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_school_id uuid;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in (
    'super_admin', 'school_admin', 'executive',
    'teacher', 'student', 'parent'
  ) then
    raise exception 'forbidden';
  end if;

  if v_actor.role = 'parent' then
    if p_student_id is null then raise exception 'student_required'; end if;

    select u.school_id into v_school_id
    from parent_links pl
    join users u on u.id = pl.student_id
    where pl.parent_id = v_actor.user_id
      and pl.student_id = p_student_id
      and pl.status = 'approved';

    if not found then raise exception 'forbidden'; end if;
  else
    v_school_id := v_actor.school_id;
  end if;

  if v_school_id is null then return; end if;

  return query
    select e.id, e.title, e.location, e.start_date
    from school_events e
    where e.school_id = v_school_id
      and e.end_date >= current_date
    order by e.start_date asc
    limit 5;
end;
$$;

revoke all on function list_school_events(text, uuid) from public;
grant execute on function list_school_events(text, uuid)
  to anon, authenticated;

drop function if exists list_calendar_events(text);
drop function if exists list_calendar_events(text, uuid);

create function list_calendar_events(
  p_token text,
  p_student_id uuid default null
)
returns table (
  event_id uuid,
  title varchar,
  description text,
  location varchar,
  start_date date,
  end_date date,
  event_type text
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_school_id uuid;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in (
    'super_admin', 'school_admin', 'executive',
    'teacher', 'student', 'parent'
  ) then
    raise exception 'forbidden';
  end if;

  if v_actor.role = 'parent' then
    if p_student_id is null then raise exception 'student_required'; end if;

    select u.school_id into v_school_id
    from parent_links pl
    join users u on u.id = pl.student_id
    where pl.parent_id = v_actor.user_id
      and pl.student_id = p_student_id
      and pl.status = 'approved';

    if not found then raise exception 'forbidden'; end if;
  else
    v_school_id := v_actor.school_id;
  end if;

  if v_school_id is null then return; end if;

  return query
    select
      e.id,
      e.title,
      e.description,
      e.location,
      e.start_date,
      e.end_date,
      e.event_type
    from school_events e
    where e.school_id = v_school_id
    order by e.start_date asc;
end;
$$;

revoke all on function list_calendar_events(text, uuid) from public;
grant execute on function list_calendar_events(text, uuid)
  to anon, authenticated;

-- Record leave creation and review regardless of which approved RPC performs
-- the write. Direct table access remains denied by RLS and revoked grants.
create or replace function audit_leave_request_change()
returns trigger
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
begin
  if tg_op = 'INSERT' then
    insert into audit_logs (
      school_id, user_id, acted_role, action, entity_type, entity_id, details
    ) values (
      new.school_id,
      new.parent_id,
      'parent',
      'submit_leave_request',
      'leave_request',
      new.id::text,
      jsonb_build_object(
        'student_id', new.student_id,
        'leave_type', new.leave_type,
        'start_date', new.start_date,
        'end_date', new.end_date
      )
    );
  elsif new.status is distinct from old.status then
    insert into audit_logs (
      school_id, user_id, acted_role, action, entity_type, entity_id, details
    ) values (
      new.school_id,
      new.reviewed_by,
      null,
      'review_leave_request',
      'leave_request',
      new.id::text,
      jsonb_build_object(
        'previous_status', old.status,
        'status', new.status,
        'student_id', new.student_id
      )
    );
  end if;

  return new;
end;
$$;

drop trigger if exists trg_audit_leave_request_change on leave_requests;
create trigger trg_audit_leave_request_change
after insert or update of status on leave_requests
for each row execute function audit_leave_request_change();

-- Apply least-privilege execution grants to all Parent leave RPCs.
revoke all on function submit_leave_request(
  text, uuid, text, date, date, text, text
) from public;
revoke all on function list_leave_requests_for_review(text, text) from public;
revoke all on function list_my_leave_requests(text, uuid) from public;
revoke all on function review_leave_request(text, uuid, text, text) from public;
revoke all on function assert_leave_attachment_upload_access(text) from public;
revoke all on function get_leave_attachment_for_download(text, uuid) from public;

grant execute on function submit_leave_request(
  text, uuid, text, date, date, text, text
) to anon, authenticated;
grant execute on function list_leave_requests_for_review(text, text)
  to anon, authenticated;
grant execute on function list_my_leave_requests(text, uuid)
  to anon, authenticated;
grant execute on function review_leave_request(text, uuid, text, text)
  to anon, authenticated;
grant execute on function assert_leave_attachment_upload_access(text)
  to anon, authenticated, service_role;
grant execute on function get_leave_attachment_for_download(text, uuid)
  to anon, authenticated, service_role;

-- Event creation remains the only write path and now records its audit event.
create or replace function create_school_event(
  p_token text,
  p_title varchar,
  p_start_date date,
  p_end_date date default null,
  p_location varchar default null,
  p_description text default null,
  p_event_type text default 'activity'
)
returns uuid
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_id uuid;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('school_admin', 'super_admin') then
    raise exception 'forbidden';
  end if;
  if v_actor.school_id is null then raise exception 'no_active_school'; end if;
  if p_event_type not in (
    'holiday', 'public_holiday', 'exam', 'activity', 'study'
  ) then
    raise exception 'invalid_event_type';
  end if;

  insert into school_events (
    school_id, title, location, start_date, end_date, event_type, description
  ) values (
    v_actor.school_id,
    p_title,
    p_location,
    p_start_date,
    coalesce(p_end_date, p_start_date),
    p_event_type,
    p_description
  )
  returning id into v_id;

  insert into audit_logs (
    school_id, user_id, acted_role, action, entity_type, entity_id, details
  ) values (
    v_actor.school_id,
    v_actor.user_id,
    v_actor.role,
    'create_school_event',
    'school_event',
    v_id::text,
    jsonb_build_object(
      'title', p_title,
      'start_date', p_start_date,
      'end_date', coalesce(p_end_date, p_start_date),
      'event_type', p_event_type
    )
  );

  return v_id;
end;
$$;

revoke all on function create_school_event(
  text, varchar, date, date, varchar, text, text
) from public;
grant execute on function create_school_event(
  text, varchar, date, date, varchar, text, text
) to anon, authenticated;
