import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/executive_redesign_prototype/pages/director_settings_page.dart';
import 'package:my_first_app/widgets/change_password_dialog.dart';
import 'package:shared_core/shared_core.dart';

/// This page did not import `shared_core` at all — it could not reach the
/// backend even in principle — yet it presented itself as a working settings
/// screen with a save button.
///
/// `_saveSettings()` set `hasChanges = false` and announced
/// "บันทึกการตั้งค่าของผู้อำนวยการแล้ว" without calling anything, so every
/// toggle reverted the next time the page opened. A director who switched off
/// emergency notifications was told it was saved and kept receiving them. The
/// password dialog collected current/new/confirm and answered
/// "เปลี่ยนรหัสผ่านเรียบร้อยแล้ว" while the password never changed. The
/// sign-out-all dialog said every other device had been signed out while every
/// session stayed live. The 2FA switch rendered OFF and could be toggled,
/// though `auth_sign_in` requires MFA for `executive` on every sign-in.
///
/// The account fields were seeded with 'ผู้อำนวยการโรงเรียน',
/// 'director@school.ac.th' and 'โรงเรียนตัวอย่าง', so every director saw the
/// same fictional account.

Future<void> _pump(
  WidgetTester tester, {
  PasswordChanger? changePassword,
}) async {
  tester.view.physicalSize = const Size(1500, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: DirectorSettingsPage(changePassword: changePassword),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    currentUserModel = const UserModel(
      uid: 'dir-1',
      name: 'สมศรี ทดสอบ',
      email: 'director.real@aiot-school-lab.local',
      role: UserRole.executive,
      schoolId: 'school-1',
    );
  });

  tearDown(() => currentUserModel = null);

  testWidgets('shows the signed-in account, not a fictional one', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('director.real@aiot-school-lab.local'), findsOneWidget);
    for (final invented in <String>[
      'director@school.ac.th',
      'โรงเรียนตัวอย่าง',
      '08X-XXX-XXXX',
    ]) {
      expect(
        find.textContaining(invented),
        findsNothing,
        reason: 'ยังพบของที่แต่งขึ้น: $invented',
      );
    }
  });

  testWidgets('the name field is seeded from the real session', (tester) async {
    await _pump(tester);

    final field = tester.widget<TextField>(find.byType(TextField).first);
    expect(field.controller?.text, 'สมศรี ทดสอบ');
    expect(find.textContaining('ผู้อำนวยการโรงเรียน'), findsNothing);
  });

  testWidgets('nothing without storage is offered — no phone field, no photo button, no dead tabs', (
    tester,
  ) async {
    await _pump(tester);

    // `users` has no phone/avatar column; there is no per-user preference
    // table, report generator or digest mailer. All of those used to be on
    // screen as "ยังไม่รองรับ"/"ยังไม่เปิดใช้งาน" placeholders.
    expect(find.text('ยังไม่รองรับ'), findsNothing);
    expect(find.text('เปลี่ยนรูป'), findsNothing);
    for (final tab in ['การแจ้งเตือน', 'การแสดงผล', 'รายงาน']) {
      expect(find.text(tab), findsNothing, reason: tab);
    }
    expect(find.text('ยังไม่เปิดใช้งาน'), findsNothing);
    expect(find.byType(Switch), findsNothing);
    // What is left is real: profile + security.
    expect(find.text('บัญชีส่วนตัว'), findsWidgets);
    expect(find.text('ความปลอดภัย'), findsWidgets);
  });

  testWidgets('2FA is reported as enforced, not offered as a switch', (
    tester,
  ) async {
    await _pump(tester);

    await tester.tap(find.text('ความปลอดภัย'));
    await tester.pumpAndSettle();

    expect(find.text('เปิดใช้งานอยู่'), findsOneWidget);
    expect(find.textContaining('บังคับใช้กับบัญชีผู้บริหาร'), findsOneWidget);
    // The login-alert tile ("ยังไม่เปิดใช้งาน") is gone — nothing sends one.
    expect(find.text('แจ้งเตือนเมื่อมีการเข้าสู่ระบบ'), findsNothing);
    expect(find.text('ยังไม่เปิดใช้งาน'), findsNothing);
  });

  testWidgets('save is disabled until the name actually changes', (
    tester,
  ) async {
    await _pump(tester);

    // `FilledButton.icon` builds a private subclass, so match the supertype.
    ButtonStyleButton saveButton() => tester.widget<ButtonStyleButton>(
      find
          .ancestor(
            of: find.text('บันทึกชื่อที่แสดง'),
            matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
          )
          .first,
    );

    expect(find.text('บันทึกชื่อที่แสดง'), findsOneWidget);
    expect(
      saveButton().onPressed,
      isNull,
      reason: 'ยังไม่ได้แก้อะไร ปุ่มบันทึกต้องกดไม่ได้',
    );
    // The old copy claimed the page's settings were saved on first open.
    expect(find.text('การตั้งค่าปัจจุบันถูกบันทึกแล้ว'), findsNothing);

    await tester.enterText(find.byType(TextField).first, 'สมศรี แก้ไขแล้ว');
    await tester.pump();
    expect(saveButton().onPressed, isNotNull);
  });

  testWidgets('the password dialog calls change_my_password and reports success only then', (
    tester,
  ) async {
    String? sentCurrent, sentNext;
    await _pump(
      tester,
      changePassword: ({required currentPassword, required newPassword}) async {
        sentCurrent = currentPassword;
        sentNext = newPassword;
      },
    );

    await tester.tap(find.text('ความปลอดภัย'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('เปลี่ยนรหัส').first);
    await tester.pumpAndSettle();

    expect(find.textContaining('ต้องยืนยันผ่านรหัส OTP'), findsNothing);
    await tester.enterText(
      find.widgetWithText(TextField, 'รหัสผ่านปัจจุบัน'),
      'Test1234!',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'รหัสผ่านใหม่ (อย่างน้อย 8 ตัว)'),
      'NewPass9!',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'ยืนยันรหัสผ่านใหม่'),
      'NewPass9!',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'เปลี่ยนรหัสผ่าน'));
    await tester.pumpAndSettle();

    expect(sentCurrent, 'Test1234!');
    expect(sentNext, 'NewPass9!');
    expect(find.textContaining('เปลี่ยนรหัสผ่านแล้ว'), findsOneWidget);
  });

  testWidgets('a wrong current password is reported, never claimed as changed', (
    tester,
  ) async {
    await _pump(
      tester,
      changePassword: ({required currentPassword, required newPassword}) async =>
          throw StateError('wrong_current_password'),
    );
    await tester.tap(find.text('ความปลอดภัย'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('เปลี่ยนรหัส').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'รหัสผ่านปัจจุบัน'), 'x');
    await tester.enterText(
      find.widgetWithText(TextField, 'รหัสผ่านใหม่ (อย่างน้อย 8 ตัว)'),
      'NewPass9!',
    );
    await tester.enterText(find.widgetWithText(TextField, 'ยืนยันรหัสผ่านใหม่'), 'NewPass9!');
    await tester.tap(find.widgetWithText(FilledButton, 'เปลี่ยนรหัสผ่าน'));
    await tester.pumpAndSettle();

    expect(find.text('รหัสผ่านปัจจุบันไม่ถูกต้อง'), findsOneWidget);
    expect(find.textContaining('เปลี่ยนรหัสผ่านแล้ว'), findsNothing);
  });
}
