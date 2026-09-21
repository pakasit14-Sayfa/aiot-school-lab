#!/usr/bin/env bash
# Apply 20260920050000 (timetable reads/clears match rooms via _class_room_key) to production.
# Run from the repo root:  bash scripts/prod_apply_2026-09-20e.sh
set -euo pipefail
cd "$(dirname "$0")/.."
m=20260920050000_timetable_room_key_reads
v=${m%%_*}; n=${m#*_}
echo "== applying $m"
npx supabase db query --linked --file "supabase/migrations/$m.sql" < /dev/null
npx supabase db query --linked \
  "insert into supabase_migrations.schema_migrations (version, name) values ('$v','$n') on conflict (version) do nothing" < /dev/null
echo "== verify (expect both true)"
npx supabase db query --linked "select (select prosrc like '%_class_room_key%' from pg_proc where proname='list_room_timetable') as list_uses_key, (select prosrc like '%_class_room_key%' from pg_proc where proname='admin_clear_room_timetable_slot') as clear_uses_key" < /dev/null
