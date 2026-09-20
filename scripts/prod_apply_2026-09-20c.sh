#!/usr/bin/env bash
# Apply 20260920030000 (D6 phase 2 RPC fixes: admin lists all teacher subjects; slot assignment records teacher↔subject) to production.
# Run from the repo root:  bash scripts/prod_apply_2026-09-20c.sh
set -euo pipefail
cd "$(dirname "$0")/.."
m=20260920030000_timetable_phase2_rpc_fixes
v=${m%%_*}; n=${m#*_}
echo "== applying $m"
npx supabase db query --linked --file "supabase/migrations/$m.sql" < /dev/null
npx supabase db query --linked \
  "insert into supabase_migrations.schema_migrations (version, name) values ('$v','$n') on conflict (version) do nothing" < /dev/null
echo "== verify (expect returns_teacher_name = true, slot_records_subject = true)"
npx supabase db query --linked "select (select pg_get_function_result(oid) like '%teacher_name%' from pg_proc where proname='list_teacher_subjects') as returns_teacher_name, (select prosrc like '%INSERT INTO public.teacher_subjects%' from pg_proc where proname='admin_set_room_timetable_slot') as slot_records_subject" < /dev/null
