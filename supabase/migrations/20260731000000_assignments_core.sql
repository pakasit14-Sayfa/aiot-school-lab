-- =====================================================================
-- Assignments (PBL) — Slice 2: individual assignments only. Group work
-- (CLS-5/PBL-10) and the in-system chart builder (PBL-7) are deferred,
-- same reasoning as Slice 1 deferring CLS-5/CLS-8. Submission content
-- is a single text field; submission_attachments stays unused (the
-- general Files feature, Slice 5, supersedes it).
-- =====================================================================

create or replace function create_assignment(
  p_token text,
  p_course_id uuid,
  p_type assignment_type,
  p_title text,
  p_instructions text default null,
  p_due_at timestamptz default null
)
returns table (assignment_id uuid)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_course courses%rowtype;
  v_assignment_id uuid;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role <> 'teacher' then raise exception 'forbidden'; end if;

  select * into v_course from courses where id = p_course_id;
  if not found then raise exception 'course_not_found'; end if;
  if v_course.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;
  if not exists (
    select 1 from course_teachers ct
    where ct.course_id = p_course_id and ct.teacher_id = v_actor.user_id
  ) then raise exception 'forbidden'; end if;

  if trim(coalesce(p_title, '')) = '' then
    raise exception 'title_required';
  end if;

  insert into assignments (course_id, type, title, instructions, due_at, is_group, created_by)
  values (p_course_id, p_type, trim(p_title), p_instructions, p_due_at, false, v_actor.user_id)
  returning id into v_assignment_id;

  return query select v_assignment_id;
end;
$$;

create or replace function update_assignment(
  p_token text,
  p_assignment_id uuid,
  p_title text default null,
  p_instructions text default null,
  p_due_at timestamptz default null
)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_assignment assignments%rowtype;
  v_course courses%rowtype;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role <> 'teacher' then raise exception 'forbidden'; end if;

  select * into v_assignment from assignments where id = p_assignment_id;
  if not found then raise exception 'assignment_not_found'; end if;

  select * into v_course from courses where id = v_assignment.course_id;
  if v_course.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;
  if not exists (
    select 1 from course_teachers ct
    where ct.course_id = v_assignment.course_id and ct.teacher_id = v_actor.user_id
  ) then raise exception 'forbidden'; end if;

  update assignments set
    title = coalesce(trim(p_title), title),
    instructions = coalesce(p_instructions, instructions),
    due_at = coalesce(p_due_at, due_at)
  where id = p_assignment_id;
end;
$$;

create or replace function publish_assignment(p_token text, p_assignment_id uuid)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_assignment assignments%rowtype;
  v_course courses%rowtype;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role <> 'teacher' then raise exception 'forbidden'; end if;

  select * into v_assignment from assignments where id = p_assignment_id;
  if not found then raise exception 'assignment_not_found'; end if;

  select * into v_course from courses where id = v_assignment.course_id;
  if v_course.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;
  if not exists (
    select 1 from course_teachers ct
    where ct.course_id = v_assignment.course_id and ct.teacher_id = v_actor.user_id
  ) then raise exception 'forbidden'; end if;

  update assignments set status = 'published' where id = p_assignment_id;
end;
$$;

create or replace function link_assignment_sensor_dataset(
  p_token text,
  p_assignment_id uuid,
  p_device_id uuid,
  p_metric metric_type,
  p_time_start timestamptz default null,
  p_time_end timestamptz default null,
  p_label text default null
)
returns table (dataset_id uuid)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_assignment assignments%rowtype;
  v_course courses%rowtype;
  v_device devices%rowtype;
  v_dataset_id uuid;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role <> 'teacher' then raise exception 'forbidden'; end if;

  select * into v_assignment from assignments where id = p_assignment_id;
  if not found then raise exception 'assignment_not_found'; end if;

  select * into v_course from courses where id = v_assignment.course_id;
  if v_course.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;
  if not exists (
    select 1 from course_teachers ct
    where ct.course_id = v_assignment.course_id and ct.teacher_id = v_actor.user_id
  ) then raise exception 'forbidden'; end if;

  select * into v_device from devices where id = p_device_id;
  if not found then raise exception 'device_not_found'; end if;
  if v_device.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;

  insert into assignment_sensor_datasets (assignment_id, device_id, metric, time_start, time_end, label)
  values (p_assignment_id, p_device_id, p_metric, p_time_start, p_time_end, p_label)
  returning id into v_dataset_id;

  return query select v_dataset_id;
end;
$$;

