#!/usr/bin/env bash
# Apply 20260921020000 (unlink_assignment_sensor_dataset + unpublish_assignment) to production.
# Run from the repo root:  bash scripts/prod_apply_2026-09-21c.sh
set -euo pipefail
cd "$(dirname "$0")/.."
m=20260921020000_assignment_dataset_unlink_and_close
v=${m%%_*}; n=${m#*_}
echo "== applying $m"
npx supabase db query --linked --file "supabase/migrations/$m.sql" < /dev/null
npx supabase db query --linked \
  "insert into supabase_migrations.schema_migrations (version, name) values ('$v','$n') on conflict (version) do nothing" < /dev/null
echo "== verify (expect 2 rows: unlink_assignment_sensor_dataset, unpublish_assignment)"
npx supabase db query --linked "select proname from pg_proc where proname in ('unlink_assignment_sensor_dataset','unpublish_assignment') order by 1" < /dev/null
