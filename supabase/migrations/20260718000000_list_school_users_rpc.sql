-- =====================================================================
-- list_school_users: real backing RPC for AuthService.getAllUsers()
-- (previously a client-side mock returning only the current user).
--
-- school_admin sees only their own school's users; super_admin sees
-- everyone. A user's "active_role" here is picked from user_roles
-- scoped to their home school (users.school_id), falling back to
-- their most recently granted role otherwise (e.g. a parent whose
-- only role rows are scoped to a different school_id).
-- =====================================================================

create or replace function list_school_users(p_token text)
returns table (
  user_id uuid,
  first_name varchar,
  last_name varchar,
  email varchar,
  active_role text,
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
      u.school_id as active_school_id,
      u.status::text as status
    from users u
    where v_actor.role = 'super_admin' or u.school_id is not distinct from v_actor.school_id
    order by u.created_at desc;
end;
$$;

grant execute on function list_school_users(text) to anon, authenticated;
