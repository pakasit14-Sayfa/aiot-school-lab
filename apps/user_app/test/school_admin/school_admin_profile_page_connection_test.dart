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

Future<void> _pump(
  WidgetTester tester, {
  Future<List<SchoolAdminAuditLog>> Function()? loadLogs,
  Future<void> Function({required String uid, required String name})?
  updateProfile,
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
        updateProfile: updateProfile,
      ),
    ),
  );
}

void main() {
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
}
