# Brief for agy: Red Team findings on Super Admin (`~/aiot_dev_dashboard`)

Findings from a red-team-style review of the Super Admin system today, verified
against the actual running code and DB (not just the audit-log report). Two
🔴 blockers, two 🟡 should-fix-soon. Ordered by priority.

## 🔴 1. `is_super_admin()` has a hardcoded email bypass — privilege escalation risk

`public.is_super_admin(p_uid uuid default auth.uid())` (defined in
`supabase/migrations/20260823100000_close_anon_rls_holes.sql`) currently reads:

```sql
select exists (
  select 1 from public.users u
  left join public.user_roles ur on ur.user_id = u.id
  where u.id = p_uid and (ur.role = 'super_admin' or u.email = 'admin@aiot-school-lab.local')
);
```

The `or u.email = 'admin@aiot-school-lab.local'` clause means **anyone whose
account ever gets that exact email address is treated as super_admin**,
independent of `user_roles`. `admin@aiot-school-lab.local` already has a real
`super_admin` row in `user_roles` (confirmed via SQL), so the email clause is
dead weight that only adds risk — remove it, don't replace it with anything.

**Fix** — new migration, don't edit `20260823100000` in place:

```sql
create or replace function public.is_super_admin(p_uid uuid default auth.uid())
returns boolean as $$
  select exists (
    select 1 from public.users u
    join public.user_roles ur on ur.user_id = u.id
    where u.id = p_uid and ur.role = 'super_admin'
  );
$$ language sql security definer stable set search_path = public;
```

(Also switched the `left join` to a plain `join` — a super-admin check should
never pass for a user with no role row at all.)

**Verify**: `admin@aiot-school-lab.local` still passes (`select
is_super_admin('c9817872-6a48-461b-88fa-b722b55f454e')` → `true`), and confirm
no other seeded account with an unrelated role suddenly gets `true`.

## 🔴 2. 23 of 27 pages look finished but don't persist anything

Checked every page under `~/aiot_dev_dashboard/lib/pages/` for whether it
actually imports a repository/service that talks to Supabase:

**Real (4):** `dev_dashboard_page.dart`, `device_control_page.dart`,
`learning_platform_page.dart`, `schools_page.dart` — these use
`SchoolRepository`/`DeviceControlRepository`, which wrap `Supabase.instance.client`
for real reads/writes.

**UI-only, no backend at all (23):** `devices_page.dart` (3,031 lines),
`permissions_page.dart` (3,474 lines), `alerts_logs_page.dart` (3,509 lines),
`settings_page.dart` (1,677 lines, literally just `TextEditingController`s
with hardcoded defaults like `'2.2'`, `'35'`, `'45'`), `alerts_logs_page.dart`,
`device_test_page.dart`, `scan_page.dart`, `kiosk_pairing_scanner_page.dart`,
and **all 9 files** under `pages/school_admin/*`.

These aren't small stubs — they're large, detailed UIs (thousands of lines
each) that look complete. A user filling in a form on any of them and hitting
save will lose the data the moment they navigate away or reload, with no
indication anything was wrong. This already caused real confusion today (user
believed everything was built and working based on how it looks).

**Fix, in order of what's most disruptive if left unaddressed:**
1. Short-term (do this first, it's cheap): add a visible banner/badge on
   every one of the 23 pages — something like "โหมดทดสอบ ข้อมูลยังไม่บันทึกจริง"
   — so nobody mistakes a mockup for a working feature. A few lines per page,
   not a redesign.
2. Then wire them to real repositories one at a time, same pattern as
   `SchoolRepository`. Suggest starting with whichever page the actual rollout
   plan needs first — flag which one that is so priority is clear.

## 🟡 3. `supabase_migrations.schema_migrations` doesn't match the files on disk

Several migrations this cycle (including both fixes above, and earlier ones
from both of us) were applied via `docker exec ... psql < file.sql` directly,
bypassing the Supabase CLI's tracking table, because `npx supabase migration
up`/`--include-all` kept erroring on out-of-order/duplicate-version conflicts.
Right now `supabase_migrations.schema_migrations` is missing several files
that are genuinely applied to the DB.

**Fix**: before the next `npx supabase db reset` (which replays every
migration file from scratch and would re-derive a consistent state), do a
full sanity pass: list every file in `supabase/migrations/`, confirm each one
that should be applied is safe to be re-run from empty (all our recent ones
use `create or replace`/`if not exists`/`on conflict`, so a full reset should
converge correctly) — then run the reset and let the CLI rebuild the tracking
table from a clean slate. Don't try to hand-patch the tracking table row by
row, that's more error-prone than just resetting.

## 🟡 4. OTP rate-limit error is a raw exception, not a friendly message

Login as `super_admin`/`school_admin`/`teacher`/`executive` requires OTP
(2FA), with a 60-second resend cooldown enforced server-side
(`auth_sign_in` RPC, `auth_state = 'rate_limited'`). Right now the client
surfaces this as a raw `FunctionException(status: 429, ...)` — confusing,
looks like a crash. Show something like "ส่ง OTP ไปแล้วเมื่อครู่ กรุณารออีก
{n} วินาที" instead, using the `otp_expires_at`/cooldown info already
returned by the RPC.

## How to verify each fix

Same standard as everything else this session — real testing, not just
"analyze passes":
1. #1: real SQL query against `is_super_admin()`, not just reading the function body
2. #2: click through each of the 23 pages after the banner goes in, confirm it's visible; for any page you wire to a real repository, create → reload → confirm the data is still there
3. #3: after `db reset`, `select * from supabase_migrations.schema_migrations order by version` and confirm it has every file in `supabase/migrations/`
4. #4: trigger the cooldown deliberately (log in twice within 60s) and confirm the UI message, not the raw exception, shows
