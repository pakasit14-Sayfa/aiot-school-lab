// Public boundary for completing a login email-OTP challenge. The verifier
// RPC remains service-role only; callers receive a session only after the
// one-use challenge succeeds.

import { createClient } from "npm:@supabase/supabase-js@2";

const minimumResponseMs = 350;

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

async function enforceMinimumResponseTime(startedAt: number): Promise<void> {
  const remaining = minimumResponseMs - (performance.now() - startedAt);
  if (remaining > 0) {
    await new Promise((resolve) => setTimeout(resolve, remaining));
  }
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return json({ error: "method_not_allowed" }, 405);
  }
  const startedAt = performance.now();

  let otpToken: string | null = null;
  let otpCode: string | null = null;
  try {
    const body = await req.json();
    otpToken = typeof body.otp_token === "string"
      ? body.otp_token.trim()
      : null;
    otpCode = typeof body.otp_code === "string" ? body.otp_code.trim() : null;
  } catch {
    // Invalid bodies deliberately receive the same result as invalid OTPs.
  }

  if (!otpToken?.match(/^lo_[0-9a-f]{64}$/) || !otpCode?.match(/^\d{6}$/)) {
    await enforceMinimumResponseTime(startedAt);
    return json({ session: null });
  }

  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!serviceRoleKey) {
    console.error("auth-verify-otp server configuration unavailable");
    await enforceMinimumResponseTime(startedAt);
    return json({ session: null });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    serviceRoleKey,
  );
  const { data, error } = await supabase.rpc("auth_verify_login_otp", {
    p_otp_token: otpToken,
    p_otp_code: otpCode,
  }).maybeSingle();

  if (error) {
    console.error("auth_verify_login_otp failed without challenge fields");
  }

  await enforceMinimumResponseTime(startedAt);
  return json({ session: error ? null : data ?? null });
});
