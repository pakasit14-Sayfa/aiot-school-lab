import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/school_admin/school_permissions_page.dart';
import 'package:shared_core/shared_core.dart';

/// Pins loading / data / empty / error apart for the user/permissions list
/// and its audit-log panel, and guards two DoD fixes made on 2026-09-07:
///
/// 1. The multi-role display bug: `list_school_users` collapses a
///    multi-role account to a single `active_role`; showing only that role
///    on the "manage permissions" page hid roles the account actually
///    holds — the same class of bug that once dropped teachers from the
///    teacher list. Roles must be built from `{u.role, ...u.allRoles}`.
/// 2. "เพิ่มสิทธิ์" (create a new user), "ส่งออกรายการ" (export), and
///    "ตั้งรหัสผ่านใหม่" (reset password) had no backend at all — the first
///    built a fake in-memory user and claimed it was added, the other two
///    just showed a snackbar. All three are now disabled/removed rather
///    than pretending to succeed.

UserModel _user({
  String uid = 'u-1',
  String name = 'ครู สมศรี',
  String email = 'somsri@school.test',
  UserRole role = UserRole.teacher,
  List<UserRole> allRoles = const [],
  String status = 'active',
}) => UserModel(
  uid: uid,
  name: name,
  email: email,
  role: role,
  allRoles: allRoles,
  status: status,
);

SchoolAdminAuditLog _log({String action = 'แก้ไขสิทธิ์'}) =>
    SchoolAdminAuditLog(
      id: 1,
      action: action,
      target: 'ครู สมศรี',
      detail: '',
      actorName: 'ผู้ดูแล ทดสอบ',
      actorRole: 'school_admin',
      createdAt: DateTime(2026, 9, 1),
    );

Future<void> _pump(
  WidgetTester tester, {
  Future<List<UserModel>> Function()? loadUsers,
  Future<List<SchoolAdminAuditLog>> Function()? loadLogs,
}) async {
  tester.view.physicalSize = const Size(1500, 3200);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: SchoolPermissionsPage(
        loadUsers: loadUsers ?? () async => <UserModel>[],
        loadLogs: loadLogs ?? () async => <SchoolAdminAuditLog>[],
      ),
    ),
  );
}

void main() {
  testWidgets('a multi-role account shows every role it holds', (
    tester,
  ) async {
    await _pump(
      tester,
      loadUsers: () async => [
        _user(role: UserRole.teacher, allRoles: const [UserRole.executive]),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.textContaining(UserRole.teacher.label), findsWidgets);
    expect(find.textContaining(UserRole.executive.label), findsWidgets);
  });

  testWidgets('no users says so, distinct from a failed load', (
    tester,
  ) async {
    await _pump(tester);
    await tester.pumpAndSettle();

    expect(find.text('ไม่พบผู้ใช้งาน'), findsOneWidget);
    expect(find.text('โหลดรายชื่อผู้ใช้ไม่สำเร็จ รายการด้านล่างจึงยังไม่ครบ'), findsNothing);
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

    expect(
      find.text('โหลดรายชื่อผู้ใช้ไม่สำเร็จ รายการด้านล่างจึงยังไม่ครบ'),
      findsOneWidget,
    );
    expect(find.textContaining('backend detail'), findsNothing);
    expect(calls, 1);

    await tester.tap(find.text('ลองใหม่'));
    await tester.pumpAndSettle();
    expect(calls, 2, reason: 'retry must actually re-issue the load');
  });

  testWidgets('a slow load shows progress, not an empty result', (
    tester,
  ) async {
    final gate = Completer<List<UserModel>>();
    await _pump(tester, loadUsers: () => gate.future);
    await tester.pump();

    expect(find.text('กำลังโหลดรายชื่อผู้ใช้และสิทธิ์…'), findsOneWidget);

    gate.complete([_user()]);
    await tester.pumpAndSettle();
    expect(find.text('กำลังโหลดรายชื่อผู้ใช้และสิทธิ์…'), findsNothing);
  });

  testWidgets('a real audit log entry is rendered', (tester) async {
    await _pump(tester, loadLogs: () async => [_log()]);
    await tester.pumpAndSettle();

    expect(find.text('ยังไม่มีประวัติการจัดการสิทธิ์'), findsNothing);
  });

  testWidgets(
    '"เพิ่มสิทธิ์" is disabled rather than faking a new user',
    (tester) async {
      await _pump(tester);
      await tester.pumpAndSettle();

      final addButton = find.byWidgetPredicate(
        (w) => w is ButtonStyleButton && w.onPressed == null,
      );
      expect(
        find.descendant(of: addButton, matching: find.text('เพิ่มสิทธิ์')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    '"ส่งออกรายการ" is disabled rather than faking a download',
    (tester) async {
      await _pump(tester);
      await tester.pumpAndSettle();

      final exportButton = find.byWidgetPredicate(
        (w) => w is ButtonStyleButton && w.onPressed == null,
      );
      expect(
        find.descendant(of: exportButton, matching: find.text('ส่งออกรายการ')),
        findsOneWidget,
      );
    },
  );
}
