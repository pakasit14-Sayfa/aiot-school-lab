// Public login boundary. The database RPC is service-role only so clients
// cannot choose or spoof the address used by the IP rate-limit bucket.

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
  // Supabase's gateway supplies these headers. For x-forwarded-for, use the
  // last hop so a client-prepended value is not trusted as the rate-limit key.
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

async function recordOperationalAlert(
  supabase: SupabaseClient,
  category: string,
  severity: "warning" | "critical",
  details: Record<string, unknown>,
): Promise<void> {
  const result = await supabase.rpc("record_operational_alert", {
    p_category: category,
    p_severity: severity,
    p_details: details,
  });
  if (result.error) {
    console.error("failed to persist operational alert");
  }

  const webhookUrl = Deno.env.get("SECURITY_ALERT_WEBHOOK_URL");
  if (!webhookUrl) return;
  try {
    const response = await fetch(webhookUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ category, severity, details }),
      signal: AbortSignal.timeout(10_000),
    });
    if (!response.ok) console.error("operational alert webhook failed");
  } catch {
    console.error("operational alert webhook unavailable");
  }
}

async function sendLoginOtpEmail(
  supabase: SupabaseClient,
  email: string,
  otpCode: string,
): Promise<void> {
  const resendApiKey = Deno.env.get("RESEND_API_KEY");
  const fromEmail = Deno.env.get("RESEND_FROM_EMAIL");
  if (!resendApiKey || !fromEmail) {
    console.error("login OTP email provider is not configured");
    await recordOperationalAlert(
      supabase,
      "login_otp_email_configuration_missing",
      "critical",
      { provider: "resend" },
    );
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
          <p>หากคุณไม่ได้พยายามเข้าสู่ระบบ กรุณาแจ้งผู้ดูแลโรงเรียน</p>
        `,
      }),
      signal: AbortSignal.timeout(10_000),
    });
    if (!emailResponse.ok) {
      console.error("login OTP email delivery failed");
      await recordOperationalAlert(
        supabase,
        "login_otp_email_delivery_failed",
        "critical",
        { provider: "resend", http_status: emailResponse.status },
      );
    }
  } catch {
    console.error("login OTP email provider unavailable");
    await recordOperationalAlert(
      supabase,
      "login_otp_email_delivery_failed",
      "critical",
      { provider: "resend", reason: "network_or_timeout" },
    );
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

  let email: string | null = null;
  let password: string | null = null;
  try {
    const body = await req.json();
    email = typeof body.email === "string"
      ? body.email.trim().toLowerCase()
      : null;
    password = typeof body.password === "string" ? body.password : null;
  } catch {
    // Invalid bodies deliberately receive the generic authentication result.
  }

  if (
    !email || !password || email.length > 320 || password.length > 1024
  ) {
    await enforceMinimumResponseTime(startedAt);
    return json({ session: null });
  }

  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!serviceRoleKey) {
    console.error("auth-sign-in server configuration unavailable");
    await enforceMinimumResponseTime(startedAt);
    return json({ session: null });
  }
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    serviceRoleKey,
  );
  const address = clientAddress(req);
  // Prefer a dedicated secret. Falling back to the server-only service key
  // keeps raw IPv4 addresses out of Postgres even before rollout config is set.
  const ipPepper = Deno.env.get("LOGIN_IP_PEPPER") ?? serviceRoleKey;
  const ipFingerprint = address
    ? await hmacSha256Hex(ipPepper, `login-ip:v1:${address}`)
    : null;
  const { data, error } = await supabase.rpc("auth_sign_in", {
    p_email: email,
    p_password: password,
    p_device_info: req.headers.get("user-agent")?.slice(0, 255) ?? null,
    p_ip_address: ipFingerprint,
  }).maybeSingle();

  if (error) {
    console.error("auth_sign_in failed without user-identifying fields");
    await enforceMinimumResponseTime(startedAt);
    return json({ session: null });
  }

  if (data?.auth_state === "rate_limited") {
    await enforceMinimumResponseTime(startedAt);
    return json({ error: "rate_limited" }, 429);
  }

  if (data?.auth_state === "mfa_required") {
    const otpCode = data.otp_code;
    const otpToken = data.otp_token;
    if (
      typeof otpCode !== "string" || typeof otpToken !== "string" ||
      typeof data.email !== "string"
    ) {
      console.error("auth_sign_in returned an invalid MFA challenge");
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
