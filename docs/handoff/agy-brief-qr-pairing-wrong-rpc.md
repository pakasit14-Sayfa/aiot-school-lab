# Brief for agy: kiosk QR pairing "fix" calls the wrong RPC, will never work

Verified all 5 items from `agy-brief-remaining-fake-features-2026-08-24.md`.
Items 1-3 check out (details below). Item 4/5 — `kiosk_pairing_scanner_page.dart`
and `school_scan_page.dart` now calling `claim_terminal_pairing_session` —
is architecturally impossible to work as wired, confirmed live.

## Why it can't work

`claim_terminal_pairing_session(p_token, p_pairing_code)` is `my_first_app`'s
custom-session RPC, and its whole design assumes `p_token` is **the
caller's own valid session token** — it calls `get_session_actor(p_token)`
to find out who's calling, then hard-requires
`v_actor.role = 'student'` (see the "AUTH-5: Actor must be student only"
comment in the function body). It was built for the AUTH-5 flow: a
**student**, already logged into `my_first_app` on their own phone with
their own session, scans a QR shown on a lab terminal and claims that
terminal as themselves.

The new code in both scanner pages does this instead:

```dart
await client.rpc('claim_terminal_pairing_session', params: {
  'p_token': decoded['token']?.toString() ?? '',  // or: token
  'p_pairing_code': pairingCode,
});
```

`decoded['token']` is a field pulled out of **the scanned QR payload
itself**, not the caller's own session. And the caller here is a
school_admin/super_admin using `aiot_dev_dashboard`, authenticated via real
Supabase Auth — they have no `my_first_app` custom session token at all,
ever, under any circumstance. Even if the QR happened to contain something
that looked like a token, the actor role check would reject it immediately
since a school_admin/super_admin is never `'student'`.

Confirmed live — reproduced the exact call shape from the code:

```bash
curl .../rest/v1/rpc/claim_terminal_pairing_session \
  -d '{"p_token":"some-fake-qr-token-value","p_pairing_code":"ABC123"}'
# → {"message":"invalid_session"}  (fails before even reaching the role check)
```

This will return `invalid_session` for every real QR an admin scans, no
matter what — there's no code path where this succeeds, so it's not a bug
that shows up only in edge cases, it's non-functional by construction.

## What this needs instead — design question, not just a fix

What should an admin scanning a kiosk-pairing QR in `aiot_dev_dashboard`
actually *see or do*? A few options, pick one before writing code:

1. **Read-only status view** — call `check_terminal_pairing_status(p_pairing_code)`
   instead (no `p_token` needed, no role restriction, just looks up the
   session by code) and show whether it's pending/claimed/expired and by
   whom. This fits "admin monitors kiosk pairing" without claiming
   anything on the student's behalf.
2. **Scope this feature out of aiot_dev_dashboard entirely** — if there's
   no real admin action here (claiming is inherently a student-only,
   self-service action), the scanner pages could just decode-and-display
   the QR type/code as they did before, without pretending there's a
   backend action to trigger.
3. **A genuinely new admin-side RPC** if there's a real use case like
   "admin manually completes a stuck pairing for a student who's having
   trouble" — but that needs its own role check
   (`is_super_admin()`/`has_role('school_admin')`) and its own design, not
   a repurposing of the student RPC.

Whichever direction, don't route through `claim_terminal_pairing_session`
from an admin context — that RPC's entire authorization model assumes the
caller IS the student claiming their own session.

## Items 1-3, for the record — verified, no issues

- **`school_admin_profile_page.dart` password change**: real
  `signInWithPassword` (re-auth with current password) →
  `auth.updateUser(UserAttributes(password: ...))`, proper `AuthException`
  handling. Code-reviewed, not live-executed (would change a real seeded
  test account's password).
- **`school_buildings_page.dart`**: `buildings`/`rooms` tables real, RLS
  dual-checked, insert/update via real `.from()` calls. Verified live —
  school_admin insert succeeds, student insert blocked (403). One thing
  fixed on this end: the migration wasn't idempotent (`CREATE POLICY`
  with no `DROP POLICY IF EXISTS` first, and the seed `DO` block had no
  guard against re-seeding) — re-running it duplicated the 3 seed
  buildings and 3 seed rooms, cleaned up and the migration file patched
  with `DROP POLICY IF EXISTS`/`NOT EXISTS (SELECT 1 FROM buildings ...)`
  so a future `db reset` replays cleanly.
- **`school_permissions_page.dart`**: role changes now go through
  `admin_update_user_profile` correctly, Thai role labels map to valid
  enum values. Verified live.
