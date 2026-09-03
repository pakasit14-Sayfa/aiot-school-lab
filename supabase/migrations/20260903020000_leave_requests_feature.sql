-- =====================================================================
-- Real "แจ้งลาเรียน" (leave request) feature. The previous "done" claim
-- (docs/handoff/agy-brief-parent-teacher-leave-request-feature.md) was
-- false — grep of every migration confirmed leave_requests/
-- submit_leave_request/review_leave_request never existed, and
-- teacher_leave_approval_page.dart called `.from('leave_requests')`
-- directly (silently empty forever under this project's deny-all RLS).
--
-- Deviates from the original brief on one point: the brief specified
-- the `leave_attachments` bucket as "Public read" — that violates hard
-- rule 3 (no direct client Storage access, signed URLs via Edge
-- Functions only). Switched to private + signed URLs, mirroring
-- submission-attachments/lesson-materials exactly. The bucket already
-- existed in production (public=true) from the earlier broken attempt;
-- flipped to private here and its old public-access policies dropped.
-- =====================================================================

set search_path = public, extensions;

create table if not exists leave_requests (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references schools(id),
  student_id uuid not null references users(id),
  parent_id uuid not null references users(id),
  leave_type text not null check (leave_type in ('sick', 'personal')),
  start_date date not null,
  end_date date not null,
  reason text,
  attachment_url text,
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  reviewed_by uuid references users(id),
  review_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (end_date >= start_date)
);

alter table leave_requests enable row level security;

-- The table (and these 2 policies) already existed in production via
-- undocumented direct SQL, never a migration file — same drift pattern
-- found on other tables this session. Dropped: access goes through RPC
-- only, per this project's convention (deny-all RLS, zero policies).
drop policy if exists "Parents can view their own submitted leave requests" on leave_requests;
drop policy if exists "Teachers can view leave requests in their school" on leave_requests;

update storage.buckets set public = false where id = 'leave_attachments';
drop policy if exists "Public Access" on storage.objects;
drop policy if exists "Authenticated users can upload" on storage.objects;

-- ---------------------------------------------------------------------
-- Parent submits a leave request for their linked student.
-- ---------------------------------------------------------------------
create or replace function submit_leave_request(
  p_token text,
  p_student_id uuid,
  p_leave_type text,
  p_start_date date,
  p_end_date date,
  p_reason text default null,
  p_attachment_url text default null
)
returns uuid
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_school_id uuid;
  v_id uuid;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role <> 'parent' then raise exception 'forbidden'; end if;

  if not exists (
    select 1 from parent_links pl
    where pl.parent_id = v_actor.user_id
      and pl.student_id = p_student_id
      and pl.status = 'approved'
  ) then
    raise exception 'forbidden';
  end if;

  if p_leave_type not in ('sick', 'personal') then
    raise exception 'invalid_leave_type';
  end if;
  if p_end_date < p_start_date then
    raise exception 'invalid_date_range';
  end if;

  select school_id into v_school_id from users where id = p_student_id;

  insert into leave_requests (
    school_id, student_id, parent_id, leave_type, start_date, end_date, reason, attachment_url
  ) values (
    v_school_id, p_student_id, v_actor.user_id, p_leave_type, p_start_date, p_end_date, p_reason, p_attachment_url
  )
  returning id into v_id;

  return v_id;
end;
$$;

-- ---------------------------------------------------------------------
-- Teacher/school_admin inbox: pending (or any status) requests in their
-- own school, with the student's real name.
-- ---------------------------------------------------------------------
create or replace function list_leave_requests_for_review(
  p_token text,
  p_status text default 'pending'
)
returns table (
  leave_id uuid,
  student_id uuid,
  student_name text,
  leave_type text,
  start_date date,
  end_date date,
  reason text,
  attachment_url text,
  status text,
  review_note text,
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
  if v_actor.role not in ('teacher', 'school_admin', 'executive') then
    raise exception 'forbidden';
  end if;

  return query
    select lr.id, lr.student_id,
      (u.first_name || ' ' || u.last_name)::text as student_name,
      lr.leave_type::text, lr.start_date, lr.end_date, lr.reason, lr.attachment_url,
      lr.status::text, lr.review_note, lr.created_at
    from leave_requests lr
    join users u on u.id = lr.student_id
    where lr.school_id = v_actor.school_id
      and (p_status is null or lr.status = p_status)
    order by lr.created_at desc;
end;
$$;

-- ---------------------------------------------------------------------
-- Parent: status of their own submitted requests for one student.
-- ---------------------------------------------------------------------
create or replace function list_my_leave_requests(
  p_token text,
  p_student_id uuid
)
returns table (
  leave_id uuid,
  leave_type text,
  start_date date,
  end_date date,
  reason text,
  status text,
  review_note text,
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
  if v_actor.role <> 'parent' then raise exception 'forbidden'; end if;

  if not exists (
    select 1 from parent_links pl
    where pl.parent_id = v_actor.user_id
      and pl.student_id = p_student_id
      and pl.status = 'approved'
  ) then
    raise exception 'forbidden';
  end if;

  return query
    select lr.id, lr.leave_type::text, lr.start_date, lr.end_date, lr.reason, lr.status::text, lr.review_note, lr.created_at
    from leave_requests lr
    where lr.student_id = p_student_id
      and lr.parent_id = v_actor.user_id
    order by lr.created_at desc;
end;
$$;

-- ---------------------------------------------------------------------
-- Teacher/school_admin approves or rejects. On approval, marks the
-- student 'excused' across the date range in every attendance table
-- that actually has a row-worthy target for them (course attendance for
-- every enrolled course; homeroom attendance only if a student_profiles
-- row exists to resolve academic_year_id/grade_level/room — skipped,
-- not errored, when absent, since not every student has one yet).
-- ---------------------------------------------------------------------
create or replace function review_leave_request(
  p_token text,
  p_leave_id uuid,
  p_status text,
  p_review_note text default null
)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_leave leave_requests%rowtype;
  v_profile record;
  v_course record;
  v_day date;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('teacher', 'school_admin', 'executive') then
    raise exception 'forbidden';
  end if;

  if p_status not in ('approved', 'rejected') then
    raise exception 'invalid_status';
  end if;

  select * into v_leave from leave_requests where id = p_leave_id;
  if not found then raise exception 'leave_request_not_found'; end if;
  if v_leave.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;
  if v_leave.status <> 'pending' then
    raise exception 'already_reviewed';
  end if;

  update leave_requests
    set status = p_status,
        reviewed_by = v_actor.user_id,
        review_note = p_review_note,
        updated_at = now()
    where id = p_leave_id;

  if p_status = 'approved' then
    for v_course in
      select cs.course_id from course_students cs where cs.student_id = v_leave.student_id
    loop
      v_day := v_leave.start_date;
      while v_day <= v_leave.end_date loop
        insert into attendance_records (course_id, student_id, class_date, status, marked_by, marked_at, note)
        values (v_course.course_id, v_leave.student_id, v_day, 'excused', v_actor.user_id, now(), 'อนุมัติใบลาอัตโนมัติ')
        on conflict (course_id, student_id, class_date)
        do update set status = 'excused', marked_by = v_actor.user_id, marked_at = now(), note = 'อนุมัติใบลาอัตโนมัติ';
        v_day := v_day + 1;
      end loop;
    end loop;

    select sp.academic_year_id, sp.grade_level, sp.room into v_profile
      from student_profiles sp where sp.student_id = v_leave.student_id
      order by sp.created_at desc limit 1;

    if found then
      v_day := v_leave.start_date;
      while v_day <= v_leave.end_date loop
        insert into homeroom_attendance_records (
          student_id, academic_year_id, grade_level, room, class_date, status, marked_by, marked_at, note
        )
        values (
          v_leave.student_id, v_profile.academic_year_id, v_profile.grade_level, v_profile.room,
          v_day, 'excused', v_actor.user_id, now(), 'อนุมัติใบลาอัตโนมัติ'
        )
        on conflict (student_id, class_date)
        do update set status = 'excused', marked_by = v_actor.user_id, marked_at = now(), note = 'อนุมัติใบลาอัตโนมัติ';
        v_day := v_day + 1;
      end loop;
    end if;
  end if;
end;
$$;

-- ---------------------------------------------------------------------
-- Gate RPCs for the leave-attachment Edge Functions (mirrors
-- assert_submission_upload_access).
-- ---------------------------------------------------------------------
create or replace function assert_leave_attachment_upload_access(p_token text)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role <> 'parent' then raise exception 'forbidden'; end if;
end;
$$;

create or replace function get_leave_attachment_for_download(p_token text, p_leave_id uuid)
returns table (attachment_url text)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_leave leave_requests%rowtype;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;

  select * into v_leave from leave_requests where id = p_leave_id;
  if not found then raise exception 'leave_request_not_found'; end if;

  if v_actor.role = 'parent' then
    if v_leave.parent_id is distinct from v_actor.user_id then raise exception 'forbidden'; end if;
  elsif v_actor.role in ('teacher', 'school_admin', 'executive') then
    if v_leave.school_id is distinct from v_actor.school_id then raise exception 'forbidden'; end if;
  else
    raise exception 'forbidden';
  end if;

  if v_leave.attachment_url is null then
    raise exception 'no_attachment';
  end if;

  return query select v_leave.attachment_url;
end;
$$;

grant execute on function submit_leave_request(text, uuid, text, date, date, text, text) to anon, authenticated;
grant execute on function list_leave_requests_for_review(text, text) to anon, authenticated;
grant execute on function list_my_leave_requests(text, uuid) to anon, authenticated;
grant execute on function review_leave_request(text, uuid, text, text) to anon, authenticated;
grant execute on function assert_leave_attachment_upload_access(text) to anon, authenticated, service_role;
grant execute on function get_leave_attachment_for_download(text, uuid) to anon, authenticated, service_role;
