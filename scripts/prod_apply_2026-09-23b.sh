#!/usr/bin/env bash
# Apply 20260923010000 (drop the stale 5-arg register_course_file overload).
#
# Run from the repo root:  bash scripts/prod_apply_2026-09-23b.sh
#
# ทำไมต้องมี: 20260923000000 เพิ่ม p_category เป็นพารามิเตอร์ที่ 6 แล้วคิดว่า
# create or replace ทับของเดิม — ไม่ทับ เพราะคนละจำนวนพารามิเตอร์คือคนละ
# ฟังก์ชัน verify 4 บน prod จึงเห็น register_course_file สองตัว ตัวเก่าไม่
# รู้จัก category ทิ้งไว้แล้วมีวันที่ตัวเรียกไหนเผลอส่ง 5 ตัว หมวดจะหายเงียบ
set -euo pipefail
cd "$(dirname "$0")/.."
m=20260923010000_drop_old_register_course_file
v=${m%%_*}; n=${m#*_}

echo "== applying $m"
npx supabase db query --linked --file "supabase/migrations/$m.sql" < /dev/null
npx supabase db query --linked \
  "insert into supabase_migrations.schema_migrations (version, name) values ('$v','$n') on conflict (version) do nothing" < /dev/null

echo "== verify 1 (expect EXACTLY ONE row, the 6-arg version with p_category)"
npx supabase db query --linked "
  select pg_get_function_identity_arguments(oid)
  from pg_proc where proname='register_course_file'" < /dev/null

echo "== verify 2 (list_course_files must return the new columns: kind,url,category)"
npx supabase db query --linked "
  select pg_get_function_result(oid) from pg_proc where proname='list_course_files'" < /dev/null
