-- =====================================================================
-- Migration: 20260824100000_grades_assignment_and_rubric_link.sql
-- Description: 
--   1. Add assignment_id to public.grades table
--   2. Update create_grade RPC to optionally accept p_assignment_id
--   3. Update create_assignment / update_assignment RPCs to accept p_rubric_id
-- =====================================================================

-- 1. Add assignment_id to public.grades
alter table public.grades add column if not exists assignment_id uuid references public.assignments(id);
create index if not exists idx_grades_assignment on public.grades(assignment_id);

-- 2. Drop old signatures to prevent overload ambiguity
drop function if exists public.create_grade(text, uuid, uuid, numeric, numeric);
drop function if exists public.create_assignment(text, uuid, assignment_type, text, text, timestamptz);
drop function if exists public.update_assignment(text, uuid, text, text, timestamptz);

-- 3. Update create_grade RPC with optional p_assignment_id
create or replace function create_grade(
  p_token text,
  p_student_id uuid,
  p_course_id uuid,
  p_score numeric,
  p_max_score numeric,
  p_assignment_id uuid default null
)
returns table (grade_id uuid)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_course courses%rowtype;
  v_coi boolean := false;
  v_grade_id uuid;
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
  elsif v_actor.role <> 'school_admin' then
    raise exception 'forbidden';
  end if;

  if not exists (
    select 1 from course_students cs
    where cs.course_id = p_course_id and cs.student_id = p_student_id
  ) then
    raise exception 'student_not_enrolled';
  end if;

  if p_max_score is null or p_max_score <= 0 or p_score is null or p_score < 0 then
    raise exception 'invalid_score';
  end if;
  if p_score > p_max_score then
    raise exception 'score_exceeds_max';
  end if;

  if exists (
    select 1 from parent_links pl
    where pl.student_id = p_student_id
      and pl.parent_id = v_actor.user_id
      and pl.status = 'approved'
  ) then
    v_coi := true;
  end if;

  insert into grades (
    student_id, course_id, source_type, score, max_score,
    status, graded_by, graded_at, coi_flag, coi_detected_at,
    coi_review_status, assignment_id
  ) values (
    p_student_id, p_course_id, 'manual', p_score, p_max_score,
    'draft', v_actor.user_id, now(), v_coi,
    case when v_coi then now() else null end,
    case when v_coi then 'pending'::coi_review_status else null end,
    p_assignment_id
  ) returning id into v_grade_id;

  if v_coi then
    insert into audit_logs (
      school_id, user_id, acted_role, action, entity_type, entity_id, details
    ) values (
      v_actor.school_id, v_actor.user_id, v_actor.role,
      'grade.coi_detected', 'grades', v_grade_id::text,
      jsonb_build_object('student_id', p_student_id, 'course_id', p_course_id, 'score', p_score)
    );
  end if;

  insert into audit_logs (
    school_id, user_id, acted_role, action, entity_type, entity_id, details
  ) values (
    v_actor.school_id, v_actor.user_id, v_actor.role,
    'grade.created', 'grades', v_grade_id::text,
    jsonb_build_object('student_id', p_student_id, 'course_id', p_course_id, 'score', p_score, 'max_score', p_max_score, 'assignment_id', p_assignment_id)
  );

  return query select v_grade_id;
end;
$$;

revoke all on function create_grade(text, uuid, uuid, numeric, numeric, uuid) from public;
grant execute on function create_grade(text, uuid, uuid, numeric, numeric, uuid) to anon, authenticated;

-- 4. Update create_assignment RPC to accept p_rubric_id
create or replace function create_assignment(
  p_token text,
  p_course_id uuid,
  p_type assignment_type,
  p_title text,
  p_instructions text default null,
  p_due_at timestamptz default null,
  p_rubric_id uuid default null
)
returns table (assignment_id uuid)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_course courses%rowtype;
  v_assignment_id uuid;
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

  insert into assignments (course_id, type, title, instructions, due_at, is_group, rubric_id, created_by)
  values (p_course_id, p_type, trim(p_title), p_instructions, p_due_at, false, p_rubric_id, v_actor.user_id)
  returning id into v_assignment_id;

  return query select v_assignment_id;
end;
$$;

revoke all on function create_assignment(text, uuid, assignment_type, text, text, timestamptz, uuid) from public;
grant execute on function create_assignment(text, uuid, assignment_type, text, text, timestamptz, uuid) to anon, authenticated;

-- 5. Update update_assignment RPC to accept p_rubric_id
create or replace function update_assignment(
  p_token text,
  p_assignment_id uuid,
  p_title text default null,
  p_instructions text default null,
  p_due_at timestamptz default null,
  p_rubric_id uuid default null
)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_assignment assignments%rowtype;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role <> 'teacher' then raise exception 'forbidden'; end if;

  select * into v_assignment from assignments where id = p_assignment_id;
  if not found then raise exception 'assignment_not_found'; end if;

  if not exists (
    select 1 from courses c
    join course_teachers ct on ct.course_id = c.id
    where c.id = v_assignment.course_id
      and c.school_id = v_actor.school_id
      and ct.teacher_id = v_actor.user_id
  ) then raise exception 'forbidden'; end if;

  update assignments
  set
    title = case when p_title is not null and trim(p_title) <> '' then trim(p_title) else title end,
    instructions = coalesce(p_instructions, instructions),
    due_at = coalesce(p_due_at, due_at),
    rubric_id = coalesce(p_rubric_id, rubric_id)
  where id = p_assignment_id;
end;
$$;

revoke all on function update_assignment(text, uuid, text, text, timestamptz, uuid) from public;
grant execute on function update_assignment(text, uuid, text, text, timestamptz, uuid) to anon, authenticated;
