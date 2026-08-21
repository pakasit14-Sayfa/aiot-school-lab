-- =====================================================================
-- 1. Terminal Pairing / QR Kiosk Login (student_qr_login_page.dart)
-- Allows a classroom lab terminal or tablet to display a temporary QR code,
-- which an authenticated student scans on their mobile device to instantly
-- authorize and log the lab terminal into their student account.
--
-- 2. Student Support & At-Risk Cases (AI-4 / AI-5 / AI-6 / AI-7 / AI-8)
-- Implements the teacher-driven student support and intervention tracking system,
-- allowing teachers across the school to record observations, categorize concerns
-- (academic, behavioral, emotional, safety), track status (open, in_progress, escalated, resolved),
-- and log follow-up interventions.
-- =====================================================================

-- ---------------------------------------------------------------------
-- Part 1: Terminal Pairing Sessions
-- ---------------------------------------------------------------------
create table if not exists terminal_pairing_sessions (
  id uuid primary key default gen_random_uuid(),
  pairing_code text unique not null,
  terminal_name text,
  status text not null default 'pending' check (status in ('pending', 'claimed', 'expired')),
  session_token text,
  claimed_by_user_id uuid references users(id),
  created_at timestamptz not null default now(),
  expires_at timestamptz not null
);

alter table terminal_pairing_sessions enable row level security;

