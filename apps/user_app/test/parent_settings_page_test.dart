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
}) => MaterialApp(
  routes: {'/login': (_) => const Scaffold(body: Text('หน้าเข้าสู่ระบบ'))},
  home: ParentSettingsPage(
    studentsLoader: loader,
    userProvider: () => _user,
    profileUpdater: updater ?? (uid, name) async {},
    signOut: () async {},
    onSignedOut: () {},
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
    expect(find.text('ยังไม่มีนักเรียนที่เชื่อมกับบัญชีนี้'), findsOneWidget);
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
}
