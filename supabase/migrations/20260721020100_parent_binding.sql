-- =====================================================================
-- Parent binding (PDPA gate 2, part 1): 7-day, one-time codes with a
-- two-slot quota, redeemed only after email OTP verification.
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
  v_code text := '';
  v_alphabet constant text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  v_random bytea;
  v_index integer;
  v_active_slots integer;
  v_expires_at timestamptz;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then
    raise exception 'invalid_session';
  end if;

  if v_actor.role not in ('school_admin', 'teacher', 'super_admin') then
    raise exception 'forbidden';
  end if;

  select * into v_student
  from users
  where student_code = trim(p_student_code)
    and status = 'active'
    and (v_actor.role = 'super_admin' or school_id = v_actor.school_id)
  for update;

  if not found then
    raise exception 'student_not_found';
  end if;

  if not exists (
    select 1 from user_roles
    where user_id = v_student.id and role = 'student'
  ) then
    raise exception 'not_a_student';
  end if;

  if v_actor.role = 'teacher' and not exists (
    select 1
    from course_teachers ct
    join course_students cs on cs.course_id = ct.course_id
    where ct.teacher_id = v_actor.user_id
      and cs.student_id = v_student.id
  ) then
    raise exception 'forbidden';
  end if;

  update parent_binding_codes
  set status = 'expired'
  where student_id = v_student.id
    and status = 'issued'
    and expires_at <= now();

  select
    (select count(*)
       from parent_links
       where student_id = v_student.id
         and status in ('pending', 'pending_second_review', 'approved'))
    +
    (select count(*)
       from parent_binding_codes
       where student_id = v_student.id
         and status = 'issued'
         and expires_at > now())
  into v_active_slots;

  if v_active_slots >= 2 then
    raise exception 'parent_quota_reached';
  end if;

  v_random := gen_random_bytes(12);
  for v_index in 0..11 loop
    v_code := v_code || substr(
      v_alphabet,
      (get_byte(v_random, v_index) % length(v_alphabet)) + 1,
      1
    );
  end loop;

  v_expires_at := now() + interval '7 days';

  insert into parent_binding_codes (
    school_id,
    student_id,
    code_hash,
    code_hint,
    expires_at,
    issued_by
  )
  values (
    v_student.school_id,
    v_student.id,
    encode(digest(v_code, 'sha256'), 'hex'),
    left(v_code, 4) || '********',
    v_expires_at,
    v_actor.user_id
  );

  insert into audit_logs (
    school_id, user_id, acted_role, action, entity_type, entity_id, details
  )
  values (
    v_student.school_id,
    v_actor.user_id,
    v_actor.role,
    'parent.issue_binding_code',
    'users',
    v_student.id::text,
    jsonb_build_object('expires_at', v_expires_at)
  );

  return query
  select v_code, v_expires_at, v_student.first_name, v_student.last_name;
end;
$$;

revoke all on function create_parent_binding_code(text, text) from public;
grant execute on function create_parent_binding_code(text, text) to anon, authenticated;

-- Opaque token ties the email OTP to one Binding Code without returning a
-- student id or any student details to the public caller.
alter table otp_codes
  add column if not exists verification_token_hash varchar;

create unique index if not exists idx_otp_codes_verification_token_hash
  on otp_codes (verification_token_hash)
  where verification_token_hash is not null;

