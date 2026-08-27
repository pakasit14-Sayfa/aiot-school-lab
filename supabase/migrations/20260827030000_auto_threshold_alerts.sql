-- =====================================================================
-- Auto-generate sensor_alerts from real threshold violations. Thresholds
-- have been settable/readable for real since 20260826160000_teacher_aiot
-- _thresholds.sql, but nothing actually created an alert when a real
-- reading crossed one — ingest_sensor_readings_verified doesn't check
-- thresholds, and there was no trigger either (documented gap in
-- HANDOFF.md). Mirrors the _run_due_device_schedules pg_cron pattern:
-- a school-scoped internal function, ticked every minute, checked
-- against the most recent reading per device (sensor_readings has no
-- device-level push notification, so poll-on-tick is the simplest
-- correct approach here, same as the existing device-schedule runner).
-- =====================================================================

CREATE OR REPLACE FUNCTION public._check_threshold_violations()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_th thresholds%rowtype;
  v_latest record;
BEGIN
  FOR v_th IN
    SELECT * FROM thresholds WHERE is_active = true AND device_id IS NULL
  LOOP
    FOR v_latest IN
      SELECT DISTINCT ON (r.device_id) r.device_id, r.value, r.ts
      FROM sensor_readings r
      JOIN devices d ON d.id = r.device_id
      WHERE d.school_id = v_th.school_id
        AND r.metric = v_th.metric
        -- Only readings from the last tick's window — a stale reading from
        -- hours ago shouldn't re-trigger just because the cron job runs.
        AND r.ts > now() - interval '2 minutes'
      ORDER BY r.device_id, r.ts DESC
    LOOP
      IF (v_th.min_value IS NOT NULL AND v_latest.value < v_th.min_value)
         OR (v_th.max_value IS NOT NULL AND v_latest.value > v_th.max_value) THEN
        -- Don't spam: skip if this exact device+threshold already has an
        -- unresolved alert (new/acknowledged). A fresh alert can only be
        -- raised again after the existing one is marked resolved.
        IF NOT EXISTS (
          SELECT 1 FROM sensor_alerts
          WHERE threshold_id = v_th.id
            AND device_id = v_latest.device_id
            AND status IN ('new', 'acknowledged')
        ) THEN
          INSERT INTO sensor_alerts (threshold_id, device_id, metric, value, status)
          VALUES (v_th.id, v_latest.device_id, v_th.metric, v_latest.value, 'new');
        END IF;
      END IF;
    END LOOP;
  END LOOP;
END;
$$;

REVOKE ALL ON FUNCTION public._check_threshold_violations() FROM public, anon, authenticated, service_role;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'threshold-violation-check') THEN
    PERFORM cron.unschedule('threshold-violation-check');
  END IF;
  PERFORM cron.schedule('threshold-violation-check', '* * * * *', 'SELECT public._check_threshold_violations()');
END $$;
