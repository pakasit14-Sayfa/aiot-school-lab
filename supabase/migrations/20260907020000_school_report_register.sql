-- Migration: 20260907020000_school_report_register.sql
-- Description: ทะเบียนรายงานของโรงเรียน — the register of reports each ฝ่าย
-- files with the director, plus the schedule of reports that are due.
--
-- Why this exists: `director_reports_page` shipped 191 lines of invented
-- report files (`Attendance_Daily_20-08-2569.pdf`, 2.4 MB, 18 หน้า, sent by
-- นางสาวอรทัย พัฒนกิจ, หัวหน้าฝ่ายวิชาการ) and 31 lines of invented pending
-- items with due dates and "ส่งแล้ว 3/6". Nothing backed any of it:
-- `course_files` is the only document table in the schema and it is
-- course-scoped coursework, not a school report register.
--
-- Design notes:
--
--   * Two different things were mixed on that page and are separated here.
--     `school_reports` is a document somebody actually filed.
--     `report_requirements` is a report the school expects — it has a due
--     date, and the "3/6" figure is how many of its target ฝ่าย have filed.
--     A due date belongs to the expectation, never to the file.
--
--   * `overdue` is therefore not a status a row carries. It is derived: a
--     requirement whose due date has passed and whose targets have not all
--     filed. A file cannot be "เกินกำหนด" on its own.
--
--   * Page count is gone. Nothing on the server can count the pages of an
--     uploaded PDF, and the old UI printed one for every file.
--
--   * Bytes live in the private `school-reports` bucket and are reached only
--     through signed URLs minted by Edge Functions, per hard rule 3. The two
--     RPCs those functions call are granted to `service_role` explicitly —
--     it is not a member of anon/authenticated and gets no execute privilege
--     from a grant to those, which has bitten this project twice.
--
--   * `department_id` points at `departments` from 20260907000000, so
--     "ฝ่ายผู้ส่ง" is the school's real structure rather than six names
--     written into the page.
--
-- Everything here is additive. No existing table or RPC is modified.

-- ---------------------------------------------------------------------------
-- Storage
-- ---------------------------------------------------------------------------

-- Private. Reads and writes go through the school-report-upload/-download
-- Edge Functions; nothing may reach storage.objects directly.
INSERT INTO storage.buckets (id, name, public)
VALUES ('school-reports', 'school-reports', false)
ON CONFLICT (id) DO UPDATE SET public = false;

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.report_requirements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id uuid NOT NULL REFERENCES public.schools(id),
  title varchar NOT NULL,
  description text,
  report_type varchar NOT NULL
    CHECK (report_type IN ('daily', 'weekly', 'monthly', 'term', 'incident', 'ad_hoc')),
  -- The period the report should cover, and when it is due. Nullable due date
  -- for a standing expectation with no deadline.
  period_start date,
  period_end date,
  due_date date,
  is_active boolean NOT NULL DEFAULT true,
  created_by uuid NOT NULL REFERENCES public.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  CHECK (period_end IS NULL OR period_start IS NULL OR period_end >= period_start)
);

ALTER TABLE public.report_requirements ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS report_requirements_school_idx
  ON public.report_requirements (school_id, is_active, due_date);

-- Which ฝ่าย this requirement is asking. The "3/6" on the old page is
-- count(filed) over count(rows here) — a real denominator instead of a
-- number typed next to it.
CREATE TABLE IF NOT EXISTS public.report_requirement_departments (
  requirement_id uuid NOT NULL REFERENCES public.report_requirements(id) ON DELETE CASCADE,
  department_id uuid NOT NULL REFERENCES public.departments(id) ON DELETE CASCADE,
  PRIMARY KEY (requirement_id, department_id)
);

