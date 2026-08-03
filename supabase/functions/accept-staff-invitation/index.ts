// Public invitation-acceptance boundary. accept_staff_invitation is
// service-role only because it can return a plaintext login OTP code for
// high-risk roles (super_admin, school_admin, teacher, executive) — this
// function sends that code by email and never returns it to the client.

import { createClient } from "npm:@supabase/supabase-js@2";

declare const EdgeRuntime: {
  waitUntil(promise: Promise<unknown>): void;
};

type SupabaseClient = ReturnType<typeof createClient>;

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

// Local Supabase (`supabase start`) has no real email provider — this must
// never be true against a hosted project, since Deno.env only sees vars the
// project's own Edge Runtime was started with.
function isLocalDev(): boolean {
  const url = Deno.env.get("SUPABASE_URL") ?? "";
  // `http://kong:8000` is the fixed internal hostname the Supabase CLI's
  // local dev stack (`supabase start`) always gives the Edge Runtime
  // container — never present against a hosted/deployed project.
  return url.includes("127.0.0.1") || url.includes("localhost") ||
    url.includes("kong:8000");
}

async function sendInvitationOtpEmail(
  supabase: SupabaseClient,
  email: string,
  otpCode: string,
): Promise<void> {
  const resendApiKey = Deno.env.get("RESEND_API_KEY");
  const fromEmail = Deno.env.get("RESEND_FROM_EMAIL");
  if (!resendApiKey || !fromEmail) {
    console.error("invitation OTP email provider is not configured");
    if (!isLocalDev()) {
      await recordOperationalAlert(
        supabase,
        "invitation_otp_email_configuration_missing",
        "critical",
        { provider: "resend" },
      );
    }
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
        subject: "รหัสยืนยันการสร้างบัญชี — AIoT School Lab",
        html: `
          <p>รหัสยืนยันการสร้างบัญชีของคุณคือ:</p>
          <p style="font-size:28px;font-weight:bold;letter-spacing:4px;">
            ${otpCode}
          </p>
          <p>รหัสนี้มีอายุ 10 นาทีและใช้ได้ครั้งเดียว</p>
          <p>หากคุณไม่ได้พยายามสร้างบัญชี กรุณาแจ้งผู้ดูแลโรงเรียน</p>
        `,
      }),
      signal: AbortSignal.timeout(10_000),
    });
    if (!emailResponse.ok) {
      console.error("invitation OTP email delivery failed");
      await recordOperationalAlert(
        supabase,
        "invitation_otp_email_delivery_failed",
        "critical",
        { provider: "resend", http_status: emailResponse.status },
      );
    }
  } catch {
    console.error("invitation OTP email provider unavailable");
    await recordOperationalAlert(
      supabase,
      "invitation_otp_email_delivery_failed",
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

  let token: string | null = null;
  let firstName: string | null = null;
  let lastName: string | null = null;
  let password: string | null = null;
  try {
    const body = await req.json();
    token = typeof body.token === "string" ? body.token.trim() : null;
    firstName = typeof body.first_name === "string"
      ? body.first_name.trim()
      : null;
    lastName = typeof body.last_name === "string"
      ? body.last_name.trim()
      : null;
    password = typeof body.password === "string" ? body.password : null;
  } catch {
    // Invalid bodies deliberately receive the generic failure result.
  }

  if (!token || !firstName || !lastName || !password) {
    return json({ error: "invalid_or_expired_invitation" }, 400);
  }

  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!serviceRoleKey) {
    console.error("accept-staff-invitation server configuration unavailable");
    return json({ error: "invalid_or_expired_invitation" }, 400);
  }
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    serviceRoleKey,
  );

  const { data, error } = await supabase.rpc("accept_staff_invitation", {
    p_token: token,
    p_first_name: firstName,
    p_last_name: lastName,
    p_password: password,
  }).maybeSingle();

  if (error || !data) {
    return json({ error: "invalid_or_expired_invitation" }, 400);
  }

  if (data.auth_state === "mfa_required") {
    const otpCode = data.otp_code;
    const otpToken = data.otp_token;
    if (
      typeof otpCode !== "string" || typeof otpToken !== "string" ||
      typeof data.email !== "string"
    ) {
      console.error("accept_staff_invitation returned an invalid MFA challenge");
      return json({ error: "invalid_or_expired_invitation" }, 400);
    }

    EdgeRuntime.waitUntil(
      sendInvitationOtpEmail(supabase, data.email, otpCode),
    );
    return json({
      session: null,
      mfa_required: true,
      otp_token: otpToken,
      otp_expires_at: data.otp_expires_at,
      // Local Supabase has no email provider configured, so the OTP would
      // otherwise be undeliverable and unrecoverable (only its hash is
      // stored). Echo it back for local dev only.
      ...(isLocalDev() && !Deno.env.get("RESEND_API_KEY")
        ? { dev_otp_code: otpCode }
        : {}),
    });
  }

  if (data.auth_state !== "authenticated") {
    return json({ error: "invalid_or_expired_invitation" }, 400);
  }

  const {
    auth_state: _authState,
    otp_token: _otpToken,
    otp_code: _otpCode,
    otp_expires_at: _otpExpiresAt,
    ...session
  } = data;

  return json({ session });
});
