-- =====================================================================
-- Classroom & Learning — Slice 1 (MVP §2.2 core): course + lesson CRUD,
-- enrollment, publish/visibility, AIoT sensor-linked lessons, and
-- per-student progress. Tables already exist from
-- 20260715000000_initial_schema.sql; this migration is purely the
-- RPC surface (the RLS lockdown revoked all direct table access).
--
-- Deferred to a later migration: CLS-5 (grouping) and CLS-8 (close
-- course) — both depend on grading/CoI, which doesn't exist yet.
-- =====================================================================

create or replace function find_student_by_email(p_token text, p_email text)
returns table (
  student_id uuid,
  first_name varchar,
  last_name varchar,
  email varchar
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
  if v_actor.role not in ('teacher', 'school_admin') then
    raise exception 'forbidden';
  end if;

  return query
  select u.id, u.first_name, u.last_name, u.email
  from users u
  join user_roles ur on ur.user_id = u.id
  where u.school_id = v_actor.school_id
    and ur.role = 'student'
    and lower(u.email) = lower(trim(p_email));
end;
$$;

create or replace function list_school_devices(p_token text)
returns table (
  device_id uuid,
  name varchar,
  type device_type,
  location varchar,
  status device_status
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
  if v_actor.role not in ('teacher', 'school_admin') then
    raise exception 'forbidden';
  end if;

  return query
  select d.id, d.name, d.type, d.location, d.status
  from devices d
  where d.school_id = v_actor.school_id
  order by d.location, d.name;
end;
$$;

create or replace function list_terms(p_token text)
returns table (
  term_id uuid,
  term_name varchar,
  academic_year_name varchar,
  start_date date,
  end_date date
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
  if v_actor.role not in ('teacher', 'school_admin') then
    raise exception 'forbidden';
  end if;

  return query
  select t.id, t.name, ay.name, t.start_date, t.end_date
  from terms t
  join academic_years ay on ay.id = t.academic_year_id
  where ay.school_id = v_actor.school_id
  order by t.start_date desc nulls last;
end;
$$;

create or replace function create_course(
  p_token text,
  p_term_id uuid,
  p_subject_name text,
  p_grade_level text default null,
  p_room text default null,
  p_description text default null,
  p_teacher_id uuid default null
)
returns table (course_id uuid)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_teacher_id uuid;
  v_course_id uuid;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('teacher', 'school_admin') then
    raise exception 'forbidden';
  end if;

  if not exists (
    select 1 from terms t
    join academic_years ay on ay.id = t.academic_year_id
    where t.id = p_term_id and ay.school_id = v_actor.school_id
  ) then
    raise exception 'term_not_found';
  end if;

  if v_actor.role = 'teacher' then
    v_teacher_id := v_actor.user_id;
  else
    v_teacher_id := p_teacher_id;
  end if;

  if trim(coalesce(p_subject_name, '')) = '' then
    raise exception 'subject_name_required';
  end if;

  insert into courses (
    school_id, term_id, subject_name, grade_level, room, description, created_by
  ) values (
    v_actor.school_id, p_term_id, trim(p_subject_name), p_grade_level, p_room,
    p_description, v_actor.user_id
  )
  returning id into v_course_id;

  if v_teacher_id is not null then
    insert into course_teachers (course_id, teacher_id, is_owner)
    values (v_course_id, v_teacher_id, true);
  end if;

  insert into audit_logs (school_id, user_id, acted_role, action, entity_type, entity_id)
  values (v_actor.school_id, v_actor.user_id, v_actor.role, 'classroom.course_created', 'courses', v_course_id::text);

  return query select v_course_id;
end;
$$;

create or replace function update_course(
  p_token text,
  p_course_id uuid,
  p_subject_name text default null,
  p_grade_level text default null,
  p_room text default null,
  p_description text default null
)
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
  elsif v_actor.role <> 'school_admin' then
    raise exception 'forbidden';
  end if;

  update courses set
    subject_name = coalesce(trim(p_subject_name), subject_name),
    grade_level = coalesce(p_grade_level, grade_level),
    room = coalesce(p_room, room),
    description = coalesce(p_description, description)
  where id = p_course_id;
end;
$$;

create or replace function list_my_courses(p_token text)
returns table (
  course_id uuid,
  subject_name varchar,
  grade_level varchar,
  room varchar,
  status course_status,
  term_id uuid
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

  if v_actor.role = 'teacher' then
    return query
    select c.id, c.subject_name, c.grade_level, c.room, c.status, c.term_id
    from courses c
    join course_teachers ct on ct.course_id = c.id
    where ct.teacher_id = v_actor.user_id and c.school_id = v_actor.school_id
    order by c.created_at desc;
  elsif v_actor.role = 'student' then
    return query
    select c.id, c.subject_name, c.grade_level, c.room, c.status, c.term_id
    from courses c
    join course_students cs on cs.course_id = c.id
    where cs.student_id = v_actor.user_id and c.school_id = v_actor.school_id
    order by c.created_at desc;
  elsif v_actor.role = 'school_admin' then
    return query
    select c.id, c.subject_name, c.grade_level, c.room, c.status, c.term_id
    from courses c
    where c.school_id = v_actor.school_id
    order by c.created_at desc;
  else
    raise exception 'forbidden';
  end if;
end;
$$;

create or replace function get_course(p_token text, p_course_id uuid)
returns table (
  course_id uuid,
  subject_name varchar,
  grade_level varchar,
  room varchar,
  description text,
  status course_status,
  term_id uuid
)
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

  select * into v_course from courses where id = p_course_id;
  if not found then raise exception 'course_not_found'; end if;
  if v_course.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;

  if v_actor.role = 'teacher' and not exists (
    select 1 from course_teachers ct
    where ct.course_id = p_course_id and ct.teacher_id = v_actor.user_id
  ) then raise exception 'forbidden';
  elsif v_actor.role = 'student' and not exists (
    select 1 from course_students cs
    where cs.course_id = p_course_id and cs.student_id = v_actor.user_id
  ) then raise exception 'forbidden';
  elsif v_actor.role not in ('teacher', 'student', 'school_admin') then
    raise exception 'forbidden';
  end if;

  return query
  select v_course.id, v_course.subject_name, v_course.grade_level, v_course.room,
         v_course.description, v_course.status, v_course.term_id;
end;
$$;

create or replace function list_course_students(p_token text, p_course_id uuid)
returns table (
  student_id uuid,
  first_name varchar,
  last_name varchar,
  email varchar,
  enrolled_at timestamptz
)
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

  select * into v_course from courses where id = p_course_id;
  if not found then raise exception 'course_not_found'; end if;
  if v_course.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;

  if v_actor.role = 'teacher' and not exists (
    select 1 from course_teachers ct
    where ct.course_id = p_course_id and ct.teacher_id = v_actor.user_id
  ) then raise exception 'forbidden';
  elsif v_actor.role not in ('teacher', 'school_admin') then
    raise exception 'forbidden';
  end if;

  return query
  select u.id, u.first_name, u.last_name, u.email, cs.enrolled_at
  from course_students cs
  join users u on u.id = cs.student_id
  where cs.course_id = p_course_id
  order by u.first_name, u.last_name;
end;
$$;

create or replace function enroll_student(
  p_token text,
  p_course_id uuid,
  p_student_id uuid
)
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
  elsif v_actor.role <> 'school_admin' then
    raise exception 'forbidden';
  end if;

  if not exists (
    select 1 from user_roles ur
    where ur.user_id = p_student_id
      and ur.role = 'student'
      and ur.school_id = v_actor.school_id
  ) then
    raise exception 'student_not_found';
  end if;

  insert into course_students (course_id, student_id, enrolled_by)
  values (p_course_id, p_student_id, v_actor.user_id)
  on conflict (course_id, student_id) do nothing;
end;
$$;

create or replace function remove_student_from_course(
  p_token text,
  p_course_id uuid,
  p_student_id uuid
)
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
  elsif v_actor.role <> 'school_admin' then
    raise exception 'forbidden';
  end if;

  delete from course_students
  where course_id = p_course_id and student_id = p_student_id;
end;
$$;

create or replace function create_lesson(
  p_token text,
  p_course_id uuid,
  p_title text,
  p_content jsonb default null
)
returns table (lesson_id uuid)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_course courses%rowtype;
  v_lesson_id uuid;
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

  insert into lessons (course_id, title, content, created_by)
  values (p_course_id, trim(p_title), p_content, v_actor.user_id)
  returning id into v_lesson_id;

  return query select v_lesson_id;
end;
$$;

create or replace function update_lesson(
  p_token text,
  p_lesson_id uuid,
  p_title text default null,
  p_content jsonb default null
)
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

  update lessons set
    title = coalesce(trim(p_title), title),
    content = coalesce(p_content, content),
    updated_at = now()
  where id = p_lesson_id;
end;
$$;

create or replace function publish_lesson(p_token text, p_lesson_id uuid)
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

  update lessons set status = 'published', published_at = now(), updated_at = now()
  where id = p_lesson_id;
end;
$$;

create or replace function add_lesson_material(
  p_token text,
  p_lesson_id uuid,
  p_type material_type,
  p_title text,
  p_url text,
  p_sort_order int default 0
)
returns table (material_id uuid)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_lesson lessons%rowtype;
  v_course courses%rowtype;
  v_material_id uuid;
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

  if trim(coalesce(p_url, '')) = '' then
    raise exception 'material_url_required';
  end if;

  insert into lesson_materials (lesson_id, type, title, url, sort_order)
  values (p_lesson_id, p_type, p_title, trim(p_url), p_sort_order)
  returning id into v_material_id;

  return query select v_material_id;
end;
$$;

create or replace function link_lesson_sensor(
  p_token text,
  p_lesson_id uuid,
  p_device_id uuid,
  p_metric metric_type,
  p_time_start timestamptz default null,
  p_time_end timestamptz default null,
  p_caption text default null
)
returns table (link_id uuid)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_lesson lessons%rowtype;
  v_course courses%rowtype;
  v_device devices%rowtype;
  v_link_id uuid;
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

  select * into v_device from devices where id = p_device_id;
  if not found then raise exception 'device_not_found'; end if;
  if v_device.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;

  insert into lesson_sensor_links (lesson_id, device_id, metric, time_start, time_end, caption)
  values (p_lesson_id, p_device_id, p_metric, p_time_start, p_time_end, p_caption)
  returning id into v_link_id;

  return query select v_link_id;
end;
$$;

create or replace function list_lessons(p_token text, p_course_id uuid)
returns table (
  lesson_id uuid,
  title varchar,
  status lesson_status,
  published_at timestamptz,
  updated_at timestamptz
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_course courses%rowtype;
  v_is_teacher boolean := false;
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
    v_is_teacher := exists (
      select 1 from course_teachers ct
      where ct.course_id = p_course_id and ct.teacher_id = v_actor.user_id
    );
    if not v_is_teacher then raise exception 'forbidden'; end if;
  elsif v_actor.role = 'student' then
    v_is_student := exists (
      select 1 from course_students cs
      where cs.course_id = p_course_id and cs.student_id = v_actor.user_id
    );
    if not v_is_student then raise exception 'forbidden'; end if;
  elsif v_actor.role <> 'school_admin' then
    raise exception 'forbidden';
  end if;

  return query
  select l.id, l.title, l.status, l.published_at, l.updated_at
  from lessons l
  where l.course_id = p_course_id
    and (v_is_student is not true or l.status = 'published')
  order by l.published_at nulls last, l.id;
end;
$$;

create or replace function get_lesson(p_token text, p_lesson_id uuid)
returns table (
  lesson_id uuid,
  course_id uuid,
  title varchar,
  content jsonb,
  status lesson_status,
  published_at timestamptz,
  materials jsonb,
  sensor_links jsonb,
  progress_pct numeric,
  completed boolean
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_lesson lessons%rowtype;
  v_course courses%rowtype;
  v_is_student boolean := false;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;

  select * into v_lesson from lessons where id = p_lesson_id;
  if not found then raise exception 'lesson_not_found'; end if;

  select * into v_course from courses where id = v_lesson.course_id;
  if v_course.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;

  if v_actor.role = 'teacher' then
    if not exists (
      select 1 from course_teachers ct
      where ct.course_id = v_lesson.course_id and ct.teacher_id = v_actor.user_id
    ) then raise exception 'forbidden'; end if;
  elsif v_actor.role = 'student' then
    v_is_student := true;
    if not exists (
      select 1 from course_students cs
      where cs.course_id = v_lesson.course_id and cs.student_id = v_actor.user_id
    ) then raise exception 'forbidden'; end if;
    if v_lesson.status <> 'published' then raise exception 'forbidden'; end if;
  elsif v_actor.role <> 'school_admin' then
    raise exception 'forbidden';
  end if;

  return query
  select
    v_lesson.id,
    v_lesson.course_id,
    v_lesson.title,
    v_lesson.content,
    v_lesson.status,
    v_lesson.published_at,
    coalesce((
      select json_agg(json_build_object(
        'id', lm.id, 'type', lm.type, 'title', lm.title,
        'url', lm.url, 'sort_order', lm.sort_order
      ) order by lm.sort_order)
      from lesson_materials lm where lm.lesson_id = v_lesson.id
    ), '[]'::json)::jsonb,
    coalesce((
      select json_agg(json_build_object(
        'id', lsl.id, 'device_id', lsl.device_id, 'metric', lsl.metric,
        'time_start', lsl.time_start, 'time_end', lsl.time_end, 'caption', lsl.caption
      ))
      from lesson_sensor_links lsl where lsl.lesson_id = v_lesson.id
    ), '[]'::json)::jsonb,
    case when v_is_student then (
      select lp.progress_pct from lesson_progress lp
      where lp.lesson_id = v_lesson.id and lp.student_id = v_actor.user_id
    ) else null end,
    case when v_is_student then coalesce((
      select lp.completed from lesson_progress lp
      where lp.lesson_id = v_lesson.id and lp.student_id = v_actor.user_id
    ), false) else null end;
end;
$$;

create or replace function update_lesson_progress(
  p_token text,
  p_lesson_id uuid,
  p_progress_pct numeric
)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_lesson lessons%rowtype;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role <> 'student' then raise exception 'forbidden'; end if;

  select * into v_lesson from lessons where id = p_lesson_id;
  if not found or v_lesson.status <> 'published' then
    raise exception 'lesson_not_found';
  end if;

  if not exists (
    select 1 from course_students cs
    where cs.course_id = v_lesson.course_id and cs.student_id = v_actor.user_id
  ) then raise exception 'forbidden'; end if;

  if p_progress_pct < 0 or p_progress_pct > 100 then
    raise exception 'invalid_progress';
  end if;

  insert into lesson_progress (lesson_id, student_id, progress_pct, updated_at)
  values (p_lesson_id, v_actor.user_id, p_progress_pct, now())
  on conflict (lesson_id, student_id) do update
  set progress_pct = excluded.progress_pct, updated_at = now();
end;
$$;

create or replace function mark_lesson_complete(p_token text, p_lesson_id uuid)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_lesson lessons%rowtype;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role <> 'student' then raise exception 'forbidden'; end if;

  select * into v_lesson from lessons where id = p_lesson_id;
  if not found or v_lesson.status <> 'published' then
    raise exception 'lesson_not_found';
  end if;

  if not exists (
    select 1 from course_students cs
    where cs.course_id = v_lesson.course_id and cs.student_id = v_actor.user_id
  ) then raise exception 'forbidden'; end if;

  insert into lesson_progress (lesson_id, student_id, progress_pct, completed, completed_at, updated_at)
  values (p_lesson_id, v_actor.user_id, 100, true, now(), now())
  on conflict (lesson_id, student_id) do update
  set progress_pct = 100, completed = true, completed_at = now(), updated_at = now();
end;
$$;

revoke all on function find_student_by_email(text, text) from public;
revoke all on function list_school_devices(text) from public;
revoke all on function list_terms(text) from public;
revoke all on function create_course(text, uuid, text, text, text, text, uuid) from public;
revoke all on function update_course(text, uuid, text, text, text, text) from public;
revoke all on function list_my_courses(text) from public;
revoke all on function get_course(text, uuid) from public;
revoke all on function list_course_students(text, uuid) from public;
revoke all on function enroll_student(text, uuid, uuid) from public;
revoke all on function remove_student_from_course(text, uuid, uuid) from public;
revoke all on function create_lesson(text, uuid, text, jsonb) from public;
revoke all on function update_lesson(text, uuid, text, jsonb) from public;
revoke all on function publish_lesson(text, uuid) from public;
revoke all on function add_lesson_material(text, uuid, material_type, text, text, int) from public;
revoke all on function link_lesson_sensor(text, uuid, uuid, metric_type, timestamptz, timestamptz, text) from public;
revoke all on function list_lessons(text, uuid) from public;
revoke all on function get_lesson(text, uuid) from public;
revoke all on function update_lesson_progress(text, uuid, numeric) from public;
revoke all on function mark_lesson_complete(text, uuid) from public;

grant execute on function find_student_by_email(text, text) to anon, authenticated;
grant execute on function list_school_devices(text) to anon, authenticated;
grant execute on function list_terms(text) to anon, authenticated;
grant execute on function create_course(text, uuid, text, text, text, text, uuid) to anon, authenticated;
grant execute on function update_course(text, uuid, text, text, text, text) to anon, authenticated;
grant execute on function list_my_courses(text) to anon, authenticated;
grant execute on function get_course(text, uuid) to anon, authenticated;
grant execute on function list_course_students(text, uuid) to anon, authenticated;
grant execute on function enroll_student(text, uuid, uuid) to anon, authenticated;
grant execute on function remove_student_from_course(text, uuid, uuid) to anon, authenticated;
grant execute on function create_lesson(text, uuid, text, jsonb) to anon, authenticated;
grant execute on function update_lesson(text, uuid, text, jsonb) to anon, authenticated;
grant execute on function publish_lesson(text, uuid) to anon, authenticated;
grant execute on function add_lesson_material(text, uuid, material_type, text, text, int) to anon, authenticated;
grant execute on function link_lesson_sensor(text, uuid, uuid, metric_type, timestamptz, timestamptz, text) to anon, authenticated;
grant execute on function list_lessons(text, uuid) to anon, authenticated;
grant execute on function get_lesson(text, uuid) to anon, authenticated;
grant execute on function update_lesson_progress(text, uuid, numeric) to anon, authenticated;
grant execute on function mark_lesson_complete(text, uuid) to anon, authenticated;
