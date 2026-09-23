#!/usr/bin/env bash
# Apply 20260923030000 (list_course_files + used_by_assignments) to production.
#
# Run from the repo root:  bash scripts/prod_apply_2026-09-23c.sh
#
# ทำไมต้องมี: หน้าคลังความรู้ต้องบอกได้ว่าของแต่ละชิ้นถูกใช้อยู่ในกี่ใบงาน
# ก่อนที่ครูจะกดลบแล้วเจอ error `file_in_use_by_N assignments` จาก
# delete_course_file — นับที่ฐานข้อมูล ไม่ใช่ให้แอปไล่ดึงไฟล์แนบของทุกใบงาน
# มานับเอง (N round trip ต่อการเปิดหน้าหนึ่งครั้ง และนับผิดถ้าครูสอนหลายวิชา)
#
# ชื่อเดิมคือ 20260923020000 / prod_apply_2026-09-23c.sh — เปลี่ยนเลขเพราะไป
# ชนกับ 20260923020000_quiz_question_type_integrity ของอีกเซสชันที่ทำงานบน
# checkout เดียวกัน (และ prod รันตัวนั้นไปแล้ว) สองไฟล์เลขเดียวกันจะทำให้
# ลำดับการรันกำกวมตอน db reset
#
# เปลี่ยนรูปร่างคอลัมน์ที่ list_course_files คืน จึงต้อง drop ก่อน create —
# migration ทำให้แล้ว แต่แปลว่าระหว่างรันมีช่วงสั้น ๆ ที่หน้าคลังความรู้บน
# เครื่องจริงเรียกไม่ได้ ควรรันตอนคนน้อย
set -euo pipefail
cd "$(dirname "$0")/.."
m=20260923030000_course_files_usage_count
v=${m%%_*}; n=${m#*_}

echo "== applying $m"
npx supabase db query --linked --file "supabase/migrations/$m.sql" < /dev/null
npx supabase db query --linked \
  "insert into supabase_migrations.schema_migrations (version, name) values ('$v','$n') on conflict (version) do nothing" < /dev/null

echo "== verify 1 (expect ONE list_course_files, and used_by_assignments in the result)"
npx supabase db query --linked "
  select pg_get_function_result(oid) from pg_proc where proname='list_course_files'" < /dev/null

echo "== verify 2 (expect used_by_assignments to count real rows, not always 0)"
npx supabase db query --linked "
  select f.id, f.file_name,
         (select count(*) from assignment_attachments a where a.course_file_id=f.id) as used
  from course_files f order by f.created_at desc limit 5" < /dev/null
