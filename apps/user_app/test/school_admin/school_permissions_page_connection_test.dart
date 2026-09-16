import 'dart:async';

import 'dart:convert';

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
  Future<List<RolePermissionEntry>> Function()? loadPermissionMatrix,
  Future<StaffInvitationTicket> Function({required String email, required UserRole role})?
  createInvitation,
  void Function({required String filename, required List<int> bytes, required String mimeType})?
  downloadBytesOverride,
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
        loadPermissionMatrix:
            loadPermissionMatrix ?? () async => <RolePermissionEntry>[],
        createInvitation: createInvitation,
        downloadBytesOverride: downloadBytesOverride ??
            ({required filename, required bytes, required mimeType}) {},
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
    '"เชิญผู้ใช้งาน" creates a real invitation and shows the one-time token',
    (tester) async {
      String? sentEmail;
      UserRole? sentRole;
      await _pump(
        tester,
        createInvitation: ({required email, required role}) async {
          sentEmail = email;
          sentRole = role;
          return StaffInvitationTicket(token: 'inv_xyz789', expiresAt: DateTime(2026, 9, 21, 12));
        },
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('เชิญผู้ใช้งาน'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'อีเมลผู้ถูกเชิญ'), 'New.Teacher@school.test');
      await tester.tap(find.text('สร้างคำเชิญ'));
      await tester.pumpAndSettle();

      expect(sentEmail, 'new.teacher@school.test');
      expect(sentRole, UserRole.teacher);
      expect(find.text('inv_xyz789'), findsOneWidget, reason: 'token shown once to relay by hand');
      expect(find.text('เพิ่มสิทธิ์ผู้ใช้งานเรียบร้อยแล้ว'), findsNothing);
    },
  );

  testWidgets(
    '"ส่งออก CSV" downloads the filtered permission list as a real file',
    (tester) async {
      String? savedName;
      List<int>? savedBytes;
      await _pump(
        tester,
        loadUsers: () async => [_user(name: 'ครูส่งออก ทดสอบ', email: 'export@school.test')],
        downloadBytesOverride: ({required filename, required bytes, required mimeType}) {
          savedName = filename;
          savedBytes = bytes;
        },
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('ส่งออก CSV'));
      await tester.pumpAndSettle();

      expect(savedName, startsWith('permissions_'));
      expect(utf8.decode(savedBytes!), contains('export@school.test'));
      expect(find.text('ส่งออกรายการสิทธิ์ตัวอย่างแล้ว'), findsNothing);
    },
  );

  // The permission matrix used to be 7 fully hand-written "modules" with a
  // column for "ครูประจำอาคาร" — a role merged away on 2026-08-25 (see
  // CLAUDE.md). It now renders whatever list_role_permission_matrix
  // actually reports for each RPC, scanned live from the RPC's own body.
  testWidgets(
    'the permission matrix shows a real function and its real roles, never the old fake modules',
    (tester) async {
      await _pump(
        tester,
        loadPermissionMatrix: () async => const [
          RolePermissionEntry(
            functionName: 'create_course',
            allowedRoles: ['teacher', 'school_admin'],
          ),
          RolePermissionEntry(
            functionName: '_assert_school_admin',
            allowedRoles: null,
          ),
        ],
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('ตารางสิทธิ์ตามบทบาท'));
      await tester.pumpAndSettle();

      expect(find.text('create_course'), findsOneWidget);
      expect(find.text('ครู'), findsOneWidget);
      // Also appears on this tab's real role-overview card (same label,
      // shared_core's UserRole.schoolAdmin.label) — at least one is enough.
      expect(find.text('แอดมินโรงเรียน'), findsWidgets);

      // The old fake matrix's fabricated content must never appear again.
      expect(find.text('ข้อมูลนักเรียน'), findsNothing);
      expect(find.text('ครูประจำอาคาร'), findsNothing);
      expect(find.text('เฉพาะที่สอน'), findsNothing);

      // A function with no scannable role-check pattern says so honestly.
      expect(find.text('_assert_school_admin'), findsOneWidget);
      expect(
        find.text('ไม่พบรูปแบบการตรวจสิทธิ์ที่สแกนได้อัตโนมัติ'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'the role filter dropdown only offers real roles, never the old fake labels',
    (tester) async {
      await _pump(
        tester,
        loadUsers: () async => [
          _user(role: UserRole.teacher),
          _user(uid: 'u-2', role: UserRole.executive),
        ],
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('ทุกบทบาท'));
      await tester.pumpAndSettle();

      // Real UserRole.label values for the roles actually present.
      expect(find.text(UserRole.teacher.label), findsWidgets);
      expect(find.text(UserRole.executive.label), findsWidgets);

      // The old fake labels never matched anything and must never appear.
      expect(find.text('ครูผู้สอน'), findsNothing);
      expect(find.text('ครูประจำอาคาร'), findsNothing);
      expect(find.text('ฝ่ายบริหาร'), findsNothing);
    },
  );

  testWidgets(
    'selecting a real role filters the user list correctly',
    (tester) async {
      await _pump(
        tester,
        loadUsers: () async => [
          _user(uid: 'u-teacher', name: 'ครูเอ', role: UserRole.teacher),
          _user(uid: 'u-exec', name: 'ผู้บริหารบี', role: UserRole.executive),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('ครูเอ'), findsOneWidget);
      expect(find.text('ผู้บริหารบี'), findsOneWidget);

      await tester.tap(find.text('ทุกบทบาท'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(UserRole.executive.label).last);
      await tester.pumpAndSettle();

      expect(find.text('ผู้บริหารบี'), findsOneWidget);
      expect(find.text('ครูเอ'), findsNothing);
    },
  );

  testWidgets(
    'the user detail sheet shows real permissions from the matrix, never the old fabricated bullets',
    (tester) async {
      await _pump(
        tester,
        loadUsers: () async => [_user(role: UserRole.teacher)],
        loadPermissionMatrix: () async => const [
          RolePermissionEntry(
            functionName: 'create_course',
            allowedRoles: ['teacher'],
          ),
          RolePermissionEntry(
            functionName: 'archive_school_device',
            allowedRoles: ['school_admin'],
          ),
        ],
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('ครู สมศรี'));
      await tester.pumpAndSettle();

      expect(find.text('create_course'), findsOneWidget);
      expect(find.text('archive_school_device'), findsNothing);
      expect(find.textContaining('จากตารางสิทธิ์จริง'), findsOneWidget);

      // None of the old invented bullet text must ever appear again.
      expect(find.text('ดูชั้นเรียนที่รับผิดชอบ'), findsNothing);
      expect(find.text('ดูอาคารและห้องในพื้นที่รับผิดชอบ'), findsNothing);
    },
  );

  testWidgets(
    'searching the matrix filters to matching function names',
    (tester) async {
      await _pump(
        tester,
        loadPermissionMatrix: () async => const [
          RolePermissionEntry(
            functionName: 'create_course',
            allowedRoles: ['teacher'],
          ),
          RolePermissionEntry(
            functionName: 'list_school_alerts',
            allowedRoles: ['school_admin'],
          ),
        ],
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('ตารางสิทธิ์ตามบทบาท'));
      await tester.pumpAndSettle();

      expect(find.text('create_course'), findsOneWidget);
      expect(find.text('list_school_alerts'), findsOneWidget);

      await tester.enterText(find.byType(TextField).last, 'alerts');
      await tester.pumpAndSettle();

      expect(find.text('create_course'), findsNothing);
      expect(find.text('list_school_alerts'), findsOneWidget);
    },
  );
}
