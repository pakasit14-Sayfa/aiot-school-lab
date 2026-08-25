-- Migration: 20260825090000_device_schedules_pg_cron.sql
-- Description: Device auto-scheduling with pg_cron execution

CREATE EXTENSION IF NOT EXISTS pg_cron;

CREATE TABLE IF NOT EXISTS public.device_schedules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id uuid NOT NULL REFERENCES public.devices(id) ON DELETE CASCADE,
  school_id uuid NOT NULL REFERENCES public.schools(id) ON DELETE CASCADE,
  label text,
  command jsonb NOT NULL,
  days_of_week smallint[] NOT NULL,
  time_of_day time NOT NULL,
  enabled boolean NOT NULL DEFAULT true,
  created_by uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  last_triggered_at timestamptz
);

ALTER TABLE public.device_schedules ENABLE ROW LEVEL SECURITY;

-- 1. create_device_schedule
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
  v_building varchar;
  v_schedule_id uuid;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  IF v_actor.role NOT IN ('school_admin', 'super_admin', 'technician', 'facility_manager') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  SELECT * INTO v_device FROM devices WHERE id = p_device_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'device_not_found';
  END IF;

  IF v_actor.role <> 'super_admin' AND v_device.school_id IS DISTINCT FROM v_actor.school_id THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  IF v_actor.role = 'facility_manager' THEN
    SELECT building INTO v_building FROM users WHERE id = v_actor.user_id;
    IF v_building IS NULL
       OR v_device.location IS NULL
       OR v_device.location NOT LIKE (v_building || '%') THEN
      RAISE EXCEPTION 'forbidden';
    END IF;
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

-- 2. list_device_schedules
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
  v_building varchar;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  IF v_actor.role NOT IN ('school_admin', 'super_admin', 'technician', 'facility_manager') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  IF v_actor.role = 'facility_manager' THEN
    SELECT building INTO v_building FROM users WHERE id = v_actor.user_id;
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
    AND (v_actor.role <> 'facility_manager' OR (v_building IS NOT NULL AND d.location LIKE (v_building || '%')))
  ORDER BY ds.time_of_day ASC, ds.created_at DESC;
END;
$$;

-- 3. toggle_device_schedule
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
  v_device record;
  v_building varchar;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  IF v_actor.role NOT IN ('school_admin', 'super_admin', 'technician', 'facility_manager') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  SELECT * INTO v_sched FROM device_schedules WHERE id = p_schedule_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'schedule_not_found';
  END IF;

  IF v_actor.role <> 'super_admin' AND v_sched.school_id IS DISTINCT FROM v_actor.school_id THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  IF v_actor.role = 'facility_manager' THEN
    SELECT * INTO v_device FROM devices WHERE id = v_sched.device_id;
    SELECT building INTO v_building FROM users WHERE id = v_actor.user_id;
    IF v_building IS NULL
       OR v_device.location IS NULL
       OR v_device.location NOT LIKE (v_building || '%') THEN
      RAISE EXCEPTION 'forbidden';
    END IF;
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

-- 4. delete_device_schedule
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
  v_device record;
  v_building varchar;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  IF v_actor.role NOT IN ('school_admin', 'super_admin', 'technician', 'facility_manager') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  SELECT * INTO v_sched FROM device_schedules WHERE id = p_schedule_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'schedule_not_found';
  END IF;

  IF v_actor.role <> 'super_admin' AND v_sched.school_id IS DISTINCT FROM v_actor.school_id THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  IF v_actor.role = 'facility_manager' THEN
    SELECT * INTO v_device FROM devices WHERE id = v_sched.device_id;
    SELECT building INTO v_building FROM users WHERE id = v_actor.user_id;
    IF v_building IS NULL
       OR v_device.location IS NULL
       OR v_device.location NOT LIKE (v_building || '%') THEN
      RAISE EXCEPTION 'forbidden';
    END IF;
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

-- 5. Internal runner for pg_cron
CREATE OR REPLACE FUNCTION public._run_due_device_schedules()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_sched record;
BEGIN
  FOR v_sched IN
    SELECT * FROM device_schedules
    WHERE enabled = true
      AND extract(dow from now() AT TIME ZONE 'Asia/Bangkok')::smallint = ANY(days_of_week)
      AND date_trunc('minute', (now() AT TIME ZONE 'Asia/Bangkok')::time) = date_trunc('minute', time_of_day)
      AND (last_triggered_at IS NULL OR last_triggered_at < now() - interval '55 seconds')
  LOOP
    INSERT INTO device_commands (device_id, command, created_by)
    VALUES (v_sched.device_id, v_sched.command, v_sched.created_by);

    UPDATE device_schedules
    SET last_triggered_at = now()
    WHERE id = v_sched.id;
  END LOOP;
END;
$$;

-- Grants
REVOKE ALL ON FUNCTION public._run_due_device_schedules() FROM public, anon, authenticated;

REVOKE ALL ON FUNCTION public.create_device_schedule FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_device_schedule TO anon, authenticated;

REVOKE ALL ON FUNCTION public.list_device_schedules FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.list_device_schedules TO anon, authenticated;

REVOKE ALL ON FUNCTION public.toggle_device_schedule FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.toggle_device_schedule TO anon, authenticated;

REVOKE ALL ON FUNCTION public.delete_device_schedule FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.delete_device_schedule TO anon, authenticated;

-- Schedule cron job if not exists
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'device-schedules-tick') THEN
    PERFORM cron.unschedule('device-schedules-tick');
  END IF;
  PERFORM cron.schedule('device-schedules-tick', '* * * * *', 'SELECT public._run_due_device_schedules()');
END $$;
