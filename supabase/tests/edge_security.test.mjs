import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import test from "node:test";

const parentOtpSource = readFileSync(
  new URL("../functions/request-parent-binding-otp/index.ts", import.meta.url),
  "utf8",
);
const authSource = readFileSync(
  new URL("../functions/auth-sign-in/index.ts", import.meta.url),
  "utf8",
);
const loginOtpVerifySource = readFileSync(
  new URL("../functions/auth-verify-otp/index.ts", import.meta.url),
  "utf8",
);
const courseFileUploadSource = readFileSync(
  new URL("../functions/course-file-upload/index.ts", import.meta.url),
  "utf8",
);
const courseFileDownloadSource = readFileSync(
  new URL("../functions/course-file-download/index.ts", import.meta.url),
  "utf8",
);
const acceptInvitationSource = readFileSync(
  new URL("../functions/accept-staff-invitation/index.ts", import.meta.url),
  "utf8",
);

test("parent OTP email delivery is detached from the public response", () => {
  assert.match(parentOtpSource, /EdgeRuntime\.waitUntil\(/);
  assert.match(parentOtpSource, /enforceMinimumResponseTime\(startedAt\)/);
});

test("parent OTP delivery failures create an operational alert", () => {
  assert.match(parentOtpSource, /recordOperationalAlert/);
  assert.match(parentOtpSource, /parent_otp_email_delivery_failed/);
});

test("login sends only a peppered IP fingerprint to Postgres", () => {
  assert.match(authSource, /LOGIN_IP_PEPPER/);
  assert.match(authSource, /hmacSha256Hex/);
  assert.doesNotMatch(authSource, /p_ip_address:\s*clientAddress\(req\)/);
});

test("login OTP email delivery is detached and failures are alerted", () => {
  assert.match(authSource, /EdgeRuntime\.waitUntil\(\s*sendLoginOtpEmail/);
  assert.match(authSource, /login_otp_email_delivery_failed/);
  assert.match(authSource, /login_otp_email_configuration_missing/);
  assert.doesNotMatch(authSource, /otp_code:\s*data\.otp_code/);
});

test("login OTP verification stays behind the Edge service-role boundary", () => {
  assert.match(loginOtpVerifySource, /auth_verify_login_otp/);
  assert.match(loginOtpVerifySource, /SUPABASE_SERVICE_ROLE_KEY/);
  assert.match(loginOtpVerifySource, /enforceMinimumResponseTime\(startedAt\)/);
});

test("course file upload checks membership before minting a signed URL", () => {
  assert.match(courseFileUploadSource, /SUPABASE_SERVICE_ROLE_KEY/);
  assert.match(courseFileUploadSource, /assert_course_upload_access/);
  const accessCheckIndex = courseFileUploadSource.indexOf(
    "assert_course_upload_access",
  );
  const signedUrlIndex = courseFileUploadSource.indexOf(
    "createSignedUploadUrl",
  );
  assert.ok(accessCheckIndex > -1 && signedUrlIndex > -1);
  assert.ok(
    accessCheckIndex < signedUrlIndex,
    "membership must be checked before a signed upload URL is created",
  );
});

test("course file upload sanitizes the client-supplied file name", () => {
  assert.match(courseFileUploadSource, /sanitizeFileName/);
  assert.doesNotMatch(courseFileUploadSource, /\$\{fileName\}/);
});

test("course file download checks membership before minting a signed URL", () => {
  assert.match(courseFileDownloadSource, /SUPABASE_SERVICE_ROLE_KEY/);
  assert.match(courseFileDownloadSource, /get_course_file_for_download/);
  const lookupIndex = courseFileDownloadSource.indexOf(
    "get_course_file_for_download",
  );
  const signedUrlIndex = courseFileDownloadSource.indexOf("createSignedUrl");
  assert.ok(lookupIndex > -1 && signedUrlIndex > -1);
  assert.ok(
    lookupIndex < signedUrlIndex,
    "membership must be checked before a signed download URL is created",
  );
});

test("course file download URLs are short-lived", () => {
  assert.match(courseFileDownloadSource, /signedUrlTtlSeconds\s*=\s*60/);
});

test("the dev-only OTP echo is gated behind isLocalDev and a missing RESEND_API_KEY", () => {
  for (const source of [authSource, acceptInvitationSource]) {
    assert.match(source, /dev_otp_code/);
    const gateIndex = source.indexOf("isLocalDev() && !Deno.env.get(\"RESEND_API_KEY\")");
    const fieldIndex = source.indexOf("dev_otp_code: otpCode");
    assert.ok(gateIndex > -1 && fieldIndex > -1);
    assert.ok(
      gateIndex < fieldIndex,
      "dev_otp_code must be wrapped in the isLocalDev()+no-key spread guard, not returned unconditionally",
    );
    assert.match(
      source,
      /url\.includes\("127\.0\.0\.1"\)|url\.includes\("localhost"\)|url\.includes\("kong:8000"\)/,
    );
  }
});
