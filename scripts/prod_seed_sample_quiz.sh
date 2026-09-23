#!/usr/bin/env bash
# สร้าง "ข้อสอบตัวอย่าง" 1 ชุดบน prod เพื่อดูหน้าตาในแอป — ข้อมูลตัวอย่าง ไม่ใช่ migration
#
# รันจาก repo root:  bash scripts/prod_seed_sample_quiz.sh
# เลือกวิชาเองได้:    COURSE_ID=<uuid> bash scripts/prod_seed_sample_quiz.sh
#
# ทำไมต้องเป็นสคริปต์ให้เจ้าของรันเอง: prod เป็นระบบที่ใช้งานจริง การเพิ่มข้อมูล
# ตัวอย่างเข้าไปเป็นการตัดสินใจของเจ้าของ ไม่ใช่ของ AI
#
# ปลอดภัย: รันซ้ำได้ (ถ้ามีชุดนี้อยู่แล้วจะข้าม) · ไม่แตะข้อสอบอื่น ·
# ชื่อขึ้นต้นด้วย "[ตัวอย่าง]" เพื่อให้แยกออกจากข้อสอบจริงและลบทิ้งง่าย
#
# ลบทิ้งเมื่อไม่ต้องการแล้ว — คำสั่งอยู่ท้ายไฟล์นี้
set -euo pipefail
cd "$(dirname "$0")/.."

TITLE='[ตัวอย่าง] แบบทดสอบก่อนเรียน — เซนเซอร์และการวัดค่า'
COURSE_ID="${COURSE_ID:-}"

echo "== 1. ดูว่าจะสร้างในวิชาไหน"
npx supabase db query --linked "
  select c.id, c.subject_name, u.email as teacher, c.status
  from courses c
  join course_teachers ct on ct.course_id = c.id
  join users u on u.id = ct.teacher_id
  $( [ -n "$COURSE_ID" ] && echo "where c.id = '$COURSE_ID'" )
  order by c.created_at
  limit 5" < /dev/null

echo
echo "== 2. สร้างข้อสอบตัวอย่าง (ข้ามถ้ามีอยู่แล้ว)"
npx supabase db query --linked "
do \$\$
declare
  v_course_id  uuid;
  v_teacher_id uuid;
  v_quiz_id    uuid;
  v_q          uuid;
begin
  -- เลือกวิชาที่มีครูผูกอยู่จริง ไม่งั้นข้อสอบจะไม่มีใครแก้ไขได้
  select ct.course_id, ct.teacher_id into v_course_id, v_teacher_id
  from course_teachers ct
  join courses c on c.id = ct.course_id
  $( [ -n "$COURSE_ID" ] && echo "where ct.course_id = '$COURSE_ID'" )
  order by c.created_at
  limit 1;

  if v_course_id is null then
    raise exception 'ไม่พบวิชาที่มีครูผูกอยู่ — สร้างรายวิชาและกำหนดครูผู้สอนก่อน';
  end if;

  select id into v_quiz_id from quizzes
  where course_id = v_course_id and title = '$TITLE';

  if v_quiz_id is not null then
    raise notice 'มีข้อสอบตัวอย่างอยู่แล้ว (%) — ไม่สร้างซ้ำ', v_quiz_id;
    return;
  end if;

  insert into quizzes (course_id, type, title, time_limit_min, status, created_by)
  values (v_course_id, 'pre_test', '$TITLE', 10, 'published', v_teacher_id)
  returning id into v_quiz_id;

  -- ข้อ 1: ปรนัย
  insert into quiz_questions (quiz_id, type, question, points, sort_order)
  values (v_quiz_id, 'multiple_choice',
          'เซนเซอร์ DHT22 ใช้วัดค่าอะไรได้บ้าง', 2, 1)
  returning id into v_q;
  insert into quiz_choices (question_id, choice_text, is_correct, sort_order) values
    (v_q, 'อุณหภูมิและความชื้น', true,  1),
    (v_q, 'ความเข้มแสงเท่านั้น', false, 2),
    (v_q, 'ระดับเสียงเท่านั้น',  false, 3),
    (v_q, 'ปริมาณฝุ่น PM2.5',    false, 4);

  -- ข้อ 2: ถูก/ผิด
  insert into quiz_questions (quiz_id, type, question, points, sort_order)
  values (v_quiz_id, 'true_false',
          'ค่าที่อ่านได้จากเซนเซอร์ควรสอบเทียบ (calibrate) ก่อนนำไปใช้อ้างอิง', 1, 2)
  returning id into v_q;
  insert into quiz_choices (question_id, choice_text, is_correct, sort_order) values
    (v_q, 'จริง', true,  1),
    (v_q, 'เท็จ', false, 2);

  -- ข้อ 3: อัตนัย (ไม่มีตัวเลือก ครูตรวจเอง)
  insert into quiz_questions (quiz_id, type, question, points, sort_order)
  values (v_quiz_id, 'short_answer',
          'อธิบายสั้น ๆ ว่าเหตุใดจึงต้องวัดค่าซ้ำหลายครั้งแล้วหาค่าเฉลี่ย', 3, 3);

  raise notice 'สร้างข้อสอบตัวอย่างแล้ว: %', v_quiz_id;
end \$\$;" < /dev/null

echo
echo "== 3. ตรวจผล (ต้องเห็น 3 ข้อ รวม 6 คะแนน สถานะ published)"
npx supabase db query --linked "
  select q.title, q.type, q.status,
         count(qq.id) as จำนวนข้อ,
         sum(qq.points) as คะแนนรวม
  from quizzes q
  join quiz_questions qq on qq.quiz_id = q.id
  where q.title = '$TITLE'
  group by q.id, q.title, q.type, q.status" < /dev/null

cat <<'EOF'

─────────────────────────────────────────────────────────────
ลบข้อสอบตัวอย่างทิ้งเมื่อไม่ต้องการแล้ว:

npx supabase db query --linked "
  delete from quiz_choices where question_id in (
    select id from quiz_questions where quiz_id in (
      select id from quizzes where title like '[ตัวอย่าง]%'));
  delete from quiz_questions where quiz_id in (
    select id from quizzes where title like '[ตัวอย่าง]%');
  delete from quizzes where title like '[ตัวอย่าง]%';"

⚠️ ลบไม่ได้ถ้ามีนักเรียนทำข้อสอบชุดนี้ไปแล้ว (จะติด foreign key จาก
   quiz_attempts/quiz_answers) — ซึ่งถูกต้องแล้ว ไม่ควรลบคำตอบของนักเรียนทิ้ง
─────────────────────────────────────────────────────────────
EOF
