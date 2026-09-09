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
  Future<List<RolePermissionEntry>> Function()? loadPermissionMatrix,
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
        // ตารางสิทธิ์เป็นข้อมูลหลักของหน้านี้เหมือน user list — โหลดไม่ได้ =
        // ทั้งหน้าขึ้น error ไม่ใช่แอบโชว์ตารางเปล่าเหมือนไม่มีสิทธิ์เลย
        loadPermissionMatrix:
            loadPermissionMatrix ?? () async => <RolePermissionEntry>[],
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

  /// เมทริกซ์สิทธิ์ของหน้านี้เคยเป็นตาราง 8 ช่องที่พิมพ์มือไว้ในไฟล์เพจเอง
  /// (ดูภาพรวม/โรงเรียน/อุปกรณ์/ควบคุม/ผู้ใช้/Log/รายงาน/Support) ซึ่งไม่ได้
  /// ผูกกับ RBAC จริงเลย — หน้า School Admin ย้ายไปใช้ RPC
  /// `list_role_permission_matrix` จริงแล้วใน `873dbc2` เทสต์ชุดนี้ล็อกไว้ว่า
  /// ฝั่ง Super Admin ก็อ่านของจริงเหมือนกัน
  group('ตารางสิทธิ์ตามบทบาท', () {
    testWidgets('แสดงจำนวนฟังก์ชันจริงต่อบทบาท ไม่ใช่ตารางที่พิมพ์มือ', (
      tester,
    ) async {
      await _pump(
        tester,
        loadPermissionMatrix: () async => const <RolePermissionEntry>[
          RolePermissionEntry(
            functionName: 'list_schools_for_super_admin',
            allowedRoles: <String>['super_admin'],
          ),
          RolePermissionEntry(
            functionName: 'list_school_users',
            allowedRoles: <String>['super_admin', 'school_admin'],
          ),
          RolePermissionEntry(
            functionName: 'list_my_courses',
            allowedRoles: <String>['teacher'],
          ),
          // allowedRoles = null คือฟังก์ชันที่สแกนรูปแบบสิทธิ์ไม่ได้ ต้องไม่
          // ถูกนับให้บทบาทไหนเลย ไม่ใช่เดาว่าใครเข้าถึงได้
          RolePermissionEntry(
            functionName: 'some_unscannable_function',
            allowedRoles: null,
          ),
        ],
      );
      await tester.pumpAndSettle();

      // หัวข้อบอกจำนวนฟังก์ชันจริงที่อ่านมาได้
      expect(
        find.textContaining('จากฐานข้อมูลจริง 4 ฟังก์ชัน'),
        findsOneWidget,
      );

      // คอลัมน์ 8 ช่องที่แต่งขึ้นต้องไม่เหลืออยู่
      expect(find.text('Support'), findsNothing);
      expect(find.text('ควบคุม'), findsNothing);

      // super_admin เรียกได้ 2 ตัว, teacher 1 ตัว, parent 0 ตัว
      expect(find.text('2 รายการ'), findsOneWidget);
      // school_admin (list_school_users) และ teacher (list_my_courses) ได้คนละ 1
      expect(find.text('1 รายการ'), findsNWidgets(2));
      expect(find.text('0 รายการ'), findsWidgets);
      expect(find.textContaining('list_schools_for_super_admin'), findsWidgets);
      // ฟังก์ชันที่สแกนไม่ได้ต้องไม่ถูกยกให้บทบาทใด
      expect(find.textContaining('some_unscannable_function'), findsNothing);
    });

    testWidgets('ตารางสิทธิ์ว่างต้องบอกตรง ๆ ไม่ใช่โชว์ตารางที่พิมพ์มือแทน', (
      tester,
    ) async {
      await _pump(tester);
      await tester.pumpAndSettle();

      expect(find.text('ยังไม่มีข้อมูลตารางสิทธิ์'), findsWidgets);
      expect(find.text('Support'), findsNothing);
    });
  });
}
