-- Same gap as 20260823050000: peek_terminal_pairing_session (added in
-- 20260823060000_auth5_qr_pairing_refinements.sql) granted execute to
-- anon/authenticated without first revoking the implicit PUBLIC grant.
-- Confirmed via information_schema.routine_privileges.

revoke all on function peek_terminal_pairing_session(text) from public;
grant execute on function peek_terminal_pairing_session(text) to anon, authenticated;
