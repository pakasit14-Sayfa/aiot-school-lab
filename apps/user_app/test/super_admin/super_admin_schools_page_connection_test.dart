import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/super_admin/super_admin_schools_page.dart';
import 'package:shared_core/shared_core.dart';

/// Pins loading / data / empty / error apart for the cross-school list, and
/// covers focused form cleanup and the suspend confirmation contract — this page can
/// suspend an entire school (every account in it loses access at once), so
/// a mutation that silently "succeeds" without the backend actually
/// applying it is the highest-blast-radius kind of bug in this app.

SchoolPlatformRecord _school({
  String id = 'school-1',
  String name = 'โรงเรียนทดสอบ',
  String status = 'active',
}) => SchoolPlatformRecord(
  id: id,
  schoolCode: 'TEST-1',
  name: name,
  province: 'กรุงเทพมหานคร',
  adminEmail: 'admin@school.test',
  packageName: 'Pro',
  status: status,
  maxUsers: 100,
  maxDevices: 50,
  usersCount: 10,
  devicesTotal: 5,
  devicesOnline: 4,
  buildingsCount: 2,
  roomsCount: 8,
  alertsCount: 0,
  licenseExpiresAt: DateTime.now().add(const Duration(days: 300)),
);

Future<void> _pump(
  WidgetTester tester, {
  Future<List<SchoolPlatformRecord>> Function()? loadSchools,
  Future<Map<String, dynamic>> Function({
    required String name,
    String? province,
    String? adminEmail,
    String packageName,
    int maxUsers,
    int maxDevices,
    DateTime? licenseExpiresAt,
  })?
  createSchool,
  Future<bool> Function({required String schoolId, required String status})?
  setSchoolStatus,
}) async {
  tester.view.physicalSize = const Size(1500, 3200);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: SuperAdminSchoolsPage(
        loadSchools: loadSchools ?? () async => <SchoolPlatformRecord>[],
        createSchool: createSchool,
        setSchoolStatus: setSchoolStatus,
      ),
    ),
  );
}

void main() {
  testWidgets('saving a focused school form survives its closing animation', (
    tester,
  ) async {
    var saves = 0;
    await _pump(
      tester,
      loadSchools: () async =>
          saves == 0 ? [] : [_school(name: 'Created school')],
      createSchool:
          ({
            required name,
            province,
            adminEmail,
            packageName = 'Basic',
            maxUsers = 30,
            maxDevices = 30,
            licenseExpiresAt,
          }) async {
            saves++;
            return {'id': 'school-1', 'name': name};
          },
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('สร้างโรงเรียนใหม่').first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'ชื่อโรงเรียน'),
      'Created school',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'จังหวัด'),
      'Test province',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'อีเมลผู้ดูแลโรงเรียน'),
      'admin@example.invalid',
    );
    await tester.tap(find.text('สร้างโรงเรียน').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(saves, 1);
    expect(find.byType(Dialog), findsNothing);
    expect(find.text('Created school'), findsWidgets);
  });

  testWidgets(
    'cancelling a focused school form survives its closing animation',
    (tester) async {
      await _pump(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text('สร้างโรงเรียนใหม่').first);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'ชื่อโรงเรียน'),
        'Cancelled school',
      );
      await tester.tap(find.text('ยกเลิก').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(Dialog), findsNothing);
      expect(find.text('Cancelled school'), findsNothing);
    },
  );

  testWidgets('real schools are rendered', (tester) async {
    await _pump(tester, loadSchools: () async => [_school()]);
    await tester.pumpAndSettle();

    expect(find.text('โรงเรียนทดสอบ'), findsWidgets);
  });

  testWidgets('no schools says so, distinct from a failed load', (
    tester,
  ) async {
    await _pump(tester);
    await tester.pumpAndSettle();

    expect(find.text('ไม่พบโรงเรียน'), findsOneWidget);
    expect(find.text('โหลดข้อมูลโรงเรียนไม่สำเร็จ'), findsNothing);
  });

  testWidgets('a failed load is distinct from empty, with retry', (
    tester,
  ) async {
    var calls = 0;
    await _pump(
      tester,
      loadSchools: () async {
        calls++;
        throw StateError('load failure detail');
      },
    );
    await tester.pumpAndSettle();

    // This page deliberately shows the raw error via SelectableText for
    // Super Admin (a technical audience) to copy while debugging — unlike
    // School Admin pages, which must never show raw backend detail.
    expect(find.text('โหลดข้อมูลโรงเรียนไม่สำเร็จ'), findsOneWidget);
    expect(calls, 1);

    await tester.tap(find.text('ลองใหม่'));
    await tester.pumpAndSettle();
    expect(calls, 2, reason: 'retry must actually re-issue the load');
  });

  testWidgets('a slow load shows progress, not an empty result', (
    tester,
  ) async {
    final gate = Completer<List<SchoolPlatformRecord>>();
    await _pump(tester, loadSchools: () => gate.future);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    gate.complete([_school()]);
    await tester.pumpAndSettle();
  });

  testWidgets(
    'suspending a school only reports success once setSchoolStatus confirms true',
    (tester) async {
      await _pump(
        tester,
        loadSchools: () async => [_school(status: 'active')],
        setSchoolStatus: ({required schoolId, required status}) async =>
            false, // RPC ran but did not apply — must not read as success.
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PopupMenuButton<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('ระงับการใช้งาน').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('ระงับการใช้งาน').last);
      await tester.pumpAndSettle();

      expect(
        find.textContaining('ระงับการใช้งาน โรงเรียนทดสอบ ใน Supabase แล้ว'),
        findsNothing,
      );
      expect(find.textContaining('เปลี่ยนสถานะไม่สำเร็จ'), findsOneWidget);
    },
  );

  testWidgets(
    'suspending a school reports success once setSchoolStatus confirms true',
    (tester) async {
      var suspended = false;
      await _pump(
        tester,
        loadSchools: () async => [
          _school(status: suspended ? 'suspended' : 'active'),
        ],
        setSchoolStatus: ({required schoolId, required status}) async {
          suspended = true;
          return true;
        },
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PopupMenuButton<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('ระงับการใช้งาน').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('ระงับการใช้งาน').last);
      await tester.pumpAndSettle();

      expect(find.textContaining('ใน Supabase แล้ว'), findsOneWidget);
    },
  );
}
