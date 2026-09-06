-- Migration: 20260907000000_staff_org_structure.sql
-- Description: ฝ่าย (departments) และกลุ่มสาระการเรียนรู้ (subject groups) —
-- the organisational structure a Thai school actually runs on, and the first
-- place `users` records anything about a staff member's role in it.
--
-- Why this exists: `director_teachers_page` and `school_teachers_page` both
-- shipped a hardcoded list of ฝ่าย (6 entries) and กลุ่มสาระ (10 entries),
-- with per-department head counts and a personnel directory whose ตำแหน่ง /
-- ฝ่าย / กลุ่มสาระ columns were invented per row. `users` has no `position`,
-- `department` or `phone` column, and no table modelled either grouping, so
-- every one of those values was fabricated. Rather than delete the sections,
-- the school confirmed it uses them, so they are modelled properly here.
--
-- Design notes:
--
--   * Departments and subject groups are per-school, not global. Thai schools
--     do not share one canonical list — the hardcoded six/ten were one
--     school's structure imposed on every tenant.
--
--   * A staff member can belong to more than one of each (a teacher is often
--     in a subject group AND on an administrative ฝ่าย), so membership is a
--     join table rather than a column on `users`.
--
--   * `is_head` marks หัวหน้าฝ่าย / หัวหน้ากลุ่มสาระ. It is a property of the
--     membership, not of the person, because the same teacher can head one
--     group while being an ordinary member of another.
--
--   * `position_title` (ครูชำนาญการ, ครูชำนาญการพิเศษ …) lives on
--     `staff_profiles` rather than on a membership: it is an academic standing
--     held by the person, independent of which group they sit in.
--
-- Everything here is additive. No existing table or RPC is modified.

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.departments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id uuid NOT NULL REFERENCES public.schools(id),
  name varchar NOT NULL,
  -- 'administrative' = ฝ่าย (ฝ่ายวิชาการ, ฝ่ายปกครอง …)
  -- 'subject_group'  = กลุ่มสาระการเรียนรู้ (วิทยาศาสตร์, คณิตศาสตร์ …)
  -- One table with a kind, rather than two near-identical ones: they are
  -- managed the same way, listed the same way, and a person joins both the
  -- same way.
  kind varchar NOT NULL CHECK (kind IN ('administrative', 'subject_group')),
  sort_order int NOT NULL DEFAULT 0,
  created_by uuid NOT NULL REFERENCES public.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (school_id, kind, name)
);

ALTER TABLE public.departments ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS departments_school_kind_idx
  ON public.departments (school_id, kind, sort_order);

