-- =====================================================================
-- Fix: create_parent_binding_code(p_token, p_student_code) has always
-- raised "column reference expires_at is ambiguous" at runtime (PL/pgSQL
-- treats the function's own `expires_at` OUT column as an implicit
-- variable, clashing with parent_binding_codes.expires_at in two
-- unqualified WHERE clauses). Never caught before because this code
-- path had apparently never actually been exercised in production.
-- Same body as 20260721020100_parent_binding.sql, only the two
-- ambiguous references now table-qualified.
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
    and parent_binding_codes.expires_at <= now();

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
         and parent_binding_codes.expires_at > now())
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
