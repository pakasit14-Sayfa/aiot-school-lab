-- Harden the deprecated parent binding function after an ACL regression.
--
-- The supported product flow is:
-- request_parent_binding_otp -> confirm_parent_binding.
-- `redeem_parent_binding_code` is a legacy no-OTP implementation that the
-- 20260721020100 migration revoked, but 20260826000000 accidentally granted it
-- back to anon/authenticated while normalizing role grants. The app does not
-- call this legacy function, but fresh resets exposed it through PostgREST.
--
-- This migration qualifies two ambiguous legacy lookups (users.email and
-- user_roles.user_id) and, critically, revokes the legacy function again.
-- No grant is added. The active OTP flow is unchanged.
create or replace function public.redeem_parent_binding_code(
  p_code text,
  p_relationship text,
  p_email text,
  p_first_name text,
  p_last_name text,
  p_password text
)
returns table(
  session_token text,
  user_id uuid,
  email character varying,
  first_name character varying,
  last_name character varying,
  active_role role_type,
  active_school_id uuid
)
language plpgsql
security definer
set search_path to 'public', 'extensions'
as $function$
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

  select * into v_user from users u where u.email = v_email;

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

  if not exists (select 1 from user_roles ur where ur.user_id = v_user.id and ur.role = 'parent' and ur.school_id = v_binding.school_id) then
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
$function$;

-- Keep this deprecated flow disabled and avoid any accidental exposure.
revoke all on function public.redeem_parent_binding_code(text, text, text, text, text, text)
  from public, anon, authenticated;