CREATE TABLE IF NOT EXISTS public.department_members (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  department_id uuid NOT NULL REFERENCES public.departments(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  is_head boolean NOT NULL DEFAULT false,
  assigned_by uuid NOT NULL REFERENCES public.users(id),
  assigned_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (department_id, user_id)
);

ALTER TABLE public.department_members ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS department_members_user_idx
  ON public.department_members (user_id);

-- Staff-only attributes that do not belong on `users` (which also holds
-- students and parents). One row per staff member, created on demand.
CREATE TABLE IF NOT EXISTS public.staff_profiles (
  user_id uuid PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
  school_id uuid NOT NULL REFERENCES public.schools(id),
  -- ครูผู้ช่วย / ครู / ครูชำนาญการ / ครูชำนาญการพิเศษ / ผู้อำนวยการ …
  -- Free text on purpose: the ladder differs between school types and
  -- changes with ก.ค.ศ. rules. A check constraint here would age badly.
  position_title varchar,
  phone varchar,
  updated_by uuid REFERENCES public.users(id),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.staff_profiles ENABLE ROW LEVEL SECURITY;

-- ---------------------------------------------------------------------------
-- Reads
-- ---------------------------------------------------------------------------

-- Both roles that manage or review staff can read the structure. `executive`
-- is included deliberately: the director's personnel page is the main reason
-- this exists.
CREATE OR REPLACE FUNCTION public.list_departments(
  p_token text,
  p_kind text DEFAULT NULL
)
RETURNS TABLE (
  department_id uuid,
  name varchar,
  kind varchar,
  sort_order int,
  member_count int,
  head_name text
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

  IF v_actor.role NOT IN ('school_admin', 'executive', 'super_admin') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  RETURN QUERY
  SELECT
    d.id,
    d.name,
    d.kind,
    d.sort_order,
    (SELECT count(*)::int FROM public.department_members m
      WHERE m.department_id = d.id),
    (SELECT string_agg(trim(u.first_name || ' ' || u.last_name), ', ')
       FROM public.department_members m
       JOIN public.users u ON u.id = m.user_id
      WHERE m.department_id = d.id AND m.is_head)
  FROM public.departments d
  WHERE d.school_id = v_actor.school_id
    AND (p_kind IS NULL OR d.kind = p_kind)
  ORDER BY d.kind, d.sort_order, d.created_at;
END;
$$;

-- Every staff member with their groups and standing, for the personnel
-- directory. Students and parents are excluded — this is a staff view.
CREATE OR REPLACE FUNCTION public.list_staff_directory(p_token text)
RETURNS TABLE (
  user_id uuid,
  full_name text,
  email varchar,
  status varchar,
  position_title varchar,
  phone varchar,
  roles text[],
  administrative_departments text[],
  subject_groups text[],
  heads_departments text[]
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

  IF v_actor.role NOT IN ('school_admin', 'executive', 'super_admin') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  RETURN QUERY
  SELECT
    u.id,
    trim(u.first_name || ' ' || u.last_name),
    u.email,
    u.status::varchar,
    sp.position_title,
    sp.phone,
    -- An account can hold more than one role; collapsing to one would hide
    -- staff from role-filtered lists, the same bug `all_roles` was added to
    -- `list_school_users` to fix.
    ARRAY(
      SELECT DISTINCT ur.role::text FROM public.user_roles ur
       WHERE ur.user_id = u.id AND ur.school_id = u.school_id
       ORDER BY ur.role::text
    ),
    -- `departments.name` is varchar; the declared return type is text[], so
    -- each element is cast rather than relying on an implicit match that
    -- Postgres refuses at RETURN QUERY time.
    ARRAY(
      SELECT d.name::text FROM public.department_members m
       JOIN public.departments d ON d.id = m.department_id
      WHERE m.user_id = u.id AND d.kind = 'administrative'
      ORDER BY d.sort_order
    ),
    ARRAY(
      SELECT d.name::text FROM public.department_members m
       JOIN public.departments d ON d.id = m.department_id
      WHERE m.user_id = u.id AND d.kind = 'subject_group'
      ORDER BY d.sort_order
    ),
    ARRAY(
      SELECT d.name::text FROM public.department_members m
       JOIN public.departments d ON d.id = m.department_id
      WHERE m.user_id = u.id AND m.is_head
      ORDER BY d.sort_order
    )
  FROM public.users u
  LEFT JOIN public.staff_profiles sp ON sp.user_id = u.id
  WHERE u.school_id = v_actor.school_id
    AND EXISTS (
      SELECT 1 FROM public.user_roles ur
       WHERE ur.user_id = u.id
         AND ur.school_id = u.school_id
         AND ur.role IN ('teacher', 'school_admin', 'executive')
    )
  ORDER BY trim(u.first_name || ' ' || u.last_name);
END;
$$;

-- ---------------------------------------------------------------------------
-- Writes (school_admin owns the structure; executive reads only)
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.create_department(
  p_token text,
  p_name text,
  p_kind text,
  p_sort_order int DEFAULT 0
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_id uuid;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  IF v_actor.role NOT IN ('school_admin', 'super_admin') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  IF p_kind NOT IN ('administrative', 'subject_group') THEN
    RAISE EXCEPTION 'invalid_kind';
  END IF;

  IF coalesce(trim(p_name), '') = '' THEN
    RAISE EXCEPTION 'name_required';
  END IF;

  INSERT INTO public.departments (school_id, name, kind, sort_order, created_by)
  VALUES (v_actor.school_id, trim(p_name), p_kind, p_sort_order, v_actor.user_id)
  RETURNING id INTO v_id;

  INSERT INTO public.audit_logs
    (school_id, user_id, acted_role, action, entity_type, entity_id, details)
  VALUES (
    v_actor.school_id, v_actor.user_id, v_actor.role,
    'department.create', 'departments', v_id::text,
    jsonb_build_object('name', trim(p_name), 'kind', p_kind)
  );

  RETURN v_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.update_department(
  p_token text,
  p_department_id uuid,
  p_name text,
  p_sort_order int
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_dept record;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  IF v_actor.role NOT IN ('school_admin', 'super_admin') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  SELECT * INTO v_dept FROM public.departments WHERE id = p_department_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'department_not_found';
  END IF;

  -- Cross-school writes are refused even for a valid session.
  IF v_actor.role <> 'super_admin'
     AND v_dept.school_id IS DISTINCT FROM v_actor.school_id THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  IF coalesce(trim(p_name), '') = '' THEN
    RAISE EXCEPTION 'name_required';
  END IF;

  UPDATE public.departments
     SET name = trim(p_name), sort_order = p_sort_order
   WHERE id = p_department_id;

  INSERT INTO public.audit_logs
    (school_id, user_id, acted_role, action, entity_type, entity_id, details)
  VALUES (
    v_dept.school_id, v_actor.user_id, v_actor.role,
    'department.update', 'departments', p_department_id::text,
    jsonb_build_object('name', trim(p_name))
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.delete_department(
  p_token text,
  p_department_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_dept record;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  IF v_actor.role NOT IN ('school_admin', 'super_admin') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  SELECT * INTO v_dept FROM public.departments WHERE id = p_department_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'department_not_found';
  END IF;

  IF v_actor.role <> 'super_admin'
     AND v_dept.school_id IS DISTINCT FROM v_actor.school_id THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  -- Memberships cascade; the people themselves are untouched.
  DELETE FROM public.departments WHERE id = p_department_id;

  INSERT INTO public.audit_logs
    (school_id, user_id, acted_role, action, entity_type, entity_id, details)
  VALUES (
    v_dept.school_id, v_actor.user_id, v_actor.role,
    'department.delete', 'departments', p_department_id::text,
    jsonb_build_object('name', v_dept.name, 'kind', v_dept.kind)
  );
END;
$$;

-- Add or update one membership. Idempotent on (department, user) so the UI
-- can send the same assignment twice without creating a duplicate.
CREATE OR REPLACE FUNCTION public.set_department_member(
  p_token text,
  p_department_id uuid,
  p_user_id uuid,
  p_is_head boolean DEFAULT false
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_dept record;
  v_target record;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  IF v_actor.role NOT IN ('school_admin', 'super_admin') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  SELECT * INTO v_dept FROM public.departments WHERE id = p_department_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'department_not_found';
  END IF;

  SELECT * INTO v_target FROM public.users WHERE id = p_user_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'user_not_found';
  END IF;

  -- The department, the actor and the person must all be the same school.
  IF v_actor.role <> 'super_admin'
     AND (v_dept.school_id IS DISTINCT FROM v_actor.school_id
          OR v_target.school_id IS DISTINCT FROM v_actor.school_id) THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  IF v_target.school_id IS DISTINCT FROM v_dept.school_id THEN
    RAISE EXCEPTION 'cross_school_assignment';
  END IF;

  INSERT INTO public.department_members
    (department_id, user_id, is_head, assigned_by)
  VALUES (p_department_id, p_user_id, coalesce(p_is_head, false), v_actor.user_id)
  ON CONFLICT (department_id, user_id)
  DO UPDATE SET is_head = excluded.is_head,
                assigned_by = excluded.assigned_by,
                assigned_at = now();

  INSERT INTO public.audit_logs
    (school_id, user_id, acted_role, action, entity_type, entity_id, details)
  VALUES (
    v_dept.school_id, v_actor.user_id, v_actor.role,
    'department.assign_member', 'department_members', p_department_id::text,
    jsonb_build_object('user_id', p_user_id, 'is_head', coalesce(p_is_head, false))
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.remove_department_member(
  p_token text,
  p_department_id uuid,
  p_user_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_dept record;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  IF v_actor.role NOT IN ('school_admin', 'super_admin') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  SELECT * INTO v_dept FROM public.departments WHERE id = p_department_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'department_not_found';
  END IF;

  IF v_actor.role <> 'super_admin'
     AND v_dept.school_id IS DISTINCT FROM v_actor.school_id THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  DELETE FROM public.department_members
   WHERE department_id = p_department_id AND user_id = p_user_id;

  INSERT INTO public.audit_logs
    (school_id, user_id, acted_role, action, entity_type, entity_id, details)
  VALUES (
    v_dept.school_id, v_actor.user_id, v_actor.role,
    'department.remove_member', 'department_members', p_department_id::text,
    jsonb_build_object('user_id', p_user_id)
  );
END;
$$;

-- Position title and phone. Separate from `update_user_profile`, which owns
-- the name and is callable by the user themselves; this is staff metadata a
-- school_admin maintains.
CREATE OR REPLACE FUNCTION public.set_staff_profile(
  p_token text,
  p_user_id uuid,
  p_position_title text,
  p_phone text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_target record;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  IF v_actor.role NOT IN ('school_admin', 'super_admin') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  SELECT * INTO v_target FROM public.users WHERE id = p_user_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'user_not_found';
  END IF;

  IF v_actor.role <> 'super_admin'
     AND v_target.school_id IS DISTINCT FROM v_actor.school_id THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  INSERT INTO public.staff_profiles
    (user_id, school_id, position_title, phone, updated_by, updated_at)
  VALUES (
    p_user_id, v_target.school_id,
    nullif(trim(coalesce(p_position_title, '')), ''),
    nullif(trim(coalesce(p_phone, '')), ''),
    v_actor.user_id, now()
  )
  ON CONFLICT (user_id) DO UPDATE
    SET position_title = excluded.position_title,
        phone = excluded.phone,
        updated_by = excluded.updated_by,
        updated_at = now();

  INSERT INTO public.audit_logs
    (school_id, user_id, acted_role, action, entity_type, entity_id, details)
  VALUES (
    v_target.school_id, v_actor.user_id, v_actor.role,
    'staff_profile.update', 'staff_profiles', p_user_id::text,
    jsonb_build_object('position_title', p_position_title)
  );
END;
$$;

-- ---------------------------------------------------------------------------
-- Grants
--
-- `service_role` is revoked explicitly on every function. It is not a member
-- of anon/authenticated, so a grant to those does not reach it — but this
-- project has leaked access three times by assuming the reverse, so each one
-- is stated.
-- ---------------------------------------------------------------------------

REVOKE ALL ON FUNCTION public.list_departments FROM PUBLIC, service_role;
GRANT EXECUTE ON FUNCTION public.list_departments TO anon, authenticated;

REVOKE ALL ON FUNCTION public.list_staff_directory FROM PUBLIC, service_role;
GRANT EXECUTE ON FUNCTION public.list_staff_directory TO anon, authenticated;

REVOKE ALL ON FUNCTION public.create_department FROM PUBLIC, service_role;
GRANT EXECUTE ON FUNCTION public.create_department TO anon, authenticated;

REVOKE ALL ON FUNCTION public.update_department FROM PUBLIC, service_role;
GRANT EXECUTE ON FUNCTION public.update_department TO anon, authenticated;

REVOKE ALL ON FUNCTION public.delete_department FROM PUBLIC, service_role;
GRANT EXECUTE ON FUNCTION public.delete_department TO anon, authenticated;

REVOKE ALL ON FUNCTION public.set_department_member FROM PUBLIC, service_role;
GRANT EXECUTE ON FUNCTION public.set_department_member TO anon, authenticated;

REVOKE ALL ON FUNCTION public.remove_department_member FROM PUBLIC, service_role;
GRANT EXECUTE ON FUNCTION public.remove_department_member TO anon, authenticated;

REVOKE ALL ON FUNCTION public.set_staff_profile FROM PUBLIC, service_role;
GRANT EXECUTE ON FUNCTION public.set_staff_profile TO anon, authenticated;
