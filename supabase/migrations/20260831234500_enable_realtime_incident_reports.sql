-- เปิดใช้งาน Realtime ให้กับตาราง incident_reports และ emergency_events
BEGIN;

ALTER PUBLICATION supabase_realtime ADD TABLE incident_reports;
ALTER PUBLICATION supabase_realtime ADD TABLE emergency_events;

COMMIT;
