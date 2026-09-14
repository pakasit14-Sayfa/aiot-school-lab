-- =====================================================================
-- Student follow-up system: home visits, SDQ screening, scholarships,
-- and executive directives — 4 domains the "งานติดตามที่ยังไม่รองรับ" card
-- on director_learning_page.dart disclosed as genuinely absent (no table,
-- no RPC, buttons hard-disabled onPressed:null). Confirmed via full repo
-- search before writing this: zero prior rows/functions for any of these.
--
-- SDQ scoring note (read before touching sdq_assessments): this stores the
-- Goodman SDQ's standard 5-subscale structure (emotional / conduct /
-- hyperactivity / peer / prosocial, 5 items each, 0-2 per item) and
-- total_difficulties_score = emotional+conduct+hyperactivity+peer (excludes
-- prosocial, matching the real instrument). It deliberately does NOT assert
-- a "ปกติ/เสี่ยง/มีปัญหา" diagnostic band — published cutoffs vary by rater
-- form and could not be verified against an authoritative source while
-- writing this migration. Showing an unverified clinical threshold as fact
-- would be exactly the kind of fabricated-data problem this whole project
-- has spent this session removing. UI must show raw scores with a
-- screening-only disclaimer, not a diagnostic label.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Home visits
-- ---------------------------------------------------------------------
create table if not exists student_home_visits (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references schools(id),
  student_id uuid not null references users(id),
  visited_by uuid not null references users(id),
  visit_date date not null,
  purpose text not null,
  family_situation text,
  follow_up_needed boolean not null default false,
  follow_up_notes text,
  created_by uuid not null references users(id),
  created_at timestamptz not null default now()
);
alter table student_home_visits enable row level security;

create or replace function create_student_home_visit(
  p_token text,
  p_student_id uuid,
  p_visit_date date,
  p_purpose text,
  p_family_situation text default null,
  p_follow_up_needed boolean default false,
  p_follow_up_notes text default null
)
returns table (visit_id uuid)
language plpgsql security definer set search_path = public, extensions
as $$
declare v_actor record; v_new_id uuid;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('teacher','school_admin') then raise exception 'forbidden'; end if;
  if not exists (select 1 from users where id = p_student_id and school_id = v_actor.school_id) then
    raise exception 'student_not_found';
  end if;
  if coalesce(trim(p_purpose), '') = '' then raise exception 'purpose_required'; end if;

  insert into student_home_visits (school_id, student_id, visited_by, visit_date, purpose, family_situation, follow_up_needed, follow_up_notes, created_by)
  values (v_actor.school_id, p_student_id, v_actor.user_id, p_visit_date, p_purpose, p_family_situation, p_follow_up_needed, p_follow_up_notes, v_actor.user_id)
  returning id into v_new_id;

  return query select v_new_id;
end;
$$;

create or replace function list_student_home_visits(p_token text, p_student_id uuid)
returns table (
  visit_id uuid, student_id uuid, student_name text, visited_by_name text,
  visit_date date, purpose text, family_situation text,
  follow_up_needed boolean, follow_up_notes text, created_at timestamptz
)
language plpgsql security definer set search_path = public, extensions
as $$
declare v_actor record;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('teacher','school_admin','executive') then raise exception 'forbidden'; end if;

  return query
  select v.id, v.student_id, trim(coalesce(u.first_name,'')||' '||coalesce(u.last_name,'')),
    trim(coalesce(vb.first_name,'')||' '||coalesce(vb.last_name,'')),
    v.visit_date, v.purpose, v.family_situation, v.follow_up_needed, v.follow_up_notes, v.created_at
  from student_home_visits v
  join users u on u.id = v.student_id
  join users vb on vb.id = v.visited_by
  where v.school_id = v_actor.school_id and v.student_id = p_student_id
  order by v.visit_date desc;
end;
$$;

create or replace function list_school_home_visits(p_token text, p_limit int default 50)
returns table (
  visit_id uuid, student_id uuid, student_name text, visited_by_name text,
  visit_date date, purpose text, follow_up_needed boolean, created_at timestamptz
)
language plpgsql security definer set search_path = public, extensions
as $$
declare v_actor record;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('school_admin','executive') then raise exception 'forbidden'; end if;

  return query
  select v.id, v.student_id, trim(coalesce(u.first_name,'')||' '||coalesce(u.last_name,'')),
    trim(coalesce(vb.first_name,'')||' '||coalesce(vb.last_name,'')),
    v.visit_date, v.purpose, v.follow_up_needed, v.created_at
  from student_home_visits v
  join users u on u.id = v.student_id
  join users vb on vb.id = v.visited_by
  where v.school_id = v_actor.school_id
  order by v.visit_date desc
  limit greatest(p_limit, 1);
