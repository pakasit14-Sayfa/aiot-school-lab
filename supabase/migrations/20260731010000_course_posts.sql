-- =====================================================================
-- Course Posts — Slice 4: minimal discussion board. No reactions, no
-- attachments (file attachments are superseded by the general Files
-- feature, Slice 5). No draft/publish concept — anyone in the course
-- (teacher or enrolled student) sees a post immediately.
-- =====================================================================

create table course_posts (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references courses(id),
  author_id uuid not null references users(id),
  body text not null,
  is_pinned bool not null default false,
  created_at timestamptz not null default now()
);

create table course_post_replies (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references course_posts(id),
  author_id uuid not null references users(id),
  body text not null,
  created_at timestamptz not null default now()
);

alter table course_posts enable row level security;
alter table course_post_replies enable row level security;

create or replace function create_post(
  p_token text,
  p_course_id uuid,
  p_body text
)
returns table (post_id uuid)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_course courses%rowtype;
  v_is_member boolean := false;
  v_post_id uuid;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;

  select * into v_course from courses where id = p_course_id;
  if not found then raise exception 'course_not_found'; end if;
  if v_course.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;

  if v_actor.role = 'teacher' then
    v_is_member := exists (
      select 1 from course_teachers ct
      where ct.course_id = p_course_id and ct.teacher_id = v_actor.user_id
    );
  elsif v_actor.role = 'student' then
    v_is_member := exists (
      select 1 from course_students cs
      where cs.course_id = p_course_id and cs.student_id = v_actor.user_id
    );
  end if;
  if not v_is_member then raise exception 'forbidden'; end if;

  if trim(coalesce(p_body, '')) = '' then
    raise exception 'body_required';
  end if;

  insert into course_posts (course_id, author_id, body)
  values (p_course_id, v_actor.user_id, trim(p_body))
  returning id into v_post_id;

  return query select v_post_id;
end;
$$;

create or replace function list_posts(p_token text, p_course_id uuid)
returns table (
  post_id uuid,
  author_id uuid,
  author_first_name varchar,
  author_last_name varchar,
  body text,
  is_pinned bool,
  created_at timestamptz,
  replies jsonb
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_course courses%rowtype;
  v_is_member boolean := false;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;

  select * into v_course from courses where id = p_course_id;
  if not found then raise exception 'course_not_found'; end if;
  if v_course.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;

  if v_actor.role = 'teacher' then
    v_is_member := exists (
      select 1 from course_teachers ct
      where ct.course_id = p_course_id and ct.teacher_id = v_actor.user_id
    );
  elsif v_actor.role = 'student' then
    v_is_member := exists (
      select 1 from course_students cs
      where cs.course_id = p_course_id and cs.student_id = v_actor.user_id
    );
  elsif v_actor.role = 'school_admin' then
    v_is_member := true;
  end if;
  if not v_is_member then raise exception 'forbidden'; end if;

  return query
  select
    p.id, p.author_id, u.first_name, u.last_name, p.body, p.is_pinned, p.created_at,
    coalesce((
      select json_agg(json_build_object(
        'id', r.id,
        'author_id', r.author_id,
        'author_first_name', ru.first_name,
        'author_last_name', ru.last_name,
        'body', r.body,
        'created_at', r.created_at
      ) order by r.created_at)
      from course_post_replies r
      join users ru on ru.id = r.author_id
      where r.post_id = p.id
    ), '[]'::json)::jsonb
  from course_posts p
  join users u on u.id = p.author_id
  where p.course_id = p_course_id
  order by p.is_pinned desc, p.created_at desc;
end;
$$;

create or replace function create_reply(
  p_token text,
  p_post_id uuid,
  p_body text
)
returns table (reply_id uuid)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_post course_posts%rowtype;
  v_course courses%rowtype;
  v_is_member boolean := false;
  v_reply_id uuid;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;

  select * into v_post from course_posts where id = p_post_id;
  if not found then raise exception 'post_not_found'; end if;

  select * into v_course from courses where id = v_post.course_id;
  if v_course.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;

  if v_actor.role = 'teacher' then
    v_is_member := exists (
      select 1 from course_teachers ct
      where ct.course_id = v_post.course_id and ct.teacher_id = v_actor.user_id
    );
  elsif v_actor.role = 'student' then
    v_is_member := exists (
      select 1 from course_students cs
      where cs.course_id = v_post.course_id and cs.student_id = v_actor.user_id
    );
  end if;
  if not v_is_member then raise exception 'forbidden'; end if;

  if trim(coalesce(p_body, '')) = '' then
    raise exception 'body_required';
  end if;

  insert into course_post_replies (post_id, author_id, body)
  values (p_post_id, v_actor.user_id, trim(p_body))
  returning id into v_reply_id;

  return query select v_reply_id;
end;
$$;

revoke all on function create_post(text, uuid, text) from public;
revoke all on function list_posts(text, uuid) from public;
revoke all on function create_reply(text, uuid, text) from public;

grant execute on function create_post(text, uuid, text) to anon, authenticated;
grant execute on function list_posts(text, uuid) to anon, authenticated;
grant execute on function create_reply(text, uuid, text) to anon, authenticated;
