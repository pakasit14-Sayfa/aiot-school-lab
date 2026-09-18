-- PBL-10: group submissions (2026-09-18)
--
-- Found on the owner's review: assignments.is_group and submissions.group_id
-- existed since the initial schema, the teacher editor has a "งานกลุ่ม"
-- toggle, but create_assignment / update_assignment hardcoded is_group =
-- false and submit_assignment only ever wrote student_id. So the toggle was
-- silently discarded and every submission was individual.
--
-- This migration:
--   1. create_assignment / update_assignment accept p_is_group.
--   2. submit_assignment: for a group assignment the submitter's group in
--      that course owns the submission; every member shares one submission
--      row and its versions; on-time G-Score goes to every member.
--   3. list_my_submission_versions: group members see the shared versions.
--   4. list_submissions: returns group_id / group_name so the teacher can
--      tell a group row from an individual one (extra columns only).
-- No policy changes; RLS stays deny-all.

-- ── 1. is_group is settable ──────────────────────────────────────────────
drop function if exists create_assignment(text, uuid, assignment_type, text, text, timestamptz, uuid);
create function create_assignment(
  p_token text,
  p_course_id uuid,
  p_type assignment_type,
  p_title text,
  p_instructions text default null,
  p_due_at timestamptz default null,
  p_rubric_id uuid default null,
  p_is_group boolean default false
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

  insert into assignments (course_id, type, title, instructions, due_at, is_group, rubric_id, created_by)
  values (p_course_id, p_type, trim(p_title), p_instructions, p_due_at, coalesce(p_is_group, false), p_rubric_id, v_actor.user_id)
  returning id into v_assignment_id;

  return query select v_assignment_id;
end;
$$;
revoke all on function create_assignment(text, uuid, assignment_type, text, text, timestamptz, uuid, boolean) from public;
grant execute on function create_assignment(text, uuid, assignment_type, text, text, timestamptz, uuid, boolean) to anon, authenticated;

drop function if exists update_assignment(text, uuid, text, text, timestamptz, uuid);
create function update_assignment(
  p_token text,
  p_assignment_id uuid,
  p_title text default null,
  p_instructions text default null,
  p_due_at timestamptz default null,
  p_rubric_id uuid default null,
  p_is_group boolean default null
)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_assignment assignments%rowtype;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role <> 'teacher' then raise exception 'forbidden'; end if;

  select * into v_assignment from assignments where id = p_assignment_id;
  if not found then raise exception 'assignment_not_found'; end if;

  if not exists (
    select 1 from courses c
    join course_teachers ct on ct.course_id = c.id
    where c.id = v_assignment.course_id
      and c.school_id = v_actor.school_id
      and ct.teacher_id = v_actor.user_id
  ) then raise exception 'forbidden'; end if;

  -- Flipping group-ness after work has been handed in would orphan rows.
  if p_is_group is not null
     and p_is_group is distinct from coalesce(v_assignment.is_group, false)
     and exists (select 1 from submissions s where s.assignment_id = p_assignment_id) then
    raise exception 'has_submissions';
  end if;

  update assignments
  set
    title = case when p_title is not null and trim(p_title) <> '' then trim(p_title) else title end,
    instructions = coalesce(p_instructions, instructions),
    due_at = coalesce(p_due_at, due_at),
    rubric_id = coalesce(p_rubric_id, rubric_id),
    is_group = coalesce(p_is_group, is_group)
  where id = p_assignment_id;
end;
$$;
revoke all on function update_assignment(text, uuid, text, text, timestamptz, uuid, boolean) from public;
grant execute on function update_assignment(text, uuid, text, text, timestamptz, uuid, boolean) to anon, authenticated;

-- ── 2. submit: a group assignment is owned by the submitter's group ──────
create or replace function submit_assignment(p_token text, p_assignment_id uuid, p_content text)
returns table (submission_id uuid, version integer, submission_version_id uuid)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_assignment assignments%rowtype;
  v_submission submissions%rowtype;
  v_group_id uuid;
  v_new_version int;
  v_version_id uuid;
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

  if coalesce(v_assignment.is_group, false) then
    select sg.id into v_group_id
    from student_groups sg
    join group_members gm on gm.group_id = sg.id
    where sg.course_id = v_assignment.course_id and gm.student_id = v_actor.user_id
    limit 1;
    if v_group_id is null then raise exception 'not_in_group'; end if;

    select * into v_submission
    from submissions
    where assignment_id = p_assignment_id and group_id = v_group_id;
  else
    select * into v_submission
    from submissions
    where assignment_id = p_assignment_id and student_id = v_actor.user_id and group_id is null;
  end if;

  if not found then
    -- student_id stays the first submitter so the teacher list's join to
    -- users keeps working; group_id is what identifies a group row.
    insert into submissions (assignment_id, student_id, group_id, status, current_version)
    values (p_assignment_id, v_actor.user_id, v_group_id, 'submitted', 1)
    returning * into v_submission;
    v_new_version := 1;
  else
    v_new_version := v_submission.current_version + 1;
    update submissions
    set current_version = v_new_version, status = 'submitted', submitted_at = now()
    where id = v_submission.id;
  end if;

  insert into submission_versions (submission_id, version, content, submitted_by)
  values (v_submission.id, v_new_version, p_content, v_actor.user_id)
  returning id into v_version_id;

  if v_new_version = 1 and (v_assignment.due_at is null or now() <= v_assignment.due_at) then
    if v_group_id is null then
      insert into g_score_entries (student_id, course_id, source, source_id, points)
      values (v_actor.user_id, v_assignment.course_id, 'assignment_on_time', p_assignment_id, 15)
      on conflict (student_id, source, source_id) do nothing;
    else
      insert into g_score_entries (student_id, course_id, source, source_id, points)
      select gm.student_id, v_assignment.course_id, 'assignment_on_time', p_assignment_id, 15
      from group_members gm where gm.group_id = v_group_id
      on conflict (student_id, source, source_id) do nothing;
    end if;
  end if;

  return query select v_submission.id, v_new_version, v_version_id;
end;
$$;

-- ── 3. members see the shared versions ───────────────────────────────────
create or replace function list_my_submission_versions(p_token text, p_assignment_id uuid)
returns table (
  version integer,
  content text,
  submitted_at timestamp with time zone,
  submission_version_id uuid,
  attachments jsonb
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_assignment assignments%rowtype;
  v_submission submissions%rowtype;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role <> 'student' then raise exception 'forbidden'; end if;

  select * into v_assignment from assignments where id = p_assignment_id;
  if not found then return; end if;

  if coalesce(v_assignment.is_group, false) then
    select s.* into v_submission
    from submissions s
    join group_members gm on gm.group_id = s.group_id
    where s.assignment_id = p_assignment_id and gm.student_id = v_actor.user_id
    limit 1;
  else
    select * into v_submission
    from submissions
    where assignment_id = p_assignment_id and student_id = v_actor.user_id and group_id is null;
  end if;
  if not found then
    return;
  end if;

  return query
  select
    sv.version, sv.content, sv.submitted_at, sv.id,
    coalesce((
      select json_agg(json_build_object('id', a.id, 'file_name', a.file_name))
      from submission_attachments a
      where a.submission_version_id = sv.id and a.type = 'file'
    ), '[]'::json)::jsonb
  from submission_versions sv
  where sv.submission_id = v_submission.id
  order by sv.version desc;
end;
$$;

-- ── 4. the teacher can tell a group row ──────────────────────────────────
drop function if exists list_submissions(text, uuid);
create function list_submissions(p_token text, p_assignment_id uuid)
returns table (
  submission_id uuid,
  student_id uuid,
  student_first_name character varying,
  student_last_name character varying,
  status submission_status,
  current_version integer,
  latest_content text,
  submitted_at timestamp with time zone,
  latest_attachments jsonb,
  group_id uuid,
  group_name character varying
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
    s.submitted_at,
    coalesce((
      select json_agg(json_build_object('id', a.id, 'file_name', a.file_name))
      from submission_versions sv
      join submission_attachments a on a.submission_version_id = sv.id and a.type = 'file'
      where sv.submission_id = s.id and sv.version = s.current_version
    ), '[]'::json)::jsonb,
    s.group_id,
    sg.name
  from submissions s
  join users u on u.id = s.student_id
  left join student_groups sg on sg.id = s.group_id
  where s.assignment_id = p_assignment_id
  order by sg.name nulls last, u.first_name, u.last_name;
end;
$$;
revoke all on function list_submissions(text, uuid) from public;
grant execute on function list_submissions(text, uuid) to anon, authenticated;
