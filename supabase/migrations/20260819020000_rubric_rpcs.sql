-- =====================================================================
-- ASM-7/8: ระบบเกณฑ์การประเมิน (Rubrics)
-- สร้าง RPC สำหรับจัดการ Rubrics และ Criteria ฝั่งครู
-- Permission Matrix: SA=– AD=R TE=CRUD EX=– ST=– PA=– FM=– TC=–
-- =====================================================================

create or replace function create_rubric(
  p_token text,
  p_title text,
  p_description text default null,
  p_criteria jsonb default '[]'::jsonb
)
returns table (rubric_id uuid)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_rubric_id uuid;
  v_crit jsonb;
  v_sort int := 0;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('school_admin', 'teacher') then
    raise exception 'forbidden';
  end if;

  if trim(coalesce(p_title, '')) = '' then
    raise exception 'title_required';
  end if;

  insert into rubrics (school_id, title, description, created_by)
  values (v_actor.school_id, trim(p_title), trim(p_description), v_actor.user_id)
  returning id into v_rubric_id;

  if p_criteria is not null and jsonb_array_length(p_criteria) > 0 then
    for v_crit in select * from jsonb_array_elements(p_criteria)
    loop
      v_sort := v_sort + 1;
      insert into rubric_criteria (rubric_id, name, description, max_score, levels, sort_order)
      values (
        v_rubric_id,
        coalesce(v_crit ->> 'name', 'เกณฑ์ที่ ' || v_sort),
        v_crit ->> 'description',
        coalesce((v_crit ->> 'max_score')::numeric, 10),
        v_crit -> 'levels',
        v_sort
      );
    end loop;
  end if;

  return query select v_rubric_id;
end;
$$;

create or replace function list_my_rubrics(p_token text)
returns table (
  rubric_id uuid,
  title varchar,
  description text,
  created_by uuid,
  criteria_count bigint,
  used_count bigint
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

  if v_actor.role not in ('school_admin', 'teacher') then
    raise exception 'forbidden';
  end if;

  return query
  select
    r.id as rubric_id,
    r.title,
    r.description,
    r.created_by,
    (select count(*) from rubric_criteria rc where rc.rubric_id = r.id) as criteria_count,
    (select count(*) from assignments a where a.rubric_id = r.id) as used_count
  from rubrics r
  where r.school_id = v_actor.school_id
  order by r.id desc;
end;
$$;

create or replace function get_rubric(p_token text, p_rubric_id uuid)
returns table (
  rubric_id uuid,
  title varchar,
  description text,
  criteria jsonb
)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_rubric rubrics%rowtype;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;

  if v_actor.role not in ('school_admin', 'teacher') then
    raise exception 'forbidden';
  end if;

  select * into v_rubric from rubrics r_check where r_check.id = p_rubric_id;
  if not found then raise exception 'rubric_not_found'; end if;
  if v_rubric.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;

  return query
  select
    r.id as rubric_id,
    r.title,
    r.description,
    coalesce(
      (
        select jsonb_agg(
          jsonb_build_object(
            'id', rc.id,
            'name', rc.name,
            'description', rc.description,
            'max_score', rc.max_score,
            'levels', rc.levels,
            'sort_order', rc.sort_order
          ) order by rc.sort_order
        )
        from rubric_criteria rc
        where rc.rubric_id = r.id
      ),
      '[]'::jsonb
    ) as criteria
  from rubrics r
  where r.id = p_rubric_id;
end;
$$;

create or replace function add_rubric_criterion(
  p_token text,
  p_rubric_id uuid,
  p_name text,
  p_description text default null,
  p_max_score numeric default 10,
  p_levels jsonb default null
)
returns table (criterion_id uuid)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_rubric rubrics%rowtype;
  v_crit_id uuid;
  v_next_sort int;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;

  if v_actor.role not in ('school_admin', 'teacher') then
    raise exception 'forbidden';
  end if;

  select * into v_rubric from rubrics r_check where r_check.id = p_rubric_id;
  if not found then raise exception 'rubric_not_found'; end if;
  if v_rubric.school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;

  if trim(coalesce(p_name, '')) = '' then
    raise exception 'criterion_name_required';
  end if;

  select coalesce(max(rc.sort_order), 0) + 1 into v_next_sort
  from rubric_criteria rc where rc.rubric_id = p_rubric_id;

  insert into rubric_criteria (rubric_id, name, description, max_score, levels, sort_order)
  values (p_rubric_id, trim(p_name), trim(p_description), coalesce(p_max_score, 10), p_levels, v_next_sort)
  returning id into v_crit_id;

  return query select v_crit_id;
end;
$$;

revoke all on function create_rubric(text, text, text, jsonb) from public;
grant execute on function create_rubric(text, text, text, jsonb) to anon, authenticated;

revoke all on function list_my_rubrics(text) from public;
grant execute on function list_my_rubrics(text) to anon, authenticated;

revoke all on function get_rubric(text, uuid) from public;
grant execute on function get_rubric(text, uuid) to anon, authenticated;

revoke all on function add_rubric_criterion(text, uuid, text, text, numeric, jsonb) from public;
grant execute on function add_rubric_criterion(text, uuid, text, text, numeric, jsonb) to anon, authenticated;
