-- ขั้น B: ผู้อนุมัติ/ปฏิเสธการผูกบัญชีผู้ปกครองฝั่งครู = **ครูประจำชั้น**
--
-- สเปกในหัวไฟล์ `teacher_parent_binding_approval_page.dart` (STK-1a) เขียนไว้
-- ตั้งแต่แรกว่า Primary Actor คือ "ครูประจำชั้น/School Admin/งานทะเบียน" แต่
-- backend เช็คแค่ว่าครูคนนั้น **สอนวิชาที่เด็กลงทะเบียน** อยู่หรือเปล่า
-- (`course_teachers ⋈ course_students`) ครูสอนวิชาใดก็ได้ที่เจอเด็กสัปดาห์ละ
-- คาบเดียวจึงตัดสินได้ว่าใครมีสิทธิ์เข้าถึงข้อมูลเด็กคนนั้น
--
-- เจ้าของโปรเจกต์ยืนยัน 2026-09-09: ในทางปฏิบัติคนที่ทำเรื่องนี้คือครูประจำชั้น
-- และ **ห้องหนึ่งมีครูประจำชั้น 2 คนเป็นปกติ — ทั้งคู่อนุมัติได้เท่ากัน**
-- (โครงสร้างรองรับอยู่แล้ว: unique key ของ homeroom_assignments มี teacher_id
-- อยู่ด้วย และ set_homeroom_teacher เป็น INSERT ... ON CONFLICT DO NOTHING
-- คือเพิ่มทีละคน ไม่ทับของเดิม)
--
-- เงื่อนไขถูกดึงออกมาเป็นฟังก์ชันกลางตัวเดียว เพราะบั๊กที่เพิ่งแก้ไปใน
-- 20260909000000 เกิดจากเงื่อนไขของ "รายการ" กับ "อนุมัติ" เขียนแยกกันแล้ว
-- หลุดจากกัน — ครั้งนี้ทั้ง 3 ฟังก์ชันเรียกตัวเดียวกัน
--
-- ถ้าโรงเรียนยังไม่ได้กำหนดครูประจำชั้น หรือเด็กยังไม่มีแถวใน student_profiles
-- (ยังไม่จัดห้อง) จะไม่มีครูคนไหนอนุมัติได้ — **ไม่ตัน** เพราะ school_admin
-- อนุมัติได้อยู่แล้วโดยไม่ผ่านเงื่อนไขครู ทางเดินคือให้ฝ่ายทะเบียนอนุมัติแทน

