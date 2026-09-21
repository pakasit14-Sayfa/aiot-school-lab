#!/usr/bin/env bash
# Repair D6 phase 1 on production: prod got the unreviewed 20260919 via `db push`
# (2026-09-20). This applies the reviewed definitions idempotently.
# Run from the repo root:  bash scripts/prod_apply_2026-09-20.sh
set -euo pipefail
cd "$(dirname "$0")/.."
m=20260920000000_d6_phase1_prod_repair
v=${m%%_*}; n=${m#*_}
echo "== applying $m"
npx supabase db query --linked --file "supabase/migrations/$m.sql" < /dev/null
npx supabase db query --linked \
  "insert into supabase_migrations.schema_migrations (version, name) values ('$v','$n') on conflict (version) do nothing" < /dev/null
echo "== verify 1 (expect set_class_schedule_overloads = 1)"
npx supabase db query --linked "select count(*) as set_class_schedule_overloads from pg_proc where proname='set_class_schedule'" < /dev/null
echo "== verify 2 (expect room_key_fn = 1, create_course_checks_school = true)"
npx supabase db query --linked "select (select count(*) from pg_proc where proname='_class_room_key') as room_key_fn, (select prosrc like '%ay.school_id = v_actor.school_id%' from pg_proc where proname='create_course') as create_course_checks_school" < /dev/null
echo "== verify 3 (expect auto_enrolled = 3: the ม.1/1 students in คณิตศาสตร์ ม.1/1)"
npx supabase db query --linked "select count(*) as auto_enrolled from course_students where enrolled_by is null" < /dev/null
