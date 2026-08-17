-- =====================================================================
-- ปฏิทิน/ตารางเรียน — ไม่มี UC กำหนดไว้ในวอลต์เลย (เช็คแล้ว) เจ้าของ
-- โปรเจกต์ยืนยันตรงๆ ให้ทำ 2 อย่าง: (1) ตารางเรียนจริงต่อวิชา (ยังไม่เคย
-- มีในระบบเลย) (2) รายการแพลนงานส่วนตัวของนักเรียนเอง (ไม่ผูกกับวิชา/ครู
-- เลย เป็น scope ส่วนตัว 100%)
-- =====================================================================

create table class_schedules (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null,
  day_of_week smallint not null check (day_of_week between 0 and 6), -- 0=จันทร์ ... 6=อาทิตย์
  start_time time not null,
  end_time time not null,
  room varchar,
  created_by uuid not null,
  created_at timestamptz not null default now()
);
comment on column class_schedules.day_of_week is '0=จันทร์ 1=อังคาร ... 6=อาทิตย์';

create table student_personal_tasks (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null,
  title varchar not null,
  note text,
  due_at timestamptz,
  done bool not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
comment on table student_personal_tasks is 'แพลนงานส่วนตัวของนักเรียนเอง — ไม่ใช่ assignments (งานที่ครูมอบหมาย) เป็น to-do list ส่วนตัว ไม่มีใครเห็นนอกจากเจ้าของ';

alter table class_schedules add constraint fk_class_schedules_course foreign key (course_id) references courses(id);
alter table class_schedules add constraint fk_class_schedules_created_by foreign key (created_by) references users(id);
alter table student_personal_tasks add constraint fk_student_personal_tasks_student foreign key (student_id) references users(id);

alter table class_schedules enable row level security;
alter table student_personal_tasks enable row level security;

create or replace function set_class_schedule(
  p_token text,
  p_course_id uuid,
  p_day_of_week smallint,
  p_start_time time,
  p_end_time time,
  p_room text default null
)
returns table (schedule_id uuid)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_course courses%rowtype;
  v_schedule_id uuid;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('teacher', 'school_admin') then raise exception 'forbidden'; end if;

  select * into v_course from courses where id = p_course_id;
  if not found then raise exception 'course_not_found'; end if;
  if v_course.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;
  if v_actor.role = 'teacher' and not exists (
    select 1 from course_teachers ct
    where ct.course_id = p_course_id and ct.teacher_id = v_actor.user_id
  ) then raise exception 'forbidden'; end if;

  if p_end_time <= p_start_time then
    raise exception 'end_time_must_be_after_start_time';
  end if;

  insert into class_schedules (course_id, day_of_week, start_time, end_time, room, created_by)
  values (p_course_id, p_day_of_week, p_start_time, p_end_time, p_room, v_actor.user_id)
  returning id into v_schedule_id;

  return query select v_schedule_id;
end;
$$;

create or replace function remove_class_schedule(p_token text, p_schedule_id uuid)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_schedule class_schedules%rowtype;
  v_course courses%rowtype;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('teacher', 'school_admin') then raise exception 'forbidden'; end if;

  select * into v_schedule from class_schedules where id = p_schedule_id;
  if not found then raise exception 'schedule_not_found'; end if;

  select * into v_course from courses where id = v_schedule.course_id;
  if v_course.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;
  if v_actor.role = 'teacher' and not exists (
    select 1 from course_teachers ct
    where ct.course_id = v_schedule.course_id and ct.teacher_id = v_actor.user_id
  ) then raise exception 'forbidden'; end if;

  delete from class_schedules where id = p_schedule_id;
end;
$$;

create or replace function list_my_schedule(p_token text)
returns table (
  schedule_id uuid,
  course_id uuid,
  subject_name varchar,
  day_of_week smallint,
  start_time time,
  end_time time,
  room varchar
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
  select cs.id, c.id, c.subject_name, cs.day_of_week, cs.start_time, cs.end_time, cs.room
  from class_schedules cs
  join courses c on c.id = cs.course_id
  join course_students st on st.course_id = c.id
  where st.student_id = v_actor.user_id
  order by cs.day_of_week, cs.start_time;
end;
$$;

create or replace function create_personal_task(
  p_token text,
  p_title text,
  p_note text default null,
  p_due_at timestamptz default null
)
returns table (task_id uuid)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_task_id uuid;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role <> 'student' then raise exception 'forbidden'; end if;

  if trim(coalesce(p_title, '')) = '' then
    raise exception 'title_required';
  end if;

  insert into student_personal_tasks (student_id, title, note, due_at)
  values (v_actor.user_id, trim(p_title), p_note, p_due_at)
  returning id into v_task_id;

  return query select v_task_id;
end;
$$;

create or replace function list_my_personal_tasks(p_token text)
returns table (
  task_id uuid,
  title varchar,
  note text,
  due_at timestamptz,
  done bool,
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
  if v_actor.role <> 'student' then raise exception 'forbidden'; end if;

  return query
  select t.id, t.title, t.note, t.due_at, t.done, t.created_at
  from student_personal_tasks t
  where t.student_id = v_actor.user_id
  order by t.done, t.due_at nulls last, t.created_at desc;
end;
$$;

create or replace function toggle_personal_task(p_token text, p_task_id uuid, p_done bool)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_task student_personal_tasks%rowtype;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role <> 'student' then raise exception 'forbidden'; end if;

  select * into v_task from student_personal_tasks where id = p_task_id;
  if not found then raise exception 'task_not_found'; end if;
  if v_task.student_id is distinct from v_actor.user_id then
    raise exception 'forbidden';
  end if;

  update student_personal_tasks set done = p_done, updated_at = now() where id = p_task_id;
end;
$$;

create or replace function delete_personal_task(p_token text, p_task_id uuid)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_task student_personal_tasks%rowtype;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role <> 'student' then raise exception 'forbidden'; end if;

  select * into v_task from student_personal_tasks where id = p_task_id;
  if not found then raise exception 'task_not_found'; end if;
  if v_task.student_id is distinct from v_actor.user_id then
    raise exception 'forbidden';
  end if;

  delete from student_personal_tasks where id = p_task_id;
end;
$$;

revoke all on function set_class_schedule(text, uuid, smallint, time, time, text) from public;
revoke all on function remove_class_schedule(text, uuid) from public;
revoke all on function list_my_schedule(text) from public;
revoke all on function create_personal_task(text, text, text, timestamptz) from public;
revoke all on function list_my_personal_tasks(text) from public;
revoke all on function toggle_personal_task(text, uuid, bool) from public;
revoke all on function delete_personal_task(text, uuid) from public;

grant execute on function set_class_schedule(text, uuid, smallint, time, time, text) to anon, authenticated;
grant execute on function remove_class_schedule(text, uuid) to anon, authenticated;
grant execute on function list_my_schedule(text) to anon, authenticated;
grant execute on function create_personal_task(text, text, text, timestamptz) to anon, authenticated;
grant execute on function list_my_personal_tasks(text) to anon, authenticated;
grant execute on function toggle_personal_task(text, uuid, bool) to anon, authenticated;
grant execute on function delete_personal_task(text, uuid) to anon, authenticated;
