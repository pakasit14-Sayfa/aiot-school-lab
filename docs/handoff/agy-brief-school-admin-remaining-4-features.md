# Brief for agy: build out the remaining 4 "Coming Soon" school_admin features

`school_admin_dashboard.dart` has 6 menu items, 2 real. This brief covers
the other 4. Checked what backend already exists before designing
anything — 2 of these need **zero new backend**, 1 reuses an existing
RPC pattern, 1 is genuinely new (user confirmed: build it in full,
including the pg_cron scheduling mechanism).

## 1. การใช้พลังงานทั้งโรงเรียน (Energy) — zero new backend, pure UI wiring

`UtilityService` already has everything this needs — it's the exact
same service already wired into `director_environment_page.dart` for
executive:

- `getEnergyUsageSummary(period: ...)` / `getWaterUsageSummary(period: ...)`
- `getEnergyUsageTrend()` / `getWaterUsageTrend()`
- `getEnergyEfficiencyScore()` / `getWaterEfficiencyScore()`

Replace the `ComingSoonCard` for this menu item with a real page calling
these same methods. No migration needed.

## 2. กล้อง CCTV+AI Detection — access-grant half reuses existing RPCs, AI half doesn't exist

Same situation as `director_cctv_page.dart` (already built this
session): `list_camera_access_grants` / `grant_camera_access` /
`revoke_camera_access` already exist and are role-gated for
`school_admin`/`executive`/`super_admin` — reuse directly, no new RPC.

**"AI Detection" has no backend anywhere** — no motion/incident-detection
table tied to cameras exists. Don't build a fake detection feed. Wire
the access-grant management half for real; if AI detection is wanted
later, that's a separate, much bigger scope (needs an actual detection
pipeline, not just a UI) — flag it back rather than mocking alerts.

## 3. ตั้งเวลาเปิด-ปิดอุปกรณ์อัตโนมัติ (Device auto-scheduling) — new, full build with pg_cron

User confirmed: build this in full, including the actual execution
mechanism (`pg_cron`), not just the schedule-storage half.

### Schema

```sql
create extension if not exists pg_cron;

create table public.device_schedules (
  id uuid primary key default gen_random_uuid(),
  device_id uuid not null references public.devices(id),
  school_id uuid not null references public.schools(id),
  label text,
  command jsonb not null,          -- e.g. {"action": "on"} / {"action": "off"}
  days_of_week smallint[] not null, -- 0=Sun..6=Sat, matches class_schedules.day_of_week convention
  time_of_day time not null,
  enabled boolean not null default true,
  created_by uuid not null references public.users(id),
  created_at timestamptz not null default now(),
  last_triggered_at timestamptz
);

alter table public.device_schedules enable row level security;
-- deny-all, RPC-only, same as every other table (CLAUDE.md hard rule 2)
```

### User-facing RPCs (normal token-checked, same pattern as everything else)

- `create_device_schedule(p_token, p_device_id, p_label, p_command, p_days_of_week, p_time_of_day)`
  — role gate: `school_admin`/`super_admin`/`technician`/`facility_manager`,
  same tenant + facility_manager building-scope check as
  `queue_device_command` (copy that exact check, don't re-derive it —
  it's the function this schedule ultimately triggers).
- `list_device_schedules(p_token)` — same role gate, school-scoped.
- `toggle_device_schedule(p_token, p_schedule_id, p_enabled)`,
  `delete_device_schedule(p_token, p_schedule_id)` — same gate + ownership
  check (school-scoped, not just creator-scoped, so any school_admin can
  manage any schedule in their school).

### Execution: internal function + pg_cron job

`pg_cron` runs as `postgres`, no session token — needs a separate
function that isn't part of the normal token-checked RPC surface:

```sql
create or replace function public._run_due_device_schedules()
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_sched record;
begin
  for v_sched in
    select * from device_schedules
    where enabled = true
      and extract(dow from now() at time zone 'Asia/Bangkok')::smallint = any(days_of_week)
      and date_trunc('minute', (now() at time zone 'Asia/Bangkok')::time) = date_trunc('minute', time_of_day)
      and (last_triggered_at is null or last_triggered_at < now() - interval '55 seconds')
  loop
    insert into device_commands (device_id, command, created_by)
    values (v_sched.device_id, v_sched.command, v_sched.created_by);

    update device_schedules set last_triggered_at = now() where id = v_sched.id;
  end loop;
end;
$$;

revoke all on function public._run_due_device_schedules() from public, anon, authenticated;
-- no grant to anon/authenticated at all — this must only ever run as
-- the cron job itself (superuser), never callable by a client.

select cron.schedule('device-schedules-tick', '* * * * *', 'select public._run_due_device_schedules()');
```

Runs every minute, matches on day-of-week + minute-precision time, uses
`last_triggered_at` as a de-dupe guard so a slow tick or DST-adjacent
edge case can't double-fire the same schedule. Timezone: hardcoded
`Asia/Bangkok` — check this matches what `class_schedules` and the rest
of the app already assume before committing to it; grep for how
existing schedule/time features handle timezone if there's already an
established convention.

**Don't skip the actual `cron.schedule(...)` call** — a schedule that's
stored but never fires isn't "built in full," it's just the storage
half again with extra steps. Verify by creating a real schedule 1-2
minutes in the future and confirming a real row lands in
`device_commands` without any manual trigger.

## 4. รายงาน ESG & Green Score — mostly reuses existing efficiency scores

`UtilityEfficiencyScore` (`getEnergyEfficiencyScore()` /
`getWaterEfficiencyScore()`) already computes a `score`/`label` per
utility — this is functionally already an efficiency/green metric, just
not presented as one yet. Proposed approach: combine the two into a
single "Green Score" card (e.g. average of the two scores, or show them
side by side rather than force-combining into one number — whichever
reads better in the actual UI, use judgment). This is a presentation
choice, not new backend — no migration needed for this part.

If "ESG report" is meant to include anything beyond energy/water
(e.g. waste, social/governance metrics), there's no data source for
that anywhere in the schema — flag back before inventing numbers for
it, don't estimate placeholder ESG metrics that aren't backed by
anything real.

## Verify

Same standard as every feature this session — real login as
`schooladmin@aiot-school-lab.local`, real clicks, not
`flutter analyze`/`flutter test` alone:

- Energy/Green Score: numbers match a direct `psql` query against the
  same tables `UtilityService` reads from.
- CCTV: grant/revoke a real access grant, confirm it persists; confirm
  no fake "AI detected motion" content anywhere.
- Device scheduling: create a schedule due in the next 1-2 minutes,
  **wait for it to actually fire** and confirm a real `device_commands`
  row appears without you inserting it manually — this is the one part
  of this brief where "the RPC returned 200" is not enough evidence,
  the cron execution itself has to be observed.
