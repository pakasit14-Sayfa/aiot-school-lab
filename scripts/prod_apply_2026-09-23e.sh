#!/usr/bin/env bash
# Apply 20260923030000 (list_homeroom_attendance / list_course_attendance
# now sort ด้วย collation th-TH-x-icu แทน default en_US.UTF-8)
#
# รันจาก repo root:  bash scripts/prod_apply_2026-09-23e.sh
#
# ทำไมต้องมี: หน้าเช็คชื่อนักเรียนเรียงชื่อด้วย ORDER BY first_name แบบ
# collation default ของ DB ซึ่งเรียงตาม Unicode codepoint ตรง ๆ ไม่ใช่
# พจนานุกรมไทย — ชื่อที่ขึ้นต้นด้วยสระนำ (เ-/แ-/โ-/ใ-/ไ-) จะถูกจัดกลุ่ม
# ท้ายสุดของอักษรนั้นแทนที่จะแทรกตามพยัญชนะถัดไปแบบที่คนไทยคาดหวัง
# ทดสอบแล้วบน local ว่า th-TH-x-icu (มากับ ICU ของ Postgres นี้อยู่แล้ว)
# เรียงถูกต้อง เช่น กมล/แก้ว/โกวิท/ไก่ ต้องอยู่กลุ่ม ก ก่อน ขวัญ ก่อน เอกชัย
set -euo pipefail
cd "$(dirname "$0")/.."
m=20260923030000_attendance_roster_thai_sort
v=${m%%_*}; n=${m#*_}

echo "== applying $m"
npx supabase db query --linked --file "supabase/migrations/$m.sql" < /dev/null
npx supabase db query --linked \
  "insert into supabase_migrations.schema_migrations (version, name) values ('$v','$n') on conflict (version) do nothing" < /dev/null

echo
echo "== verify 1 (ทั้งสอง RPC ต้องมี th-TH-x-icu อยู่ในตัวฟังก์ชันจริง)"
npx supabase db query --linked "
  select proname, prosrc ilike '%th-TH-x-icu%' as has_thai_collation
  from pg_proc where proname in ('list_homeroom_attendance','list_course_attendance')" < /dev/null

echo
echo "== verify 2 (สิทธิ์ execute ต้องไม่หายหลัง CREATE OR REPLACE)"
npx supabase db query --linked "
  select routine_name, grantee, privilege_type
  from information_schema.routine_privileges
  where routine_name in ('list_homeroom_attendance','list_course_attendance')
  order by routine_name, grantee" < /dev/null

cat <<'EOF'

─────────────────────────────────────────────────────────────
verify 1 ต้อง has_thai_collation = true ทั้ง 2 แถว
verify 2 ต้องมีครบ anon/authenticated/postgres/service_role ทั้ง 2 ฟังก์ชัน
   (ถ้าขาดแถวไหนไป แปลว่า grant เดิมหาย ต้อง grant execute ใหม่)
─────────────────────────────────────────────────────────────
EOF
