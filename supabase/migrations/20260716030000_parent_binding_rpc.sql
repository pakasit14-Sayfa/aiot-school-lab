-- =====================================================================
-- Parent binding flow — MVP scope only.
--
-- Full schema for this (parent_links/consent_policies/consents/
-- consent_events) supports a two-step Conflict-of-Interest review and
-- PDPA consent capture with policy version/document hash/evidence —
-- see comment on parent_links in the initial schema. Those rules live
-- in the vault's Decision Log, which isn't available on this machine
-- (see project memory), so this migration deliberately does NOT
-- implement them:
--   - coi_conflict is left at its schema default (false) — never set
--   - pending_second_review is never used, only pending/approved/rejected
--   - consent_policies/consents/consent_events are untouched — no
--     consent is captured, so approving a link here is NOT a PDPA
--     consent record. Treat as a known compliance gap until the
--     vault's actual consent rules are available.
--
-- Flow: staff issues a binding code for a student (looked up by
-- student_code, since there's no working "list students" RPC yet) ->
-- parent redeems it (creates their account if they don't have one
-- yet, since binding codes don't carry an email at issuance time) ->
-- parent_links row starts 'pending' -> staff approves/rejects
-- (single step, no COI routing).
-- =====================================================================

create or replace function create_parent_binding_code(
  p_token text,
  p_student_code text
)
returns table (
  binding_code text,
  expires_at timestamptz,
  student_first_name varchar,
  student_last_name varchar
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_student users%rowtype;
  v_code text;
  v_code_hash text;
  v_expires_at timestamptz;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then
    raise exception 'invalid_session';
  end if;

  if v_actor.role not in ('school_admin', 'teacher', 'super_admin') then
    raise exception 'forbidden';
  end if;

  select * into v_student from users
    where student_code = p_student_code
      and status = 'active'
      and (v_actor.role = 'super_admin' or school_id = v_actor.school_id);

  if not found then
    raise exception 'student_not_found';
  end if;

  if not exists (select 1 from user_roles where user_id = v_student.id and role = 'student') then
    raise exception 'not_a_student';
  end if;

  update parent_binding_codes
    set status = 'revoked', revoked_at = now(), revoked_by = v_actor.user_id, revoke_reason = 'superseded_by_new_code'
    where student_id = v_student.id and status = 'issued';

  v_code := upper(encode(gen_random_bytes(5), 'hex'));
  v_code_hash := encode(digest(v_code, 'sha256'), 'hex');
  v_expires_at := now() + interval '14 days';

  insert into parent_binding_codes (school_id, student_id, code_hash, code_hint, expires_at, issued_by)
  values (v_student.school_id, v_student.id, v_code_hash, left(v_code, 4) || '******', v_expires_at, v_actor.user_id);

  insert into audit_logs (school_id, user_id, acted_role, action, entity_type, entity_id)
  values (v_student.school_id, v_actor.user_id, v_actor.role, 'parent.issue_binding_code', 'users', v_student.id::text);

  return query select v_code, v_expires_at, v_student.first_name, v_student.last_name;
end;
$$;

create or replace function list_binding_codes(
  p_token text,
  p_school_id uuid default null
)
returns table (
  id uuid,
  student_id uuid,
  student_first_name varchar,
  student_last_name varchar,
  code_hint varchar,
  status binding_code_status,
  expires_at timestamptz,
  issued_at timestamptz
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
    select pbc.id, pbc.student_id, u.first_name, u.last_name, pbc.code_hint, pbc.status, pbc.expires_at, pbc.issued_at
    from parent_binding_codes pbc
    join users u on u.id = pbc.student_id
    where pbc.school_id = v_school_id
    order by pbc.issued_at desc;
end;
$$;

create or replace function revoke_binding_code(
  p_token text,
  p_code_id uuid
)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_code parent_binding_codes%rowtype;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then
    raise exception 'invalid_session';
  end if;

  if v_actor.role not in ('school_admin', 'teacher', 'super_admin') then
    raise exception 'forbidden';
  end if;

  select * into v_code from parent_binding_codes where id = p_code_id;
  if not found then
    raise exception 'code_not_found';
  end if;

  if v_actor.role <> 'super_admin' and v_actor.school_id is distinct from v_code.school_id then
    raise exception 'forbidden';
  end if;

  update parent_binding_codes
    set status = 'revoked', revoked_at = now(), revoked_by = v_actor.user_id, revoke_reason = 'revoked_by_staff'
    where id = p_code_id and status = 'issued';

  insert into audit_logs (school_id, user_id, acted_role, action, entity_type, entity_id)
  values (v_code.school_id, v_actor.user_id, v_actor.role, 'parent.revoke_binding_code', 'parent_binding_codes', p_code_id::text);
end;
$$;

create or replace function redeem_parent_binding_code(
  p_code text,
  p_relationship text,
  p_email text,
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
  v_code_hash text;
  v_binding parent_binding_codes%rowtype;
  v_email text;
  v_user users%rowtype;
  v_link_id uuid;
  v_session_token text;
  v_session_token_hash text;
  v_session_id uuid;
begin
  v_code_hash := encode(digest(upper(trim(p_code)), 'sha256'), 'hex');

  select * into v_binding from parent_binding_codes
    where code_hash = v_code_hash and status = 'issued' and expires_at > now();

  if not found then
    raise exception 'invalid_or_expired_code';
  end if;

  v_email := lower(trim(p_email));

  select * into v_user from users where email = v_email;

  if not found then
    insert into users (school_id, email, password_hash, first_name, last_name, created_by)
    values (v_binding.school_id, v_email, crypt(p_password, gen_salt('bf')), p_first_name, p_last_name, v_binding.issued_by)
    returning * into v_user;
  else
    -- account already exists (e.g. parent with a kid at another school too) —
    -- verify the password so a binding code + guessed email can't hijack it
    if v_user.password_hash is null or v_user.password_hash <> crypt(p_password, v_user.password_hash) then
      raise exception 'invalid_credentials';
    end if;
  end if;

  if not exists (select 1 from user_roles where user_id = v_user.id and role = 'parent' and school_id = v_binding.school_id) then
    insert into user_roles (user_id, role, school_id, granted_by)
    values (v_user.id, 'parent', v_binding.school_id, v_binding.issued_by);
  end if;

  if exists (select 1 from parent_links where student_id = v_binding.student_id and parent_id = v_user.id) then
    raise exception 'already_linked';
  end if;

  insert into parent_links (student_id, parent_id, relationship, binding_code_id, status)
  values (v_binding.student_id, v_user.id, p_relationship, v_binding.id, 'pending')
  returning id into v_link_id;

  update parent_binding_codes
    set status = 'redeemed', redeemed_by = v_user.id, redeemed_at = now()
    where id = v_binding.id;

  insert into audit_logs (school_id, user_id, acted_role, action, entity_type, entity_id)
  values (v_binding.school_id, v_user.id, 'parent', 'parent.redeem_binding_code', 'parent_links', v_link_id::text);

  v_session_token := encode(gen_random_bytes(32), 'hex');
  v_session_token_hash := encode(digest(v_session_token, 'sha256'), 'hex');

  insert into sessions (user_id, active_role, active_school_id, token_hash, expires_at)
  values (v_user.id, 'parent', v_binding.school_id, v_session_token_hash, now() + interval '7 days')
  returning id into v_session_id;

  return query
    select v_session_token, v_user.id, v_user.email, v_user.first_name, v_user.last_name,
           'parent'::role_type, v_binding.school_id;
end;
$$;

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
    order by pl.requested_at desc;
end;
$$;

create or replace function approve_parent_link(
  p_token text,
  p_parent_link_id uuid
)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_link parent_links%rowtype;
  v_school_id uuid;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then
    raise exception 'invalid_session';
  end if;

  if v_actor.role not in ('school_admin', 'teacher', 'super_admin') then
    raise exception 'forbidden';
  end if;

  select * into v_link from parent_links where id = p_parent_link_id;
  if not found then
    raise exception 'link_not_found';
  end if;

  if v_link.status <> 'pending' then
    raise exception 'link_not_pending';
  end if;

  select school_id into v_school_id from users where id = v_link.student_id;

  if v_actor.role <> 'super_admin' and v_actor.school_id is distinct from v_school_id then
    raise exception 'forbidden';
  end if;

  update parent_links
    set status = 'approved',
        approved_by = v_actor.user_id,
        approved_at = now(),
        first_reviewed_by = coalesce(first_reviewed_by, v_actor.user_id),
        first_reviewed_at = coalesce(first_reviewed_at, now())
    where id = p_parent_link_id;

  insert into audit_logs (school_id, user_id, acted_role, action, entity_type, entity_id)
  values (v_school_id, v_actor.user_id, v_actor.role, 'parent_link.approve', 'parent_links', p_parent_link_id::text);
end;
$$;

create or replace function reject_parent_link(
  p_token text,
  p_parent_link_id uuid,
  p_reason text default null
)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_link parent_links%rowtype;
  v_school_id uuid;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then
    raise exception 'invalid_session';
  end if;

  if v_actor.role not in ('school_admin', 'teacher', 'super_admin') then
    raise exception 'forbidden';
  end if;

  select * into v_link from parent_links where id = p_parent_link_id;
  if not found then
    raise exception 'link_not_found';
  end if;

  if v_link.status <> 'pending' then
    raise exception 'link_not_pending';
  end if;

  select school_id into v_school_id from users where id = v_link.student_id;

  if v_actor.role <> 'super_admin' and v_actor.school_id is distinct from v_school_id then
    raise exception 'forbidden';
  end if;

  update parent_links
    set status = 'rejected',
        rejected_by = v_actor.user_id,
        rejected_at = now(),
        rejection_reason = p_reason,
        first_reviewed_by = coalesce(first_reviewed_by, v_actor.user_id),
        first_reviewed_at = coalesce(first_reviewed_at, now())
    where id = p_parent_link_id;

  insert into audit_logs (school_id, user_id, acted_role, action, entity_type, entity_id, details)
  values (v_school_id, v_actor.user_id, v_actor.role, 'parent_link.reject', 'parent_links', p_parent_link_id::text,
          jsonb_build_object('reason', p_reason));
end;
$$;

grant execute on function create_parent_binding_code(text, text) to anon, authenticated;
grant execute on function list_binding_codes(text, uuid) to anon, authenticated;
grant execute on function revoke_binding_code(text, uuid) to anon, authenticated;
grant execute on function redeem_parent_binding_code(text, text, text, text, text, text) to anon, authenticated;
grant execute on function list_parent_links(text, binding_status, uuid) to anon, authenticated;
grant execute on function approve_parent_link(text, uuid) to anon, authenticated;
grant execute on function reject_parent_link(text, uuid, text) to anon, authenticated;
