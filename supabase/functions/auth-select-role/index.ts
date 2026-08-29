// Public boundary for choosing a role from a multi-role login challenge.
// The RPC issues an MFA challenge (if OTP required) or mints a session directly.

import { createClient } from "npm:@supabase/supabase-js@2";

declare const EdgeRuntime: {
  waitUntil(promise: Promise<unknown>): void;
};

type SupabaseClient = ReturnType<typeof createClient>;

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

function clientAddress(req: Request): string | null {
  for (const name of ["cf-connecting-ip", "x-real-ip"]) {
    const value = req.headers.get(name)?.trim();
    if (value) return value.slice(0, 64);
  }
  const forwarded = req.headers.get("x-forwarded-for");
  const value = forwarded?.split(",").at(-1)?.trim();
  return value ? value.slice(0, 64) : null;
}

function hex(bytes: ArrayBuffer): string {
  return Array.from(new Uint8Array(bytes), (byte) =>
    byte.toString(16).padStart(2, "0")
  ).join("");
}

async function hmacSha256Hex(key: string, value: string): Promise<string> {
  const encoder = new TextEncoder();
  const cryptoKey = await crypto.subtle.importKey(
    "raw",
    encoder.encode(key),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  return hex(await crypto.subtle.sign("HMAC", cryptoKey, encoder.encode(value)));
}

async function enforceMinimumResponseTime(startedAt: number): Promise<void> {
  const remaining = minimumResponseMs - (performance.now() - startedAt);
  if (remaining > 0) {
    await new Promise((resolve) => setTimeout(resolve, remaining));
  }
}

function isLocalDev(): boolean {
  const url = Deno.env.get("SUPABASE_URL") ?? "";
  return url.includes("127.0.0.1") || url.includes("localhost") ||
    url.includes("kong:8000");
}

async function sendLoginOtpEmail(
  _supabase: SupabaseClient,
  email: string,
  otpCode: string,
): Promise<void> {
  const resendApiKey = Deno.env.get("RESEND_API_KEY");
  const fromEmail = Deno.env.get("RESEND_FROM_EMAIL");
  if (!resendApiKey || !fromEmail) {
    console.error("login OTP email provider is not configured");
    return;
  }

  try {
    const emailResponse = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${resendApiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: fromEmail,
        to: email,
        subject: "รหัสยืนยันการเข้าสู่ระบบ — AIoT School Lab",
        html: `
          <p>รหัสยืนยันการเข้าสู่ระบบของคุณคือ:</p>
          <p style="font-size:28px;font-weight:bold;letter-spacing:4px;">
            ${otpCode}
          </p>
          <p>รหัสนี้มีอายุ 10 นาทีและใช้ได้ครั้งเดียว</p>
        `,
      }),
      signal: AbortSignal.timeout(10_000),
    });
    if (!emailResponse.ok) {
      console.error("login OTP email delivery failed");
    }
  } catch {
    console.error("login OTP email provider unavailable");
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

  let roleSelectionToken: string | null = null;
  let role: string | null = null;
  let schoolId: string | null = null;
  let deviceTrustToken: string | null = null;
  try {
    const body = await req.json();
    roleSelectionToken = typeof body.role_selection_token === "string"
      ? body.role_selection_token.trim()
      : null;
    role = typeof body.role === "string" ? body.role.trim() : null;
    schoolId = typeof body.school_id === "string" ? body.school_id.trim() : null;
    deviceTrustToken = typeof body.device_trust_token === "string"
      ? body.device_trust_token
      : null;
  } catch {
    // Invalid bodies deliberately receive generic error.
  }

  if (!roleSelectionToken || !role) {
    await enforceMinimumResponseTime(startedAt);
    return json({ session: null, error: "invalid_request" }, 400);
  }

  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!serviceRoleKey) {
    console.error("auth-select-role server configuration unavailable");
    await enforceMinimumResponseTime(startedAt);
    return json({ session: null });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    serviceRoleKey,
  );
  const address = clientAddress(req);
  const ipPepper = Deno.env.get("LOGIN_IP_PEPPER") ?? serviceRoleKey;
  const ipFingerprint = address
    ? await hmacSha256Hex(ipPepper, `login-ip:v1:${address}`)
    : null;

  const { data, error } = await supabase.rpc("auth_select_role", {
    p_role_selection_token: roleSelectionToken,
    p_role: role,
    p_school_id: schoolId,
    p_device_info: req.headers.get("user-agent")?.slice(0, 255) ?? null,
    p_ip_address: ipFingerprint,
    p_device_trust_token: deviceTrustToken,
  }).maybeSingle();

  if (error) {
    console.error("auth_select_role failed:", error.message);
    await enforceMinimumResponseTime(startedAt);
    return json({ error: error.message }, 400);
  }

  if (data?.auth_state === "rate_limited") {
    await enforceMinimumResponseTime(startedAt);
    // 200, not 429: a real rate-limited *response* still needs to reach
    // the client's normal JSON parsing path. A non-2xx status makes the
    // Supabase client throw instead, which the caller's fallback-to-RPC
    // logic then misreads as "edge function unreachable" and retries via
    // direct RPC — reusing an already-consumed role_selection_token and
    // masking this real error behind a confusing "expired" one instead.
    return json({ error: "rate_limited" });
  }

  if (data?.auth_state === "mfa_required") {
    const otpCode = data.otp_code;
    const otpToken = data.otp_token;
    if (typeof otpCode !== "string" || typeof otpToken !== "string" || typeof data.email !== "string") {
      console.error("auth_select_role returned an invalid MFA challenge");
      await enforceMinimumResponseTime(startedAt);
      return json({ session: null });
    }

    EdgeRuntime.waitUntil(
      sendLoginOtpEmail(supabase, data.email, otpCode),
    );
    await enforceMinimumResponseTime(startedAt);
    return json({
      session: null,
      mfa_required: true,
      otp_token: otpToken,
      otp_expires_at: data.otp_expires_at,
      ...(isLocalDev() && !Deno.env.get("RESEND_API_KEY")
        ? { dev_otp_code: otpCode }
        : {}),
    });
  }

  if (data?.auth_state !== "authenticated") {
    await enforceMinimumResponseTime(startedAt);
    return json({ session: null });
  }

  const {
    auth_state: _authState,
    otp_token: _otpToken,
    otp_code: _otpCode,
    otp_expires_at: _otpExpiresAt,
    ...session
  } = data;

  await enforceMinimumResponseTime(startedAt);
  return json({ session });
});
