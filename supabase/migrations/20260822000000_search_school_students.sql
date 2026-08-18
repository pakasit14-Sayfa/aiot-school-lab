-- =====================================================================
-- Migration: Search School Students RPC
-- Provides autocomplete student search for teachers in the same school.
-- =====================================================================

set search_path = public, extensions;

create or replace function search_school_students(
  p_token text,
  p_query text default ''
)
returns table (
  student_id uuid,
  first_name varchar,
  last_name varchar,
  email varchar
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_q text;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('teacher', 'school_admin') then
    raise exception 'forbidden';
  end if;

  v_q := coalesce(trim(p_query), '');

  return query
  select distinct
    u.id as student_id,
    u.first_name,
    u.last_name,
    u.email
  from users u
  join user_roles ur on ur.user_id = u.id
  where ur.school_id = v_actor.school_id
    and ur.role = 'student'
    and (
      v_q = ''
      or (u.first_name || ' ' || u.last_name) ilike ('%' || v_q || '%')
      or u.email ilike ('%' || v_q || '%')
    )
  order by u.first_name, u.last_name
  limit 50;
end;
$$;

revoke all on function search_school_students(text, text) from public;
grant execute on function search_school_students(text, text) to anon, authenticated;
