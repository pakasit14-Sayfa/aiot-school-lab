-- =====================================================================
-- Parent-link approval (PDPA gate 2, part 2): the explicitly-audited
-- small-school conflict-of-interest path.
-- =====================================================================

create or replace function approve_parent_link(
  p_token text,
  p_parent_link_id uuid
)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_link parent_links%rowtype;
  v_school_id uuid;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('school_admin', 'teacher', 'super_admin') then
    raise exception 'forbidden';
  end if;

  select * into v_link from parent_links
  where id = p_parent_link_id
  for update;
  if not found then raise exception 'link_not_found'; end if;
  if v_link.status <> 'pending' then raise exception 'link_not_pending'; end if;

  select school_id into v_school_id from users where id = v_link.student_id;
  if v_actor.role <> 'super_admin'
     and v_actor.school_id is distinct from v_school_id then
    raise exception 'forbidden';
  end if;

  if v_actor.role = 'teacher' and not exists (
    select 1
    from course_teachers ct
    join course_students cs on cs.course_id = ct.course_id
    where ct.teacher_id = v_actor.user_id
      and cs.student_id = v_link.student_id
  ) then
    raise exception 'forbidden';
  end if;

  if v_actor.user_id = v_link.parent_id then
    raise exception 'coi_self_approval_blocked';
  end if;

  update parent_links
  set status = 'approved',
      approved_by = v_actor.user_id,
      approved_at = now(),
      first_reviewed_by = v_actor.user_id,
      first_reviewed_at = now(),
      coi_conflict = false
  where id = p_parent_link_id;

  insert into user_roles (user_id, role, school_id, granted_by)
  values (v_link.parent_id, 'parent', v_school_id, v_actor.user_id)
  on conflict (user_id, role, school_id) do nothing;

  insert into audit_logs (
    school_id, user_id, acted_role, action, entity_type, entity_id
  )
  values (
    v_school_id, v_actor.user_id, v_actor.role,
    'parent_link.approve', 'parent_links', p_parent_link_id::text
  );
end;
$$;

create or replace function request_parent_link_second_review(
  p_token text,
  p_parent_link_id uuid,
  p_exception_reason text
)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_link parent_links%rowtype;
  v_school_id uuid;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role <> 'school_admin' then raise exception 'forbidden'; end if;
  if nullif(trim(p_exception_reason), '') is null then
    raise exception 'exception_reason_required';
  end if;

  select * into v_link from parent_links
  where id = p_parent_link_id
  for update;
  if not found then raise exception 'link_not_found'; end if;
  if v_link.status <> 'pending' then raise exception 'link_not_pending'; end if;

  select school_id into v_school_id from users where id = v_link.student_id;
  if v_actor.school_id is distinct from v_school_id then
    raise exception 'forbidden';
  end if;
  if v_actor.user_id <> v_link.parent_id then
    raise exception 'exception_only_for_self_approval_coi';
  end if;

  update parent_links
  set status = 'pending_second_review',
      coi_conflict = true,
      exception_reason = trim(p_exception_reason),
      first_reviewed_by = v_actor.user_id,
      first_reviewed_at = now()
  where id = p_parent_link_id;

  insert into audit_logs (
    school_id, user_id, acted_role, action, entity_type, entity_id, details
  )
  values (
    v_school_id, v_actor.user_id, v_actor.role,
    'parent_link.request_second_review', 'parent_links',
    p_parent_link_id::text,
    jsonb_build_object('reason', trim(p_exception_reason), 'sla_hours', 24)
  );
end;
$$;

