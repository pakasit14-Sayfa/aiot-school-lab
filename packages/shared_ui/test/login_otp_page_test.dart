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
          verifyOtp: ({
            required otpToken,
            required otpCode,
            rememberDevice = false,
          }) async {
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

  /// เจอจริงตอนทดสอบ 2026-09-09: Docker ดับ → Supabase/Edge Function ลงทั้งชุด
  /// → หน้านี้ยังขึ้นว่า "รหัสไม่ถูกต้อง หมดอายุ หรือถูกใช้แล้ว" ผู้ใช้จึงนั่ง
  /// กรอกรหัสใหม่ซ้ำ ๆ ทั้งที่ไม่มีรหัสไหนผ่านได้เลยเพราะระบบหลังบ้านไม่อยู่
  group('ข้อความตอนยืนยันรหัสไม่ผ่าน', () {
    Future<void> pumpWithFailure(WidgetTester tester, Object error) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginOtpPage(
            challenge: LoginOtpChallenge(
              token: 'lo_${'a' * 64}',
              expiresAt: DateTime.utc(2026, 7, 22, 12, 10),
            ),
            verifyOtp: ({
              required otpToken,
              required otpCode,
              rememberDevice = false,
            }) async => throw error,
            onVerified: (_) {},
          ),
        ),
      );
      await tester.enterText(find.byKey(const Key('login-otp-code')), '123456');
      await tester.tap(find.byKey(const Key('login-otp-submit')));
      await tester.pumpAndSettle();
    }

    testWidgets('รหัสผิดจริง — บอกว่ารหัสไม่ถูกต้องได้ตามเดิม', (tester) async {
      await pumpWithFailure(tester, Exception('invalid_or_expired_otp'));

      expect(find.text('รหัสไม่ถูกต้อง หมดอายุ หรือถูกใช้แล้ว'), findsOneWidget);
    });

    testWidgets('ต่อระบบไม่ได้ — ต้องไม่โทษว่ารหัสผู้ใช้ผิด', (tester) async {
      await pumpWithFailure(
        tester,
        Exception('ClientException: Connection refused'),
      );

      expect(find.text('รหัสไม่ถูกต้อง หมดอายุ หรือถูกใช้แล้ว'), findsNothing);
      expect(
        find.textContaining('เชื่อมต่อระบบยืนยันตัวตนไม่ได้'),
        findsOneWidget,
      );
      // ข้อความ exception ดิบต้องไม่หลุดขึ้นจอ
      expect(find.textContaining('Connection refused'), findsNothing);
    });
  });
}
