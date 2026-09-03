-- =====================================================================
-- Real fix for the parent academic calendar page.
--
-- agy's previous attempt (20260901164430_calendar_events_table.sql,
-- never applied — references a non-existent public.students table) and
-- the matching Flutter code (Supabase.instance.client.from('calendar_events')
-- called directly from the page) never worked: the table doesn't exist
-- in production, and direct client table access violates this
-- project's RPC-only convention (CLAUDE.md hard rule 2) regardless.
--
-- Reuses the existing, real `school_events` table (already has 3 real
-- rows and a working `list_school_events` RPC used by the parent
-- dashboard's upcoming-activity card) instead of creating a duplicate
-- calendar table. Adds event categorization + a school_admin write
-- path so future events don't have to be inserted by hand again.
-- =====================================================================

set search_path = public, extensions;

alter table school_events
  add column if not exists event_type text not null default 'activity'
    check (event_type in ('holiday', 'public_holiday', 'exam', 'activity', 'study')),
  add column if not exists description text;

-- Backfill the 3 existing rows with their real categories.
update school_events set event_type = 'activity' where id = 'e887f7b6-d4e0-4f03-ae9e-125fa050d305';
update school_events set event_type = 'activity' where id = 'ad42ce1c-2a5d-4507-813d-555cc15bd225';
update school_events set event_type = 'exam' where id = '5559de0d-94b9-4bf2-9652-d8e1f8b1b940';

-- Seed real, fixed-date Thai national public holidays for the rest of
-- 2026 (deliberately limited to holidays with a fixed Gregorian date
-- every year, not lunar/Buddhist-calendar-calculated ones like Visakha
-- Bucha, to avoid seeding a wrong date under a false "official" claim).
-- Scoped to every school (loop), since these are national, not
-- school-specific, and school_events.school_id is not-null.
insert into school_events (school_id, title, location, start_date, end_date, event_type, description)
select s.id, holiday.title, 'ทั่วประเทศ', holiday.d, holiday.d, 'public_holiday', holiday.description
from schools s
cross join (values
  ('วันแม่แห่งชาติ'::varchar, date '2026-08-12', 'วันเฉลิมพระชนมพรรษา สมเด็จพระนางเจ้าสิริกิติ์ พระบรมราชินีนาถ พระบรมราชชนนีพันปีหลวง'::text),
  ('วันปิยมหาราช', date '2026-10-23', 'วันคล้ายวันสวรรคตพระบาทสมเด็จพระจุลจอมเกล้าเจ้าอยู่หัว'),
  ('วันพ่อแห่งชาติ', date '2026-12-05', 'วันคล้ายวันพระบรมราชสมภพ พระบาทสมเด็จพระบรมชนกาธิเบศร มหาภูมิพลอดุลยเดชมหาราช บรมนาถบพิตร'),
  ('วันรัฐธรรมนูญ', date '2026-12-10', 'วันที่ระลึกการประกาศใช้รัฐธรรมนูญฉบับถาวรฉบับแรก')
) as holiday(title, d, description)
where not exists (
  select 1 from school_events e
  where e.school_id = s.id and e.title = holiday.title and e.start_date = holiday.d
);

-- ---------------------------------------------------------------------
-- Full calendar read (no date/limit restriction, unlike
-- list_school_events which is a "next 5 upcoming" widget query — left
-- untouched so the dashboard card doesn't change behavior).
-- ---------------------------------------------------------------------
create or replace function list_calendar_events(p_token text)
returns table (
  event_id uuid,
  title varchar,
  description text,
  location varchar,
  start_date date,
  end_date date,
  event_type text
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_school_id uuid;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;

  if v_actor.role = 'parent' then
    select u.school_id into v_school_id
    from parent_links pl
    join users u on u.id = pl.student_id
    where pl.parent_id = v_actor.user_id and pl.status = 'approved'
    limit 1;
  else
    v_school_id := v_actor.school_id;
  end if;

  if v_school_id is null then
    return;
  end if;

  return query
    select e.id, e.title, e.description, e.location, e.start_date, e.end_date, e.event_type
    from school_events e
    where e.school_id = v_school_id
    order by e.start_date asc;
end;
$$;

-- ---------------------------------------------------------------------
-- Write path so future events go through a real RPC instead of manual
-- SQL (the 3 existing rows had no create RPC at all before this).
-- ---------------------------------------------------------------------
create or replace function create_school_event(
  p_token text,
  p_title varchar,
  p_start_date date,
  p_end_date date default null,
  p_location varchar default null,
  p_description text default null,
  p_event_type text default 'activity'
)
returns uuid
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_id uuid;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('school_admin', 'super_admin') then raise exception 'forbidden'; end if;
  if p_event_type not in ('holiday', 'public_holiday', 'exam', 'activity', 'study') then
    raise exception 'invalid_event_type';
  end if;

  insert into school_events (school_id, title, location, start_date, end_date, event_type, description)
  values (v_actor.school_id, p_title, p_location, p_start_date, coalesce(p_end_date, p_start_date), p_event_type, p_description)
  returning id into v_id;

  return v_id;
end;
$$;

grant execute on function list_calendar_events(text) to anon, authenticated;
grant execute on function create_school_event(text, varchar, date, date, varchar, text, text) to anon, authenticated;
