// Starts Parent Binding without disclosing whether a Binding Code is valid.
// Postgres validates the code and creates the OTP. This Edge Function is the
// only caller allowed to receive the plaintext OTP; the app receives only an
// opaque verification token and the same generic message for every request.

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

function fakeVerificationToken(): string {
  const bytes = crypto.getRandomValues(new Uint8Array(32));
  return `pv_${Array.from(bytes, (byte) =>
    byte.toString(16).padStart(2, "0")
  ).join("")}`;
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

async function sendParentOtpEmail(
  supabase: SupabaseClient,
  email: string,
  otpCode: string,
): Promise<void> {
  const resendApiKey = Deno.env.get("RESEND_API_KEY");
  const fromEmail = Deno.env.get("RESEND_FROM_EMAIL");
  if (!resendApiKey || !fromEmail) {
    console.error("parent OTP email provider is not configured");
    await recordOperationalAlert(
      supabase,
      "parent_otp_email_configuration_missing",
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
        subject: "รหัสยืนยันผู้ปกครอง — AIoT School Lab",
        html: `
          <p>รหัสยืนยันสำหรับส่งคำขอผูกบัญชีผู้ปกครองคือ:</p>
          <p style="font-size:28px;font-weight:bold;letter-spacing:4px;">
            ${otpCode}
          </p>
          <p>รหัสนี้มีอายุ 10 นาทีและใช้ได้ครั้งเดียว</p>
          <p>หากคุณไม่ได้ดำเนินการ กรุณาละเว้นอีเมลนี้</p>
        `,
      }),
      signal: AbortSignal.timeout(10_000),
    });
    if (!emailResponse.ok) {
      console.error("parent OTP email delivery failed");
      await recordOperationalAlert(
        supabase,
        "parent_otp_email_delivery_failed",
        "critical",
        { provider: "resend", http_status: emailResponse.status },
      );
    }
  } catch {
    console.error("parent OTP email provider unavailable");
    await recordOperationalAlert(
      supabase,
      "parent_otp_email_delivery_failed",
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

  let code: string | undefined;
  let email: string | undefined;
  try {
    const body = await req.json();
    code = typeof body.code === "string" ? body.code.trim() : undefined;
    email = typeof body.email === "string"
      ? body.email.trim().toLowerCase()
      : undefined;
  } catch {
    // Invalid input receives the same generic public result.
  }

  let verificationToken = fakeVerificationToken();

  if (!code || !email) {
    await enforceMinimumResponseTime(startedAt);
    return json({
      verification_token: verificationToken,
      message: "หากข้อมูลถูกต้อง เราได้ส่งรหัสยืนยันไปยังอีเมลแล้ว",
    });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { data, error } = await supabase
    .rpc("request_parent_binding_otp", { p_code: code, p_email: email })
    .maybeSingle();

  if (error) {
    // Rate limits and invalid codes are intentionally indistinguishable.
    console.error("request_parent_binding_otp failed");
    if (!error.message.includes("rate_limited")) {
      EdgeRuntime.waitUntil(
        recordOperationalAlert(
          supabase,
          "parent_otp_database_failure",
          "critical",
          { operation: "request_parent_binding_otp" },
        ),
      );
    }
  }

  if (data) {
    verificationToken = data.verification_token;
    EdgeRuntime.waitUntil(
      sendParentOtpEmail(supabase, email, data.otp_code),
    );
  }

  await enforceMinimumResponseTime(startedAt);
  return json({
    verification_token: verificationToken,
    message: "หากข้อมูลถูกต้อง เราได้ส่งรหัสยืนยันไปยังอีเมลแล้ว",
  });
});
