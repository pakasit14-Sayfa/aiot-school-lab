-- Bug 3: retain the existing RPC contracts and add the missing read fields
-- needed for canonical verification and meeting documents.
CREATE OR REPLACE FUNCTION public._can_see_meeting(
 p_user_id uuid, p_role text, p_school_id uuid, p_meeting public.meetings
) RETURNS boolean LANGUAGE sql STABLE SET search_path=public,extensions AS $$
 SELECT p_meeting.school_id = p_school_id
 AND p_role IN ('teacher','executive','school_admin','super_admin')
 AND (
   p_role IN ('school_admin','super_admin')
   OR p_meeting.created_by = p_user_id
   OR EXISTS (SELECT 1 FROM meeting_attendees a WHERE a.meeting_id=p_meeting.id AND a.user_id=p_user_id)
   OR (p_meeting.meeting_type <> 'one_on_one'
       AND (p_role='executive' OR p_meeting.visibility='school'))
 );
$$;

CREATE OR REPLACE FUNCTION public.list_meeting_records(p_token text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,extensions AS $$
DECLARE v_actor record; v_result jsonb;
BEGIN
 SELECT * INTO v_actor FROM get_session_actor(p_token);
 IF NOT FOUND THEN RAISE EXCEPTION 'invalid_session'; END IF;
 -- list_meetings also enforces the staff role allowlist and visibility.
 SELECT coalesce(jsonb_agg(to_jsonb(l) || jsonb_build_object(
   'meeting_no',m.meeting_no,'meeting_year',m.meeting_year,
   'attendance_taken_at',m.attendance_taken_at,
   'can_manage',(m.created_by=v_actor.user_id OR v_actor.role IN ('school_admin','super_admin'))
 ) ORDER BY m.start_at DESC,m.id),'[]'::jsonb)
 INTO v_result FROM list_meetings(p_token) l JOIN meetings m ON m.id=l.meeting_id;
 RETURN v_result;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_meeting_detail(p_token text,p_meeting_id uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,extensions AS $$
DECLARE v_actor record; v_meeting meetings; v_summary jsonb; v_minutes jsonb;
BEGIN
 SELECT * INTO v_actor FROM get_session_actor(p_token);
 IF NOT FOUND THEN RAISE EXCEPTION 'invalid_session'; END IF;
 SELECT * INTO v_meeting FROM meetings WHERE id=p_meeting_id;
 IF NOT FOUND OR NOT _can_see_meeting(v_actor.user_id,v_actor.role::text,v_actor.school_id,v_meeting)
 THEN RAISE EXCEPTION 'forbidden'; END IF;
 SELECT e INTO v_summary FROM jsonb_array_elements(list_meeting_records(p_token)) e
 WHERE e->>'meeting_id'=p_meeting_id::text;
 -- Preserve the existing draft-visibility and audit-on-read behaviour.
 SELECT to_jsonb(mn) INTO v_minutes FROM get_meeting_minutes(p_token,p_meeting_id) mn;
 RETURN jsonb_build_object(
  'meeting',v_summary,
  'attendees',(SELECT coalesce(jsonb_agg(to_jsonb(a) || jsonb_build_object('attended',ma.attended)
    ORDER BY a.is_organizer DESC,a.full_name),'[]'::jsonb)
    FROM list_meeting_attendees(p_token,p_meeting_id) a
    JOIN meeting_attendees ma ON ma.meeting_id=p_meeting_id AND ma.user_id=a.user_id),
  'external_attendees',(SELECT coalesce(jsonb_agg(to_jsonb(e)),'[]'::jsonb) FROM list_meeting_external_attendees(p_token,p_meeting_id) e),
  'agenda',(SELECT coalesce(jsonb_agg(to_jsonb(a) || jsonb_build_object('presenter_user_id',i.presenter_user_id)
    ORDER BY a.sort_order,a.item_id),'[]'::jsonb)
    FROM list_meeting_agenda(p_token,p_meeting_id) a JOIN meeting_agenda_items i ON i.id=a.item_id),
  'minutes',v_minutes,
  'addenda',(SELECT coalesce(jsonb_agg(to_jsonb(a) ORDER BY a.created_at,a.addendum_id),'[]'::jsonb) FROM list_meeting_minute_addenda(p_token,p_meeting_id) a),
  'resolutions',(SELECT coalesce(jsonb_agg(to_jsonb(r)),'[]'::jsonb) FROM list_meeting_resolutions(p_token,p_meeting_id) r),
  'attachments',(SELECT coalesce(jsonb_agg(to_jsonb(a)),'[]'::jsonb) FROM list_meeting_attachments(p_token,p_meeting_id) a),
  'can_upload',v_meeting.created_by=v_actor.user_id OR v_actor.role IN ('executive','school_admin','super_admin')
     OR EXISTS (SELECT 1 FROM meeting_attendees a WHERE a.meeting_id=p_meeting_id AND a.user_id=v_actor.user_id),
  'my_user_id',v_actor.user_id
 );
END;
$$;
REVOKE ALL ON FUNCTION public._can_see_meeting FROM PUBLIC,anon,authenticated,service_role;
REVOKE ALL ON FUNCTION public.list_meeting_records(text) FROM PUBLIC,service_role;
GRANT EXECUTE ON FUNCTION public.list_meeting_records(text) TO anon,authenticated;
REVOKE ALL ON FUNCTION public.get_meeting_detail(text,uuid) FROM PUBLIC,service_role;
GRANT EXECUTE ON FUNCTION public.get_meeting_detail(text,uuid) TO anon,authenticated;
-- These two are deliberately the only service-role entry points for signed URLs.
GRANT EXECUTE ON FUNCTION public.assert_meeting_attachment_upload_access(text,uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.get_meeting_attachment_for_download(text,uuid) TO service_role;
NOTIFY pgrst,'reload schema';