end;
$$;

-- ---------------------------------------------------------------------
-- 2. SDQ screening (see scoring note at top of file)
-- ---------------------------------------------------------------------
create table if not exists sdq_assessments (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references schools(id),
  student_id uuid not null references users(id),
  assessed_by uuid not null references users(id),
  rater_type text not null default 'teacher' check (rater_type in ('teacher','parent','self')),
  assessment_date date not null default current_date,
  item_scores jsonb not null,
  emotional_score int not null,
  conduct_score int not null,
  hyperactivity_score int not null,
  peer_score int not null,
  prosocial_score int not null,
  total_difficulties_score int not null,
  notes text,
  created_at timestamptz not null default now(),
  constraint sdq_item_count check (jsonb_array_length(item_scores) = 25)
);
alter table sdq_assessments enable row level security;

create or replace function record_sdq_assessment(
  p_token text,
  p_student_id uuid,
  p_item_scores jsonb,
  p_rater_type text default 'teacher',
  p_notes text default null
)
returns table (
  assessment_id uuid, emotional_score int, conduct_score int,
  hyperactivity_score int, peer_score int, prosocial_score int, total_difficulties_score int
)
language plpgsql security definer set search_path = public, extensions
as $$
declare
  v_actor record; v_new_id uuid; v_items int[]; v_i int;
  v_emotional int := 0; v_conduct int := 0; v_hyper int := 0; v_peer int := 0; v_prosocial int := 0;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('teacher','school_admin') then raise exception 'forbidden'; end if;
  if not exists (select 1 from users where id = p_student_id and school_id = v_actor.school_id) then
    raise exception 'student_not_found';
  end if;
  if jsonb_array_length(p_item_scores) <> 25 then raise exception 'must_have_25_items'; end if;

  select array_agg((value)::int) into v_items from jsonb_array_elements_text(p_item_scores) as value;
  for v_i in 1..25 loop
    if v_items[v_i] < 0 or v_items[v_i] > 2 then raise exception 'item_score_out_of_range'; end if;
  end loop;

  -- Fixed 5-items-per-subscale grouping in item order 1-25 (see top-of-file
  -- note on why no diagnostic band is derived from these totals).
  for v_i in 1..5 loop v_emotional := v_emotional + v_items[v_i]; end loop;
  for v_i in 6..10 loop v_conduct := v_conduct + v_items[v_i]; end loop;
  for v_i in 11..15 loop v_hyper := v_hyper + v_items[v_i]; end loop;
  for v_i in 16..20 loop v_peer := v_peer + v_items[v_i]; end loop;
  for v_i in 21..25 loop v_prosocial := v_prosocial + v_items[v_i]; end loop;

  insert into sdq_assessments (
    school_id, student_id, assessed_by, rater_type, item_scores,
    emotional_score, conduct_score, hyperactivity_score, peer_score, prosocial_score,
    total_difficulties_score, notes
  ) values (
    v_actor.school_id, p_student_id, v_actor.user_id, coalesce(p_rater_type,'teacher'), p_item_scores,
    v_emotional, v_conduct, v_hyper, v_peer, v_prosocial,
    v_emotional + v_conduct + v_hyper + v_peer, p_notes
  ) returning id into v_new_id;

  return query select v_new_id, v_emotional, v_conduct, v_hyper, v_peer, v_prosocial, v_emotional + v_conduct + v_hyper + v_peer;
end;
$$;