create or replace function request_parent_binding_otp(
  p_code text,
  p_email text
)
returns table (
  otp_code text,
  verification_token text
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_code_hash text;
  v_binding parent_binding_codes%rowtype;
  v_email text;
  v_last_sent timestamptz;
  v_daily_count integer;
  v_otp_code text;
  v_verification_token text;
begin
  v_code_hash := encode(digest(upper(trim(p_code)), 'sha256'), 'hex');
  v_email := lower(trim(p_email));

  if v_email !~* '^[A-Z0-9._%+\-]+@[A-Z0-9.\-]+\.[A-Z]{2,}$' then
    return;
  end if;

  select * into v_binding
  from parent_binding_codes
  where code_hash = v_code_hash
    and status = 'issued'
    and expires_at > now();

  if not found then
    return;
  end if;

  select max(last_sent_at), count(*) filter (
    where last_sent_at >= now() - interval '24 hours'
  )
  into v_last_sent, v_daily_count
  from otp_codes
  where purpose = 'parent_email_verify'
    and (
      parent_binding_code_id = v_binding.id
      or sent_to_email = v_email
    );

  if v_last_sent is not null
     and v_last_sent > now() - interval '60 seconds' then
    raise exception 'rate_limited';
  end if;

  if v_daily_count >= 10 then
    raise exception 'daily_rate_limited';
  end if;

  v_otp_code := lpad(
    ((('x' || encode(gen_random_bytes(4), 'hex'))::bit(32)::bigint % 1000000))::text,
    6,
    '0'
  );
  v_verification_token := 'pv_' || encode(gen_random_bytes(32), 'hex');

  insert into otp_codes (
    parent_binding_code_id,
    purpose,
    code_hash,
    sent_to_email,
    verification_token_hash,
    last_sent_at,
    expires_at
  )
  values (
    v_binding.id,
    'parent_email_verify',
    encode(digest(v_otp_code, 'sha256'), 'hex'),
    v_email,
    encode(digest(v_verification_token, 'sha256'), 'hex'),
    now(),
    now() + interval '10 minutes'
  );

  return query select v_otp_code, v_verification_token;
end;
$$;

revoke all on function request_parent_binding_otp(text, text)
  from public, anon, authenticated;
grant execute on function request_parent_binding_otp(text, text) to service_role;

create or replace function confirm_parent_binding(
  p_verification_token text,
  p_otp_code text,
  p_relationship text,
  p_first_name text,
  p_last_name text,
  p_password text
)
returns table (
  parent_link_id uuid,
  status binding_status
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_otp otp_codes%rowtype;
  v_binding parent_binding_codes%rowtype;
  v_user users%rowtype;
  v_link_id uuid;
  v_active_links integer;
begin
  select * into v_otp
  from otp_codes
  where verification_token_hash = encode(
      digest(trim(p_verification_token), 'sha256'),
      'hex'
    )
    and purpose = 'parent_email_verify'
    and used_at is null
  order by last_sent_at desc
  limit 1
  for update;

  if not found or v_otp.expires_at <= now() then
    return;
  end if;

  if v_otp.locked_until is not null and v_otp.locked_until > now() then
    raise exception 'too_many_attempts';
  end if;

  if v_otp.code_hash <> encode(digest(trim(p_otp_code), 'sha256'), 'hex') then
    update otp_codes
    set attempt_count = attempt_count + 1,
        locked_until = case
          when attempt_count + 1 >= 5 then now() + interval '10 minutes'
          else locked_until
        end
    where id = v_otp.id;
    return;
  end if;

  select pb.* into v_binding
  from parent_binding_codes pb
  where pb.id = v_otp.parent_binding_code_id
    and pb.status = 'issued'
    and pb.expires_at > now()
  for update;

  if not found then
    raise exception 'invalid_or_expired_verification';
  end if;

  select count(*) into v_active_links
  from parent_links pl
  where pl.student_id = v_binding.student_id
    and pl.status in ('pending', 'pending_second_review', 'approved');

  if v_active_links >= 2 then
    raise exception 'parent_quota_reached';
  end if;

  select * into v_user from users where email = v_otp.sent_to_email;

  if not found then
    insert into users (
      school_id, email, password_hash, first_name, last_name, created_by
    )
    values (
      v_binding.school_id,
      v_otp.sent_to_email,
      crypt(p_password, gen_salt('bf')),
      trim(p_first_name),
      trim(p_last_name),
      v_binding.issued_by
    )
    returning * into v_user;
  elsif v_user.password_hash is null
     or v_user.password_hash <> crypt(p_password, v_user.password_hash) then
    raise exception 'invalid_credentials';
  end if;

  if exists (
    select 1 from parent_links pl
    where pl.student_id = v_binding.student_id
      and pl.parent_id = v_user.id
  ) then
    raise exception 'already_linked';
  end if;

  insert into parent_links (
    student_id, parent_id, relationship, binding_code_id, status
  )
  values (
    v_binding.student_id,
    v_user.id,
    trim(p_relationship),
    v_binding.id,
    'pending'
  )
  returning id into v_link_id;

  update parent_binding_codes
  set status = 'redeemed', redeemed_by = v_user.id, redeemed_at = now()
  where id = v_binding.id;

  update otp_codes set used_at = now() where id = v_otp.id;

  update otp_codes set used_at = now()
  where parent_binding_code_id = v_binding.id
    and id <> v_otp.id
    and used_at is null;

  insert into audit_logs (
    school_id, user_id, acted_role, action, entity_type, entity_id
  )
  values (
    v_binding.school_id,
    v_user.id,
    'parent',
    'parent.redeem_binding_code',
    'parent_links',
    v_link_id::text
  );

  return query select v_link_id, 'pending'::binding_status;
end;
$$;

revoke all on function confirm_parent_binding(text, text, text, text, text, text)
  from public;
grant execute on function confirm_parent_binding(text, text, text, text, text, text)
  to anon, authenticated;

-- Disable the legacy flow that created a parent account without email OTP.
revoke all on function redeem_parent_binding_code(text, text, text, text, text, text)
  from public, anon, authenticated;
