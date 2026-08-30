-- Migration: 20260830010000_platform_settings.sql
-- Description: Real persistence for Super Admin's "ตั้งค่าระบบส่วนกลาง"
-- page — previously 100% local widget state, self-disclosed as fake with
-- two banners, edits never survived a refresh. This makes every field
-- actually save. It does NOT make every toggle actively enforced —
-- nothing else in the schema currently reads audit_log_enabled,
-- maintenance_mode, two_factor_required, or the notification-channel
-- flags (grepped, zero references), and the 3 thresholds here are a
-- separate concept from the already-real per-school thresholds table
-- (20260826160000_teacher_aiot_thresholds.sql) — these are NOT wired
-- into alert generation. The UI must caption these sections honestly
-- rather than implying they already take effect.

CREATE TABLE IF NOT EXISTS public.platform_settings (
  id int PRIMARY KEY DEFAULT 1 CHECK (id = 1),
  mq2_threshold numeric NOT NULL DEFAULT 2.2,
  pm25_threshold numeric NOT NULL DEFAULT 35,
  temperature_threshold numeric NOT NULL DEFAULT 45,
  offline_minutes int NOT NULL DEFAULT 5,
  mqtt_host text NOT NULL DEFAULT '192.168.1.180',
  mqtt_port int NOT NULL DEFAULT 1883,
  line_notify boolean NOT NULL DEFAULT true,
  email_notify boolean NOT NULL DEFAULT true,
  push_notify boolean NOT NULL DEFAULT true,
  automatic_backup boolean NOT NULL DEFAULT true,
  maintenance_mode boolean NOT NULL DEFAULT false,
  two_factor_required boolean NOT NULL DEFAULT true,
  audit_log_enabled boolean NOT NULL DEFAULT true,
  language text NOT NULL DEFAULT 'ภาษาไทย',
  timezone text NOT NULL DEFAULT 'Asia/Bangkok (UTC+7)',
  log_retention_days int NOT NULL DEFAULT 365,
  backup_time text NOT NULL DEFAULT '02:00',
  updated_by uuid REFERENCES public.users(id),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.platform_settings ENABLE ROW LEVEL SECURITY;

INSERT INTO public.platform_settings (id) VALUES (1) ON CONFLICT (id) DO NOTHING;

CREATE OR REPLACE FUNCTION public.get_platform_settings(p_token text)
RETURNS public.platform_settings
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_row public.platform_settings;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;
  IF v_actor.role != 'super_admin' THEN
    RAISE EXCEPTION 'forbidden: super_admin role required';
  END IF;

  SELECT * INTO v_row FROM public.platform_settings WHERE id = 1;
  RETURN v_row;
END;
$$;

CREATE OR REPLACE FUNCTION public.update_platform_settings(
  p_token text,
  p_mq2_threshold numeric DEFAULT NULL,
  p_pm25_threshold numeric DEFAULT NULL,
  p_temperature_threshold numeric DEFAULT NULL,
  p_offline_minutes int DEFAULT NULL,
  p_mqtt_host text DEFAULT NULL,
  p_mqtt_port int DEFAULT NULL,
  p_line_notify boolean DEFAULT NULL,
  p_email_notify boolean DEFAULT NULL,
  p_push_notify boolean DEFAULT NULL,
  p_automatic_backup boolean DEFAULT NULL,
  p_maintenance_mode boolean DEFAULT NULL,
  p_two_factor_required boolean DEFAULT NULL,
  p_audit_log_enabled boolean DEFAULT NULL,
  p_language text DEFAULT NULL,
  p_timezone text DEFAULT NULL,
  p_log_retention_days int DEFAULT NULL,
  p_backup_time text DEFAULT NULL
)
RETURNS public.platform_settings
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_row public.platform_settings;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;
  IF v_actor.role != 'super_admin' THEN
    RAISE EXCEPTION 'forbidden: super_admin role required';
  END IF;

  UPDATE public.platform_settings SET
    mq2_threshold = COALESCE(p_mq2_threshold, mq2_threshold),
    pm25_threshold = COALESCE(p_pm25_threshold, pm25_threshold),
    temperature_threshold = COALESCE(p_temperature_threshold, temperature_threshold),
    offline_minutes = COALESCE(p_offline_minutes, offline_minutes),
    mqtt_host = COALESCE(p_mqtt_host, mqtt_host),
    mqtt_port = COALESCE(p_mqtt_port, mqtt_port),
    line_notify = COALESCE(p_line_notify, line_notify),
    email_notify = COALESCE(p_email_notify, email_notify),
    push_notify = COALESCE(p_push_notify, push_notify),
    automatic_backup = COALESCE(p_automatic_backup, automatic_backup),
    maintenance_mode = COALESCE(p_maintenance_mode, maintenance_mode),
    two_factor_required = COALESCE(p_two_factor_required, two_factor_required),
    audit_log_enabled = COALESCE(p_audit_log_enabled, audit_log_enabled),
    language = COALESCE(p_language, language),
    timezone = COALESCE(p_timezone, timezone),
    log_retention_days = COALESCE(p_log_retention_days, log_retention_days),
    backup_time = COALESCE(p_backup_time, backup_time),
    updated_by = v_actor.user_id,
    updated_at = now()
  WHERE id = 1
  RETURNING * INTO v_row;

  INSERT INTO public.audit_logs (
    user_id, acted_role, action, entity_type, entity_id, details
  ) VALUES (
    v_actor.user_id, v_actor.role, 'platform_settings.update',
    'platform_settings', '1', '{}'::jsonb
  );

  RETURN v_row;
END;
$$;

REVOKE ALL ON FUNCTION public.get_platform_settings FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_platform_settings TO anon, authenticated;

REVOKE ALL ON FUNCTION public.update_platform_settings FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.update_platform_settings TO anon, authenticated;
