// HMAC-authenticated sensor ingest. The raw device token is never sent.
// Signature input:
//   METHOD + "\n" + PATH + "\n" + UNIX_SECONDS + "\n" + NONCE + "\n" + SHA256(RAW_BODY)
// HMAC key: lowercase hex SHA-256 of the device token.

import { createClient } from "npm:@supabase/supabase-js@2";

const path = "/functions/v1/gateway-sensor-ingest";

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

async function sha256Hex(value: string): Promise<string> {
  const bytes = new TextEncoder().encode(value);
  const digest = await crypto.subtle.digest("SHA-256", bytes);
  return Array.from(new Uint8Array(digest), (byte) =>
    byte.toString(16).padStart(2, "0")
  ).join("");
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  const gatewayId = req.headers.get("x-gateway-id");
  const timestampText = req.headers.get("x-timestamp");
  const nonce = req.headers.get("x-nonce");
  const signature = req.headers.get("x-gateway-signature");
  const timestamp = Number(timestampText);

  if (
    !gatewayId ||
    !timestampText ||
    !Number.isSafeInteger(timestamp) ||
    !nonce ||
    !signature
  ) {
    return json({ error: "invalid_gateway_request" }, 401);
  }

  const rawBody = await req.text();
  let readings: unknown;
  try {
    const parsed = JSON.parse(rawBody);
    readings = parsed.readings;
    if (!Array.isArray(readings)) throw new Error("readings_must_be_array");
  } catch {
    return json({ error: "invalid_payload" }, 400);
  }

  const bodyHash = await sha256Hex(rawBody);
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const verification = await supabase.rpc("verify_gateway_request", {
    p_gateway_id: gatewayId,
    p_timestamp: timestamp,
    p_nonce: nonce,
    p_signature: signature,
    p_method: req.method,
    p_path: path,
    p_body_hash: bodyHash,
  });

  if (verification.error || verification.data !== true) {
    console.error("gateway verification failed:", verification.error?.message);
    return json({ error: "invalid_gateway_request" }, 401);
  }

  const result = await supabase.rpc("ingest_sensor_readings_verified", {
    p_gateway_id: gatewayId,
    p_readings: readings,
  });
  if (result.error) {
    console.error("signed sensor ingest failed:", result.error.message);
    return json({ error: "invalid_payload" }, 400);
  }

  return json({ inserted: result.data }, 200);
});
