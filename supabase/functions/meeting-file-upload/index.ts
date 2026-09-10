import { createClient } from "npm:@supabase/supabase-js@2";

const cors = { "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS" };
const reply = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { ...cors, "Content-Type": "application/json" } });

// Custom sessions are checked by the RPC; this endpoint does not use Auth JWTs.
Deno.serve(async (request) => {
  if (request.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (request.method !== "POST") return reply({ error: "method_not_allowed" }, 405);
  let body: Record<string, unknown>;
  try { body = await request.json(); } catch { return reply({ error: "invalid_json" }, 400); }
  if (!body || typeof body.token !== "string" || typeof body.meeting_id !== "string" ||
      typeof body.file_name !== "string" || !body.file_name.trim()) {
    return reply({ error: "invalid_request" }, 400);
  }
  const client = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    { auth: { persistSession: false, autoRefreshToken: false } });
  const { data: schoolId, error } = await client.rpc("assert_meeting_attachment_upload_access",
    { p_token: body.token, p_meeting_id: body.meeting_id });
  if (error || !schoolId) return reply({ error: "forbidden" }, 403);
  const name = body.file_name.trim().replace(/[^\p{L}\p{N}._-]/gu, "_").slice(-180);
  const path = `${schoolId}/${body.meeting_id}/${crypto.randomUUID()}-${name}`;
  const { data, error: uploadError } = await client.storage.from("meeting-files").createSignedUploadUrl(path);
  if (uploadError || !data) return reply({ error: "upload_unavailable" }, 500);
  return reply({ storage_path: path, token: data.token });
});
