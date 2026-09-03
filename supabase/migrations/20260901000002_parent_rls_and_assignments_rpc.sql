-- 1. Enable RLS and add Parent Read Policies for attendance_records
DO $$
BEGIN
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'attendance_records') THEN
    ALTER TABLE attendance_records ENABLE ROW LEVEL SECURITY;
    
    DROP POLICY IF EXISTS "Parents can view attendance of linked students" ON attendance_records;
    CREATE POLICY "Parents can view attendance of linked students"
    ON attendance_records FOR SELECT
    TO authenticated
    USING (
      student_id IN (
        SELECT student_id FROM parent_links WHERE parent_id = auth.uid() AND status = 'approved'
      )
    );
  END IF;
END $$;

-- 2. Enable RLS and add Parent Read Policies for assignments and submissions
DO $$
BEGIN
  -- Assignments
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'assignments') THEN
    ALTER TABLE assignments ENABLE ROW LEVEL SECURITY;
    DROP POLICY IF EXISTS "Parents can view assignments of their linked students courses" ON assignments;
    CREATE POLICY "Parents can view assignments of their linked students courses"
    ON assignments FOR SELECT
    TO authenticated
    USING (
      course_id IN (
        SELECT cs.course_id FROM course_students cs
        JOIN parent_links pl ON pl.student_id = cs.student_id
        WHERE pl.parent_id = auth.uid() AND pl.status = 'approved'
      )
    );
  END IF;

  -- Submissions
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'submissions') THEN
    ALTER TABLE submissions ENABLE ROW LEVEL SECURITY;
    DROP POLICY IF EXISTS "Parents can view submissions of their linked students" ON submissions;
    CREATE POLICY "Parents can view submissions of their linked students"
    ON submissions FOR SELECT
    TO authenticated
    USING (
      student_id IN (
        SELECT student_id FROM parent_links WHERE parent_id = auth.uid() AND status = 'approved'
      )
    );
  END IF;
END $$;

-- 3. Create RPC for Parent to fetch assignments for their child
CREATE OR REPLACE FUNCTION list_my_student_assignments(
  p_token text,
  p_student_id uuid
)
RETURNS TABLE (
  assignment_id uuid,
  course_name varchar,
  title text,
  due_at timestamptz,
  status text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $func$
DECLARE
  v_actor record;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN RAISE EXCEPTION 'invalid_session'; END IF;
  IF v_actor.role <> 'parent' THEN
    RAISE EXCEPTION 'forbidden';
  END IF;


  -- Ensure actor is an approved parent of this student
  IF NOT EXISTS (
    SELECT 1 FROM parent_links pl
    WHERE pl.parent_id = v_actor.user_id 
      AND pl.student_id = p_student_id
      AND pl.status = 'approved'
  ) THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  RETURN QUERY
  SELECT
    a.id AS assignment_id,
    c.subject_name::varchar AS course_name,
    a.title::text,
    a.due_at,
    COALESCE(s.status::text, 'pending') AS status
  FROM assignments a
  JOIN courses c ON c.id = a.course_id
  JOIN course_students cs ON cs.course_id = c.id
  LEFT JOIN submissions s ON s.assignment_id = a.id AND s.student_id = p_student_id
  WHERE cs.student_id = p_student_id
    AND a.status = 'published'
  ORDER BY a.due_at ASC NULLS LAST;
END;
$func$;

REVOKE ALL ON FUNCTION list_my_student_assignments(text, uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION list_my_student_assignments(text, uuid) TO anon, authenticated;
