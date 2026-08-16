-- =====================================================================
-- LA-9 "ดูรายงานภาพรวมของสถานศึกษา" — ให้ผู้บริหาร (executive) เข้าถึง
-- สถิติระดับโรงเรียนที่ยังไม่เคยมีให้เรียกได้เลย โดยไม่ละเมิด BR1
-- ("ผู้บริหารเห็นภาพรวมระดับโรงเรียน ไม่ใช่ข้อมูลรายคนเชิงลึก"):
--
-- 1. count_school_users_by_role — RPC ใหม่ คืน "จำนวนผู้ใช้ต่อ role"
--    เท่านั้น (ไม่มีชื่อ/อีเมล/รหัสรายคนเลย) แทนที่จะเปิด list_school_users
--    ตรงๆ ให้ executive ซึ่งจะคืนรายชื่อ/อีเมลทุกคนในโรงเรียน ขัด BR1 ชัดเจน
-- 2. list_school_devices — เพิ่ม 'executive' เข้าไปใน role ที่อนุญาต
--    (เดิมมีแค่ teacher/school_admin) ตัวนี้ปลอดภัยเพราะคืนข้อมูลอุปกรณ์
--    ไม่มีข้อมูลบุคคลเลย
-- =====================================================================

create or replace function count_school_users_by_role(p_token text)
returns table (
  active_role text,
  user_count bigint
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then
    raise exception 'invalid_session';
  end if;

  if v_actor.role not in ('school_admin', 'super_admin', 'executive') then
    raise exception 'forbidden';
  end if;

  return query
    select
      coalesce(
        (select ur.role::text from user_roles ur
         where ur.user_id = u.id and ur.school_id is not distinct from u.school_id
         order by ur.granted_at desc limit 1),
        (select ur.role::text from user_roles ur
         where ur.user_id = u.id
         order by ur.granted_at desc limit 1),
        'student'
      ) as active_role,
      count(*) as user_count
    from users u
    where v_actor.role = 'super_admin' or u.school_id is not distinct from v_actor.school_id
    group by active_role
    order by active_role;
end;
$$;

revoke all on function count_school_users_by_role(text) from public;
grant execute on function count_school_users_by_role(text) to anon, authenticated;

create or replace function list_school_devices(p_token text)
returns table (
  device_id uuid,
  name varchar,
  type device_type,
  location varchar,
  status device_status
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('teacher', 'school_admin', 'executive') then
    raise exception 'forbidden';
  end if;

  return query
  select d.id, d.name, d.type, d.location, d.status
  from devices d
  where d.school_id = v_actor.school_id
  order by d.location, d.name;
end;
$$;

revoke all on function list_school_devices(text) from public;
grant execute on function list_school_devices(text) to anon, authenticated;
