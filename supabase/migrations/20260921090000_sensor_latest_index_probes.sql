-- Keep the existing token/role/school boundary and result signature.
-- Probe the existing (device_id, metric, ts) primary key backwards once per
-- device/metric instead of sorting the entire reading history on every poll.
create or replace function public.sensor_latest(
  p_token text, p_device_id uuid default null
)
returns table (
  device_id uuid, device_name varchar, location varchar,
  metric public.metric_type, ts timestamptz, value numeric
)
language plpgsql security definer
set search_path = public, extensions
as $function$
declare
  v_actor record;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then
    raise exception 'invalid_session';
  end if;
  if v_actor.role not in (
    'super_admin', 'school_admin', 'teacher', 'executive', 'student', 'parent'
  ) then
    raise exception 'forbidden';
  end if;

  return query
    select d.id, d.name, d.location, m.metric, r.ts, r.value
    from devices d
    cross join unnest(enum_range(null::public.metric_type)) as m(metric)
    cross join lateral (
      select s.ts, s.value from sensor_readings s
      where s.device_id = d.id and s.metric = m.metric
      order by s.ts desc
      limit 1
    ) r
    where (v_actor.role = 'super_admin'
      or d.school_id is not distinct from v_actor.school_id)
      and (p_device_id is null or d.id = p_device_id)
    order by d.id, m.metric;
end;
$function$;
