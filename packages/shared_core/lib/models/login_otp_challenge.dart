import 'user_model.dart';

class LoginOtpChallenge {
  const LoginOtpChallenge({
    required this.token,
    required this.expiresAt,
    this.devOtpCode,
  });

  final String token;
  final DateTime expiresAt;

  /// Only ever set by a local Supabase instance with no email provider
  /// configured (see `isLocalDev()` in the auth-sign-in/accept-staff-invitation
  /// Edge Functions) — a real deployed project never sends this field, since
  /// the code is otherwise unrecoverable (only its hash is stored).
  final String? devOtpCode;

  factory LoginOtpChallenge.fromResponse(Map<String, dynamic> response) {
    final token = response['otp_token'];
    final expiresAt = response['otp_expires_at'];
    if (token is! String || !token.startsWith('lo_') || expiresAt is! String) {
      throw const FormatException('invalid_login_otp_challenge');
    }
    final devOtpCode = response['dev_otp_code'];
    return LoginOtpChallenge(
      token: token,
      expiresAt: DateTime.parse(expiresAt).toUtc(),
      devOtpCode: devOtpCode is String ? devOtpCode : null,
    );
  }
}

class AuthSignInResult {
  const AuthSignInResult._({this.user, this.challenge});

  const AuthSignInResult.authenticated(UserModel user) : this._(user: user);

  const AuthSignInResult.otpRequired(LoginOtpChallenge challenge)
    : this._(challenge: challenge);

  final UserModel? user;
  final LoginOtpChallenge? challenge;

  bool get isAuthenticated => user != null;
  bool get requiresOtp => challenge != null;
}
