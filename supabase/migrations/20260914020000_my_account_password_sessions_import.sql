-- บัญชีของฉัน + การนำเข้าผู้ใช้ที่ปลอดภัย (2026-09-14)
--
-- 1) change_my_password — เปลี่ยนรหัสผ่านจากในแอปด้วยรหัสปัจจุบัน (เดิมมีแค่
--    เส้นทาง OTP ทางอีเมล "ลืมรหัสผ่าน") และเป็นทางเดียวที่ล้าง
--    users.must_change_password ซึ่งมีคอลัมน์มาตั้งแต่ต้นแต่ไม่มีใครเซ็ต/อ่าน
-- 2) list_my_sessions / revoke_my_session — "อุปกรณ์ที่เข้าสู่ระบบ" ของจริง
--    (ตาราง sessions มี device_info/ip_address อยู่แล้ว มีแค่ auth_sign_out_all)
-- 3) import_school_users_batch_for_school_admin — เดิมตั้งรหัส 'Test1234!'
--    เหมือนกันทุกคน ไม่ตั้ง must_change_password และข้ามอีเมลซ้ำแบบเงียบ
--    หน้านำเข้าจึงถูกปิดไว้ด้วยเหตุผลด้านความปลอดภัยตั้งแต่ 2026-09-07
--    ตอนนี้: รหัสชั่วคราวสุ่มต่อคน + must_change_password = true (แอปบังคับ
--    เปลี่ยนก่อนเข้าใช้ — ดู RoleRouter) + คืน credentials ให้แอดมินส่งมอบ
--    ครั้งเดียว + รายงานแถวที่ข้ามพร้อมเหตุผล

-- ── 1) เปลี่ยนรหัสผ่าน ──────────────────────────────────────────────────

create or replace function change_my_password(
  p_token text,
  p_current_password text,
  p_new_password text
)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_user users%rowtype;
  v_token_hash text := encode(digest(p_token, 'sha256'), 'hex');
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;

  select * into v_user from users where id = v_actor.user_id for update;
  if not found then raise exception 'invalid_session'; end if;

  if coalesce(p_new_password, '') = '' or length(p_new_password) < 8 then
    raise exception 'password_too_short';
  end if;
  if v_user.password_hash <> crypt(coalesce(p_current_password, ''), v_user.password_hash) then
    raise exception 'wrong_current_password';
  end if;
  if p_new_password = p_current_password then
    raise exception 'password_unchanged';
  end if;

  update users
  set password_hash = crypt(p_new_password, gen_salt('bf')),
      must_change_password = false
  where id = v_user.id;

  -- เซสชันอื่นทั้งหมดหลุด เหลือเครื่องที่กำลังเปลี่ยนรหัสอยู่
  update sessions set revoked_at = now()
  where user_id = v_user.id and revoked_at is null and token_hash <> v_token_hash;

  insert into audit_logs (school_id, user_id, acted_role, action, entity_type, entity_id)
  values (v_actor.school_id, v_actor.user_id, v_actor.role, 'auth.change_password',
          'users', v_user.id::text);
end;
$$;

-- ── 2) เซสชันของฉัน ─────────────────────────────────────────────────────

create or replace function list_my_sessions(p_token text)
returns table (
  id uuid,
  device_info varchar,
  ip_address varchar,
  created_at timestamptz,
  expires_at timestamptz,
  is_current boolean
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_token_hash text := encode(digest(p_token, 'sha256'), 'hex');
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;

  return query
    select s.id, s.device_info, s.ip_address, s.created_at, s.expires_at,
           s.token_hash = v_token_hash
    from sessions s
    where s.user_id = v_actor.user_id
      and s.revoked_at is null
      and s.expires_at > now()
    order by (s.token_hash = v_token_hash) desc, s.created_at desc;
end;
$$;

create or replace function revoke_my_session(p_token text, p_session_id uuid)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_token_hash text := encode(digest(p_token, 'sha256'), 'hex');
  v_session sessions%rowtype;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;

  select * into v_session from sessions where id = p_session_id for update;
  if not found or v_session.user_id <> v_actor.user_id then
    raise exception 'session_not_found';
  end if;
  if v_session.token_hash = v_token_hash then
    -- เครื่องปัจจุบันให้ใช้ "ออกจากระบบ" ตามปกติ
    raise exception 'cannot_revoke_current_session';
  end if;

  update sessions set revoked_at = now() where id = p_session_id and revoked_at is null;

  insert into audit_logs (school_id, user_id, acted_role, action, entity_type, entity_id)
  values (v_actor.school_id, v_actor.user_id, v_actor.role, 'auth.revoke_session',
          'sessions', p_session_id::text);
end;
$$;

-- ── 3) นำเข้าผู้ใช้ด้วยรหัสชั่วคราวต่อคน ──────────────────────────────

