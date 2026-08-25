-- Migration: 20260826100000_school_admin_redesign_phase2_alerts.sql
-- Description: Phase 2 School Admin Redesign RPCs with Custom Session Auth (p_token)
-- RPCs:
-- 1. list_school_alerts(p_token, p_status)
-- 2. acknowledge_sensor_alert_for_school_admin(p_token, p_alert_id)
-- 3. resolve_sensor_alert_for_school_admin(p_token, p_alert_id, p_note)
-- 4. import_school_users_batch_for_school_admin(p_token, p_role, p_users)

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
SET search_path = public, extensions
AS $$
DECLARE
  v_actor RECORD;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;
  IF v_actor.role NOT IN ('school_admin', 'super_admin') THEN
    RAISE EXCEPTION 'forbidden: school_admin or super_admin role required';
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
    TRIM(COALESCE(u.first_name || ' ' || u.last_name, u.email, ''))::text AS acknowledged_by_name,
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
SET search_path = public, extensions
AS $$
DECLARE
  v_actor RECORD;
  v_alert RECORD;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;
  IF v_actor.role NOT IN ('school_admin', 'super_admin') THEN
    RAISE EXCEPTION 'forbidden: school_admin or super_admin role required';
  END IF;

  SELECT sa.id, sa.status, d.school_id INTO v_alert
  FROM public.sensor_alerts sa
  JOIN public.devices d ON d.id = sa.device_id
  WHERE sa.id = p_alert_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'alert_not_found';
  END IF;

  IF v_actor.role != 'super_admin' AND v_alert.school_id != v_actor.school_id THEN
    RAISE EXCEPTION 'forbidden: cannot access alert from other school';
  END IF;

  UPDATE public.sensor_alerts
  SET status = 'acknowledged',
      acknowledged_by = v_actor.user_id,
      acknowledged_at = NOW()
  WHERE id = p_alert_id;

  INSERT INTO public.audit_logs (
    school_id, user_id, acted_role, action, entity_type, entity_id, details
  ) VALUES (
    v_alert.school_id,
    v_actor.user_id,
    v_actor.role::role_type,
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

CREATE OR REPLACE FUNCTION public.resolve_sensor_alert_for_school_admin(
  p_token text,
  p_alert_id uuid,
  p_note text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor RECORD;
  v_alert RECORD;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;
  IF v_actor.role NOT IN ('school_admin', 'super_admin') THEN
    RAISE EXCEPTION 'forbidden: school_admin or super_admin role required';
  END IF;

  SELECT sa.id, sa.status, d.school_id INTO v_alert
  FROM public.sensor_alerts sa
  JOIN public.devices d ON d.id = sa.device_id
  WHERE sa.id = p_alert_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'alert_not_found';
  END IF;

  IF v_actor.role != 'super_admin' AND v_alert.school_id != v_actor.school_id THEN
    RAISE EXCEPTION 'forbidden: cannot access alert from other school';
  END IF;

  UPDATE public.sensor_alerts
  SET status = 'resolved',
      acknowledged_by = COALESCE(acknowledged_by, v_actor.user_id),
      acknowledged_at = COALESCE(acknowledged_at, NOW())
  WHERE id = p_alert_id;

  INSERT INTO public.audit_logs (
    school_id, user_id, acted_role, action, entity_type, entity_id, details
  ) VALUES (
    v_alert.school_id,
    v_actor.user_id,
    v_actor.role::role_type,
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

CREATE OR REPLACE FUNCTION public.import_school_users_batch_for_school_admin(
  p_token text,
  p_role text,
  p_users jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor RECORD;
  v_item jsonb;
  v_inserted_count int := 0;
  v_user_id uuid;
  v_email text;
  v_first_name text;
  v_last_name text;
  v_student_code text;
  v_building text;
  v_role_type public.role_type;
  v_default_password_hash text;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;
  IF v_actor.role NOT IN ('school_admin', 'super_admin') THEN
    RAISE EXCEPTION 'forbidden: school_admin or super_admin role required';
  END IF;

  BEGIN
    v_role_type := p_role::public.role_type;
  EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'invalid_role: %', p_role;
  END;

  IF v_role_type IN ('super_admin'::role_type) AND v_actor.role != 'super_admin' THEN
    RAISE EXCEPTION 'forbidden: only super_admin can import super_admin users';
  END IF;

  v_default_password_hash := crypt('Test1234!', gen_salt('bf'));

  FOR v_item IN SELECT * FROM jsonb_array_elements(p_users)
  LOOP
    v_email := lower(trim(v_item->>'email'));
    v_first_name := trim(COALESCE(v_item->>'first_name', v_item->>'name', ''));
    v_last_name := trim(COALESCE(v_item->>'last_name', ''));
    v_student_code := trim(COALESCE(v_item->>'student_code', ''));
    v_building := trim(COALESCE(v_item->>'building', ''));

    IF v_first_name = '' AND v_email != '' THEN
      v_first_name := split_part(v_email, '@', 1);
    END IF;

    IF v_last_name = '' THEN
      v_last_name := '-';
    END IF;

    IF v_email IS NOT NULL AND v_email != '' THEN
      SELECT id INTO v_user_id FROM public.users WHERE email = v_email;

      IF v_user_id IS NULL THEN
        INSERT INTO public.users (
          school_id, email, first_name, last_name, password_hash, student_code, building, status
        ) VALUES (
          v_actor.school_id,
          v_email,
          v_first_name,
          v_last_name,
          v_default_password_hash,
          NULLIF(v_student_code, ''),
          NULLIF(v_building, ''),
          'active'::user_status
        ) RETURNING id INTO v_user_id;

        INSERT INTO public.user_roles (
          user_id, school_id, role, granted_by
        ) VALUES (
          v_user_id, v_actor.school_id, v_role_type, v_actor.user_id
        ) ON CONFLICT DO NOTHING;

        v_inserted_count := v_inserted_count + 1;
      END IF;
    END IF;
  END LOOP;

  INSERT INTO public.audit_logs (
    school_id, user_id, acted_role, action, entity_type, entity_id, details
  ) VALUES (
    v_actor.school_id,
    v_actor.user_id,
    v_actor.role::role_type,
    'users.batch_import',
    'users',
    v_actor.school_id::text,
    jsonb_build_object('role', p_role, 'count', v_inserted_count)
  );

  RETURN jsonb_build_object(
    'success', true,
    'inserted_count', v_inserted_count
  );
END;
$$;

REVOKE ALL ON FUNCTION public.list_school_alerts(text, text) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.acknowledge_sensor_alert_for_school_admin(text, uuid) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.resolve_sensor_alert_for_school_admin(text, uuid, text) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.import_school_users_batch_for_school_admin(text, text, jsonb) FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.list_school_alerts(text, text) TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.acknowledge_sensor_alert_for_school_admin(text, uuid) TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.resolve_sensor_alert_for_school_admin(text, uuid, text) TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.import_school_users_batch_for_school_admin(text, text, jsonb) TO anon, authenticated, service_role;
