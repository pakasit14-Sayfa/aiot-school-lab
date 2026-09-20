#!/usr/bin/env bash
# Apply 20260920040000 (list_school_classes varchar→text cast; the admin timetable page failed to load without it).
# Run from the repo root:  bash scripts/prod_apply_2026-09-20d.sh
set -euo pipefail
cd "$(dirname "$0")/.."
m=20260920040000_list_school_classes_text_cast
v=${m%%_*}; n=${m#*_}
echo "== applying $m"
npx supabase db query --linked --file "supabase/migrations/$m.sql" < /dev/null
npx supabase db query --linked \
  "insert into supabase_migrations.schema_migrations (version, name) values ('$v','$n') on conflict (version) do nothing" < /dev/null
echo "== verify (expect casts_to_text = true)"
npx supabase db query --linked "select prosrc like '%sp.grade_level::text%' as casts_to_text from pg_proc where proname='list_school_classes'" < /dev/null
