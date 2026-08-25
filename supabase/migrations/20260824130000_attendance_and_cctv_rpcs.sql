-- Migration: 20260824130000_attendance_and_cctv_rpcs.sql
-- Description: Creates attendance_records table and RPCs for Attendance & CCTV access grants

-- 1. Attendance Records Table
CREATE TABLE IF NOT EXISTS public.attendance_records (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id uuid NOT NULL REFERENCES public.courses(id) ON DELETE CASCADE,
  student_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  class_date date NOT NULL,
  status text NOT NULL CHECK (status IN ('present', 'late', 'absent', 'excused')),
  marked_by uuid NOT NULL REFERENCES public.users(id),
  marked_at timestamptz NOT NULL DEFAULT now(),
  note text,
  UNIQUE (course_id, student_id, class_date)
);

ALTER TABLE public.attendance_records ENABLE ROW LEVEL SECURITY;

-- 2. mark_attendance (Teacher bulk upsert)
CREATE OR REPLACE FUNCTION public.mark_attendance(
  p_token text,
  p_course_id uuid,
  p_class_date date,
  p_records jsonb
)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_rec jsonb;
  v_student_id uuid;
  v_status text;
  v_note text;
  v_count integer := 0;
BEGIN
  v_actor := get_session_actor(p_token);
  
  IF v_actor.role = 'teacher' THEN
    IF NOT EXISTS (
      SELECT 1 FROM public.course_teachers
      WHERE course_id = p_course_id AND teacher_id = v_actor.user_id
    ) THEN
      RAISE EXCEPTION 'forbidden';
    END IF;
  ELSIF v_actor.role NOT IN ('school_admin', 'executive', 'super_admin') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.courses
    WHERE id = p_course_id AND school_id = v_actor.school_id
  ) THEN
    RAISE EXCEPTION 'course_not_found';
  END IF;

  IF jsonb_typeof(p_records) != 'array' THEN
    RAISE EXCEPTION 'invalid_records_format';
  END IF;

  FOR v_rec IN SELECT * FROM jsonb_array_elements(p_records)
  LOOP
    v_student_id := (v_rec->>'student_id')::uuid;
    v_status := v_rec->>'status';
    v_note := v_rec->>'note';

    IF v_status NOT IN ('present', 'late', 'absent', 'excused') THEN
      RAISE EXCEPTION 'invalid_status';
    END IF;

    IF NOT EXISTS (
      SELECT 1 FROM public.course_students
      WHERE course_id = p_course_id AND student_id = v_student_id
    ) THEN
      RAISE EXCEPTION 'student_not_enrolled';
    END IF;

    INSERT INTO public.attendance_records (
      course_id, student_id, class_date, status, marked_by, marked_at, note
    )
    VALUES (
      p_course_id, v_student_id, p_class_date, v_status, v_actor.user_id, now(), v_note
    )
    ON CONFLICT (course_id, student_id, class_date)
    DO UPDATE SET
      status = EXCLUDED.status,
      marked_by = EXCLUDED.marked_by,
      marked_at = now(),
      note = EXCLUDED.note;

    v_count := v_count + 1;
  END LOOP;

  RETURN v_count;
END;
$$;

-- 3. list_course_attendance (Teacher roster view)
CREATE OR REPLACE FUNCTION public.list_course_attendance(
  p_token text,
  p_course_id uuid,
  p_class_date date
)
RETURNS TABLE (
  student_id uuid,
  student_name text,
  student_code text,
  status text,
  note text,
  marked_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
BEGIN
  v_actor := get_session_actor(p_token);

  IF v_actor.role = 'teacher' THEN
    IF NOT EXISTS (
      SELECT 1 FROM public.course_teachers
      WHERE course_id = p_course_id AND teacher_id = v_actor.user_id
    ) THEN
      RAISE EXCEPTION 'forbidden';
    END IF;
  ELSIF v_actor.role NOT IN ('school_admin', 'executive', 'super_admin') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.courses
    WHERE id = p_course_id AND school_id = v_actor.school_id
  ) THEN
    RAISE EXCEPTION 'course_not_found';
  END IF;

  RETURN QUERY
  SELECT
    u.id AS student_id,
    (u.first_name || ' ' || u.last_name)::text AS student_name,
    coalesce(u.student_code, '')::text AS student_code,
    ar.status,
    ar.note,
    ar.marked_at
  FROM public.course_students cs
  JOIN public.users u ON u.id = cs.student_id
  LEFT JOIN public.attendance_records ar
    ON ar.course_id = cs.course_id
   AND ar.student_id = cs.student_id
   AND ar.class_date = p_class_date
  WHERE cs.course_id = p_course_id
  ORDER BY u.first_name ASC, u.last_name ASC;
END;
$$;