create or replace function list_student_sdq_assessments(p_token text, p_student_id uuid)
returns table (
  assessment_id uuid, assessed_by_name text, rater_type text, assessment_date date,
  emotional_score int, conduct_score int, hyperactivity_score int, peer_score int,
  prosocial_score int, total_difficulties_score int, notes text
)
language plpgsql security definer set search_path = public, extensions
as $$
declare v_actor record;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('teacher','school_admin','executive') then raise exception 'forbidden'; end if;

  return query
  select s.id, trim(coalesce(u.first_name,'')||' '||coalesce(u.last_name,'')), s.rater_type, s.assessment_date,
    s.emotional_score, s.conduct_score, s.hyperactivity_score, s.peer_score, s.prosocial_score,
    s.total_difficulties_score, s.notes
  from sdq_assessments s
  join users u on u.id = s.assessed_by
  where s.school_id = v_actor.school_id and s.student_id = p_student_id
  order by s.assessment_date desc;
end;
$$;

create or replace function list_school_sdq_assessments(p_token text, p_limit int default 50)
returns table (
  assessment_id uuid, student_id uuid, student_name text, assessment_date date,
  total_difficulties_score int
)
language plpgsql security definer set search_path = public, extensions
as $$
declare v_actor record;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('school_admin','executive') then raise exception 'forbidden'; end if;

  return query
  select s.id, s.student_id, trim(coalesce(u.first_name,'')||' '||coalesce(u.last_name,'')),
    s.assessment_date, s.total_difficulties_score
  from sdq_assessments s
  join users u on u.id = s.student_id
  where s.school_id = v_actor.school_id
  order by s.assessment_date desc
  limit greatest(p_limit, 1);
end;
$$;

-- ---------------------------------------------------------------------
-- 3. Scholarships
-- ---------------------------------------------------------------------
create table if not exists scholarships (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references schools(id),
  name text not null,
  sponsor text,
  amount_thb numeric,
  description text,
  created_by uuid not null references users(id),
  created_at timestamptz not null default now()
);
alter table scholarships enable row level security;

create table if not exists scholarship_awards (
  id uuid primary key default gen_random_uuid(),
  scholarship_id uuid not null references scholarships(id) on delete cascade,
  student_id uuid not null references users(id),
  status text not null default 'applied' check (status in ('applied','approved','rejected','disbursed')),
  awarded_amount_thb numeric,
  notes text,
  created_by uuid not null references users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (scholarship_id, student_id)
);
alter table scholarship_awards enable row level security;

create or replace function create_scholarship(
  p_token text, p_name text, p_sponsor text default null,
  p_amount_thb numeric default null, p_description text default null
)
returns table (scholarship_id uuid)
language plpgsql security definer set search_path = public, extensions
as $$
declare v_actor record; v_new_id uuid;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('school_admin','executive') then raise exception 'forbidden'; end if;
  if coalesce(trim(p_name), '') = '' then raise exception 'name_required'; end if;

  insert into scholarships (school_id, name, sponsor, amount_thb, description, created_by)
  values (v_actor.school_id, p_name, p_sponsor, p_amount_thb, p_description, v_actor.user_id)
  returning id into v_new_id;

  return query select v_new_id;
end;
$$;

create or replace function nominate_scholarship_award(
  p_token text, p_scholarship_id uuid, p_student_id uuid, p_notes text default null
)
returns table (award_id uuid)
language plpgsql security definer set search_path = public, extensions
as $$
declare v_actor record; v_new_id uuid;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('teacher','school_admin','executive') then raise exception 'forbidden'; end if;
  if not exists (select 1 from scholarships where id = p_scholarship_id and school_id = v_actor.school_id) then
    raise exception 'scholarship_not_found';
  end if;
  if not exists (select 1 from users where id = p_student_id and school_id = v_actor.school_id) then
    raise exception 'student_not_found';
  end if;

  insert into scholarship_awards (scholarship_id, student_id, notes, created_by)
  values (p_scholarship_id, p_student_id, p_notes, v_actor.user_id)
  on conflict (scholarship_id, student_id) do update set notes = excluded.notes
  returning id into v_new_id;

  return query select v_new_id;
end;
$$;

create or replace function set_scholarship_award_status(
  p_token text, p_award_id uuid, p_status text,
  p_awarded_amount_thb numeric default null, p_notes text default null
)
returns table (award_id uuid, status text)
language plpgsql security definer set search_path = public, extensions
as $$
declare v_actor record;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('school_admin','executive') then raise exception 'forbidden'; end if;
  if p_status not in ('applied','approved','rejected','disbursed') then raise exception 'invalid_status'; end if;
  if not exists (
    select 1 from scholarship_awards a join scholarships s on s.id = a.scholarship_id
    where a.id = p_award_id and s.school_id = v_actor.school_id
  ) then raise exception 'award_not_found'; end if;

  update scholarship_awards
  set status = p_status,
      awarded_amount_thb = coalesce(p_awarded_amount_thb, awarded_amount_thb),
      notes = coalesce(p_notes, notes),
      updated_at = now()
  where id = p_award_id;

  return query select p_award_id, p_status;
