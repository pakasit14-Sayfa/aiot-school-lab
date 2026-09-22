import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/school_admin/school_reports_page.dart';
import 'package:shared_core/shared_core.dart';

/// Before this suite the page had no loading state, no error state, and
/// `catch (_) {}` swallowing every failure — a failed load and a school with
/// genuinely no data both rendered the same '--'. These tests pin the four
/// states apart so that cannot regress silently.

SchoolAdminDashboardSummary _summary({
  int students = 120,
  int devices = 8,
  int online = 5,
  int buildings = 3,
  int rooms = 24,
  int alerts = 2,
}) => SchoolAdminDashboardSummary(
  schoolId: 'school-1',
  schoolName: 'โรงเรียนทดสอบ',
  schoolCode: 'TEST-1',
  studentsCount: students,
  teachersCount: 10,
  devicesCount: devices,
  devicesOnline: online,
  buildingsCount: buildings,
  roomsCount: rooms,
  openAlertsCount: alerts,
);

SchoolAdminAuditLog _log(String action) => SchoolAdminAuditLog(
  id: 1,
  action: action,
  target: 'reports',
  detail: 'รายละเอียดจริง',
  actorName: 'ผู้ดูแล ทดสอบ',
  actorRole: 'school_admin',
  createdAt: DateTime(2026, 9, 6, 10, 30),
);

Future<void> _pump(
  WidgetTester tester, {
  required Future<SchoolAdminDashboardSummary> Function() loadSummary,
  required Future<List<SchoolAdminAuditLog>> Function() loadLogs,
  ReportsDownloadBytes? downloadBytesOverride,
}) async {
  tester.view.physicalSize = const Size(1400, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: SchoolReportsPage(
        loadSummary: loadSummary,
        loadLogs: loadLogs,
        downloadBytesOverride: downloadBytesOverride,
      ),
    ),
  );
}

