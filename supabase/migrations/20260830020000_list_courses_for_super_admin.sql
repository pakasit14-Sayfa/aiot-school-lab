-- Migration: 20260830020000_list_courses_for_super_admin.sql
-- Description: Real cross-school course/lesson overview for Super
-- Admin's "แพลตฟอร์มการเรียนรู้" page. Replaces what would otherwise be
-- a port of aiot_dev_dashboard's learning_platform_page.dart, which
-- turned out to be ~90% fake local-widget-state CRUD with zero Supabase
-- calls, duplicating (badly) the real course/lesson system this app
-- already has for teachers (course_service.dart / lesson_service.dart).
-- This RPC is an oversight aggregate only (per-school counts), not an
-- editor — editing stays with teachers where it already works for real.

create or replace function public.list_courses_for_super_admin(p_token text)
returns table (
  school_id uuid,
  school_name text,
  courses_total integer,
  courses_active integer,
  lessons_total integer,
  lessons_published integer,
  lessons_draft integer
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
begin
  select * into v_actor from get_session_actor(p_token);
  if v_actor.user_id is null or v_actor.role != 'super_admin' then
    raise exception 'forbidden: super_admin role required';
  end if;

  return query
  with lesson_counts as (
    select
      c.school_id as s_id,
      count(l.id)::integer as l_total,
      count(l.id) filter (where l.status = 'published')::integer as l_published,
      count(l.id) filter (where l.status = 'draft')::integer as l_draft
    from courses c
    left join lessons l on l.course_id = c.id
    group by c.school_id
  ),
  course_counts as (
    select
      c.school_id as s_id,
      count(*)::integer as c_total,
      count(*) filter (where c.status = 'active')::integer as c_active
    from courses c
    group by c.school_id
  )
  select
    s.id,
    s.name,
    coalesce(cc.c_total, 0),
    coalesce(cc.c_active, 0),
    coalesce(lc.l_total, 0),
    coalesce(lc.l_published, 0),
    coalesce(lc.l_draft, 0)
  from schools s
  left join course_counts cc on cc.s_id = s.id
  left join lesson_counts lc on lc.s_id = s.id
  order by s.name;
end;
$$;

revoke all on function public.list_courses_for_super_admin(text) from public, anon;
grant execute on function public.list_courses_for_super_admin(text) to anon, authenticated;
