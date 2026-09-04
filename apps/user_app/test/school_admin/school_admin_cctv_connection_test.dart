import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/school_admin/controllers/school_admin_cctv_controller.dart';
import 'package:my_first_app/pages/school_admin/school_admin_cctv_page.dart';
import 'package:shared_core/shared_core.dart';

void main() {
  testWidgets('empty CCTV backend renders the required honest empty label', (
    tester,
  ) async {
    final controller = _controller(
      loadGrants: () async => const <CameraAccessGrantItem>[],
    );
    addTearDown(controller.dispose);

    await _pumpPage(tester, controller);

    expect(find.text('ยังไม่มีข้อมูล'), findsOneWidget);
    expect(find.text('ยังไม่มีรายการสิทธิ์กล้อง CCTV'), findsOneWidget);
  });

  testWidgets('CCTV load failure is visible and retryable', (tester) async {
    final controller = _controller(
      loadGrants: () async => throw StateError('offline'),
    );
    addTearDown(controller.dispose);

    await _pumpPage(tester, controller);

    expect(find.text('โหลดข้อมูลสิทธิ์กล้อง CCTV ไม่สำเร็จ'), findsOneWidget);
    expect(find.text('ลองใหม่'), findsOneWidget);
    expect(find.text('ยังไม่มีข้อมูล'), findsNothing);
  });

  testWidgets('grant failure never shows a success message', (tester) async {
    final controller = _controller(
      loadGrants: () async => const <CameraAccessGrantItem>[],
      grantAccess:
          ({
            required userId,
            cameraDeviceId,
            required reason,
            required validUntil,
          }) async => null,
    );
    addTearDown(controller.dispose);

    await _pumpPage(tester, controller);
    await tester.tap(find.text('อนุญาตสิทธิ์ใหม่'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'ตรวจสอบเหตุการณ์');
    await tester.tap(find.text('ยืนยันอนุญาตสิทธิ์'));
    await tester.pumpAndSettle();

    expect(find.text('บันทึกสิทธิ์กล้อง CCTV ไม่สำเร็จ'), findsWidgets);
    expect(
      find.text('บันทึกการอนุญาตสิทธิ์เข้าถึงกล้อง CCTV เรียบร้อยแล้ว'),
      findsNothing,
    );
  });
}

Future<void> _pumpPage(
  WidgetTester tester,
  SchoolAdminCctvController controller,
) async {
  tester.view.physicalSize = const Size(1200, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(home: SchoolAdminCctvPage(controller: controller)),
  );
  await tester.pumpAndSettle();
}

SchoolAdminCctvController _controller({
  required SchoolAdminCctvGrantsLoader loadGrants,
  SchoolAdminCctvGrantAccess? grantAccess,
}) {
  return SchoolAdminCctvController(
    loadGrants: loadGrants,
    loadUsers: () async => <UserModel>[_user()],
    grantAccess: grantAccess ?? _unusedGrant,
    revokeAccess: (_) async => true,
  );
}

Future<String?> _unusedGrant({
  required String userId,
  String? cameraDeviceId,
  required String reason,
  required DateTime validUntil,
}) async => 'unused';

UserModel _user() => const UserModel(
  uid: 'user-1',
  name: 'ครูทดสอบ',
  email: 'teacher@example.test',
  role: UserRole.teacher,
  schoolId: 'school-1',
);
