-- 20260920020000_sensor_history_downsample.sql
-- sensor_history returned every raw reading; PostgREST then silently cut the
-- result at its 1,000-row default. Seen 2026-09-20 on the iPhone against
-- prod: a dataset pinned for 30 days rendered as 49 minutes of 29 Aug
-- (1,000 rows at ~3 s each). Now the RPC buckets by time so the result
-- never exceeds p_max_points, and the bucket width follows the span of the
-- data that actually exists in the window (not the requested window), so a
-- long window over a short burst keeps its resolution.
-- Callers that pass the old five args get the same signature with
-- p_max_points defaulting to 1000.

DROP FUNCTION IF EXISTS public.sensor_history(text, uuid, metric_type, timestamptz, timestamptz);

CREATE OR REPLACE FUNCTION public.sensor_history(
  p_token text,
  p_device_id uuid,
  p_metric metric_type,
  p_from timestamp with time zone,
  p_to timestamp with time zone DEFAULT NULL::timestamp with time zone,
  p_max_points integer DEFAULT 1000
)
RETURNS TABLE(ts timestamp with time zone, value numeric)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
declare
  v_actor record;
  v_device record;
  v_to_ts timestamptz;
  v_first timestamptz;
  v_last timestamptz;
  v_count bigint;
  v_max int := greatest(coalesce(p_max_points, 1000), 10);
  v_bucket double precision;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;

  if v_actor.role not in ('school_admin', 'teacher', 'executive', 'student', 'super_admin') then
    raise exception 'forbidden';
  end if;

  select * into v_device from devices where id = p_device_id;
  if not found then raise exception 'device_not_found'; end if;
  if v_actor.role <> 'super_admin' and v_device.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;

  v_to_ts := coalesce(p_to, now());

  select min(r.ts), max(r.ts), count(*) into v_first, v_last, v_count
  from sensor_readings r
  where r.device_id = p_device_id
    and r.metric = p_metric
    and r.ts >= p_from
    and r.ts <= v_to_ts;

  if v_count = 0 then
    return;
  end if;

  if v_count <= v_max then
    return query
    select r.ts, r.value
    from sensor_readings r
    where r.device_id = p_device_id
      and r.metric = p_metric
      and r.ts >= p_from
      and r.ts <= v_to_ts
    order by r.ts asc;
    return;
  end if;

  -- bucket width in seconds, from the span of the data present. The span
  -- covers v_max - 1 intervals between v_max points (the last reading would
  -- otherwise open a bucket of its own and give v_max + 1 rows).
  v_bucket := greatest(1.0, extract(epoch from (v_last - v_first)) / (v_max - 1));

  return query
  select
    to_timestamp(floor(extract(epoch from r.ts) / v_bucket) * v_bucket) as ts,
    round(avg(r.value), 2) as value
  from sensor_readings r
  where r.device_id = p_device_id
    and r.metric = p_metric
    and r.ts >= p_from
    and r.ts <= v_to_ts
  group by 1
  order by 1 asc;
end;
$$;

REVOKE ALL ON FUNCTION public.sensor_history(text, uuid, metric_type, timestamptz, timestamptz, integer) FROM public;
GRANT EXECUTE ON FUNCTION public.sensor_history(text, uuid, metric_type, timestamptz, timestamptz, integer) TO anon, authenticated;
