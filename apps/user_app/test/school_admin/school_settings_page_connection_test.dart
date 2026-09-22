import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/school_admin/school_settings_page.dart';
import 'package:shared_core/shared_core.dart';

/// Pins loading / data / empty / error apart across the three real sources
/// this page reads (`get_school_admin_dashboard_summary`,
/// `get_school_utility_rates`, `list_school_admin_audit_logs`), and guards
/// the write→read-back→confirm contract on `set_school_utility_rates`: a
/// "saved" message may only appear once the value read back matches what was
/// submitted, never on the strength of the write call alone.

SchoolAdminDashboardSummary _summary({
  String schoolName = 'โรงเรียนทดสอบ',
  String schoolCode = 'TEST-1',
}) => SchoolAdminDashboardSummary(
  schoolId: 'school-1',
  schoolName: schoolName,
  schoolCode: schoolCode,
  studentsCount: 120,
  teachersCount: 8,
  devicesCount: 5,
  devicesOnline: 3,
  buildingsCount: 2,
  roomsCount: 10,
  openAlertsCount: 1,
);

SchoolUtilityRates _rates({
  double electricity = 4.2,
  double water = 18,
  bool electricityDefault = false,
  bool waterDefault = false,
}) => SchoolUtilityRates(
  electricityRateThb: electricity,
  isElectricityDefault: electricityDefault,
  waterRateThb: water,
  isWaterDefault: waterDefault,
);

SchoolAdminAuditLog _log({String action = 'แก้ไขอัตราค่าไฟฟ้า'}) =>
    SchoolAdminAuditLog(
      id: 1,
      action: action,
      target: 'school_settings',
      detail: '',
      actorName: 'ผู้ดูแล ทดสอบ',
      actorRole: 'school_admin',
      createdAt: DateTime(2026, 9, 1),
    );

Future<void> _pump(
  WidgetTester tester, {
  Future<SchoolAdminDashboardSummary> Function()? loadSummary,
  Future<SchoolUtilityRates?> Function()? loadRates,
  Future<void> Function({
    required double electricityRateThb,
    required double waterRateThb,
  })?
  saveRates,
  Future<List<SchoolAdminAuditLog>> Function()? loadLogs,
  Future<List<AcademicYearOption>> Function()? loadAcademicYears,
  Future<List<TermOption>> Function()? loadTerms,
  Future<String> Function({
    required String name,
    DateTime? startDate,
    DateTime? endDate,
  })?
  createAcademicYear,
  Future<String> Function({
    required String academicYearId,
    required String name,
    DateTime? startDate,
    DateTime? endDate,
  })?
  createTerm,
  Future<List<CalendarEventItem>> Function()? loadSchoolEvents,
  Future<String> Function({
    required String title,
    required DateTime startDate,
    DateTime? endDate,
    String? location,
    String? description,
    String eventType,
  })?
  createSchoolEvent,
  Future<void> Function(String eventId)? deleteSchoolEvent,
}) async {
  tester.view.physicalSize = const Size(1500, 3200);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: SchoolSettingsPage(
        loadSummary: loadSummary ?? () async => _summary(),
        loadRates: loadRates ?? () async => _rates(),
        saveRates: saveRates,
        loadLogs: loadLogs ?? () async => <SchoolAdminAuditLog>[],
        loadAcademicYears:
            loadAcademicYears ?? () async => const <AcademicYearOption>[],
        loadTerms: loadTerms ?? () async => const <TermOption>[],
        createAcademicYear: createAcademicYear,
        createTerm: createTerm,
        loadSchoolEvents:
            loadSchoolEvents ?? () async => const <CalendarEventItem>[],
        createSchoolEvent: createSchoolEvent,
        deleteSchoolEvent: deleteSchoolEvent,
      ),
    ),
  );
}