create or replace function list_assignments(p_token text, p_course_id uuid)
returns table (
  assignment_id uuid,
  type assignment_type,
  title varchar,
  due_at timestamptz,
  status publish_status
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_course courses%rowtype;
  v_is_student boolean := false;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;

  select * into v_course from courses where id = p_course_id;
  if not found then raise exception 'course_not_found'; end if;
  if v_course.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;

  if v_actor.role = 'teacher' then
    if not exists (
      select 1 from course_teachers ct
      where ct.course_id = p_course_id and ct.teacher_id = v_actor.user_id
    ) then raise exception 'forbidden'; end if;
  elsif v_actor.role = 'student' then
    v_is_student := true;
    if not exists (
      select 1 from course_students cs
      where cs.course_id = p_course_id and cs.student_id = v_actor.user_id
    ) then raise exception 'forbidden'; end if;
  elsif v_actor.role <> 'school_admin' then
    raise exception 'forbidden';
  end if;

  return query
  select a.id, a.type, a.title, a.due_at, a.status
  from assignments a
  where a.course_id = p_course_id
    and (v_is_student is not true or a.status = 'published')
  order by a.due_at nulls last, a.created_at;
end;
$$;

create or replace function get_assignment(p_token text, p_assignment_id uuid)
returns table (
  assignment_id uuid,
  course_id uuid,
  type assignment_type,
  title varchar,
  instructions text,
  due_at timestamptz,
  status publish_status,
  sensor_datasets jsonb
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_assignment assignments%rowtype;
  v_course courses%rowtype;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;

  select * into v_assignment from assignments where id = p_assignment_id;
  if not found then raise exception 'assignment_not_found'; end if;

  select * into v_course from courses where id = v_assignment.course_id;
  if v_course.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;

  if v_actor.role = 'teacher' then
    if not exists (
      select 1 from course_teachers ct
      where ct.course_id = v_assignment.course_id and ct.teacher_id = v_actor.user_id
    ) then raise exception 'forbidden'; end if;
  elsif v_actor.role = 'student' then
    if not exists (
      select 1 from course_students cs
      where cs.course_id = v_assignment.course_id and cs.student_id = v_actor.user_id
    ) then raise exception 'forbidden'; end if;
    if v_assignment.status <> 'published' then raise exception 'forbidden'; end if;
  elsif v_actor.role <> 'school_admin' then
    raise exception 'forbidden';
  end if;

  return query
  select
    v_assignment.id, v_assignment.course_id, v_assignment.type, v_assignment.title,
    v_assignment.instructions, v_assignment.due_at, v_assignment.status,
    coalesce((
      select json_agg(json_build_object(
        'id', d.id, 'device_id', d.device_id, 'metric', d.metric,
        'time_start', d.time_start, 'time_end', d.time_end, 'label', d.label
      ))
      from assignment_sensor_datasets d where d.assignment_id = v_assignment.id
    ), '[]'::json)::jsonb;
end;
$$;

create or replace function submit_assignment(
  p_token text,
  p_assignment_id uuid,
  p_content text
)
returns table (submission_id uuid, version int)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_assignment assignments%rowtype;
  v_submission submissions%rowtype;
  v_new_version int;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role <> 'student' then raise exception 'forbidden'; end if;

  select * into v_assignment from assignments where id = p_assignment_id;
  if not found or v_assignment.status <> 'published' then
    raise exception 'assignment_not_found';
  end if;

  if not exists (
    select 1 from course_students cs
    where cs.course_id = v_assignment.course_id and cs.student_id = v_actor.user_id
  ) then raise exception 'forbidden'; end if;

  select * into v_submission
  from submissions
  where assignment_id = p_assignment_id and student_id = v_actor.user_id;

  if not found then
    insert into submissions (assignment_id, student_id, status, current_version)
    values (p_assignment_id, v_actor.user_id, 'submitted', 1)
    returning * into v_submission;
    v_new_version := 1;
  else
    v_new_version := v_submission.current_version + 1;
    update submissions
    set current_version = v_new_version, status = 'submitted', submitted_at = now()
    where id = v_submission.id;
  end if;

  insert into submission_versions (submission_id, version, content, submitted_by)
  values (v_submission.id, v_new_version, p_content, v_actor.user_id);

  return query select v_submission.id, v_new_version;
end;
$$;

create or replace function list_my_submission_versions(p_token text, p_assignment_id uuid)
returns table (
  version int,
  content text,
  submitted_at timestamptz
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_submission submissions%rowtype;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role <> 'student' then raise exception 'forbidden'; end if;

  select * into v_submission
  from submissions
  where assignment_id = p_assignment_id and student_id = v_actor.user_id;
  if not found then
    return;
  end if;

  return query
  select sv.version, sv.content, sv.submitted_at
  from submission_versions sv
  where sv.submission_id = v_submission.id
  order by sv.version desc;
end;
$$;

create or replace function list_submissions(p_token text, p_assignment_id uuid)
returns table (
  submission_id uuid,
  student_id uuid,
  student_first_name varchar,
  student_last_name varchar,
  status submission_status,
  current_version int,
  latest_content text,
  submitted_at timestamptz
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_assignment assignments%rowtype;
  v_course courses%rowtype;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;

  select * into v_assignment from assignments where id = p_assignment_id;
  if not found then raise exception 'assignment_not_found'; end if;

  select * into v_course from courses where id = v_assignment.course_id;
  if v_course.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;

  if v_actor.role = 'teacher' then
    if not exists (
      select 1 from course_teachers ct
      where ct.course_id = v_assignment.course_id and ct.teacher_id = v_actor.user_id
    ) then raise exception 'forbidden'; end if;
  elsif v_actor.role <> 'school_admin' then
    raise exception 'forbidden';
  end if;

  return query
  select s.id, s.student_id, u.first_name, u.last_name, s.status, s.current_version,
    (
      select sv.content from submission_versions sv
      where sv.submission_id = s.id and sv.version = s.current_version
    ),
    s.submitted_at
  from submissions s
  join users u on u.id = s.student_id
  where s.assignment_id = p_assignment_id
  order by u.first_name, u.last_name;
end;
$$;

create or replace function give_feedback(
  p_token text,
  p_submission_id uuid,
  p_body text
)
returns table (feedback_id uuid)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_submission submissions%rowtype;
  v_assignment assignments%rowtype;
  v_course courses%rowtype;
  v_feedback_id uuid;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role <> 'teacher' then raise exception 'forbidden'; end if;

  select * into v_submission from submissions where id = p_submission_id;
  if not found then raise exception 'submission_not_found'; end if;

  select * into v_assignment from assignments where id = v_submission.assignment_id;
  select * into v_course from courses where id = v_assignment.course_id;
  if v_course.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;
  if not exists (
    select 1 from course_teachers ct
    where ct.course_id = v_assignment.course_id and ct.teacher_id = v_actor.user_id
  ) then raise exception 'forbidden'; end if;

  if trim(coalesce(p_body, '')) = '' then
    raise exception 'feedback_body_required';
  end if;

  insert into feedbacks (submission_id, author_id, body)
  values (p_submission_id, v_actor.user_id, trim(p_body))
  returning id into v_feedback_id;

  return query select v_feedback_id;
end;
$$;

create or replace function list_feedback(p_token text, p_submission_id uuid)
returns table (
  feedback_id uuid,
  author_first_name varchar,
  author_last_name varchar,
  body text,
  created_at timestamptz
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_submission submissions%rowtype;
  v_assignment assignments%rowtype;
  v_course courses%rowtype;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;

  select * into v_submission from submissions where id = p_submission_id;
  if not found then raise exception 'submission_not_found'; end if;

  select * into v_assignment from assignments where id = v_submission.assignment_id;
  select * into v_course from courses where id = v_assignment.course_id;
  if v_course.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;

  if v_actor.role = 'student' then
    if v_submission.student_id is distinct from v_actor.user_id then
      raise exception 'forbidden';
    end if;
  elsif v_actor.role = 'teacher' then
    if not exists (
      select 1 from course_teachers ct
      where ct.course_id = v_assignment.course_id and ct.teacher_id = v_actor.user_id
    ) then raise exception 'forbidden'; end if;
  elsif v_actor.role <> 'school_admin' then
    raise exception 'forbidden';
  end if;

  return query
  select f.id, u.first_name, u.last_name, f.body, f.created_at
  from feedbacks f
  join users u on u.id = f.author_id
  where f.submission_id = p_submission_id
  order by f.created_at;
end;
$$;

revoke all on function create_assignment(text, uuid, assignment_type, text, text, timestamptz) from public;
revoke all on function update_assignment(text, uuid, text, text, timestamptz) from public;
revoke all on function publish_assignment(text, uuid) from public;
revoke all on function link_assignment_sensor_dataset(text, uuid, uuid, metric_type, timestamptz, timestamptz, text) from public;
revoke all on function list_assignments(text, uuid) from public;
revoke all on function get_assignment(text, uuid) from public;
revoke all on function submit_assignment(text, uuid, text) from public;
revoke all on function list_my_submission_versions(text, uuid) from public;
revoke all on function list_submissions(text, uuid) from public;
revoke all on function give_feedback(text, uuid, text) from public;
revoke all on function list_feedback(text, uuid) from public;

grant execute on function create_assignment(text, uuid, assignment_type, text, text, timestamptz) to anon, authenticated;
grant execute on function update_assignment(text, uuid, text, text, timestamptz) to anon, authenticated;
grant execute on function publish_assignment(text, uuid) to anon, authenticated;
grant execute on function link_assignment_sensor_dataset(text, uuid, uuid, metric_type, timestamptz, timestamptz, text) to anon, authenticated;
grant execute on function list_assignments(text, uuid) to anon, authenticated;
grant execute on function get_assignment(text, uuid) to anon, authenticated;
grant execute on function submit_assignment(text, uuid, text) to anon, authenticated;
grant execute on function list_my_submission_versions(text, uuid) to anon, authenticated;
grant execute on function list_submissions(text, uuid) to anon, authenticated;
grant execute on function give_feedback(text, uuid, text) to anon, authenticated;
grant execute on function list_feedback(text, uuid) to anon, authenticated;
