-- แก้ 2 บั๊กใน accept_staff_invitation ที่เจอตอนรัน pgTAP จริงครั้งแรก:
-- (1) "email" ชนกันระหว่าง users.email กับ OUT parameter ชื่อ email ของ
--     RETURNS TABLE ทำให้ query error "column reference \"email\" is
--     ambiguous" — same root cause as
--     20260715020000_fix_auth_sign_in_ambiguous_email.sql, qualify เป็น
--     users.email ให้ชัดเจน
-- (2) p_first_name/p_last_name เป็น text แต่ RETURNS TABLE ประกาศเป็น
--     varchar ทำให้ RETURN QUERY error "structure of query does not
--     match function result type" — cast เป็น varchar ตรงๆ

create or replace function accept_staff_invitation(
  p_token text,
  p_first_name text,
  p_last_name text,
  p_password text
)
returns table (
  session_token text,
  user_id uuid,
  email varchar,
  first_name varchar,
  last_name varchar,
  active_role role_type,
  active_school_id uuid
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_invite_token_hash text;
  v_invitation user_invitations%rowtype;
  v_user_id uuid;
  v_session_token text;
  v_session_token_hash text;
  v_session_id uuid;
begin
  v_invite_token_hash := encode(digest(p_token, 'sha256'), 'hex');

  select * into v_invitation from user_invitations
    where token_hash = v_invite_token_hash
      and status = 'pending'
      and expires_at > now();

  if not found then
    raise exception 'invalid_or_expired_invitation';
  end if;

  if exists (select 1 from users where users.email = v_invitation.email and users.school_id = v_invitation.school_id) then
    raise exception 'user_already_exists';
  end if;

  insert into users (school_id, email, password_hash, first_name, last_name, created_by)
  values (v_invitation.school_id, v_invitation.email, crypt(p_password, gen_salt('bf')), p_first_name, p_last_name, v_invitation.invited_by)
  returning id into v_user_id;

  insert into user_roles (user_id, role, school_id, granted_by)
  values (v_user_id, v_invitation.initial_role, v_invitation.school_id, v_invitation.invited_by);

  update user_invitations
    set status = 'accepted', accepted_by = v_user_id, accepted_at = now()
    where id = v_invitation.id;

  v_session_token := encode(gen_random_bytes(32), 'hex');
  v_session_token_hash := encode(digest(v_session_token, 'sha256'), 'hex');

  insert into sessions (user_id, active_role, active_school_id, token_hash, expires_at)
  values (v_user_id, v_invitation.initial_role, v_invitation.school_id, v_session_token_hash, now() + interval '7 days')
  returning id into v_session_id;

  insert into audit_logs (school_id, user_id, acted_role, action, entity_type, entity_id)
  values (v_invitation.school_id, v_user_id, v_invitation.initial_role, 'auth.accept_invitation', 'sessions', v_session_id::text);

  return query
    select v_session_token, v_user_id, v_invitation.email, p_first_name::varchar, p_last_name::varchar,
           v_invitation.initial_role, v_invitation.school_id;
end;
$$;
