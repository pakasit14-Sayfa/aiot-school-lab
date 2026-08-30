-- Migration: 20260829030000_learning_tracks.sql
-- Description: Real "สายการเรียน" (learning track, e.g. วิทย์-คณิต / สายภาษา /
-- สายทั่วไป) tracking, previously 100% hardcoded on the executive overview
-- page (fixed numbers regenerated with a date-seeded jitter, no DB backing
-- at all). A track is assigned per (academic_year_id, grade_level, room) —
-- matching how homeroom_assignments models a classroom section — rather
-- than per-student, since in practice a whole ห้อง belongs to one track.
--
-- Only student_count/room_count and avg_grade_percent are computed from
-- real data (grades.status = 'confirmed', per the existing "students only
-- ever see confirmed grades" rule). Behavior/environment scores are
-- deliberately NOT added here — no real tracked source exists yet for
-- either (see HANDOFF.md).

CREATE TABLE IF NOT EXISTS public.learning_tracks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id uuid NOT NULL REFERENCES public.schools(id),
  name varchar NOT NULL,
  color varchar NOT NULL DEFAULT '#7C3AED',
  sort_order int NOT NULL DEFAULT 0,
  created_by uuid NOT NULL REFERENCES public.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (school_id, name)
);

ALTER TABLE public.learning_tracks ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.learning_track_room_assignments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id uuid NOT NULL REFERENCES public.schools(id),
  academic_year_id uuid NOT NULL REFERENCES public.academic_years(id),
  grade_level varchar NOT NULL,
  room varchar NOT NULL,
  track_id uuid NOT NULL REFERENCES public.learning_tracks(id) ON DELETE CASCADE,
  assigned_by uuid NOT NULL REFERENCES public.users(id),
  assigned_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (academic_year_id, grade_level, room)
);

ALTER TABLE public.learning_track_room_assignments ENABLE ROW LEVEL SECURITY;

-- Internal helper: school_admin of this school only.
CREATE OR REPLACE FUNCTION public._assert_school_admin(v_actor record)
RETURNS void
LANGUAGE plpgsql
STABLE
SET search_path = public, extensions
AS $$
BEGIN
  IF v_actor.role != 'school_admin' THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public._assert_school_admin FROM PUBLIC, anon, authenticated;

