// Sends a password-reset OTP by email via Resend.
//
// Deliberately dumb: it always answers the client with a generic
// "ok" regardless of whether the email belongs to a real account, so
// the endpoint can't be used to enumerate registered emails. The
// actual account lookup + OTP generation happens in Postgres
// (request_password_reset_otp), called here with the service_role
// key since that RPC is not granted to anon/authenticated — this
// function is the only caller allowed to see the plaintext code.
//
// Requires these secrets to be set (`supabase secrets set ...`):
//   RESEND_API_KEY    - Resend API key
//   RESEND_FROM_EMAIL - verified sender, e.g. "AIoT School Lab <noreply@yourdomain.com>"
// SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY are injected automatically
// by the Edge Function runtime.

import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const genericResponse = new Response(
  JSON.stringify({ message: "หากอีเมลนี้มีอยู่ในระบบ เราได้ส่งรหัสยืนยันไปให้แล้ว" }),
  { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
);

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  let email: string | undefined;
  try {
    const body = await req.json();
    email = typeof body.email === "string" ? body.email.trim().toLowerCase() : undefined;
  } catch {
    // fall through — treated as invalid below
  }

  if (!email) {
    return new Response(JSON.stringify({ error: "email is required" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { data, error } = await supabase
    .rpc("request_password_reset_otp", { p_email: email })
    .maybeSingle();

  if (error) {
    if (error.message?.includes("rate_limited")) {
      // still generic to the client — don't reveal timing info either
      return genericResponse;
    }
    console.error("request_password_reset_otp failed:", error);
    return genericResponse;
  }

  if (!data) {
    // no account for this email — stay silent
    return genericResponse;
  }

  const resendApiKey = Deno.env.get("RESEND_API_KEY");
  const fromEmail = Deno.env.get("RESEND_FROM_EMAIL");

  if (!resendApiKey || !fromEmail) {
    console.error("RESEND_API_KEY / RESEND_FROM_EMAIL not configured");
    return genericResponse;
  }

  const emailResponse = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${resendApiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from: fromEmail,
      to: email,
      subject: "รหัสยืนยันสำหรับรีเซ็ตรหัสผ่าน — AIoT School Lab",
      html: `
        <p>สวัสดีคุณ ${data.first_name ?? ""},</p>
        <p>รหัสยืนยันสำหรับรีเซ็ตรหัสผ่านของคุณคือ:</p>
        <p style="font-size:28px;font-weight:bold;letter-spacing:4px;">${data.otp_code}</p>
        <p>รหัสนี้จะหมดอายุใน 15 นาที หากคุณไม่ได้ร้องขอ กรุณาละเว้นอีเมลนี้</p>
      `,
    }),
  });

  if (!emailResponse.ok) {
    console.error("Resend send failed:", await emailResponse.text());
  }

  return genericResponse;
});
