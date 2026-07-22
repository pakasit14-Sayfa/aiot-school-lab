import 'user_model.dart';

class LoginOtpChallenge {
  const LoginOtpChallenge({required this.token, required this.expiresAt});

  final String token;
  final DateTime expiresAt;

  factory LoginOtpChallenge.fromResponse(Map<String, dynamic> response) {
    final token = response['otp_token'];
    final expiresAt = response['otp_expires_at'];
    if (token is! String || !token.startsWith('lo_') || expiresAt is! String) {
      throw const FormatException('invalid_login_otp_challenge');
    }
    return LoginOtpChallenge(
      token: token,
      expiresAt: DateTime.parse(expiresAt).toUtc(),
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
