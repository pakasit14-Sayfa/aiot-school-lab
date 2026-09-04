-- The School Admin app calls these RPCs as anon/authenticated with its
-- opaque session token. No service-role consumer exists for this slice.

revoke execute on function public.list_incident_reports(text, incident_status)
  from service_role;
revoke execute on function public.get_incident_report(text, uuid)
  from service_role;
revoke execute on function public.get_incident_report_for_staff(text, uuid)
  from service_role;
revoke execute on function public.acknowledge_incident_report(text, uuid)
  from service_role;
revoke execute on function public.close_incident_report(
  text,
  uuid,
  incident_resolution_type,
  text
) from service_role;
