import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/school_admin/school_admin_profile_page.dart';
import 'package:shared_core/shared_core.dart';

/// Pins loading / data / empty / error apart for the audit-log panel
/// (the only part of this page that reads from a real RPC —
/// `list_school_admin_audit_logs`), and guards two things that used to be
/// wrong: every log row was hardcoded green ("success") even though
/// audit_logs has no outcome column, and the save button claimed
/// "บันทึกข้อมูลโปรไฟล์แล้ว" without writing anything.

SchoolAdminAuditLog _log({String action = 'เข้าสู่ระบบ'}) => SchoolAdminAuditLog(
  id: 1,
  action: action,
  target: '',
  detail: 'เข้าสู่ระบบสำเร็จ',
  actorName: 'ผู้ดูแล ทดสอบ',
  actorRole: 'school_admin',
  createdAt: DateTime(2026, 9, 1),
);

SchoolAdminDashboardSummary _summary({String schoolName = 'โรงเรียนทดสอบ'}) =>
    SchoolAdminDashboardSummary(
      schoolId: 'school-1',
      schoolName: schoolName,
      schoolCode: 'TEST-1',
      studentsCount: 0,
      teachersCount: 0,
      devicesCount: 0,
      devicesOnline: 0,
      buildingsCount: 0,
      roomsCount: 0,
      openAlertsCount: 0,
    );

Future<void> _pump(
  WidgetTester tester, {
  Future<List<SchoolAdminAuditLog>> Function()? loadLogs,
  Future<SchoolAdminDashboardSummary> Function()? loadSummary,
  Future<void> Function({required String uid, required String name})?
  updateProfile,
  Future<void> Function()? signOutAllDevices,
  Future<List<StaffDirectoryEntry>> Function()? loadDirectory,
  Future<void> Function({required String userId, String? positionTitle, String? phone})?
  saveStaffProfile,
  Future<void> Function({required String currentPassword, required String newPassword})?
  changePassword,
  Future<List<MySessionRecord>> Function()? loadSessions,
  Future<void> Function(String sessionId)? revokeSession,
}) async {
  tester.view.physicalSize = const Size(1400, 2600);
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
    schoolId: 'school-1',
  );
  addTearDown(() => currentUserModel = null);

  await tester.pumpWidget(
    MaterialApp(
      home: SchoolAdminProfilePage(
        loadLogs: loadLogs ?? () async => <SchoolAdminAuditLog>[],
        loadSummary: loadSummary ?? () async => _summary(),
        updateProfile: updateProfile,
        signOutAllDevices: signOutAllDevices,
        loadDirectory: loadDirectory ?? () async => const <StaffDirectoryEntry>[],
        saveStaffProfile: saveStaffProfile ??
            ({required userId, positionTitle, phone}) async {},
        changePassword: changePassword,
        loadSessions: loadSessions,
        revokeSession: revokeSession,
      ),
    ),
  );
}

