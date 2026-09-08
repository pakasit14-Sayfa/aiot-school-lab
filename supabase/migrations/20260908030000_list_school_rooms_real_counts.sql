-- list_school_rooms hardcoded devices_count=0, training_kits_count=0, and
-- resource_status='ปกติ' for every room unconditionally, unlike its sibling
-- list_school_buildings which does a real join. Every room in the app
-- looked like it had zero devices and was always "normal" regardless of
-- actual state. floor also fabricated 'ชั้น 1' via COALESCE when null,
-- inventing a value the school never entered. Found 2026-09-08 during a
-- full School Admin re-audit.
--
-- devices_count/training_kits_count now join devices.room to rooms.name,
-- the same name-matching pattern list_school_buildings already uses for
-- devices.building. resource_status has no real signal anywhere in the
-- schema (unlike devices.status), so it now returns null rather than an
-- invented 'ปกติ' — honest "ยังไม่มีข้อมูล" is the caller's job, not this
-- RPC's job to paper over with a fake constant.
create or replace function public.list_school_rooms(p_token text, p_building_id uuid default null::uuid)
returns table(
  id uuid, school_id uuid, building_id uuid, building_name text, name text,
  code text, floor text, room_type text, capacity integer, teacher_name text,
  devices_count bigint, training_kits_count bigint, status text, resource_status text
)
language plpgsql
security definer
set search_path to 'public', 'extensions'
as $function$
declare
  v_actor record;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then
    raise exception 'invalid_session';
  end if;

  if v_actor.role not in ('school_admin', 'super_admin') then
    raise exception 'forbidden';
  end if;

  return query
  select
    r.id,
    r.school_id,
    r.building_id,
    coalesce(b.name, 'ไม่ระบุอาคาร') as building_name,
    r.name,
    coalesce(r.code, ''),
    r.floor,
    coalesce(r.room_type, 'ห้องเรียน'),
    coalesce(r.capacity, 30),
    coalesce(r.teacher_name, ''),
    coalesce(dc.cnt, 0)::bigint as devices_count,
    coalesce(dc.training_cnt, 0)::bigint as training_kits_count,
    coalesce(r.status, 'active') as status,
    null::text as resource_status
  from public.rooms r
  left join public.buildings b on b.id = r.building_id
  left join (
    select d.room, count(*) as cnt,
      count(case when d.type::text ilike '%kit%' or d.name ilike '%ฝึก%' then 1 end) as training_cnt
    from public.devices d
    where d.school_id = v_actor.school_id
    group by d.room
  ) dc on dc.room = r.name
  where r.school_id = v_actor.school_id
    and (p_building_id is null or r.building_id = p_building_id)
  order by r.name asc;
end;
$function$;
