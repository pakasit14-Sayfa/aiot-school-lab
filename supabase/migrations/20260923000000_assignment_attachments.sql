-- 20260923000000_assignment_attachments.sql
--
-- ครูแนบไฟล์ / รูป / ลิงก์เข้าใบงานได้ และทุกอย่างที่แนบไปเก็บอยู่ใน
-- คลังความรู้ของวิชานั้นด้วย (course_files) — ตามที่เจ้าของโปรเจกต์สั่ง
-- 2026-09-23 หลังเทียบกับ Google Classroom (คัดลอกเข้า class Drive folder)
-- และ Microsoft Teams (เก็บใน Class Files library) ซึ่งทั้งคู่เก็บให้เอง
-- ไม่ถามครูว่าจะเก็บเข้าคลังไหม
--
-- ต่างจากสองเจ้านั้นหนึ่งข้อ: ลิงก์ก็เข้าคลังด้วย (ของเขาแนบลิงก์ได้แต่
-- ไม่เก็บเข้าคลัง เพราะลิงก์คัดลอกเข้า Drive ไม่ได้) — เป็นการตัดสินใจของ
-- โปรเจกต์นี้เอง ไม่ใช่การลอกตาม
--
-- สิ่งที่ migration นี้ทำ
--   1. course_files รับลิงก์ได้ + มีหมวด
--   2. register_course_file รับหมวด — ปิดบั๊กที่ชีตอัปโหลดมีช่อง
--      'หมวด/บทเรียน' ให้กรอกมาตลอด แต่ RPC ไม่มีพารามิเตอร์รับ ค่าที่
--      ครูพิมพ์จึงหายทุกครั้งในโหมดจริง
--   3. assignment_attachments — ผูกไฟล์ในคลังเข้ากับใบงาน
--   4. แก้ไข/ลบของในคลัง และลบใบงาน ซึ่งระบบไม่เคยมีเลยทั้งคู่

-- ─────────────────────────────────────────────────────────────────────
-- 1. course_files: รับลิงก์ และมีหมวด
-- ─────────────────────────────────────────────────────────────────────

do $$ begin
  create type course_file_kind as enum ('file', 'link');
exception when duplicate_object then null; end $$;

alter table public.course_files
  add column if not exists kind public.course_file_kind not null default 'file',
  add column if not exists url text,
  add column if not exists category text;

-- ลิงก์ไม่มีไฟล์จริงในถัง จึงไม่มี storage_path และไม่มีขนาด
alter table public.course_files alter column storage_path drop not null;
alter table public.course_files alter column size_bytes drop not null;

alter table public.course_files
  drop constraint if exists course_files_kind_shape;
alter table public.course_files add constraint course_files_kind_shape check (
  (kind = 'file' and storage_path is not null and size_bytes is not null)
  or
  (kind = 'link' and url is not null and storage_path is null)
);

-- ─────────────────────────────────────────────────────────────────────
-- 2. assignment_attachments — ใบงานชี้ไปที่ของในคลัง ไม่ได้ถือสำเนาเอง
-- ─────────────────────────────────────────────────────────────────────

create table if not exists public.assignment_attachments (
  id uuid primary key default gen_random_uuid(),
  assignment_id uuid not null references public.assignments(id) on delete cascade,
  -- restrict โดยตั้งใจ: ลบของในคลังทั้งที่ใบงานยังอ้างอยู่ไม่ได้ ไม่งั้น
  -- นักเรียนกดไฟล์แล้วเจอของหาย ต้องเอาออกจากใบงานก่อน
  course_file_id uuid not null references public.course_files(id) on delete restrict,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  unique (assignment_id, course_file_id)
);

alter table public.assignment_attachments enable row level security;

create index if not exists assignment_attachments_assignment_idx
  on public.assignment_attachments (assignment_id, sort_order);
create index if not exists assignment_attachments_file_idx
  on public.assignment_attachments (course_file_id);

-- ─────────────────────────────────────────────────────────────────────
-- 3. ตัวช่วยตรวจสิทธิ์ — ครูของวิชานั้น
-- ─────────────────────────────────────────────────────────────────────

create or replace function public.assert_course_teacher(p_token text, p_course_id uuid)
returns uuid
language plpgsql security definer set search_path = public, extensions
as $$
declare v_actor record;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role <> 'teacher' then raise exception 'forbidden'; end if;
  if not exists (
    select 1 from course_teachers ct
    where ct.course_id = p_course_id and ct.teacher_id = v_actor.user_id
  ) then raise exception 'forbidden'; end if;
  return v_actor.user_id;
