-- Migration: 20260907060000_staff_leave_attachments.sql
-- Description: file attachments for staff_leave_requests (ลา) — ใบรับรอง
-- แพทย์ and the like. `staff_leave_requests` (20260907010000) shipped
-- without any way to attach a document at all.
--
-- Follows the exact upload/download shape already established by
-- `school-report-upload`/`-download` and `meeting-files`: a private
-- Storage bucket, an `assert_*_upload_access` RPC the Edge Function calls
-- with the service role before minting a signed upload URL, a
-- `register_*` RPC the client calls afterward to record the object, and a
-- `get_*_for_download` RPC re-checking visibility on every read rather
-- than trusting a client-supplied path.
--
-- Design notes:
--
--   * A leave request can carry more than one file (front and back of a
--     medical certificate, for instance) — a child table, not a single
--     column on staff_leave_requests, same shape as `meeting_attachments`.
--
--   * Attaching is allowed for the requester (it is their own leave) or a
--     school_admin/super_admin acting on their behalf — the same override
--     shape already used throughout `staff_requests` and `meetings`.
--
--   * Once a leave request has been decided (approved/rejected/cancelled),
--     no attachment may be removed — the record of what was submitted at
--     decision time stays intact, matching this schema's established
--     append-don't-erase ethos for anything already reviewed. New files may
--     still be added afterward (e.g. a requested follow-up document).
--
--   * Bucket is named `staff-leave-attachments`, distinct from the
--     pre-existing `leave_attachments` bucket — that one belongs to the
--     unrelated, parent-submitted *student* `leave_requests` feature
--     (20260903020000) and must not be reused here.
--
-- Everything here is additive. No existing table or RPC is modified.

INSERT INTO storage.buckets (id, name, public)
VALUES ('staff-leave-attachments', 'staff-leave-attachments', false)
ON CONFLICT (id) DO UPDATE SET public = false;

CREATE TABLE IF NOT EXISTS public.staff_leave_attachments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  leave_request_id uuid NOT NULL REFERENCES public.staff_leave_requests(id) ON DELETE CASCADE,
  storage_path text NOT NULL UNIQUE,
  file_name varchar NOT NULL,
  file_type varchar NOT NULL,
  size_bytes bigint NOT NULL CHECK (size_bytes >= 0),
  uploaded_by uuid NOT NULL REFERENCES public.users(id),
  uploaded_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.staff_leave_attachments ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS staff_leave_attachments_request_idx
  ON public.staff_leave_attachments (leave_request_id);

-- ---------------------------------------------------------------------------
-- Upload path (Edge Function -> signed URL -> register)
-- ---------------------------------------------------------------------------

