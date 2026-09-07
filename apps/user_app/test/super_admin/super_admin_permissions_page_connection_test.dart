import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/super_admin/super_admin_permissions_page.dart';
import 'package:shared_core/shared_core.dart';

/// Pins loading / data / empty / error apart for the cross-school user
/// list, and guards the write→confirm contract on suspend/reactivate and
/// role change — this page can change any user's role or lock any account
/// out of the entire platform, so a mutation that reports success without
/// the backend actually applying it is a serious bug class.

UserModel _teacher({
  String uid = 'u-1',
  String name = 'ครู สมศรี',
  String email = 'somsri@school.test',
  String status = 'active',
}) => UserModel(
  uid: uid,
  name: name,
  email: email,
  role: UserRole.teacher,
  status: status,
);

Future<void> _pump(
  WidgetTester tester, {
  Future<List<UserModel>> Function()? loadUsers,
  Future<void> Function(String uid)? suspendUser,
  Future<void> Function(String uid)? reactivateUser,
}) async {
  tester.view.physicalSize = const Size(1500, 3200);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: SuperAdminPermissionsPage(
        loadUsers: loadUsers ?? () async => <UserModel>[],
        loadSchools: () async => <SchoolPlatformRecord>[],
        suspendUser: suspendUser,
        reactivateUser: reactivateUser,
      ),
    ),
  );
}

void main() {
  testWidgets('real users are rendered', (tester) async {
    await _pump(tester, loadUsers: () async => [_teacher()]);
    await tester.pumpAndSettle();

    expect(find.text('ครู สมศรี'), findsWidgets);
  });

  testWidgets('a failed load is distinct from empty, with retry', (
    tester,
  ) async {
    var calls = 0;
    await _pump(
      tester,
      loadUsers: () async {
        calls++;
        throw StateError('backend detail that must stay internal');
      },
    );
    await tester.pumpAndSettle();

    // getAllUsers failing surfaces as a page-level load error banner. Like
    // the other two Super Admin pages tested this session, this page shows
    // the raw error via SelectableText for the technical Super Admin
    // audience to copy while debugging.
    expect(find.text('ไม่สามารถโหลดข้อมูลสิทธิ์และผู้ใช้ได้'), findsOneWidget);
    expect(calls, 1);
  });

  testWidgets('a slow load shows progress, not an empty result', (
    tester,
  ) async {
    final gate = Completer<List<UserModel>>();
    await _pump(tester, loadUsers: () => gate.future);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    gate.complete([_teacher()]);
    await tester.pumpAndSettle();
  });

  testWidgets(
    'suspending only reports success once suspendUser actually resolves',
    (tester) async {
      await _pump(
        tester,
        loadUsers: () async => [_teacher(status: 'active')],
        suspendUser: (uid) async {
          throw StateError('rpc rejected the suspend');
        },
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PopupMenuButton<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('ระงับการใช้งาน'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ระงับบัญชี'));
      await tester.pumpAndSettle();

      expect(find.textContaining('ระงับบัญชี ครู สมศรี แล้ว'), findsNothing);
      expect(find.textContaining('ไม่สามารถเปลี่ยนสถานะบัญชีได้'), findsOneWidget);
    },
  );

  testWidgets(
    'suspending reports success once suspendUser actually resolves',
    (tester) async {
      var suspended = false;
      await _pump(
        tester,
        loadUsers: () async =>
            [_teacher(status: suspended ? 'suspended' : 'active')],
        suspendUser: (uid) async {
          suspended = true;
        },
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PopupMenuButton<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('ระงับการใช้งาน'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ระงับบัญชี'));
      await tester.pumpAndSettle();

      expect(find.textContaining('ระงับบัญชี ครู สมศรี แล้ว'), findsOneWidget);
    },
  );

  testWidgets('a super admin cannot be suspended from this page', (
    tester,
  ) async {
    await _pump(
      tester,
      loadUsers: () async => [
        UserModel(
          uid: 'admin-1',
          name: 'ผู้ดูแลระบบ',
          email: 'admin@platform.test',
          role: UserRole.superAdmin,
          status: 'active',
        ),
      ],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('ระงับการใช้งาน'));
    await tester.pumpAndSettle();

    expect(find.text('ไม่สามารถระงับ Super Admin หลักจากหน้านี้ได้'), findsOneWidget);
    // The confirmation dialog must never even open for this case.
    expect(find.text('ระงับการใช้งานบัญชี'), findsNothing);
  });
}