-- list_learning_tracks (school_admin / executive)
CREATE OR REPLACE FUNCTION public.list_learning_tracks(p_token text)
RETURNS TABLE (
  track_id uuid,
  name varchar,
  color varchar,
  sort_order int
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
  SELECT lt.id, lt.name, lt.color, lt.sort_order
  FROM public.learning_tracks lt
  WHERE lt.school_id = v_actor.school_id
  ORDER BY lt.sort_order ASC, lt.created_at ASC;
END;
$$;

-- create_learning_track (school_admin)
CREATE OR REPLACE FUNCTION public.create_learning_track(
  p_token text,
  p_name text,
  p_color text DEFAULT '#7C3AED'
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_id uuid;
  v_next_sort int;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  PERFORM public._assert_school_admin(v_actor);

  IF trim(coalesce(p_name, '')) = '' THEN
    RAISE EXCEPTION 'name_required';
  END IF;

  SELECT coalesce(max(sort_order), -1) + 1 INTO v_next_sort
  FROM public.learning_tracks WHERE school_id = v_actor.school_id;

  INSERT INTO public.learning_tracks (school_id, name, color, sort_order, created_by)
  VALUES (v_actor.school_id, trim(p_name), coalesce(p_color, '#7C3AED'), v_next_sort, v_actor.user_id)
  RETURNING id INTO v_id;

  RETURN v_id;
END;
$$;

-- update_learning_track (school_admin)
CREATE OR REPLACE FUNCTION public.update_learning_track(
  p_token text,
  p_track_id uuid,
  p_name text,
  p_color text,
  p_sort_order int
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
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  PERFORM public._assert_school_admin(v_actor);

  IF trim(coalesce(p_name, '')) = '' THEN
    RAISE EXCEPTION 'name_required';
  END IF;

  UPDATE public.learning_tracks
  SET name = trim(p_name),
      color = coalesce(p_color, color),
      sort_order = coalesce(p_sort_order, sort_order)
  WHERE id = p_track_id AND school_id = v_actor.school_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'track_not_found';
  END IF;
END;
$$;

-- delete_learning_track (school_admin) — cascades to room assignments.
CREATE OR REPLACE FUNCTION public.delete_learning_track(
  p_token text,
  p_track_id uuid
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
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  PERFORM public._assert_school_admin(v_actor);

  DELETE FROM public.learning_tracks
  WHERE id = p_track_id AND school_id = v_actor.school_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'track_not_found';
  END IF;
END;
$$;

-- list_learning_track_rooms (school_admin) — every (grade_level, room) that
-- has students this year, with its current track assignment (if any) and
-- live student count, for the assignment UI.
CREATE OR REPLACE FUNCTION public.list_learning_track_rooms(p_token text)
RETURNS TABLE (
  grade_level varchar,
  room varchar,
  student_count bigint,
  track_id uuid,
  track_name varchar
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_year uuid;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  PERFORM public._assert_school_admin(v_actor);

  v_year := public._current_academic_year_id(v_actor.school_id);

  RETURN QUERY
  SELECT
    sp.grade_level,
    sp.room,
    count(DISTINCT sp.student_id) AS student_count,
    a.track_id,
    lt.name AS track_name
  FROM public.student_profiles sp
  JOIN public.users u ON u.id = sp.student_id AND u.school_id = v_actor.school_id
  LEFT JOIN public.learning_track_room_assignments a
    ON a.academic_year_id = sp.academic_year_id
    AND a.grade_level = sp.grade_level
    AND a.room = sp.room
  LEFT JOIN public.learning_tracks lt ON lt.id = a.track_id
  WHERE sp.academic_year_id = v_year
  GROUP BY sp.grade_level, sp.room, a.track_id, lt.name
  ORDER BY sp.grade_level, sp.room;
END;
$$;

-- set_learning_track_room (school_admin) — assign (or clear, if
-- p_track_id is null) which track a classroom section belongs to.
CREATE OR REPLACE FUNCTION public.set_learning_track_room(
  p_token text,
  p_grade_level text,
  p_room text,
  p_track_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_year uuid;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  PERFORM public._assert_school_admin(v_actor);

  v_year := public._current_academic_year_id(v_actor.school_id);
  IF v_year IS NULL THEN
    RAISE EXCEPTION 'no_academic_year';
  END IF;

  IF p_track_id IS NULL THEN
    DELETE FROM public.learning_track_room_assignments
    WHERE academic_year_id = v_year AND grade_level = p_grade_level AND room = p_room;
    RETURN;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.learning_tracks
    WHERE id = p_track_id AND school_id = v_actor.school_id
  ) THEN
    RAISE EXCEPTION 'track_not_found';
  END IF;

  INSERT INTO public.learning_track_room_assignments
    (school_id, academic_year_id, grade_level, room, track_id, assigned_by)
  VALUES (v_actor.school_id, v_year, p_grade_level, p_room, p_track_id, v_actor.user_id)
  ON CONFLICT (academic_year_id, grade_level, room)
  DO UPDATE SET track_id = excluded.track_id,
                assigned_by = excluded.assigned_by,
                assigned_at = now();
END;
$$;

-- get_learning_track_overview (school_admin / executive) — real
-- student_count/room_count per track plus avg_grade_percent from
-- confirmed grades only (null if no confirmed grades exist yet).
-- Deliberately no behavior/environment columns — no real source for
-- either yet.
CREATE OR REPLACE FUNCTION public.get_learning_track_overview(p_token text)
RETURNS TABLE (
  track_id uuid,
  name varchar,
  color varchar,
  sort_order int,
  student_count bigint,
  room_count bigint,
  avg_grade_percent numeric
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_year uuid;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  IF v_actor.role NOT IN ('school_admin', 'executive', 'super_admin') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  v_year := public._current_academic_year_id(v_actor.school_id);

  RETURN QUERY
  WITH track_students AS (
    SELECT a.track_id, sp.student_id, sp.grade_level, sp.room
    FROM public.learning_track_room_assignments a
    JOIN public.student_profiles sp
      ON sp.academic_year_id = a.academic_year_id
      AND sp.grade_level = a.grade_level
      AND sp.room = a.room
    WHERE a.academic_year_id = v_year
  ),
  track_grades AS (
    SELECT ts.track_id, avg(g.score / NULLIF(g.max_score, 0)) * 100 AS avg_percent
    FROM track_students ts
    JOIN public.grades g ON g.student_id = ts.student_id AND g.status = 'confirmed'
    WHERE g.max_score IS NOT NULL AND g.max_score > 0
    GROUP BY ts.track_id
  )
  SELECT
    lt.id,
    lt.name,
    lt.color,
    lt.sort_order,
    count(DISTINCT ts.student_id),
    count(DISTINCT (ts.grade_level, ts.room)),
    tg.avg_percent
  FROM public.learning_tracks lt
  LEFT JOIN track_students ts ON ts.track_id = lt.id
  LEFT JOIN track_grades tg ON tg.track_id = lt.id
  WHERE lt.school_id = v_actor.school_id
  GROUP BY lt.id, lt.name, lt.color, lt.sort_order, tg.avg_percent
  ORDER BY lt.sort_order ASC, lt.created_at ASC;
END;
$$;

REVOKE ALL ON FUNCTION public.list_learning_tracks FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.list_learning_tracks TO anon, authenticated;

REVOKE ALL ON FUNCTION public.create_learning_track FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_learning_track TO anon, authenticated;

REVOKE ALL ON FUNCTION public.update_learning_track FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.update_learning_track TO anon, authenticated;

REVOKE ALL ON FUNCTION public.delete_learning_track FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.delete_learning_track TO anon, authenticated;

REVOKE ALL ON FUNCTION public.list_learning_track_rooms FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.list_learning_track_rooms TO anon, authenticated;

REVOKE ALL ON FUNCTION public.set_learning_track_room FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.set_learning_track_room TO anon, authenticated;

REVOKE ALL ON FUNCTION public.get_learning_track_overview FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_learning_track_overview TO anon, authenticated;
