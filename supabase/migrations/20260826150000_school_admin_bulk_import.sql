-- Migration: 20260826150000_school_admin_bulk_import.sql
-- Description: Real bulk-import RPCs for School Admin's "นำเข้าข้อมูล" page —
--   buildings, rooms, and devices (also used for ชุดฝึก/training kits, which
--   are just devices sharing a kit_code, not a separate table).
--   Mirrors import_school_users_batch_for_school_admin's pattern: session/role
--   check, loop over jsonb_array_elements, skip duplicates within the school
--   rather than aborting the whole batch, audit_logs insert, jsonb return with
--   inserted_count + a skipped[] array of {row, reason} for real per-row
--   failure reporting in the UI.
-- RPCs:
-- 1. import_school_buildings_batch(p_token, p_buildings)
-- 2. import_school_rooms_batch(p_token, p_rooms)
-- 3. import_school_devices_batch(p_token, p_devices)

CREATE OR REPLACE FUNCTION public.import_school_buildings_batch(
  p_token text,
  p_buildings jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'extensions'
AS $$
DECLARE
  v_actor RECORD;
  v_item jsonb;
  v_row_index int := 0;
  v_inserted_count int := 0;
  v_skipped jsonb := '[]'::jsonb;
  v_name text;
  v_code text;
  v_floors int;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;
  IF v_actor.role NOT IN ('school_admin', 'super_admin') THEN
    RAISE EXCEPTION 'forbidden: school_admin or super_admin role required';
  END IF;

  FOR v_item IN SELECT * FROM jsonb_array_elements(p_buildings)
  LOOP
    v_row_index := v_row_index + 1;
    v_name := trim(COALESCE(v_item->>'name', ''));
    v_code := trim(COALESCE(v_item->>'code', ''));
    v_floors := COALESCE((v_item->>'floors')::int, 1);

    IF v_name = '' OR v_code = '' THEN
      v_skipped := v_skipped || jsonb_build_object('row', v_row_index, 'reason', 'missing_required_field');
      CONTINUE;
    END IF;

    IF EXISTS (SELECT 1 FROM public.buildings WHERE school_id = v_actor.school_id AND code = v_code) THEN
      v_skipped := v_skipped || jsonb_build_object('row', v_row_index, 'reason', 'duplicate_code');
      CONTINUE;
    END IF;

    INSERT INTO public.buildings (school_id, name, code, floors)
    VALUES (v_actor.school_id, v_name, v_code, v_floors);

    v_inserted_count := v_inserted_count + 1;
  END LOOP;

  INSERT INTO public.audit_logs (
    school_id, user_id, acted_role, action, entity_type, entity_id, details
  ) VALUES (
    v_actor.school_id,
    v_actor.user_id,
    v_actor.role,
    'buildings.batch_import',
    'buildings',
    v_actor.school_id::text,
    jsonb_build_object('count', v_inserted_count, 'skipped', v_skipped)
  );

  RETURN jsonb_build_object(
    'success', true,
    'inserted_count', v_inserted_count,
    'skipped', v_skipped
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.import_school_rooms_batch(
  p_token text,
  p_rooms jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'extensions'
AS $$
DECLARE
  v_actor RECORD;
  v_item jsonb;
  v_row_index int := 0;
  v_inserted_count int := 0;
  v_skipped jsonb := '[]'::jsonb;
  v_name text;
  v_code text;
  v_building_code text;
  v_building_id uuid;
  v_floor text;
  v_capacity int;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;
  IF v_actor.role NOT IN ('school_admin', 'super_admin') THEN
    RAISE EXCEPTION 'forbidden: school_admin or super_admin role required';
  END IF;

  FOR v_item IN SELECT * FROM jsonb_array_elements(p_rooms)
  LOOP
    v_row_index := v_row_index + 1;
    v_name := trim(COALESCE(v_item->>'name', ''));
    v_code := trim(COALESCE(v_item->>'code', ''));
    v_building_code := trim(COALESCE(v_item->>'building_code', ''));
    v_floor := NULLIF(trim(COALESCE(v_item->>'floor', '')), '');
    v_capacity := COALESCE((v_item->>'capacity')::int, 30);

    IF v_name = '' OR v_code = '' OR v_building_code = '' THEN
      v_skipped := v_skipped || jsonb_build_object('row', v_row_index, 'reason', 'missing_required_field');
      CONTINUE;
    END IF;

    SELECT id INTO v_building_id FROM public.buildings
      WHERE school_id = v_actor.school_id AND code = v_building_code;

    IF v_building_id IS NULL THEN
      v_skipped := v_skipped || jsonb_build_object('row', v_row_index, 'reason', 'building_not_found');
      CONTINUE;
    END IF;

    IF EXISTS (SELECT 1 FROM public.rooms WHERE school_id = v_actor.school_id AND code = v_code) THEN
      v_skipped := v_skipped || jsonb_build_object('row', v_row_index, 'reason', 'duplicate_code');
      CONTINUE;
    END IF;

    INSERT INTO public.rooms (school_id, building_id, name, code, floor, capacity)
    VALUES (v_actor.school_id, v_building_id, v_name, v_code, v_floor, v_capacity);

    v_inserted_count := v_inserted_count + 1;
  END LOOP;

  INSERT INTO public.audit_logs (
    school_id, user_id, acted_role, action, entity_type, entity_id, details
  ) VALUES (
    v_actor.school_id,
    v_actor.user_id,
    v_actor.role,
    'rooms.batch_import',
    'rooms',
    v_actor.school_id::text,
    jsonb_build_object('count', v_inserted_count, 'skipped', v_skipped)
  );

  RETURN jsonb_build_object(
    'success', true,
    'inserted_count', v_inserted_count,
    'skipped', v_skipped
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.import_school_devices_batch(
  p_token text,
  p_devices jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'extensions'
AS $$
DECLARE
  v_actor RECORD;
  v_item jsonb;
  v_row_index int := 0;
  v_inserted_count int := 0;
  v_skipped jsonb := '[]'::jsonb;
  v_name text;
  v_type text;
  v_location text;
  v_kit_code text;
  v_serial_no text;
  v_device_token text;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;
  IF v_actor.role NOT IN ('school_admin', 'super_admin') THEN
    RAISE EXCEPTION 'forbidden: school_admin or super_admin role required';
  END IF;

  FOR v_item IN SELECT * FROM jsonb_array_elements(p_devices)
  LOOP
    v_row_index := v_row_index + 1;
    v_name := trim(COALESCE(v_item->>'name', ''));
    v_type := trim(COALESCE(v_item->>'type', ''));
    v_location := NULLIF(trim(COALESCE(v_item->>'location', '')), '');
    v_kit_code := NULLIF(trim(COALESCE(v_item->>'kit_code', '')), '');
    v_serial_no := NULLIF(trim(COALESCE(v_item->>'serial_no', '')), '');

    IF v_name = '' OR v_type = '' THEN
      v_skipped := v_skipped || jsonb_build_object('row', v_row_index, 'reason', 'missing_required_field');
      CONTINUE;
    END IF;

    BEGIN
      PERFORM v_type::public.device_type;
    EXCEPTION WHEN OTHERS THEN
      v_skipped := v_skipped || jsonb_build_object('row', v_row_index, 'reason', 'invalid_device_type');
      CONTINUE;
    END;

    IF v_serial_no IS NOT NULL AND EXISTS (
      SELECT 1 FROM public.devices WHERE school_id = v_actor.school_id AND serial_no = v_serial_no
    ) THEN
      v_skipped := v_skipped || jsonb_build_object('row', v_row_index, 'reason', 'duplicate_serial_no');
      CONTINUE;
    END IF;

    v_device_token := 'dev_' || encode(gen_random_bytes(24), 'hex');

    INSERT INTO public.devices (
      school_id, type, name, serial_no, location, kit_code, registered_by, token_hash
    ) VALUES (
      v_actor.school_id, v_type::public.device_type, v_name, v_serial_no, v_location, v_kit_code,
      v_actor.user_id, encode(digest(v_device_token, 'sha256'), 'hex')
    );

    v_inserted_count := v_inserted_count + 1;
  END LOOP;

  INSERT INTO public.audit_logs (
    school_id, user_id, acted_role, action, entity_type, entity_id, details
  ) VALUES (
    v_actor.school_id,
    v_actor.user_id,
    v_actor.role,
    'devices.batch_import',
    'devices',
    v_actor.school_id::text,
    jsonb_build_object('count', v_inserted_count, 'skipped', v_skipped)
  );

  RETURN jsonb_build_object(
    'success', true,
    'inserted_count', v_inserted_count,
    'skipped', v_skipped
  );
END;
$$;

REVOKE ALL ON FUNCTION public.import_school_buildings_batch(text, jsonb) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.import_school_buildings_batch(text, jsonb) TO anon, authenticated, service_role;

REVOKE ALL ON FUNCTION public.import_school_rooms_batch(text, jsonb) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.import_school_rooms_batch(text, jsonb) TO anon, authenticated, service_role;

REVOKE ALL ON FUNCTION public.import_school_devices_batch(text, jsonb) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.import_school_devices_batch(text, jsonb) TO anon, authenticated, service_role;
