-- =====================================================================
-- Real file attachments on assignment submissions. `submission_attachments`
-- already existed in the schema (file_url/dataset_id/chart_id columns)
-- but had zero RPCs touching it — student_assignments_page.dart's submit
-- flow was text-only, no attach button, no upload path at all. Adds the
-- `file` attachment_type path (sensor_dataset/chart stay unwired — a
-- separate AIoT-specific submission mode, out of scope here), mirroring
-- the lesson-material-upload/-download pattern: private Storage bucket
-- `submission-attachments`, signed URLs minted by service-role Edge
-- Functions, never touched directly by clients.
-- =====================================================================

alter table submission_attachments add column file_name varchar;

create or replace function assert_submission_upload_access(p_token text, p_submission_version_id uuid)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_version submission_versions%rowtype;
  v_submission submissions%rowtype;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role <> 'student' then raise exception 'forbidden'; end if;

  select * into v_version from submission_versions where id = p_submission_version_id;
  if not found then raise exception 'submission_version_not_found'; end if;

  select * into v_submission from submissions where id = v_version.submission_id;
  if v_submission.student_id is distinct from v_actor.user_id then
    raise exception 'forbidden';
  end if;
end;
$$;

create or replace function add_submission_attachment(
  p_token text,
  p_submission_version_id uuid,
  p_storage_path varchar,
  p_file_name varchar
)
returns table (attachment_id uuid)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_id uuid;
begin
  perform assert_submission_upload_access(p_token, p_submission_version_id);

  insert into submission_attachments (submission_version_id, type, file_url, file_name)
  values (p_submission_version_id, 'file', p_storage_path, p_file_name)
  returning id into v_id;

  return query select v_id;
end;
$$;

create or replace function get_submission_attachment_for_download(p_token text, p_attachment_id uuid)
returns table (storage_path text, file_name character varying)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_attachment submission_attachments%rowtype;
  v_version submission_versions%rowtype;
  v_submission submissions%rowtype;
  v_assignment assignments%rowtype;
  v_course courses%rowtype;
  v_is_member boolean := false;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;

  select * into v_attachment from submission_attachments where id = p_attachment_id;
  if not found then raise exception 'attachment_not_found'; end if;
  if v_attachment.type <> 'file' then raise exception 'not_an_uploaded_file'; end if;

  select * into v_version from submission_versions where id = v_attachment.submission_version_id;
  select * into v_submission from submissions where id = v_version.submission_id;
  select * into v_assignment from assignments where id = v_submission.assignment_id;
  select * into v_course from courses where id = v_assignment.course_id;
  if v_course.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;

  if v_actor.role = 'student' then
    v_is_member := v_submission.student_id = v_actor.user_id;
  elsif v_actor.role = 'teacher' then
    v_is_member := exists (
      select 1 from course_teachers ct
      where ct.course_id = v_assignment.course_id and ct.teacher_id = v_actor.user_id
    );
  elsif v_actor.role = 'school_admin' then
    v_is_member := true;
  end if;
  if not v_is_member then raise exception 'forbidden'; end if;

  return query
    select v_attachment.file_url::text, coalesce(v_attachment.file_name, 'ไฟล์แนบ')::varchar;
end;
$$;

-- submit_assignment: also return the new submission_version_id so the
-- client can attach files to it right after submitting. Postgres won't
-- let CREATE OR REPLACE change RETURNS TABLE's column set, so drop first.
drop function if exists submit_assignment(text, uuid, text);

create function submit_assignment(p_token text, p_assignment_id uuid, p_content text)
returns table (submission_id uuid, version integer, submission_version_id uuid)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_assignment assignments%rowtype;
  v_submission submissions%rowtype;
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
  values (v_submission.id, v_new_version, p_content, v_actor.user_id)
  returning id into v_version_id;

  if v_new_version = 1 and (v_assignment.due_at is null or now() <= v_assignment.due_at) then
    insert into g_score_entries (student_id, course_id, source, source_id, points)
    values (v_actor.user_id, v_assignment.course_id, 'assignment_on_time', p_assignment_id, 15)
    on conflict (student_id, source, source_id) do nothing;
  end if;

  return query select v_submission.id, v_new_version, v_version_id;
end;
$$;

-- list_my_submission_versions: also return each version's file attachments.
drop function if exists list_my_submission_versions(text, uuid);

create function list_my_submission_versions(p_token text, p_assignment_id uuid)
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

-- list_submissions: also return the latest version's file attachments.
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
  latest_attachments jsonb
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
    ), '[]'::json)::jsonb
  from submissions s
  join users u on u.id = s.student_id
  where s.assignment_id = p_assignment_id
  order by u.first_name, u.last_name;
end;
$$;

revoke all on function assert_submission_upload_access(text, uuid) from public;
revoke all on function add_submission_attachment(text, uuid, varchar, varchar) from public;
revoke all on function get_submission_attachment_for_download(text, uuid) from public;

grant execute on function assert_submission_upload_access(text, uuid) to service_role;
grant execute on function add_submission_attachment(text, uuid, varchar, varchar) to anon, authenticated;
grant execute on function get_submission_attachment_for_download(text, uuid) to anon, authenticated, service_role;
grant execute on function submit_assignment(text, uuid, text) to anon, authenticated;
grant execute on function list_my_submission_versions(text, uuid) to anon, authenticated;
grant execute on function list_submissions(text, uuid) to anon, authenticated;
