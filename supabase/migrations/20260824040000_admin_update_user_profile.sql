-- Migration: 20260824040000_admin_update_user_profile.sql
-- Description: Security Definer RPC for Super Admin / School Admin to update user name and role safely

CREATE OR REPLACE FUNCTION public.admin_update_user_profile(
  p_user_id UUID,
  p_first_name TEXT,
  p_last_name TEXT,
  p_role TEXT DEFAULT NULL,
  p_school_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_role_type public.role_type;
  v_current_school_id UUID;
  v_target_school_id UUID;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  -- Get target user's current school
  SELECT school_id INTO v_target_school_id
  FROM public.users
  WHERE id = p_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'user_not_found';
  END IF;

  -- Super admin can edit any user, School Admin can only edit users in their school
  IF NOT (
    public.is_super_admin()
    OR (public.has_role('school_admin') AND v_target_school_id = public.current_user_school_id())
  ) THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  -- Update name in public.users
  UPDATE public.users
  SET first_name = COALESCE(NULLIF(TRIM(p_first_name), ''), first_name),
      last_name = COALESCE(NULLIF(TRIM(p_last_name), ''), last_name),
      updated_at = NOW()
  WHERE id = p_user_id;

  -- Update role in public.user_roles if provided
  IF p_role IS NOT NULL AND TRIM(p_role) != '' THEN
    BEGIN
      v_role_type := TRIM(p_role)::public.role_type;
    EXCEPTION WHEN OTHERS THEN
      RAISE EXCEPTION 'invalid_role: %', p_role;
    END;

    UPDATE public.user_roles
    SET role = v_role_type
    WHERE user_id = p_user_id
      AND (p_school_id IS NULL OR school_id = p_school_id);
  END IF;

  -- Audit logging
  INSERT INTO public.audit_logs (
    school_id, user_id, acted_role, action, entity_type, entity_id, details
  ) VALUES (
    v_target_school_id,
    auth.uid(),
    CASE WHEN public.is_super_admin() THEN 'super_admin'::role_type ELSE 'school_admin'::role_type END,
    'user.admin_update',
    'users',
    p_user_id::text,
    jsonb_build_object(
      'first_name', p_first_name,
      'last_name', p_last_name,
      'role', p_role
    )
  );

  RETURN jsonb_build_object(
    'success', true,
    'user_id', p_user_id,
    'first_name', p_first_name,
    'last_name', p_last_name,
    'role', p_role
  );
END;
$$;

REVOKE ALL ON FUNCTION public.admin_update_user_profile(UUID, TEXT, TEXT, TEXT, UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.admin_update_user_profile(UUID, TEXT, TEXT, TEXT, UUID) FROM anon;
GRANT EXECUTE ON FUNCTION public.admin_update_user_profile(UUID, TEXT, TEXT, TEXT, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_update_user_profile(UUID, TEXT, TEXT, TEXT, UUID) TO service_role;

-- Revoke direct table updates to enforce RPC pathway
REVOKE UPDATE ON public.users FROM PUBLIC, anon, authenticated;
