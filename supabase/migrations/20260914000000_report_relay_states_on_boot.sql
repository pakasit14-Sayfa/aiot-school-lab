-- บอร์ดรายงานสถานะรีเลย์ทุกช่องได้เอง โดยไม่ต้องผูกกับคำสั่ง
--
-- ก่อนหน้านี้ `device_relay_states` เขียนได้ทางเดียวคือผ่าน `ack_device_command`
-- ซึ่งต้องมี command id — บอร์ดที่เพิ่งบูต (ไฟดับ/รีสตาร์ท) รีเลย์ทุกช่อง OFF
-- จริง แต่ไม่มีคำสั่งให้ ack จึงบอกแอปไม่ได้ แอปยังโชว์ "ยืนยันว่าเปิดอยู่"
-- จากครั้งล่าสุด → แอดมินเชื่อว่าปั๊มน้ำยังทำงานทั้งที่หยุดไปแล้ว
--
-- เคสจริง 2026-09-14: บอร์ดเก่าพัง กำลังลงบอร์ดใหม่ — จังหวะที่ต้องมี RPC นี้
-- ให้เฟิร์มแวร์เรียกครั้งเดียวหลังต่อ WiFi ก่อนเริ่ม loop
create or replace function report_relay_states(
  p_device_token text,
  p_states jsonb
)
returns int
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_device record;
  v_item jsonb;
  v_relay smallint;
  v_state boolean;
  v_count int := 0;
begin
  select * into v_device from devices
    where token_hash = encode(digest(p_device_token, 'sha256'), 'hex');
  if not found then
    raise exception 'invalid_device_token';
  end if;

  if p_states is null or jsonb_typeof(p_states) <> 'array' then
    raise exception 'invalid_states: expected array of {relay, state}';
  end if;

  -- รายงานตัวไปด้วยในตัว — จะได้ไม่ต้องรอ heartbeat รอบถัดไป
  update devices set status = 'online', last_seen_at = now()
    where devices.id = v_device.id;

  for v_item in select * from jsonb_array_elements(p_states) loop
    if jsonb_typeof(v_item -> 'relay') <> 'number'
       or jsonb_typeof(v_item -> 'state') <> 'boolean' then
      raise exception 'invalid_states: each item needs numeric relay and boolean state, got %', v_item;
    end if;
    v_relay := (v_item ->> 'relay')::smallint;
    v_state := (v_item ->> 'state')::boolean;

    -- updated_by_command_id เป็น null โดยตั้งใจ: สถานะนี้มาจากบอร์ดเอง
    -- ไม่ได้มาจากคำสั่งของใคร
    insert into device_relay_states (device_id, relay_no, state, updated_at, updated_by_command_id)
    values (v_device.id, v_relay, v_state, now(), null)
    on conflict (device_id, relay_no) do update
      set state = excluded.state,
          updated_at = excluded.updated_at,
          updated_by_command_id = null;
    v_count := v_count + 1;
  end loop;

  return v_count;
end;
$$;

revoke all on function report_relay_states(text, jsonb) from public;
grant execute on function report_relay_states(text, jsonb) to anon, authenticated;
