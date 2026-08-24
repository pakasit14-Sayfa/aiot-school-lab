-- Migration: 20260824050000_sensor_alert_actions.sql
-- Description: Security Definer RPCs for acknowledging and resolving sensor alerts with Dual-Check RLS & Audit Logging

CREATE OR REPLACE FUNCTION public.acknowledge_sensor_alert(p_alert_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_alert RECORD;
  v_school_id UUID;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  -- Get alert and device's school_id
  SELECT sa.id, sa.status, d.school_id INTO v_alert
  FROM public.sensor_alerts sa
  JOIN public.devices d ON d.id = sa.device_id
  WHERE sa.id = p_alert_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'alert_not_found';
  END IF;

  -- Dual-Check: Super Admin OR (school_admin/technician in own school)
  IF NOT (
    public.is_super_admin()
    OR (
      (public.has_role('school_admin') OR public.has_role('technician'))
      AND v_alert.school_id = public.current_user_school_id()
    )
  ) THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  -- Update sensor_alerts table
  UPDATE public.sensor_alerts
  SET status = 'acknowledged',
      acknowledged_by = auth.uid(),
      acknowledged_at = NOW()
  WHERE id = p_alert_id;

  -- Audit logging
  INSERT INTO public.audit_logs (
    school_id, user_id, acted_role, action, entity_type, entity_id, details
  ) VALUES (
    v_alert.school_id,
    auth.uid(),
    CASE WHEN public.is_super_admin() THEN 'super_admin'::role_type ELSE 'school_admin'::role_type END,
    'alert.acknowledge',
    'sensor_alerts',
    p_alert_id::text,
    jsonb_build_object('previous_status', v_alert.status, 'new_status', 'acknowledged')
  );

  RETURN jsonb_build_object(
    'success', true,
    'alert_id', p_alert_id,
    'status', 'acknowledged',
    'acknowledged_at', NOW()
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.resolve_sensor_alert(
  p_alert_id UUID,
  p_note TEXT DEFAULT NULL
)
RETURNS JSONB
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
      (public.has_role('school_admin') OR public.has_role('technician'))
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

REVOKE ALL ON FUNCTION public.acknowledge_sensor_alert(UUID) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.resolve_sensor_alert(UUID, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.acknowledge_sensor_alert(UUID) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.resolve_sensor_alert(UUID, TEXT) TO authenticated, service_role;
