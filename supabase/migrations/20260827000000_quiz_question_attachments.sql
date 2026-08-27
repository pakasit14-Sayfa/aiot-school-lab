-- =====================================================================
-- Real image/video attachments for exam questions. Previously
-- teacher_exam_builder_page.dart picked image/video bytes into memory
-- (_ExamQuestionMock.imageBytes/videoBytes) but QuizService.addQuizQuestion
-- had no attachment parameter at all — the bytes were silently dropped,
-- never uploaded. Mirrors the lesson-material-upload/-download pattern:
-- the private `quiz-attachments` Storage bucket is never touched
-- directly by clients, only via signed URLs minted by service-role Edge
-- Functions (quiz-attachment-upload / quiz-attachment-download).
-- =====================================================================

create type quiz_attachment_type as enum ('image', 'video');

create table quiz_question_attachments (
  id uuid primary key default gen_random_uuid(),
  question_id uuid not null references quiz_questions(id) on delete cascade,
  type quiz_attachment_type not null,
  storage_path varchar not null,
  file_name varchar,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create index idx_quiz_question_attachments_question
  on quiz_question_attachments(question_id);

create or replace function assert_quiz_question_upload_access(p_token text, p_question_id uuid)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_question quiz_questions%rowtype;
  v_quiz quizzes%rowtype;
  v_course courses%rowtype;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role <> 'teacher' then raise exception 'forbidden'; end if;

  select * into v_question from quiz_questions where id = p_question_id;
  if not found then raise exception 'question_not_found'; end if;

  select * into v_quiz from quizzes where id = v_question.quiz_id;
  select * into v_course from courses where id = v_quiz.course_id;
  if v_course.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;
  if not exists (
    select 1 from course_teachers ct
    where ct.course_id = v_quiz.course_id and ct.teacher_id = v_actor.user_id
  ) then raise exception 'forbidden'; end if;
end;
$$;

create or replace function add_quiz_question_attachment(
  p_token text,
  p_question_id uuid,
  p_type quiz_attachment_type,
  p_storage_path varchar,
  p_file_name varchar
)
returns table (attachment_id uuid)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_id uuid;
  v_next_sort integer;
begin
  perform assert_quiz_question_upload_access(p_token, p_question_id);

  select coalesce(max(sort_order) + 1, 0) into v_next_sort
  from quiz_question_attachments where question_id = p_question_id;

  insert into quiz_question_attachments (question_id, type, storage_path, file_name, sort_order)
  values (p_question_id, p_type, p_storage_path, p_file_name, v_next_sort)
  returning id into v_id;

  return query select v_id;
end;
$$;

create or replace function get_quiz_attachment_for_download(p_token text, p_attachment_id uuid)
returns table (storage_path text, file_name character varying)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_attachment quiz_question_attachments%rowtype;
  v_question quiz_questions%rowtype;
  v_quiz quizzes%rowtype;
  v_course courses%rowtype;
  v_is_member boolean := false;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;

  select * into v_attachment from quiz_question_attachments where id = p_attachment_id;
  if not found then raise exception 'attachment_not_found'; end if;

  select * into v_question from quiz_questions where id = v_attachment.question_id;
  select * into v_quiz from quizzes where id = v_question.quiz_id;
  select * into v_course from courses where id = v_quiz.course_id;
  if v_course.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;

  if v_actor.role = 'teacher' then
    v_is_member := exists (
      select 1 from course_teachers ct
      where ct.course_id = v_quiz.course_id and ct.teacher_id = v_actor.user_id
    );
  elsif v_actor.role = 'student' then
    v_is_member := v_quiz.status = 'published' and exists (
      select 1 from course_students cs
      where cs.course_id = v_quiz.course_id and cs.student_id = v_actor.user_id
    );
  elsif v_actor.role = 'school_admin' then
    v_is_member := true;
  end if;
  if not v_is_member then raise exception 'forbidden'; end if;

  return query
    select v_attachment.storage_path::text,
           coalesce(v_attachment.file_name, 'ไฟล์แนบ')::varchar;
end;
$$;

-- Extended to also return each question's attachments (id/type/file_name
-- only — never the storage_path, which resolves to a signed URL on
-- demand via get_quiz_attachment_for_download / the download Edge
-- Function, same as lesson materials). Postgres won't let CREATE OR
-- REPLACE change a function's RETURNS TABLE column set, so drop first.
drop function if exists get_quiz_for_student(text, uuid);

create function get_quiz_for_student(p_token text, p_quiz_id uuid)
returns table(
  quiz_id uuid, title character varying, type quiz_type, time_limit_min integer,
  question_id uuid, question_type question_type, question text, points numeric,
  sort_order integer, choices jsonb, attachments jsonb
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
    ), '[]'::json)::jsonb,
    coalesce((
      select json_agg(json_build_object('id', a.id, 'type', a.type, 'file_name', a.file_name) order by a.sort_order)
      from quiz_question_attachments a where a.question_id = qq.id
    ), '[]'::json)::jsonb
  from quiz_questions qq
  where qq.quiz_id = p_quiz_id
  order by qq.sort_order;
end;
$$;

revoke all on function assert_quiz_question_upload_access(text, uuid) from public;
revoke all on function add_quiz_question_attachment(text, uuid, quiz_attachment_type, varchar, varchar) from public;
revoke all on function get_quiz_attachment_for_download(text, uuid) from public;

grant execute on function assert_quiz_question_upload_access(text, uuid) to service_role;
grant execute on function add_quiz_question_attachment(text, uuid, quiz_attachment_type, varchar, varchar) to anon, authenticated;
grant execute on function get_quiz_attachment_for_download(text, uuid) to anon, authenticated, service_role;
grant execute on function get_quiz_for_student(text, uuid) to anon, authenticated;
