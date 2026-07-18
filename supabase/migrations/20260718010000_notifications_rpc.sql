-- =====================================================================
-- Notification RPCs: list_my_notifications, mark_notification_read
--
-- Same reasoning as every other RPC here — RLS is deny-all, notifications
-- are strictly per-user (own inbox only, no cross-user/school scoping).
-- =====================================================================

create or replace function list_my_notifications(p_token text)
returns table (
  id uuid,
  type varchar,
  title varchar,
  body text,
  payload jsonb,
  created_at timestamptz,
  read_at timestamptz
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

  return query
    select n.id, n.type, n.title, n.body, n.payload, n.created_at, n.read_at
    from notifications n
    where n.user_id = v_actor.user_id
    order by n.created_at desc
    limit 100;
end;
$$;

create or replace function mark_notification_read(
  p_token text,
  p_notification_id uuid
)
returns void
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

  update notifications
    set read_at = now()
    where id = p_notification_id
      and user_id = v_actor.user_id
      and read_at is null;
end;
$$;

grant execute on function list_my_notifications(text) to anon, authenticated;
grant execute on function mark_notification_read(text, uuid) to anon, authenticated;
