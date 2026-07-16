-- =====================================================================
-- Staff invitation RPCs (school_admin/super_admin invites a teacher/
-- staff account, invitee accepts with the token to create their own
-- account) — this is how accounts get created now that public
-- self-signup is gone. Parent binding via parent_binding_codes is a
-- separate flow, not covered here.
--
-- No deep-linking/email-link infra exists yet, so the invitation
-- token is handed to the admin to relay manually (copy/paste via
-- LINE, email, etc.) — same shape as the password-reset OTP: the
-- invitee pastes the token into the app themselves rather than
-- clicking a link.
--
-- get_session_actor is defined in 20260716000000_user_admin_rpc.sql.
-- =====================================================================

create or replace function create_staff_invitation(
  p_token text,
  p_email text,
  p_role role_type,
  p_school_id uuid default null
)
returns table (
  invitation_token text,
  expires_at timestamptz
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_school_id uuid;
  v_email text;
  v_invite_token text;
  v_invite_token_hash text;
  v_expires_at timestamptz;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then
    raise exception 'invalid_session';
  end if;

  if v_actor.role not in ('school_admin', 'super_admin') then
    raise exception 'forbidden';
  end if;

  if p_role = 'super_admin' and v_actor.role <> 'super_admin' then
    raise exception 'forbidden';
  end if;

  if v_actor.role = 'school_admin' then
    v_school_id := v_actor.school_id;
  else
    if p_school_id is null then
      raise exception 'school_id_required';
    end if;
    v_school_id := p_school_id;
  end if;

  v_email := lower(trim(p_email));

  if exists (select 1 from users where email = v_email and school_id = v_school_id) then
    raise exception 'user_already_exists';
  end if;

  update user_invitations
    set status = 'revoked', revoked_at = now()
    where email = v_email and school_id = v_school_id and status = 'pending';

  v_invite_token := encode(gen_random_bytes(32), 'hex');
  v_invite_token_hash := encode(digest(v_invite_token, 'sha256'), 'hex');
  v_expires_at := now() + interval '7 days';

  insert into user_invitations (school_id, email, initial_role, scope, token_hash, expires_at, invited_by)
  values (v_school_id, v_email, p_role, '{}'::jsonb, v_invite_token_hash, v_expires_at, v_actor.user_id);

  insert into audit_logs (school_id, user_id, acted_role, action, entity_type, entity_id, details)
  values (v_school_id, v_actor.user_id, v_actor.role, 'user.invite', 'user_invitations', v_email,
          jsonb_build_object('role', p_role));

  return query select v_invite_token, v_expires_at;
end;
$$;

create or replace function list_school_invitations(
  p_token text,
  p_school_id uuid default null
)
returns table (
  id uuid,
  email varchar,
  initial_role role_type,
  status invitation_status,
  expires_at timestamptz,
  created_at timestamptz
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

  if v_actor.role not in ('school_admin', 'super_admin') then
    raise exception 'forbidden';
  end if;

  if v_actor.role = 'school_admin' then
    v_school_id := v_actor.school_id;
  else
    if p_school_id is null then
      raise exception 'school_id_required';
    end if;
    v_school_id := p_school_id;
  end if;

  return query
    select ui.id, ui.email, ui.initial_role, ui.status, ui.expires_at, ui.created_at
    from user_invitations ui
    where ui.school_id = v_school_id
    order by ui.created_at desc;
end;
$$;

create or replace function revoke_staff_invitation(
  p_token text,
  p_invitation_id uuid
)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_invitation user_invitations%rowtype;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then
    raise exception 'invalid_session';
  end if;

  if v_actor.role not in ('school_admin', 'super_admin') then
    raise exception 'forbidden';
  end if;

  select * into v_invitation from user_invitations where id = p_invitation_id;
  if not found then
    raise exception 'invitation_not_found';
  end if;

  if v_actor.role = 'school_admin' and v_actor.school_id is distinct from v_invitation.school_id then
    raise exception 'forbidden';
  end if;

  update user_invitations set status = 'revoked', revoked_at = now()
    where id = p_invitation_id and status = 'pending';

  insert into audit_logs (school_id, user_id, acted_role, action, entity_type, entity_id)
  values (v_invitation.school_id, v_actor.user_id, v_actor.role, 'user.revoke_invitation', 'user_invitations', p_invitation_id::text);
end;
$$;

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

  if exists (select 1 from users where email = v_invitation.email and school_id = v_invitation.school_id) then
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
    select v_session_token, v_user_id, v_invitation.email, p_first_name, p_last_name,
           v_invitation.initial_role, v_invitation.school_id;
end;
$$;

grant execute on function create_staff_invitation(text, text, role_type, uuid) to anon, authenticated;
grant execute on function list_school_invitations(text, uuid) to anon, authenticated;
grant execute on function revoke_staff_invitation(text, uuid) to anon, authenticated;
grant execute on function accept_staff_invitation(text, text, text, text) to anon, authenticated;