end;
$$;

create or replace function list_scholarships(p_token text)
returns table (
  scholarship_id uuid, name text, sponsor text, amount_thb numeric,
  description text, award_count bigint, created_at timestamptz
)
language plpgsql security definer set search_path = public, extensions
as $$
declare v_actor record;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('teacher','school_admin','executive') then raise exception 'forbidden'; end if;

  return query
  select s.id, s.name, s.sponsor, s.amount_thb, s.description, count(a.id), s.created_at
  from scholarships s
  left join scholarship_awards a on a.scholarship_id = s.id
  where s.school_id = v_actor.school_id
  group by s.id
  order by s.created_at desc;
end;
$$;

create or replace function list_scholarship_awards(p_token text, p_scholarship_id uuid default null)
returns table (
  award_id uuid, scholarship_id uuid, scholarship_name text, student_id uuid, student_name text,
  status text, awarded_amount_thb numeric, notes text, created_at timestamptz
)
language plpgsql security definer set search_path = public, extensions
as $$
declare v_actor record;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('teacher','school_admin','executive') then raise exception 'forbidden'; end if;

  return query
  select a.id, a.scholarship_id, s.name, a.student_id,
    trim(coalesce(u.first_name,'')||' '||coalesce(u.last_name,'')),
    a.status, a.awarded_amount_thb, a.notes, a.created_at
  from scholarship_awards a
  join scholarships s on s.id = a.scholarship_id
  join users u on u.id = a.student_id
  where s.school_id = v_actor.school_id
    and (p_scholarship_id is null or a.scholarship_id = p_scholarship_id)
  order by a.created_at desc;
end;
$$;

-- ---------------------------------------------------------------------
-- 4. Executive directives ("สั่งการติดตาม")
-- ---------------------------------------------------------------------
create table if not exists executive_directives (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references schools(id),
  student_id uuid references users(id),
  case_id uuid references student_support_cases(id),
  assigned_to uuid not null references users(id),
  assigned_by uuid not null references users(id),
  title text not null,
  instructions text,
  due_date date,
  status text not null default 'pending' check (status in ('pending','acknowledged','completed')),
  completed_notes text,
  created_at timestamptz not null default now(),
  acknowledged_at timestamptz,
  completed_at timestamptz
);
alter table executive_directives enable row level security;

create or replace function create_directive(
  p_token text, p_assigned_to uuid, p_title text,
  p_instructions text default null, p_student_id uuid default null,
  p_case_id uuid default null, p_due_date date default null
)
returns table (directive_id uuid)
language plpgsql security definer set search_path = public, extensions
as $$
declare v_actor record; v_new_id uuid;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('executive','school_admin') then raise exception 'forbidden'; end if;
  if coalesce(trim(p_title), '') = '' then raise exception 'title_required'; end if;
  if not exists (select 1 from users where id = p_assigned_to and school_id = v_actor.school_id) then
    raise exception 'assignee_not_found';
  end if;
  if p_student_id is not null and not exists (select 1 from users where id = p_student_id and school_id = v_actor.school_id) then
    raise exception 'student_not_found';
  end if;
  if p_case_id is not null and not exists (select 1 from student_support_cases where id = p_case_id and school_id = v_actor.school_id) then
    raise exception 'case_not_found';
  end if;

  insert into executive_directives (school_id, student_id, case_id, assigned_to, assigned_by, title, instructions, due_date)
  values (v_actor.school_id, p_student_id, p_case_id, p_assigned_to, v_actor.user_id, p_title, p_instructions, p_due_date)
  returning id into v_new_id;

  return query select v_new_id;
end;
$$;

