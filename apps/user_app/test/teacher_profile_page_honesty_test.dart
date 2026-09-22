import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/teacher_redesign_prototype/teacher_profile_page.dart';
import 'package:shared_core/shared_core.dart';

Future<void> _pump(
  WidgetTester tester, {
  Future<List<CourseSummary>> Function()? loadCourses,
  Future<List<TermOption>> Function()? loadTerms,
  Future<List<AiotLabDeviceItem>> Function()? loadDevices,
  Future<List<CourseStudent>> Function(String)? loadCourseStudents,
  Future<void> Function(String)? updateName,
  Future<void> Function({
    required String currentPassword,
    required String newPassword,
  })?
  changePassword,
}) async {
  tester.view.physicalSize = const Size(1400, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: TeacherProfilePage(
        loadCourses: loadCourses ?? () async => const [],
        loadTerms: loadTerms ?? () async => const [],
        loadDevices: loadDevices ?? () async => const [],
        loadCourseStudents: loadCourseStudents ?? (_) async => const [],
        updateName: updateName,
        changePassword: changePassword,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    currentUserModel = const UserModel(
      uid: 'teacher-1',
      email: 'teacher@aiot-school-lab.local',
      name: 'ครูทดสอบ ระบบ',
      role: UserRole.teacher,
      schoolId: 'school-1',
    );
  });
  tearDown(() => currentUserModel = null);

  testWidgets(
    'a teacher with no real courses/devices never sees the old fabricated stats',
    (tester) async {
      await _pump(tester);

      // The old bug fabricated a name, subjects, classroom size, and 2
      // hardware devices with fake MAC addresses whenever real data was
      // empty/unavailable — none of that may render again.
      expect(find.text('ครูสมชาย สายวิทย์'), findsNothing);
      expect(find.textContaining('ฟิสิกส์ประยุกต์'), findsNothing);
      expect(find.textContaining('ม.5/2 · 32 คน'), findsNothing);
      expect(find.textContaining('AA:BB:CC:DD:EE:01'), findsNothing);
      expect(find.textContaining('โรงเรียนสาธิต AIoT'), findsNothing);
      expect(find.text('ยังไม่มีวิชาที่สอน'), findsOneWidget);
      expect(
        find.text('ยังไม่มีอุปกรณ์แล็บ AIoT ที่ผูกกับบัญชีนี้'),
        findsOneWidget,
      );
    },
  );

  testWidgets('no placeholder tile is left — only actions with a backend', (
    tester,
  ) async {
    await _pump(tester);
    for (final gone in [
      'เคล็ดลับการใช้งาน',
      'คำถามที่พบบ่อย',
      'ติดต่อทีมงาน',
      'การแจ้งเตือน',
      'ซิงก์ข้อมูลออฟไลน์ & ล้างแคช',
      'ความเป็นส่วนตัวและ PDPA',
    ]) {
      expect(find.text(gone), findsNothing, reason: gone);
    }
    expect(find.textContaining('ยังไม่เปิดใช้งาน'), findsNothing);
    expect(find.text('แก้ไขชื่อที่แสดง'), findsOneWidget);
    expect(find.text('เปลี่ยนรหัสผ่าน'), findsOneWidget);
    expect(find.text('ออกจากระบบ'), findsWidgets);
  });

  testWidgets('a failed read is an error, not an empty-but-healthy profile', (
    tester,
  ) async {
    await _pump(
      tester,
      loadCourses: () async => throw StateError('backend-secret'),
    );
    // Before: `.catchError((_) => [])` per call turned this into
    // "ยังไม่มีวิชาที่สอน" with zero students — indistinguishable from a
    // teacher who really has none.
    expect(find.text('ยังไม่มีวิชาที่สอน'), findsNothing);
    expect(find.textContaining('backend-secret'), findsNothing);
    expect(find.textContaining('ไม่สำเร็จ'), findsWidgets);
  });

  testWidgets(
    'editing the display name calls update_user_profile with the typed name',
    (tester) async {
      String? sent;
      await _pump(tester, updateName: (n) async => sent = n);
      await tester.tap(find.text('แก้ไขชื่อที่แสดง'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'ชื่อ-นามสกุล'),
        'ครูใหม่ นามสกุลใหม่',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'บันทึก'));
      await tester.pumpAndSettle();
      expect(sent, 'ครูใหม่ นามสกุลใหม่');
      expect(find.text('บันทึกชื่อแล้ว'), findsOneWidget);
    },
  );

  testWidgets('a failed name save is reported and never claimed as saved', (
    tester,
  ) async {
    await _pump(tester, updateName: (_) async => throw StateError('nope'));
    await tester.tap(find.text('แก้ไขชื่อที่แสดง'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'ชื่อ-นามสกุล'),
      'x y',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'บันทึก'));
    await tester.pumpAndSettle();
    expect(
      find.text('บันทึกชื่อไม่สำเร็จ กรุณาลองใหม่อีกครั้ง'),
      findsOneWidget,
    );
    expect(find.text('บันทึกชื่อแล้ว'), findsNothing);
    expect(find.textContaining('nope'), findsNothing);
  });

  testWidgets('the password tile opens the real change_my_password dialog', (
    tester,
  ) async {
    String? current, next;
    await _pump(
      tester,
      changePassword: ({required currentPassword, required newPassword}) async {
        current = currentPassword;
        next = newPassword;
      },
    );
    await tester.tap(find.text('เปลี่ยนรหัสผ่าน'));
    await tester.pumpAndSettle();
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
    expect(current, 'Test1234!');
    expect(next, 'NewPass9!');
    expect(find.textContaining('เปลี่ยนรหัสผ่านแล้ว'), findsOneWidget);
  });
}
