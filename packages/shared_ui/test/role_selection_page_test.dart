import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  testWidgets('renders all available roles and allows selecting a non-OTP role', (
    tester,
  ) async {
    String? selectedToken;
    UserRole? selectedRole;
    UserModel? completedUser;

    const challenge = RoleSelectionChallenge(
      roleSelectionToken: 'rs_test_1234567890abcdef',
      availableRoles: [
        AvailableRoleOption(
          role: UserRole.schoolAdmin,
          schoolId: 'school-1',
          schoolName: 'โรงเรียนสาธิต AIoT',
        ),
        AvailableRoleOption(
          role: UserRole.teacher,
          schoolId: 'school-1',
          schoolName: 'โรงเรียนสาธิต AIoT',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: RoleSelectionPage(
          challenge: challenge,
          selectRole: ({
            required String roleSelectionToken,
            required UserRole role,
            String? schoolId,
          }) async {
            selectedToken = roleSelectionToken;
            selectedRole = role;
            return const AuthSignInResult.authenticated(
              UserModel(
                uid: 'user-123',
                name: 'Dual Role User',
                email: 'dual@test.local',
                role: UserRole.schoolAdmin,
                schoolId: 'school-1',
              ),
            );
          },
          onSelected: (user) => completedUser = user,
        ),
      ),
    );

    expect(find.text('เลือกบทบาทการใช้งาน'), findsOneWidget);
    expect(find.text('ผู้ดูแลโรงเรียน (School Admin)'), findsOneWidget);
    expect(find.text('คุณครู (Teacher)'), findsOneWidget);
    expect(find.text('โรงเรียนสาธิต AIoT'), findsNWidgets(2));

    // Tap School Admin option
    await tester.tap(find.text('ผู้ดูแลโรงเรียน (School Admin)'));
    await tester.pumpAndSettle();

    expect(selectedToken, 'rs_test_1234567890abcdef');
    expect(selectedRole, UserRole.schoolAdmin);
    expect(completedUser?.role, UserRole.schoolAdmin);
  });

  testWidgets('selecting an OTP-required role advances to OTP screen', (
    tester,
  ) async {
    const challenge = RoleSelectionChallenge(
      roleSelectionToken: 'rs_test_1234567890abcdef',
      availableRoles: [
        AvailableRoleOption(
          role: UserRole.teacher,
          schoolId: 'school-1',
          schoolName: 'โรงเรียนสาธิต AIoT',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: RoleSelectionPage(
          challenge: challenge,
          selectRole: ({
            required String roleSelectionToken,
            required UserRole role,
            String? schoolId,
          }) async {
            return AuthSignInResult.otpRequired(
              LoginOtpChallenge(
                token: 'lo_${'b' * 64}',
                expiresAt: DateTime.utc(2026, 8, 25, 15, 0),
              ),
            );
          },
          onSelected: (_) {},
        ),
      ),
    );

    await tester.tap(find.text('คุณครู (Teacher)'));
    await tester.pumpAndSettle();

    // Verify OTP page is pushed
    expect(find.text('ยืนยันการเข้าสู่ระบบ'), findsOneWidget);
    expect(find.text('กรอกรหัส 6 หลักจากอีเมล'), findsOneWidget);
  });
}
