-- =====================================================================
-- Course Files — Slice 5: pure metadata table. The actual bytes live in
-- the private `course-files` Storage bucket; every read/write goes
-- through a signed URL minted by a service-role Edge Function
-- (course-file-upload / course-file-download), never direct client
-- access to the bucket or to storage.objects, matching this project's
-- RPC-only/deny-all philosophy.
-- =====================================================================

create table course_files (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references courses(id),
  uploaded_by uuid not null references users(id),
  storage_path text not null unique,
  file_name varchar not null,
  size_bytes bigint not null,
  created_at timestamptz not null default now()
);

alter table course_files enable row level security;

create or replace function list_course_files(p_token text, p_course_id uuid)
returns table (
  file_id uuid,
  storage_path text,
  file_name varchar,
  size_bytes bigint,
  uploaded_by uuid,
  uploader_first_name varchar,
  uploader_last_name varchar,
  created_at timestamptz
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_course courses%rowtype;
  v_is_member boolean := false;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;

  select * into v_course from courses where id = p_course_id;
  if not found then raise exception 'course_not_found'; end if;
  if v_course.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;

  if v_actor.role = 'teacher' then
    v_is_member := exists (
      select 1 from course_teachers ct
      where ct.course_id = p_course_id and ct.teacher_id = v_actor.user_id
    );
  elsif v_actor.role = 'student' then
    v_is_member := exists (
      select 1 from course_students cs
      where cs.course_id = p_course_id and cs.student_id = v_actor.user_id
    );
  elsif v_actor.role = 'school_admin' then
    v_is_member := true;
  end if;
  if not v_is_member then raise exception 'forbidden'; end if;

  return query
  select
    f.id, f.storage_path, f.file_name, f.size_bytes, f.uploaded_by,
    u.first_name, u.last_name, f.created_at
  from course_files f
  join users u on u.id = f.uploaded_by
  where f.course_id = p_course_id
  order by f.created_at desc;
end;
$$;

create or replace function assert_course_upload_access(p_token text, p_course_id uuid)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_course courses%rowtype;
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
end;
$$;

create or replace function register_course_file(
  p_token text,
  p_course_id uuid,
  p_storage_path text,
  p_file_name text,
  p_size_bytes bigint
)
returns table (file_id uuid)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_file_id uuid;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;

  perform assert_course_upload_access(p_token, p_course_id);

  insert into course_files (course_id, uploaded_by, storage_path, file_name, size_bytes)
  values (p_course_id, v_actor.user_id, p_storage_path, trim(p_file_name), p_size_bytes)
  returning id into v_file_id;

  return query select v_file_id;
end;
$$;

create or replace function get_course_file_for_download(p_token text, p_file_id uuid)
returns table (storage_path text, file_name varchar)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_file course_files%rowtype;
  v_course courses%rowtype;
  v_is_member boolean := false;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;

  select * into v_file from course_files where id = p_file_id;
  if not found then raise exception 'file_not_found'; end if;

  select * into v_course from courses where id = v_file.course_id;
  if v_course.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;

  if v_actor.role = 'teacher' then
    v_is_member := exists (
      select 1 from course_teachers ct
      where ct.course_id = v_file.course_id and ct.teacher_id = v_actor.user_id
    );
  elsif v_actor.role = 'student' then
    v_is_member := exists (
      select 1 from course_students cs
      where cs.course_id = v_file.course_id and cs.student_id = v_actor.user_id
    );
  elsif v_actor.role = 'school_admin' then
    v_is_member := true;
  end if;
  if not v_is_member then raise exception 'forbidden'; end if;

  return query select v_file.storage_path, v_file.file_name;
end;
$$;

revoke all on function list_course_files(text, uuid) from public;
revoke all on function assert_course_upload_access(text, uuid) from public;
revoke all on function register_course_file(text, uuid, text, text, bigint) from public;
revoke all on function get_course_file_for_download(text, uuid) from public;

grant execute on function list_course_files(text, uuid) to anon, authenticated;
grant execute on function register_course_file(text, uuid, text, text, bigint) to anon, authenticated;
grant execute on function get_course_file_for_download(text, uuid) to anon, authenticated;
grant execute on function assert_course_upload_access(text, uuid) to service_role;
