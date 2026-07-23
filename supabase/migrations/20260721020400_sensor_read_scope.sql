-- =====================================================================
-- AIoT read scope (tenant isolation applied to sensor RPCs): current
-- school values for students; building summaries for Facility Manager;
-- raw history only for roles/datasets that allow it.
-- =====================================================================

create or replace function sensor_latest(
  p_token text,
  p_device_id uuid default null
)
returns table (
  device_id uuid,
  device_name varchar,
  location varchar,
  metric metric_type,
  ts timestamptz,
  value numeric
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

  if v_actor.role = 'facility_manager' then
    if p_device_id is not null then raise exception 'summary_only'; end if;
    return query
    select
      null::uuid,
      (coalesce(d.location, 'ไม่ระบุอาคาร') || ' summary')::varchar,
      coalesce(d.location, 'ไม่ระบุอาคาร')::varchar,
      r.metric,
      max(r.ts),
      round(avg(r.value), 4)
    from devices d
    join sensor_readings r on r.device_id = d.id
    where d.school_id = v_actor.school_id
      and r.ts >= now() - interval '15 minutes'
    group by d.location, r.metric
    order by d.location, r.metric;
    return;
  end if;

  if v_actor.role not in (
    'school_admin', 'teacher', 'executive', 'student', 'technician'
  ) then
    raise exception 'forbidden';
  end if;

  return query
  select distinct on (d.id, r.metric)
    d.id, d.name, d.location, r.metric, r.ts, r.value
  from devices d
  join sensor_readings r on r.device_id = d.id
  where d.school_id = v_actor.school_id
    and (p_device_id is null or d.id = p_device_id)
  order by d.id, r.metric, r.ts desc;
end;
$$;

create or replace function sensor_history(
  p_token text,
  p_device_id uuid,
  p_metric metric_type,
  p_from timestamptz,
  p_to timestamptz default null
)
returns table (ts timestamptz, value numeric)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_device devices%rowtype;
  v_to timestamptz := coalesce(p_to, now());
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if p_from >= v_to then raise exception 'invalid_time_range'; end if;

  select * into v_device from devices where id = p_device_id;
  if not found then raise exception 'device_not_found'; end if;
  if v_device.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;

  if v_actor.role = 'student' then
    if not exists (
      select 1
      from course_students cs
      join lessons l on l.course_id = cs.course_id and l.status = 'published'
      join lesson_sensor_links lsl on lsl.lesson_id = l.id
      where cs.student_id = v_actor.user_id
        and lsl.device_id = p_device_id
        and lsl.metric = p_metric
        and p_from >= coalesce(lsl.time_start, p_from)
        and v_to <= coalesce(lsl.time_end, v_to)
      union all
      select 1
      from course_students cs
      join assignments a on a.course_id = cs.course_id
      join assignment_sensor_datasets asd on asd.assignment_id = a.id
      where cs.student_id = v_actor.user_id
        and asd.device_id = p_device_id
        and asd.metric = p_metric
        and p_from >= coalesce(asd.time_start, p_from)
        and v_to <= coalesce(asd.time_end, v_to)
    ) then
      raise exception 'learning_dataset_required';
    end if;
  elsif v_actor.role not in (
    'school_admin', 'teacher', 'executive', 'technician'
  ) then
    raise exception 'forbidden';
  end if;

  return query
  select r.ts, r.value
  from sensor_readings r
  where r.device_id = p_device_id
    and r.metric = p_metric
    and r.ts >= p_from
    and r.ts <= v_to
  order by r.ts
  limit 10000;
end;
$$;

revoke all on function sensor_latest(text, uuid) from public;
revoke all on function sensor_history(text, uuid, metric_type, timestamptz, timestamptz)
  from public;
grant execute on function sensor_latest(text, uuid) to anon, authenticated;
grant execute on function sensor_history(text, uuid, metric_type, timestamptz, timestamptz)
  to anon, authenticated;