-- รหัสชั่วคราว 10 ตัว จากตัวอักษรที่ไม่สับสน (ไม่มี 0/O/1/l/I)
create or replace function _generate_temp_password()
returns text
language plpgsql
as $$
declare
  v_alphabet text := 'ABCDEFGHJKMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789';
  v_bytes bytea := gen_random_bytes(10);
  v_out text := '';
  i int;
begin
  for i in 0..9 loop
    v_out := v_out || substr(v_alphabet, (get_byte(v_bytes, i) % length(v_alphabet)) + 1, 1);
  end loop;
  return v_out;
end;
$$;

create or replace function import_school_users_batch_for_school_admin(
  p_token text,
  p_role text,
  p_users jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_item jsonb;
  v_role_type public.role_type;
  v_email text;
  v_first_name text;
  v_last_name text;
  v_student_code text;
  v_building text;
  v_user_id uuid;
  v_temp_password text;
  v_row_index int := 0;
  v_inserted_count int := 0;
  v_skipped jsonb := '[]'::jsonb;
  v_credentials jsonb := '[]'::jsonb;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('school_admin', 'super_admin') then
    raise exception 'forbidden: school_admin or super_admin role required';
  end if;
  if v_actor.school_id is null then raise exception 'no_active_school'; end if;

  begin
    v_role_type := p_role::public.role_type;
  exception when others then
    raise exception 'invalid_role: %', p_role;
  end;
  if v_role_type = 'super_admin'::role_type and v_actor.role <> 'super_admin' then
    raise exception 'forbidden: cannot import super_admin';
  end if;

  for v_item in select * from jsonb_array_elements(p_users)
  loop
    v_row_index := v_row_index + 1;
    v_email := lower(trim(coalesce(v_item->>'email', '')));
    v_first_name := trim(coalesce(v_item->>'first_name', v_item->>'name', ''));
    v_last_name := trim(coalesce(v_item->>'last_name', ''));
    v_student_code := trim(coalesce(v_item->>'student_code', ''));
    v_building := trim(coalesce(v_item->>'building', ''));

    if v_email = '' then
      v_skipped := v_skipped || jsonb_build_object('row', v_row_index, 'reason', 'missing_required_field');
      continue;
    end if;
    if v_first_name = '' then
      v_first_name := split_part(v_email, '@', 1);
    end if;
    if v_last_name = '' then
      v_last_name := '-';
    end if;

    select id into v_user_id from users where email = v_email;
    if v_user_id is not null then
      -- เดิมข้ามเงียบ แอดมินไม่รู้ว่าแถวไหนไม่ถูกสร้าง
      v_skipped := v_skipped || jsonb_build_object('row', v_row_index, 'reason', 'duplicate_email');
      continue;
    end if;

    v_temp_password := _generate_temp_password();

    insert into users (
      school_id, email, first_name, last_name, password_hash, must_change_password,
      student_code, building, status
    ) values (
      v_actor.school_id, v_email, v_first_name, v_last_name,
      crypt(v_temp_password, gen_salt('bf')), true,
      nullif(v_student_code, ''), nullif(v_building, ''), 'active'::user_status
    ) returning id into v_user_id;

    insert into user_roles (user_id, school_id, role, granted_by)
    values (v_user_id, v_actor.school_id, v_role_type, v_actor.user_id)
    on conflict do nothing;

    v_inserted_count := v_inserted_count + 1;
    v_credentials := v_credentials || jsonb_build_object(
      'row', v_row_index, 'email', v_email, 'temp_password', v_temp_password
    );
  end loop;

  -- ไม่บันทึกรหัสชั่วคราวลง log — คืนให้ผู้เรียกครั้งเดียวเท่านั้น
  insert into audit_logs (school_id, user_id, acted_role, action, entity_type, entity_id, details)
  values (v_actor.school_id, v_actor.user_id, v_actor.role::role_type, 'users.batch_import',
          'users', v_actor.school_id::text,
          jsonb_build_object('role', p_role, 'count', v_inserted_count,
                             'skipped', jsonb_array_length(v_skipped)));

  return jsonb_build_object(
    'success', true,
    'inserted_count', v_inserted_count,
    'skipped', v_skipped,
    'credentials', v_credentials
  );
end;
$$;

revoke all on function change_my_password(text, text, text) from public;
revoke all on function list_my_sessions(text) from public;
revoke all on function revoke_my_session(text, uuid) from public;
revoke all on function _generate_temp_password() from public;
revoke all on function import_school_users_batch_for_school_admin(text, text, jsonb) from public;

grant execute on function change_my_password(text, text, text) to anon, authenticated, service_role;
grant execute on function list_my_sessions(text) to anon, authenticated, service_role;
grant execute on function revoke_my_session(text, uuid) to anon, authenticated, service_role;
grant execute on function import_school_users_batch_for_school_admin(text, text, jsonb) to anon, authenticated, service_role;