create or replace function acknowledge_directive(p_token text, p_directive_id uuid)
returns table (directive_id uuid, status text)
language plpgsql security definer set search_path = public, extensions
as $$
declare v_actor record;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if not exists (
    select 1 from executive_directives where id = p_directive_id and school_id = v_actor.school_id and assigned_to = v_actor.user_id
  ) then raise exception 'directive_not_found'; end if;

  update executive_directives ed set status = 'acknowledged', acknowledged_at = now()
  where ed.id = p_directive_id and ed.status = 'pending';

  return query select p_directive_id, d.status from executive_directives d where d.id = p_directive_id;
end;
$$;

create or replace function complete_directive(p_token text, p_directive_id uuid, p_completed_notes text default null)
returns table (directive_id uuid, status text)
language plpgsql security definer set search_path = public, extensions
as $$
declare v_actor record;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if not exists (
    select 1 from executive_directives where id = p_directive_id and school_id = v_actor.school_id and assigned_to = v_actor.user_id
  ) then raise exception 'directive_not_found'; end if;

  update executive_directives
  set status = 'completed', completed_at = now(), completed_notes = coalesce(p_completed_notes, completed_notes)
  where id = p_directive_id;

  return query select p_directive_id, d.status from executive_directives d where d.id = p_directive_id;
end;
$$;

create or replace function list_my_directives(p_token text)
returns table (
  directive_id uuid, title text, instructions text, student_name text,
  assigned_by_name text, due_date date, status text, created_at timestamptz
)
language plpgsql security definer set search_path = public, extensions
as $$
declare v_actor record;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;

  return query
  select d.id, d.title, d.instructions,
    trim(coalesce(su.first_name,'')||' '||coalesce(su.last_name,'')),
    trim(coalesce(ab.first_name,'')||' '||coalesce(ab.last_name,'')),
    d.due_date, d.status, d.created_at
  from executive_directives d
  left join users su on su.id = d.student_id
  join users ab on ab.id = d.assigned_by
  where d.school_id = v_actor.school_id and d.assigned_to = v_actor.user_id
  order by (d.status = 'completed'), d.due_date nulls last, d.created_at desc;
end;
$$;

create or replace function list_executive_directives(p_token text)
returns table (
  directive_id uuid, title text, instructions text, student_name text,
  assigned_to_name text, due_date date, status text, created_at timestamptz
)
language plpgsql security definer set search_path = public, extensions
as $$
declare v_actor record;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('executive','school_admin') then raise exception 'forbidden'; end if;

  return query
  select d.id, d.title, d.instructions,
    trim(coalesce(su.first_name,'')||' '||coalesce(su.last_name,'')),
    trim(coalesce(at_.first_name,'')||' '||coalesce(at_.last_name,'')),
    d.due_date, d.status, d.created_at
  from executive_directives d
  left join users su on su.id = d.student_id
  join users at_ on at_.id = d.assigned_to
  where d.school_id = v_actor.school_id
  order by (d.status = 'completed'), d.due_date nulls last, d.created_at desc;
end;
$$;

-- ---------------------------------------------------------------------
-- 4.5. Student picker — every create dialog on the new follow-up page
-- (home visit, SDQ, scholarship nomination, directive target) needs to
-- search the school's student roster by name. Nothing in the schema
-- already exposes this to teacher/school_admin/executive as a flat
-- search; `list_homeroom_roster` needs a known grade+room first.
-- ---------------------------------------------------------------------
create or replace function list_school_students(p_token text, p_search text default null)
returns table (student_id uuid, student_name text, grade_level text, room text)
language plpgsql security definer set search_path = public, extensions
as $$
declare v_actor record; v_year uuid;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('teacher','school_admin','executive') then raise exception 'forbidden'; end if;
  v_year := _current_academic_year_id(v_actor.school_id);

  return query
  select u.id, trim(coalesce(u.first_name,'')||' '||coalesce(u.last_name,'')),
    sp.grade_level::text, sp.room::text
  from users u
  join user_roles ur on ur.user_id = u.id and ur.school_id = v_actor.school_id and ur.role = 'student'
  left join student_profiles sp on sp.student_id = u.id and sp.academic_year_id = v_year
  where u.school_id = v_actor.school_id and u.status = 'active'
    and (
      p_search is null or trim(p_search) = '' or
      (coalesce(u.first_name,'')||' '||coalesce(u.last_name,'')) ilike '%'||p_search||'%'
    )
  order by u.first_name, u.last_name
  limit 100;
end;
$$;