ALTER TABLE public.report_requirement_departments ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.school_reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id uuid NOT NULL REFERENCES public.schools(id),
  -- Null for a report filed off its own bat rather than against an expectation.
  requirement_id uuid REFERENCES public.report_requirements(id) ON DELETE SET NULL,
  -- The ฝ่าย that filed it. Null when the submitter belongs to none.
  department_id uuid REFERENCES public.departments(id) ON DELETE SET NULL,
  title varchar NOT NULL,
  description text,
  report_type varchar NOT NULL
    CHECK (report_type IN ('daily', 'weekly', 'monthly', 'term', 'incident', 'ad_hoc')),
  period_start date,
  period_end date,
  storage_path text NOT NULL UNIQUE,
  file_name varchar NOT NULL,
  -- Derived from the extension by the RPC, never sent by the client.
  file_type varchar NOT NULL
    CHECK (file_type IN ('pdf', 'excel', 'word', 'image', 'other')),
  size_bytes bigint NOT NULL CHECK (size_bytes >= 0),
  -- submitted → under_review → approved | needs_revision.
  -- 'overdue' is deliberately absent: lateness is a property of the
  -- requirement's due date, not of a file that exists.
  status varchar NOT NULL DEFAULT 'submitted'
    CHECK (status IN ('submitted', 'under_review', 'approved', 'needs_revision')),
  submitted_by uuid NOT NULL REFERENCES public.users(id),
  submitted_at timestamptz NOT NULL DEFAULT now(),
  reviewed_by uuid REFERENCES public.users(id),
  reviewed_at timestamptz,
  review_note text
);

ALTER TABLE public.school_reports ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS school_reports_school_idx
  ON public.school_reports (school_id, submitted_at DESC);
CREATE INDEX IF NOT EXISTS school_reports_requirement_idx
  ON public.school_reports (requirement_id);

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

-- Extension → the four categories the page filters on. Runs server-side so a
-- client cannot label an .exe as a PDF.
CREATE OR REPLACE FUNCTION public._report_file_type(p_file_name text)
RETURNS text
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CASE lower(substring(p_file_name from '\.([A-Za-z0-9]+)$'))
    WHEN 'pdf' THEN 'pdf'
    WHEN 'xls' THEN 'excel'
    WHEN 'xlsx' THEN 'excel'
    WHEN 'csv' THEN 'excel'
    WHEN 'doc' THEN 'word'
    WHEN 'docx' THEN 'word'
    WHEN 'png' THEN 'image'
    WHEN 'jpg' THEN 'image'
    WHEN 'jpeg' THEN 'image'
    ELSE 'other'
  END;
$$;

-- ---------------------------------------------------------------------------
-- Upload path (Edge Function → signed URL → register)
-- ---------------------------------------------------------------------------

-- Called by the school-report-upload Edge Function before it mints a signed
-- upload URL. school_admin may file for any ฝ่าย; anyone else must belong to
-- the one they are filing for. Returns the school id the object must be
-- filed under so the function cannot be talked into another tenant's prefix.
CREATE OR REPLACE FUNCTION public.assert_school_report_upload_access(
  p_token text,
  p_department_id uuid
)
RETURNS uuid
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

  IF v_actor.role NOT IN ('teacher', 'school_admin', 'executive') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  IF p_department_id IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1 FROM public.departments d
       WHERE d.id = p_department_id AND d.school_id = v_actor.school_id
    ) THEN
      RAISE EXCEPTION 'forbidden';
    END IF;

    IF v_actor.role NOT IN ('school_admin', 'executive')
       AND NOT EXISTS (
         SELECT 1 FROM public.department_members m
          WHERE m.department_id = p_department_id
            AND m.user_id = v_actor.user_id
       ) THEN
      RAISE EXCEPTION 'not_a_member';
    END IF;
  END IF;

  RETURN v_actor.school_id;
END;
$$;

