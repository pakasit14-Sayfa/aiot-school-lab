#!/usr/bin/env bash
# Apply 20260923000000 (assignment attachments + course library links/category/delete)
# to production.
#
# Run from the repo root:  bash scripts/prod_apply_2026-09-23.sh
#
# สิ่งที่ migration นี้เปลี่ยนบน prod:
#   * course_files  + kind / url / category  และ storage_path, size_bytes
#     เป็น null ได้ (ลิงก์ไม่มีไฟล์จริง) — แถวเดิมทั้งหมดได้ kind='file'
#     อัตโนมัติจาก default ไม่มีข้อมูลเดิมเสียหาย
#   * ตารางใหม่ assignment_attachments
#   * RPC ใหม่ 8 ตัว และแทนที่ register_course_file / list_course_files
#
# list_course_files เปลี่ยนรูปร่างคอลัมน์ที่คืน จึงต้อง drop ก่อน create —
# migration ทำให้แล้ว แต่แปลว่าช่วงระหว่างรันแอปจะเรียกไม่ได้ชั่วขณะ
#
# รอบแรก (2026-09-23) รันแล้วพังที่ `type "public.course_file_kind" does not
# exist` เพราะ `do $$ ... create type ... $$` ไม่ทำงานผ่าน supabase db query
# migration จึงเปลี่ยนมาใช้ text + CHECK แทน enum — รันซ้ำได้ปลอดภัย ทุก
# statement เป็น idempotent และรอบที่พังยังไม่ได้บันทึกเวอร์ชันลงตาราง
set -euo pipefail
cd "$(dirname "$0")/.."
m=20260923000000_assignment_attachments
v=${m%%_*}; n=${m#*_}

echo "== applying $m"
npx supabase db query --linked --file "supabase/migrations/$m.sql" < /dev/null
npx supabase db query --linked \
  "insert into supabase_migrations.schema_migrations (version, name) values ('$v','$n') on conflict (version) do nothing" < /dev/null

echo "== verify 1 (expect 9 rows)"
npx supabase db query --linked "
  select proname from pg_proc where proname in (
    'assert_course_teacher','register_course_link','update_course_file',
    'delete_course_file','attach_assignment_file','detach_assignment_file',
    'reorder_assignment_attachment','list_assignment_attachments','delete_assignment'
  ) order by 1" < /dev/null

echo "== verify 2 (expect table assignment_attachments)"
npx supabase db query --linked "
  select table_name from information_schema.tables
  where table_schema='public' and table_name='assignment_attachments'" < /dev/null

echo "== verify 2b (expect course_files_kind_enum check constraint)"
npx supabase db query --linked "
  select conname from pg_constraint where conname='course_files_kind_enum'" < /dev/null

echo "== verify 3 (expect columns kind, url, category on course_files)"
npx supabase db query --linked "
  select column_name, is_nullable from information_schema.columns
  where table_schema='public' and table_name='course_files'
    and column_name in ('kind','url','category','storage_path','size_bytes')
  order by column_name" < /dev/null

echo "== verify 4 (expect register_course_file to take 6 args incl. p_category)"
npx supabase db query --linked "
  select pg_get_function_identity_arguments(oid)
  from pg_proc where proname='register_course_file'" < /dev/null
