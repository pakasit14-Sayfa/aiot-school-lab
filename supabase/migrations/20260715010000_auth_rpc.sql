-- =====================================================================
-- Custom auth RPC functions
--
-- Decision Log ล็อกว่าไม่มี self-signup และ users.password_hash เก็บเอง
-- (ไม่ใช้ Supabase Auth/GoTrue) จึงต้องเขียน sign-in/sign-out/session
-- validation เองทั้งหมดผ่าน SECURITY DEFINER function — client (anon key)
-- ไม่มีสิทธิ์ SELECT ตาราง users/sessions โดยตรง เข้าถึงได้เฉพาะผ่าน
-- ฟังก์ชันเหล่านี้เท่านั้น เพื่อไม่ให้ password_hash/token_hash รั่วไหล
-- =====================================================================

create or replace function auth_sign_in(
  p_email text,
  p_password text,
  p_device_info text default null,
  p_ip_address text default null
)
returns table (
  session_token text,
  user_id uuid,
  email varchar,
  first_name varchar,
  last_name varchar,
  must_change_password bool,
  active_role role_type,
  active_school_id uuid
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_user users%rowtype;
  v_role user_roles%rowtype;
  v_token text;
  v_token_hash text;
  v_session_id uuid;
begin
  select * into v_user from users where email = lower(p_email) and status = 'active';

  if not found or v_user.password_hash is null
     or v_user.password_hash <> crypt(p_password, v_user.password_hash) then
    raise exception 'invalid_credentials';
  end if;

  select * into v_role from user_roles
    where user_roles.user_id = v_user.id
    order by granted_at asc
    limit 1;

  if not found then
    raise exception 'no_role_assigned';
  end if;

  v_token := encode(gen_random_bytes(32), 'hex');
  v_token_hash := encode(digest(v_token, 'sha256'), 'hex');

  insert into sessions (user_id, active_role, active_school_id, token_hash, device_info, ip_address, expires_at)
  values (v_user.id, v_role.role, v_role.school_id, v_token_hash, p_device_info, p_ip_address, now() + interval '7 days')
  returning id into v_session_id;

  insert into audit_logs (school_id, user_id, acted_role, action, entity_type, entity_id)
  values (v_role.school_id, v_user.id, v_role.role, 'auth.sign_in', 'sessions', v_session_id::text);

  return query
    select v_token, v_user.id, v_user.email, v_user.first_name, v_user.last_name,
           v_user.must_change_password, v_role.role, v_role.school_id;
end;
$$;

create or replace function auth_validate_session(p_token text)
returns table (
  user_id uuid,
  email varchar,
  first_name varchar,
  last_name varchar,
  must_change_password bool,
  active_role role_type,
  active_school_id uuid
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_token_hash text;
  v_session sessions%rowtype;
  v_user users%rowtype;
begin
  v_token_hash := encode(digest(p_token, 'sha256'), 'hex');

  select * into v_session from sessions
    where token_hash = v_token_hash
      and revoked_at is null
      and expires_at > now();

  if not found then
    return;
  end if;

  select * into v_user from users where id = v_session.user_id and status = 'active';

  if not found then
    return;
  end if;

  return query
    select v_user.id, v_user.email, v_user.first_name, v_user.last_name,
           v_user.must_change_password, v_session.active_role, v_session.active_school_id;
end;
$$;

create or replace function auth_sign_out(p_token text)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_token_hash text;
begin
  v_token_hash := encode(digest(p_token, 'sha256'), 'hex');
  update sessions set revoked_at = now()
    where token_hash = v_token_hash and revoked_at is null;
end;
$$;

grant execute on function auth_sign_in(text, text, text, text) to anon, authenticated;
grant execute on function auth_validate_session(text) to anon, authenticated;
grant execute on function auth_sign_out(text) to anon, authenticated;

-- =====================================================================
-- Bootstrap super_admin — ตาม comment ใน db-schema-mvp-v1.dbml:
-- "ไม่มี self-signup: บัญชีทั่วไปต้องมี users.created_by; null ได้เฉพาะ
-- bootstrap super_admin คนแรกจาก migration"
-- เปลี่ยนรหัสผ่านทันทีหลัง deploy จริง — เก็บไว้แค่สำหรับ MVP dev/testing
-- =====================================================================

set search_path = public, extensions;

do $$
declare
  v_super_admin_id uuid;
begin
  if not exists (select 1 from users where email = 'admin@aiot-school-lab.local') then
    insert into users (email, password_hash, first_name, last_name, created_by)
    values (
      'admin@aiot-school-lab.local',
      crypt('ChangeMe123!', gen_salt('bf')),
      'Super',
      'Admin',
      null
    )
    returning id into v_super_admin_id;

    insert into user_roles (user_id, role, school_id, granted_by)
    values (v_super_admin_id, 'super_admin', null, v_super_admin_id);
  end if;
end $$;
