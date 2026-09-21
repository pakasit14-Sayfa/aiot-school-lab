#!/usr/bin/env bash
# Apply 20260918020000 (charts RPC, PBL-7) to production.
# Run from the repo root:  bash scripts/prod_apply_2026-09-18b.sh
set -euo pipefail
cd "$(dirname "$0")/.."
m=20260918020000_charts_rpc
v=${m%%_*}; n=${m#*_}
echo "== applying $m"
npx supabase db query --linked --file "supabase/migrations/$m.sql" < /dev/null
npx supabase db query --linked \
  "insert into supabase_migrations.schema_migrations (version, name) values ('$v','$n') on conflict (version) do nothing" < /dev/null
echo "== verify (expect 4)"
npx supabase db query --linked "select count(*) as charts_rpc_expect_4 from pg_proc where proname in ('list_my_sensor_datasets','create_chart','list_my_charts','delete_chart')" < /dev/null
