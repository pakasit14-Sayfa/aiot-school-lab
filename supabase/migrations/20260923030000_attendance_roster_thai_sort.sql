-- list_homeroom_attendance / list_course_attendance เรียงด้วย
-- `ORDER BY u.first_name ASC` แบบ collation default ของ DB (en_US.UTF-8)
-- ซึ่งเรียงตาม Unicode codepoint ตรง ๆ ไม่ใช่พจนานุกรมไทย — ชื่อที่ขึ้นต้น
-- ด้วยสระนำ (เ-/แ-/โ-/ใ-/ไ-) จะถูกจัดกลุ่มท้ายสุดของตัวอักษรนั้นแทนที่จะ
-- แทรกตามพยัญชนะถัดไปแบบที่คนไทยคาดหวัง (เช่น "เอกชัย" ควรอยู่ใกล้ "อ"
-- ไม่ใช่ไปอยู่ท้ายสุด) ทดสอบแล้วบน local ว่า collation "th-TH-x-icu"
-- (มากับ ICU ของ Postgres นี้อยู่แล้ว ไม่ต้องติดตั้งเพิ่ม) เรียงถูกต้อง

create or replace function public.list_homeroom_attendance(
  p_token text,
  p_grade_level text,
  p_room text,
  p_class_date date
)
returns table(
  student_id uuid,
  student_name text,
  student_code text,
  status text,
  note text,
  marked_at timestamp with time zone
)
language plpgsql
security definer
set search_path to 'public', 'extensions'
as $function$
DECLARE
  v_actor record;
  v_year uuid;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;
  v_year := public._current_academic_year_id(v_actor.school_id);

  PERFORM public._assert_homeroom_access(v_actor, p_grade_level, p_room, v_year);

  RETURN QUERY
  SELECT
    u.id AS student_id,
    (u.first_name || ' ' || u.last_name)::text AS student_name,
    coalesce(u.student_code, '')::text AS student_code,
    har.status,
    har.note,
    har.marked_at
  FROM public.student_profiles sp
  JOIN public.users u ON u.id = sp.student_id
  LEFT JOIN public.homeroom_attendance_records har
    ON har.student_id = sp.student_id AND har.class_date = p_class_date
  WHERE sp.academic_year_id = v_year
    AND sp.grade_level = p_grade_level AND sp.room = p_room
  ORDER BY u.first_name COLLATE "th-TH-x-icu" ASC,
           u.last_name COLLATE "th-TH-x-icu" ASC;
END;
$function$;

create or replace function public.list_course_attendance(
  p_token text,
  p_course_id uuid,
  p_class_date date
)
returns table(
  student_id uuid,
  student_name text,
  student_code text,
  status text,
  note text,
  marked_at timestamp with time zone
)
language plpgsql
security definer
set search_path to 'public', 'extensions'
as $function$
DECLARE
  v_actor record;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

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
  ORDER BY u.first_name COLLATE "th-TH-x-icu" ASC,
           u.last_name COLLATE "th-TH-x-icu" ASC;
END;
$function$;