-- Records the metadata once the bytes are up. Re-checks access rather than
-- trusting that the upload step did.
CREATE OR REPLACE FUNCTION public.register_school_report(
  p_token text,
  p_title text,
  p_report_type text,
  p_storage_path text,
  p_file_name text,
  p_size_bytes bigint,
  p_department_id uuid DEFAULT NULL,
  p_requirement_id uuid DEFAULT NULL,
  p_description text DEFAULT NULL,
  p_period_start date DEFAULT NULL,
  p_period_end date DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_school uuid;
  v_id uuid;
BEGIN
  v_school := public.assert_school_report_upload_access(p_token, p_department_id);
  SELECT * INTO v_actor FROM get_session_actor(p_token);

  IF coalesce(trim(p_title), '') = '' THEN
    RAISE EXCEPTION 'title_required';
  END IF;

  IF p_report_type NOT IN ('daily', 'weekly', 'monthly', 'term', 'incident', 'ad_hoc') THEN
    RAISE EXCEPTION 'invalid_report_type';
  END IF;

  IF coalesce(trim(p_storage_path), '') = '' OR coalesce(trim(p_file_name), '') = '' THEN
    RAISE EXCEPTION 'file_required';
  END IF;

  -- The object must sit under this school's prefix; anything else means the
  -- path was not the one the upload function minted.
  IF p_storage_path NOT LIKE v_school::text || '/%' THEN
    RAISE EXCEPTION 'invalid_storage_path';
  END IF;

  IF p_requirement_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.report_requirements r
     WHERE r.id = p_requirement_id AND r.school_id = v_school
  ) THEN
    RAISE EXCEPTION 'requirement_not_found';
  END IF;

  INSERT INTO public.school_reports (
    school_id, requirement_id, department_id, title, description, report_type,
    period_start, period_end, storage_path, file_name, file_type, size_bytes,
    submitted_by
  ) VALUES (
    v_school, p_requirement_id, p_department_id, trim(p_title),
    nullif(trim(coalesce(p_description, '')), ''), p_report_type,
    p_period_start, p_period_end, p_storage_path, trim(p_file_name),
    public._report_file_type(p_file_name), greatest(coalesce(p_size_bytes, 0), 0),
    v_actor.user_id
  )
  RETURNING id INTO v_id;

  INSERT INTO public.audit_logs
    (school_id, user_id, acted_role, action, entity_type, entity_id, details)
  VALUES (
    v_school, v_actor.user_id, v_actor.role,
    'school_report.submit', 'school_reports', v_id::text,
    jsonb_build_object('title', trim(p_title), 'report_type', p_report_type)
  );

  RETURN v_id;
END;
$$;

-- Called by the school-report-download Edge Function. Re-checks who may see
-- the file on every request rather than trusting a URL handed out earlier.
CREATE OR REPLACE FUNCTION public.get_school_report_for_download(
  p_token text,
  p_report_id uuid
)
RETURNS TABLE (storage_path text, file_name varchar)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_report record;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  SELECT * INTO v_report FROM public.school_reports WHERE id = p_report_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'report_not_found';
  END IF;

  IF v_report.school_id IS DISTINCT FROM v_actor.school_id THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  -- The director and the school admin read everything filed with them. Anyone
  -- else reads their own submissions and their own ฝ่าย's.
  IF v_actor.role NOT IN ('executive', 'school_admin', 'super_admin')
     AND v_report.submitted_by <> v_actor.user_id
     AND NOT (
       v_report.department_id IS NOT NULL
       AND EXISTS (
         SELECT 1 FROM public.department_members m
          WHERE m.department_id = v_report.department_id
            AND m.user_id = v_actor.user_id
       )
     ) THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  RETURN QUERY
  SELECT v_report.storage_path, v_report.file_name;
END;
$$;

