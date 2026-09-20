#!/usr/bin/env bash
# Apply 20260920020000 (sensor_history downsampling — no more silent 1,000-row cut) to production.
# Run from the repo root:  bash scripts/prod_apply_2026-09-20b.sh
set -euo pipefail
cd "$(dirname "$0")/.."
m=20260920020000_sensor_history_downsample
v=${m%%_*}; n=${m#*_}
echo "== applying $m"
npx supabase db query --linked --file "supabase/migrations/$m.sql" < /dev/null
npx supabase db query --linked \
  "insert into supabase_migrations.schema_migrations (version, name) values ('$v','$n') on conflict (version) do nothing" < /dev/null
echo "== verify 1 (expect has_max_points = true, overloads = 1)"
npx supabase db query --linked "select bool_and(pg_get_function_arguments(oid) like '%p_max_points%') as has_max_points, count(*) as overloads from pg_proc where proname='sensor_history'" < /dev/null
npx supabase db query --linked "select count(*) as raw_rows_30d, max(ts) as last_raw_ts from sensor_readings r join devices d on d.id=r.device_id where d.name='เซนเซอร์ห้องทดลอง' and r.metric='temperature' and r.ts > now() - interval '30 days'" < /dev/null
echo "== (the RPC itself needs a session token, so check the result in the app: the dataset chart must now span the whole 29 Aug burst, not 09:48–10:37)"
