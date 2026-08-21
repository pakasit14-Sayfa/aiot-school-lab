-- =====================================================================
-- G-Score (Gamification) — LRN-11/LRN-12. Previously a UI-only prototype
-- (teacher_gscore_confirm_page.dart) with an honest banner saying no
-- table/RPC existed yet. This adds the real thing.
--
-- LRN-11: the system auto-accumulates *pending* points when a student
-- completes a lesson (mark_lesson_complete) or submits an assignment on
-- time (submit_assignment, first submission only, before due_at). Points
-- are hooked directly into those two existing RPCs rather than a trigger,
-- so the awarding logic stays visible next to the event that causes it.
--
-- LRN-12: points sit as 'pending' until a teacher confirms them via this
-- migration's confirm_g_score — matches the "ครูยืนยันขั้นสุดท้ายเสมอ"
-- principle already used for regular grades (grades.status
-- draft->confirmed in 20260730010000_grades_core.sql). Students only ever
-- see confirmed points (list_my_g_score filters status='confirmed'), same
-- pattern as list_my_grades.
--
-- Point values (10 / 15) are placeholder gamification tuning, not derived
-- from any spec — easy to change later, just numbers in this file.
-- =====================================================================

do $$ begin
  create type g_score_source as enum ('lesson_completed', 'assignment_on_time');
exception when duplicate_object then null;
end $$;

do $$ begin
  create type g_score_status as enum ('pending', 'confirmed');
exception when duplicate_object then null;
end $$;

create table if not exists g_score_entries (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references users(id),
  course_id uuid not null references courses(id),
  source g_score_source not null,
  source_id uuid not null,
  points numeric not null,
  status g_score_status not null default 'pending',
  created_at timestamptz not null default now(),
  confirmed_by uuid references users(id),
  confirmed_at timestamptz,
  unique (student_id, source, source_id)
);

alter table g_score_entries enable row level security;

-- ---------------------------------------------------------------------
-- Hook into mark_lesson_complete (redefines the function from
-- 20260724000000_classroom_core.sql — create or replace, not editing
-- that file). Only awards points the first time a lesson is completed
-- (the unique constraint on (student_id, source, source_id) also
-- protects against a race, ON CONFLICT DO NOTHING).
-- ---------------------------------------------------------------------
create or replace function mark_lesson_complete(p_token text, p_lesson_id uuid)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_lesson lessons%rowtype;
  v_was_completed boolean;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role <> 'student' then raise exception 'forbidden'; end if;

  select * into v_lesson from lessons where id = p_lesson_id;
  if not found or v_lesson.status <> 'published' then
    raise exception 'lesson_not_found';
  end if;

  if not exists (
    select 1 from course_students cs
    where cs.course_id = v_lesson.course_id and cs.student_id = v_actor.user_id
  ) then raise exception 'forbidden'; end if;

  select completed into v_was_completed
  from lesson_progress
  where lesson_id = p_lesson_id and student_id = v_actor.user_id;

  insert into lesson_progress (lesson_id, student_id, progress_pct, completed, completed_at, updated_at)
  values (p_lesson_id, v_actor.user_id, 100, true, now(), now())
  on conflict (lesson_id, student_id) do update
  set progress_pct = 100, completed = true, completed_at = now(), updated_at = now();

  if coalesce(v_was_completed, false) is not true then
    insert into g_score_entries (student_id, course_id, source, source_id, points)
    values (v_actor.user_id, v_lesson.course_id, 'lesson_completed', p_lesson_id, 10)
    on conflict (student_id, source, source_id) do nothing;
  end if;
end;
$$;

