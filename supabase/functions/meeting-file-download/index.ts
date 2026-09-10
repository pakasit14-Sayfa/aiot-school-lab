import { createClient } from "npm:@supabase/supabase-js@2";

const cors = { "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS" };
const reply = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { ...cors, "Content-Type": "application/json" } });

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (request.method !== "POST") return reply({ error: "method_not_allowed" }, 405);
  let body: Record<string, unknown>;
  try { body = await request.json(); } catch { return reply({ error: "invalid_json" }, 400); }
  if (!body || typeof body.token !== "string" || typeof body.attachment_id !== "string") {
    return reply({ error: "invalid_request" }, 400);
  }
  const client = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    { auth: { persistSession: false, autoRefreshToken: false } });
  const { data: record, error } = await client.rpc("get_meeting_attachment_for_download",
    { p_token: body.token, p_attachment_id: body.attachment_id }).maybeSingle();
  if (error || !record) return reply({ error: "forbidden" }, 403);
  const { data, error: downloadError } = await client.storage.from("meeting-files")
    .createSignedUrl(record.storage_path, 60, { download: record.file_name });
  if (downloadError || !data) return reply({ error: "download_unavailable" }, 500);
  // Local Docker's internal URL is not browser-accessible. Configure
  // PUBLIC_STORAGE_URL=http://127.0.0.1:54321 in the local functions env file.
  const url = new URL(data.signedUrl);
  const publicBase = new URL(Deno.env.get("PUBLIC_STORAGE_URL") ?? Deno.env.get("SUPABASE_URL")!);
  url.protocol = publicBase.protocol;
  url.host = publicBase.host;
  return reply({ signed_url: url.toString(), file_name: record.file_name });
});
