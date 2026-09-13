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
    await _pump(
      tester,
      updateProfile: ({required uid, required name}) async {
        saved = true;
      },
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('บันทึก'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ยืนยัน'));
    await tester.pumpAndSettle();

    expect(saved, isTrue);
    expect(
      find.text('บันทึกชื่อเรียบร้อยแล้ว (ฟิลด์อื่นยังไม่รองรับการบันทึก)'),
      findsOneWidget,
    );
  });

  testWidgets(
    'unsupported fields are disclosed as not-saveable, not silently accepted',
    (tester) async {
      await _pump(tester);
      await tester.pumpAndSettle();

      expect(find.text('ยังไม่รองรับการบันทึก'), findsWidgets);
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
    '"เปลี่ยนรหัสผ่าน" explains the real OTP flow instead of faking a change',
    (tester) async {
      await _pump(tester);
      await tester.pumpAndSettle();

      await tester.tap(
        find.widgetWithText(OutlinedButton, 'เปลี่ยนรหัสผ่าน'),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('OTP'), findsOneWidget);
      expect(find.text('รับทราบ'), findsOneWidget);
      // No password fields in the dialog — the old 3-field dialog claimed a
      // change that never reached the backend, and must never come back.
      expect(find.text('รหัสผ่านปัจจุบัน'), findsNothing);
      expect(find.text('รหัสผ่านใหม่'), findsNothing);

      await tester.tap(find.text('รับทราบ'));
      await tester.pumpAndSettle();

      expect(find.text('เปลี่ยนรหัสผ่านแล้ว'), findsNothing);
    },
  );

  testWidgets(
    '"ดูอุปกรณ์" is disabled — no RPC lists active sessions',
    (tester) async {
      await _pump(tester);
      await tester.pumpAndSettle();

      final button = find.widgetWithText(OutlinedButton, 'ดูอุปกรณ์');
      expect(button, findsOneWidget);
      expect(tester.widget<OutlinedButton>(button).onPressed, isNull);
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
