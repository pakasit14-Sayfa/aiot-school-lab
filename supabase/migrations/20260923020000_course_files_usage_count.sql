-- 20260923020000_course_files_usage_count.sql
--
-- คลังความรู้ต้องบอกได้ว่าของแต่ละชิ้นถูกใช้อยู่ในกี่ใบงาน ก่อนที่ครูจะกดลบ
-- แล้วเจอ error `file_in_use_by_N assignments` จาก delete_course_file
--
-- นับที่ฐานข้อมูล ไม่ใช่ให้แอปไล่ดึงไฟล์แนบของทุกใบงานมานับเอง — วิธีหลังคือ
-- N round trip ต่อการเปิดหน้าหนึ่งครั้ง และนับผิดได้ถ้าครูสอนหลายวิชา

drop function if exists public.list_course_files(text, uuid);

create function public.list_course_files(p_token text, p_course_id uuid)
returns table(
  file_id uuid,
  kind text,
  storage_path text,
  url text,
  file_name varchar,
  category text,
  size_bytes bigint,
  used_by_assignments integer,
  uploaded_by uuid,
  uploader_first_name varchar,
  uploader_last_name varchar,
  created_at timestamptz
)
language plpgsql security definer set search_path = public, extensions
as $$
declare v_actor record;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;

  -- ครูของวิชา หรือ นักเรียนที่ลงทะเบียนวิชานั้น
  if not exists (
    select 1 from course_teachers ct
    where ct.course_id = p_course_id and ct.teacher_id = v_actor.user_id
  ) and not exists (
    select 1 from course_students ce
    where ce.course_id = p_course_id and ce.student_id = v_actor.user_id
  ) then raise exception 'forbidden'; end if;

  return query
  select f.id, f.kind, f.storage_path, f.url, f.file_name, f.category,
         f.size_bytes,
         (select count(*)::int from assignment_attachments at
           where at.course_file_id = f.id) as used_by_assignments,
         f.uploaded_by, u.first_name, u.last_name, f.created_at
  from course_files f
  join users u on u.id = f.uploaded_by
  where f.course_id = p_course_id
  order by f.created_at desc;
end;
$$;
revoke all on function public.list_course_files(text, uuid) from public;
grant execute on function public.list_course_files(text, uuid)
  to anon, authenticated, service_role;
