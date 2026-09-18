-- PBL-7: charts (2026-09-18)
--
-- The charts table has existed since the initial schema (it stores the
-- query — device / metric / window — never raw numbers: BR1) but had no
-- RPC at all, so no client could create or list a chart.
--
-- Read scope follows sensor_history (20260721020400): a student may only
-- read windows that a published lesson link or an assignment dataset in
-- one of their courses covers. create_chart re-checks that server-side, so
-- a saved chart can never widen what the student could read anyway.
--
--   list_my_sensor_datasets  what this user may chart (student: lesson links
--                            + assignment datasets of enrolled courses;
--                            teacher: those of courses they teach)
--   create_chart             save a chart query (window validated)
--   list_my_charts           own charts, with device name
--   delete_chart             own charts only

-- ── helper: the same permission sensor_history applies to students ─────
create or replace function student_sensor_window_allowed(
  p_student_id uuid,
  p_device_id uuid,
  p_metric metric_type,
  p_from timestamptz,
  p_to timestamptz
)
returns boolean
language sql
stable
security definer
set search_path = public, extensions
as $$
  select exists (
    select 1
    from course_students cs
    join lessons l on l.course_id = cs.course_id and l.status = 'published'
    join lesson_sensor_links lsl on lsl.lesson_id = l.id
    where cs.student_id = p_student_id
      and lsl.device_id = p_device_id
      and lsl.metric = p_metric
      and p_from >= coalesce(lsl.time_start, p_from)
      and p_to <= coalesce(lsl.time_end, p_to)
    union all
    select 1
    from course_students cs
    join assignments a on a.course_id = cs.course_id
    join assignment_sensor_datasets asd on asd.assignment_id = a.id
    where cs.student_id = p_student_id
      and asd.device_id = p_device_id
      and asd.metric = p_metric
      and p_from >= coalesce(asd.time_start, p_from)
      and p_to <= coalesce(asd.time_end, p_to)
  );
$$;
revoke all on function student_sensor_window_allowed(uuid, uuid, metric_type, timestamptz, timestamptz) from public;