-- ---------------------------------------------------------------------------
-- Reads
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.list_school_reports(
  p_token text,
  p_status text DEFAULT NULL,
  p_report_type text DEFAULT NULL,
  p_file_type text DEFAULT NULL,
  p_department_id uuid DEFAULT NULL,
  p_from date DEFAULT NULL,
  p_to date DEFAULT NULL
)
RETURNS TABLE (
  report_id uuid,
  title varchar,
  description text,
  report_type text,
  file_name varchar,
  file_type text,
  size_bytes bigint,
  department_id uuid,
  department_name text,
  period_start date,
  period_end date,
  status text,
  submitted_by uuid,
  submitter_name text,
  submitter_position text,
  submitted_at timestamptz,
  reviewer_name text,
  reviewed_at timestamptz,
  review_note text,
  requirement_id uuid,
  requirement_title text
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

  IF v_actor.role NOT IN ('teacher', 'school_admin', 'executive', 'super_admin') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  RETURN QUERY
  SELECT
    r.id,
    r.title,
    r.description,
    r.report_type::text,
    r.file_name,
    r.file_type::text,
    r.size_bytes,
    r.department_id,
    d.name::text,
    r.period_start,
    r.period_end,
    r.status::text,
    r.submitted_by,
    trim(u.first_name || ' ' || u.last_name),
    sp.position_title::text,
    r.submitted_at,
    trim(rv.first_name || ' ' || rv.last_name),
    r.reviewed_at,
    r.review_note,
    r.requirement_id,
    req.title::text
  FROM public.school_reports r
  JOIN public.users u ON u.id = r.submitted_by
  LEFT JOIN public.staff_profiles sp ON sp.user_id = r.submitted_by
  LEFT JOIN public.departments d ON d.id = r.department_id
  LEFT JOIN public.users rv ON rv.id = r.reviewed_by
  LEFT JOIN public.report_requirements req ON req.id = r.requirement_id
  WHERE r.school_id = v_actor.school_id
    -- A teacher sees their own and their ฝ่าย's; the two roles the register
    -- exists for see all of it.
    AND (
      v_actor.role IN ('executive', 'school_admin', 'super_admin')
      OR r.submitted_by = v_actor.user_id
      OR (r.department_id IS NOT NULL AND EXISTS (
            SELECT 1 FROM public.department_members m
             WHERE m.department_id = r.department_id
               AND m.user_id = v_actor.user_id))
    )
    AND (p_status IS NULL OR r.status = p_status)
    AND (p_report_type IS NULL OR r.report_type = p_report_type)
    AND (p_file_type IS NULL OR r.file_type = p_file_type)
    AND (p_department_id IS NULL OR r.department_id = p_department_id)
    AND (p_from IS NULL OR r.submitted_at >= p_from::timestamptz)
    AND (p_to IS NULL OR r.submitted_at < (p_to + 1)::timestamptz)
  ORDER BY r.submitted_at DESC;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_school_report_summary(p_token text)
RETURNS TABLE (
  total_reports int,
  awaiting_review int,
  approved int,
  needs_revision int,
  submitted_this_month int,
  open_requirements int,
  overdue_requirements int
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_today date;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  IF v_actor.role NOT IN ('school_admin', 'executive', 'super_admin') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  v_today := (now() AT TIME ZONE 'Asia/Bangkok')::date;

  RETURN QUERY
  WITH scoped AS (
    SELECT * FROM public.school_reports WHERE school_id = v_actor.school_id
  ),
  reqs AS (
    SELECT
      r.id,
      r.due_date,
      (SELECT count(*) FROM public.report_requirement_departments rd
        WHERE rd.requirement_id = r.id) AS expected,
      (SELECT count(DISTINCT s.department_id) FROM scoped s
        WHERE s.requirement_id = r.id AND s.department_id IS NOT NULL) AS filed
    FROM public.report_requirements r
    WHERE r.school_id = v_actor.school_id AND r.is_active
  )
  SELECT
    (SELECT count(*)::int FROM scoped),
    (SELECT count(*)::int FROM scoped WHERE status IN ('submitted', 'under_review')),
    (SELECT count(*)::int FROM scoped WHERE status = 'approved'),
    (SELECT count(*)::int FROM scoped WHERE status = 'needs_revision'),
    (SELECT count(*)::int FROM scoped
      WHERE (submitted_at AT TIME ZONE 'Asia/Bangkok')::date
            >= date_trunc('month', v_today)::date),
    (SELECT count(*)::int FROM reqs WHERE filed < expected),
    -- Overdue is derived here and nowhere else: past its due date and still
    -- missing at least one ฝ่าย's file.
    (SELECT count(*)::int FROM reqs
      WHERE due_date IS NOT NULL AND due_date < v_today AND filed < expected);
END;
$$;

CREATE OR REPLACE FUNCTION public.list_report_requirements(
  p_token text,
  p_only_open boolean DEFAULT false
)
RETURNS TABLE (
  requirement_id uuid,
  title varchar,
  description text,
  report_type text,
  period_start date,
  period_end date,
  due_date date,
  expected_count int,
  filed_count int,
  is_overdue boolean,
  missing_departments text[]
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_today date;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  IF v_actor.role NOT IN ('teacher', 'school_admin', 'executive', 'super_admin') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  v_today := (now() AT TIME ZONE 'Asia/Bangkok')::date;

  RETURN QUERY
  WITH base AS (
    SELECT
      r.*,
      (SELECT count(*)::int FROM public.report_requirement_departments rd
        WHERE rd.requirement_id = r.id) AS expected,
      (SELECT count(DISTINCT s.department_id)::int FROM public.school_reports s
        WHERE s.requirement_id = r.id AND s.department_id IS NOT NULL) AS filed
    FROM public.report_requirements r
    WHERE r.school_id = v_actor.school_id AND r.is_active
  )
  SELECT
    b.id,
    b.title,
    b.description,
    b.report_type::text,
    b.period_start,
    b.period_end,
    b.due_date,
    b.expected,
    b.filed,
    (b.due_date IS NOT NULL AND b.due_date < v_today AND b.filed < b.expected),
    -- Named, so the page shows which ฝ่าย is missing instead of only "3/6".
    ARRAY(
      SELECT d.name::text
        FROM public.report_requirement_departments rd
        JOIN public.departments d ON d.id = rd.department_id
       WHERE rd.requirement_id = b.id
         AND NOT EXISTS (
           SELECT 1 FROM public.school_reports s
            WHERE s.requirement_id = b.id AND s.department_id = rd.department_id
         )
       ORDER BY d.sort_order, d.name
    )
  FROM base b
  WHERE NOT p_only_open OR b.filed < b.expected
  ORDER BY b.due_date NULLS LAST, b.created_at DESC;
END;
$$;

-- ---------------------------------------------------------------------------
-- Review
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.review_school_report(
  p_token text,
  p_report_id uuid,
  p_status text,
  p_note text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_report record;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  -- The director is the reason this register exists, so executive can decide
  -- here — unlike the staff structure, which it only reads.
  IF v_actor.role NOT IN ('executive', 'school_admin', 'super_admin') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  IF p_status NOT IN ('under_review', 'approved', 'needs_revision') THEN
    RAISE EXCEPTION 'invalid_status';
  END IF;

  SELECT * INTO v_report FROM public.school_reports WHERE id = p_report_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'report_not_found';
  END IF;

  IF v_actor.role <> 'super_admin'
     AND v_report.school_id IS DISTINCT FROM v_actor.school_id THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  IF p_status = 'needs_revision'
     AND coalesce(trim(coalesce(p_note, '')), '') = '' THEN
    -- Sending a report back without saying why is what makes a review queue
    -- useless to the person who has to act on it.
    RAISE EXCEPTION 'note_required';
  END IF;

  UPDATE public.school_reports
     SET status = p_status,
         reviewed_by = v_actor.user_id,
         reviewed_at = now(),
         review_note = nullif(trim(coalesce(p_note, '')), '')
   WHERE id = p_report_id;

  INSERT INTO public.audit_logs
    (school_id, user_id, acted_role, action, entity_type, entity_id, details)
  VALUES (
    v_report.school_id, v_actor.user_id, v_actor.role,
    'school_report.review', 'school_reports', p_report_id::text,
    jsonb_build_object('status', p_status)
  );
END;
$$;

-- The submitter may withdraw their own file while nobody has acted on it.
CREATE OR REPLACE FUNCTION public.delete_school_report(
  p_token text,
  p_report_id uuid
)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_report record;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  SELECT * INTO v_report FROM public.school_reports WHERE id = p_report_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'report_not_found';
  END IF;

  IF v_report.school_id IS DISTINCT FROM v_actor.school_id THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  IF v_actor.role NOT IN ('school_admin', 'super_admin') THEN
    IF v_report.submitted_by <> v_actor.user_id THEN
      RAISE EXCEPTION 'forbidden';
    END IF;
    IF v_report.status <> 'submitted' THEN
      RAISE EXCEPTION 'already_reviewed';
    END IF;
  END IF;

  DELETE FROM public.school_reports WHERE id = p_report_id;

  INSERT INTO public.audit_logs
    (school_id, user_id, acted_role, action, entity_type, entity_id, details)
  VALUES (
    v_report.school_id, v_actor.user_id, v_actor.role,
    'school_report.delete', 'school_reports', p_report_id::text,
    jsonb_build_object('title', v_report.title)
  );

  -- Returned so the caller can delete the object it points at; the row is
  -- gone either way, and an orphaned object is better than a row pointing at
  -- bytes that are not there.
  RETURN v_report.storage_path;
END;
$$;

-- ---------------------------------------------------------------------------
-- Requirements (school_admin owns the schedule)
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.create_report_requirement(
  p_token text,
  p_title text,
  p_report_type text,
  p_department_ids uuid[],
  p_due_date date DEFAULT NULL,
  p_description text DEFAULT NULL,
  p_period_start date DEFAULT NULL,
  p_period_end date DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_id uuid;
  v_dept uuid;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  IF v_actor.role NOT IN ('school_admin', 'super_admin') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  IF coalesce(trim(p_title), '') = '' THEN
    RAISE EXCEPTION 'title_required';
  END IF;

  IF p_report_type NOT IN ('daily', 'weekly', 'monthly', 'term', 'incident', 'ad_hoc') THEN
    RAISE EXCEPTION 'invalid_report_type';
  END IF;

  -- A requirement nobody is asked for has no denominator and would render as
  -- "0/0 ส่งแล้ว" forever.
  IF p_department_ids IS NULL OR array_length(p_department_ids, 1) IS NULL THEN
    RAISE EXCEPTION 'departments_required';
  END IF;

  INSERT INTO public.report_requirements (
    school_id, title, description, report_type,
    period_start, period_end, due_date, created_by
  ) VALUES (
    v_actor.school_id, trim(p_title),
    nullif(trim(coalesce(p_description, '')), ''), p_report_type,
    p_period_start, p_period_end, p_due_date, v_actor.user_id
  )
  RETURNING id INTO v_id;

  FOREACH v_dept IN ARRAY p_department_ids LOOP
    IF NOT EXISTS (
      SELECT 1 FROM public.departments d
       WHERE d.id = v_dept AND d.school_id = v_actor.school_id
    ) THEN
      RAISE EXCEPTION 'department_not_found';
    END IF;
    INSERT INTO public.report_requirement_departments (requirement_id, department_id)
    VALUES (v_id, v_dept)
    ON CONFLICT DO NOTHING;
  END LOOP;

  INSERT INTO public.audit_logs
    (school_id, user_id, acted_role, action, entity_type, entity_id, details)
  VALUES (
    v_actor.school_id, v_actor.user_id, v_actor.role,
    'report_requirement.create', 'report_requirements', v_id::text,
    jsonb_build_object('title', trim(p_title), 'due_date', p_due_date)
  );

  RETURN v_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.close_report_requirement(
  p_token text,
  p_requirement_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_req record;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  IF v_actor.role NOT IN ('school_admin', 'super_admin') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  SELECT * INTO v_req FROM public.report_requirements WHERE id = p_requirement_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'requirement_not_found';
  END IF;

  IF v_actor.role <> 'super_admin'
     AND v_req.school_id IS DISTINCT FROM v_actor.school_id THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  -- Closed, not deleted: the reports already filed against it keep pointing
  -- at something with a name.
  UPDATE public.report_requirements SET is_active = false
   WHERE id = p_requirement_id;
END;
$$;

-- ---------------------------------------------------------------------------
-- Grants
--
-- The two Edge-Function RPCs need `service_role` EXPLICITLY: it is not a
-- member of anon/authenticated, and granting to those alone left both
-- existing upload pairs broken until 26d0343/908707e.
-- ---------------------------------------------------------------------------

REVOKE ALL ON FUNCTION public._report_file_type FROM PUBLIC, anon, authenticated, service_role;

REVOKE ALL ON FUNCTION public.assert_school_report_upload_access FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.assert_school_report_upload_access TO service_role;

REVOKE ALL ON FUNCTION public.get_school_report_for_download FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_school_report_for_download TO service_role;

REVOKE ALL ON FUNCTION public.register_school_report FROM PUBLIC, service_role;
GRANT EXECUTE ON FUNCTION public.register_school_report TO anon, authenticated;

REVOKE ALL ON FUNCTION public.list_school_reports FROM PUBLIC, service_role;
GRANT EXECUTE ON FUNCTION public.list_school_reports TO anon, authenticated;

REVOKE ALL ON FUNCTION public.get_school_report_summary FROM PUBLIC, service_role;
GRANT EXECUTE ON FUNCTION public.get_school_report_summary TO anon, authenticated;

REVOKE ALL ON FUNCTION public.list_report_requirements FROM PUBLIC, service_role;
GRANT EXECUTE ON FUNCTION public.list_report_requirements TO anon, authenticated;

REVOKE ALL ON FUNCTION public.review_school_report FROM PUBLIC, service_role;
GRANT EXECUTE ON FUNCTION public.review_school_report TO anon, authenticated;

REVOKE ALL ON FUNCTION public.delete_school_report FROM PUBLIC, service_role;
GRANT EXECUTE ON FUNCTION public.delete_school_report TO anon, authenticated;

REVOKE ALL ON FUNCTION public.create_report_requirement FROM PUBLIC, service_role;
GRANT EXECUTE ON FUNCTION public.create_report_requirement TO anon, authenticated;

REVOKE ALL ON FUNCTION public.close_report_requirement FROM PUBLIC, service_role;
GRANT EXECUTE ON FUNCTION public.close_report_requirement TO anon, authenticated;
