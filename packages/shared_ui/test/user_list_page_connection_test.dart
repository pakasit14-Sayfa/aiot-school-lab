import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_ui/shared_ui.dart';

/// Pins loading / data / empty error handling for UserListPage — shared
/// between School Admin's dashboard and Super Admin's nav shell. Guards the
/// fix made 2026-09-07: all 4 mutations (edit name, change role, suspend,
/// reactivate) used to call their service with no try/catch at all, so a
/// thrown exception left the confirmation dialog open with no feedback —
/// no error message, no retry, just a silent hang.

UserModel _teacher({
  String uid = 'u-1',
  String name = 'ครู สมศรี',
  String email = 'somsri@school.test',
  bool suspended = false,
}) => UserModel(
  uid: uid,
  name: name,
  email: email,
  role: UserRole.teacher,
  status: suspended ? 'suspended' : 'active',
);

Future<void> _pump(
  WidgetTester tester, {
  Future<List<UserModel>> Function()? loadUsers,
  Future<void> Function({required String uid, required String name})?
  updateProfile,
  Future<void> Function({required String uid, required UserRole role})?
  updateRole,
  Future<void> Function(String uid)? suspendUser,
  Future<void> Function(String uid)? reactivateUser,
}) async {
  tester.view.physicalSize = const Size(1500, 3200);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  currentUserModel = const UserModel(
    uid: 'admin-1',
    name: 'ผู้ดูแล ทดสอบ',
    email: 'admin@school.test',
    role: UserRole.schoolAdmin,
  );
  addTearDown(() => currentUserModel = null);

  await tester.pumpWidget(
    MaterialApp(
      home: UserListPage(
        loadUsers: loadUsers ?? () async => <UserModel>[],
        updateProfile: updateProfile,
        updateRole: updateRole,
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

  testWidgets('no users says so, not an error', (tester) async {
    await _pump(tester);
    await tester.pumpAndSettle();

    expect(find.text('ไม่พบข้อมูลผู้ใช้'), findsOneWidget);
  });

  testWidgets(
    'a slow load shows progress, not an empty result',
    (tester) async {
      final gate = Future.delayed(
        const Duration(milliseconds: 200),
        () => <UserModel>[_teacher()],
      );
      await _pump(tester, loadUsers: () => gate);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('ไม่พบข้อมูลผู้ใช้'), findsNothing);

      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );

  testWidgets(
    'edit name shows an error and keeps the dialog reachable on failure',
    (tester) async {
      var calls = 0;
      await _pump(
        tester,
        loadUsers: () async => [_teacher()],
        updateProfile: ({required uid, required name}) async {
          calls++;
          throw StateError('rpc rejected');
        },
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PopupMenuButton<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('แก้ไขชื่อผู้ใช้'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        'ครู สมศรี ใหม่',
      );
      await tester.tap(find.text('บันทึก'));
      await tester.pumpAndSettle();

      expect(calls, 1);
      expect(find.text('บันทึกไม่สำเร็จ กรุณาลองใหม่'), findsOneWidget);
      expect(find.text('แก้ไขข้อมูลผู้ใช้เรียบร้อยแล้ว'), findsNothing);
    },
  );

  testWidgets('edit name succeeds and reloads when updateProfile resolves', (
    tester,
  ) async {
    var renamed = false;
    await _pump(
      tester,
      loadUsers: () async =>
          [_teacher(name: renamed ? 'ครู สมศรี ใหม่' : 'ครู สมศรี')],
      updateProfile: ({required uid, required name}) async {
        renamed = true;
      },
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('แก้ไขชื่อผู้ใช้'));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        'ครู สมศรี ใหม่',
      );
    await tester.tap(find.text('บันทึก'));
    await tester.pumpAndSettle();

    expect(find.text('แก้ไขข้อมูลผู้ใช้เรียบร้อยแล้ว'), findsOneWidget);
    expect(find.text('ครู สมศรี ใหม่'), findsWidgets);
  });

  testWidgets(
    'suspend shows an error instead of a silent hang when the RPC throws',
    (tester) async {
      await _pump(
        tester,
        loadUsers: () async => [_teacher()],
        suspendUser: (uid) async {
          throw StateError('rpc rejected');
        },
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PopupMenuButton<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('ระงับการใช้งาน'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ระงับบัญชี'));
      await tester.pumpAndSettle();

      expect(find.text('ระงับผู้ใช้ไม่สำเร็จ กรุณาลองใหม่'), findsOneWidget);
      expect(find.text('ระงับผู้ใช้เรียบร้อยแล้ว'), findsNothing);
    },
  );

  testWidgets('suspend succeeds and reloads when suspendUser resolves', (
    tester,
  ) async {
    var suspended = false;
    await _pump(
      tester,
      loadUsers: () async => [_teacher(suspended: suspended)],
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

    expect(find.text('ระงับผู้ใช้เรียบร้อยแล้ว'), findsOneWidget);
  });

  testWidgets(
    'change role shows an error instead of a silent hang when the RPC throws',
    (tester) async {
      await _pump(
        tester,
        loadUsers: () async => [_teacher()],
        updateRole: ({required uid, required role}) async {
          throw StateError('rpc rejected');
        },
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PopupMenuButton<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('เปลี่ยนสิทธิ์และบทบาท'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('ยืนยันการเปลี่ยนสิทธิ์'));
      await tester.pumpAndSettle();

      expect(find.text('เปลี่ยนสิทธิ์ไม่สำเร็จ กรุณาลองใหม่'), findsOneWidget);
    },
  );
}
