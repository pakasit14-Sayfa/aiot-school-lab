-- =====================================================================
-- Migration: 20260824110000_parent_portal_rpcs.sql
-- Description:
--   1. list_my_student_grades(p_token, p_student_id) — STK-2 Parent Grade View (only confirmed grades for linked children)
--   2. list_my_linked_students(p_token) — Return list of approved bound children
-- =====================================================================

create or replace function list_my_linked_students(p_token text)
returns table (
  student_id uuid,
  first_name varchar,
  last_name varchar,
  school_id uuid,
  relationship varchar,
  linked_at timestamptz
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role <> 'parent' then raise exception 'forbidden'; end if;

  return query
  select
    u.id as student_id,
    u.first_name,
    u.last_name,
    u.school_id,
    pl.relationship,
    pl.reviewed_at as linked_at
  from parent_links pl
  join users u on u.id = pl.student_id
  where pl.parent_id = v_actor.user_id
    and pl.status = 'approved'
  order by u.first_name, u.last_name;
end;
$$;

revoke all on function list_my_linked_students(text) from public;
grant execute on function list_my_linked_students(text) to anon, authenticated;

create or replace function list_my_student_grades(
  p_token text,
  p_student_id uuid
)
returns table (
  grade_id uuid,
  course_id uuid,
  subject_name varchar,
  score numeric,
  max_score numeric,
  confirmed_at timestamptz
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role <> 'parent' then raise exception 'forbidden'; end if;

  -- Verify active approved parent link
  if not exists (
    select 1 from parent_links pl
    where pl.parent_id = v_actor.user_id
      and pl.student_id = p_student_id
      and pl.status = 'approved'
  ) then
    raise exception 'forbidden';
  end if;

  return query
  select g.id, g.course_id, c.subject_name, g.score, g.max_score, g.confirmed_at
  from grades g
  join courses c on c.id = g.course_id
  where g.student_id = p_student_id
    and g.status = 'confirmed'
  order by c.subject_name;
end;
$$;

revoke all on function list_my_student_grades(text, uuid) from public;
grant execute on function list_my_student_grades(text, uuid) to anon, authenticated;
