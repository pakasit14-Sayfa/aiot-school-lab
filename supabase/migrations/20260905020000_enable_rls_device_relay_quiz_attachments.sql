-- Close a live gap found via 05_tenant_isolation.test.sql ("RLS is enabled
-- on every public table"): device_relay_states (added in
-- 20260902000000_device_command_ack_and_relay_state.sql) and
-- quiz_question_attachments (added in
-- 20260827000000_quiz_question_attachments.sql) were both created without
-- ever enabling row level security, and both still carry the default
-- anon/authenticated table-level grants (select/insert/update/delete).
-- With RLS off, those grants gave direct, unauthenticated read/write access
-- to every row in both tables, bypassing every session-token check. All
-- real access to both tables already goes through SECURITY DEFINER RPCs
-- (list_device_relay_states/ack_device_command,
-- add_quiz_question_attachment/get_quiz_attachment_for_download/
-- get_quiz_for_student) — no client code or Edge Function calls either
-- table directly. This migration only enables deny-all RLS and revokes the
-- now-redundant direct grants, matching every other table in this schema.

alter table public.device_relay_states enable row level security;
alter table public.quiz_question_attachments enable row level security;

revoke select, insert, update, delete on public.device_relay_states
  from anon, authenticated;
revoke select, insert, update, delete on public.quiz_question_attachments
  from anon, authenticated;
