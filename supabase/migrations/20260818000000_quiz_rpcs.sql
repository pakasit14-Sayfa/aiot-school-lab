-- =====================================================================
-- ASM-1/2/3/4: แบบทดสอบก่อน-หลังเรียน (pretest/posttest) — ตาราง
-- quizzes/quiz_questions/quiz_choices/quiz_attempts/quiz_answers มีอยู่
-- แล้วตั้งแต่ initial_schema แต่ไม่เคยมี RPC ให้ใช้งานเลย เพิ่มเฉพาะชั้น
-- RPC ตามแพทเทิร์นเดียวกับ assignments_core.sql
--
-- Scope รอบนี้: ฝั่งครูมีแค่ RPC (ยังไม่มีหน้าสร้างแบบทดสอบใน Flutter,
-- ใช้ seed.sql/SQL ตรงๆ ก่อน) ฝั่งนักเรียนมี RPC ครบสำหรับทำแบบทดสอบจริง
-- =====================================================================

create or replace function create_quiz(
  p_token text,
  p_course_id uuid,
  p_type quiz_type,
  p_title text,
  p_lesson_id uuid default null,
  p_time_limit_min int default null
)
returns table (quiz_id uuid)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_course courses%rowtype;
  v_quiz_id uuid;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role <> 'teacher' then raise exception 'forbidden'; end if;

  select * into v_course from courses where id = p_course_id;
  if not found then raise exception 'course_not_found'; end if;
  if v_course.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;
  if not exists (
    select 1 from course_teachers ct
    where ct.course_id = p_course_id and ct.teacher_id = v_actor.user_id
  ) then raise exception 'forbidden'; end if;

  if trim(coalesce(p_title, '')) = '' then
    raise exception 'title_required';
  end if;

  insert into quizzes (course_id, lesson_id, type, title, time_limit_min, created_by)
  values (p_course_id, p_lesson_id, p_type, trim(p_title), p_time_limit_min, v_actor.user_id)
  returning id into v_quiz_id;

  return query select v_quiz_id;
end;
$$;

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

create or replace function publish_quiz(p_token text, p_quiz_id uuid)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_quiz quizzes%rowtype;
  v_course courses%rowtype;
  v_unanswered_count int;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role <> 'teacher' then raise exception 'forbidden'; end if;

  select * into v_quiz from quizzes where id = p_quiz_id;
  if not found then raise exception 'quiz_not_found'; end if;

  select * into v_course from courses where id = v_quiz.course_id;
  if v_course.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;
  if not exists (
    select 1 from course_teachers ct
    where ct.course_id = v_quiz.course_id and ct.teacher_id = v_actor.user_id
  ) then raise exception 'forbidden'; end if;

  if not exists (select 1 from quiz_questions where quiz_id = p_quiz_id) then
    raise exception 'quiz_has_no_questions';
  end if;

  -- ASM-1 exception flow: ทุกคำถามแบบเลือกตอบ/ถูกผิดต้องมีเฉลยก่อนเผยแพร่
  select count(*) into v_unanswered_count
  from quiz_questions q
  where q.quiz_id = p_quiz_id
    and q.type in ('multiple_choice', 'true_false')
    and not exists (
      select 1 from quiz_choices c where c.question_id = q.id and c.is_correct = true
    );
  if v_unanswered_count > 0 then
    raise exception 'question_missing_correct_choice';
  end if;

  update quizzes set status = 'published' where id = p_quiz_id;
end;
$$;

