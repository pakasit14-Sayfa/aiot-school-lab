-- ============================================================================
-- Migration: 20260823110000_school_admin_hardening_and_batch_import.sql
-- Purpose: Multi-tenant isolation helpers, batch import RPC, and safe soft delete
-- ============================================================================

-- 1. Helper function to check if current user has a specific role
CREATE OR REPLACE FUNCTION public.has_role(p_role text)
RETURNS boolean AS $$
  SELECT EXISTS (
    SELECT 1 
    FROM public.user_roles ur
    WHERE ur.user_id = auth.uid() 
      AND ur.role::text = p_role
  );
$$ LANGUAGE sql STABLE SECURITY DEFINER;

-- 2. Helper function to get the current authenticated user's school_id
CREATE OR REPLACE FUNCTION public.current_user_school_id()
RETURNS UUID AS $$
  SELECT school_id FROM public.users WHERE id = auth.uid() LIMIT 1;
$$ LANGUAGE sql STABLE SECURITY DEFINER;

-- 3. High-Performance Batch User Import RPC (USR-7, USR-11, USR-12)
CREATE OR REPLACE FUNCTION public.import_school_users_batch(
  p_school_id UUID,
  p_role TEXT,
  p_users JSONB
)
RETURNS JSONB AS $$
DECLARE
  v_item JSONB;
  v_inserted_count INT := 0;
  v_user_id UUID;
  v_email TEXT;
  v_first_name TEXT;
  v_last_name TEXT;
  v_role_type public.role_type;
  v_granter_id UUID;
BEGIN
  -- Cast role to role_type enum
  BEGIN
    v_role_type := p_role::public.role_type;
  EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'Invalid role specified: %', p_role;
  END;

  -- Validate caller permission (Super Admin, or School Admin of this specific school, or Direct Server Call)
  IF auth.uid() IS NOT NULL THEN
    IF NOT (public.is_super_admin() OR (public.has_role('school_admin') AND p_school_id = public.current_user_school_id())) THEN
      RAISE EXCEPTION 'Access denied: insufficient permissions to import users for school %', p_school_id;
    END IF;
    v_granter_id := auth.uid();
  ELSE
    SELECT id INTO v_granter_id FROM public.users WHERE email = 'admin@aiot-school-lab.local' LIMIT 1;
  END IF;

  FOR v_item IN SELECT * FROM jsonb_array_elements(p_users)
  LOOP
    v_email := TRIM(v_item->>'email');
    v_first_name := COALESCE(TRIM(v_item->>'first_name'), 'นักเรียน');
    v_last_name := COALESCE(TRIM(v_item->>'last_name'), 'ใหม่');

    IF v_email IS NOT NULL AND v_email != '' THEN
      -- Insert into users table with default bcrypt placeholder hash
      INSERT INTO public.users (school_id, email, password_hash, first_name, last_name, status)
      VALUES (
        p_school_id, 
        v_email, 
        '$2a$10$7EqJtq98hPqEX7fNZaFWoO.8H0u.placeholderpasswordhash', 
        v_first_name, 
        v_last_name, 
        'active'
      )
      ON CONFLICT (email) DO UPDATE
      SET first_name = EXCLUDED.first_name,
          last_name = EXCLUDED.last_name,
          school_id = EXCLUDED.school_id
      RETURNING id INTO v_user_id;

      -- Assign Role with valid granter and school_id
      INSERT INTO public.user_roles (user_id, role, school_id, granted_by)
      VALUES (v_user_id, v_role_type, p_school_id, COALESCE(v_granter_id, v_user_id))
      ON CONFLICT (user_id, role, school_id) DO NOTHING;

      v_inserted_count := v_inserted_count + 1;
    END IF;
  END LOOP;

  -- Record audit log
  INSERT INTO public.device_logs (device_id, school_id, event_type, message, metadata)
  VALUES (
    NULL,
    p_school_id,
    'batch_import_completed',
    'Batch import completed for role ' || p_role || ' (total ' || v_inserted_count || ' records)',
    jsonb_build_object('role', p_role, 'count', v_inserted_count)
  );

  RETURN jsonb_build_object(
    'success', true,
    'total_imported', v_inserted_count,
    'school_id', p_school_id,
    'role', p_role
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Safe Soft Delete RPC for Devices
CREATE OR REPLACE FUNCTION public.archive_school_device(p_device_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_school_id UUID;
BEGIN
  SELECT school_id INTO v_school_id FROM public.devices WHERE id = p_device_id;
  
  IF auth.uid() IS NOT NULL THEN
    IF NOT (public.is_super_admin() OR (public.has_role('school_admin') AND v_school_id = public.current_user_school_id())) THEN
      RAISE EXCEPTION 'Access denied: cannot archive device %', p_device_id;
    END IF;
  END IF;

  UPDATE public.devices
  SET status = 'maintenance'
  WHERE id = p_device_id;

  RETURN jsonb_build_object('success', true, 'device_id', p_device_id, 'status', 'maintenance');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Safe Soft Delete RPC for Users
CREATE OR REPLACE FUNCTION public.archive_school_user(p_user_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_school_id UUID;
BEGIN
  SELECT school_id INTO v_school_id FROM public.users WHERE id = p_user_id;
  
  IF auth.uid() IS NOT NULL THEN
    IF NOT (public.is_super_admin() OR (public.has_role('school_admin') AND v_school_id = public.current_user_school_id())) THEN
      RAISE EXCEPTION 'Access denied: cannot suspend user %', p_user_id;
    END IF;
  END IF;

  UPDATE public.users
  SET status = 'suspended'
  WHERE id = p_user_id;

  RETURN jsonb_build_object('success', true, 'user_id', p_user_id, 'status', 'suspended');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

