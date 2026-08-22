-- =====================================================================
-- RedTeam Security Fix: Remove Hardcoded Email Bypass from is_super_admin
-- =====================================================================

create or replace function public.is_super_admin(p_uid uuid default auth.uid())
returns boolean as $$
  select exists (
    select 1 from public.users u
    join public.user_roles ur on ur.user_id = u.id
    where u.id = p_uid and ur.role = 'super_admin'
  );
$$ language sql security definer stable set search_path = public;