-- 4. list_my_student_attendance (Parent portal)
CREATE OR REPLACE FUNCTION public.list_my_student_attendance(
  p_token text,
  p_student_id uuid,
  p_date_from date DEFAULT NULL,
  p_date_to date DEFAULT NULL
)
RETURNS TABLE (
  record_id uuid,
  course_id uuid,
  course_name text,
  course_code text,
  class_date date,
  status text,
  note text,
  marked_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
BEGIN
  v_actor := get_session_actor(p_token);

  IF v_actor.role != 'parent' THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.parent_links pl
    WHERE pl.parent_id = v_actor.user_id
      AND pl.student_id = p_student_id
      AND pl.status = 'approved'
  ) THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  RETURN QUERY
  SELECT
    ar.id AS record_id,
    c.id AS course_id,
    c.subject_name::text AS course_name,
    coalesce(c.grade_level, '')::text AS course_code,
    ar.class_date,
    ar.status,
    ar.note,
    ar.marked_at
  FROM public.attendance_records ar
  JOIN public.courses c ON c.id = ar.course_id
  WHERE ar.student_id = p_student_id
    AND (p_date_from IS NULL OR ar.class_date >= p_date_from)
    AND (p_date_to IS NULL OR ar.class_date <= p_date_to)
  ORDER BY ar.class_date DESC, ar.marked_at DESC;
END;
$$;

-- 5. list_camera_access_grants (Executive / School Admin)
CREATE OR REPLACE FUNCTION public.list_camera_access_grants(
  p_token text
)
RETURNS TABLE (
  grant_id uuid,
  camera_device_id uuid,
  camera_name text,
  location text,
  building text,
  room text,
  user_id uuid,
  user_name text,
  user_email text,
  user_role text,
  reason text,
  valid_from timestamptz,
  valid_until timestamptz,
  granted_at timestamptz,
  granted_by_name text,
  is_active boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
BEGIN
  v_actor := get_session_actor(p_token);

  IF v_actor.role NOT IN ('executive', 'school_admin', 'super_admin') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  RETURN QUERY
  SELECT
    cag.id AS grant_id,
    cag.camera_device_id,
    coalesce(d.name, 'ไม่ระบุชื่อกล้อง')::text AS camera_name,
    coalesce(d.location, '')::text AS location,
    coalesce(d.building, '')::text AS building,
    coalesce(d.room, '')::text AS room,
    u.id AS user_id,
    (u.first_name || ' ' || u.last_name)::text AS user_name,
    u.email::text AS user_email,
    ur.role::text AS user_role,
    cag.reason,
    cag.valid_from,
    cag.valid_until,
    cag.granted_at,
    (gb.first_name || ' ' || gb.last_name)::text AS granted_by_name,
    (cag.revoked_at IS NULL AND cag.valid_until > now()) AS is_active
  FROM public.camera_access_grants cag
  LEFT JOIN public.devices d ON d.id = cag.camera_device_id
  JOIN public.users u ON u.id = cag.user_id
  LEFT JOIN public.user_roles ur ON ur.user_id = u.id
  LEFT JOIN public.users gb ON gb.id = cag.granted_by
  WHERE cag.school_id = v_actor.school_id
  ORDER BY cag.granted_at DESC;
END;
$$;

-- 6. grant_camera_access (Executive / School Admin)
CREATE OR REPLACE FUNCTION public.grant_camera_access(
  p_token text,
  p_user_id uuid,
  p_camera_device_id uuid,
  p_reason text,
  p_valid_until timestamptz
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_grant_id uuid;
BEGIN
  v_actor := get_session_actor(p_token);

  IF v_actor.role NOT IN ('executive', 'school_admin', 'super_admin') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = p_user_id AND school_id = v_actor.school_id
  ) THEN
    RAISE EXCEPTION 'user_not_found';
  END IF;

  IF p_camera_device_id IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1 FROM public.devices
      WHERE id = p_camera_device_id AND school_id = v_actor.school_id AND type = 'camera'
    ) THEN
      RAISE EXCEPTION 'camera_not_found';
    END IF;
  END IF;

  IF p_valid_until <= now() THEN
    RAISE EXCEPTION 'invalid_expiry';
  END IF;

  INSERT INTO public.camera_access_grants (
    school_id, user_id, camera_device_id, granted_by, reason, valid_from, valid_until, granted_at
  )
  VALUES (
    v_actor.school_id, p_user_id, p_camera_device_id, v_actor.user_id, p_reason, now(), p_valid_until, now()
  )
  RETURNING id INTO v_grant_id;

  RETURN v_grant_id;
END;
$$;

-- 7. revoke_camera_access (Executive / School Admin)
CREATE OR REPLACE FUNCTION public.revoke_camera_access(
  p_token text,
  p_grant_id uuid
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
BEGIN
  v_actor := get_session_actor(p_token);

  IF v_actor.role NOT IN ('executive', 'school_admin', 'super_admin') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  UPDATE public.camera_access_grants
  SET revoked_at = now()
  WHERE id = p_grant_id
    AND school_id = v_actor.school_id
    AND revoked_at IS NULL;

  RETURN FOUND;
END;
$$;

-- Revoke all from anon/authenticated and grant execute to anon/authenticated
REVOKE ALL ON FUNCTION public.mark_attendance FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.mark_attendance TO anon, authenticated;

REVOKE ALL ON FUNCTION public.list_course_attendance FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.list_course_attendance TO anon, authenticated;

REVOKE ALL ON FUNCTION public.list_my_student_attendance FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.list_my_student_attendance TO anon, authenticated;

REVOKE ALL ON FUNCTION public.list_camera_access_grants FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.list_camera_access_grants TO anon, authenticated;

REVOKE ALL ON FUNCTION public.grant_camera_access FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.grant_camera_access TO anon, authenticated;

REVOKE ALL ON FUNCTION public.revoke_camera_access FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.revoke_camera_access TO anon, authenticated;
