import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/executive_redesign_prototype/pages/director_settings_page.dart';
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

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1500, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    const MaterialApp(home: Scaffold(body: DirectorSettingsPage())),
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

  testWidgets('phone has nowhere to be stored and says so', (tester) async {
    await _pump(tester);

    expect(find.text('ยังไม่รองรับ'), findsOneWidget);
    expect(
      find.textContaining('ระบบยังไม่ได้เก็บเบอร์โทรศัพท์'),
      findsOneWidget,
    );
  });

  testWidgets('settings with no storage are disabled, not fake-saved', (
    tester,
  ) async {
    await _pump(tester);

    // Three whole sections (notifications, dashboard, reports) plus the
    // login-alert status badge.
    expect(find.text('ยังไม่เปิดใช้งาน'), findsNWidgets(4));
    for (final reason in <String>[
      'ระบบยังไม่มีที่เก็บการตั้งค่าการแจ้งเตือนรายบุคคล',
      'ระบบยังไม่มีที่เก็บการตั้งค่าส่วนตัวของผู้ใช้',
      'ระบบยังไม่มีตัวสร้างไฟล์รายงาน',
    ]) {
      expect(find.textContaining(reason), findsOneWidget, reason: reason);
    }
    // No switch is offered for a preference that cannot persist.
    expect(find.byType(Switch), findsNothing);
  });

  testWidgets('2FA is reported as enforced, not offered as a switch', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('เปิดใช้งานอยู่'), findsOneWidget);
    expect(find.textContaining('บังคับใช้กับบัญชีผู้บริหาร'), findsOneWidget);
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

  testWidgets('the password dialog no longer claims to change anything', (
    tester,
  ) async {
    await _pump(tester);

    await tester.tap(find.text('เปลี่ยนรหัส').first);
    await tester.pumpAndSettle();

    expect(find.textContaining('ต้องยืนยันผ่านรหัส OTP'), findsOneWidget);
    expect(find.text('เปลี่ยนรหัสผ่านเรียบร้อยแล้ว'), findsNothing);
    expect(find.widgetWithText(TextField, 'รหัสผ่านปัจจุบัน'), findsNothing);
  });
}
