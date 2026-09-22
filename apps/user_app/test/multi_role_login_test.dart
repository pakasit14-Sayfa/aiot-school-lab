import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  testWidgets('RoleSelectionPage renders and passes selection back', (
    tester,
  ) async {
    UserModel? chosenUser;

    const challenge = RoleSelectionChallenge(
      roleSelectionToken: 'rs_dual_role_token_abc123',
      availableRoles: [
        AvailableRoleOption(
          role: UserRole.teacher,
          schoolId: 'school-1',
          schoolName: 'โรงเรียนสาธิต AIoT',
        ),
        AvailableRoleOption(
          role: UserRole.schoolAdmin,
          schoolId: 'school-1',
          schoolName: 'โรงเรียนสาธิต AIoT',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: RoleSelectionPage(
          challenge: challenge,
          selectRole:
              ({
                required String roleSelectionToken,
                required UserRole role,
                String? schoolId,
              }) async {
                return AuthSignInResult.authenticated(
                  UserModel(
                    uid: 'teacher-1',
                    name: 'ครูผู้สอน',
                    email: 'teacher@aiot-school-lab.local',
                    role: role,
                    schoolId: schoolId ?? 'school-1',
                  ),
                );
              },
          onSelected: (user) {
            chosenUser = user;
          },
        ),
      ),
    );

    expect(find.text('เลือกบทบาทการใช้งาน'), findsOneWidget);
    expect(find.text('คุณครู (Teacher)'), findsOneWidget);
    expect(find.text('ผู้ดูแลโรงเรียน (School Admin)'), findsOneWidget);

    // Tap teacher role
    await tester.tap(find.text('คุณครู (Teacher)'));
    await tester.pumpAndSettle();

    expect(chosenUser?.role, UserRole.teacher);
  });
}
