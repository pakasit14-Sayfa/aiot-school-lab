-- Migration: 20260826170000_teacher_close_course_update_rubric.sql
-- Description: Two real RPCs found missing during the teacher-pages fake-write
--   audit — both had a fake client-only "success" UI with no backend call.
-- RPCs:
-- 1. close_course(p_token, p_course_id) — courses.status/closed_at already
--    existed in the schema, just had no RPC to set them.
-- 2. update_rubric(p_token, p_rubric_id, p_title, p_description, p_criteria)
--    — mirrors create_rubric's insert logic for criteria, but as a real
--    update: matches incoming criteria by id (update in place), inserts
--    criteria with no id, and only deletes criteria that are no longer in
--    the incoming list AND have no real grade_criterion_scores referencing
--    them — never silently destroys historical grade data.

CREATE OR REPLACE FUNCTION public.close_course(
  p_token text,
  p_course_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'extensions'
AS $$
DECLARE
  v_actor RECORD;
  v_course RECORD;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;
  IF v_actor.role NOT IN ('teacher', 'school_admin', 'super_admin') THEN
    RAISE EXCEPTION 'forbidden: teacher, school_admin or super_admin role required';
  END IF;

  SELECT id, school_id, created_by, status INTO v_course
  FROM public.courses
  WHERE id = p_course_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'course_not_found';
  END IF;

  IF v_actor.role = 'teacher' AND v_course.created_by != v_actor.user_id THEN
    RAISE EXCEPTION 'forbidden: not your course';
  END IF;
  IF v_actor.role != 'super_admin' AND v_course.school_id != v_actor.school_id THEN
    RAISE EXCEPTION 'forbidden: course does not belong to your school';
  END IF;

  IF v_course.status = 'closed' THEN
    RAISE EXCEPTION 'course_already_closed';
  END IF;

  UPDATE public.courses
  SET status = 'closed', closed_at = now()
  WHERE id = p_course_id;

  INSERT INTO public.audit_logs (
    school_id, user_id, acted_role, action, entity_type, entity_id, details
  ) VALUES (
    v_course.school_id,
    v_actor.user_id,
    v_actor.role,
    'course.close',
    'courses',
    p_course_id::text,
    '{}'::jsonb
  );

  RETURN jsonb_build_object('success', true, 'course_id', p_course_id, 'status', 'closed');
END;
$$;

CREATE OR REPLACE FUNCTION public.update_rubric(
  p_token text,
  p_rubric_id uuid,
  p_title text,
  p_description text DEFAULT NULL,
  p_criteria jsonb DEFAULT '[]'::jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'extensions'
AS $$
DECLARE
  v_actor RECORD;
  v_rubric RECORD;
  v_crit jsonb;
  v_sort int := 0;
  v_crit_id uuid;
  v_kept_ids uuid[] := ARRAY[]::uuid[];
  v_protected_count int;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;
  IF v_actor.role NOT IN ('school_admin', 'teacher') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  SELECT id, school_id, created_by INTO v_rubric
  FROM public.rubrics
  WHERE id = p_rubric_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'rubric_not_found';
  END IF;
  IF v_rubric.school_id != v_actor.school_id THEN
    RAISE EXCEPTION 'forbidden: rubric does not belong to your school';
  END IF;

  IF trim(coalesce(p_title, '')) = '' THEN
    RAISE EXCEPTION 'title_required';
  END IF;

  UPDATE public.rubrics
  SET title = trim(p_title), description = trim(p_description)
  WHERE id = p_rubric_id;

  IF p_criteria IS NOT NULL THEN
    FOR v_crit IN SELECT * FROM jsonb_array_elements(p_criteria)
    LOOP
      v_sort := v_sort + 1;
      v_crit_id := NULLIF(v_crit->>'id', '')::uuid;

      IF v_crit_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM public.rubric_criteria WHERE id = v_crit_id AND rubric_id = p_rubric_id
      ) THEN
        UPDATE public.rubric_criteria
        SET name = coalesce(v_crit->>'name', 'เกณฑ์ที่ ' || v_sort),
            description = v_crit->>'description',
            max_score = coalesce((v_crit->>'max_score')::numeric, 10),
            levels = v_crit->'levels',
            sort_order = v_sort
        WHERE id = v_crit_id;
        v_kept_ids := array_append(v_kept_ids, v_crit_id);
      ELSE
        INSERT INTO public.rubric_criteria (rubric_id, name, description, max_score, levels, sort_order)
        VALUES (
          p_rubric_id,
          coalesce(v_crit->>'name', 'เกณฑ์ที่ ' || v_sort),
          v_crit->>'description',
          coalesce((v_crit->>'max_score')::numeric, 10),
          v_crit->'levels',
          v_sort
        )
        RETURNING id INTO v_crit_id;
        v_kept_ids := array_append(v_kept_ids, v_crit_id);
      END IF;
    END LOOP;
  END IF;

  -- Only remove criteria that were dropped from the incoming list AND have
  -- no real grade_criterion_scores referencing them — never silently
  -- destroy historical grading data.
  SELECT count(*) INTO v_protected_count
  FROM public.rubric_criteria rc
  WHERE rc.rubric_id = p_rubric_id
    AND rc.id != ALL(v_kept_ids)
    AND EXISTS (SELECT 1 FROM public.grade_criterion_scores gcs WHERE gcs.criterion_id = rc.id);

  DELETE FROM public.rubric_criteria rc
  WHERE rc.rubric_id = p_rubric_id
    AND rc.id != ALL(v_kept_ids)
    AND NOT EXISTS (SELECT 1 FROM public.grade_criterion_scores gcs WHERE gcs.criterion_id = rc.id);

  RETURN jsonb_build_object(
    'success', true,
    'rubric_id', p_rubric_id,
    'protected_criteria_not_deleted', v_protected_count
  );
END;
$$;

REVOKE ALL ON FUNCTION public.close_course(text, uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.close_course(text, uuid) TO anon, authenticated, service_role;

REVOKE ALL ON FUNCTION public.update_rubric(text, uuid, text, text, jsonb) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.update_rubric(text, uuid, text, text, jsonb) TO anon, authenticated, service_role;
