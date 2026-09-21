#!/usr/bin/env bash
# Apply 20260918010000 (group submissions, PBL-10) to production.
# Run from the repo root:  bash scripts/prod_apply_2026-09-18.sh
set -euo pipefail
cd "$(dirname "$0")/.."
m=20260918010000_group_submissions
v=${m%%_*}; n=${m#*_}
echo "== applying $m"
npx supabase db query --linked --file "supabase/migrations/$m.sql" < /dev/null
npx supabase db query --linked \
  "insert into supabase_migrations.schema_migrations (version, name) values ('$v','$n') on conflict (version) do nothing" < /dev/null
echo "== verify (expect p_is_group in both, group_name in list_submissions)"
npx supabase db query --linked "select proname, pg_get_function_arguments(oid) like '%p_is_group%' as has_is_group from pg_proc where proname in ('create_assignment','update_assignment')" < /dev/null
npx supabase db query --linked "select pg_get_function_result(oid) like '%group_name%' as list_submissions_has_group_name from pg_proc where proname='list_submissions'" < /dev/null
