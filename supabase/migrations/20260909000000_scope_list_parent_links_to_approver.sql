-- list_parent_links: ให้ครูเห็นเฉพาะคำขอที่ตัวเองมีสิทธิ์อนุมัติจริง
--
-- ปัญหา: ของเดิมกรองแค่ `su.school_id = v_school_id` คือ "นักเรียนอยู่โรงเรียน
-- เดียวกัน" เท่านั้น ครูคนไหนก็เห็นคำขอผูกบัญชีผู้ปกครองของนักเรียน **ทุกคน**
-- ในโรงเรียน พร้อมชื่อ-นามสกุลนักเรียน และชื่อ/อีเมลผู้ปกครอง ทั้งที่
-- `approve_parent_link` อนุญาตให้ครูอนุมัติได้เฉพาะนักเรียนที่ตัวเองสอนเท่านั้น
--
-- ผลคือด่านของ "รายการ" กว้างกว่าด่านของ "อนุมัติ" ครูจึงเห็นคำขอที่กดแล้ว
-- เจอ forbidden เฉย ๆ และข้อมูลติดต่อของครอบครัวคนอื่นก็หลุดไปยังครูที่ไม่
-- เกี่ยวข้องด้วย
--
-- migration นี้ทำให้ 2 ด่านกว้างเท่ากันพอดี — **หดสิทธิ์อย่างเดียว** ไม่มีใคร
-- ได้สิทธิ์เพิ่ม และไม่เปลี่ยนว่าใครอนุมัติได้ (นั่นเป็นคนละเรื่อง ยังไม่แตะ
-- ในรอบนี้: สเปกในหัวไฟล์ teacher_parent_binding_approval_page.dart ระบุว่า
-- ผู้อนุมัติควรเป็น "ครูประจำชั้น" แต่ backend เช็คแค่ "ครูที่สอนวิชาที่เด็ก
-- ลงทะเบียน" — ต้องให้เจ้าของโปรเจกต์เคาะก่อนว่าจะบีบเป็นครูประจำชั้นไหม)
--
-- school_admin / super_admin ยังเห็นทั้งโรงเรียนเหมือนเดิม (งานทะเบียนต้องเห็น
-- ครบเพื่ออนุมัติแทนได้เมื่อไม่มีครูที่เกี่ยวข้อง)

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
      -- เงื่อนไขเดียวกับที่ approve_parent_link ใช้ตัดสินว่าครูอนุมัติได้ไหม
      and (
        v_actor.role <> 'teacher'
        or exists (
          select 1
          from course_teachers ct
          join course_students cs on cs.course_id = ct.course_id
          where ct.teacher_id = v_actor.user_id
            and cs.student_id = pl.student_id
        )
      )
    order by pl.requested_at desc;
end;
$$;

grant execute on function list_parent_links(text, binding_status, uuid)
  to anon, authenticated, service_role;
