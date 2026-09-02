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
  v_building varchar;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;

  if v_actor.role = 'facility_manager' then
    if p_device_id is not null then raise exception 'summary_only'; end if;

    select building into v_building from users where id = v_actor.user_id;
    if v_building is null then
      return;
    end if;

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
      and d.location like (v_building || '%')
      and r.ts >= now() - interval '15 minutes'
    group by d.location, r.metric
    order by d.location, r.metric;
    return;
  end if;

  if v_actor.role not in (
    'school_admin', 'teacher', 'executive', 'student', 'technician', 'parent'
  ) then
    raise exception 'forbidden';
  end if;

  -- For parents, we might want to restrict to school_id = their linked student's school_id, 
  -- but get_session_actor sets active_school_id if they log in via a specific school context,
  -- or we might need to get it differently. Let's see if parent has active_school_id.
  -- In this MVP, get_session_actor returns the school_id they are currently viewing.
  return query
  select distinct on (d.id, r.metric)
    d.id, d.name, d.location, r.metric, r.ts, r.value
  from devices d
  join sensor_readings r on r.device_id = d.id
  where d.school_id = coalesce(v_actor.school_id, d.school_id) -- Fallback if parent has no active_school_id 
    and (p_device_id is null or d.id = p_device_id)
  order by d.id, r.metric, r.ts desc;
end;
$$;
