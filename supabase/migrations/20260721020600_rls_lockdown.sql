-- =====================================================================
-- RLS/RPC tenant isolation lockdown (PDPA gate 1).
--
-- Must be the LAST migration in this series: it sweeps every table and
-- every SECURITY DEFINER function that exists in the public schema at
-- the moment it runs, so it has to execute after all of
-- 20260721020000_session_and_rate_limit_hardening.sql,
-- 20260721020100_parent_binding.sql,
-- 20260721020200_parent_link_review.sql,
-- 20260721020300_consent_policy.sql,
-- 20260721020400_sensor_read_scope.sql and
-- 20260721020500_signed_gateway_ingest.sql have created their tables
-- and functions.
-- =====================================================================

-- RPC-only client model: direct Data API table access stays revoked even if a
-- future RLS policy is added accidentally. SECURITY DEFINER RPCs are reviewed
-- and allow-listed separately.
do $$
declare
  v_table record;
begin
  for v_table in
    select schemaname, tablename
    from pg_tables
    where schemaname = 'public'
  loop
    execute format(
      'alter table %I.%I enable row level security',
      v_table.schemaname,
      v_table.tablename
    );
  end loop;
end;
$$;

revoke all on all tables in schema public from public, anon, authenticated;
revoke all on all sequences in schema public from public, anon, authenticated;

-- Defense in depth for every SECURITY DEFINER function created by all prior
-- migrations. Explicit grants to anon/authenticated/service_role remain; the
-- implicit PostgreSQL PUBLIC execute privilege is removed universally.
do $$
declare
  v_function record;
begin
  for v_function in
    select
      n.nspname as schema_name,
      p.proname as function_name,
      pg_get_function_identity_arguments(p.oid) as identity_arguments
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.prosecdef
  loop
    execute format(
      'revoke execute on function %I.%I(%s) from public',
      v_function.schema_name,
      v_function.function_name,
      v_function.identity_arguments
    );
  end loop;
end;
$$;
