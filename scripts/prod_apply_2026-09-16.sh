#!/usr/bin/env bash
# Apply the 6 migrations missing on production as of 2026-09-17 (runbook 4.1–4.3).
# Read-only pre-check on 2026-09-17 showed exactly these 6 absent; everything
# up to 20260914000000 is already on the remote.
#
# Run from the repo root after `npx supabase link` (already linked):
#   ./scripts/prod_apply_2026-09-16.sh
# Stops at the first failure. Each file runs as one statement batch (all-or-nothing).
set -euo pipefail
cd "$(dirname "$0")/.."

MIGRATIONS=(
  20260914010000_school_admin_assets_mutations
  20260914020000_my_account_password_sessions_import
  20260914030000_utility_usage_by_location
  20260914040000_school_device_detail
  20260916010000_list_lesson_progress
  20260916020000_offline_minutes_enforced
)

for m in "${MIGRATIONS[@]}"; do
  v=${m%%_*}; n=${m#*_}
  echo "== applying $m"
  npx supabase db query --linked --file "supabase/migrations/$m.sql" < /dev/null
  npx supabase db query --linked \
    "insert into supabase_migrations.schema_migrations (version, name) values ('$v','$n') on conflict (version) do nothing" < /dev/null
done

echo "== verify"
npx supabase db query --linked "
select
  (select count(*) from pg_proc where proname in ('update_school_building','change_my_password','get_utility_usage_by_location','get_school_device_detail','list_lesson_progress')) as new_rpcs_present_expect_5,
  (select column_default from information_schema.columns where table_name='devices' and column_name='firmware_version') as fw_default_expect_null,
  (select count(*) from devices where firmware_version='v1.2.0-prod') as fake_fw_left_expect_1_or_0,
  (select pg_get_functiondef(oid) like '%offline_minutes%' from pg_proc where proname='device_effective_status') as offline_enforced_expect_true
" < /dev/null
npx supabase migration list --linked < /dev/null | grep -o '"local":"2026091[46][0-9]*","remote":"[0-9]*"'
