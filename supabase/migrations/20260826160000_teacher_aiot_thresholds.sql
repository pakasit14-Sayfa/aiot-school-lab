-- Migration: 20260826160000_teacher_aiot_thresholds.sql
-- Description: Real threshold CRUD for the Teacher AIoT dashboard (the
--   `thresholds` table had zero RPCs before this), and widen the existing
--   school_admin-only alert RPCs to also allow teacher, per this app's own
--   documented permission model (see teacher_aiot_dashboard_page.dart's
--   top-of-file comment). Thresholds here are school-wide per metric
--   (device_id left null) — the dashboard UI is 4 metric cards, not
--   per-device settings.
-- RPCs:
-- 1. list_thresholds(p_token)
-- 2. set_threshold(p_token, p_metric, p_min, p_max, p_is_active)
-- 3. list_school_alerts(p_token, p_status) — widened to allow teacher
-- 4. acknowledge_sensor_alert_for_school_admin(p_token, p_alert_id) — widened to allow teacher

CREATE OR REPLACE FUNCTION public.list_thresholds(
  p_token text
)
RETURNS TABLE (
  id uuid,
  metric metric_type,
  min_value numeric,
  max_value numeric,
  is_active boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'extensions'
AS $$
DECLARE
  v_actor RECORD;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;
  IF v_actor.role NOT IN ('teacher', 'school_admin', 'super_admin') THEN
    RAISE EXCEPTION 'forbidden: teacher, school_admin or super_admin role required';
  END IF;

  RETURN QUERY
  SELECT t.id, t.metric, t.min_value, t.max_value, t.is_active
  FROM public.thresholds t
  WHERE t.school_id = v_actor.school_id
    AND t.device_id IS NULL
  ORDER BY t.metric;
END;
$$;

CREATE OR REPLACE FUNCTION public.set_threshold(
  p_token text,
  p_metric metric_type,
  p_min numeric,
  p_max numeric,
  p_is_active boolean DEFAULT true
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'extensions'
AS $$
DECLARE
  v_actor RECORD;
  v_threshold_id uuid;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;
  IF v_actor.role NOT IN ('teacher', 'school_admin', 'super_admin') THEN
    RAISE EXCEPTION 'forbidden: teacher, school_admin or super_admin role required';
  END IF;

  SELECT id INTO v_threshold_id
  FROM public.thresholds
  WHERE school_id = v_actor.school_id
    AND device_id IS NULL
    AND metric = p_metric;

  IF v_threshold_id IS NOT NULL THEN
    UPDATE public.thresholds
    SET min_value = p_min, max_value = p_max, is_active = p_is_active
    WHERE id = v_threshold_id;
  ELSE
    INSERT INTO public.thresholds (school_id, device_id, metric, min_value, max_value, is_active, created_by)
    VALUES (v_actor.school_id, NULL, p_metric, p_min, p_max, p_is_active, v_actor.user_id)
    RETURNING id INTO v_threshold_id;
  END IF;

  INSERT INTO public.audit_logs (
    school_id, user_id, acted_role, action, entity_type, entity_id, details
  ) VALUES (
    v_actor.school_id,
    v_actor.user_id,
    v_actor.role,
    'threshold.set',
    'thresholds',
    v_threshold_id::text,
    jsonb_build_object('metric', p_metric, 'min', p_min, 'max', p_max, 'is_active', p_is_active)
  );

  RETURN jsonb_build_object('success', true, 'threshold_id', v_threshold_id);
END;
$$;

REVOKE ALL ON FUNCTION public.list_thresholds(text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.list_thresholds(text) TO anon, authenticated, service_role;

REVOKE ALL ON FUNCTION public.set_threshold(text, metric_type, numeric, numeric, boolean) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.set_threshold(text, metric_type, numeric, numeric, boolean) TO anon, authenticated, service_role;

-- Widen role checks only — bodies otherwise unchanged from the
-- school_admin-only versions.
CREATE OR REPLACE FUNCTION public.list_school_alerts(
  p_token text,
  p_status text DEFAULT NULL
)
RETURNS TABLE (
  id uuid,
  device_id uuid,
  device_name text,
  device_code text,
  school_id uuid,
  threshold_id uuid,
  metric text,
  value numeric,
  triggered_at timestamptz,
  status text,
  acknowledged_by uuid,
  acknowledged_by_name text,
  acknowledged_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'extensions'
AS $$
DECLARE
  v_actor RECORD;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;
  IF v_actor.role NOT IN ('teacher', 'school_admin', 'super_admin') THEN
    RAISE EXCEPTION 'forbidden: teacher, school_admin or super_admin role required';
  END IF;

  RETURN QUERY
  SELECT
    sa.id,
    sa.device_id,
    COALESCE(d.name, 'Unknown Device')::text AS device_name,
    COALESCE(d.device_code, 'DEV-UNKNOWN')::text AS device_code,
    d.school_id,
    sa.threshold_id,
    sa.metric::text,
    sa.value,
    sa.triggered_at,
    sa.status::text,
    sa.acknowledged_by,
    u.first_name::text AS acknowledged_by_name,
    sa.acknowledged_at
  FROM public.sensor_alerts sa
  JOIN public.devices d ON d.id = sa.device_id
  LEFT JOIN public.users u ON u.id = sa.acknowledged_by
  WHERE (v_actor.role = 'super_admin' OR d.school_id = v_actor.school_id)
    AND (p_status IS NULL OR sa.status::text = p_status)
  ORDER BY sa.triggered_at DESC;
END;
$$;

CREATE OR REPLACE FUNCTION public.acknowledge_sensor_alert_for_school_admin(
  p_token text,
  p_alert_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'extensions'
AS $$
DECLARE
  v_actor RECORD;
  v_alert RECORD;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;
  IF v_actor.role NOT IN ('teacher', 'school_admin', 'super_admin') THEN
    RAISE EXCEPTION 'forbidden: teacher, school_admin or super_admin role required';
  END IF;

  SELECT sa.id, sa.status, d.school_id INTO v_alert
  FROM public.sensor_alerts sa
  JOIN public.devices d ON d.id = sa.device_id
  WHERE sa.id = p_alert_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'alert_not_found';
  END IF;

  IF v_actor.role != 'super_admin' AND v_alert.school_id != v_actor.school_id THEN
    RAISE EXCEPTION 'forbidden: alert does not belong to your school';
  END IF;

  UPDATE public.sensor_alerts
  SET status = 'acknowledged',
      acknowledged_at = NOW(),
      acknowledged_by = v_actor.user_id
  WHERE id = p_alert_id;

  INSERT INTO public.audit_logs (
    school_id, user_id, acted_role, action, entity_type, entity_id, details
  ) VALUES (
    v_alert.school_id,
    v_actor.user_id,
    v_actor.role,
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
