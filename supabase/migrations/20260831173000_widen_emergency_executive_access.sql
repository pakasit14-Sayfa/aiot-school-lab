-- Widen acknowledge and close emergency event to include executive

create or replace function acknowledge_emergency_event(
  p_token text,
  p_event_id uuid
)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_event record;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('school_admin', 'teacher', 'executive') then
    raise exception 'forbidden';
  end if;

  select * into v_event from emergency_events where id = p_event_id;
  if not found then raise exception 'event_not_found'; end if;
  if v_actor.role <> 'super_admin' and v_event.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;

  if v_event.status = 'closed' then
    raise exception 'event_already_closed';
  end if;
  if v_event.status = 'acknowledged' then
    raise exception 'event_already_acknowledged';
  end if;

  update emergency_events
  set status = 'acknowledged',
      acknowledged_by = v_actor.user_id,
      acknowledged_at = now()
  where id = p_event_id;
end;
$$;


create or replace function close_emergency_event(
  p_token text,
  p_event_id uuid,
  p_review_note text
)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_event record;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('school_admin', 'teacher', 'executive') then
    raise exception 'forbidden';
  end if;

  if p_review_note is null or trim(p_review_note) = '' then
    raise exception 'review_note_required';
  end if;

  select * into v_event from emergency_events where id = p_event_id;
  if not found then raise exception 'event_not_found'; end if;
  if v_actor.role <> 'super_admin' and v_event.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;

  if v_event.status = 'closed' then
    raise exception 'event_already_closed';
  end if;

  update emergency_events
  set status = 'closed',
      closed_at = now(),
      review_note = trim(p_review_note),
      warning_light_on = false
  where id = p_event_id;
end;
$$;

grant execute on function acknowledge_emergency_event(text, uuid) to anon, authenticated;
grant execute on function close_emergency_event(text, uuid, text) to anon, authenticated;