-- ---------------------------------------------------------------------
-- Hook into submit_assignment (redefines the function from
-- 20260731000000_assignments_core.sql). Only awards points on the FIRST
-- submission (v_new_version = 1) and only if it lands before due_at (an
-- assignment with no due_at is treated as always-on-time).
-- ---------------------------------------------------------------------
create or replace function submit_assignment(
  p_token text,
  p_assignment_id uuid,
  p_content text
)
returns table (submission_id uuid, version int)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_assignment assignments%rowtype;
  v_submission submissions%rowtype;
  v_new_version int;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role <> 'student' then raise exception 'forbidden'; end if;

  select * into v_assignment from assignments where id = p_assignment_id;
  if not found or v_assignment.status <> 'published' then
    raise exception 'assignment_not_found';
  end if;

  if not exists (
    select 1 from course_students cs
    where cs.course_id = v_assignment.course_id and cs.student_id = v_actor.user_id
  ) then raise exception 'forbidden'; end if;

  select * into v_submission
  from submissions
  where assignment_id = p_assignment_id and student_id = v_actor.user_id;

  if not found then
    insert into submissions (assignment_id, student_id, status, current_version)
    values (p_assignment_id, v_actor.user_id, 'submitted', 1)
    returning * into v_submission;
    v_new_version := 1;
  else
    v_new_version := v_submission.current_version + 1;
    update submissions
    set current_version = v_new_version, status = 'submitted', submitted_at = now()
    where id = v_submission.id;
  end if;

  insert into submission_versions (submission_id, version, content, submitted_by)
  values (v_submission.id, v_new_version, p_content, v_actor.user_id);

  if v_new_version = 1 and (v_assignment.due_at is null or now() <= v_assignment.due_at) then
    insert into g_score_entries (student_id, course_id, source, source_id, points)
    values (v_actor.user_id, v_assignment.course_id, 'assignment_on_time', p_assignment_id, 15)
    on conflict (student_id, source, source_id) do nothing;
  end if;

  return query select v_submission.id, v_new_version;
end;
$$;

-- ---------------------------------------------------------------------
-- Teacher-facing: pending entries for students in courses they teach.
-- ---------------------------------------------------------------------
create or replace function list_pending_g_score(p_token text)
returns table (
  entry_id uuid,
  student_id uuid,
  student_first_name varchar,
  student_last_name varchar,
  course_id uuid,
  subject_name varchar,
  source g_score_source,
  points numeric,
  created_at timestamptz
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
  if v_actor.role <> 'teacher' then raise exception 'forbidden'; end if;

  return query
  select g.id, g.student_id, u.first_name, u.last_name, g.course_id, c.subject_name,
         g.source, g.points, g.created_at
  from g_score_entries g
  join courses c on c.id = g.course_id
  join users u on u.id = g.student_id
  join course_teachers ct on ct.course_id = g.course_id and ct.teacher_id = v_actor.user_id
  where g.status = 'pending'
  order by g.created_at asc;
end;
$$;

create or replace function confirm_g_score(p_token text, p_entry_id uuid)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_entry g_score_entries%rowtype;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role <> 'teacher' then raise exception 'forbidden'; end if;

  select * into v_entry from g_score_entries where id = p_entry_id;
  if not found then raise exception 'entry_not_found'; end if;
  if v_entry.status <> 'pending' then raise exception 'already_confirmed'; end if;

  if not exists (
    select 1 from course_teachers ct
    where ct.course_id = v_entry.course_id and ct.teacher_id = v_actor.user_id
  ) then raise exception 'forbidden'; end if;

  update g_score_entries
  set status = 'confirmed', confirmed_by = v_actor.user_id, confirmed_at = now()
  where id = p_entry_id;
end;
$$;

-- ---------------------------------------------------------------------
-- Student-facing: only ever see confirmed points.
-- ---------------------------------------------------------------------
create or replace function list_my_g_score(p_token text)
returns table (
  entry_id uuid,
  course_id uuid,
  subject_name varchar,
  source g_score_source,
  points numeric,
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
  select g.id, g.course_id, c.subject_name, g.source, g.points, g.confirmed_at
  from g_score_entries g
  join courses c on c.id = g.course_id
  where g.student_id = v_actor.user_id and g.status = 'confirmed'
  order by g.confirmed_at desc;
end;
$$;

revoke all on function mark_lesson_complete(text, uuid) from public;
revoke all on function submit_assignment(text, uuid, text) from public;
revoke all on function list_pending_g_score(text) from public;
revoke all on function confirm_g_score(text, uuid) from public;
revoke all on function list_my_g_score(text) from public;

grant execute on function mark_lesson_complete(text, uuid) to anon, authenticated;
grant execute on function submit_assignment(text, uuid, text) to anon, authenticated;
grant execute on function list_pending_g_score(text) to anon, authenticated;
grant execute on function confirm_g_score(text, uuid) to anon, authenticated;
grant execute on function list_my_g_score(text) to anon, authenticated;
