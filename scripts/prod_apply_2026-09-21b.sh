#!/usr/bin/env bash
# Apply 20260921010000 (list_assignments returns submitted/pending/total/dataset counts) to production.
# Run from the repo root:  bash scripts/prod_apply_2026-09-21b.sh
set -euo pipefail
cd "$(dirname "$0")/.."
m=20260921010000_list_assignments_counts
v=${m%%_*}; n=${m#*_}
echo "== applying $m"
npx supabase db query --linked --file "supabase/migrations/$m.sql" < /dev/null
npx supabase db query --linked \
  "insert into supabase_migrations.schema_migrations (version, name) values ('$v','$n') on conflict (version) do nothing" < /dev/null
echo "== verify (expect has_counts = true)"
npx supabase db query --linked "select pg_get_function_result(oid) like '%pending_grade_count%' as has_counts from pg_proc where proname='list_assignments'" < /dev/null