void main() {
  /// สวิตช์แจ้งเตือน 3 ตัวเคย setState อย่างเดียว — ไม่มี RPC ไม่มีตารางเก็บ
  /// และไม่มีระบบส่งอีเมล/แจ้งเตือนความปลอดภัยที่อ่านค่านั้น ถูกปิดไว้ก่อน
  /// (2026-09-13) แล้วถอดออกทั้งส่วน (2026-09-14): ควบคุมที่ไม่มีผลอะไรเลย
  /// ไม่ควรอยู่บนหน้าจอ เทสต์นี้กันไม่ให้มันกลับมาโดยไม่มี backend
  testWidgets('no notification switches without a backend behind them', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.byType(Switch), findsNothing);
    expect(find.text('การแจ้งเตือนของฉัน'), findsNothing);
    expect(find.text('แจ้งเตือนทางอีเมล'), findsNothing);
  });

  testWidgets('no log history says so, not an error', (tester) async {
    await _pump(tester);
    await tester.pumpAndSettle();

    expect(find.text('ยังไม่มีข้อมูลประวัติกิจกรรม'), findsOneWidget);
    expect(find.text('โหลดประวัติไม่สำเร็จ'), findsNothing);
  });

  testWidgets('a failed log load is distinct from empty, with retry', (
    tester,
  ) async {
    var calls = 0;
    await _pump(
      tester,
      loadLogs: () async {
        calls++;
        throw StateError('backend detail that must stay internal');
      },
    );
    await tester.pumpAndSettle();

    expect(find.text('โหลดประวัติไม่สำเร็จ'), findsOneWidget);
    expect(find.text('ยังไม่มีข้อมูลประวัติกิจกรรม'), findsNothing);
    expect(find.textContaining('backend detail'), findsNothing);
    expect(calls, 1);

    await tester.tap(find.text('ลองใหม่'));
    await tester.pumpAndSettle();
    expect(calls, 2, reason: 'retry must actually re-issue the load');
  });

  testWidgets('a slow log load shows a spinner, not an empty result', (
    tester,
  ) async {
    final gate = Completer<List<SchoolAdminAuditLog>>();
    await _pump(tester, loadLogs: () => gate.future);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('ยังไม่มีข้อมูลประวัติกิจกรรม'), findsNothing);

    gate.complete([_log()]);
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('a real log entry is rendered without an invented success color', (
    tester,
  ) async {
    await _pump(tester, loadLogs: () async => [_log()]);
    await tester.pumpAndSettle();

    expect(find.text('เข้าสู่ระบบ'), findsOneWidget);
    expect(find.text('เข้าสู่ระบบสำเร็จ'), findsOneWidget);
  });

  testWidgets('saving only claims success once the write actually completes', (
    tester,
  ) async {
    await _pump(
      tester,
      updateProfile: ({required uid, required name}) async {
        throw StateError('write failed');
      },
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('บันทึก'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ยืนยัน'));
    await tester.pumpAndSettle();

    expect(find.text('บันทึกไม่สำเร็จ กรุณาลองใหม่'), findsOneWidget);
  });

  testWidgets('saving reports success once the write actually completes', (
    tester,
  ) async {
    var saved = false;
    String? savedPhone, savedPosition, savedFor;
    await _pump(
      tester,
      updateProfile: ({required uid, required name}) async {
        saved = true;
      },
      saveStaffProfile: ({required userId, positionTitle, phone}) async {
        savedFor = userId;
        savedPosition = positionTitle;
        savedPhone = phone;
      },
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'เบอร์โทรศัพท์'), '0812345678');
    await tester.enterText(find.widgetWithText(TextField, 'ตำแหน่ง'), 'รองผู้อำนวยการ');
    await tester.tap(find.text('บันทึก'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ยืนยัน'));
    await tester.pumpAndSettle();

    expect(saved, isTrue);
    // เบอร์โทร/ตำแหน่ง ลง staff_profiles ของบัญชีตัวเอง — ไม่ใช่ "ยังไม่รองรับ" อีกต่อไป
    expect(savedFor, 'admin-1');
    expect(savedPhone, '0812345678');
    expect(savedPosition, 'รองผู้อำนวยการ');
    expect(find.text('บันทึกโปรไฟล์เรียบร้อยแล้ว'), findsOneWidget);
  });

  testWidgets(
    'phone/position/department come from the staff directory, and no field claims to be unsaveable',
    (tester) async {
      await _pump(
        tester,
        loadDirectory: () async => const [
          StaffDirectoryEntry(
            userId: 'admin-1',
            fullName: 'ผู้ดูแล ทดสอบ',
            email: 'admin@school.test',
            status: 'active',
            positionTitle: 'หัวหน้างานทะเบียน',
            phone: '0899999999',
            roles: ['school_admin'],
            administrativeDepartments: ['ฝ่ายบริหารทั่วไป'],
            subjectGroups: [],
            headsDepartments: [],
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('ยังไม่รองรับการบันทึก'), findsNothing);
      expect(find.widgetWithText(TextField, '0899999999'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'หัวหน้างานทะเบียน'), findsOneWidget);
      expect(find.text('ฝ่ายบริหารทั่วไป'), findsOneWidget);
      // ไม่มีคอลัมน์ไหนเก็บรหัสบุคลากร — ช่องนั้นต้องไม่อยู่บนจอ
      expect(find.text('รหัสผู้ใช้งาน / รหัสบุคลากร'), findsNothing);
    },
  );

  testWidgets(
    'the real school name is rendered, and the old fake placeholder never appears',
    (tester) async {
      await _pump(
        tester,
        loadSummary: () async => _summary(schoolName: 'โรงเรียนจริงจากระบบ'),
      );
      await tester.pumpAndSettle();

      expect(find.text('โรงเรียนจริงจากระบบ'), findsWidgets);
      expect(find.text('โรงเรียนตัวอย่าง AIoT Smart Lab'), findsNothing);
      expect(find.text('AIoT Smart Lab • โรงเรียนตัวอย่าง'), findsNothing);
    },
  );

  testWidgets(
    'fields with no real data source say so, instead of showing an invented value',
    (tester) async {
      await _pump(tester);
      await tester.pumpAndSettle();

      // last-login time and the security-anomaly claim used to be
      // hardcoded ('09:20 น.' / 'ไม่พบการเข้าสู่ระบบผิดปกติ') regardless of
      // what actually happened on this account — neither is backed by any
      // RPC, so both must say so honestly now.
      expect(find.text('ยังไม่มีข้อมูล'), findsWidgets);
      expect(find.text('09:20 น.'), findsNothing);
      expect(find.text('ไม่พบการเข้าสู่ระบบผิดปกติ'), findsNothing);
      expect(find.text('18 มิถุนายน 2569'), findsNothing);
    },
  );

  testWidgets(
    '"เปลี่ยนรหัสผ่าน" sends current+new password to the real RPC and translates a wrong current password',
    (tester) async {
      final calls = <String>[];
      await _pump(
        tester,
        changePassword: ({required currentPassword, required newPassword}) async {
          calls.add('$currentPassword→$newPassword');
          if (currentPassword == 'wrong') {
            throw Exception('PostgrestException: wrong_current_password');
          }
        },
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'เปลี่ยนรหัสผ่าน'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'รหัสผ่านปัจจุบัน'), 'wrong');
      await tester.enterText(find.widgetWithText(TextField, 'รหัสผ่านใหม่ (อย่างน้อย 8 ตัว)'), 'NewPass12345');
      await tester.enterText(find.widgetWithText(TextField, 'ยืนยันรหัสผ่านใหม่'), 'NewPass12345');
      await tester.tap(find.widgetWithText(FilledButton, 'เปลี่ยนรหัสผ่าน'));
      await tester.pumpAndSettle();

      expect(calls, ['wrong→NewPass12345']);
      expect(find.text('รหัสผ่านปัจจุบันไม่ถูกต้อง'), findsOneWidget);
      expect(find.textContaining('wrong_current_password'), findsNothing);
      expect(find.byType(AlertDialog), findsOneWidget, reason: 'stays open to retry');

      await tester.enterText(find.widgetWithText(TextField, 'รหัสผ่านปัจจุบัน'), 'OldPass123');
      await tester.tap(find.widgetWithText(FilledButton, 'เปลี่ยนรหัสผ่าน'));
      await tester.pumpAndSettle();

      expect(calls.last, 'OldPass123→NewPass12345');
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.textContaining('เปลี่ยนรหัสผ่านแล้ว'), findsOneWidget);
    },
  );

  testWidgets(
    '"ดูอุปกรณ์" lists real sessions, marks this device, and revokes another through the RPC',
    (tester) async {
      var revoked = <String>[];
      var loads = 0;
      await _pump(
        tester,
        loadSessions: () async {
          loads++;
          return [
            MySessionRecord(
              id: 's-here', deviceInfo: 'MacBook', ipAddress: '10.0.0.2',
              createdAt: DateTime(2026, 9, 14, 8), expiresAt: DateTime(2026, 9, 21, 8), isCurrent: true,
            ),
            if (!revoked.contains('s-phone'))
              MySessionRecord(
                id: 's-phone', deviceInfo: 'iPhone', ipAddress: null,
                createdAt: DateTime(2026, 9, 13, 20), expiresAt: DateTime(2026, 9, 20, 20), isCurrent: false,
              ),
          ];
        },
        revokeSession: (id) async => revoked.add(id),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'ดูอุปกรณ์'));
      await tester.pumpAndSettle();

      expect(find.text('MacBook'), findsOneWidget);
      expect(find.text('เครื่องนี้'), findsOneWidget);
      expect(find.text('iPhone'), findsOneWidget);

      await tester.tap(find.text('ถอนออก'));
      await tester.pumpAndSettle();

      expect(revoked, ['s-phone']);
      expect(loads, 2, reason: 'reads back after revoking, not local removal');
      expect(find.text('iPhone'), findsNothing);
    },
  );

  testWidgets(
    '"ออกจากระบบทุกอุปกรณ์" calls the real sign-out-all RPC and is honest that it includes this device',
    (tester) async {
      var calls = 0;
      await _pump(
        tester,
        signOutAllDevices: () async {
          calls++;
        },
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('ออกจากระบบ'));
      await tester.pumpAndSettle();

      expect(find.text('ยืนยันออกจากระบบทุกอุปกรณ์'), findsOneWidget);
      expect(find.textContaining('รวมถึงเครื่องนี้ด้วย'), findsWidgets);

      await tester.tap(find.text('ยืนยัน'));
      await tester.pumpAndSettle();

      expect(calls, 1, reason: 'confirming must actually call the real RPC');
      // The old copy claimed only *other* devices were affected — false,
      // since auth_sign_out_all revokes every session including this one.
      expect(find.text('ออกจากระบบอุปกรณ์อื่น'), findsNothing);
      expect(find.text('ออกจากระบบอุปกรณ์อื่นแล้ว'), findsNothing);
    },
  );

  testWidgets(
    'a failed sign-out-all surfaces a real error, not a silent fake success',
    (tester) async {
      await _pump(
        tester,
        signOutAllDevices: () async {
          throw StateError('network down');
        },
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('ออกจากระบบ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ยืนยัน'));
      await tester.pumpAndSettle();

      expect(find.text('ออกจากระบบไม่สำเร็จ กรุณาลองใหม่'), findsOneWidget);
    },
  );
}
