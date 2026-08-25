-- Migration: 20260826110000_school_admin_redesign_phase2_batch2.sql
-- Description: RPCs for School Admin Redesign Phase 2 Batch 2 (Buildings, Rooms, Dashboard Summary, Settings, Audit Logs)

DROP FUNCTION IF EXISTS public.list_school_buildings(text);
DROP FUNCTION IF EXISTS public.list_school_rooms(text, uuid);
DROP FUNCTION IF EXISTS public.get_school_admin_dashboard_summary(text);
DROP FUNCTION IF EXISTS public.list_school_admin_audit_logs(text, integer);

-- 1. list_school_buildings(p_token text)
CREATE OR REPLACE FUNCTION public.list_school_buildings(p_token text)
RETURNS TABLE (
  id uuid,
  school_id uuid,
  name text,
  code text,
  floors integer,
  rooms_count bigint,
  manager_name text,
  devices_count bigint,
  training_kits_count bigint,
  status text,
  note text
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
    b.id,
    b.school_id,
    b.name,
    COALESCE(b.code, ''),
    COALESCE(b.floors, 1),
    COALESCE(rc.cnt, 0)::bigint AS rooms_count,
    COALESCE(b.manager_name, ''),
    COALESCE(dc.cnt, 0)::bigint AS devices_count,
    COALESCE(dc.training_cnt, 0)::bigint AS training_kits_count,
    COALESCE(b.status, 'active') AS status,
    COALESCE(b.note, '') AS note
  FROM public.buildings b
  LEFT JOIN (
    SELECT r.building_id, COUNT(*) AS cnt
    FROM public.rooms r
    GROUP BY r.building_id
  ) rc ON rc.building_id = b.id
  LEFT JOIN (
    SELECT d.building, COUNT(*) AS cnt, COUNT(CASE WHEN d.type::text ILIKE '%kit%' OR d.name ILIKE '%ฝึก%' THEN 1 END) AS training_cnt
    FROM public.devices d
    WHERE d.school_id = v_actor.school_id
    GROUP BY d.building
  ) dc ON dc.building = b.name
  WHERE b.school_id = v_actor.school_id
  ORDER BY b.name ASC;
END;
$$;

REVOKE ALL ON FUNCTION public.list_school_buildings(text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.list_school_buildings(text) TO authenticated, anon;


-- 2. list_school_rooms(p_token text, p_building_id uuid)
CREATE OR REPLACE FUNCTION public.list_school_rooms(
  p_token text,
  p_building_id uuid DEFAULT NULL
)
RETURNS TABLE (
  id uuid,
  school_id uuid,
  building_id uuid,
  building_name text,
  name text,
  code text,
  floor text,
  room_type text,
  capacity integer,
  teacher_name text,
  devices_count bigint,
  training_kits_count bigint,
  status text,
  resource_status text
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
    r.id,
    r.school_id,
    r.building_id,
    COALESCE(b.name, 'ไม่ระบุอาคาร') AS building_name,
    r.name,
    COALESCE(r.code, ''),
    COALESCE(r.floor, 'ชั้น 1'),
    COALESCE(r.room_type, 'ห้องเรียน'),
    COALESCE(r.capacity, 30),
    COALESCE(r.teacher_name, ''),
    0::bigint AS devices_count,
    0::bigint AS training_kits_count,
    COALESCE(r.status, 'active') AS status,
    'ปกติ'::text AS resource_status
  FROM public.rooms r
  LEFT JOIN public.buildings b ON b.id = r.building_id
  WHERE r.school_id = v_actor.school_id
    AND (p_building_id IS NULL OR r.building_id = p_building_id)
  ORDER BY r.name ASC;
END;
$$;

REVOKE ALL ON FUNCTION public.list_school_rooms(text, uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.list_school_rooms(text, uuid) TO authenticated, anon;


-- 3. get_school_admin_dashboard_summary(p_token text)
CREATE OR REPLACE FUNCTION public.get_school_admin_dashboard_summary(p_token text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_students_count bigint;
  v_teachers_count bigint;
  v_devices_count bigint;
  v_devices_online bigint;
  v_buildings_count bigint;
  v_rooms_count bigint;
  v_open_alerts_count bigint;
  v_school_name text;
  v_school_code text;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  IF v_actor.role NOT IN ('school_admin', 'super_admin') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  -- School info
  SELECT name, school_code INTO v_school_name, v_school_code
  FROM public.schools
  WHERE id = v_actor.school_id;

  -- Students count
  SELECT COUNT(DISTINCT ur.user_id) INTO v_students_count
  FROM public.user_roles ur
  JOIN public.users u ON u.id = ur.user_id
  WHERE ur.school_id = v_actor.school_id
    AND ur.role = 'student';

  -- Teachers count
  SELECT COUNT(DISTINCT ur.user_id) INTO v_teachers_count
  FROM public.user_roles ur
  JOIN public.users u ON u.id = ur.user_id
  WHERE ur.school_id = v_actor.school_id
    AND ur.role = 'teacher';

  -- Devices count & online count
  SELECT 
    COUNT(*),
    COUNT(CASE WHEN status = 'online' OR last_seen_at >= (NOW() - INTERVAL '15 minutes') THEN 1 END)
  INTO v_devices_count, v_devices_online
  FROM public.devices
  WHERE school_id = v_actor.school_id;

  -- Buildings & Rooms count
  SELECT COUNT(*) INTO v_buildings_count
  FROM public.buildings
  WHERE school_id = v_actor.school_id;

  SELECT COUNT(*) INTO v_rooms_count
  FROM public.rooms
  WHERE school_id = v_actor.school_id;

  -- Open alerts count
  SELECT COUNT(*) INTO v_open_alerts_count
  FROM public.sensor_alerts sa
  JOIN public.devices d ON d.id = sa.device_id
  WHERE d.school_id = v_actor.school_id
    AND sa.status != 'resolved';

  RETURN jsonb_build_object(
    'school_id', v_actor.school_id,
    'school_name', COALESCE(v_school_name, ''),
    'school_code', COALESCE(v_school_code, ''),
    'students_count', COALESCE(v_students_count, 0),
    'teachers_count', COALESCE(v_teachers_count, 0),
    'devices_count', COALESCE(v_devices_count, 0),
    'devices_online', COALESCE(v_devices_online, 0),
    'buildings_count', COALESCE(v_buildings_count, 0),
    'rooms_count', COALESCE(v_rooms_count, 0),
    'open_alerts_count', COALESCE(v_open_alerts_count, 0)
  );
END;
$$;

REVOKE ALL ON FUNCTION public.get_school_admin_dashboard_summary(text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_school_admin_dashboard_summary(text) TO authenticated, anon;


-- 4. list_school_admin_audit_logs(p_token text, p_limit int)
CREATE OR REPLACE FUNCTION public.list_school_admin_audit_logs(
  p_token text,
  p_limit integer DEFAULT 20
)
RETURNS TABLE (
  id bigint,
  action text,
  target text,
  detail text,
  actor_name text,
  actor_role text,
  created_at timestamptz
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
    al.id,
    COALESCE(al.action, 'action')::text AS action,
    COALESCE(al.entity_type, '')::text AS target,
    COALESCE(al.details::text, '') AS detail,
    COALESCE(u.first_name || ' ' || u.last_name, 'ผู้ดูแลระบบ') AS actor_name,
    COALESCE(al.acted_role::text, 'school_admin') AS actor_role,
    al.created_at
  FROM public.audit_logs al
  LEFT JOIN public.users u ON u.id = al.user_id
  WHERE (al.school_id = v_actor.school_id OR al.school_id IS NULL)
  ORDER BY al.created_at DESC
  LIMIT LEAST(p_limit, 100);
END;
$$;

REVOKE ALL ON FUNCTION public.list_school_admin_audit_logs(text, integer) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.list_school_admin_audit_logs(text, integer) TO authenticated, anon;
