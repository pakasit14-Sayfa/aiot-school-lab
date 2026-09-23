-- =====================================================================
-- add_quiz_question: ปฏิเสธคำถามที่ชนิดกับข้อมูลขัดกันเอง
--
-- ทำไม (2026-09-23): หน้าคลังข้อสอบเทียบชนิดคำถามกับค่า 'essay' ที่ไม่มี
-- อยู่ใน enum question_type เลย (มีแค่ multiple_choice/true_false/
-- short_answer) เงื่อนไขจึงเป็นเท็จทุกครั้ง คำถามทุกข้อที่ดึงจากคลังกลาย
-- เป็นปรนัย ข้ออัตนัยไหลเข้า Exam Builder เป็นปรนัยที่ไม่มีตัวเลือกและมี
-- เฉลยชี้ไปที่ตัวเลือกที่ไม่มีอยู่ ด่านกันเผยแพร่ฝั่งแอปก็ปล่อยผ่านเพราะ
-- เช็คแค่ว่าเฉลยไม่เป็น null (ค่าเป็น 0) และ RPC นี้ก็รับทุกอย่าง —
-- ข้อมูลเสียไหลถึงตานักเรียนโดยไม่มี error ที่ใดเลยทั้งสาย
--
-- ฝั่งแอปแก้แล้ว แต่ด่านสุดท้ายต้องอยู่ที่นี่ด้วย เพราะ RPC นี้เป็นทางเดียว
-- ที่เขียน quiz_questions ได้ และมีตัวเรียกได้หลายตัวในอนาคต
-- =====================================================================

create or replace function add_quiz_question(
  p_token text,
  p_quiz_id uuid,
  p_type question_type,
  p_question text,
  p_points numeric default 1,
  p_choices jsonb default null -- [{"text": "...", "is_correct": true}, ...]
)
returns table (question_id uuid)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_quiz quizzes%rowtype;
  v_course courses%rowtype;
  v_question_id uuid;
  v_choice jsonb;
  v_choice_count int;
  v_correct_count int;
  v_blank_count int;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role <> 'teacher' then raise exception 'forbidden'; end if;

  select * into v_quiz from quizzes where id = p_quiz_id;
  if not found then raise exception 'quiz_not_found'; end if;
  if v_quiz.status <> 'draft' then raise exception 'quiz_already_published'; end if;

  select * into v_course from courses where id = v_quiz.course_id;
  if v_course.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;
  if not exists (
    select 1 from course_teachers ct
    where ct.course_id = v_quiz.course_id and ct.teacher_id = v_actor.user_id
  ) then raise exception 'forbidden'; end if;

  if trim(coalesce(p_question, '')) = '' then
    raise exception 'question_required';
  end if;

  -- ── ชนิดต้องสอดคล้องกับตัวเลือกที่ส่งมา ──────────────────────────
  select
    count(*),
    count(*) filter (where coalesce((c ->> 'is_correct')::bool, false)),
    count(*) filter (where trim(coalesce(c ->> 'text', '')) = '')
  into v_choice_count, v_correct_count, v_blank_count
  from jsonb_array_elements(coalesce(p_choices, '[]'::jsonb)) as c;

  if p_type = 'short_answer' then
    -- อัตนัยครูตรวจเอง ห้ามมีตัวเลือก ไม่ใช่ปล่อยให้เก็บเงียบ ๆ
    if v_choice_count > 0 then
      raise exception 'short_answer_takes_no_choices';
    end if;
  else
    if v_choice_count < 2 then
      raise exception 'choices_required';
    end if;
    if v_blank_count > 0 then
      raise exception 'choice_text_required';
    end if;
    if v_correct_count <> 1 then
      raise exception 'exactly_one_correct_choice_required';
    end if;
    if p_type = 'true_false' and v_choice_count <> 2 then
      raise exception 'true_false_needs_exactly_two_choices';
    end if;
  end if;

  insert into quiz_questions (quiz_id, type, question, points)
  values (p_quiz_id, p_type, trim(p_question), coalesce(p_points, 1))
  returning id into v_question_id;

  if p_choices is not null then
    for v_choice in select * from jsonb_array_elements(p_choices)
    loop
      insert into quiz_choices (question_id, choice_text, is_correct)
      values (
        v_question_id,
        v_choice ->> 'text',
        coalesce((v_choice ->> 'is_correct')::bool, false)
      );
    end loop;
  end if;

  return query select v_question_id;
end;
$$;

grant execute on function add_quiz_question(text, uuid, question_type, text, numeric, jsonb)
  to anon, authenticated, service_role;
