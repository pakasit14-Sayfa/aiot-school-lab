#!/usr/bin/env bash
# Apply 20260919000000 (D6 phase 1: admin timetable → room-based enrollment) to production.
# Run from the repo root:  bash scripts/prod_apply_2026-09-19.sh
# Same shape as prod_apply_2026-09-18b.sh — prod does not track migration history
# through `db push`, so we apply the file directly and record the version by hand.
set -euo pipefail
cd "$(dirname "$0")/.."
m=20260919000000_admin_timetable_enrollment
v=${m%%_*}; n=${m#*_}
echo "== applying $m"
npx supabase db query --linked --file "supabase/migrations/$m.sql" < /dev/null
npx supabase db query --linked \
  "insert into supabase_migrations.schema_migrations (version, name) values ('$v','$n') on conflict (version) do nothing" < /dev/null
echo "== verify 1 (expect timetable_rpcs = 6)"
npx supabase db query --linked "select count(*) as timetable_rpcs from pg_proc where proname in ('set_teacher_subjects','set_school_periods','admin_set_room_timetable_slot','admin_clear_room_timetable_slot','list_room_timetable','list_school_classes')" < /dev/null
echo "== verify 2 (expect create_course_admin_only = true)"
npx supabase db query --linked "select prosrc like '%not in (''school_admin'')%' as create_course_admin_only from pg_proc where proname='create_course'" < /dev/null
echo "== verify 3 (backfill: students auto-enrolled by room; expect > 0 if any course has a room)"
npx supabase db query --linked "select count(*) as auto_enrolled from course_students where enrolled_by is null" < /dev/null