-- Called by the staff-leave-attachment-upload Edge Function before it mints
-- a signed upload URL. Returns the school id the object must be filed
-- under, so a caller cannot be talked into another tenant's prefix.
CREATE OR REPLACE FUNCTION public.assert_staff_leave_attachment_upload_access(
  p_token text,
  p_leave_request_id uuid
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_req public.staff_leave_requests;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  SELECT * INTO v_req FROM public.staff_leave_requests WHERE id = p_leave_request_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'leave_request_not_found';
  END IF;

  IF v_req.school_id IS DISTINCT FROM v_actor.school_id THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  IF v_req.user_id <> v_actor.user_id
     AND v_actor.role NOT IN ('school_admin', 'super_admin') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  RETURN v_req.school_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.register_staff_leave_attachment(
  p_token text,
  p_leave_request_id uuid,
  p_storage_path text,
  p_file_name text,
  p_size_bytes bigint
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_school uuid;
  v_id uuid;
BEGIN
  v_school := public.assert_staff_leave_attachment_upload_access(p_token, p_leave_request_id);
  SELECT * INTO v_actor FROM get_session_actor(p_token);

  IF coalesce(trim(coalesce(p_storage_path, '')), '') = ''
     OR coalesce(trim(coalesce(p_file_name, '')), '') = '' THEN
    RAISE EXCEPTION 'file_required';
  END IF;

  -- The object must sit under this school's prefix; anything else means the
  -- path was not the one the upload function minted.
  IF p_storage_path NOT LIKE v_school::text || '/%' THEN
    RAISE EXCEPTION 'invalid_storage_path';
  END IF;

  INSERT INTO public.staff_leave_attachments (
    leave_request_id, storage_path, file_name, file_type, size_bytes, uploaded_by
  ) VALUES (
    p_leave_request_id, p_storage_path, trim(p_file_name),
    public._report_file_type(p_file_name),
    greatest(coalesce(p_size_bytes, 0), 0), v_actor.user_id
  )
  RETURNING id INTO v_id;

  RETURN v_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.remove_staff_leave_attachment(
  p_token text,
  p_attachment_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_att public.staff_leave_attachments;
  v_req public.staff_leave_requests;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  SELECT * INTO v_att FROM public.staff_leave_attachments WHERE id = p_attachment_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'attachment_not_found';
  END IF;

  SELECT * INTO v_req FROM public.staff_leave_requests WHERE id = v_att.leave_request_id;

  IF v_req.school_id IS DISTINCT FROM v_actor.school_id THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  IF v_req.user_id <> v_actor.user_id
     AND v_actor.role NOT IN ('school_admin', 'super_admin') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  -- Once decided, what was submitted at decision time is part of the
  -- record — a file may still be added afterward, never removed.
  IF v_req.status <> 'pending' THEN
    RAISE EXCEPTION 'already_reviewed';
  END IF;

  DELETE FROM public.staff_leave_attachments WHERE id = p_attachment_id;
END;
$$;

-- ---------------------------------------------------------------------------
-- Reads
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.list_staff_leave_attachments(
  p_token text,
  p_leave_request_id uuid
)
RETURNS TABLE (
  attachment_id uuid,
  file_name varchar,
  file_type varchar,
  size_bytes bigint,
  uploader_name text,
  uploaded_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_req public.staff_leave_requests;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  SELECT * INTO v_req FROM public.staff_leave_requests WHERE id = p_leave_request_id;
  IF NOT FOUND OR v_req.school_id IS DISTINCT FROM v_actor.school_id THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  IF v_actor.role NOT IN ('school_admin', 'executive', 'super_admin')
     AND v_req.user_id <> v_actor.user_id THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  RETURN QUERY
  SELECT a.id, a.file_name, a.file_type, a.size_bytes,
         trim(u.first_name || ' ' || u.last_name), a.uploaded_at
    FROM public.staff_leave_attachments a
    JOIN public.users u ON u.id = a.uploaded_by
   WHERE a.leave_request_id = p_leave_request_id
   ORDER BY a.uploaded_at;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_staff_leave_attachment_for_download(
  p_token text,
  p_attachment_id uuid
)
RETURNS TABLE (storage_path text, file_name varchar)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_actor record;
  v_att public.staff_leave_attachments;
  v_req public.staff_leave_requests;
BEGIN
  SELECT * INTO v_actor FROM get_session_actor(p_token);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_session';
  END IF;

  SELECT * INTO v_att FROM public.staff_leave_attachments WHERE id = p_attachment_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'attachment_not_found';
  END IF;

  SELECT * INTO v_req FROM public.staff_leave_requests WHERE id = v_att.leave_request_id;

  IF v_req.school_id IS DISTINCT FROM v_actor.school_id THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  IF v_actor.role NOT IN ('school_admin', 'executive', 'super_admin')
     AND v_req.user_id <> v_actor.user_id THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  RETURN QUERY SELECT v_att.storage_path, v_att.file_name;
END;
$$;

-- ---------------------------------------------------------------------------
-- Grants
-- ---------------------------------------------------------------------------

REVOKE ALL ON FUNCTION public.assert_staff_leave_attachment_upload_access FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.assert_staff_leave_attachment_upload_access TO service_role;

REVOKE ALL ON FUNCTION public.get_staff_leave_attachment_for_download FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_staff_leave_attachment_for_download TO service_role;

REVOKE ALL ON FUNCTION public.register_staff_leave_attachment FROM PUBLIC, service_role;
GRANT EXECUTE ON FUNCTION public.register_staff_leave_attachment TO anon, authenticated;

REVOKE ALL ON FUNCTION public.remove_staff_leave_attachment FROM PUBLIC, service_role;
GRANT EXECUTE ON FUNCTION public.remove_staff_leave_attachment TO anon, authenticated;

REVOKE ALL ON FUNCTION public.list_staff_leave_attachments FROM PUBLIC, service_role;
GRANT EXECUTE ON FUNCTION public.list_staff_leave_attachments TO anon, authenticated;