create or replace function list_course_quizzes(p_token text, p_course_id uuid)
returns table (
  quiz_id uuid,
  type quiz_type,
  title varchar,
  time_limit_min int,
  status publish_status,
  lesson_id uuid
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_course courses%rowtype;
  v_is_student boolean := false;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;

  select * into v_course from courses where id = p_course_id;
  if not found then raise exception 'course_not_found'; end if;
  if v_course.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;

  if v_actor.role = 'teacher' then
    if not exists (
      select 1 from course_teachers ct
      where ct.course_id = p_course_id and ct.teacher_id = v_actor.user_id
    ) then raise exception 'forbidden'; end if;
  elsif v_actor.role = 'student' then
    v_is_student := true;
    if not exists (
      select 1 from course_students cs
      where cs.course_id = p_course_id and cs.student_id = v_actor.user_id
    ) then raise exception 'forbidden'; end if;
  elsif v_actor.role <> 'school_admin' then
    raise exception 'forbidden';
  end if;

  return query
  select q.id, q.type, q.title, q.time_limit_min, q.status, q.lesson_id
  from quizzes q
  where q.course_id = p_course_id
    and (v_is_student is not true or q.status = 'published')
  order by q.type, q.title;
end;
$$;

create or replace function get_quiz_for_student(p_token text, p_quiz_id uuid)
returns table (
  quiz_id uuid,
  title varchar,
  type quiz_type,
  time_limit_min int,
  question_id uuid,
  question_type question_type,
  question text,
  points numeric,
  sort_order int,
  choices jsonb
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_quiz quizzes%rowtype;
  v_course courses%rowtype;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role <> 'student' then raise exception 'forbidden'; end if;

  select * into v_quiz from quizzes where id = p_quiz_id;
  if not found or v_quiz.status <> 'published' then
    raise exception 'quiz_not_found';
  end if;

  select * into v_course from courses where id = v_quiz.course_id;
  if v_course.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;
  if not exists (
    select 1 from course_students cs
    where cs.course_id = v_quiz.course_id and cs.student_id = v_actor.user_id
  ) then raise exception 'forbidden'; end if;

  -- ห้ามส่ง is_correct กลับให้นักเรียนเด็ดขาด
  return query
  select
    v_quiz.id, v_quiz.title, v_quiz.type, v_quiz.time_limit_min,
    qq.id, qq.type, qq.question, qq.points, qq.sort_order,
    coalesce((
      select json_agg(json_build_object('id', c.id, 'text', c.choice_text) order by c.sort_order)
      from quiz_choices c where c.question_id = qq.id
    ), '[]'::json)::jsonb
  from quiz_questions qq
  where qq.quiz_id = p_quiz_id
  order by qq.sort_order;
end;
$$;

create or replace function start_quiz_attempt(p_token text, p_quiz_id uuid)
returns table (attempt_id uuid, started_at timestamptz)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_quiz quizzes%rowtype;
  v_course courses%rowtype;
  v_attempt quiz_attempts%rowtype;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role <> 'student' then raise exception 'forbidden'; end if;

  select * into v_quiz from quizzes where id = p_quiz_id;
  if not found or v_quiz.status <> 'published' then
    raise exception 'quiz_not_found';
  end if;

  select * into v_course from courses where id = v_quiz.course_id;
  if v_course.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;
  if not exists (
    select 1 from course_students cs
    where cs.course_id = v_quiz.course_id and cs.student_id = v_actor.user_id
  ) then raise exception 'forbidden'; end if;

  -- ทำต่อจาก attempt เดิมที่ยังไม่ส่ง แทนสร้างใหม่ซ้ำ (idempotent)
  select * into v_attempt
  from quiz_attempts
  where quiz_id = p_quiz_id and student_id = v_actor.user_id and submitted_at is null
  order by started_at desc
  limit 1;

  if not found then
    insert into quiz_attempts (quiz_id, student_id)
    values (p_quiz_id, v_actor.user_id)
    returning * into v_attempt;
  end if;

  return query select v_attempt.id, v_attempt.started_at;
end;
$$;

create or replace function get_my_latest_quiz_attempt(p_token text, p_quiz_id uuid)
returns table (
  attempt_id uuid,
  started_at timestamptz,
  submitted_at timestamptz,
  auto_score numeric
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role <> 'student' then raise exception 'forbidden'; end if;

  return query
  select a.id, a.started_at, a.submitted_at, a.auto_score
  from quiz_attempts a
  where a.quiz_id = p_quiz_id and a.student_id = v_actor.user_id
  order by a.started_at desc
  limit 1;
end;
$$;

create or replace function save_quiz_answer(
  p_token text,
  p_attempt_id uuid,
  p_question_id uuid,
  p_answer jsonb
)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_attempt quiz_attempts%rowtype;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role <> 'student' then raise exception 'forbidden'; end if;

  select * into v_attempt from quiz_attempts where id = p_attempt_id;
  if not found then raise exception 'attempt_not_found'; end if;
  if v_attempt.student_id is distinct from v_actor.user_id then
    raise exception 'forbidden';
  end if;
  if v_attempt.submitted_at is not null then
    raise exception 'attempt_already_submitted';
  end if;

  if exists (select 1 from quiz_answers where attempt_id = p_attempt_id and question_id = p_question_id) then
    update quiz_answers set answer = p_answer
    where attempt_id = p_attempt_id and question_id = p_question_id;
  else
    insert into quiz_answers (attempt_id, question_id, answer)
    values (p_attempt_id, p_question_id, p_answer);
  end if;
end;
$$;

create or replace function submit_quiz_attempt(p_token text, p_attempt_id uuid)
returns table (auto_score numeric)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_attempt quiz_attempts%rowtype;
  v_answer record;
  v_correct_choice_ids uuid[];
  v_submitted_choice_id uuid;
  v_is_correct boolean;
  v_score numeric;
  v_total_score numeric := 0;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role <> 'student' then raise exception 'forbidden'; end if;

  select * into v_attempt from quiz_attempts where id = p_attempt_id;
  if not found then raise exception 'attempt_not_found'; end if;
  if v_attempt.student_id is distinct from v_actor.user_id then
    raise exception 'forbidden';
  end if;
  if v_attempt.submitted_at is not null then
    raise exception 'attempt_already_submitted';
  end if;

  -- ASM-4: ตรวจอัตโนมัติเฉพาะปรนัย (multiple_choice/true_false) —
  -- short_answer เว้น is_correct/score ไว้เป็น null รอครูตรวจภายหลัง (BR1)
  for v_answer in
    select a.id as answer_id, a.answer, q.id as question_id, q.type, q.points
    from quiz_answers a
    join quiz_questions q on q.id = a.question_id
    where a.attempt_id = p_attempt_id
  loop
    if v_answer.type in ('multiple_choice', 'true_false') then
      select array_agg(id) into v_correct_choice_ids
      from quiz_choices where question_id = v_answer.question_id and is_correct = true;

      v_submitted_choice_id := (v_answer.answer ->> 'choice_id')::uuid;
      v_is_correct := v_submitted_choice_id = any(v_correct_choice_ids);
      v_score := case when v_is_correct then v_answer.points else 0 end;

      update quiz_answers set is_correct = v_is_correct, score = v_score
      where id = v_answer.answer_id;

      v_total_score := v_total_score + v_score;
    end if;
  end loop;

  update quiz_attempts set submitted_at = now(), auto_score = v_total_score
  where id = p_attempt_id;

  return query select v_total_score;
end;
$$;

revoke all on function create_quiz(text, uuid, quiz_type, text, uuid, int) from public;
revoke all on function add_quiz_question(text, uuid, question_type, text, numeric, jsonb) from public;
revoke all on function publish_quiz(text, uuid) from public;
revoke all on function list_course_quizzes(text, uuid) from public;
revoke all on function get_quiz_for_student(text, uuid) from public;
revoke all on function start_quiz_attempt(text, uuid) from public;
revoke all on function get_my_latest_quiz_attempt(text, uuid) from public;
revoke all on function save_quiz_answer(text, uuid, uuid, jsonb) from public;
revoke all on function submit_quiz_attempt(text, uuid) from public;

grant execute on function create_quiz(text, uuid, quiz_type, text, uuid, int) to anon, authenticated;
grant execute on function add_quiz_question(text, uuid, question_type, text, numeric, jsonb) to anon, authenticated;
grant execute on function publish_quiz(text, uuid) to anon, authenticated;
grant execute on function list_course_quizzes(text, uuid) to anon, authenticated;
grant execute on function get_quiz_for_student(text, uuid) to anon, authenticated;
grant execute on function start_quiz_attempt(text, uuid) to anon, authenticated;
grant execute on function get_my_latest_quiz_attempt(text, uuid) to anon, authenticated;
grant execute on function save_quiz_answer(text, uuid, uuid, jsonb) to anon, authenticated;
grant execute on function submit_quiz_attempt(text, uuid) to anon, authenticated;
