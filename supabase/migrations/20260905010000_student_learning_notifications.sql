-- Notify students only when learning content actually becomes visible.
-- Existing publication/confirmation RPC authorization remains unchanged.
create unique index if not exists notifications_learning_event_once
on public.notifications (user_id, type, (payload->>'learning_source_id'))
where type in ('grade_confirmed', 'assignment_published', 'lesson_published')
  and payload ? 'learning_source_id';

create or replace function public._notify_learning_status_change()
returns trigger
language plpgsql security definer
set search_path = public, extensions
as $$
declare
  v_school uuid;
  v_type text;
  v_title text;
  v_body text;
begin
  if new.status is not distinct from old.status then return new; end if;
  select school_id into v_school from public.courses where id = new.course_id;
  if v_school is null then return new; end if;

  if tg_table_name = 'grades' then
    if new.status::text <> 'confirmed' then return new; end if;
    insert into public.notifications (user_id, type, title, body, payload)
    select u.id, 'grade_confirmed', 'มีผลคะแนนที่ยืนยันแล้ว',
           'ตรวจสอบผลคะแนนได้ที่หน้าคะแนนของคุณ',
           jsonb_build_object('learning_source_id', new.id, 'grade_id', new.id, 'course_id', new.course_id)
    from public.users u
    where u.id = new.student_id and u.school_id = v_school and u.status::text = 'active'
    on conflict do nothing;
    return new;
  end if;

  if new.status::text <> 'published' then return new; end if;
  if tg_table_name = 'assignments' then
    v_type := 'assignment_published';
    v_title := 'มีการบ้านใหม่';
  elsif tg_table_name = 'lessons' then
    v_type := 'lesson_published';
    v_title := 'มีบทเรียนใหม่';
  else
    return new;
  end if;
  v_body := new.title;
  insert into public.notifications (user_id, type, title, body, payload)
  select distinct cs.student_id, v_type, v_title, v_body,
    jsonb_build_object('learning_source_id', new.id, 'course_id', new.course_id,
      case when tg_table_name = 'assignments' then 'assignment_id' else 'lesson_id' end, new.id)
  from public.course_students cs
  join public.users u on u.id = cs.student_id
  where cs.course_id = new.course_id and u.school_id = v_school and u.status::text = 'active'
  on conflict do nothing;
  return new;
end;
$$;
revoke all on function public._notify_learning_status_change()
  from public, anon, authenticated, service_role;

create trigger notify_grade_confirmation
after update of status on public.grades
for each row execute function public._notify_learning_status_change();
create trigger notify_assignment_publication
after update of status on public.assignments
for each row execute function public._notify_learning_status_change();
create trigger notify_lesson_publication
after update of status on public.lessons
for each row execute function public._notify_learning_status_change();