end;
$$;
revoke all on function public.assert_course_teacher(text, uuid) from public;
grant execute on function public.assert_course_teacher(text, uuid)
  to anon, authenticated, service_role;

-- ─────────────────────────────────────────────────────────────────────
-- 4. คลังความรู้: register (รับหมวดแล้ว) · link · update · delete
-- ─────────────────────────────────────────────────────────────────────

-- พารามิเตอร์ที่ 6 มี default ตัวเรียกเดิมที่ส่ง 5 ตัวจึงยังทำงานได้
create or replace function public.register_course_file(
  p_token text,
  p_course_id uuid,
  p_storage_path text,
  p_file_name text,
  p_size_bytes bigint,
  p_category text default null
) returns table(file_id uuid)
language plpgsql security definer set search_path = public, extensions
as $$
declare v_user uuid;
begin
  v_user := assert_course_teacher(p_token, p_course_id);
  return query
  insert into course_files (
    course_id, uploaded_by, storage_path, file_name, size_bytes, kind, category
  ) values (
    p_course_id, v_user, p_storage_path, p_file_name, p_size_bytes, 'file',
    nullif(btrim(coalesce(p_category, '')), '')
  ) returning course_files.id;
end;
$$;
revoke all on function public.register_course_file(text, uuid, text, text, bigint, text) from public;
grant execute on function public.register_course_file(text, uuid, text, text, bigint, text)
  to anon, authenticated, service_role;

create or replace function public.register_course_link(
  p_token text,
  p_course_id uuid,
  p_url text,
  p_title text default null,
  p_category text default null
) returns table(file_id uuid)
language plpgsql security definer set search_path = public, extensions
as $$
declare
  v_user uuid;
  v_url text := btrim(coalesce(p_url, ''));
begin
  v_user := assert_course_teacher(p_token, p_course_id);
  -- กันลิงก์ที่เปิดไม่ได้ตั้งแต่ต้นทาง นักเรียนจะได้ไม่กดแล้วเจอหน้าเปล่า
  if v_url !~* '^https?://\S+$' then raise exception 'invalid_url'; end if;

  return query
  insert into course_files (
    course_id, uploaded_by, file_name, kind, url, category
  ) values (
    p_course_id, v_user,
    coalesce(nullif(btrim(coalesce(p_title, '')), ''), v_url),
    'link', v_url,
    nullif(btrim(coalesce(p_category, '')), '')
  ) returning course_files.id;
end;
$$;
revoke all on function public.register_course_link(text, uuid, text, text, text) from public;
grant execute on function public.register_course_link(text, uuid, text, text, text)
  to anon, authenticated, service_role;

-- แก้ชื่อ / หมวด / ปลายทางของลิงก์ — ของในคลังใช้ร่วมกันหลายใบงานได้
-- แก้ที่นี่ทีเดียวจึงเปลี่ยนทุกใบงานที่อ้างอยู่ ตั้งใจให้เป็นแบบนั้น
create or replace function public.update_course_file(
  p_token text,
  p_file_id uuid,
  p_file_name text default null,
  p_category text default null,
  p_url text default null
) returns void
language plpgsql security definer set search_path = public, extensions
as $$
declare
  v_course_id uuid;
  v_kind public.course_file_kind;
begin
  select course_id, kind into v_course_id, v_kind from course_files where id = p_file_id;
  if not found then raise exception 'file_not_found'; end if;
  perform assert_course_teacher(p_token, v_course_id);

  if p_url is not null then
    if v_kind <> 'link' then raise exception 'not_a_link'; end if;
    if btrim(p_url) !~* '^https?://\S+$' then raise exception 'invalid_url'; end if;
  end if;

  update course_files set
    file_name = coalesce(nullif(btrim(coalesce(p_file_name, '')), ''), file_name),
    category  = case when p_category is null then category
                     else nullif(btrim(p_category), '') end,
    url       = coalesce(btrim(p_url), url)
  where id = p_file_id;
end;
$$;
revoke all on function public.update_course_file(text, uuid, text, text, text) from public;
grant execute on function public.update_course_file(text, uuid, text, text, text)
  to anon, authenticated, service_role;

