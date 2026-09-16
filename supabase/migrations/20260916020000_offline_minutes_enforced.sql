-- platform_settings.offline_minutes was saved by the Super Admin settings page
-- (20260830010000) but never read: device_effective_status() hard-coded
-- "5 minutes". The page even carried a banner saying its values were stored
-- "for reference" only. This makes the one setting that has a real consumer
-- actually drive that consumer.
--
-- STABLE (not IMMUTABLE) because it now reads a table. Callers
-- (list_school_devices, get_school_device_detail) are unchanged.

create or replace function public.device_effective_status(
  p_status device_status,
  p_last_seen_at timestamptz
)
returns device_status
language sql
stable
set search_path = public, extensions
as $$
  select case
    when p_status in ('error', 'maintenance') then p_status
    when p_last_seen_at is null then 'offline'::device_status
    when p_last_seen_at < now() - make_interval(
      mins => coalesce((select ps.offline_minutes from platform_settings ps where ps.id = 1), 5)
    ) then 'offline'::device_status
    else p_status
  end;
$$;
