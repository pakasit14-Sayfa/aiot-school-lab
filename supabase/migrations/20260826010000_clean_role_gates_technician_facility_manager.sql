-- Migration: 20260826010000_clean_role_gates_technician_facility_manager.sql
-- Description: Part A Checkpoint 2 - Role-gate cleanup: replace all 'technician' and 'facility_manager' literals

-- 1. acknowledge_sensor_alert
CREATE OR REPLACE FUNCTION public.acknowledge_sensor_alert(p_alert_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_alert RECORD;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  SELECT sa.id, sa.status, d.school_id INTO v_alert
  FROM public.sensor_alerts sa
  JOIN public.devices d ON d.id = sa.device_id
  WHERE sa.id = p_alert_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'alert_not_found';
  END IF;

  IF NOT (
    public.is_super_admin()
    OR (
      public.has_role('school_admin')
      AND v_alert.school_id = public.current_user_school_id()
    )
  ) THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  UPDATE public.sensor_alerts
  SET status = 'acknowledged',
      acknowledged_at = NOW(),
      acknowledged_by = auth.uid()
  WHERE id = p_alert_id;

  INSERT INTO public.audit_logs (
    school_id, user_id, acted_role, action, entity_type, entity_id, details
  ) VALUES (
    v_alert.school_id,
    auth.uid(),
    CASE WHEN public.is_super_admin() THEN 'super_admin'::role_type ELSE 'school_admin'::role_type END,
    'alert.acknowledge',
    'sensor_alerts',
    p_alert_id::text,
    jsonb_build_object('acknowledged_status', 'acknowledged')
  );

  RETURN jsonb_build_object(
    'success', true,
    'alert_id', p_alert_id,
    'status', 'acknowledged',
    'acknowledged_at', NOW()
  );
END;
$$;

-- 2. resolve_sensor_alert
CREATE OR REPLACE FUNCTION public.resolve_sensor_alert(p_alert_id uuid, p_note text DEFAULT NULL::text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_alert RECORD;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  SELECT sa.id, sa.status, d.school_id INTO v_alert
  FROM public.sensor_alerts sa
  JOIN public.devices d ON d.id = sa.device_id
  WHERE sa.id = p_alert_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'alert_not_found';
  END IF;

  IF NOT (
    public.is_super_admin()
    OR (
      public.has_role('school_admin')
      AND v_alert.school_id = public.current_user_school_id()
    )
  ) THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  UPDATE public.sensor_alerts
  SET status = 'resolved',
      acknowledged_at = COALESCE(acknowledged_at, NOW()),
      acknowledged_by = COALESCE(acknowledged_by, auth.uid())
  WHERE id = p_alert_id;

  INSERT INTO public.audit_logs (
    school_id, user_id, acted_role, action, entity_type, entity_id, details
  ) VALUES (
    v_alert.school_id,
    auth.uid(),
    CASE WHEN public.is_super_admin() THEN 'super_admin'::role_type ELSE 'school_admin'::role_type END,
    'alert.resolve',
    'sensor_alerts',
    p_alert_id::text,
    jsonb_build_object('note', p_note, 'resolved_status', 'resolved')
  );

  RETURN jsonb_build_object(
    'success', true,
    'alert_id', p_alert_id,
    'status', 'resolved'
  );
END;
$$;

-- 3. create_device_schedule
CREATE OR REPLACE FUNCTION public.create_device_schedule(
  p_token text,
  p_device_id uuid,
  p_label text,
  p_command jsonb,
  p_days_of_week smallint[],
  p_time_of_day time
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_device record;
  v_schedule_id uuid;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  IF v_actor.role NOT IN ('school_admin', 'super_admin') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  SELECT * INTO v_device FROM devices WHERE id = p_device_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'device_not_found';
  END IF;

  IF v_actor.role <> 'super_admin' AND v_device.school_id IS DISTINCT FROM v_actor.school_id THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  INSERT INTO device_schedules (
    device_id, school_id, label, command, days_of_week, time_of_day, created_by
  )
  VALUES (
    p_device_id, v_device.school_id, p_label, p_command, p_days_of_week, p_time_of_day, v_actor.user_id
  )
  RETURNING id INTO v_schedule_id;

  INSERT INTO audit_logs (
    school_id, user_id, acted_role, action, entity_type, entity_id, details
  )
  VALUES (
    v_device.school_id, v_actor.user_id, v_actor.role, 'device_schedule.create', 'device_schedules', v_schedule_id::text,
    jsonb_build_object('device_id', p_device_id, 'command', p_command, 'time_of_day', p_time_of_day)
  );

  RETURN v_schedule_id;
END;
$$;

-- 4. list_device_schedules
CREATE OR REPLACE FUNCTION public.list_device_schedules(
  p_token text,
  p_device_id uuid DEFAULT NULL
)
RETURNS TABLE (
  id uuid,
  device_id uuid,
  device_name varchar,
  device_location varchar,
  school_id uuid,
  label text,
  command jsonb,
  days_of_week smallint[],
  time_of_day time,
  enabled boolean,
  created_by uuid,
  created_at timestamptz,
  last_triggered_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  IF v_actor.role NOT IN ('school_admin', 'super_admin') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  RETURN QUERY
  SELECT
    ds.id,
    ds.device_id,
    d.name AS device_name,
    d.location AS device_location,
    ds.school_id,
    ds.label,
    ds.command,
    ds.days_of_week,
    ds.time_of_day,
    ds.enabled,
    ds.created_by,
    ds.created_at,
    ds.last_triggered_at
  FROM device_schedules ds
  JOIN devices d ON d.id = ds.device_id
  WHERE (v_actor.role = 'super_admin' OR ds.school_id = v_actor.school_id)
    AND (p_device_id IS NULL OR ds.device_id = p_device_id)
  ORDER BY ds.time_of_day ASC, ds.created_at DESC;
END;
$$;

-- 5. toggle_device_schedule
CREATE OR REPLACE FUNCTION public.toggle_device_schedule(
  p_token text,
  p_schedule_id uuid,
  p_enabled boolean
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_sched device_schedules%rowtype;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  IF v_actor.role NOT IN ('school_admin', 'super_admin') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  SELECT * INTO v_sched FROM device_schedules WHERE id = p_schedule_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'schedule_not_found';
  END IF;

  IF v_actor.role <> 'super_admin' AND v_sched.school_id IS DISTINCT FROM v_actor.school_id THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  UPDATE device_schedules
  SET enabled = p_enabled
  WHERE id = p_schedule_id;

  INSERT INTO audit_logs (
    school_id, user_id, acted_role, action, entity_type, entity_id, details
  )
  VALUES (
    v_sched.school_id, v_actor.user_id, v_actor.role, 'device_schedule.toggle', 'device_schedules', p_schedule_id::text,
    jsonb_build_object('enabled', p_enabled)
  );
END;
$$;

-- 6. delete_device_schedule
CREATE OR REPLACE FUNCTION public.delete_device_schedule(
  p_token text,
  p_schedule_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_sched device_schedules%rowtype;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  IF v_actor.role NOT IN ('school_admin', 'super_admin') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  SELECT * INTO v_sched FROM device_schedules WHERE id = p_schedule_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'schedule_not_found';
  END IF;

  IF v_actor.role <> 'super_admin' AND v_sched.school_id IS DISTINCT FROM v_actor.school_id THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  DELETE FROM device_schedules WHERE id = p_schedule_id;

  INSERT INTO audit_logs (
    school_id, user_id, acted_role, action, entity_type, entity_id
  )
  VALUES (
    v_sched.school_id, v_actor.user_id, v_actor.role, 'device_schedule.delete', 'device_schedules', p_schedule_id::text
  );
END;
$$;

-- 7. get_energy_efficiency_score
CREATE OR REPLACE FUNCTION public.get_energy_efficiency_score(p_token text)
RETURNS TABLE(score numeric, label text, current_kwh numeric, previous_kwh numeric)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
declare
  v_actor record;
  v_current numeric;
  v_previous numeric;
  v_score numeric;
  v_label text;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;

  if v_actor.role not in (
    'school_admin', 'teacher', 'executive', 'student', 'super_admin'
  ) then
    raise exception 'forbidden';
  end if;

  select coalesce(sum(sr.value), 0) into v_current
  from devices d
  join sensor_readings sr on sr.device_id = d.id and sr.metric = 'energy_kwh'
  where (v_actor.role = 'super_admin' or d.school_id = v_actor.school_id) and d.type = 'energy_meter'
    and sr.ts >= now() - interval '7 days';

  select coalesce(sum(sr.value), 0) into v_previous
  from devices d
  join sensor_readings sr on sr.device_id = d.id and sr.metric = 'energy_kwh'
  where (v_actor.role = 'super_admin' or d.school_id = v_actor.school_id) and d.type = 'energy_meter'
    and sr.ts >= now() - interval '14 days' and sr.ts < now() - interval '7 days';

  if v_previous <= 0 then
    return query select null::numeric, null::text, v_current, v_previous;
    return;
  end if;

  v_score := greatest(0, least(100, 50 + ((v_previous - v_current) / v_previous * 100)));
  v_label := case
    when v_score >= 70 then 'ดีมาก'
    when v_score >= 50 then 'พอใช้'
    else 'ควรปรับปรุง'
  end;

  return query select round(v_score, 0), v_label, v_current, v_previous;
end;
$$;

-- 8. get_energy_usage_summary
CREATE OR REPLACE FUNCTION public.get_energy_usage_summary(p_token text, p_period text DEFAULT 'month'::text)
RETURNS TABLE(device_count integer, total_kwh numeric, electricity_rate_thb numeric, is_rate_default boolean, estimated_cost_thb numeric, disclaimer text)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
declare
  v_actor record;
  v_start_ts timestamptz;
  v_device_count integer := 0;
  v_total_kwh numeric := 0;
  v_school_rate numeric;
  v_rate numeric := 4.50;
  v_is_default boolean := true;
  v_estimated_cost numeric := 0;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;

  if v_actor.role not in (
    'school_admin', 'teacher', 'executive', 'student', 'super_admin'
  ) then
    raise exception 'forbidden';
  end if;

  if p_period = 'today' or p_period = 'day' then
    v_start_ts := date_trunc('day', now());
  elsif p_period = 'week' then
    v_start_ts := date_trunc('week', now());
  elsif p_period = 'year' then
    v_start_ts := date_trunc('year', now());
  else
    v_start_ts := date_trunc('month', now());
  end if;

  select count(distinct d.id)::integer, coalesce(sum(sr.value), 0)::numeric
  into v_device_count, v_total_kwh
  from devices d
  left join sensor_readings sr on sr.device_id = d.id
    and sr.metric = 'energy_kwh'
    and sr.ts >= v_start_ts
  where (v_actor.role = 'super_admin' or d.school_id = v_actor.school_id)
    and d.type = 'energy_meter';

  select ss.electricity_rate_thb
  into v_school_rate
  from school_settings ss
  where ss.school_id = v_actor.school_id;

  if v_school_rate is not null then
    v_rate := v_school_rate;
    v_is_default := false;
  end if;

  v_estimated_cost := round(v_total_kwh * v_rate, 2);

  return query select
    v_device_count,
    v_total_kwh,
    v_rate,
    v_is_default,
    v_estimated_cost,
    'ค่าบริการประมาณการเพื่อการบริหารจัดการภายใน ไม่ใช่ใบแจ้งหนี้จริงจากผู้ให้บริการ'::text;
end;
$$;

-- 9. get_energy_usage_trend
CREATE OR REPLACE FUNCTION public.get_energy_usage_trend(p_token text, p_days integer DEFAULT 7)
RETURNS TABLE(day date, total_kwh numeric)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
declare
  v_actor record;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;

  if v_actor.role not in (
    'school_admin', 'teacher', 'executive', 'student', 'super_admin'
  ) then
    raise exception 'forbidden';
  end if;

  return query
  select
    date_trunc('day', sr.ts)::date as day,
    round(coalesce(sum(sr.value), 0), 2) as total_kwh
  from devices d
  join sensor_readings sr on sr.device_id = d.id and sr.metric = 'energy_kwh'
  where (v_actor.role = 'super_admin' or d.school_id = v_actor.school_id)
    and d.type = 'energy_meter'
    and sr.ts >= now() - (p_days || ' days')::interval
  group by date_trunc('day', sr.ts)::date
  order by date_trunc('day', sr.ts)::date asc;
end;
$$;

-- 10. get_water_efficiency_score
CREATE OR REPLACE FUNCTION public.get_water_efficiency_score(p_token text)
RETURNS TABLE(score numeric, label text, current_m3 numeric, previous_m3 numeric)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
declare
  v_actor record;
  v_current numeric;
  v_previous numeric;
  v_score numeric;
  v_label text;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;

  if v_actor.role not in (
    'school_admin', 'teacher', 'executive', 'student', 'super_admin'
  ) then
    raise exception 'forbidden';
  end if;

  select coalesce(sum(sr.value), 0) into v_current
  from devices d
  join sensor_readings sr on sr.device_id = d.id and sr.metric = 'water_m3'
  where (v_actor.role = 'super_admin' or d.school_id = v_actor.school_id) and d.type = 'water_meter'
    and sr.ts >= now() - interval '7 days';

  select coalesce(sum(sr.value), 0) into v_previous
  from devices d
  join sensor_readings sr on sr.device_id = d.id and sr.metric = 'water_m3'
  where (v_actor.role = 'super_admin' or d.school_id = v_actor.school_id) and d.type = 'water_meter'
    and sr.ts >= now() - interval '14 days' and sr.ts < now() - interval '7 days';

  if v_previous <= 0 then
    return query select null::numeric, null::text, v_current, v_previous;
    return;
  end if;

  v_score := greatest(0, least(100, 50 + ((v_previous - v_current) / v_previous * 100)));
  v_label := case
    when v_score >= 70 then 'ดีมาก'
    when v_score >= 50 then 'พอใช้'
    else 'ควรปรับปรุง'
  end;

  return query select round(v_score, 0), v_label, v_current, v_previous;
end;
$$;

-- 11. get_water_usage_summary
CREATE OR REPLACE FUNCTION public.get_water_usage_summary(p_token text, p_period text DEFAULT 'month'::text)
RETURNS TABLE(device_count integer, total_m3 numeric, water_rate_thb numeric, is_rate_default boolean, estimated_cost_thb numeric, disclaimer text)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
declare
  v_actor record;
  v_start_ts timestamptz;
  v_device_count integer := 0;
  v_total_m3 numeric := 0;
  v_school_rate numeric;
  v_rate numeric := 18.00;
  v_is_default boolean := true;
  v_estimated_cost numeric := 0;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;

  if v_actor.role not in (
    'school_admin', 'teacher', 'executive', 'student', 'super_admin'
  ) then
    raise exception 'forbidden';
  end if;

  if p_period = 'today' or p_period = 'day' then
    v_start_ts := date_trunc('day', now());
  elsif p_period = 'week' then
    v_start_ts := date_trunc('week', now());
  elsif p_period = 'year' then
    v_start_ts := date_trunc('year', now());
  else
    v_start_ts := date_trunc('month', now());
  end if;

  select count(distinct d.id)::integer, coalesce(sum(sr.value), 0)::numeric
  into v_device_count, v_total_m3
  from devices d
  left join sensor_readings sr on sr.device_id = d.id
    and sr.metric = 'water_m3'
    and sr.ts >= v_start_ts
  where (v_actor.role = 'super_admin' or d.school_id = v_actor.school_id)
    and d.type = 'water_meter';

  select ss.water_rate_thb
  into v_school_rate
  from school_settings ss
  where ss.school_id = v_actor.school_id;

  if v_school_rate is not null then
    v_rate := v_school_rate;
    v_is_default := false;
  end if;

  v_estimated_cost := round(v_total_m3 * v_rate, 2);

  return query select
    v_device_count,
    v_total_m3,
    v_rate,
    v_is_default,
    v_estimated_cost,
    'ค่าบริการประมาณการเพื่อการบริหารจัดการภายใน ไม่ใช่ใบแจ้งหนี้จริงจากผู้ให้บริการ'::text;
end;
$$;

-- 12. get_water_usage_trend
CREATE OR REPLACE FUNCTION public.get_water_usage_trend(p_token text, p_days integer DEFAULT 7)
RETURNS TABLE(day date, total_m3 numeric)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
declare
  v_actor record;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;

  if v_actor.role not in (
    'school_admin', 'teacher', 'executive', 'student', 'super_admin'
  ) then
    raise exception 'forbidden';
  end if;

  return query
  select
    date_trunc('day', sr.ts)::date as day,
    round(coalesce(sum(sr.value), 0), 2) as total_m3
  from devices d
  join sensor_readings sr on sr.device_id = d.id and sr.metric = 'water_m3'
  where (v_actor.role = 'super_admin' or d.school_id = v_actor.school_id)
    and d.type = 'water_meter'
    and sr.ts >= now() - (p_days || ' days')::interval
  group by date_trunc('day', sr.ts)::date
  order by date_trunc('day', sr.ts)::date asc;
end;
$$;

-- 13. get_school_utility_rates
CREATE OR REPLACE FUNCTION public.get_school_utility_rates(p_token text)
RETURNS TABLE(electricity_rate_thb numeric, is_electricity_default boolean, water_rate_thb numeric, is_water_default boolean)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
declare
  v_actor record;
  v_elec numeric;
  v_water numeric;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;

  if v_actor.role not in (
    'school_admin', 'teacher', 'executive', 'student', 'super_admin'
  ) then
    raise exception 'forbidden';
  end if;

  select ss.electricity_rate_thb, ss.water_rate_thb
  into v_elec, v_water
  from school_settings ss
  where ss.school_id = v_actor.school_id;

  return query select
    coalesce(v_elec, 4.50)::numeric as electricity_rate_thb,
    (v_elec is null) as is_electricity_default,
    coalesce(v_water, 18.00)::numeric as water_rate_thb,
    (v_water is null) as is_water_default;
end;
$$;

-- 14. get_incident_summary
CREATE OR REPLACE FUNCTION public.get_incident_summary(p_token text)
RETURNS TABLE(category incident_category, total_count integer, avg_response_seconds numeric)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
declare
  v_actor record;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('teacher', 'school_admin', 'executive', 'super_admin') then
    raise exception 'forbidden';
  end if;

  return query
  select ir.category, count(*)::integer,
         avg(extract(epoch from (ir.acknowledged_at - ir.created_at)))
  from incident_reports ir
  where v_actor.role = 'super_admin' or ir.school_id = v_actor.school_id
  group by ir.category;
end;
$$;

-- 15. grant_camera_access
CREATE OR REPLACE FUNCTION public.grant_camera_access(
  p_token text,
  p_user_id uuid,
  p_camera_device_id uuid DEFAULT NULL::uuid,
  p_reason text DEFAULT ''::text,
  p_valid_until timestamp with time zone DEFAULT (now() + '7 days'::interval)
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor RECORD;
  v_grant_id uuid;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  IF v_actor.role NOT IN ('executive', 'school_admin', 'super_admin') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = p_user_id
      AND school_id = v_actor.school_id
      AND role IN ('teacher', 'school_admin', 'executive', 'super_admin')
  ) THEN
    RAISE EXCEPTION 'user_not_found';
  END IF;

  IF p_camera_device_id IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1 FROM public.devices
      WHERE id = p_camera_device_id AND school_id = v_actor.school_id AND type = 'camera'
    ) THEN
      RAISE EXCEPTION 'camera_not_found';
    END IF;
  END IF;

  IF p_valid_until <= now() THEN
    RAISE EXCEPTION 'invalid_expiry';
  END IF;

  INSERT INTO public.camera_access_grants (
    school_id, user_id, camera_device_id, granted_by, reason, valid_from, valid_until, granted_at
  )
  VALUES (
    v_actor.school_id, p_user_id, p_camera_device_id, v_actor.user_id, p_reason, now(), p_valid_until, now()
  )
  RETURNING id INTO v_grant_id;

  RETURN v_grant_id;
END;
$$;

-- 16. issue_device_token
CREATE OR REPLACE FUNCTION public.issue_device_token(p_token text, p_device_id uuid)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
declare
  v_actor record;
  v_device record;
  v_token text;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then
    raise exception 'invalid_session';
  end if;
  if v_actor.role not in ('school_admin', 'super_admin') then
    raise exception 'forbidden';
  end if;

  select * into v_device from devices where id = p_device_id;
  if not found then
    raise exception 'device_not_found';
  end if;
  if v_actor.role <> 'super_admin' and v_device.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;

  v_token := 'dev_' || encode(gen_random_bytes(24), 'hex');

  update devices
  set token_hash = encode(digest(v_token, 'sha256'), 'hex')
  where id = p_device_id;

  return v_token;
end;
$$;

-- 17. register_device
CREATE OR REPLACE FUNCTION public.register_device(
  p_token text,
  p_type device_type,
  p_name text,
  p_serial_no text DEFAULT NULL::text,
  p_location text DEFAULT NULL::text,
  p_kit_code text DEFAULT NULL::text
)
RETURNS TABLE(device_id uuid, device_token text)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
declare
  v_actor record;
  v_device_token text;
  v_device_id uuid;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then
    raise exception 'invalid_session';
  end if;
  if v_actor.role not in ('school_admin', 'super_admin') then
    raise exception 'forbidden';
  end if;
  if v_actor.school_id is null then
    raise exception 'no_active_school';
  end if;

  v_device_token := 'dev_' || encode(gen_random_bytes(24), 'hex');

  insert into devices (school_id, type, name, serial_no, location, kit_code,
                       registered_by, token_hash)
  values (v_actor.school_id, p_type, p_name, p_serial_no, p_location, p_kit_code,
          v_actor.user_id, encode(digest(v_device_token, 'sha256'), 'hex'))
  returning id into v_device_id;

  return query select v_device_id, v_device_token;
end;
$$;

-- 18. queue_device_command
CREATE OR REPLACE FUNCTION public.queue_device_command(p_token text, p_device_id uuid, p_command jsonb)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
declare
  v_actor record;
  v_device record;
  v_command_id uuid;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then
    raise exception 'invalid_session';
  end if;
  if v_actor.role not in ('school_admin', 'super_admin') then
    raise exception 'forbidden';
  end if;

  select * into v_device from devices where id = p_device_id;
  if not found then
    raise exception 'device_not_found';
  end if;
  if v_actor.role <> 'super_admin' and v_device.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;

  insert into device_commands (device_id, command, created_by)
  values (p_device_id, p_command, v_actor.user_id)
  returning id into v_command_id;

  return v_command_id;
end;
$$;

-- 19. list_devices_in_my_building
CREATE OR REPLACE FUNCTION public.list_devices_in_my_building(p_token text)
RETURNS TABLE(device_id uuid, name character varying, type device_type, location character varying, status device_status)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
declare
  v_actor record;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('school_admin', 'super_admin', 'teacher') then raise exception 'forbidden'; end if;

  return query
  select d.id, d.name, d.type, d.location, d.status
  from devices d
  where (v_actor.role = 'super_admin' or d.school_id = v_actor.school_id)
  order by d.location, d.name;
end;
$$;

-- 20. sensor_history
CREATE OR REPLACE FUNCTION public.sensor_history(
  p_token text,
  p_device_id uuid,
  p_metric metric_type,
  p_from timestamp with time zone,
  p_to timestamp with time zone DEFAULT NULL::timestamp with time zone
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

  return query
  select r.ts, r.value
  from sensor_readings r
  where r.device_id = p_device_id
    and r.metric = p_metric
    and r.ts >= p_from
    and r.ts <= v_to_ts
  order by r.ts asc;
end;
$$;

-- 21. sensor_latest
CREATE OR REPLACE FUNCTION public.sensor_latest(p_token text, p_device_id uuid DEFAULT NULL::uuid)
RETURNS TABLE(device_id uuid, device_name character varying, location character varying, metric metric_type, ts timestamp with time zone, value numeric)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
declare
  v_actor record;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;

  if v_actor.role not in ('school_admin', 'teacher', 'executive', 'student', 'super_admin') then
    raise exception 'forbidden';
  end if;

  return query
  select distinct on (d.id, r.metric)
    d.id, d.name, d.location, r.metric, r.ts, r.value
  from devices d
  join sensor_readings r on r.device_id = d.id
  where (v_actor.role = 'super_admin' or d.school_id = v_actor.school_id)
    and (p_device_id is null or d.id = p_device_id)
  order by d.id, r.metric, r.ts desc;
end;
$$;

-- 22. set_facility_manager_building
CREATE OR REPLACE FUNCTION public.set_facility_manager_building(
  p_token text,
  p_target_user_id uuid,
  p_building text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
declare
  v_actor record;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('school_admin', 'super_admin') then
    raise exception 'forbidden';
  end if;

  update users
  set building = p_building
  where id = p_target_user_id
    and (v_actor.role = 'super_admin' or school_id = v_actor.school_id);
end;
$$;

-- Function Grants
GRANT EXECUTE ON FUNCTION public.acknowledge_sensor_alert TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.resolve_sensor_alert TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.create_device_schedule TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.list_device_schedules TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.toggle_device_schedule TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.delete_device_schedule TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_energy_efficiency_score TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_energy_usage_summary TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_energy_usage_trend TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_water_efficiency_score TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_water_usage_summary TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_water_usage_trend TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_school_utility_rates TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_incident_summary TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.grant_camera_access TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.issue_device_token TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.register_device TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.queue_device_command TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.list_devices_in_my_building TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.sensor_history TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.sensor_latest TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.set_facility_manager_building TO anon, authenticated;