void main() {
  testWidgets('real school info and rates are rendered', (tester) async {
    await _pump(tester);
    await tester.pumpAndSettle();

    expect(find.text('โรงเรียนทดสอบ'), findsOneWidget);
    expect(find.text('TEST-1'), findsOneWidget);
    expect(find.text('4.2'), findsOneWidget);
    expect(find.text('18'), findsOneWidget);
  });

  testWidgets('no utility rates yet says so, not an error', (tester) async {
    await _pump(tester, loadRates: () async => null);
    await tester.pumpAndSettle();

    expect(
      find.text(
        'ยังไม่มีข้อมูลอัตราค่าสาธารณูปโภคของโรงเรียนนี้ กรอกค่าแล้วกดบันทึกเพื่อตั้งค่าครั้งแรก',
      ),
      findsOneWidget,
    );
    expect(find.text('โหลดอัตราค่าไฟฟ้าและค่าน้ำไม่สำเร็จ'), findsNothing);
  });

  testWidgets('a default (unset) rate is disclosed, not shown as chosen', (
    tester,
  ) async {
    await _pump(
      tester,
      loadRates: () async =>
          _rates(electricityDefault: true, waterDefault: true),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('โรงเรียนนี้ยังไม่ได้ตั้งอัตราเอง ระบบใช้ค่ากลางอยู่'),
      findsOneWidget,
    );
  });

  testWidgets('a failed summary load is distinct from a failed rates load', (
    tester,
  ) async {
    await _pump(tester, loadSummary: () async => throw StateError('boom'));
    await tester.pumpAndSettle();

    expect(find.text('โหลดข้อมูลโรงเรียนไม่สำเร็จ'), findsOneWidget);
    // Rates still loaded fine — the two sources must not be conflated.
    expect(find.text('โหลดอัตราค่าไฟฟ้าและค่าน้ำไม่สำเร็จ'), findsNothing);
    expect(find.text('4.2'), findsOneWidget);
  });

  testWidgets('saving is rejected client-side if the retry never confirms', (
    tester,
  ) async {
    var writeCalls = 0;
    var stillOldRate = _rates(electricity: 4.2);
    await _pump(
      tester,
      loadRates: () async => stillOldRate,
      saveRates: ({required electricityRateThb, required waterRateThb}) async {
        writeCalls++;
        // Simulate the write silently not taking effect server-side.
      },
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'อัตราค่าไฟฟ้า (บาท/หน่วย)'),
      '5.5',
    );
    await tester.tap(find.text('บันทึกอัตราค่าสาธารณูปโภค'));
    await tester.pumpAndSettle();

    expect(writeCalls, 1);
    expect(
      find.text(
        'บันทึกอัตราค่าไฟฟ้าและค่าน้ำไม่สำเร็จ ระบบยังไม่ได้บันทึกการเปลี่ยนแปลง',
      ),
      findsOneWidget,
    );
    // Must never claim success when the read-back does not match.
    expect(
      find.text('บันทึกอัตราค่าไฟฟ้าและค่าน้ำเรียบร้อยแล้ว'),
      findsNothing,
    );
  });

  testWidgets('saving succeeds only after the read-back confirms the value', (
    tester,
  ) async {
    var confirmed = _rates(electricity: 4.2);
    await _pump(
      tester,
      loadRates: () async => confirmed,
      saveRates: ({required electricityRateThb, required waterRateThb}) async {
        confirmed = _rates(
          electricity: electricityRateThb,
          water: waterRateThb,
        );
      },
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'อัตราค่าไฟฟ้า (บาท/หน่วย)'),
      '5.5',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'อัตราค่าน้ำ (บาท/ลูกบาศก์เมตร)'),
      '20',
    );
    await tester.tap(find.text('บันทึกอัตราค่าสาธารณูปโภค'));
    await tester.pumpAndSettle();

    expect(find.text('5.5'), findsOneWidget);
    expect(find.text('20'), findsOneWidget);
  });

  testWidgets('a slow summary load shows progress, not empty fields', (
    tester,
  ) async {
    final gate = Completer<SchoolAdminDashboardSummary>();
    await _pump(tester, loadSummary: () => gate.future);
    await tester.pump();

    expect(find.text('กำลังโหลดข้อมูลโรงเรียน…'), findsOneWidget);

    gate.complete(_summary());
    await tester.pumpAndSettle();
    expect(find.text('กำลังโหลดข้อมูลโรงเรียน…'), findsNothing);
  });

  testWidgets('log error is distinct from empty log history', (tester) async {
    await _pump(tester, loadLogs: () async => throw StateError('boom'));
    await tester.pumpAndSettle();

    expect(find.text('โหลดประวัติการแก้ไขการตั้งค่าไม่สำเร็จ'), findsOneWidget);
    expect(find.text('ยังไม่มีประวัติการแก้ไขการตั้งค่า'), findsNothing);
  });

  testWidgets('a real log entry is rendered', (tester) async {
    await _pump(tester, loadLogs: () async => [_log()]);
    await tester.pumpAndSettle();

    expect(find.text('แก้ไขอัตราค่าไฟฟ้า'), findsOneWidget);
  });

  /// เดิมมีการ์ด "การตั้งค่าที่ยังไม่เปิดใช้งาน" 4 แถว — ถอดออก 2026-09-14
  /// ส่วนที่มีที่เก็บจริง (ปี/ภาคเรียน) กลายเป็นส่วนจัดการจริง
  testWidgets(
    'no "unavailable settings" card; academic years and terms come from the backend',
    (tester) async {
      await _pump(
        tester,
        loadAcademicYears: () async => const [
          AcademicYearOption(
            id: 'ay-1',
            name: '2569',
            startDate: null,
            endDate: null,
            termsCount: 1,
          ),
        ],
        loadTerms: () async => const [
          TermOption(
            id: 't-1',
            name: 'ภาคเรียนที่ 1/2569',
            academicYearName: '2569',
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('การตั้งค่าที่ยังไม่เปิดใช้งาน'), findsNothing);
      expect(find.text('ปีการศึกษา 2569'), findsOneWidget);
      expect(find.text('· ภาคเรียนที่ 1/2569'), findsOneWidget);
    },
  );

  testWidgets(
    'creating a term sends the chosen year and name to create_term, then reads back',
    (tester) async {
      Map<String, Object?>? sent;
      var loads = 0;
      await _pump(
        tester,
        loadAcademicYears: () async {
          loads++;
          return const [
            AcademicYearOption(
              id: 'ay-1',
              name: '2569',
              startDate: null,
              endDate: null,
              termsCount: 0,
            ),
          ];
        },
        createTerm:
            ({
              required academicYearId,
              required name,
              startDate,
              endDate,
            }) async {
              sent = {
                'year': academicYearId,
                'name': name,
                'start': startDate?.toIso8601String(),
              };
              return 't-new';
            },
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('สร้างภาคเรียน'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(
          TextField,
          'ชื่อภาคเรียน (เช่น ภาคเรียนที่ 1/2569)',
        ),
        'ภาคเรียนที่ 2/2569',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'วันเริ่ม (ปี-เดือน-วัน, ถ้ามี)'),
        '2026-11-01',
      );
      await tester.tap(find.text('บันทึก'));
      await tester.pumpAndSettle();

      expect(sent, {
        'year': 'ay-1',
        'name': 'ภาคเรียนที่ 2/2569',
        'start': '2026-11-01T00:00:00.000',
      });
      expect(loads, 2, reason: 'reads back after the write');
      expect(find.text('สร้างภาคเรียนที่ 2/2569แล้ว'), findsOneWidget);
    },
  );

  testWidgets('a bad date is rejected in the form before any RPC call', (
    tester,
  ) async {
    var calls = 0;
    await _pump(
      tester,
      createAcademicYear: ({required name, startDate, endDate}) async {
        calls++;
        return 'ay-x';
      },
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('สร้างปีการศึกษา'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'ชื่อปีการศึกษา (เช่น 2569)'),
      '2570',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'วันเริ่ม (ปี-เดือน-วัน, ถ้ามี)'),
      '16/05/2570',
    );
    await tester.tap(find.text('บันทึก'));
    await tester.pumpAndSettle();

    expect(calls, 0);
    expect(find.textContaining('รูปแบบวันที่ต้องเป็น'), findsOneWidget);
  });

  // -------------------------------------------------------------------------
  // 2026-09-17: school events can finally be created/deleted from the app.
  // -------------------------------------------------------------------------

  CalendarEventItem ev(String id, String title) => CalendarEventItem(
    eventId: id,
    title: title,
    startDate: DateTime(2026, 9, 20),
    eventType: 'activity',
  );

  testWidgets(
    'school events list from list_calendar_events with an honest empty state',
    (tester) async {
      await _pump(tester);
      await tester.pumpAndSettle();
      expect(find.text('กิจกรรมและวันสำคัญ'), findsOneWidget);
      expect(find.text('ยังไม่มีกิจกรรมในปฏิทินโรงเรียน'), findsOneWidget);
    },
  );

  testWidgets(
    'adding an event calls create_school_event and shows it only after read-back',
    (tester) async {
      final events = <CalendarEventItem>[];
      String? sentTitle;
      await _pump(
        tester,
        loadSchoolEvents: () async => List.of(events),
        createSchoolEvent:
            ({
              required title,
              required startDate,
              endDate,
              location,
              description,
              eventType = 'activity',
            }) async {
              sentTitle = title;
              expect(startDate, DateTime(2026, 9, 20));
              events.add(ev('ev-1', title));
              return 'ev-1';
            },
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('เพิ่มกิจกรรม / วันสำคัญ'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'ชื่อกิจกรรม'),
        'กีฬาสี',
      );
      await tester.enterText(
        find.widgetWithText(
          TextField,
          'วันเริ่ม (ปี-เดือน-วัน เช่น 2026-09-20)',
        ),
        '2026-09-20',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'บันทึก'));
      await tester.pumpAndSettle();

      expect(sentTitle, 'กีฬาสี');
      expect(find.textContaining('กีฬาสี'), findsWidgets);
      expect(
        find.textContaining('เพิ่ม "กีฬาสี" ในปฏิทินโรงเรียนแล้ว'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'deleting an event is confirmed by read-back; a lingering row is reported as failure',
    (tester) async {
      var deleted = false;
      await _pump(
        tester,
        loadSchoolEvents: () async => [
          ev('ev-1', 'กีฬาสี'),
        ], // never disappears
        deleteSchoolEvent: (id) async => deleted = true,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'ลบ'));
      await tester.pumpAndSettle();
      expect(deleted, isTrue);
      expect(find.text('ลบไม่สำเร็จ กิจกรรมยังอยู่ในปฏิทิน'), findsOneWidget);
      expect(find.textContaining('กีฬาสี'), findsWidgets);
    },
  );
}