-- ลบของออกจากคลังถาวร — ของที่ยังมีใบงานอ้างอยู่ลบไม่ได้ (FK restrict)
-- แปลง error ของ FK เป็นข้อความที่บอกครูได้ว่าติดอยู่กี่ใบงาน
create or replace function public.delete_course_file(p_token text, p_file_id uuid)
returns table(storage_path text)
language plpgsql security definer set search_path = public, extensions
as $$
declare
  v_course_id uuid;
  v_path text;
  v_used int;
begin
  select course_id, course_files.storage_path into v_course_id, v_path
  from course_files where id = p_file_id;
  if not found then raise exception 'file_not_found'; end if;
  perform assert_course_teacher(p_token, v_course_id);

  select count(*) into v_used from assignment_attachments where course_file_id = p_file_id;
  if v_used > 0 then
    raise exception 'file_in_use_by_% assignments', v_used using errcode = 'P0001';
  end if;

  delete from course_files where id = p_file_id;
  -- คืน path ให้ผู้เรียกไปลบไฟล์ในถังต่อ (Edge Function) — RPC ลบ Storage เองไม่ได้
  return query select v_path;
end;
$$;
revoke all on function public.delete_course_file(text, uuid) from public;
grant execute on function public.delete_course_file(text, uuid)
  to anon, authenticated, service_role;

-- list เดิมไม่ได้คืน kind/url/category — ของที่เพิ่มมาจะมองไม่เห็นเลย
-- ต้อง drop ก่อน: เปลี่ยนรูปร่างคอลัมน์ที่คืน create or replace ทำไม่ได้
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
  select f.id, f.kind::text, f.storage_path, f.url, f.file_name, f.category,
         f.size_bytes, f.uploaded_by, u.first_name, u.last_name, f.created_at
  from course_files f
  join users u on u.id = f.uploaded_by
  where f.course_id = p_course_id
  order by f.created_at desc;
end;
$$;
revoke all on function public.list_course_files(text, uuid) from public;
grant execute on function public.list_course_files(text, uuid)
  to anon, authenticated, service_role;

-- ─────────────────────────────────────────────────────────────────────
-- 5. ผูก / ถอด / อ่าน ไฟล์แนบของใบงาน
-- ─────────────────────────────────────────────────────────────────────

create or replace function public.attach_assignment_file(
  p_token text,
  p_assignment_id uuid,
  p_course_file_id uuid,
  p_sort_order integer default null
) returns table(attachment_id uuid)
language plpgsql security definer set search_path = public, extensions
as $$
declare
  v_course_id uuid;
  v_file_course uuid;
  v_order integer;
begin
  select course_id into v_course_id from assignments where id = p_assignment_id;
  if not found then raise exception 'assignment_not_found'; end if;
  perform assert_course_teacher(p_token, v_course_id);

  select course_id into v_file_course from course_files where id = p_course_file_id;
  if not found then raise exception 'file_not_found'; end if;
  -- ไฟล์ของวิชาอื่นแนบข้ามมาไม่ได้ คลังเป็นของรายวิชา
  if v_file_course <> v_course_id then raise exception 'file_course_mismatch'; end if;

  select coalesce(p_sort_order, coalesce(max(sort_order), -1) + 1)
  into v_order from assignment_attachments where assignment_id = p_assignment_id;

  return query
  insert into assignment_attachments (assignment_id, course_file_id, sort_order)
  values (p_assignment_id, p_course_file_id, v_order)
  on conflict (assignment_id, course_file_id) do update set sort_order = excluded.sort_order
  returning assignment_attachments.id;
end;
$$;
revoke all on function public.attach_assignment_file(text, uuid, uuid, integer) from public;
grant execute on function public.attach_assignment_file(text, uuid, uuid, integer)
  to anon, authenticated, service_role;

-- 'เอาออกจากใบงาน' ไม่ใช่ 'ลบ' — ไฟล์ยังอยู่ในคลังความรู้
create or replace function public.detach_assignment_file(p_token text, p_attachment_id uuid)
returns void
language plpgsql security definer set search_path = public, extensions
as $$
declare v_course_id uuid;
begin
  select a.course_id into v_course_id
  from assignment_attachments at join assignments a on a.id = at.assignment_id
  where at.id = p_attachment_id;
  if not found then raise exception 'attachment_not_found'; end if;
  perform assert_course_teacher(p_token, v_course_id);

  delete from assignment_attachments where id = p_attachment_id;
