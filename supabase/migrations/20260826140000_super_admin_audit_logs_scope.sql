-- Migration: 20260826140000_super_admin_audit_logs_scope.sql
-- Allow super_admin to view all audit logs across schools while preserving school_admin scope

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
  WHERE (v_actor.role = 'super_admin' OR al.school_id = v_actor.school_id OR al.school_id IS NULL)
  ORDER BY al.created_at DESC
  LIMIT LEAST(p_limit, 100);
END;
$$;

REVOKE ALL ON FUNCTION public.list_school_admin_audit_logs(text, integer) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.list_school_admin_audit_logs(text, integer) TO authenticated, anon;