-- ── what the user may chart ─────────────────────────────────────────────
create or replace function list_my_sensor_datasets(p_token text)
returns table (
  source text,
  source_id uuid,
  source_title varchar,
  course_id uuid,
  device_id uuid,
  device_name varchar,
  location varchar,
  metric metric_type,
  time_start timestamptz,
  time_end timestamptz,
  label text
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

  if v_actor.role = 'student' then
    return query
    select 'assignment'::text, a.id, a.title, a.course_id, asd.device_id, d.name, d.location,
           asd.metric, asd.time_start, asd.time_end, asd.label::text
    from course_students cs
    join assignments a on a.course_id = cs.course_id and a.status = 'published'
    join assignment_sensor_datasets asd on asd.assignment_id = a.id
    join devices d on d.id = asd.device_id
    where cs.student_id = v_actor.user_id
    union all
    select 'lesson'::text, l.id, l.title, l.course_id, lsl.device_id, d.name, d.location,
           lsl.metric, lsl.time_start, lsl.time_end, lsl.caption::text
    from course_students cs
    join lessons l on l.course_id = cs.course_id and l.status = 'published'
    join lesson_sensor_links lsl on lsl.lesson_id = l.id
    join devices d on d.id = lsl.device_id
    where cs.student_id = v_actor.user_id
    order by 3, 8;
  elsif v_actor.role = 'teacher' then
    return query
    select 'assignment'::text, a.id, a.title, a.course_id, asd.device_id, d.name, d.location,
           asd.metric, asd.time_start, asd.time_end, asd.label::text
    from course_teachers ct
    join assignments a on a.course_id = ct.course_id
    join assignment_sensor_datasets asd on asd.assignment_id = a.id
    join devices d on d.id = asd.device_id
    where ct.teacher_id = v_actor.user_id
    union all
    select 'lesson'::text, l.id, l.title, l.course_id, lsl.device_id, d.name, d.location,
           lsl.metric, lsl.time_start, lsl.time_end, lsl.caption::text
    from course_teachers ct
    join lessons l on l.course_id = ct.course_id
    join lesson_sensor_links lsl on lsl.lesson_id = l.id
    join devices d on d.id = lsl.device_id
    where ct.teacher_id = v_actor.user_id
    order by 3, 8;
  else
    raise exception 'forbidden';
  end if;
end;
$$;
revoke all on function list_my_sensor_datasets(text) from public;
grant execute on function list_my_sensor_datasets(text) to anon, authenticated;

-- ── create ──────────────────────────────────────────────────────────────
create or replace function create_chart(
  p_token text,
  p_device_id uuid,
  p_metric metric_type,
  p_time_start timestamptz,
  p_time_end timestamptz,
  p_chart_type chart_type default 'line',
  p_course_id uuid default null,
  p_annotation text default null
)
returns uuid
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_device devices%rowtype;
  v_id uuid;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('student', 'teacher') then raise exception 'forbidden'; end if;

  if p_time_start is null or p_time_end is null or p_time_start >= p_time_end then
    raise exception 'invalid_time_range';
  end if;

  select * into v_device from devices where id = p_device_id;
  if not found then raise exception 'device_not_found'; end if;
  if v_device.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;

  if v_actor.role = 'student'
     and not student_sensor_window_allowed(v_actor.user_id, p_device_id, p_metric, p_time_start, p_time_end) then
    raise exception 'learning_dataset_required';
  end if;

  if p_course_id is not null and not exists (
    select 1 from course_students cs where cs.course_id = p_course_id and cs.student_id = v_actor.user_id
    union all
    select 1 from course_teachers ct where ct.course_id = p_course_id and ct.teacher_id = v_actor.user_id
  ) then
    raise exception 'forbidden';
  end if;

  insert into charts (created_by, course_id, chart_type, device_id, metric, time_start, time_end, annotation)
  values (v_actor.user_id, p_course_id, p_chart_type, p_device_id, p_metric, p_time_start, p_time_end, nullif(trim(coalesce(p_annotation, '')), ''))
  returning id into v_id;

  return v_id;
end;
$$;
revoke all on function create_chart(text, uuid, metric_type, timestamptz, timestamptz, chart_type, uuid, text) from public;
grant execute on function create_chart(text, uuid, metric_type, timestamptz, timestamptz, chart_type, uuid, text) to anon, authenticated;

-- ── list own ─────────────────────────────────────────────────────────────
create or replace function list_my_charts(p_token text)
returns table (
  id uuid,
  course_id uuid,
  chart_type chart_type,
  device_id uuid,
  device_name varchar,
  location varchar,
  metric metric_type,
  time_start timestamptz,
  time_end timestamptz,
  annotation text,
  created_at timestamptz
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

  return query
  select c.id, c.course_id, c.chart_type, c.device_id, d.name, d.location,
         c.metric, c.time_start, c.time_end, c.annotation, c.created_at
  from charts c
  join devices d on d.id = c.device_id
  where c.created_by = v_actor.user_id
  order by c.created_at desc;
end;
$$;
revoke all on function list_my_charts(text) from public;
grant execute on function list_my_charts(text) to anon, authenticated;

-- ── delete own ───────────────────────────────────────────────────────────
create or replace function delete_chart(p_token text, p_chart_id uuid)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_chart charts%rowtype;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;

  select * into v_chart from charts where id = p_chart_id;
  if not found then raise exception 'chart_not_found'; end if;
  if v_chart.created_by <> v_actor.user_id then raise exception 'forbidden'; end if;

  delete from charts where id = p_chart_id;
end;
$$;
revoke all on function delete_chart(text, uuid) from public;
grant execute on function delete_chart(text, uuid) to anon, authenticated;
