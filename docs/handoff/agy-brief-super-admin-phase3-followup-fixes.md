# Brief for agy: 3 issues found independently verifying Phase 3

## Context

Phase 3's report claimed all 6 pages done at 100%, all tests passing.
I independently re-verified (not taken on the report alone, same
standard as every phase before this one) — most of it holds up: no new
migrations needed and none of the dangerous `catch (_) {}` /
`if (data.isNotEmpty)` patterns from earlier phases reappeared in the
core data paths, navigation wiring is correct, the root shell was
correctly left untouched. But 3 specific things don't match the "100%,
real backend" framing in the report. Fix these 3, nothing else needs
touching.

## 1. `super_admin_device_test_page.dart` — the diagnostic numbers are fabricated, not measured

`_checks[0]`/`_checks[1]`/`_checks[2]` ("Supabase Database & Realtime
API", "Session Token & Authentication RPC", "Telemetry & Ingestion
Pipeline") are initialized with hardcoded `latencyMs: 45` / `28` / `62`
(lines 34/41/48), and `_runAllTests()` (lines 113-125) just does
`await Future.delayed(const Duration(milliseconds: 600))` then sets
different hardcoded numbers (`38`/`24`/`55`) — no real timing, no real
network call happens for these 3 checks at all. Only `_checks[3]`
(MQTT Gateway) is honest about being unmeasured
(`'ฮาร์ดแวร์จริงยังไม่เชื่อมต่อ (โหมดจำลอง)'`).

The page-level disclosure banner at the top ("การทดสอบนี้เป็นการตรวจสอบ
ความพร้อมของ API และสถานะระบบส่วนกลาง") implies these ARE real API
checks — which makes the fabricated numbers worse, not better: it's a
believable claim of real measurement sitting on top of fake data,
exactly the pattern `agy-brief-school-admin-fake-fallback-data.md`
already established must not happen.

**Fix**: for each of the 3 checks, wrap an actual real call with a
stopwatch and report the real elapsed time:
- Check 0 (Database & Realtime): time `_service.fetchDeviceControlData()`
  itself, or a lightweight real query if that's too heavy to run on
  every "test" click.
- Check 1 (Session/Auth): time a real `get_session_actor`-backed RPC
  call (any cheap existing one — reuse, don't add a new RPC just for
  this).
- Check 2 (Telemetry/Ingestion): check real data freshness instead of
  a fake latency — e.g. how recent the newest real `sensor_readings`
  row is, and report that (or a real "no recent readings" state) rather
  than a made-up millisecond count.

If a check genuinely can't be backed by anything real yet, mark it
`idle`/`unmeasured` with the same honest wording `_checks[3]` already
uses — don't leave a plausible-looking fake number instead.

## 2. `super_admin_devices_page.dart` — same fake-fallback bug already fixed once today, reintroduced here

Lines 72-73:
```dart
building: d.building.isNotEmpty ? d.building : 'อาคาร 1',
room: d.room.isNotEmpty ? d.room : 'ห้อง Lab',
```
This is the exact same class of bug fixed in `school_devices_page.dart`
earlier today (`'อาคารเรียน A'` → `'ไม่ระบุ'`, see HANDOFF.md section 11)
— a plausible-looking fake value standing in for missing real data,
indistinguishable from a real building/room name. **Fix**: same pattern
as the school_admin fix — `d.building.isNotEmpty ? d.building : 'ไม่ระบุ'`,
`d.room.isNotEmpty ? d.room : 'ไม่ระบุ'`. Grep this file (and the other
5 Phase 3 pages) for any other `: 'อาคาร N'` / `: 'ห้อง X'` / similar
plausible-fake-string fallbacks before calling this done — this
specific instance is the one I found, there may be others I didn't
have time to check line-by-line.

## 3. `list_school_admin_audit_logs` — super_admin only sees 17% of real audit logs, silently

RPC's `WHERE` clause: `(al.school_id = v_actor.school_id OR al.school_id
IS NULL)`. A real super_admin session has `active_school_id = NULL`
(confirmed via `select active_school_id from sessions where
user_id=...` against the real seeded super_admin account). In SQL,
`NULL = NULL` evaluates to `NULL`, not `TRUE`, so the first branch never
matches for a super_admin — only the `IS NULL` branch does. Real data
right now: 141 total audit log rows, 117 have a real `school_id` (school-
specific actions), only 24 are global (`school_id IS NULL`). **A
super_admin viewing "Audit Logs" today sees 24 of 141 real entries
(17%)** — silently missing 83% of the real audit trail, while the page
presents itself as the cross-school oversight view.

**Fix**: add the same bypass `list_school_alerts` already correctly has
(`WHERE (v_actor.role = 'super_admin' OR d.school_id = v_actor.school_id)`
— note it checks the role explicitly, not just a null-comparison
coincidence). New migration:
```sql
create or replace function public.list_school_admin_audit_logs(p_token text, p_limit int default 20)
...
where (v_actor.role = 'super_admin' or al.school_id = v_actor.school_id or al.school_id is null)
...
```
Check the exact current function body with `pg_get_functiondef` first
rather than guessing the full signature — only the `WHERE` clause needs
changing, don't touch anything else about it (school_admin's own usage
of this RPC must keep working identically — verify that after the
change, not just the super_admin path).

## Verify

1. Device test page: click "เริ่มทดสอบระบบทั้งหมด" twice in a row, confirm the reported numbers actually differ if the underlying real timing differs (a suspiciously identical number every single run is a sign it's still fake) — or confirm an honest "unmeasured" state where a real number genuinely isn't available yet.
2. Devices page: find or create a real device row with an empty `location`, confirm it now renders "ไม่ระบุ" not a fake building/room name.
3. Audit logs: log in as the real super_admin account, open Audit Logs, confirm the count now reflects real school-scoped entries too (compare against `select count(*) from audit_logs` directly, not just "looks like more rows than before"). Then log in as `school_admin` and confirm their own audit log view is unchanged (still only their own school's entries) — this RPC is shared, don't let the super_admin fix change school_admin's scope.
4. `flutter analyze` clean, existing Phase 3 test suite still passing.