-- ---------------------------------------------------------------------
-- 5. Combined summary for the "งานติดตามที่ยังไม่รองรับ" card
-- ---------------------------------------------------------------------
create or replace function get_student_followup_summary(p_token text)
returns table (
  home_visits_this_month bigint, home_visits_follow_up_needed bigint,
  sdq_assessments_total bigint, sdq_assessments_this_month bigint,
  scholarships_active bigint, scholarship_awards_pending bigint,
  directives_open bigint, directives_overdue bigint
)
language plpgsql security definer set search_path = public, extensions
as $$
declare v_actor record;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('executive','school_admin','super_admin') then raise exception 'forbidden'; end if;

  return query
  select
    (select count(*) from student_home_visits where school_id = v_actor.school_id and visit_date >= date_trunc('month', current_date)),
    (select count(*) from student_home_visits where school_id = v_actor.school_id and follow_up_needed),
    (select count(*) from sdq_assessments where school_id = v_actor.school_id),
    (select count(*) from sdq_assessments where school_id = v_actor.school_id and assessment_date >= date_trunc('month', current_date)),
    (select count(*) from scholarships where school_id = v_actor.school_id),
    (select count(*) from scholarship_awards a join scholarships s on s.id = a.scholarship_id where s.school_id = v_actor.school_id and a.status = 'applied'),
    (select count(*) from executive_directives where school_id = v_actor.school_id and status <> 'completed'),
    (select count(*) from executive_directives where school_id = v_actor.school_id and status <> 'completed' and due_date < current_date);
end;
$$;

-- ---------------------------------------------------------------------
-- 6. Widen the schoolwide watchlist with an SDQ-based signal, so "risk
-- assessment" draws on more than attendance/grades/assignments. Return
-- shape is unchanged (AutoFlaggedStudent.fromRow in Dart is untouched) so
-- this is DROP+CREATE only because Postgres won't let a CREATE OR REPLACE
-- change a table function's body-only logic safely across the two source
-- CTEs added — kept the exact same columns as
-- 20260910150000_executive_flag_grade_and_advisor.sql.
-- 17 is the commonly-cited "high difficulties" cutoff for a teacher-rated
-- SDQ total (max 40) — used here only to decide whether to surface the
-- flag at all, not printed as a diagnostic claim; the detail text states
-- the raw score so a human makes the call.
-- ---------------------------------------------------------------------
DROP FUNCTION IF EXISTS public.list_executive_students_needing_attention(text);

