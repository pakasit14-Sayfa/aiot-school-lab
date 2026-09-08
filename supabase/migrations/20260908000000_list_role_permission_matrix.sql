-- =====================================================================
-- S1: real role→permission matrix for school_permissions_page, replacing
-- the fully hand-written matrix it used to show (7 fake "modules", and a
-- "ครูประจำอาคาร" column for a role merged away on 2026-08-25 — see
-- CLAUDE.md). Per DECISIONS_2026-09-07.md item 5: build the matrix from
-- the live database's own RPC definitions, not from a hand-maintained
-- table, and never let it drift out of sync with what the RPCs actually
-- enforce again.
--
-- Extraction method: every RPC in this project gates access with a
-- `v_actor.role not in (...)` check near the top of its body (see
-- AGENTS.md's "3 ข้อที่ผิดแล้วพังเงียบ" / hard rule 2). This scans
-- `pg_get_functiondef()` — the function's *live* source, not a migration
-- file that may have been superseded — for that exact pattern and
-- extracts the role list. Functions whose access control does not match
-- this pattern (a helper function, a NOT EXISTS subquery, multiple
-- sequential checks, etc.) report allowed_roles = null rather than a
-- guessed list — an honest gap is safer than a wrong permission claim on
-- a page administrators may use to reason about who can do what.
-- =====================================================================

create or replace function list_role_permission_matrix(p_token text)
returns table (
  function_name text,
  allowed_roles text[]
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

  if v_actor.role not in ('school_admin', 'super_admin') then
    raise exception 'forbidden';
  end if;

  return query
  select
    p.proname::text,
    case
      when m[1] is not null then
        (
          select array_agg(trim(both '''' from trim(role_text)))
          from unnest(string_to_array(m[1], ',')) as role_text
        )
      else null
    end
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  cross join lateral (
    select (regexp_match(
      pg_get_functiondef(p.oid),
      'v_actor\.role\s+not\s+in\s*\(([^)]+)\)',
      'i'
    )) as m
  ) matched
  where n.nspname = 'public'
    and p.prokind = 'f'
    and p.prosrc ilike '%v_actor.role%'
  order by p.proname;
end;
$$;

-- New functions in schema public default to service_role having EXECUTE
-- (this project's local Supabase bootstrap grants it broadly) — revoke it
-- explicitly since no Edge Function calls this.
revoke all on function list_role_permission_matrix(text) from public, service_role;
grant execute on function list_role_permission_matrix(text) to anon, authenticated;
