-- Red-team finding: record_class_substitution silently overwrites the row
-- on reassignment (ON CONFLICT ... DO UPDATE) with no trace of who assigned
-- it originally vs who changed it. Add updated_by/updated_at so a
-- reassignment is visible instead of indistinguishable from the first
-- assignment.
ALTER TABLE class_substitutions
  ADD COLUMN updated_by uuid REFERENCES users(id),
  ADD COLUMN updated_at timestamptz;

-- Return shape changed (added `reassigned`) -- CREATE OR REPLACE cannot
-- change a function's return columns in place (same lesson already hit
-- twice this session for set_class_schedule / list_executive_students...).
DROP FUNCTION IF EXISTS public.record_class_substitution(text, uuid, date, uuid, uuid, text);
CREATE FUNCTION public.record_class_substitution(
  p_token text, p_class_schedule_id uuid, p_class_date date,
  p_original_teacher_id uuid, p_substitute_teacher_id uuid,
  p_note text DEFAULT NULL::text
) RETURNS TABLE(substitution_id uuid, reassigned boolean)
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public', 'extensions'
AS $function$
DECLARE v_actor record; v_school uuid; v_id uuid; v_existed boolean;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN RAISE EXCEPTION 'invalid_session'; END IF;
  IF v_actor.role NOT IN ('school_admin', 'executive', 'super_admin')
     OR v_actor.school_id IS NULL THEN RAISE EXCEPTION 'forbidden'; END IF;

  SELECT c.school_id INTO v_school
  FROM class_schedules cs JOIN courses c ON c.id = cs.course_id
  WHERE cs.id = p_class_schedule_id;
  IF NOT FOUND OR v_school IS DISTINCT FROM v_actor.school_id THEN
    RAISE EXCEPTION 'schedule_not_found';
  END IF;

  IF p_substitute_teacher_id = p_original_teacher_id THEN
    RAISE EXCEPTION 'substitute_cannot_be_original_teacher';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM users u JOIN user_roles r ON r.user_id = u.id AND r.role = 'teacher'
    WHERE u.id = p_substitute_teacher_id AND u.school_id = v_actor.school_id AND u.status = 'active'
  ) THEN RAISE EXCEPTION 'substitute_teacher_not_found'; END IF;

  SELECT EXISTS (
    SELECT 1 FROM class_substitutions
    WHERE class_schedule_id = p_class_schedule_id AND class_date = p_class_date
  ) INTO v_existed;

  INSERT INTO class_substitutions (school_id, class_schedule_id, class_date, original_teacher_id, substitute_teacher_id, note, created_by)
  VALUES (v_actor.school_id, p_class_schedule_id, p_class_date, p_original_teacher_id, p_substitute_teacher_id, p_note, v_actor.user_id)
  ON CONFLICT (class_schedule_id, class_date) DO UPDATE
    SET substitute_teacher_id = excluded.substitute_teacher_id,
        original_teacher_id = excluded.original_teacher_id,
        note = excluded.note,
        updated_by = excluded.created_by,
        updated_at = now()
  RETURNING id INTO v_id;

  RETURN QUERY SELECT v_id, v_existed;
END;
$function$;
REVOKE ALL ON FUNCTION public.record_class_substitution(text, uuid, date, uuid, uuid, text) FROM PUBLIC,service_role;
GRANT EXECUTE ON FUNCTION public.record_class_substitution(text, uuid, date, uuid, uuid, text) TO anon,authenticated;

-- list_periods_needing_substitute: surface who assigned it and when it was
-- last changed, so a reassignment is visible in the UI, not just "covered".
DROP FUNCTION IF EXISTS public.list_periods_needing_substitute(text, date);
CREATE FUNCTION public.list_periods_needing_substitute(p_token text, p_date date)
RETURNS TABLE(
  class_schedule_id uuid, subject_name character varying, grade_level character varying, room character varying,
  start_time time without time zone, end_time time without time zone,
  original_teacher_id uuid, original_teacher_name text,
  already_covered boolean, substitute_teacher_name text,
  assigned_by_name text, reassigned boolean
)
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public', 'extensions'
AS $function$
DECLARE v_actor record; v_dow int;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN RAISE EXCEPTION 'invalid_session'; END IF;
  IF v_actor.role NOT IN ('school_admin', 'executive', 'super_admin')
     OR v_actor.school_id IS NULL THEN RAISE EXCEPTION 'forbidden'; END IF;

  v_dow := EXTRACT(isodow FROM p_date)::int - 1;

  RETURN QUERY
  SELECT cs.id, c.subject_name, c.grade_level, cs.room, cs.start_time, cs.end_time,
    ct.teacher_id, trim(coalesce(u.first_name, '') || ' ' || coalesce(u.last_name, '')),
    (sub.id IS NOT NULL), trim(coalesce(su.first_name, '') || ' ' || coalesce(su.last_name, '')),
    CASE WHEN sub.updated_by IS NOT NULL
      THEN trim(coalesce(uu.first_name, '') || ' ' || coalesce(uu.last_name, ''))
      ELSE trim(coalesce(uc.first_name, '') || ' ' || coalesce(uc.last_name, ''))
    END,
    (sub.updated_by IS NOT NULL)
  FROM class_schedules cs
  JOIN courses c ON c.id = cs.course_id AND c.school_id = v_actor.school_id AND c.status = 'active'
  JOIN course_teachers ct ON ct.course_id = c.id
  JOIN users u ON u.id = ct.teacher_id
  JOIN staff_leave_requests lr ON lr.user_id = ct.teacher_id AND lr.status = 'approved'
    AND p_date BETWEEN lr.start_date AND lr.end_date
  LEFT JOIN class_substitutions sub ON sub.class_schedule_id = cs.id AND sub.class_date = p_date
  LEFT JOIN users su ON su.id = sub.substitute_teacher_id
  LEFT JOIN users uc ON uc.id = sub.created_by
  LEFT JOIN users uu ON uu.id = sub.updated_by
  WHERE cs.day_of_week = v_dow
  ORDER BY cs.start_time;
END;
$function$;
REVOKE ALL ON FUNCTION public.list_periods_needing_substitute(text, date) FROM PUBLIC,service_role;
GRANT EXECUTE ON FUNCTION public.list_periods_needing_substitute(text, date) TO anon,authenticated;
