-- The School Admin app and the executive overview page call these RPCs as
-- anon/authenticated with an opaque session token (see CLAUDE.md hard rule
-- 1). No service-role consumer exists for this slice. Found via pgTAP while
-- verifying the Learning tracks page: all 7 functions unexpectedly carried
-- EXECUTE for service_role (same shape as the incident-inbox ACL fix in
-- 20260904010200_incident_inbox_service_role_acl.sql), even though
-- 20260829030000_learning_tracks.sql only ever granted anon/authenticated.

revoke execute on function public.list_learning_tracks(text)
  from service_role;
revoke execute on function public.create_learning_track(text, text, text)
  from service_role;
revoke execute on function public.update_learning_track(
  text,
  uuid,
  text,
  text,
  integer
) from service_role;
revoke execute on function public.delete_learning_track(text, uuid)
  from service_role;
revoke execute on function public.list_learning_track_rooms(text)
  from service_role;
revoke execute on function public.set_learning_track_room(
  text,
  text,
  text,
  uuid
) from service_role;
revoke execute on function public.get_learning_track_overview(text)
  from service_role;
