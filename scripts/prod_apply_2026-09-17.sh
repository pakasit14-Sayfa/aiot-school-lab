#!/usr/bin/env bash
# Apply 20260917010000 (set_student_profile + import with grade/room) to production.
# Run from the repo root:  bash scripts/prod_apply_2026-09-17.sh
set -euo pipefail
cd "$(dirname "$0")/.."
m=20260917010000_set_student_profile
v=${m%%_*}; n=${m#*_}
echo "== applying $m"
npx supabase db query --linked --file "supabase/migrations/$m.sql" < /dev/null
npx supabase db query --linked \
  "insert into supabase_migrations.schema_migrations (version, name) values ('$v','$n') on conflict (version) do nothing" < /dev/null
echo "== verify"
npx supabase db query --linked "
select
  (select count(*) from pg_proc where proname='set_student_profile') as set_student_profile_expect_1,
  (select prosrc ilike '%student_profiles%' from pg_proc where proname='import_school_users_batch_for_school_admin') as import_writes_profiles_expect_true
" < /dev/null
