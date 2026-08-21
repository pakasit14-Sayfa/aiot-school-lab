-- =====================================================================
-- AUTH-5 QR Terminal Pairing Refinements (from vault spec review)
-- 1. Actor check: Restricted to 'student' only (teachers/parents/admins cannot claim terminal as student)
-- 2. Anti-relay/phishing (BR3): Add peek_terminal_pairing_session for pre-confirmation context
-- 3. Auto-logout/No remember-me (BR4): Lab terminal session expiry set to 4 hours instead of 30 days
-- =====================================================================

-- 1. Peek terminal pairing session (Read-only pre-confirmation context)
create or replace function peek_terminal_pairing_session(p_pairing_code text)
returns table (
  is_valid boolean,
  terminal_name text,
  created_at timestamptz,
  expires_at timestamptz
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_session terminal_pairing_sessions%rowtype;
begin
  select * into v_session from terminal_pairing_sessions t
  where t.pairing_code = trim(p_pairing_code)
    and t.status = 'pending'
    and t.expires_at > now();

  if not found then
    return query select false, ''::text, null::timestamptz, null::timestamptz;
    return;
  end if;

  return query select true, coalesce(v_session.terminal_name, 'เครื่องแล็บ'), v_session.created_at, v_session.expires_at;
end;
$$;

-- 2. Claim terminal pairing session with student role check and 4-hour expiry
create or replace function claim_terminal_pairing_session(
  p_token text,
  p_pairing_code text
)
returns table (
  success boolean,
  student_name text,
  message text
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_user users%rowtype;
  v_session terminal_pairing_sessions%rowtype;
  v_new_token text;
  v_new_token_hash text;
  v_full_name text;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;

  -- AUTH-5: Actor must be student only
  if v_actor.role <> 'student' then
    raise exception 'forbidden';
  end if;

  select * into v_user from users where id = v_actor.user_id;
  if not found then raise exception 'user_not_found'; end if;

  v_full_name := trim(coalesce(v_user.first_name, '') || ' ' || coalesce(v_user.last_name, ''));
  if v_full_name = '' then v_full_name := v_user.email; end if;

  select * into v_session from terminal_pairing_sessions t
  where t.pairing_code = trim(p_pairing_code)
    and t.status = 'pending'
    and t.expires_at > now();

  if not found then
    return query select false, ''::text, 'รหัส QR นี้หมดอายุหรือไม่ถูกต้อง'::text;
    return;
  end if;

  -- BR4: Lab terminal session has 4-hour expiry (class session), no 30-day remember-me
  v_new_token := 'tkn_' || encode(gen_random_bytes(24), 'hex');
  v_new_token_hash := encode(digest(v_new_token, 'sha256'), 'hex');

  insert into sessions (
    user_id,
    active_role,
    active_school_id,
    token_hash,
    device_info,
    expires_at
  )
  values (
    v_actor.user_id,
    v_actor.role,
    v_actor.school_id,
    v_new_token_hash,
    coalesce(v_session.terminal_name, 'Lab Kiosk Terminal'),
    now() + interval '4 hours'
  );

  update terminal_pairing_sessions
  set status = 'claimed',
      session_token = v_new_token,
      claimed_by_user_id = v_actor.user_id
  where id = v_session.id;

  return query select true, v_full_name, 'เข้าสู่ระบบบนเครื่องแล็บสำเร็จ'::text;
end;
$$;

grant execute on function peek_terminal_pairing_session(text) to anon, authenticated;
grant execute on function claim_terminal_pairing_session(text, text) to authenticated;
