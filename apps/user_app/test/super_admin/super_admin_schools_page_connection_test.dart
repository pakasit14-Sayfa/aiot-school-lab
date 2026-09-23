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
  String packageName = 'Pro',
  String status = 'active',
  int devicesTotal = 5,
  int devicesOnline = 4,
  DateTime? licenseExpiresAt,
}) => SchoolPlatformRecord(
  id: id,
  schoolCode: 'TEST-1',
  name: name,
  province: 'กรุงเทพมหานคร',
  adminEmail: 'admin@school.test',
  packageName: packageName,
  status: status,
  maxUsers: 100,
  maxDevices: 50,
  usersCount: 10,
  devicesTotal: devicesTotal,
  devicesOnline: devicesOnline,
  buildingsCount: 2,
  roomsCount: 8,
  alertsCount: 0,
  licenseExpiresAt:
      licenseExpiresAt ?? DateTime.now().add(const Duration(days: 300)),
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
  Future<bool> Function({
    required String schoolId,
    required String name,
    String? province,
    String? adminEmail,
    String? packageName,
    int? maxUsers,
    int? maxDevices,
    DateTime? licenseExpiresAt,
  })?
  updateSchool,
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
        updateSchool: updateSchool,
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

  testWidgets(
    'editing a school with legacy package name "Pro Package" from priority list does not crash with dropdown assertion',
    (tester) async {
      final school = _school(
        id: 'school-pro-pkg',
        name: 'โรงเรียนDilion',
        packageName: 'Pro Package',
        devicesOnline: 0,
        devicesTotal: 5,
      );
      await _pump(
        tester,
        loadSchools: () async => [school],
      );
      await tester.pumpAndSettle();

      expect(find.text('รายการที่ควรจัดการก่อน'), findsOneWidget);
      expect(find.text('โรงเรียนDilion'), findsWidgets);

      await tester.tap(find.text('โรงเรียนDilion').first);
      await tester.pumpAndSettle();

      expect(find.text('แก้ไขข้อมูล'), findsOneWidget);
      await tester.tap(find.text('แก้ไขข้อมูล'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('แก้ไขข้อมูลโรงเรียน'), findsOneWidget);
      expect(find.text('Pro Package'), findsWidgets);
    },
  );

  testWidgets(
    'editing school with unknown package or empty package does not crash and preserves package options',
    (tester) async {
      final schoolUnknown = _school(
        id: 'school-unknown',
        name: 'โรงเรียนคัสตอม',
        packageName: 'Custom Tier XYZ',
        devicesOnline: 0,
      );
      final schoolEmpty = _school(
        id: 'school-empty',
        name: 'โรงเรียนไม่ระบุ',
        packageName: '',
        devicesOnline: 0,
      );
      await _pump(
        tester,
        loadSchools: () async => [schoolUnknown, schoolEmpty],
      );
      await tester.pumpAndSettle();

      // Open school with unknown package
      await tester.tap(find.text('โรงเรียนคัสตอม').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('แก้ไขข้อมูล'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Custom Tier XYZ'), findsWidgets);
      await tester.tap(find.text('ยกเลิก').last);
      await tester.pumpAndSettle();

      // Open school with empty package
      await tester.tap(find.text('โรงเรียนไม่ระบุ').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('แก้ไขข้อมูล'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('ไม่ระบุแพ็กเกจ'), findsOneWidget);
      await tester.tap(find.text('ยกเลิก').last);
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'editing school name only preserves original package value when saving',
    (tester) async {
      String? savedPackage;
      String? savedName;
      final school = _school(
        id: 'school-preserve',
        name: 'โรงเรียนเดิม',
        packageName: 'Pro Package',
        devicesOnline: 0,
      );
      await _pump(
        tester,
        loadSchools: () async => [school],
        updateSchool: ({
          required schoolId,
          required name,
          province,
          adminEmail,
          packageName,
          maxUsers,
          maxDevices,
          licenseExpiresAt,
        }) async {
          savedName = name;
          savedPackage = packageName;
          return true;
        },
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('โรงเรียนเดิม').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('แก้ไขข้อมูล'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'ชื่อโรงเรียน'),
        'โรงเรียนชื่อใหม่',
      );
      await tester.tap(find.text('บันทึกการแก้ไข').last);
      await tester.pumpAndSettle();

      expect(savedName, 'โรงเรียนชื่อใหม่');
      // Crucial requirement 4: package must NOT be changed to 'Pro'
      expect(savedPackage, 'Pro Package');
    },
  );

  testWidgets(
    'editing form lifecycle: save, cancel, and close X do not dispose controller prematurely',
    (tester) async {
      final school = _school(
        id: 'school-lifecycle',
        name: 'โรงเรียนทดสอบ lifecycle',
        packageName: 'Basic',
      );
      await _pump(
        tester,
        loadSchools: () async => [school],
        updateSchool: ({
          required schoolId,
          required name,
          province,
          adminEmail,
          packageName,
          maxUsers,
          maxDevices,
          licenseExpiresAt,
        }) async => true,
      );
      await tester.pumpAndSettle();

      // Case 1: Cancel while focused
      await tester.tap(find.text('ดูรายละเอียด').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('แก้ไขข้อมูล'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'ชื่อโรงเรียน'),
        'Edited Cancel',
      );
      await tester.tap(find.text('ยกเลิก').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Case 2: Close with X while focused
      await tester.tap(find.text('ดูรายละเอียด').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('แก้ไขข้อมูล'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'ชื่อโรงเรียน'),
        'Edited Close X',
      );
      await tester.tap(find.byTooltip('ปิด').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Case 3: Save while focused
      await tester.tap(find.text('ดูรายละเอียด').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('แก้ไขข้อมูล'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'ชื่อโรงเรียน'),
        'Edited Saved',
      );
      await tester.tap(find.text('บันทึกการแก้ไข').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'package filter syncs with dynamic data and resets if selected package disappears',
    (tester) async {
      List<SchoolPlatformRecord> currentRecords = [
        _school(id: 's-1', name: 'โรงเรียน โปรพิเศษ', packageName: 'Pro Package'),
        _school(id: 's-2', name: 'โรงเรียน เบสิก', packageName: 'Basic'),
      ];

      await _pump(
        tester,
        loadSchools: () async => currentRecords,
      );
      await tester.pumpAndSettle();

      // Tap package filter dropdown (the second DropdownButton on the page)
      await tester.tap(find.byType(DropdownButton<String>).last);
      await tester.pumpAndSettle();

      // Select 'Pro Package'
      await tester.tap(find.text('Pro Package').last);
      await tester.pumpAndSettle();

      expect(find.text('โรงเรียน โปรพิเศษ'), findsOneWidget);
      expect(find.text('โรงเรียน เบสิก'), findsNothing);

      // Change data where 'Pro Package' is no longer present
      currentRecords = [
        _school(id: 's-2', name: 'โรงเรียน เบสิก', packageName: 'Basic'),
        _school(id: 's-3', name: 'โรงเรียน เอ็นเตอร์ไพรส์', packageName: 'Enterprise'),
      ];

      // Re-pump with updated data source
      await _pump(
        tester,
        loadSchools: () async => currentRecords,
      );
      await tester.pumpAndSettle();

      // Filter must reset to 'ทุกแพ็กเกจ'
      expect(find.text('ทุกแพ็กเกจ'), findsWidgets);
      // Both schools are visible now, not stuck filtering with old 'Pro Package'
      expect(find.text('โรงเรียน เบสิก'), findsOneWidget);
      expect(find.text('โรงเรียน เอ็นเตอร์ไพรส์'), findsOneWidget);
    },
  );

  testWidgets('ชื่อแพ็กเกจมีช่องว่างหัวท้าย เลือกกรองแล้วต้องยังเห็นโรงเรียน', (t) async {
    await _pump(t, loadSchools: () async => [
      _school(id: 's1', name: 'โรงเรียนเว้นวรรค', packageName: ' Pro Package '),
      _school(id: 's2', name: 'โรงเรียนเบสิก', packageName: 'Basic'),
    ]);
    await t.pumpAndSettle();

    await t.tap(find.byType(DropdownButton<String>).last);
    await t.pumpAndSettle();
    await t.tap(find.text('Pro Package').last);
    await t.pumpAndSettle();

    expect(find.text('โรงเรียนเว้นวรรค'), findsWidgets,
        reason: 'เลือกตัวเลือกที่สร้างจากโรงเรียนใบนี้เอง แต่กลับกรองมันทิ้ง');
  });

  testWidgets('แพ็กเกจชื่อ "ทุกแพ็กเกจ" ต้องไม่ทำให้ Dropdown assert', (t) async {
    await _pump(t, loadSchools: () async => [
      _school(id: 's1', name: 'โรงเรียนชนชื่อ', packageName: 'ทุกแพ็กเกจ'),
      _school(id: 's2', name: 'โรงเรียนเบสิก', packageName: 'Basic'),
    ]);
    await t.pumpAndSettle();
    expect(t.takeException(), isNull,
        reason: 'ชื่อแพ็กเกจซ้ำกับ sentinel ทำให้ DropdownButton assert');
  });
}
