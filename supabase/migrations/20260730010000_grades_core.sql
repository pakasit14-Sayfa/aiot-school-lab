-- =====================================================================
-- Grades — Slice 3 (manual grade entry, independent of Assignments/
-- Quizzes which don't exist yet). grades.source_type/submission_id/
-- quiz_attempt_id are all nullable, so this adds a third, honest path:
-- a teacher enters a score directly for a student in a course.
--
-- Conflict of Interest (Decision Log): a teacher may grade/confirm
-- their own child's grade, but the system must auto-flag it via
-- parent_links, log it to audit_logs, and coi_flag must never be
-- cleared by the API once set.
-- =====================================================================

alter type grade_source add value if not exists 'manual';

create or replace function create_grade(
  p_token text,
  p_student_id uuid,
  p_course_id uuid,
  p_score numeric,
  p_max_score numeric
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

  v_coi := exists (
    select 1 from parent_links pl
    where pl.parent_id = v_actor.user_id
      and pl.student_id = p_student_id
      and pl.status = 'approved'
  );

  insert into grades (
    student_id, course_id, source_type, score, max_score, status,
    graded_by, coi_flag, coi_detected_at, coi_review_status
  ) values (
    p_student_id, p_course_id, 'manual', p_score, p_max_score, 'draft',
    v_actor.user_id,
    v_coi,
    case when v_coi then now() else null end,
    case when v_coi then 'pending'::coi_review_status else null end
  )
  returning id into v_grade_id;

  if v_coi then
    insert into audit_logs (school_id, user_id, acted_role, action, entity_type, entity_id)
    values (v_actor.school_id, v_actor.user_id, v_actor.role, 'grade.coi_detected', 'grades', v_grade_id::text);
  end if;

  return query select v_grade_id;
end;
$$;

create or replace function update_grade(
  p_token text,
  p_grade_id uuid,
  p_score numeric,
  p_max_score numeric
)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_grade grades%rowtype;
  v_course courses%rowtype;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;

  select * into v_grade from grades where id = p_grade_id;
  if not found then raise exception 'grade_not_found'; end if;
  if v_grade.status <> 'draft' then raise exception 'grade_already_confirmed'; end if;

  select * into v_course from courses where id = v_grade.course_id;
  if v_course.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;

  if v_actor.role = 'teacher' then
    if not exists (
      select 1 from course_teachers ct
      where ct.course_id = v_grade.course_id and ct.teacher_id = v_actor.user_id
    ) then raise exception 'forbidden'; end if;
  elsif v_actor.role <> 'school_admin' then
    raise exception 'forbidden';
  end if;

  if p_max_score is null or p_max_score <= 0 or p_score is null or p_score < 0 then
    raise exception 'invalid_score';
  end if;

  update grades set score = p_score, max_score = p_max_score
  where id = p_grade_id;
end;
$$;

create or replace function confirm_grade(p_token text, p_grade_id uuid)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_grade grades%rowtype;
  v_course courses%rowtype;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;

  select * into v_grade from grades where id = p_grade_id;
  if not found then raise exception 'grade_not_found'; end if;

  select * into v_course from courses where id = v_grade.course_id;
  if v_course.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;

  if v_actor.role = 'teacher' then
    if not exists (
      select 1 from course_teachers ct
      where ct.course_id = v_grade.course_id and ct.teacher_id = v_actor.user_id
    ) then raise exception 'forbidden'; end if;
  elsif v_actor.role <> 'school_admin' then
    raise exception 'forbidden';
  end if;

  update grades
  set status = 'confirmed', confirmed_by = v_actor.user_id, confirmed_at = now()
  where id = p_grade_id;

  insert into audit_logs (school_id, user_id, acted_role, action, entity_type, entity_id)
  values (v_course.school_id, v_actor.user_id, v_actor.role, 'grade.confirmed', 'grades', p_grade_id::text);
end;
$$;

create or replace function list_course_grades(p_token text, p_course_id uuid)
returns table (
  grade_id uuid,
  student_id uuid,
  student_first_name varchar,
  student_last_name varchar,
  score numeric,
  max_score numeric,
  status grade_status,
  coi_flag boolean,
  coi_review_status coi_review_status,
  confirmed_at timestamptz
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_course courses%rowtype;
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

  return query
  select g.id, g.student_id, u.first_name, u.last_name, g.score, g.max_score,
         g.status, g.coi_flag, g.coi_review_status, g.confirmed_at
  from grades g
  join users u on u.id = g.student_id
  where g.course_id = p_course_id
  order by u.first_name, u.last_name;
end;
$$;

create or replace function list_my_grades(p_token text)
returns table (
  grade_id uuid,
  course_id uuid,
  subject_name varchar,
  score numeric,
  max_score numeric,
  confirmed_at timestamptz
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
  select g.id, g.course_id, c.subject_name, g.score, g.max_score, g.confirmed_at
  from grades g
  join courses c on c.id = g.course_id
  where g.student_id = v_actor.user_id
    and g.status = 'confirmed'
  order by g.confirmed_at desc;
end;
$$;

create or replace function list_pending_coi_grades(p_token text)
returns table (
  grade_id uuid,
  student_id uuid,
  student_first_name varchar,
  student_last_name varchar,
  course_id uuid,
  subject_name varchar,
  graded_by uuid,
  score numeric,
  max_score numeric,
  status grade_status
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
  if v_actor.role <> 'school_admin' then raise exception 'forbidden'; end if;

  return query
  select g.id, g.student_id, u.first_name, u.last_name, g.course_id, c.subject_name,
         g.graded_by, g.score, g.max_score, g.status
  from grades g
  join users u on u.id = g.student_id
  join courses c on c.id = g.course_id
  where c.school_id = v_actor.school_id
    and g.coi_flag = true
    and g.coi_review_status = 'pending'
  order by g.coi_detected_at;
end;
$$;

create or replace function review_coi_grade(p_token text, p_grade_id uuid)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_grade grades%rowtype;
  v_course courses%rowtype;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role <> 'school_admin' then raise exception 'forbidden'; end if;

  select * into v_grade from grades where id = p_grade_id;
  if not found then raise exception 'grade_not_found'; end if;

  select * into v_course from courses where id = v_grade.course_id;
  if v_course.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;

  update grades
  set coi_review_status = 'reviewed', coi_reviewed_by = v_actor.user_id, coi_reviewed_at = now()
  where id = p_grade_id;

  insert into audit_logs (school_id, user_id, acted_role, action, entity_type, entity_id)
  values (v_course.school_id, v_actor.user_id, v_actor.role, 'grade.coi_reviewed', 'grades', p_grade_id::text);
end;
$$;

revoke all on function create_grade(text, uuid, uuid, numeric, numeric) from public;
revoke all on function update_grade(text, uuid, numeric, numeric) from public;
revoke all on function confirm_grade(text, uuid) from public;
revoke all on function list_course_grades(text, uuid) from public;
revoke all on function list_my_grades(text) from public;
revoke all on function list_pending_coi_grades(text) from public;
revoke all on function review_coi_grade(text, uuid) from public;

grant execute on function create_grade(text, uuid, uuid, numeric, numeric) to anon, authenticated;
grant execute on function update_grade(text, uuid, numeric, numeric) to anon, authenticated;
grant execute on function confirm_grade(text, uuid) to anon, authenticated;
grant execute on function list_course_grades(text, uuid) to anon, authenticated;
grant execute on function list_my_grades(text) to anon, authenticated;
grant execute on function list_pending_coi_grades(text) to anon, authenticated;
grant execute on function review_coi_grade(text, uuid) to anon, authenticated;
