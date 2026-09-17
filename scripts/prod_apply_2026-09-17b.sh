#!/usr/bin/env bash
# Apply 20260917020000 (delete_school_event) to production.
# Run from the repo root:  bash scripts/prod_apply_2026-09-17b.sh
set -euo pipefail
cd "$(dirname "$0")/.."
m=20260917020000_delete_school_event
v=${m%%_*}; n=${m#*_}
echo "== applying $m"
npx supabase db query --linked --file "supabase/migrations/$m.sql" < /dev/null
npx supabase db query --linked \
  "insert into supabase_migrations.schema_migrations (version, name) values ('$v','$n') on conflict (version) do nothing" < /dev/null
echo "== verify"
npx supabase db query --linked "select count(*) as delete_school_event_expect_1 from pg_proc where proname='delete_school_event'" < /dev/null
