#!/usr/bin/env bash
# Apply 20260923020000 (add_quiz_question ปฏิเสธคำถามที่ชนิดกับข้อมูลขัดกันเอง)
#
# รันจาก repo root:  bash scripts/prod_apply_2026-09-23c.sh
#
# ทำไมต้องมี: หน้าคลังข้อสอบเทียบชนิดคำถามกับค่า 'essay' ที่ไม่มีใน enum
# question_type เลย คำถามทุกข้อจึงกลายเป็นปรนัย ข้ออัตนัยไหลเข้า Exam Builder
# เป็นปรนัยที่ไม่มีตัวเลือกและมีเฉลยชี้ไปที่ตัวเลือกที่ไม่มีอยู่ ฝั่งแอปแก้แล้ว
# (d359225) แต่ RPC นี้เป็นทางเดียวที่เขียน quiz_questions ได้ ด่านสุดท้ายจึง
# ต้องอยู่ที่นี่ด้วย
set -euo pipefail
cd "$(dirname "$0")/.."
m=20260923020000_quiz_question_type_integrity
v=${m%%_*}; n=${m#*_}

echo "== applying $m"
npx supabase db query --linked --file "supabase/migrations/$m.sql" < /dev/null
npx supabase db query --linked \
  "insert into supabase_migrations.schema_migrations (version, name) values ('$v','$n') on conflict (version) do nothing" < /dev/null

echo
echo "== verify 1 (ต้องมี add_quiz_question ตัวเดียว ลายเซ็น 6 พารามิเตอร์)"
npx supabase db query --linked "
  select pg_get_function_identity_arguments(oid)
  from pg_proc where proname='add_quiz_question'" < /dev/null

echo
echo "== verify 2 (ด่านใหม่ต้องอยู่ในตัวฟังก์ชันจริง)"
npx supabase db query --linked "
  select
    position('choices_required' in prosrc) > 0                 as has_choices_guard,
    position('short_answer_takes_no_choices' in prosrc) > 0    as has_short_answer_guard,
    position('exactly_one_correct_choice_required' in prosrc) > 0 as has_one_correct_guard
  from pg_proc where proname='add_quiz_question'" < /dev/null

echo
echo "== verify 3 (ข้อมูลเสียที่ค้างอยู่ก่อนหน้านี้ — ถ้ามีแถว ต้องตามไปแก้ด้วยมือ)"
npx supabase db query --linked "
  select q.title as ชุด, qq.question as คำถาม, qq.type as ชนิด,
         count(qc.id) as จำนวนตัวเลือก
  from quiz_questions qq
  join quizzes q on q.id = qq.quiz_id
  left join quiz_choices qc on qc.question_id = qq.id
  where qq.type <> 'short_answer'
  group by q.title, qq.question, qq.type
  having count(qc.id) < 2" < /dev/null

cat <<'EOF'

─────────────────────────────────────────────────────────────
verify 3 ว่างเปล่า = ไม่มีข้อมูลเสียค้างอยู่บน prod
ถ้ามีแถวขึ้นมา = ข้อสอบพวกนั้นถูกสร้างตอนบั๊กยังอยู่ นักเรียนตอบไม่ได้
   แก้ได้ 2 ทาง: เปลี่ยนชนิดเป็น short_answer (ถ้าตั้งใจให้เขียนตอบ)
   หรือเพิ่มตัวเลือกกับเฉลยให้ครบผ่านหน้า Exam Builder
─────────────────────────────────────────────────────────────
EOF
