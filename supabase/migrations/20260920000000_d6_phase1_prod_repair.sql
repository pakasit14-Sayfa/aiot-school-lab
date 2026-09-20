-- 20260920000000_d6_phase1_prod_repair.sql
-- =====================================================================
-- Production received the UNREVIEWED version of 20260919000000 (agy's
-- 9bd32dc, applied 2026-09-20 via `db push` before the review fixes in
-- 5beea08 landed). Local resets already run the fixed 20260919 file, so
-- this migration re-applies the fixed definitions idempotently on top of
-- whichever version a database has:
--   * create_course: term must belong to the actor's school (security)
--   * set_class_schedule: drop the stale (...,text,text) overload, one
--     signature with p_period_type + p_period_no, school_admin only
--   * _class_room_key + room-key matching in both sync functions
--     (prod stores profile room '1' vs course room 'ม.1/1')
--   * owner-only replace in admin_set_room_timetable_slot
--   * grants; backfill re-run so prod's ม.1/1 students get enrolled
-- Every statement below is CREATE OR REPLACE / DROP IF EXISTS / guarded,
-- so running it on the fixed schema changes nothing.
-- =====================================================================


-- 1. teacher_subjects
CREATE TABLE IF NOT EXISTS public.teacher_subjects (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id uuid NOT NULL REFERENCES public.schools(id) ON DELETE CASCADE,
    teacher_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    subject_name varchar NOT NULL,
    created_by uuid,
    created_at timestamptz DEFAULT now(),
    UNIQUE (teacher_id, subject_name)
);
ALTER TABLE public.teacher_subjects ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.set_teacher_subjects(p_token text, p_teacher_id uuid, p_subjects text[])
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
    v_actor record;
    v_subject text;
