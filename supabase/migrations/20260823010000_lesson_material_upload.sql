-- =====================================================================
-- Real file uploads for lesson materials (LRN-2) — mirrors the
-- course-files pattern: the private `lesson-materials` Storage bucket
-- is never touched directly by clients, only via signed URLs minted by
-- service-role Edge Functions (lesson-material-upload /
-- lesson-material-download). lesson_materials.url already exists and
-- stores either an external link (type = 'link', launched directly) or
-- a storage_path for uploaded bytes (type in file/image/video, resolved
-- to a short-lived signed URL on demand).
-- =====================================================================

create or replace function assert_lesson_upload_access(p_token text, p_lesson_id uuid)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_lesson lessons%rowtype;
  v_course courses%rowtype;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role <> 'teacher' then raise exception 'forbidden'; end if;

  select * into v_lesson from lessons where id = p_lesson_id;
  if not found then raise exception 'lesson_not_found'; end if;

  select * into v_course from courses where id = v_lesson.course_id;
  if v_course.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;
  if not exists (
    select 1 from course_teachers ct
    where ct.course_id = v_lesson.course_id and ct.teacher_id = v_actor.user_id
  ) then raise exception 'forbidden'; end if;
end;
$$;

create or replace function get_lesson_material_for_download(p_token text, p_material_id uuid)
returns table (storage_path text, file_name varchar)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_material lesson_materials%rowtype;
  v_lesson lessons%rowtype;
  v_course courses%rowtype;
  v_is_member boolean := false;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;

  select * into v_material from lesson_materials where id = p_material_id;
  if not found then raise exception 'material_not_found'; end if;
  if v_material.type = 'link' then raise exception 'not_an_uploaded_file'; end if;

  select * into v_lesson from lessons where id = v_material.lesson_id;
  select * into v_course from courses where id = v_lesson.course_id;
  if v_course.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;

  if v_actor.role = 'teacher' then
    v_is_member := exists (
      select 1 from course_teachers ct
      where ct.course_id = v_lesson.course_id and ct.teacher_id = v_actor.user_id
    );
  elsif v_actor.role = 'student' then
    v_is_member := v_lesson.status = 'published' and exists (
      select 1 from course_students cs
      where cs.course_id = v_lesson.course_id and cs.student_id = v_actor.user_id
    );
  elsif v_actor.role = 'school_admin' then
    v_is_member := true;
  end if;
  if not v_is_member then raise exception 'forbidden'; end if;

  return query select v_material.url::text, coalesce(v_material.title, 'ไฟล์แนบ')::varchar;
end;
$$;

revoke all on function assert_lesson_upload_access(text, uuid) from public;
revoke all on function get_lesson_material_for_download(text, uuid) from public;

grant execute on function assert_lesson_upload_access(text, uuid) to service_role;
grant execute on function get_lesson_material_for_download(text, uuid) to anon, authenticated, service_role;
