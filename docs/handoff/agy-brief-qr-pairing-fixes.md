# Brief for agy: 3 fixes needed in QR terminal pairing (AUTH-5)

Reviewed against the AUTH-5 spec in the vault
(`~/Documents/AIoT-School-Lab-Vault/UC-Descriptions/AUTH_Group_Use_Case_Descriptions.md`).
The feature works end-to-end (verified live: create → poll → claim → poll →
token validates), but 3 things don't match the spec you wrote it against.
All 3 are confirmed against the spec text, not opinions.

Files involved:
- `supabase/migrations/20260823040000_terminal_pairing_and_student_support.sql`
- `packages/shared_core/lib/services/terminal_pairing_service.dart`
- `apps/user_app/lib/pages/student_redesign_prototype/widgets/student_qr_login_page.dart`

## 1. Actor must be student-only — currently unrestricted

Spec: *"Actor หลัก: นักเรียน (ที่ login บนมือถือแล้ว)"*

`claim_terminal_pairing_session(p_token, p_pairing_code)` never checks
`v_actor.role`. Any authenticated role (teacher, parent, school_admin...)
can currently pair a lab terminal to their own account.

**Fix**: add a role check right after `get_session_actor`, same pattern
used everywhere else in this codebase, e.g.:
```sql
if v_actor.role <> 'student' then raise exception 'forbidden'; end if;
```
Needs a new migration (`create or replace function`) — don't edit the
20260823040000 file directly, it's already applied/committed.

## 2. BR3 — must show device context *before* confirming (anti-relay/phishing)

Spec: *"จอมือถือแสดงบริบทชัดเจน: ชื่อเครื่อง/ห้อง/เวลา"* then *"นักเรียนกดยืนยัน"*
— i.e. scan → show what you're about to log into → explicit confirm tap →
only then claim. This exists specifically to stop a relay attack (someone
captures/relays your QR to a different physical terminal than you think
you're approving).

Current flow in `student_qr_login_page.dart` (`_handleScannedCode`,
~line 174): the barcode scan handler calls
`TerminalPairingService.claimPairingSession(code)` immediately on detection.
There is no intermediate screen — the claim (i.e. the actual login) has
already happened by the time anything is shown to the student. The result
sheet appears *after*, which defeats the purpose (nothing left to cancel).

**Fix** (two parts):
- Backend: split into two RPCs — a read-only
  `peek_terminal_pairing_session(p_pairing_code)` that returns
  `terminal_name`/`created_at` (no session minted, no auth required beyond
  the code existing/being pending) for the preview screen, and keep
  `claim_terminal_pairing_session` as the actual confirm action.
- Frontend: on scan, call the peek RPC, show a confirm sheet with the
  terminal name + a countdown/time, only call `claimPairingSession` when
  the student taps confirm (and let them cancel).

## 3. BR4 — lab terminal session must auto-logout, no remember-me

Spec: *"คอมโรงเรียน auto-logout + no remember-me"*

`claim_terminal_pairing_session` inserts into `sessions` with
`expires_at = now() + interval '30 days'` — a month-long session on a
shared physical device. If a student forgets to log out, the next student
who sits down inherits their session.

**Fix**: give terminal-originated sessions a much shorter expiry (spec
doesn't give an exact number — a few hours, matching a typical class
period, is a reasonable default; confirm with whoever owns the UC if there's
a specific number in mind). This likely means adding a distinct expiry
constant for this one insert rather than reusing whatever the regular
login path uses.

## How to verify after fixing

Same method used to verify the original feature — direct RPC calls against
the local DB (`docker exec -i supabase_db_aiot-school-lab psql -U postgres
-d postgres -c "select ..."`), not just `flutter analyze`/`build`:

1. Claim as a non-student role (e.g. teacher token) → should now raise
   `forbidden`.
2. Call the new peek RPC with a pending code → should return terminal_name
   without minting a session or requiring a token.
3. Check the new session's `expires_at` after claiming → should be hours,
   not `now() + 30 days`.
