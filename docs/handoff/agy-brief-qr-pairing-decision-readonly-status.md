# Decision made: QR pairing scanners become read-only status inspectors

Product decision on `agy-brief-qr-pairing-wrong-rpc.md`'s 3 options:
**Option 1 — read-only status inspector.** Applies to both affected pages
(they have the same bug): `kiosk_pairing_scanner_page.dart` (Super Admin
level) and `school_admin/school_scan_page.dart` (School Admin level).

## What to change

In both files, replace the `claim_terminal_pairing_session` call with
`check_terminal_pairing_status(p_pairing_code)` — no `p_token`, no role
restriction, just looks up the session by code:

```dart
final response = await client.rpc('check_terminal_pairing_status', params: {
  'p_pairing_code': pairingCode,
});
```

`check_terminal_pairing_status(p_pairing_code text)` returns `(status
text, session_token text, student_name text)` (see
`supabase/migrations/20260823040000_terminal_pairing_and_student_support.sql`
and the AUTH-5 fixes after it for the exact shape). Use `status` and
`student_name` to show something like "รอนักเรียนสแกน" (pending) /
"จับคู่แล้วโดย {student_name}" (claimed) / "หมดอายุ" (expired) instead of
the current "จับคู่ Kiosk Terminal ในระบบ Supabase สำเร็จ" message, which
implies an action was taken when none was.

Since this is now read-only, drop whatever "ยืนยันการจับคู่"/confirm-action
button exists around this — there's nothing to confirm, just a status to
show after decoding the QR.

## Verify

Real login as school_admin/super_admin, scan (or manually trigger the
detection handler with) a QR containing a real pending `pairing_code` from
`terminal_pairing_sessions`, confirm the status shown matches
`select status, claimed_by_user_id from terminal_pairing_sessions where
pairing_code = '...'` — not just that the UI shows *something*, that it
shows the *actual* status.
