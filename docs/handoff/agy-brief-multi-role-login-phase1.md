# Brief for agy: multi-role accounts — choose role at login (Phase 1)

Goal: one email/account can hold more than one role at once (e.g. a
teacher who is also school_admin). At login, if the account has 2+
roles, show a picker before entering the dashboard. Switching roles
means logging out and back in — no in-app switch button, no "remember
this device." Both were considered and explicitly rejected for this
phase (see rationale below) — don't add them.

## Why not an in-app switch button (context, don't relitigate this)

An earlier design let a logged-in session switch roles without
re-authenticating. Pre-mortem'd it and found a real MFA-bypass hole:
`auth_sign_in` requires OTP for `super_admin`/`school_admin`/`executive`/
`teacher`, but a same-session switch with no re-auth would let a session
that only ever proved itself via a lower-stakes role slide into a
higher-stakes one without ever passing OTP for it. Full logout+login on
every switch avoids this for free, since every switch becomes a real
`auth_sign_in` call end to end. Keep it that way — this is a hard
requirement, not a preference.

"Remember this device, skip OTP" (`trusted_devices` table) was also
considered and rejected for this phase: the table has no `revoked_at`
column (no way for a user to un-trust a stolen device short of waiting
out the expiry), and device fingerprinting is weak on the web build this
app ships today. Don't touch `trusted_devices` in this pass.

## Before writing any code — create a real dual-role test account

