import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/parent_redesign_prototype/pages/parent/parent_settings_page.dart';
import 'package:shared_core/shared_core.dart';

const _user = UserModel(
  uid: 'parent-1',
  name: 'ผู้ปกครอง ทดสอบ',
  email: 'parent@example.com',
  role: UserRole.parent,
  schoolId: 'school-1',
);

Widget _app({
  required ParentSettingsStudentsLoader loader,
  ParentProfileUpdater? updater,
  Future<void> Function({required String currentPassword, required String newPassword})?
  changePassword,
}) => MaterialApp(
  routes: {'/login': (_) => const Scaffold(body: Text('หน้าเข้าสู่ระบบ'))},
  home: ParentSettingsPage(
    studentsLoader: loader,
    userProvider: () => _user,
    profileUpdater: updater ?? (uid, name) async {},
    signOut: () async {},
    onSignedOut: () {},
    changePassword: changePassword,
  ),
);

void main() {
  testWidgets('shows real account and explicit no-linked-student state', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    await tester.pumpWidget(_app(loader: () async => const []));
    await tester.pumpAndSettle();

    expect(find.text('ผู้ปกครอง ทดสอบ'), findsOneWidget);
    expect(find.text('parent@example.com'), findsOneWidget);
    expect(find.text('ยังไม่ได้เชื่อมโยงนักเรียน'), findsOneWidget);
    expect(find.text('ยังไม่มีข้อมูล'), findsWidgets);
    expect(find.text('น้องมะลิ'), findsNothing);
  });

  testWidgets('keeps load failures distinct from empty data', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 800));
    await tester.pumpWidget(
      _app(loader: () async => throw Exception('network_error')),
    );
    await tester.pumpAndSettle();

    expect(find.text('ไม่สามารถโหลดข้อมูลได้'), findsOneWidget);
    expect(find.text('ลองอีกครั้ง'), findsOneWidget);
    expect(find.text('ยังไม่มีข้อมูล'), findsNothing);
  });

  testWidgets('renders linked students and persists profile name update', (
    tester,
  ) async {
    String? updatedUid;
    String? updatedName;
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    await tester.pumpWidget(
      _app(
        loader: () async => const [
          LinkedStudentItem(
            studentId: 'student-1',
            firstName: 'นักเรียน',
            lastName: 'ทดสอบ',
            schoolId: 'school-1',
            relationship: 'บุตร',
          ),
        ],
        updater: (uid, name) async {
          updatedUid = uid;
          updatedName = name;
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('นักเรียน ทดสอบ'), findsOneWidget);
    expect(find.text('บุตร'), findsOneWidget);
    await tester.tap(find.text('แก้ไขชื่อ'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'ผู้ปกครอง คนใหม่');
    await tester.tap(find.text('บันทึก'));
    await tester.pumpAndSettle();

    expect(updatedUid, 'parent-1');
    expect(updatedName, 'ผู้ปกครอง คนใหม่');
    expect(find.text('ผู้ปกครอง คนใหม่'), findsOneWidget);
    expect(find.text('บันทึกข้อมูลแล้ว'), findsOneWidget);
  });

  testWidgets('no API-less notification card; "เปลี่ยนรหัสผ่าน" is a real action', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    String? sentNew;
    await tester.pumpWidget(
      _app(
        loader: () async => const [],
        changePassword: ({required currentPassword, required newPassword}) async =>
            sentNew = newPassword,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('การตั้งค่าการแจ้งเตือน'), findsNothing);
    expect(find.textContaining('ยังไม่มี API'), findsNothing);

    await tester.tap(find.text('เปลี่ยนรหัสผ่าน'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'รหัสผ่านปัจจุบัน'), 'Test1234!');
    await tester.enterText(find.widgetWithText(TextField, 'รหัสผ่านใหม่ (อย่างน้อย 8 ตัว)'), 'NewPass9!');
    await tester.enterText(find.widgetWithText(TextField, 'ยืนยันรหัสผ่านใหม่'), 'NewPass9!');
    await tester.tap(find.widgetWithText(FilledButton, 'เปลี่ยนรหัสผ่าน'));
    await tester.pumpAndSettle();
    expect(sentNew, 'NewPass9!');
    expect(find.textContaining('เปลี่ยนรหัสผ่านแล้ว'), findsOneWidget);
  });
}
