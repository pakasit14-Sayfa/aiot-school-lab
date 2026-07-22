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
