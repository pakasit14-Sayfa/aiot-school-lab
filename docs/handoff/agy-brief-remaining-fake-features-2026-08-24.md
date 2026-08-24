# Brief for agy: 5 more fake/missing features found finishing the page-by-page audit

Finished auditing the remaining pages of `aiot_dev_dashboard` (18/27 now
confirmed genuinely wired, up from 4 this morning). Found 5 more pages
that look complete but aren't. Ordered by how bad it is if a real user
hits it, not by file order.

## 🔴 1. `school_admin_profile_page.dart` — "เปลี่ยนรหัสผ่าน" is completely fake

`_changePassword()` opens a dialog with current/new/confirm password
fields, validates client-side (non-empty, length ≥ 8, new == confirm),
then just does `Navigator.pop(true)`. The caller then shows
`_message('เปลี่ยนรหัสผ่านแล้ว')` — **there is no
`Supabase.instance.client.auth.updateUser(...)` call anywhere in this
file, no RPC, nothing.** A user (a school_admin, someone with real access)
who thinks they just secured their account after this dialog has changed
nothing. This is the worst one on this list — it's a false sense of
security, not just a missing feature.

**Fix**: after client-side validation passes, actually call
`Supabase.instance.client.auth.updateUser(UserAttributes(password: next))`.
Supabase Auth requires the current session to be valid for this (it
doesn't itself re-verify the "current password" field) — if you want the
current-password field to mean something, you'd need to
re-authenticate first (`signInWithPassword` with the typed current
password) before calling `updateUser`, otherwise drop that field since
it's currently decorative.

## 🔴 2. `school_buildings_page.dart` — no `buildings`/`rooms` table exists at all

Read is real (`.from('devices')` for the device count), but "เพิ่ม/แก้ไข
อาคาร" and "เพิ่มห้องแล็บ" only do `_buildings.insert(0, result)` /
`_rooms.insert(0, result)` — local Dart lists, no Supabase call anywhere
in the file. Checked the schema: **there is no `buildings` or `rooms`
table in the database at all.** `devices.building`/`devices.room` are
free-text columns on the device row itself — there's no normalized place
to persist "a building" or "a room" as its own entity with, e.g., floor
count or room type (both of which the UI already asks for).

This one needs a design decision before it needs code: do buildings/rooms
become real tables (schema work, a migration, RPCs), or does this feature
get scoped down to derive its list purely from `distinct
devices.building`/`devices.room` (no create/edit, just what's already
implied by device data)? Flag which direction before starting — this is
bigger than the other four.

## 🟡 3. `school_permissions_page.dart` — read-only, no role-change RPC wired

Only `.from('profiles')` for reading; no `.update()`, `.rpc()`, or
anything else in the file. The list of staff and their roles is real, but
there's no way to actually change anyone's role from this page. Unlike
`permissions_page.dart` (top-level) or `school_students_page.dart`/
`school_teachers_page.dart`, this one was never wired to
`admin_update_user_profile` (which already exists and already handles
exactly this — see `20260824040000_admin_update_user_profile.sql` /
`20260824060000_extend_admin_update_user_profile_fields.sql`). Wiring
this one should be the cheapest fix on this list — the RPC's already
built and tested.

## 🔴 4/5. `kiosk_pairing_scanner_page.dart`, `scan_page.dart`, `school_scan_page.dart` — QR scanning has zero backend

All three (well, `scan_page.dart` is a thin redirect to
`KioskPairingScannerPage`, so really two distinct implementations) decode
a scanned QR's JSON payload (`app`/`type`/`token`/`session_id` fields) and
show a summary card describing what was scanned — "คำขอจับคู่ Kiosk
Terminal", "รหัสเซสชัน: ...". **Neither file has a single `.from()` or
`.rpc()` call.** Nothing confirms the pairing session actually exists,
nothing claims it, nothing writes to `terminal_pairing_sessions` at all.
An earlier report described this as "ผูก Logic กับตาราง
terminal_pairing_sessions แล้ว แต่ต้องทดสอบกับกล้องจริง" — that's not
accurate; there's no logic connected to that table to test with a camera,
real or otherwise.

`my_first_app` already has the real RPCs for this side of the flow —
`check_terminal_pairing_status(p_pairing_code)` and
`claim_terminal_pairing_session(p_token, p_pairing_code)` (see
`supabase/migrations/20260823040000_terminal_pairing_and_student_support.sql`
and the AUTH-5 fixes after it). After a successful scan that decodes to
`type == 'kiosk_pairing' || type == 'terminal_pairing'`, call
`check_terminal_pairing_status` with the decoded code/token to show real
status instead of a static card, and wire whatever "confirm pairing"
action exists in the UI to `claim_terminal_pairing_session`.

## Verification standard, same as every item today

None of these five are caught by `flutter analyze` or `flutter test` —
confirmed by re-reading the actual call sites, not by trusting a status
report. For each: drive the real flow (change password → try logging in
with the new password; add a building → check the table exists and has
the row; change a role via school_permissions_page → check `user_roles`;
scan a real kiosk-pairing QR → check `terminal_pairing_sessions` for the
claim). A screen that changes after clicking a button is not evidence —
the database row is.