end;
$$;
revoke all on function public.detach_assignment_file(text, uuid) from public;
grant execute on function public.detach_assignment_file(text, uuid)
  to anon, authenticated, service_role;

create or replace function public.reorder_assignment_attachment(
  p_token text, p_attachment_id uuid, p_sort_order integer
) returns void
language plpgsql security definer set search_path = public, extensions
as $$
declare v_course_id uuid;
begin
  select a.course_id into v_course_id
  from assignment_attachments at join assignments a on a.id = at.assignment_id
  where at.id = p_attachment_id;
  if not found then raise exception 'attachment_not_found'; end if;
  perform assert_course_teacher(p_token, v_course_id);

  update assignment_attachments set sort_order = p_sort_order where id = p_attachment_id;
end;
$$;
revoke all on function public.reorder_assignment_attachment(text, uuid, integer) from public;
grant execute on function public.reorder_assignment_attachment(text, uuid, integer)
  to anon, authenticated, service_role;

-- นักเรียนต้องอ่านได้ด้วย ไม่งั้นแนบไปก็ไม่มีใครเห็น
create or replace function public.list_assignment_attachments(
  p_token text, p_assignment_id uuid
) returns table(
  attachment_id uuid,
  file_id uuid,
  kind text,
  file_name varchar,
  url text,
  category text,
  size_bytes bigint,
  sort_order integer
)
language plpgsql security definer set search_path = public, extensions
as $$
declare
  v_actor record;
  v_course_id uuid;
  v_status text;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;

  select course_id, status::text into v_course_id, v_status
  from assignments where id = p_assignment_id;
  if not found then raise exception 'assignment_not_found'; end if;

  if exists (
    select 1 from course_teachers ct
    where ct.course_id = v_course_id and ct.teacher_id = v_actor.user_id
  ) then
    null; -- ครูเห็นได้ทั้งใบงานร่างและที่เผยแพร่แล้ว
  elsif exists (
    select 1 from course_students ce
    where ce.course_id = v_course_id and ce.student_id = v_actor.user_id
  ) then
    -- ใบงานร่างยังไม่ถูกมอบหมาย นักเรียนต้องไม่เห็นไฟล์แนบของมัน
    if v_status <> 'published' then raise exception 'forbidden'; end if;
  else
    raise exception 'forbidden';
  end if;

  return query
  select at.id, f.id, f.kind::text, f.file_name, f.url, f.category,
         f.size_bytes, at.sort_order
  from assignment_attachments at
  join course_files f on f.id = at.course_file_id
  where at.assignment_id = p_assignment_id
  order by at.sort_order, at.created_at;
end;
$$;
revoke all on function public.list_assignment_attachments(text, uuid) from public;
grant execute on function public.list_assignment_attachments(text, uuid)
  to anon, authenticated, service_role;

-- ─────────────────────────────────────────────────────────────────────
-- 6. ลบใบงาน — ระบบไม่เคยมีมาก่อน สร้างผิดแล้วลบทิ้งไม่ได้เลย
-- ─────────────────────────────────────────────────────────────────────

create or replace function public.delete_assignment(p_token text, p_assignment_id uuid)
returns void
language plpgsql security definer set search_path = public, extensions
as $$
declare
  v_course_id uuid;
  v_subs int;
begin
  select course_id into v_course_id from assignments where id = p_assignment_id;
  if not found then raise exception 'assignment_not_found'; end if;
  perform assert_course_teacher(p_token, v_course_id);

  -- มีนักเรียนส่งงานแล้วห้ามลบ — งานและคะแนนของเด็กจะหายไปด้วย
  -- ครูที่ไม่อยากให้ส่งต่อแล้วให้ใช้ 'ปิดรับงาน' (unpublish_assignment) แทน
  select count(*) into v_subs from submissions where assignment_id = p_assignment_id;
  if v_subs > 0 then
    raise exception 'assignment_has_% submissions', v_subs using errcode = 'P0001';
  end if;

  -- ไฟล์แนบถูกถอดตาม (cascade) แต่ตัวไฟล์ยังอยู่ในคลังความรู้
  delete from assignments where id = p_assignment_id;
end;
$$;
revoke all on function public.delete_assignment(text, uuid) from public;
grant execute on function public.delete_assignment(text, uuid)
  to anon, authenticated, service_role;
