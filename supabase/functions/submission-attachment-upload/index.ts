// Mints a short-lived Storage signed-upload URL for the private
// `submission-attachments` bucket. Clients never touch storage.objects
// directly — assert_submission_upload_access (student who owns the
// submission version) gates every path, matching this project's
// RPC-only/deny-all philosophy. Mirrors lesson-material-upload.

import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function sanitizeFileName(fileName: string): string {
  return fileName.replace(/[^a-zA-Z0-9._-]/g, "_").slice(-180);
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return json({ error: "method_not_allowed" }, 405);
  }

  let token: string | null = null;
  let submissionVersionId: string | null = null;
  let fileName: string | null = null;
  try {
    const body = await req.json();
    token = typeof body.token === "string" ? body.token.trim() : null;
    submissionVersionId = typeof body.submission_version_id === "string"
      ? body.submission_version_id
      : null;
    fileName = typeof body.file_name === "string" ? body.file_name.trim() : null;
  } catch {
    // Invalid bodies deliberately receive the generic failure result.
  }

  if (!token || !submissionVersionId || !fileName) {
    return json({ error: "invalid_request" }, 400);
  }

  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!serviceRoleKey) {
    console.error("submission-attachment-upload server configuration unavailable");
    return json({ error: "invalid_request" }, 400);
  }
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    serviceRoleKey,
  );

  const access = await supabase.rpc("assert_submission_upload_access", {
    p_token: token,
    p_submission_version_id: submissionVersionId,
  });
  if (access.error) {
    return json({ error: "forbidden" }, 403);
  }

  const storagePath = `${submissionVersionId}/${crypto.randomUUID()}-${
    sanitizeFileName(fileName)
  }`;

  const signed = await supabase.storage
    .from("submission-attachments")
    .createSignedUploadUrl(storagePath);

  if (signed.error || !signed.data) {
    console.error("failed to create signed upload url:", signed.error?.message);
    return json({ error: "upload_url_unavailable" }, 500);
  }

  return json({
    storage_path: storagePath,
    token: signed.data.token,
  });
});