void main() {
  testWidgets('loading is visually distinct from an empty result', (
    tester,
  ) async {
    final gate = Completer<SchoolAdminDashboardSummary>();
    await _pump(
      tester,
      loadSummary: () => gate.future,
      loadLogs: () async => <SchoolAdminAuditLog>[],
    );
    await tester.pump();

    // Shows in the preview and insights sections too now that both derive
    // from the same summary load instead of rendering fabricated content.
    expect(find.text('กำลังโหลด…'), findsWidgets);
    expect(
      find.textContaining('ยังไม่มีข้อมูล'),
      findsNothing,
      reason: 'a slow load must not read as "this school has no data"',
    );

    gate.complete(_summary());
    await tester.pumpAndSettle();
    expect(find.text('กำลังโหลด…'), findsNothing);
  });

  testWidgets('real numbers are rendered, including a genuine zero', (
    tester,
  ) async {
    await _pump(
      tester,
      loadSummary: () async => _summary(students: 0, alerts: 0),
      loadLogs: () async => <SchoolAdminAuditLog>[],
    );
    await tester.pumpAndSettle();

    // A real 0 must show as 0, never as an empty state — that distinction is
    // the whole point of separating "no data" from "data that happens to be 0".
    expect(find.text('0'), findsWidgets);
    // Appears on both the summary card and the preview's metric card now
    // that the preview shows real counts instead of a fabricated chart.
    expect(find.text('3 / 24'), findsWidgets);
  });

  testWidgets(
    'the report preview shows real counts, never the old fabricated chart',
    (tester) async {
      await _pump(
        tester,
        loadSummary: () async =>
            _summary(devices: 10, online: 7, alerts: 3, students: 55),
        loadLogs: () async => <SchoolAdminAuditLog>[],
      );
      await tester.pumpAndSettle();

      expect(find.text('7 / 10'), findsOneWidget);
      expect(find.text('3 รายการ'), findsOneWidget);
      // The old chart/metrics were hardcoded values unrelated to any data
      // source and must never appear again.
      expect(find.text('386 kWh'), findsNothing);
      expect(find.text('146 / 152'), findsNothing);
      expect(find.text('แนวโน้มข้อมูลในช่วงที่เลือก'), findsNothing);
    },
  );

  testWidgets(
    'insights are derived from real data, never the old fabricated claims',
    (tester) async {
      await _pump(
        tester,
        loadSummary: () async =>
            _summary(devices: 10, online: 10, alerts: 0, students: 42),
        loadLogs: () async => <SchoolAdminAuditLog>[],
      );
      await tester.pumpAndSettle();

      expect(find.text('อุปกรณ์ออนไลน์ครบ'), findsOneWidget);
      expect(find.text('ไม่มีการแจ้งเตือนค้าง'), findsOneWidget);
      expect(
        find.text('มีนักเรียนลงทะเบียนในระบบทั้งหมด 42 คน'),
        findsOneWidget,
      );
      // The old insights invented specific, unsourced claims that must
      // never reappear. (PM2.5 still legitimately appears as a report-type
      // label elsewhere on this page, so it isn't checked here.)
      expect(find.textContaining('14%'), findsNothing);
      expect(find.textContaining('96.4%'), findsNothing);
    },
  );

  testWidgets('an empty log list says so honestly instead of staying blank', (
    tester,
  ) async {
    await _pump(
      tester,
      loadSummary: () async => _summary(),
      loadLogs: () async => <SchoolAdminAuditLog>[],
    );
    await tester.pumpAndSettle();

    expect(find.text('ยังไม่มีข้อมูลประวัติการใช้งานรายงาน'), findsOneWidget);
  });

  testWidgets('a failed load surfaces a retryable error, not a silent "--"', (
    tester,
  ) async {
    var calls = 0;
    await _pump(
      tester,
      loadSummary: () async {
        calls++;
        throw StateError('backend detail that must not reach the user');
      },
      loadLogs: () async => <SchoolAdminAuditLog>[],
    );
    await tester.pumpAndSettle();

    expect(find.text('โหลดข้อมูลรายงานไม่สำเร็จ กรุณาลองใหม่'), findsOneWidget);
    expect(
      find.textContaining('backend detail'),
      findsNothing,
      reason: 'raw backend text must never be shown to the user',
    );
    expect(calls, 1);

    await tester.tap(find.text('ลองใหม่'));
    await tester.pumpAndSettle();
    expect(calls, 2, reason: 'retry must actually re-issue the load');
  });

  testWidgets('a recovered retry clears the error and shows real data', (
    tester,
  ) async {
    var shouldFail = true;
    await _pump(
      tester,
      loadSummary: () async {
        if (shouldFail) throw StateError('transient');
        return _summary(students: 321);
      },
      loadLogs: () async => <SchoolAdminAuditLog>[_log('report.export')],
    );
    await tester.pumpAndSettle();
    expect(find.text('โหลดข้อมูลรายงานไม่สำเร็จ กรุณาลองใหม่'), findsOneWidget);

    shouldFail = false;
    await tester.tap(find.text('ลองใหม่'));
    await tester.pumpAndSettle();

    expect(find.text('โหลดข้อมูลรายงานไม่สำเร็จ กรุณาลองใหม่'), findsNothing);
    expect(find.text('321'), findsOneWidget);
  });

  testWidgets('export downloads a real CSV built from the loaded summary', (
    tester,
  ) async {
    String? downloadedFilename;
    List<int>? downloadedBytes;
    await _pump(
      tester,
      loadSummary: () async => _summary(students: 55, alerts: 3),
      loadLogs: () async => <SchoolAdminAuditLog>[],
      downloadBytesOverride:
          ({
            required String filename,
            required List<int> bytes,
            required String mimeType,
          }) {
            downloadedFilename = filename;
            downloadedBytes = bytes;
          },
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('ส่งออกรายงาน'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ส่งออกเป็น CSV'));
    await tester.pump();

    expect(downloadedFilename, contains('school_report_'));
    expect(downloadedFilename, endsWith('.csv'));
    expect(downloadedBytes, isNotNull);
    final csv = utf8.decode(downloadedBytes!, allowMalformed: true);
    expect(csv, contains('students_count,55'));
    expect(csv, contains('open_alerts_count,3'));
    expect(find.text('ส่งออกรายงานแล้ว (CSV)'), findsOneWidget);
  });

  testWidgets(
    'export downloads a real Excel file built from the loaded summary',
    (tester) async {
      String? downloadedFilename;
      List<int>? downloadedBytes;
      await _pump(
        tester,
        loadSummary: () async => _summary(),
        loadLogs: () async => <SchoolAdminAuditLog>[],
        downloadBytesOverride:
            ({
              required String filename,
              required List<int> bytes,
              required String mimeType,
            }) {
              downloadedFilename = filename;
              downloadedBytes = bytes;
            },
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('ส่งออกรายงาน'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ส่งออกเป็น Excel'));
      await tester.pump();

      expect(downloadedFilename, endsWith('.xlsx'));
      expect(downloadedBytes, isNotNull);
      // .xlsx is a zip archive — 'PK' magic bytes confirm a real file was
      // encoded, not an empty/placeholder byte list.
      expect(downloadedBytes![0], 0x50);
      expect(downloadedBytes![1], 0x4B);
      expect(find.text('ส่งออกรายงานแล้ว (Excel)'), findsOneWidget);
    },
  );

  testWidgets(
    'export with no data loaded yet refuses instead of downloading an empty file',
    (tester) async {
      var downloadCalled = false;
      final gate = Completer<SchoolAdminDashboardSummary>();
      await _pump(
        tester,
        loadSummary: () => gate.future,
        loadLogs: () async => <SchoolAdminAuditLog>[],
        downloadBytesOverride:
            ({
              required String filename,
              required List<int> bytes,
              required String mimeType,
            }) {
              downloadCalled = true;
            },
      );
      await tester.pump();

      await tester.tap(find.text('ส่งออกรายงาน'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ส่งออกเป็น CSV'));
      await tester.pump();

      expect(downloadCalled, isFalse);
      expect(find.text('ยังไม่มีข้อมูลสำหรับส่งออก'), findsOneWidget);
    },
  );

  /// หน้านี้เคยมี dropdown "ช่วงเวลา / อาคาร / ห้อง" ที่ไม่ได้กรองอะไรเลย —
  /// ค่าที่เลือกถูกเอาไปพิมพ์เป็นหัวข้อ "ช่วง เดือนนี้ • อาคารเรียน B • A-101"
  /// เหนือตัวเลขของทั้งโรงเรียน ผู้ดูแลจึงอ่านตัวเลขรวมโดยเข้าใจว่าเป็นของ
  /// อาคารเดียว แถมชื่ออาคาร/ห้องในลิสต์ก็เป็นชื่อที่แต่งขึ้น ไม่มีในฐานข้อมูล
  testWidgets('ต้องไม่มีตัวกรองอาคาร/ห้องที่กรองอะไรไม่ได้จริง', (
    tester,
  ) async {
    await _pump(
      tester,
      loadSummary: () async => _summary(),
      loadLogs: () async => const <SchoolAdminAuditLog>[],
    );
    await tester.pumpAndSettle();

    // ชื่ออาคาร/ห้องที่แต่งขึ้นต้องไม่เหลืออยู่
    expect(find.text('อาคารเรียน A'), findsNothing);
    expect(find.text('อาคารเรียน B'), findsNothing);
    expect(find.text('LAB-01'), findsNothing);
    expect(find.text('A-101'), findsNothing);
    expect(find.text('กำหนดข้อมูลในรายงาน'), findsNothing);

    // และต้องบอกขอบเขตจริงของตัวเลขแทน
    expect(
      find.textContaining('ภาพรวมทั้งโรงเรียน ณ เวลาที่โหลดล่าสุด'),
      findsOneWidget,
    );
  });
}
