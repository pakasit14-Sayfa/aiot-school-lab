-- Migration: 20260830000000_register_device_for_super_admin.sql
-- Description: Real device registration/provisioning for Super Admin's
-- "ทะเบียนและ QR Code" page — previously had zero backend path (the page
-- could only list existing devices via list_device_control_data_for_super_admin,
-- there was no way to add a new one). Modeled on
-- import_school_devices_batch (20260826150000_school_admin_bulk_import.sql)
-- but that RPC scopes writes to the *caller's own* school_id
-- (v_actor.school_id), which is null/not applicable for super_admin —
-- this variant takes an explicit p_school_id since super_admin operates
-- across every school, and returns the plaintext device_token once (for
-- provisioning the physical device), matching the pattern already used
-- by device registration elsewhere in this schema.

CREATE OR REPLACE FUNCTION public.register_device_for_super_admin(
  p_token text,
  p_school_id uuid,
  p_name text,
  p_type text,
  p_category_code text DEFAULT NULL,
  p_device_code text DEFAULT NULL,
  p_building text DEFAULT NULL,
  p_room text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_device_id uuid;
  v_device_token text;
  v_device_code text;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;
  IF v_actor.role != 'super_admin' THEN
    RAISE EXCEPTION 'forbidden: super_admin role required';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.schools WHERE id = p_school_id) THEN
    RAISE EXCEPTION 'school_not_found';
  END IF;

  IF trim(coalesce(p_name, '')) = '' THEN
    RAISE EXCEPTION 'name_required';
  END IF;

  BEGIN
    PERFORM p_type::public.device_type;
  EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'invalid_device_type';
  END;

  v_device_code := NULLIF(trim(coalesce(p_device_code, '')), '');
  IF v_device_code IS NOT NULL AND EXISTS (
    SELECT 1 FROM public.devices WHERE device_code = v_device_code
  ) THEN
    RAISE EXCEPTION 'duplicate_device_code';
  END IF;

  v_device_token := 'dev_' || encode(gen_random_bytes(24), 'hex');

  INSERT INTO public.devices (
    school_id, type, name, category_code, device_code, building, room,
    registered_by, token_hash
  ) VALUES (
    p_school_id,
    p_type::public.device_type,
    trim(p_name),
    NULLIF(trim(coalesce(p_category_code, '')), ''),
    coalesce(v_device_code, 'DEV-' || upper(substr(md5(random()::text), 1, 8))),
    NULLIF(trim(coalesce(p_building, '')), ''),
    NULLIF(trim(coalesce(p_room, '')), ''),
    v_actor.user_id,
    encode(digest(v_device_token, 'sha256'), 'hex')
  )
  RETURNING id INTO v_device_id;

  INSERT INTO public.audit_logs (
    school_id, user_id, acted_role, action, entity_type, entity_id, details
  ) VALUES (
    p_school_id, v_actor.user_id, v_actor.role,
    'devices.register', 'devices', v_device_id::text,
    jsonb_build_object('name', p_name, 'type', p_type)
  );

  RETURN jsonb_build_object(
    'device_id', v_device_id,
    'device_token', v_device_token
  );
END;
$$;

REVOKE ALL ON FUNCTION public.register_device_for_super_admin FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.register_device_for_super_admin TO anon, authenticated;
