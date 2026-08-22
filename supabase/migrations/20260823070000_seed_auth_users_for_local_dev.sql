-- =====================================================================
-- Seed auth.users and identities for local Supabase development
-- =====================================================================

create extension if not exists pgcrypto;

insert into auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  recovery_sent_at,
  last_sign_in_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at,
  confirmation_token,
  email_change,
  email_change_token_new,
  recovery_token
)
select
  '00000000-0000-0000-0000-000000000000'::uuid as instance_id,
  u.id,
  'authenticated' as aud,
  'authenticated' as role,
  u.email,
  crypt('Password123!', gen_salt('bf', 10)) as encrypted_password,
  now() as email_confirmed_at,
  now() as recovery_sent_at,
  now() as last_sign_in_at,
  jsonb_build_object('provider', 'email', 'providers', array['email']) as raw_app_meta_data,
  jsonb_build_object(
    'full_name', trim(coalesce(u.first_name, '') || ' ' || coalesce(u.last_name, '')),
    'role', coalesce(ur.role::text, 'school_admin'),
    'school_id', u.school_id
  ) as raw_user_meta_data,
  u.created_at,
  now() as updated_at,
  '' as confirmation_token,
  '' as email_change,
  '' as email_change_token_new,
  '' as recovery_token
from public.users u
left join public.user_roles ur on ur.user_id = u.id
on conflict (id) do update set
  encrypted_password = crypt('Password123!', gen_salt('bf', 10)),
  email_confirmed_at = now(),
  raw_user_meta_data = excluded.raw_user_meta_data;

insert into auth.identities (
  id,
  user_id,
  identity_data,
  provider,
  provider_id,
  last_sign_in_at,
  created_at,
  updated_at
)
select
  gen_random_uuid(),
  u.id,
  jsonb_build_object('sub', u.id::text, 'email', u.email),
  'email',
  u.id::text,
  now(),
  now(),
  now()
from public.users u
where not exists (
  select 1 from auth.identities i where i.user_id = u.id and i.provider = 'email'
);
