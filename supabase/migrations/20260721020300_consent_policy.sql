-- =====================================================================
-- Consent policy + consent history (PDPA gate 2, part 3).
-- Current state lives in consents; every transition is appended to
-- consent_events and audit_logs with the exact policy version.
-- =====================================================================

alter table consent_policies
  add column if not exists is_required boolean not null default false;

create or replace function list_consent_policies_admin(
  p_token text,
  p_school_id uuid default null
)
returns table (
  policy_id uuid,
  school_id uuid,
  consent_type varchar,
  version varchar,
  document_hash varchar,
  content_url varchar,
  is_required boolean,
  effective_at timestamptz,
  retired_at timestamptz
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
  if v_actor.role not in ('school_admin', 'super_admin') then
    raise exception 'forbidden';
  end if;

  v_school_id := case
    when v_actor.role = 'super_admin' then p_school_id
    else v_actor.school_id
  end;
  if v_school_id is null then raise exception 'school_required'; end if;
  if v_actor.role <> 'super_admin'
     and p_school_id is not null
     and p_school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;

  return query
  select cp.id, cp.school_id, cp.consent_type, cp.version,
         cp.document_hash, cp.content_url, cp.is_required,
         cp.effective_at, cp.retired_at
  from consent_policies cp
  where cp.school_id = v_school_id
  order by cp.consent_type, cp.effective_at desc;
end;
$$;

create or replace function publish_consent_policy(
  p_token text,
  p_consent_type text,
  p_version text,
  p_document_hash text,
  p_content_url text,
  p_is_required boolean default false,
  p_effective_at timestamptz default now(),
  p_school_id uuid default null
)
returns uuid
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_school_id uuid;
  v_policy_id uuid;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('school_admin', 'super_admin') then
    raise exception 'forbidden';
  end if;

  v_school_id := case
    when v_actor.role = 'super_admin' then p_school_id
    else v_actor.school_id
  end;
  if v_school_id is null then raise exception 'school_required'; end if;
  if v_actor.role <> 'super_admin'
     and p_school_id is not null
     and p_school_id is distinct from v_actor.school_id then
    raise exception 'forbidden';
  end if;
  if nullif(trim(p_consent_type), '') is null
     or length(trim(p_consent_type)) > 100 then
    raise exception 'invalid_consent_type';
  end if;
  if nullif(trim(p_version), '') is null or length(trim(p_version)) > 50 then
    raise exception 'invalid_policy_version';
  end if;
  if lower(trim(p_document_hash)) !~ '^[0-9a-f]{64}$' then
    raise exception 'invalid_document_hash';
  end if;
  if trim(p_content_url) !~* '^https://[^[:space:]]+$'
     or length(trim(p_content_url)) > 2048 then
    raise exception 'invalid_content_url';
  end if;

  insert into consent_policies (
    school_id, consent_type, version, document_hash, content_url,
    is_required, effective_at, created_by
  ) values (
    v_school_id, trim(p_consent_type), trim(p_version),
    lower(trim(p_document_hash)), trim(p_content_url),
    coalesce(p_is_required, false), coalesce(p_effective_at, now()),
    v_actor.user_id
  )
  returning id into v_policy_id;

  insert into audit_logs (
    school_id, user_id, acted_role, action, entity_type, entity_id, details
  ) values (
    v_school_id, v_actor.user_id, v_actor.role,
    'consent_policy.publish', 'consent_policies', v_policy_id::text,
    jsonb_build_object(
      'consent_type', trim(p_consent_type),
      'version', trim(p_version),
      'document_hash', lower(trim(p_document_hash)),
      'is_required', coalesce(p_is_required, false),
      'effective_at', coalesce(p_effective_at, now())
    )
  );
  return v_policy_id;
exception when unique_violation then
  raise exception 'policy_version_already_exists';
end;
$$;

create or replace function retire_consent_policy(
  p_token text,
  p_policy_id uuid
)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_policy consent_policies%rowtype;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role not in ('school_admin', 'super_admin') then
    raise exception 'forbidden';
  end if;

  select * into v_policy
  from consent_policies
  where id = p_policy_id
  for update;
  if not found then raise exception 'policy_not_found'; end if;
  if v_actor.role <> 'super_admin'
     and v_actor.school_id is distinct from v_policy.school_id then
    raise exception 'forbidden';
  end if;
  if v_policy.retired_at is not null then raise exception 'policy_retired'; end if;

  update consent_policies set retired_at = now() where id = p_policy_id;
  insert into audit_logs (
    school_id, user_id, acted_role, action, entity_type, entity_id, details
  ) values (
    v_policy.school_id, v_actor.user_id, v_actor.role,
    'consent_policy.retire', 'consent_policies', p_policy_id::text,
    jsonb_build_object(
      'consent_type', v_policy.consent_type,
      'version', v_policy.version,
      'document_hash', v_policy.document_hash
    )
  );
end;
$$;

revoke all on function list_consent_policies_admin(text, uuid) from public;
revoke all on function publish_consent_policy(
  text, text, text, text, text, boolean, timestamptz, uuid
) from public;
revoke all on function retire_consent_policy(text, uuid) from public;
grant execute on function list_consent_policies_admin(text, uuid)
  to anon, authenticated;
grant execute on function publish_consent_policy(
  text, text, text, text, text, boolean, timestamptz, uuid
) to anon, authenticated;
grant execute on function retire_consent_policy(text, uuid)
  to anon, authenticated;

create or replace function list_active_consent_policies(p_token text)
returns table (
  policy_id uuid,
  consent_type varchar,
  version varchar,
  document_hash varchar,
  content_url varchar,
  effective_at timestamptz
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

  return query
  select cp.id, cp.consent_type, cp.version, cp.document_hash,
         cp.content_url, cp.effective_at
  from consent_policies cp
  where (cp.school_id is null or cp.school_id = v_actor.school_id)
    and cp.effective_at <= now()
    and (cp.retired_at is null or cp.retired_at > now())
  order by cp.consent_type, cp.effective_at desc;
end;
$$;

create or replace function grant_parent_consent(
  p_token text,
  p_parent_link_id uuid,
  p_policy_id uuid,
  p_evidence jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_link parent_links%rowtype;
  v_policy consent_policies%rowtype;
  v_consent_id uuid;
  v_evidence jsonb;
  v_evidence_hash text;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role <> 'parent' then raise exception 'forbidden'; end if;

  select pl.* into v_link
  from parent_links pl
  join users student on student.id = pl.student_id
  where pl.id = p_parent_link_id
    and pl.parent_id = v_actor.user_id
    and pl.status = 'approved'
    and student.school_id = v_actor.school_id;
  if not found then raise exception 'approved_parent_link_required'; end if;

  select * into v_policy from consent_policies
  where id = p_policy_id
    and (school_id is null or school_id = v_actor.school_id)
    and effective_at <= now()
    and (retired_at is null or retired_at > now());
  if not found then raise exception 'active_policy_required'; end if;

  if coalesce((p_evidence->>'confirmed_read')::boolean, false) is not true then
    raise exception 'policy_read_confirmation_required';
  end if;

  v_evidence := coalesce(p_evidence, '{}'::jsonb) || jsonb_build_object(
    'policy_version', v_policy.version,
    'policy_document_hash', v_policy.document_hash,
    'actor_id', v_actor.user_id,
    'recorded_at', now()
  );
  v_evidence_hash := encode(digest(v_evidence::text, 'sha256'), 'hex');

  insert into consents (
    parent_link_id, policy_id, status, granted_by, granted_at,
    withdrawn_at, evidence_hash, details
  )
  values (
    v_link.id, v_policy.id, 'granted', v_actor.user_id, now(),
    null, v_evidence_hash, v_evidence
  )
  on conflict (parent_link_id, policy_id) do update
  set status = 'granted',
      granted_by = excluded.granted_by,
      granted_at = excluded.granted_at,
      withdrawn_at = null,
      evidence_hash = excluded.evidence_hash,
      details = excluded.details
  returning id into v_consent_id;

  insert into consent_events (
    consent_id, policy_id, actor_id, action, evidence
  )
  values (
    v_consent_id, v_policy.id, v_actor.user_id, 'granted',
    v_evidence || jsonb_build_object('evidence_hash', v_evidence_hash)
  );

  insert into audit_logs (
    school_id, user_id, acted_role, action, entity_type, entity_id, details
  )
  values (
    v_actor.school_id, v_actor.user_id, v_actor.role,
    'consent.grant', 'consents', v_consent_id::text,
    jsonb_build_object(
      'policy_id', v_policy.id,
      'policy_version', v_policy.version,
      'evidence_hash', v_evidence_hash
    )
  );

  return v_consent_id;
end;
$$;

create or replace function withdraw_parent_consent(
  p_token text,
  p_consent_id uuid,
  p_reason text default null
)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_actor record;
  v_consent consents%rowtype;
  v_evidence jsonb;
begin
  select * into v_actor from get_session_actor(p_token);
  if not found then raise exception 'invalid_session'; end if;
  if v_actor.role <> 'parent' then raise exception 'forbidden'; end if;

  select c.* into v_consent
  from consents c
  join parent_links pl on pl.id = c.parent_link_id
  join users student on student.id = pl.student_id
  where c.id = p_consent_id
    and pl.parent_id = v_actor.user_id
    and student.school_id = v_actor.school_id
    and c.status = 'granted'
  for update of c;
  if not found then raise exception 'active_consent_not_found'; end if;

  v_evidence := jsonb_build_object(
    'reason', nullif(trim(p_reason), ''),
    'actor_id', v_actor.user_id,
    'recorded_at', now(),
    'previous_evidence_hash', v_consent.evidence_hash
  );

  update consents
  set status = 'withdrawn', withdrawn_at = now()
  where id = v_consent.id;

  insert into consent_events (
    consent_id, policy_id, actor_id, action, evidence
  )
  values (
    v_consent.id, v_consent.policy_id, v_actor.user_id,
    'withdrawn', v_evidence
  );

  insert into audit_logs (
    school_id, user_id, acted_role, action, entity_type, entity_id, details
  )
  values (
    v_actor.school_id, v_actor.user_id, v_actor.role,
    'consent.withdraw', 'consents', v_consent.id::text,
    jsonb_build_object('policy_id', v_consent.policy_id)
  );
end;
$$;

revoke all on function list_active_consent_policies(text) from public;
revoke all on function grant_parent_consent(text, uuid, uuid, jsonb) from public;
revoke all on function withdraw_parent_consent(text, uuid, text) from public;
grant execute on function list_active_consent_policies(text) to anon, authenticated;
grant execute on function grant_parent_consent(text, uuid, uuid, jsonb)
  to anon, authenticated;
grant execute on function withdraw_parent_consent(text, uuid, text)
  to anon, authenticated;

create or replace function list_my_parent_links(p_token text)
returns table (
  parent_link_id uuid,
  student_id uuid,
  student_first_name varchar,
  student_last_name varchar,
  relationship varchar,
  status binding_status
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

  return query
  select pl.id, pl.student_id, u.first_name, u.last_name,
         pl.relationship, pl.status
  from parent_links pl
  join users u on u.id = pl.student_id
  where pl.parent_id = v_actor.user_id
    and u.school_id = v_actor.school_id
  order by u.first_name, u.last_name;
end;
$$;

create or replace function list_my_consents(
  p_token text,
  p_parent_link_id uuid
)
returns table (
  consent_id uuid,
  policy_id uuid,
  consent_type varchar,
  version varchar,
  document_hash varchar,
  content_url varchar,
  is_required boolean,
  status consent_status,
  granted_at timestamptz,
  withdrawn_at timestamptz
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
    select 1
    from parent_links pl
    join users student on student.id = pl.student_id
    where pl.id = p_parent_link_id
      and pl.parent_id = v_actor.user_id
      and student.school_id = v_actor.school_id
  ) then
    raise exception 'forbidden';
  end if;

  return query
  select c.id, cp.id, cp.consent_type, cp.version,
         cp.document_hash, cp.content_url, cp.is_required, c.status,
         c.granted_at, c.withdrawn_at
  from consent_policies cp
  left join consents c
    on c.policy_id = cp.id
   and c.parent_link_id = p_parent_link_id
  where (cp.school_id is null or cp.school_id = v_actor.school_id)
    and cp.effective_at <= now()
    and (cp.retired_at is null or cp.retired_at > now())
  order by cp.consent_type, cp.effective_at desc;
end;
$$;

revoke all on function list_my_parent_links(text) from public;
revoke all on function list_my_consents(text, uuid) from public;
grant execute on function list_my_parent_links(text) to anon, authenticated;
grant execute on function list_my_consents(text, uuid) to anon, authenticated;
