-- =====================================================================
-- Real course join codes (CLS-1). teacher_courses_page.dart's
-- TeacherCourseModel.joinCode was `'${code.toUpperCase()}-JOIN'`,
-- computed purely client-side from `code` (itself just the course id's
-- first 8 chars, truncated for display) — deterministic, guessable from
-- the id shown right next to it in the UI, and never actually checked
-- against anything since no redemption flow reads it either. Adds a
-- real persisted, randomly-generated, unique code per course.
-- =====================================================================

alter table courses add column join_code varchar unique;

create or replace function generate_course_join_code()
returns varchar
language plpgsql
as $$
declare
  v_alphabet text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; -- no 0/O/1/I ambiguity
  v_code varchar;
begin
  loop
    v_code := (
      select string_agg(substr(v_alphabet, (random() * length(v_alphabet))::int + 1, 1), '')
      from generate_series(1, 8)
    );
    exit when not exists (select 1 from courses where join_code = v_code);
  end loop;
  return v_code;
end;
$$;

create or replace function get_or_create_course_join_code(p_token text, p_course_id uuid)
returns varchar
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_course courses%rowtype;
  v_code varchar;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role <> 'teacher' then raise exception 'forbidden'; end if;

  select * into v_course from courses where id = p_course_id;
  if not found then raise exception 'course_not_found'; end if;
  if v_course.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;
  if not exists (
    select 1 from course_teachers ct
    where ct.course_id = p_course_id and ct.teacher_id = v_actor.user_id
  ) then raise exception 'forbidden'; end if;

  if v_course.join_code is not null then
    return v_course.join_code;
  end if;

  v_code := generate_course_join_code();
  update courses set join_code = v_code where id = p_course_id;
  return v_code;
end;
$$;

create or replace function regenerate_course_join_code(p_token text, p_course_id uuid)
returns varchar
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_course courses%rowtype;
  v_code varchar;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role <> 'teacher' then raise exception 'forbidden'; end if;

  select * into v_course from courses where id = p_course_id;
  if not found then raise exception 'course_not_found'; end if;
  if v_course.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;
  if not exists (
    select 1 from course_teachers ct
    where ct.course_id = p_course_id and ct.teacher_id = v_actor.user_id
  ) then raise exception 'forbidden'; end if;

  v_code := generate_course_join_code();
  update courses set join_code = v_code where id = p_course_id;

  insert into audit_logs (school_id, user_id, acted_role, action, entity_type, entity_id)
  values (v_actor.school_id, v_actor.user_id, v_actor.role, 'course.regenerate_join_code', 'courses', p_course_id::text);

  return v_code;
end;
$$;

revoke all on function get_or_create_course_join_code(text, uuid) from public;
revoke all on function regenerate_course_join_code(text, uuid) from public;

grant execute on function get_or_create_course_join_code(text, uuid) to anon, authenticated;
grant execute on function regenerate_course_join_code(text, uuid) to anon, authenticated;