BEGIN
    SELECT * INTO v_actor FROM get_session_actor(p_token);
    IF NOT FOUND THEN RAISE EXCEPTION 'invalid_session'; END IF;
    IF v_actor.role not in ('school_admin') THEN RAISE EXCEPTION 'forbidden'; END IF;

    IF NOT EXISTS (
        SELECT 1 FROM users u
        JOIN user_roles ur ON ur.user_id = u.id
        WHERE u.id = p_teacher_id AND u.school_id = v_actor.school_id AND ur.role = 'teacher'
    ) THEN
        RAISE EXCEPTION 'teacher_not_found';
    END IF;

    DELETE FROM public.teacher_subjects WHERE teacher_id = p_teacher_id AND school_id = v_actor.school_id;

    IF p_subjects IS NOT NULL THEN
        FOREACH v_subject IN ARRAY p_subjects LOOP
            IF trim(v_subject) <> '' THEN
                INSERT INTO public.teacher_subjects (school_id, teacher_id, subject_name, created_by)
                VALUES (v_actor.school_id, p_teacher_id, trim(v_subject), v_actor.user_id)
                ON CONFLICT (teacher_id, subject_name) DO NOTHING;
            END IF;
        END LOOP;
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.list_teacher_subjects(p_token text, p_teacher_id uuid DEFAULT NULL)
RETURNS TABLE (
    id uuid,
    teacher_id uuid,
    subject_name varchar,
    created_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
    v_actor record;
    v_target_teacher uuid;
BEGIN
    SELECT * INTO v_actor FROM get_session_actor(p_token);
    IF NOT FOUND THEN RAISE EXCEPTION 'invalid_session'; END IF;

    IF p_teacher_id IS NULL THEN
        IF v_actor.role = 'teacher' THEN
            v_target_teacher := v_actor.user_id;
        ELSE
            RAISE EXCEPTION 'forbidden';
        END IF;
    ELSE
        IF v_actor.role = 'school_admin' THEN
            v_target_teacher := p_teacher_id;
        ELSIF v_actor.role = 'teacher' AND p_teacher_id = v_actor.user_id THEN
            v_target_teacher := v_actor.user_id;
        ELSE
            RAISE EXCEPTION 'forbidden';
        END IF;
    END IF;

    RETURN QUERY
    SELECT ts.id, ts.teacher_id, ts.subject_name, ts.created_at
    FROM public.teacher_subjects ts
    WHERE ts.teacher_id = v_target_teacher AND ts.school_id = v_actor.school_id
    ORDER BY ts.subject_name;
END;
$$;

-- 2. school_periods
CREATE TABLE IF NOT EXISTS public.school_periods (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id uuid NOT NULL REFERENCES public.schools(id) ON DELETE CASCADE,
    period_no smallint NOT NULL,
    start_time time NOT NULL,
    end_time time NOT NULL,
    label varchar,
    UNIQUE (school_id, period_no)
);
ALTER TABLE public.school_periods ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.set_school_periods(p_token text, p_periods jsonb)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
    v_actor record;
    v_item jsonb;
    v_no smallint;
    v_start time;
    v_end time;
    v_label varchar;
BEGIN
    SELECT * INTO v_actor FROM get_session_actor(p_token);
    IF NOT FOUND THEN RAISE EXCEPTION 'invalid_session'; END IF;
    IF v_actor.role not in ('school_admin') THEN RAISE EXCEPTION 'forbidden'; END IF;

    DELETE FROM public.school_periods WHERE school_id = v_actor.school_id;

    FOR v_item IN SELECT * FROM jsonb_array_elements(p_periods)
    LOOP
        v_no := (v_item->>'period_no')::smallint;
        v_start := (v_item->>'start_time')::time;
        v_end := (v_item->>'end_time')::time;
        v_label := v_item->>'label';

        IF v_end <= v_start THEN
            RAISE EXCEPTION 'invalid_period_time';
        END IF;

        INSERT INTO public.school_periods (school_id, period_no, start_time, end_time, label)
        VALUES (v_actor.school_id, v_no, v_start, v_end, v_label);
    END LOOP;
END;
$$;

CREATE OR REPLACE FUNCTION public.list_school_periods(p_token text)
RETURNS TABLE (
    id uuid,
    period_no smallint,
    start_time time,
    end_time time,
    label varchar
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
    v_actor record;
BEGIN
    SELECT * INTO v_actor FROM get_session_actor(p_token);
    IF NOT FOUND THEN RAISE EXCEPTION 'invalid_session'; END IF;
    -- All roles in school can list
    
    RETURN QUERY
    SELECT sp.id, sp.period_no, sp.start_time, sp.end_time, sp.label
    FROM public.school_periods sp
    WHERE sp.school_id = v_actor.school_id
    ORDER BY sp.period_no;
END;
$$;

-- 3a. Room key normaliser. The two sides of the sync store rooms in different
-- shapes today: prod student_profiles has (grade 'ม.1', room '1') while the
-- prod course has (grade 'ม.1', room 'ม.1/1'), and the local seed profiles
-- use 'ม.4/1'. An exact match would enrol nobody on prod, so both sides are
-- compared through this key ('ม.1' + '1' -> 'ม.1/1'; 'ม.1' + 'ม.1/1' -> 'ม.1/1').
CREATE OR REPLACE FUNCTION public._class_room_key(p_grade text, p_room text)
RETURNS text
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CASE
    WHEN nullif(trim(coalesce(p_room, '')), '') IS NULL THEN NULL
    WHEN position(trim(p_grade) || '/' IN trim(p_room)) = 1 THEN trim(p_room)
    ELSE trim(p_grade) || '/' || trim(p_room)
  END
$$;

-- 3. sync_course_students_for_room
CREATE OR REPLACE FUNCTION public.sync_course_students_for_room(p_school_id uuid, p_academic_year_id uuid, p_grade_level text, p_room text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
BEGIN
  INSERT INTO public.course_students (course_id, student_id, enrolled_by)
  SELECT c.id, sp.student_id, null
  FROM public.courses c
  JOIN public.terms t ON t.id = c.term_id
  JOIN public.student_profiles sp ON sp.academic_year_id = t.academic_year_id
    AND sp.grade_level = c.grade_level
    AND public._class_room_key(sp.grade_level, sp.room) = public._class_room_key(c.grade_level, c.room)
  JOIN public.users u ON u.id = sp.student_id AND u.school_id = c.school_id
  WHERE c.school_id = p_school_id
    AND t.academic_year_id = p_academic_year_id
    AND c.grade_level = p_grade_level
    AND public._class_room_key(c.grade_level, c.room) = public._class_room_key(p_grade_level, p_room)
  ON CONFLICT (course_id, student_id) DO NOTHING;
END;
$$;
REVOKE ALL ON FUNCTION public.sync_course_students_for_room(uuid, uuid, text, text) FROM public, anon, authenticated;

-- 4. sync_course_students_for_student
CREATE OR REPLACE FUNCTION public.sync_course_students_for_student(p_student_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
BEGIN
  -- Delete invalid auto-enrollments (where student is no longer in the matching room/year)
  DELETE FROM public.course_students cs
  USING public.courses c
  JOIN public.terms t ON t.id = c.term_id
  WHERE cs.course_id = c.id
    AND cs.student_id = p_student_id
    AND cs.enrolled_by IS NULL
    AND NOT EXISTS (
      SELECT 1 FROM public.student_profiles sp
      WHERE sp.student_id = p_student_id
        AND sp.academic_year_id = t.academic_year_id
        AND sp.grade_level = c.grade_level
        AND public._class_room_key(sp.grade_level, sp.room) = public._class_room_key(c.grade_level, c.room)
    );

  -- Insert valid auto-enrollments
  INSERT INTO public.course_students (course_id, student_id, enrolled_by)
  SELECT c.id, p_student_id, null
  FROM public.courses c
  JOIN public.terms t ON t.id = c.term_id
  JOIN public.student_profiles sp ON sp.academic_year_id = t.academic_year_id
    AND sp.grade_level = c.grade_level
    AND public._class_room_key(sp.grade_level, sp.room) = public._class_room_key(c.grade_level, c.room)
  JOIN public.users u ON u.id = sp.student_id AND u.school_id = c.school_id
  WHERE sp.student_id = p_student_id
  ON CONFLICT (course_id, student_id) DO NOTHING;
END;
$$;
REVOKE ALL ON FUNCTION public.sync_course_students_for_student(uuid) FROM public, anon, authenticated;

-- 5. Mod set_student_profile
CREATE OR REPLACE FUNCTION public.set_student_profile(
  p_token text,
  p_student_id uuid,
  p_grade_level text,
  p_room text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_student users%rowtype;
  v_year uuid;
  v_grade text := nullif(trim(coalesce(p_grade_level, '')), '');
  v_room text := nullif(trim(coalesce(p_room, '')), '');
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN RAISE EXCEPTION 'invalid_session'; END IF;
  IF v_actor.role NOT IN ('school_admin', 'super_admin') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  SELECT * INTO v_student FROM users WHERE id = p_student_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'student_not_found'; END IF;
  IF v_actor.role <> 'super_admin' AND v_student.school_id IS DISTINCT FROM v_actor.school_id THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM user_roles ur
    WHERE ur.user_id = p_student_id AND ur.role = 'student'
  ) THEN RAISE EXCEPTION 'not_a_student'; END IF;

  v_year := _current_academic_year_id(v_student.school_id);
  IF v_year IS NULL THEN RAISE EXCEPTION 'no_academic_year'; END IF;

  IF v_grade IS NULL AND v_room IS NULL THEN
    DELETE FROM student_profiles
    WHERE student_id = p_student_id AND academic_year_id = v_year;
  ELSE
    IF v_grade IS NULL OR v_room IS NULL THEN
      RAISE EXCEPTION 'missing_required_field';
    END IF;
    INSERT INTO student_profiles (student_id, academic_year_id, grade_level, room, created_by)
    VALUES (p_student_id, v_year, v_grade, v_room, v_actor.user_id)
    ON CONFLICT (student_id, academic_year_id) DO UPDATE
      SET grade_level = excluded.grade_level, room = excluded.room;
  END IF;

  PERFORM public.sync_course_students_for_student(p_student_id);

  INSERT INTO audit_logs (school_id, user_id, acted_role, action, entity_type, entity_id, details)
  VALUES (v_student.school_id, v_actor.user_id, v_actor.role, 'student_profile.set',
          'student_profiles', p_student_id::text,
          jsonb_build_object('grade_level', v_grade, 'room', v_room, 'academic_year_id', v_year));
END;
$$;

-- Modify import_school_users_batch_for_school_admin to call sync
CREATE OR REPLACE FUNCTION public.import_school_users_batch_for_school_admin(p_token text, p_role text, p_users jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
declare
  v_actor record;
  v_item jsonb;
  v_role_type public.role_type;
  v_email text;
  v_first_name text;
  v_last_name text;
  v_student_code text;
  v_building text;
  v_grade text;
  v_room text;
  v_year uuid;
  v_user_id uuid;
  v_temp_password text;
  v_row_index int := 0;
  v_inserted_count int := 0;
  v_skipped jsonb := '[]'::jsonb;
  v_credentials jsonb := '[]'::jsonb;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('school_admin', 'super_admin') then
    raise exception 'forbidden: school_admin or super_admin role required';
  end if;
  if v_actor.school_id is null then raise exception 'no_active_school'; end if;

  begin
    v_role_type := p_role::public.role_type;
  exception when others then
    raise exception 'invalid_role: %', p_role;
  end;
  if v_role_type = 'super_admin'::role_type and v_actor.role <> 'super_admin' then
    raise exception 'forbidden: cannot import super_admin';
  end if;

  for v_item in select * from jsonb_array_elements(p_users)
  loop
    v_row_index := v_row_index + 1;
    v_email := lower(trim(coalesce(v_item->>'email', '')));
    v_first_name := trim(coalesce(v_item->>'first_name', v_item->>'name', ''));
    v_last_name := trim(coalesce(v_item->>'last_name', ''));
    v_student_code := trim(coalesce(v_item->>'student_code', ''));
    v_building := trim(coalesce(v_item->>'building', ''));
    v_grade := trim(coalesce(v_item->>'grade_level', v_item->>'grade', ''));
    v_room := trim(coalesce(v_item->>'room', ''));

    if v_email = '' then
      v_skipped := v_skipped || jsonb_build_object('row', v_row_index, 'reason', 'missing_required_field');
      continue;
    end if;
    if v_first_name = '' then
      v_first_name := split_part(v_email, '@', 1);
    end if;
    if v_last_name = '' then
      v_last_name := '-';
    end if;

    select id into v_user_id from users where email = v_email;
    if v_user_id is not null then
      v_skipped := v_skipped || jsonb_build_object('row', v_row_index, 'reason', 'duplicate_email');
      continue;
    end if;

    v_temp_password := _generate_temp_password();

    insert into users (
      school_id, email, first_name, last_name, password_hash, must_change_password,
      student_code, building, status
    ) values (
      v_actor.school_id, v_email, v_first_name, v_last_name,
      crypt(v_temp_password, gen_salt('bf')), true,
      nullif(v_student_code, ''), nullif(v_building, ''), 'active'::user_status
    ) returning id into v_user_id;

    insert into user_roles (user_id, school_id, role, granted_by)
    values (v_user_id, v_actor.school_id, v_role_type, v_actor.user_id)
    on conflict do nothing;

    if v_role_type = 'student'::role_type and v_grade <> '' and v_room <> '' then
      v_year := _current_academic_year_id(v_actor.school_id);
      if v_year is not null then
        insert into student_profiles (student_id, academic_year_id, grade_level, room, created_by)
        values (v_user_id, v_year, v_grade, v_room, v_actor.user_id)
        on conflict (student_id, academic_year_id) do update
          set grade_level = excluded.grade_level, room = excluded.room;
          
        PERFORM public.sync_course_students_for_student(v_user_id);
      end if;
    end if;

    v_inserted_count := v_inserted_count + 1;
    v_credentials := v_credentials || jsonb_build_object(
      'row', v_row_index, 'email', v_email, 'temp_password', v_temp_password
    );
  end loop;

  insert into audit_logs (school_id, user_id, acted_role, action, entity_type, entity_id, details)
  values (v_actor.school_id, v_actor.user_id, v_actor.role::role_type, 'users.batch_import',
          'users', v_actor.school_id::text,
          jsonb_build_object('role', p_role, 'count', v_inserted_count,
                             'skipped', jsonb_array_length(v_skipped)));

  return jsonb_build_object(
    'success', true,
    'inserted_count', v_inserted_count,
    'skipped', v_skipped,
    'credentials', v_credentials
  );
end;
$function$;

-- 6. Mod create_course
-- Drop the old signature (just in case they don't exactly match if defaults changed, but here they are the same except teacher_id default)
DROP FUNCTION IF EXISTS public.create_course(text, uuid, text, text, text, text, uuid);

CREATE OR REPLACE FUNCTION public.create_course(
  p_token text,
  p_term_id uuid,
  p_subject_name text,
  p_grade_level text,
  p_room text,
  p_description text DEFAULT NULL,
  p_teacher_id uuid DEFAULT NULL
)
RETURNS TABLE (course_id uuid)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_course_id uuid;
  v_term terms%rowtype;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN RAISE EXCEPTION 'invalid_session'; END IF;
  IF v_actor.role not in ('school_admin') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  -- Same school check the original create_course had: without it an admin of
  -- school A could create a course on school B's term, and the room sync below
  -- would then pull school B's students (via academic_year_id) into A's course.
  SELECT t.* INTO v_term
  FROM terms t
  JOIN academic_years ay ON ay.id = t.academic_year_id
  WHERE t.id = p_term_id AND ay.school_id = v_actor.school_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'term_not_found'; END IF;

  IF trim(coalesce(p_subject_name, '')) = '' THEN RAISE EXCEPTION 'subject_name_required'; END IF;
  IF trim(coalesce(p_grade_level, '')) = '' OR trim(coalesce(p_room, '')) = '' THEN
    RAISE EXCEPTION 'room_required';
  END IF;
  IF p_teacher_id IS NULL THEN RAISE EXCEPTION 'teacher_required'; END IF;

  IF NOT EXISTS (
    SELECT 1 FROM users u
    JOIN user_roles ur ON ur.user_id = u.id
    WHERE u.id = p_teacher_id AND u.school_id = v_actor.school_id AND ur.role = 'teacher'
  ) THEN
    RAISE EXCEPTION 'teacher_not_found';
  END IF;

  INSERT INTO courses (
    school_id, term_id, subject_name, grade_level, room, description, created_by
  ) VALUES (
    v_actor.school_id, p_term_id, trim(p_subject_name), trim(p_grade_level), trim(p_room),
    p_description, v_actor.user_id
  )
  RETURNING id INTO v_course_id;

  INSERT INTO course_teachers (course_id, teacher_id, is_owner)
  VALUES (v_course_id, p_teacher_id, true);

  PERFORM public.sync_course_students_for_room(v_actor.school_id, v_term.academic_year_id, trim(p_grade_level), trim(p_room));

  INSERT INTO audit_logs (school_id, user_id, acted_role, action, entity_type, entity_id)
  VALUES (v_actor.school_id, v_actor.user_id, v_actor.role, 'classroom.course_created', 'courses', v_course_id::text);

  RETURN QUERY SELECT v_course_id;
END;
$$;

REVOKE ALL ON FUNCTION public.create_course(text, uuid, text, text, text, text, uuid) FROM public;
GRANT EXECUTE ON FUNCTION public.create_course(text, uuid, text, text, text, text, uuid) TO anon, authenticated;

-- 7. Mod enroll_student
CREATE OR REPLACE FUNCTION public.enroll_student(
  p_token text,
  p_course_id uuid,
  p_student_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_course courses%rowtype;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN RAISE EXCEPTION 'invalid_session'; END IF;
  IF v_actor.role not in ('school_admin') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  SELECT * INTO v_course FROM courses WHERE id = p_course_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'course_not_found'; END IF;
  IF v_course.school_id IS DISTINCT FROM v_actor.school_id THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM user_roles ur
    WHERE ur.user_id = p_student_id
      AND ur.role = 'student'
      AND ur.school_id = v_actor.school_id
  ) THEN
    RAISE EXCEPTION 'student_not_found';
  END IF;

  INSERT INTO course_students (course_id, student_id, enrolled_by)
  VALUES (p_course_id, p_student_id, v_actor.user_id)
  ON CONFLICT (course_id, student_id) DO NOTHING;
END;
$$;

-- 8. class_schedules changes
ALTER TABLE public.class_schedules ADD COLUMN IF NOT EXISTS period_no smallint NULL;
-- Drop the current overload (20260910160000 added p_period_type as the 7th
-- arg). Leaving it in place next to the new signature makes every 6-arg call
-- ambiguous ("function is not unique") and lets the client's named
-- p_period_type call silently hit the old teacher-writable version.
DROP FUNCTION IF EXISTS public.set_class_schedule(text, uuid, smallint, time, time, text);
DROP FUNCTION IF EXISTS public.set_class_schedule(text, uuid, smallint, time, time, text, text);
-- the unreviewed 9bd32dc shape that reached production on 2026-09-20
DROP FUNCTION IF EXISTS public.set_class_schedule(text, uuid, smallint, time, time, text, smallint);

CREATE OR REPLACE FUNCTION public.set_class_schedule(
  p_token text,
  p_course_id uuid,
  p_day_of_week smallint,
  p_start_time time DEFAULT NULL,
  p_end_time time DEFAULT NULL,
  p_room text DEFAULT NULL,
  p_period_type text DEFAULT 'regular',
  p_period_no smallint DEFAULT NULL
)
RETURNS TABLE (schedule_id uuid)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_course courses%rowtype;
  v_schedule_id uuid;
  v_start time := p_start_time;
  v_end time := p_end_time;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN RAISE EXCEPTION 'invalid_session'; END IF;
  -- D6 (DECISIONS_2026-09-18): the timetable is the school admin's; teachers
  -- only read it. Before this migration teachers could set their own slots.
  IF v_actor.role NOT IN ('school_admin') THEN RAISE EXCEPTION 'forbidden'; END IF;

  SELECT * INTO v_course FROM courses WHERE id = p_course_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'course_not_found'; END IF;
  IF v_course.school_id IS DISTINCT FROM v_actor.school_id THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  IF p_period_type NOT IN ('regular', 'activity_lab') THEN
    RAISE EXCEPTION 'invalid_period_type';
  END IF;

  IF p_period_no IS NOT NULL THEN
    SELECT start_time, end_time INTO v_start, v_end
    FROM public.school_periods
    WHERE school_id = v_actor.school_id AND period_no = p_period_no;
    IF NOT FOUND THEN RAISE EXCEPTION 'period_not_found'; END IF;
  END IF;

  IF v_start IS NULL OR v_end IS NULL THEN
    RAISE EXCEPTION 'missing_times';
  END IF;

  IF v_end <= v_start THEN
    RAISE EXCEPTION 'end_time_must_be_after_start_time';
  END IF;

  INSERT INTO class_schedules (course_id, day_of_week, start_time, end_time, room, period_type, period_no, created_by)
  VALUES (p_course_id, p_day_of_week, v_start, v_end, p_room, p_period_type, p_period_no, v_actor.user_id)
  RETURNING id INTO v_schedule_id;

  RETURN QUERY SELECT v_schedule_id;
END;
$$;

-- 9. admin_set_room_timetable_slot and others
CREATE OR REPLACE FUNCTION public.admin_set_room_timetable_slot(
  p_token text,
  p_term_id uuid,
  p_grade_level text,
  p_room text,
  p_day_of_week smallint,
  p_period_no smallint,
  p_subject_name text,
  p_teacher_id uuid
)
RETURNS TABLE (course_id uuid, schedule_id uuid)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_course courses%rowtype;
  v_target_course_id uuid;
  v_schedule_id uuid;
  v_start time;
  v_end time;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN RAISE EXCEPTION 'invalid_session'; END IF;
  IF v_actor.role not in ('school_admin') THEN RAISE EXCEPTION 'forbidden'; END IF;

  SELECT start_time, end_time INTO v_start, v_end
  FROM public.school_periods
  WHERE school_id = v_actor.school_id AND period_no = p_period_no;
  IF NOT FOUND THEN RAISE EXCEPTION 'period_not_found'; END IF;

  -- Delete any existing slot for this room on this day/period across all courses
  DELETE FROM public.class_schedules cs
  USING public.courses c
  WHERE cs.course_id = c.id
    AND c.term_id = p_term_id
    AND c.grade_level = p_grade_level
    AND c.room = p_room
    AND cs.day_of_week = p_day_of_week
    AND cs.period_no = p_period_no;

  -- Find existing course
  SELECT c.* INTO v_course FROM public.courses c
  WHERE c.term_id = p_term_id
    AND c.grade_level = p_grade_level
    AND c.room = p_room
    AND c.subject_name = trim(p_subject_name)
    AND c.school_id = v_actor.school_id;

  IF FOUND THEN
    v_target_course_id := v_course.id;
    -- check if teacher is different
    IF NOT EXISTS (
      SELECT 1 FROM public.course_teachers ct
      WHERE ct.course_id = v_target_course_id AND ct.teacher_id = p_teacher_id
    ) THEN
      -- Replace the owner row only; co-teachers on the course stay.
      DELETE FROM public.course_teachers ct
      WHERE ct.course_id = v_target_course_id AND ct.is_owner = true;
      INSERT INTO public.course_teachers (course_id, teacher_id, is_owner)
      VALUES (v_target_course_id, p_teacher_id, true);
    END IF;
  ELSE
    SELECT public.create_course(
      p_token, p_term_id, trim(p_subject_name), p_grade_level, p_room, NULL, p_teacher_id
    ) INTO v_target_course_id;
  END IF;

  -- UNIQUE in class_schedules would be (course_id, day_of_week, period_no). 
  -- But we deleted it above so it's safe to insert.
  INSERT INTO public.class_schedules (course_id, day_of_week, period_no, start_time, end_time, created_by)
  VALUES (v_target_course_id, p_day_of_week, p_period_no, v_start, v_end, v_actor.user_id)
  RETURNING id INTO v_schedule_id;

  RETURN QUERY SELECT v_target_course_id, v_schedule_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_clear_room_timetable_slot(
  p_token text,
  p_term_id uuid,
  p_grade_level text,
  p_room text,
  p_day_of_week smallint,
  p_period_no smallint
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN RAISE EXCEPTION 'invalid_session'; END IF;
  IF v_actor.role not in ('school_admin') THEN RAISE EXCEPTION 'forbidden'; END IF;

  DELETE FROM public.class_schedules cs
  USING public.courses c
  WHERE cs.course_id = c.id
    AND c.term_id = p_term_id
    AND c.grade_level = p_grade_level
    AND c.room = p_room
    AND cs.day_of_week = p_day_of_week
    AND cs.period_no = p_period_no;
END;
$$;

CREATE OR REPLACE FUNCTION public.list_room_timetable(
  p_token text,
  p_term_id uuid,
  p_grade_level text,
  p_room text
)
RETURNS TABLE (
  schedule_id uuid,
  course_id uuid,
  day_of_week smallint,
  period_no smallint,
  start_time time,
  end_time time,
  subject_name varchar,
  teacher_id uuid,
  teacher_name text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN RAISE EXCEPTION 'invalid_session'; END IF;
  -- Any school staff can list
  
  RETURN QUERY
  SELECT
    cs.id, cs.course_id, cs.day_of_week, cs.period_no, cs.start_time, cs.end_time,
    c.subject_name,
    t.id, (t.first_name || ' ' || t.last_name)
  FROM public.class_schedules cs
  JOIN public.courses c ON c.id = cs.course_id
  LEFT JOIN public.course_teachers ct ON ct.course_id = c.id AND ct.is_owner = true
  LEFT JOIN public.users t ON t.id = ct.teacher_id
  WHERE c.school_id = v_actor.school_id
    AND c.term_id = p_term_id
    AND c.grade_level = p_grade_level
    AND c.room = p_room
    AND cs.period_no IS NOT NULL
  ORDER BY cs.day_of_week, cs.period_no;
END;
$$;

DROP FUNCTION IF EXISTS public.list_school_classes(text, uuid);

CREATE OR REPLACE FUNCTION public.list_school_classes(p_token text, p_academic_year_id uuid)
RETURNS TABLE (
  grade_level text,
  room text,
  student_count bigint
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN RAISE EXCEPTION 'invalid_session'; END IF;

  RETURN QUERY
  SELECT sp.grade_level, sp.room, count(*) as student_count
  FROM public.student_profiles sp
  JOIN public.users u ON u.id = sp.student_id
  WHERE u.school_id = v_actor.school_id
    AND sp.academic_year_id = p_academic_year_id
  GROUP BY sp.grade_level, sp.room
  ORDER BY sp.grade_level, sp.room;
END;
$$;

-- 11. Grant/Revoke
GRANT EXECUTE ON FUNCTION public.set_teacher_subjects(text, uuid, text[]) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.list_teacher_subjects(text, uuid) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.set_school_periods(text, jsonb) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.list_school_periods(text) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.admin_set_room_timetable_slot(text, uuid, text, text, smallint, smallint, text, uuid) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.admin_clear_room_timetable_slot(text, uuid, text, text, smallint, smallint) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.list_room_timetable(text, uuid, text, text) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.list_school_classes(text, uuid) TO anon, authenticated;
REVOKE ALL ON FUNCTION public.set_class_schedule(text, uuid, smallint, time, time, text, text, smallint) FROM public;
GRANT EXECUTE ON FUNCTION public.set_class_schedule(text, uuid, smallint, time, time, text, text, smallint) TO anon, authenticated;

-- 10. Backfill course_students
DO $$
DECLARE
  v_course record;
  v_term record;
BEGIN
  FOR v_course IN 
    SELECT c.* FROM public.courses c
    WHERE c.grade_level IS NOT NULL AND c.room IS NOT NULL
  LOOP
    SELECT * INTO v_term FROM public.terms WHERE id = v_course.term_id;
    IF FOUND THEN
      PERFORM public.sync_course_students_for_room(v_course.school_id, v_term.academic_year_id, v_course.grade_level, v_course.room);
    END IF;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'class_schedules_course_day_period_key') THEN
    ALTER TABLE public.class_schedules ADD CONSTRAINT class_schedules_course_day_period_key UNIQUE (course_id, day_of_week, period_no);
  END IF;
END $$;