create or replace function _is_homeroom_teacher_of(
  p_teacher_id uuid,
  p_student_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = public, extensions
as $$
  select exists (
    select 1
    from homeroom_assignments ha
    join student_profiles sp
      on sp.academic_year_id = ha.academic_year_id
     and btrim(sp.grade_level) = btrim(ha.grade_level)
     and btrim(sp.room) = btrim(ha.room)
    where ha.teacher_id = p_teacher_id
      and sp.student_id = p_student_id
  );
$$;

comment on function _is_homeroom_teacher_of(uuid, uuid) is
  'ครูคนนี้เป็นครูประจำชั้นของห้องที่นักเรียนคนนี้สังกัดในปีการศึกษานั้นหรือไม่ '
  '— ห้องหนึ่งมีครูประจำชั้นได้หลายคน คืน true ให้ทุกคน';

-- 1) รายการคำขอ: ครูเห็นเฉพาะเด็กในห้องที่ตัวเองเป็นครูประจำชั้น
create or replace function list_parent_links(
  p_token text,
  p_status binding_status default 'pending',
  p_school_id uuid default null
)
returns table (
  id uuid,
  student_id uuid,
  student_first_name varchar,
  student_last_name varchar,
  parent_id uuid,
  parent_first_name varchar,
  parent_last_name varchar,
  parent_email varchar,
  relationship varchar,
  status binding_status,
  requested_at timestamptz
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_school_id uuid;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then
    raise exception 'invalid_session';
  end if;

  if v_actor.role not in ('school_admin', 'teacher', 'super_admin') then
    raise exception 'forbidden';
  end if;

  if v_actor.role = 'super_admin' then
    if p_school_id is null then
      raise exception 'school_id_required';
    end if;
    v_school_id := p_school_id;
  else
    v_school_id := v_actor.school_id;
  end if;

  return query
    select pl.id, pl.student_id, su.first_name, su.last_name,
           pl.parent_id, pu.first_name, pu.last_name, pu.email,
           pl.relationship, pl.status, pl.requested_at
    from parent_links pl
    join users su on su.id = pl.student_id
    join users pu on pu.id = pl.parent_id
    where su.school_id = v_school_id
      and (p_status is null or pl.status = p_status)
      and (
        v_actor.role <> 'teacher'
        or _is_homeroom_teacher_of(v_actor.user_id, pl.student_id)
      )
    order by pl.requested_at desc;
end;
$$;

-- 2) อนุมัติ
create or replace function approve_parent_link(p_token text, p_parent_link_id uuid)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_link parent_links%rowtype;
  v_school_id uuid;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('school_admin', 'teacher', 'super_admin') then
    raise exception 'forbidden';
  end if;

  select * into v_link from parent_links
  where id = p_parent_link_id
  for update;
  if not found then raise exception 'link_not_found'; end if;
  if v_link.status <> 'pending' then raise exception 'link_not_pending'; end if;

  select school_id into v_school_id from users where id = v_link.student_id;
  if v_actor.role <> 'super_admin'
     and v_actor.school_id is distinct from v_school_id then
    raise exception 'forbidden';
  end if;

  if v_actor.role = 'teacher'
     and not _is_homeroom_teacher_of(v_actor.user_id, v_link.student_id) then
    raise exception 'forbidden';
  end if;

  if v_actor.user_id = v_link.parent_id then
    raise exception 'coi_self_approval_blocked';
  end if;

  update parent_links
  set status = 'approved',
      approved_by = v_actor.user_id,
      approved_at = now(),
      first_reviewed_by = v_actor.user_id,
      first_reviewed_at = now(),
      coi_conflict = false
  where id = p_parent_link_id;

  insert into user_roles (user_id, role, school_id, granted_by)
  values (v_link.parent_id, 'parent', v_school_id, v_actor.user_id)
  on conflict (user_id, role, school_id) do nothing;

  insert into audit_logs (
    school_id, user_id, acted_role, action, entity_type, entity_id
  )
  values (
    v_school_id, v_actor.user_id, v_actor.role,
    'parent_link.approve', 'parent_links', p_parent_link_id::text
  );
end;
$$;

-- 3) ปฏิเสธ — ใช้ด่านเดียวกัน การปฏิเสธคำขอของครอบครัวอื่นก็ร้ายแรงพอกัน
create or replace function reject_parent_link(
  p_token text,
  p_parent_link_id uuid,
  p_reason text default null
)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_link parent_links%rowtype;
  v_school_id uuid;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('school_admin', 'teacher', 'super_admin') then
    raise exception 'forbidden';
  end if;

  select * into v_link from parent_links
  where id = p_parent_link_id
  for update;
  if not found then raise exception 'link_not_found'; end if;
  if v_link.status not in ('pending', 'pending_second_review') then
    raise exception 'link_not_pending';
  end if;

  select school_id into v_school_id from users where id = v_link.student_id;
  if v_actor.role <> 'super_admin'
     and v_actor.school_id is distinct from v_school_id then
    raise exception 'forbidden';
  end if;
  if v_link.status = 'pending_second_review'
     and v_actor.role <> 'school_admin' then
    raise exception 'forbidden';
  end if;
  if v_actor.role = 'teacher'
     and not _is_homeroom_teacher_of(v_actor.user_id, v_link.student_id) then
    raise exception 'forbidden';
  end if;

  update parent_links
  set status = 'rejected',
      rejected_by = v_actor.user_id,
      rejected_at = now(),
      rejection_reason = trim(p_reason),
      first_reviewed_by = coalesce(first_reviewed_by, v_actor.user_id),
      first_reviewed_at = coalesce(first_reviewed_at, now())
  where id = p_parent_link_id;

  insert into audit_logs (
    school_id, user_id, acted_role, action, entity_type, entity_id, details
  )
  values (
    v_school_id, v_actor.user_id, v_actor.role,
    'parent_link.reject', 'parent_links', p_parent_link_id::text,
    jsonb_build_object('reason', trim(p_reason))
  );
end;
$$;

grant execute on function list_parent_links(text, binding_status, uuid)
  to anon, authenticated, service_role;
grant execute on function approve_parent_link(text, uuid)
  to anon, authenticated, service_role;
grant execute on function reject_parent_link(text, uuid, text)
  to anon, authenticated, service_role;
