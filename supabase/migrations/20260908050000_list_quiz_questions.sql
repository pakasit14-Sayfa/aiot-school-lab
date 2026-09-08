-- Teachers had a way to CREATE quiz questions (add_quiz_question) but no
-- way to LIST the questions already in a quiz. teacher_question_bank_page.dart
-- worked around this by never populating BankQuestionSet.questions at all —
-- every quiz set showed a permanent "0 ข้อ" regardless of how many real
-- questions it actually had, and the "select questions to add to an exam"
-- feature had nothing to select. Mirrors add_quiz_question's own
-- teacher-owns-course authorization check.
create or replace function public.list_quiz_questions(p_token text, p_quiz_id uuid)
returns table(
  question_id uuid, type question_type, question text, points numeric,
  sort_order integer, choices jsonb
)
language plpgsql
security definer
set search_path to 'public', 'extensions'
as $function$
declare
  v_actor record;
  v_quiz quizzes%rowtype;
  v_course courses%rowtype;
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

  return query
  select
    qq.id, qq.type, qq.question, qq.points, qq.sort_order,
    coalesce(
      (
        select jsonb_agg(
          jsonb_build_object(
            'id', qc.id,
            'text', qc.choice_text,
            'is_correct', qc.is_correct
          )
          order by qc.sort_order
        )
        from quiz_choices qc
        where qc.question_id = qq.id
      ),
      '[]'::jsonb
    )
  from quiz_questions qq
  where qq.quiz_id = p_quiz_id
  order by qq.sort_order, qq.id;
end;
$function$;

revoke all on function public.list_quiz_questions(text, uuid) from public;
grant execute on function public.list_quiz_questions(text, uuid)
  to anon, authenticated, service_role;
