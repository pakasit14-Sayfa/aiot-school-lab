-- แก้บั๊ก: "email" ชนกันระหว่าง users.email กับ OUT parameter ชื่อ email
-- ของ RETURNS TABLE ใน auth_sign_in ทำให้ query error "column reference
-- \"email\" is ambiguous" — qualify เป็น users.email ให้ชัดเจน

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
  select * into v_user from users where users.email = lower(p_email) and users.status = 'active';

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