create or replace function second_approve_parent_link(
  p_token text,
  p_parent_link_id uuid
)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_link parent_links%rowtype;
  v_school_id uuid;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role <> 'school_admin' then raise exception 'forbidden'; end if;

  select * into v_link from parent_links
  where id = p_parent_link_id
  for update;
  if not found then raise exception 'link_not_found'; end if;
  if v_link.status <> 'pending_second_review' then
    raise exception 'second_review_not_pending';
  end if;
  if v_link.first_reviewed_by = v_actor.user_id then
    raise exception 'second_reviewer_must_be_different';
  end if;
  if v_actor.user_id = v_link.parent_id then
    raise exception 'coi_self_approval_blocked';
  end if;

  select school_id into v_school_id from users where id = v_link.student_id;
  if v_actor.school_id is distinct from v_school_id then
    raise exception 'forbidden';
  end if;

  update parent_links
  set status = 'approved',
      approved_by = v_actor.user_id,
      approved_at = now(),
      second_approved_by = v_actor.user_id,
      second_approved_at = now()
  where id = p_parent_link_id;

  insert into user_roles (user_id, role, school_id, granted_by)
  values (v_link.parent_id, 'parent', v_school_id, v_actor.user_id)
  on conflict (user_id, role, school_id) do nothing;

  insert into audit_logs (
    school_id, user_id, acted_role, action, entity_type, entity_id, details
  )
  values (
    v_school_id, v_actor.user_id, v_actor.role,
    'parent_link.second_approve', 'parent_links', p_parent_link_id::text,
    jsonb_build_object(
      'first_reviewer', v_link.first_reviewed_by,
      'elapsed_seconds', extract(epoch from (now() - v_link.first_reviewed_at))
    )
  );
end;
$$;

create or replace function reject_parent_link(
  p_token text,
  p_parent_link_id uuid,
  p_reason text default null
)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_link parent_links%rowtype;
  v_school_id uuid;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('school_admin', 'teacher', 'super_admin') then
    raise exception 'forbidden';
  end if;
  if nullif(trim(p_reason), '') is null then
    raise exception 'rejection_reason_required';
  end if;

  select * into v_link from parent_links
  where id = p_parent_link_id
  for update;
  if not found then raise exception 'link_not_found'; end if;
  if v_link.status not in ('pending', 'pending_second_review') then
    raise exception 'link_not_pending';
  end if;

  select school_id into v_school_id from users where id = v_link.student_id;
  if v_actor.role <> 'super_admin'
     and v_actor.school_id is distinct from v_school_id then
    raise exception 'forbidden';
  end if;
  if v_link.status = 'pending_second_review'
     and v_actor.role <> 'school_admin' then
    raise exception 'forbidden';
  end if;
  if v_actor.role = 'teacher' and not exists (
    select 1
    from course_teachers ct
    join course_students cs on cs.course_id = ct.course_id
    where ct.teacher_id = v_actor.user_id
      and cs.student_id = v_link.student_id
  ) then
    raise exception 'forbidden';
  end if;

  update parent_links
  set status = 'rejected',
      rejected_by = v_actor.user_id,
      rejected_at = now(),
      rejection_reason = trim(p_reason),
      first_reviewed_by = coalesce(first_reviewed_by, v_actor.user_id),
      first_reviewed_at = coalesce(first_reviewed_at, now())
  where id = p_parent_link_id;

  insert into audit_logs (
    school_id, user_id, acted_role, action, entity_type, entity_id, details
  )
  values (
    v_school_id, v_actor.user_id, v_actor.role,
    'parent_link.reject', 'parent_links', p_parent_link_id::text,
    jsonb_build_object(
      'reason', trim(p_reason),
      'previous_status', v_link.status
    )
  );
end;
$$;

revoke all on function approve_parent_link(text, uuid) from public;
revoke all on function request_parent_link_second_review(text, uuid, text) from public;
revoke all on function second_approve_parent_link(text, uuid) from public;
revoke all on function reject_parent_link(text, uuid, text) from public;
grant execute on function approve_parent_link(text, uuid) to anon, authenticated;
grant execute on function request_parent_link_second_review(text, uuid, text)
  to anon, authenticated;
grant execute on function second_approve_parent_link(text, uuid)
  to anon, authenticated;
grant execute on function reject_parent_link(text, uuid, text)
  to anon, authenticated;