CREATE FUNCTION public.list_executive_students_needing_attention(p_token text)
RETURNS TABLE(
  student_id uuid, student_name text, reason text, detail text,
  action_label text, severity text,
  grade_level text, room text, advisor_name text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'extensions'
AS $function$
DECLARE v_actor record; v_year uuid;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN RAISE EXCEPTION 'invalid_session'; END IF;
  IF v_actor.role NOT IN ('executive','school_admin','super_admin')
     OR v_actor.school_id IS NULL THEN RAISE EXCEPTION 'forbidden'; END IF;
  v_year := _current_academic_year_id(v_actor.school_id);

  RETURN QUERY
  WITH school_courses AS (
    SELECT c.id FROM courses c
    JOIN terms t ON t.id=c.term_id AND t.academic_year_id=v_year
    WHERE c.school_id=v_actor.school_id
  ), students AS (
    SELECT DISTINCT cs.student_id AS id
    FROM course_students cs JOIN school_courses sc ON sc.id=cs.course_id
  ), overdue AS (
    SELECT cs.student_id AS id,count(*) AS n
    FROM course_students cs
    JOIN school_courses sc ON sc.id=cs.course_id
    JOIN assignments a ON a.course_id=cs.course_id
    WHERE a.status='published' AND a.due_at < now()
      AND NOT EXISTS (
        SELECT 1 FROM submissions sub
        WHERE sub.assignment_id=a.id
          AND (
            sub.student_id=cs.student_id OR
            (sub.group_id IS NOT NULL AND EXISTS (
              SELECT 1 FROM group_members gm
              WHERE gm.group_id=sub.group_id AND gm.student_id=cs.student_id
            ))
          )
      )
    GROUP BY cs.student_id
  ), absences AS (
    SELECT ar.student_id AS id,count(*) AS n
    FROM attendance_records ar JOIN school_courses sc ON sc.id=ar.course_id
    WHERE ar.status='absent' AND ar.class_date >= current_date - 30
    GROUP BY ar.student_id
  ), low_grades AS (
    SELECT g.student_id AS id,avg(g.score/nullif(g.max_score,0)) AS ratio
    FROM grades g JOIN school_courses sc ON sc.id=g.course_id
    WHERE g.status='confirmed' AND g.score IS NOT NULL AND g.max_score>0
    GROUP BY g.student_id
    HAVING avg(g.score/nullif(g.max_score,0)) < .5
  ), latest_sdq AS (
    SELECT DISTINCT ON (s.student_id) s.student_id AS id, s.total_difficulties_score AS score
    FROM sdq_assessments s
    WHERE s.school_id = v_actor.school_id
    ORDER BY s.student_id, s.assessment_date DESC, s.created_at DESC
  ), high_sdq AS (
    SELECT id, score FROM latest_sdq WHERE score >= 17
  ), profile AS (
    SELECT sp.student_id AS id, sp.grade_level, sp.room
    FROM student_profiles sp
    WHERE sp.academic_year_id = v_year
  ), advisor AS (
    SELECT ha.grade_level, ha.room,
      trim(coalesce(tu.first_name,'')||' '||coalesce(tu.last_name,'')) AS advisor_name
    FROM homeroom_assignments ha
    JOIN users tu ON tu.id = ha.teacher_id
    WHERE ha.academic_year_id = v_year AND ha.school_id = v_actor.school_id
  )
  SELECT st.id,trim(coalesce(u.first_name,'')||' '||coalesce(u.last_name,'')),
    CASE WHEN coalesce(o.n,0)>=2 THEN 'ค้างส่งงาน'
         WHEN g.ratio IS NOT NULL THEN 'คะแนนเฉลี่ยต่ำ'
         WHEN hs.score IS NOT NULL THEN 'คะแนน SDQ สูง'
         ELSE 'ขาดเรียนบ่อย' END,
    CASE WHEN coalesce(o.n,0)>=2 THEN 'ค้างส่ง '||o.n||' งาน'
         WHEN g.ratio IS NOT NULL THEN 'เฉลี่ย '||round(g.ratio*100)||'%'
         WHEN hs.score IS NOT NULL THEN 'SDQ รวม '||hs.score||'/40 (ครั้งล่าสุด)'
         ELSE 'ขาดเรียน '||coalesce(ab.n,0)||' ครั้ง (30 วัน)' END,
    CASE WHEN coalesce(o.n,0)>=2 THEN 'ดูงานค้าง'
         WHEN g.ratio IS NOT NULL THEN 'ดูคะแนน'
         WHEN hs.score IS NOT NULL THEN 'ดูผล SDQ' ELSE 'เช็คชื่อ' END,
    CASE WHEN coalesce(o.n,0)>=3 OR coalesce(ab.n,0)>=4 OR coalesce(hs.score,0)>=25 THEN 'urgent' ELSE 'normal' END,
    p.grade_level::text, p.room::text, adv.advisor_name
  FROM students st
  JOIN users u ON u.id=st.id AND u.school_id=v_actor.school_id AND u.status='active'
  LEFT JOIN overdue o ON o.id=st.id
  LEFT JOIN absences ab ON ab.id=st.id
  LEFT JOIN low_grades g ON g.id=st.id
  LEFT JOIN high_sdq hs ON hs.id=st.id
  LEFT JOIN profile p ON p.id=st.id
  LEFT JOIN advisor adv ON adv.grade_level=p.grade_level AND adv.room=p.room
  WHERE coalesce(o.n,0)>=2 OR coalesce(ab.n,0)>=2 OR g.ratio IS NOT NULL OR hs.score IS NOT NULL
  ORDER BY u.first_name,u.last_name;
END;
$function$;

-- ---------------------------------------------------------------------
-- Grants — REVOKE ALL then GRANT to anon,authenticated, matching every
-- migration since 20260910090000.
-- ---------------------------------------------------------------------
REVOKE ALL ON FUNCTION public.create_student_home_visit(text,uuid,date,text,text,boolean,text) FROM PUBLIC,service_role;
GRANT EXECUTE ON FUNCTION public.create_student_home_visit(text,uuid,date,text,text,boolean,text) TO anon,authenticated;
REVOKE ALL ON FUNCTION public.list_student_home_visits(text,uuid) FROM PUBLIC,service_role;
GRANT EXECUTE ON FUNCTION public.list_student_home_visits(text,uuid) TO anon,authenticated;
REVOKE ALL ON FUNCTION public.list_school_home_visits(text,int) FROM PUBLIC,service_role;
GRANT EXECUTE ON FUNCTION public.list_school_home_visits(text,int) TO anon,authenticated;

REVOKE ALL ON FUNCTION public.record_sdq_assessment(text,uuid,jsonb,text,text) FROM PUBLIC,service_role;
GRANT EXECUTE ON FUNCTION public.record_sdq_assessment(text,uuid,jsonb,text,text) TO anon,authenticated;
REVOKE ALL ON FUNCTION public.list_student_sdq_assessments(text,uuid) FROM PUBLIC,service_role;
GRANT EXECUTE ON FUNCTION public.list_student_sdq_assessments(text,uuid) TO anon,authenticated;
REVOKE ALL ON FUNCTION public.list_school_sdq_assessments(text,int) FROM PUBLIC,service_role;
GRANT EXECUTE ON FUNCTION public.list_school_sdq_assessments(text,int) TO anon,authenticated;

REVOKE ALL ON FUNCTION public.create_scholarship(text,text,text,numeric,text) FROM PUBLIC,service_role;
GRANT EXECUTE ON FUNCTION public.create_scholarship(text,text,text,numeric,text) TO anon,authenticated;
REVOKE ALL ON FUNCTION public.nominate_scholarship_award(text,uuid,uuid,text) FROM PUBLIC,service_role;
GRANT EXECUTE ON FUNCTION public.nominate_scholarship_award(text,uuid,uuid,text) TO anon,authenticated;
REVOKE ALL ON FUNCTION public.set_scholarship_award_status(text,uuid,text,numeric,text) FROM PUBLIC,service_role;
GRANT EXECUTE ON FUNCTION public.set_scholarship_award_status(text,uuid,text,numeric,text) TO anon,authenticated;
REVOKE ALL ON FUNCTION public.list_scholarships(text) FROM PUBLIC,service_role;
GRANT EXECUTE ON FUNCTION public.list_scholarships(text) TO anon,authenticated;
REVOKE ALL ON FUNCTION public.list_scholarship_awards(text,uuid) FROM PUBLIC,service_role;
GRANT EXECUTE ON FUNCTION public.list_scholarship_awards(text,uuid) TO anon,authenticated;

REVOKE ALL ON FUNCTION public.create_directive(text,uuid,text,text,uuid,uuid,date) FROM PUBLIC,service_role;
GRANT EXECUTE ON FUNCTION public.create_directive(text,uuid,text,text,uuid,uuid,date) TO anon,authenticated;
REVOKE ALL ON FUNCTION public.acknowledge_directive(text,uuid) FROM PUBLIC,service_role;
GRANT EXECUTE ON FUNCTION public.acknowledge_directive(text,uuid) TO anon,authenticated;
REVOKE ALL ON FUNCTION public.complete_directive(text,uuid,text) FROM PUBLIC,service_role;
GRANT EXECUTE ON FUNCTION public.complete_directive(text,uuid,text) TO anon,authenticated;
REVOKE ALL ON FUNCTION public.list_my_directives(text) FROM PUBLIC,service_role;
GRANT EXECUTE ON FUNCTION public.list_my_directives(text) TO anon,authenticated;
REVOKE ALL ON FUNCTION public.list_executive_directives(text) FROM PUBLIC,service_role;
GRANT EXECUTE ON FUNCTION public.list_executive_directives(text) TO anon,authenticated;

REVOKE ALL ON FUNCTION public.list_school_students(text,text) FROM PUBLIC,service_role;
GRANT EXECUTE ON FUNCTION public.list_school_students(text,text) TO anon,authenticated;

REVOKE ALL ON FUNCTION public.get_student_followup_summary(text) FROM PUBLIC,service_role;
GRANT EXECUTE ON FUNCTION public.get_student_followup_summary(text) TO anon,authenticated;

REVOKE ALL ON FUNCTION public.list_executive_students_needing_attention(text) FROM PUBLIC,service_role;
GRANT EXECUTE ON FUNCTION public.list_executive_students_needing_attention(text) TO anon,authenticated;
