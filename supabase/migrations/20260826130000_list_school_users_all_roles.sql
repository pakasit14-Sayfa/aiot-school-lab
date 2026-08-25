-- list_school_users currently collapses a multi-role account down to a
-- single "active_role" (most-recently-granted wins), which hides
-- multi-role users from single-role-filtered lists (e.g. the teacher
-- roster excluding a teacher who was later also granted school_admin).
-- Add an `all_roles` array alongside the existing `active_role` so
-- callers that need "does this user hold role X at all" can check that
-- instead of the single collapsed value. `active_role` is left
-- unchanged for backward compatibility with existing callers.
drop function if exists public.list_school_users(text);

create or replace function public.list_school_users(p_token text)
returns table(
  user_id uuid,
  first_name varchar,
  last_name varchar,
  email varchar,
  active_role text,
  all_roles text[],
  active_school_id uuid,
  status text
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then
    raise exception 'invalid_session';
  end if;

  if v_actor.role not in ('school_admin', 'super_admin') then
    raise exception 'forbidden';
  end if;

  return query
    select
      u.id as user_id,
      u.first_name,
      u.last_name,
      u.email,
      coalesce(
        (select ur.role::text from user_roles ur
         where ur.user_id = u.id and ur.school_id is not distinct from u.school_id
         order by ur.granted_at desc limit 1),
        (select ur.role::text from user_roles ur
         where ur.user_id = u.id
         order by ur.granted_at desc limit 1),
        'student'
      ) as active_role,
      coalesce(
        (select array_agg(distinct ur.role::text) from user_roles ur
         where ur.user_id = u.id),
        array[]::text[]
      ) as all_roles,
      u.school_id as active_school_id,
      u.status::text as status
    from users u
    where v_actor.role = 'super_admin' or u.school_id is not distinct from v_actor.school_id
    order by u.created_at desc;
end;
$$;

grant execute on function public.list_school_users(text) to anon, authenticated;