Every seeded test account in this system has exactly one role. Build
one that has two (e.g. `teacher@aiot-school-lab.local`'s user_id, granted
both `teacher` and `school_admin` in the same school) via the new
`add_secondary_role` RPC once it exists, and use that account for every
verification step below. Don't verify any of this against a single-role
account — that would never exercise the actual new code path, and this
project has a documented pattern of exactly that kind of gap letting
real bugs through (the CCTV grant bug and the facility-manager
building-scope bug were both "looked correct, never hit the real data
shape that broke it").

## Work order — 3 checkpoints, report back after each

### Checkpoint 1 — data model

New migration. Two things:

1. **`add_secondary_role(p_token, p_target_user_id, p_role, p_school_id)`**
   — same role gate as `update_user_role` (`school_admin`/`super_admin`,
   with the same "school_admin can't grant super_admin or touch another
   school" checks it already has). Unlike `update_user_role`, this
   **does not delete existing role rows** — it just inserts the new one,
   same shape as `update_user_role`'s insert (`user_id, role, school_id,
   granted_by, granted_at`). Guard against granting a role the user
   already holds in that school (no duplicate rows). `update_user_role`
   itself doesn't change — it still fully replaces, for the ordinary
   single-role-change flow. Don't merge these two functions or give
   `update_user_role` a "keep old role" flag — keep the two operations
   named and separated, they mean different things to whoever's granting
   the role.
2. Create the dual-role test account described above using this new RPC,
   confirm `select * from user_roles where user_id = ...` shows both
   rows with no old one deleted.

**Report back**: confirm the test account has 2 real, independent role
rows and that a normal single-role grant via `update_user_role` still
replaces (not adds) for every other account — i.e. confirm you haven't
changed `update_user_role`'s existing delete-then-insert behavior at all.

### Checkpoint 2 — auth core

This is the riskiest checkpoint — auth core has broken in real,
user-visible ways multiple times already this project (a schema-mismatch
rewrite of `auth_sign_in` took down login for 4 roles; the technician/
facility_manager enum rebuild silently dropped a `service_role` grant and
took down login again). Go slow, verify with real RPC calls before
moving to Checkpoint 3.

1. **`auth_sign_in` change**: right after password verification succeeds
   (before the existing "select newest granted role" logic), check how
   many `user_roles` rows the user has (same tenant-scoping condition
   already there: `school_id IS NOT DISTINCT FROM v_user.school_id OR
   role = 'super_admin'`).
   - **Exactly 1** → fall through to the existing logic unchanged. This
     is the overwhelming majority of accounts — don't change their
     behavior or response shape at all.
   - **2 or more** → don't auto-pick one. Instead: generate a short-lived
     `role_selection_token` (same pattern as `otp_token` —
     `encode(gen_random_bytes(32), 'hex')`, store it somewhere it can be
     looked up and expired, e.g. a small new table
     `role_selection_challenges(token_hash, user_id, expires_at)` with a
     ~5 minute expiry), and return a new `auth_state` value
     `'role_selection_required'` along with the token and the list of
     available `(role, school_id)` pairs for that user. **Do not send an
     OTP yet at this point** — OTP only gets sent once a role is chosen,
     in the next step, and only if that specific role needs it.
2. **New RPC `auth_select_role(p_role_selection_token, p_role,
   p_school_id)`**:
   - Look up and validate the token (not expired, not already used —
     mark used or delete on success same as OTP tokens do).
   - Confirm the user actually holds `(p_role, p_school_id)` in
     `user_roles` (don't trust the client to only submit values from the
     list they were shown).
   - If the chosen role is in the OTP-required set
     (`super_admin`/`school_admin`/`executive`/`teacher`) — run the
     **exact same OTP-issuing logic** `auth_sign_in` already has (same
     rate-limit checks, same `otp_codes` insert), return
     `'mfa_required'` same as today. The existing
     `auth_verify_login_otp` RPC needs **no changes** — it already mints
     a session from `otp_codes.login_role`/`login_school_id`, which will
     be correct regardless of which path set them.
   - If not OTP-required — mint the session directly, same as
     `auth_sign_in`'s direct-session path today.
3. **OTP daily cap**: currently 10 sends/day per user
   (`auth_sign_in`'s `coalesce(v_daily_otp_count, 0) >= 10` check).
   Someone switching between two OTP-required roles several times a day
   will burn through this fast — raise the cap to 20/day specifically
   when the calling user has 2+ roles (a simple `exists (select 1 from
   user_roles where user_id = ... having count(*) > 1)`-style check
   feeding the threshold), leave it at 10 for everyone else. Don't build
   a separate counter or a different table — just make the existing
   check's threshold conditional.
4. **`supabase/functions/auth-sign-in/index.ts`**: needs to pass through
   the new `role_selection_required` state and its payload
   (`role_selection_token` + role list) the same way it already passes
   through `mfa_required` — check how that's currently forwarded in the
   response JSON and mirror the pattern for the new state.

**Report back with a RedTeam-style live probe before moving on** — same
standard as every auth change this session:
- Sign in as the dual-role test account with real credentials → confirm
  `role_selection_required` comes back with both roles listed, no
  session token yet.
- Call `auth_select_role` with a garbage/expired token → clean error, not
  a raw 500.
- Call `auth_select_role` with a role the account does *not* hold →
  clean error, not a session for a role they don't have.
- Pick the OTP-required role → confirm `mfa_required` comes back,
  complete it via `auth_verify_login_otp`, confirm the resulting
  session's `active_role` matches what was chosen.
- Sign in as an ordinary single-role account (e.g.
  `student@aiot-school-lab.local`) → confirm the response is byte-for-byte
  the same shape as before this change, `auth_state: 'authenticated'`
  straight through, no picker step introduced for them.

### Checkpoint 3 — Dart/UI

1. New page: role picker, shown when `auth_sign_in`'s response has
   `auth_state == 'role_selection_required'`. List of role options (role
   name + school name), tapping one calls `auth_select_role` with the
   token from the response. If that returns `mfa_required`, continue
   into the existing OTP-entry screen (reuse it, don't fork it) — same
   as the normal MFA flow, just entered from a different starting point.
2. Wire into the existing login flow's state handling (wherever
   `mfa_required` is currently branched on) — add the new state as a
   sibling branch, not a special case bolted on top.
3. No changes needed anywhere else — `RoleRouter` already switches on
   `currentUserModel.role`, which will just be whatever role the chosen
   session ended up with, same as today.

**Report back with a real browser click-through**: log in as the
dual-role test account through the actual built app (not just RPC
calls) — confirm the picker renders, choosing "teacher" enters the
teacher dashboard, logging out and back in and choosing "school_admin"
enters that dashboard instead. Confirm a single-role account's login
flow looks completely unchanged.

## Final verify

- `grep -rn "role_selection" supabase/migrations/` and the Dart side —
  confirm both the new RPC and the UI state exist and match.
- Clean up the dual-role test account's extra role afterward is *not*
  required — keep it, it's useful for regression-testing this feature
  going forward. Just make sure it's clearly named/commented as a
  deliberate dual-role fixture, not left looking like an accident.
- `flutter analyze` clean, no new errors.

Flag back rather than guessing on anything not covered here — this
touches auth core, which has broken for real users multiple times this
project from confident-but-wrong assumptions. Slow and verified beats
fast here.
