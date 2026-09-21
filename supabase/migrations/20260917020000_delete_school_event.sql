-- delete_school_event — pairs with create_school_event (20260901…), which
-- until 2026-09-17 had no caller anywhere in the app: the calendar pages of
-- every role read school_events, but nothing let a School Admin add one.
-- The School Admin settings page now creates and deletes events; a create
-- without a delete would leave typos on every parent's calendar forever.

create or replace function public.delete_school_event(p_token text, p_event_id uuid)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_event school_events%rowtype;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('school_admin', 'super_admin') then
    raise exception 'forbidden';
  end if;

  select * into v_event from school_events where id = p_event_id;
  if not found then raise exception 'event_not_found'; end if;
  if v_actor.role <> 'super_admin' and v_event.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;

  delete from school_events where id = p_event_id;

  insert into audit_logs (school_id, user_id, acted_role, action, entity_type, entity_id, details)
  values (v_event.school_id, v_actor.user_id, v_actor.role, 'delete_school_event',
          'school_event', p_event_id::text,
          jsonb_build_object('title', v_event.title, 'start_date', v_event.start_date));
end;
$$;

grant execute on function public.delete_school_event(text, uuid) to anon, authenticated, service_role;
