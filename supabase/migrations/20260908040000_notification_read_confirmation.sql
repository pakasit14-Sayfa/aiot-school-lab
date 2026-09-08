-- Own-inbox mutations and an exact canonical read, independent of list limits.
CREATE OR REPLACE FUNCTION public.get_my_notification(p_token text, p_notification_id uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions AS $$
DECLARE actor record; result jsonb;
BEGIN
  SELECT * INTO actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN RAISE EXCEPTION 'invalid_session'; END IF;
  SELECT to_jsonb(n) || jsonb_build_object('category', public._notification_category(n.type::text))
    INTO result FROM notifications n WHERE n.id = p_notification_id AND n.user_id = actor.user_id;
  RETURN result;
END;
$$;

CREATE OR REPLACE FUNCTION public.mark_all_my_notifications_read(p_token text)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions AS $$
DECLARE actor record;
BEGIN
  SELECT * INTO actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN RAISE EXCEPTION 'invalid_session'; END IF;
  UPDATE notifications SET read_at = now() WHERE user_id = actor.user_id AND read_at IS NULL;
END;
$$;
REVOKE ALL ON FUNCTION public.get_my_notification(text, uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.mark_all_my_notifications_read(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_my_notification(text, uuid) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.mark_all_my_notifications_read(text) TO anon, authenticated;
