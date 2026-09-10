-- Resolve identity only. This does not pair a terminal or record a loan/check-in.
create or replace function public.get_school_device_by_code(p_token text, p_code text)
returns jsonb language plpgsql security definer set search_path = public, extensions as $$
declare actor record; matches jsonb;
begin
  select * into actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if actor.role not in ('executive','school_admin','super_admin','teacher') or actor.school_id is null
    then raise exception 'forbidden'; end if;
  if nullif(btrim(p_code),'') is null then raise exception 'code_required'; end if;
  select jsonb_agg(jsonb_build_object(
    'id',d.id,'name',d.name,'type',d.type,'status',d.status,
    'device_code',d.device_code,'kit_code',d.kit_code,
    'location',d.location,'building',d.building,'room',d.room
  )) into matches from devices d
  where d.school_id = actor.school_id and
    (d.id::text=btrim(p_code) or d.device_code=btrim(p_code) or d.kit_code=btrim(p_code));
  if coalesce(jsonb_array_length(matches),0) > 1 then raise exception 'ambiguous_device_code'; end if;
  return matches->0;
end;
$$;
revoke all on function public.get_school_device_by_code(text,text) from public, service_role;
grant execute on function public.get_school_device_by_code(text,text) to anon, authenticated;
notify pgrst, 'reload schema';
