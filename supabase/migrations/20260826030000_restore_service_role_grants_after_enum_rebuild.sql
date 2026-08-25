-- Migration: 20260826030000_restore_service_role_grants_after_enum_rebuild.sql
-- Description: Checkpoint 1's enum rebuild used DROP TYPE role_type CASCADE,
-- which drops (not just replaces) the 9 dependent functions. pg_get_functiondef()
-- only captures signature+body, not grants, so the service_role grants these 3
-- functions had (needed by edge functions calling them with the service-role
-- key: supabase/functions/auth-sign-in, auth-verify-login-otp, staff-invite-accept)
-- were silently lost on replay. CREATE OR REPLACE FUNCTION preserves existing
-- grants when the signature is unchanged; a DROP + recreate does not.
-- Found by live-testing the real edge function path (not just direct RPC calls)
-- post-Checkpoint-3 — direct psql calls to these functions worked fine and masked
-- this, since only the service-role grant was missing, not anon/authenticated.

GRANT EXECUTE ON FUNCTION public.auth_sign_in(text, text, text, text) TO service_role;
GRANT EXECUTE ON FUNCTION public.auth_verify_login_otp(text, text) TO service_role;
GRANT EXECUTE ON FUNCTION public.accept_staff_invitation(text, text, text, text) TO service_role;
