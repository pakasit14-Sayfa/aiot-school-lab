-- 20260823040000_terminal_pairing_and_student_support.sql granted execute
-- on its 8 new functions without first revoking the implicit PUBLIC
-- execute grant Postgres gives every new function by default — every other
-- migration in this codebase does `revoke all ... from public` before
-- granting to specific roles (deny-all-by-default, matching the RLS
-- policy). Confirmed via information_schema.routine_privileges that
-- PUBLIC actually had EXECUTE on all 8. Not exploitable through the
-- Supabase API today (PostgREST/Kong only ever connect as anon/
-- authenticated/service_role), but it's a real deviation from the
-- project's deny-by-default convention — closing the gap for defense in
-- depth and consistency.

revoke all on function create_terminal_pairing_session(text) from public;
revoke all on function claim_terminal_pairing_session(text, text) from public;
revoke all on function check_terminal_pairing_status(text) from public;
revoke all on function list_student_support_cases(text, uuid, text) from public;
revoke all on function create_student_support_case(text, uuid, uuid, text, text, text, text) from public;
revoke all on function update_student_support_case_status(text, uuid, text, text) from public;
revoke all on function add_student_support_intervention(text, uuid, text, text) from public;
revoke all on function list_student_support_interventions(text, uuid) from public;

grant execute on function create_terminal_pairing_session(text) to anon, authenticated;
grant execute on function claim_terminal_pairing_session(text, text) to authenticated;
grant execute on function check_terminal_pairing_status(text) to anon, authenticated;
grant execute on function list_student_support_cases(text, uuid, text) to authenticated;
grant execute on function create_student_support_case(text, uuid, uuid, text, text, text, text) to authenticated;
grant execute on function update_student_support_case_status(text, uuid, text, text) to authenticated;
grant execute on function add_student_support_intervention(text, uuid, text, text) to authenticated;
grant execute on function list_student_support_interventions(text, uuid) to authenticated;
