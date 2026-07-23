import 'supabase_config.dart';

/// Password reset — ไม่ต้องมี session token เพราะเป็น flow ก่อนล็อกอิน
class PasswordResetService {
  static Future<void> resetPassword(String email) async {
    await supabase.functions.invoke(
      'request-password-reset',
      body: {'email': email.trim().toLowerCase()},
    );
  }

  static Future<void> confirmPasswordReset({
    required String email,
    required String otpCode,
    required String newPassword,
  }) async {
    await supabase.rpc(
      'confirm_password_reset',
      params: {
        'p_email': email.trim().toLowerCase(),
        'p_otp_code': otpCode.trim(),
        'p_new_password': newPassword,
      },
    );
  }
}
