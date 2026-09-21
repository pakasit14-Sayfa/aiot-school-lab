#!/usr/bin/env bash
# Apply 20260921000000 (timetable v2: lunch breaks, school overview, teacher clashes, copy/clear a room) to production.
# Run from the repo root:  bash scripts/prod_apply_2026-09-21.sh
set -euo pipefail
cd "$(dirname "$0")/.."
m=20260921000000_timetable_v2
v=${m%%_*}; n=${m#*_}
echo "== applying $m"
npx supabase db query --linked --file "supabase/migrations/$m.sql" < /dev/null
npx supabase db query --linked \
  "insert into supabase_migrations.schema_migrations (version, name) values ('$v','$n') on conflict (version) do nothing" < /dev/null
echo "== verify (expect new_rpcs = 5, periods_have_kind = true)"
npx supabase db query --linked "select (select count(*) from pg_proc where proname in ('list_timetable_overview','list_teacher_week','list_teacher_conflicts','admin_copy_room_timetable','admin_clear_room_timetable')) as new_rpcs, (select count(*)=1 from information_schema.columns where table_name='school_periods' and column_name='kind') as periods_have_kind" < /dev/null
