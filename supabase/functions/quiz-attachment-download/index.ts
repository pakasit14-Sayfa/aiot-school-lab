// Mints a short-lived Storage signed-download URL for the private
// `quiz-attachments` bucket. get_quiz_attachment_for_download re-checks
// course membership (teacher/enrolled student on a published quiz/admin)
// on every call. Mirrors lesson-material-download.

import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const signedUrlTtlSeconds = 60;

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return json({ error: "method_not_allowed" }, 405);
  }

  let token: string | null = null;
  let attachmentId: string | null = null;
  try {
    const body = await req.json();
    token = typeof body.token === "string" ? body.token.trim() : null;
    attachmentId = typeof body.attachment_id === "string"
      ? body.attachment_id
      : null;
  } catch {
    // Invalid bodies deliberately receive the generic failure result.
  }

  if (!token || !attachmentId) {
    return json({ error: "invalid_request" }, 400);
  }

  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!serviceRoleKey) {
    console.error("quiz-attachment-download server configuration unavailable");
    return json({ error: "invalid_request" }, 400);
  }
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    serviceRoleKey,
  );

  const lookup = await supabase.rpc("get_quiz_attachment_for_download", {
    p_token: token,
    p_attachment_id: attachmentId,
  }).maybeSingle();

  if (lookup.error || !lookup.data) {
    return json({ error: "forbidden" }, 403);
  }

  const signed = await supabase.storage
    .from("quiz-attachments")
    .createSignedUrl(lookup.data.storage_path, signedUrlTtlSeconds);

  if (signed.error || !signed.data) {
    console.error("failed to create signed download url:", signed.error?.message);
    return json({ error: "download_url_unavailable" }, 500);
  }

  const publicBaseUrl =
    Deno.env.get("PUBLIC_STORAGE_URL") ?? "http://127.0.0.1:54321";
  const signedUrl = new URL(signed.data.signedUrl);
  if (publicBaseUrl) {
    const publicUrl = new URL(publicBaseUrl);
    signedUrl.protocol = publicUrl.protocol;
    signedUrl.host = publicUrl.host;
  }

  return json({
    signed_url: signedUrl.toString(),
    file_name: lookup.data.file_name,
  });
});
