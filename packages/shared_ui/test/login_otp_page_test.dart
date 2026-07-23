import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  testWidgets('submits a six-digit OTP with the opaque login challenge', (
    tester,
  ) async {
    String? submittedToken;
    String? submittedCode;
    UserModel? verifiedUser;

    await tester.pumpWidget(
      MaterialApp(
        home: LoginOtpPage(
          challenge: LoginOtpChallenge(
            token: 'lo_${'a' * 64}',
            expiresAt: DateTime.utc(2026, 7, 22, 12, 10),
          ),
          verifyOtp: ({required otpToken, required otpCode}) async {
            submittedToken = otpToken;
            submittedCode = otpCode;
            return const UserModel(
              uid: 'user-1',
              name: 'Test Teacher',
              email: 'teacher@example.ac.th',
              role: UserRole.teacher,
              schoolId: 'school-1',
            );
          },
          onVerified: (user) => verifiedUser = user,
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('login-otp-code')), '123456');
    await tester.tap(find.byKey(const Key('login-otp-submit')));
    await tester.pumpAndSettle();

    expect(submittedToken, 'lo_${'a' * 64}');
    expect(submittedCode, '123456');
    expect(verifiedUser?.role, UserRole.teacher);
  });
}