-- 1.1 Create Pairing Session (Called by Kiosk screen anonymously)
create or replace function create_terminal_pairing_session(p_terminal_name text default null)
returns table (
  pairing_code text,
  expires_at timestamptz
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_code text;
  v_expires timestamptz;
begin
  -- Generate random uppercase pairing code
  v_code := 'aiot-pairing:' || upper(encode(gen_random_bytes(12), 'hex'));
  v_expires := now() + interval '5 minutes';

  insert into terminal_pairing_sessions (pairing_code, terminal_name, status, expires_at)
  values (v_code, coalesce(p_terminal_name, 'Lab Terminal'), 'pending', v_expires);

  return query select v_code, v_expires;
end;
$$;

-- 1.2 Claim Pairing Session (Called by Student on authenticated mobile phone)
create or replace function claim_terminal_pairing_session(
  p_token text,
  p_pairing_code text
)
returns table (
  success boolean,
  student_name text,
  message text
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_user users%rowtype;
  v_session terminal_pairing_sessions%rowtype;
  v_new_token text;
  v_new_token_hash text;
  v_full_name text;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;

  select * into v_user from users where id = v_actor.user_id;
  if not found then raise exception 'user_not_found'; end if;

  v_full_name := trim(coalesce(v_user.first_name, '') || ' ' || coalesce(v_user.last_name, ''));
  if v_full_name = '' then v_full_name := v_user.email; end if;

  select * into v_session from terminal_pairing_sessions
  where pairing_code = trim(p_pairing_code)
    and status = 'pending'
    and expires_at > now();

  if not found then
    return query select false, ''::text, 'รหัส QR นี้หมดอายุหรือไม่ถูกต้อง'::text;
    return;
  end if;

  -- Generate a fresh session token for the terminal
  v_new_token := 'tkn_' || encode(gen_random_bytes(24), 'hex');
  v_new_token_hash := encode(digest(v_new_token, 'sha256'), 'hex');

  insert into sessions (
    user_id,
    active_role,
    active_school_id,
    token_hash,
    device_info,
    expires_at
  )
  values (
    v_actor.user_id,
    v_actor.role,
    v_actor.school_id,
    v_new_token_hash,
    coalesce(v_session.terminal_name, 'Kiosk Terminal'),
    now() + interval '30 days'
  );

  update terminal_pairing_sessions
  set status = 'claimed',
      session_token = v_new_token,
      claimed_by_user_id = v_actor.user_id
  where id = v_session.id;

  return query select true, v_full_name, 'เข้าสู่ระบบบนเครื่องแล็บสำเร็จ'::text;
end;
$$;

-- 1.3 Check Pairing Status (Called by Kiosk terminal polling for claim)
create or replace function check_terminal_pairing_status(p_pairing_code text)
returns table (
  status text,
  session_token text,
  student_name text
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_session terminal_pairing_sessions%rowtype;
  v_user users%rowtype;
  v_name text := '';
begin
  select * into v_session from terminal_pairing_sessions
  where pairing_code = trim(p_pairing_code);

  if not found then
    return query select 'not_found'::text, null::text, ''::text;
    return;
  end if;

  if v_session.status = 'pending' and v_session.expires_at <= now() then
    update terminal_pairing_sessions set status = 'expired' where id = v_session.id;
    return query select 'expired'::text, null::text, ''::text;
    return;
  end if;

  if v_session.status = 'claimed' and v_session.claimed_by_user_id is not null then
    select * into v_user from users where id = v_session.claimed_by_user_id;
    if found then
      v_name := trim(coalesce(v_user.first_name, '') || ' ' || coalesce(v_user.last_name, ''));
      if v_name = '' then v_name := v_user.email; end if;
    end if;
  end if;

  return query select v_session.status, v_session.session_token, v_name;
end;
$$;

grant execute on function create_terminal_pairing_session(text) to anon, authenticated;
grant execute on function claim_terminal_pairing_session(text, text) to authenticated;
grant execute on function check_terminal_pairing_status(text) to anon, authenticated;


-- ---------------------------------------------------------------------
-- Part 2: Student Support & At-Risk System (AI-4 / AI-5 / AI-6 / AI-7 / AI-8)
-- ---------------------------------------------------------------------
create table if not exists student_support_cases (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references schools(id),
  student_id uuid not null references users(id),
  course_id uuid references courses(id),
  category text not null default 'academic' check (category in ('academic', 'behavioral', 'emotional', 'safety')),
  risk_level text not null default 'medium' check (risk_level in ('low', 'medium', 'high')),
  status text not null default 'open' check (status in ('open', 'in_progress', 'escalated', 'resolved')),
  title text not null,
  notes text,
  created_by uuid not null references users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists student_support_interventions (
  id uuid primary key default gen_random_uuid(),
  case_id uuid not null references student_support_cases(id) on delete cascade,
  action_type text not null check (action_type in ('counseling', 'remedial_lesson', 'parent_meeting', 'activity_assigned', 'observation')),
  notes text not null,
  recorded_by uuid not null references users(id),
  created_at timestamptz not null default now()
);

alter table student_support_cases enable row level security;
alter table student_support_interventions enable row level security;

-- 2.1 List Support Cases
create or replace function list_student_support_cases(
  p_token text,
  p_course_id uuid default null,
  p_status text default null
)
returns table (
  case_id uuid,
  student_id uuid,
  student_name text,
  student_email text,
  course_id uuid,
  course_name text,
  category text,
  risk_level text,
  status text,
  title text,
  notes text,
  created_by_name text,
  intervention_count bigint,
  created_at timestamptz,
  updated_at timestamptz
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
  if v_actor.role <> 'teacher' and v_actor.role <> 'school_admin' then
    raise exception 'forbidden';
  end if;

  return query
  select
    c.id as case_id,
    c.student_id,
    trim(coalesce(u.first_name, '') || ' ' || coalesce(u.last_name, '')) as student_name,
    u.email as student_email,
    c.course_id,
    coalesce(crs.subject_name, 'ภาพรวมทั่วไป') as course_name,
    c.category,
    c.risk_level,
    c.status,
    c.title,
    c.notes,
    trim(coalesce(creator.first_name, '') || ' ' || coalesce(creator.last_name, '')) as created_by_name,
    count(i.id) as intervention_count,
    c.created_at,
    c.updated_at
  from student_support_cases c
  join users u on u.id = c.student_id
  join users creator on creator.id = c.created_by
  left join courses crs on crs.id = c.course_id
  left join student_support_interventions i on i.case_id = c.id
  where c.school_id = v_actor.school_id
    and (p_course_id is null or c.course_id = p_course_id)
    and (p_status is null or c.status = p_status)
  group by c.id, u.id, creator.id, crs.id
  order by
    case c.risk_level when 'high' then 1 when 'medium' then 2 else 3 end,
    c.updated_at desc;
end;
$$;

-- 2.2 Create Support Case
create or replace function create_student_support_case(
  p_token text,
  p_student_id uuid,
  p_course_id uuid default null,
  p_category text default 'academic',
  p_risk_level text default 'medium',
  p_title text default '',
  p_notes text default null
)
returns table (case_id uuid)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_student users%rowtype;
  v_new_id uuid;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role <> 'teacher' and v_actor.role <> 'school_admin' then
    raise exception 'forbidden';
  end if;

  select * into v_student from users where id = p_student_id and school_id = v_actor.school_id;
  if not found then raise exception 'student_not_found'; end if;

  if trim(coalesce(p_title, '')) = '' then
    raise exception 'title_required';
  end if;

  insert into student_support_cases (
    school_id,
    student_id,
    course_id,
    category,
    risk_level,
    status,
    title,
    notes,
    created_by
  )
  values (
    v_actor.school_id,
    p_student_id,
    p_course_id,
    p_category,
    p_risk_level,
    'open',
    trim(p_title),
    p_notes,
    v_actor.user_id
  )
  returning id into v_new_id;

  return query select v_new_id;
end;
$$;

-- 2.3 Update Support Case Status
create or replace function update_student_support_case_status(
  p_token text,
  p_case_id uuid,
  p_status text,
  p_note text default null
)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_case student_support_cases%rowtype;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role <> 'teacher' and v_actor.role <> 'school_admin' then
    raise exception 'forbidden';
  end if;

  select * into v_case from student_support_cases
  where id = p_case_id and school_id = v_actor.school_id;
  if not found then raise exception 'case_not_found'; end if;

  update student_support_cases
  set status = p_status,
      updated_at = now()
  where id = p_case_id;

  if p_note is not null and trim(p_note) <> '' then
    insert into student_support_interventions (case_id, action_type, notes, recorded_by)
    values (p_case_id, 'observation', trim(p_note), v_actor.user_id);
  end if;
end;
$$;

-- 2.4 Add Support Intervention
create or replace function add_student_support_intervention(
  p_token text,
  p_case_id uuid,
  p_action_type text,
  p_notes text
)
returns table (intervention_id uuid)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_case student_support_cases%rowtype;
  v_new_id uuid;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role <> 'teacher' and v_actor.role <> 'school_admin' then
    raise exception 'forbidden';
  end if;

  select * into v_case from student_support_cases
  where id = p_case_id and school_id = v_actor.school_id;
  if not found then raise exception 'case_not_found'; end if;

  if trim(coalesce(p_notes, '')) = '' then
    raise exception 'notes_required';
  end if;

  insert into student_support_interventions (
    case_id,
    action_type,
    notes,
    recorded_by
  )
  values (
    p_case_id,
    p_action_type,
    trim(p_notes),
    v_actor.user_id
  )
  returning id into v_new_id;

  update student_support_cases set updated_at = now() where id = p_case_id;

  return query select v_new_id;
end;
$$;

-- 2.5 List Interventions for a Case
create or replace function list_student_support_interventions(
  p_token text,
  p_case_id uuid
)
returns table (
  intervention_id uuid,
  case_id uuid,
  action_type text,
  notes text,
  recorded_by_name text,
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
  if v_actor.role <> 'teacher' and v_actor.role <> 'school_admin' then
    raise exception 'forbidden';
  end if;

  return query
  select
    i.id as intervention_id,
    i.case_id,
    i.action_type,
    i.notes,
    trim(coalesce(u.first_name, '') || ' ' || coalesce(u.last_name, '')) as recorded_by_name,
    i.created_at
  from student_support_interventions i
  join users u on u.id = i.recorded_by
  where i.case_id = p_case_id
  order by i.created_at desc;
end;
$$;

grant execute on function list_student_support_cases(text, uuid, text) to authenticated;
grant execute on function create_student_support_case(text, uuid, uuid, text, text, text, text) to authenticated;
grant execute on function update_student_support_case_status(text, uuid, text, text) to authenticated;
grant execute on function add_student_support_intervention(text, uuid, text, text) to authenticated;
grant execute on function list_student_support_interventions(text, uuid) to authenticated;
