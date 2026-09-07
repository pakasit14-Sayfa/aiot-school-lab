import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/school_admin/school_admin_attendance_settings_page.dart';
import 'package:shared_core/shared_core.dart';

/// Pins loading / data / not-yet-configured apart, and guards the write
/// path: saving must actually call the real seam with the picked times and
/// grace minutes — until this exists, staff_check_in refuses everyone in
/// the school with work_hours_not_configured.

StaffWorkHours _hours({
  String start = '08:00:00',
  String end = '16:30:00',
  int grace = 15,
}) => StaffWorkHours(
  workStartTime: start,
  workEndTime: end,
  lateGraceMinutes: grace,
);

StaffAttendanceSummary _summary({
  int total = 10,
  int present = 6,
  int late = 1,
  int leave = 1,
  int officialDuty = 1,
  int absent = 0,
  int noRecord = 1,
  bool configured = true,
}) => StaffAttendanceSummary(
  workDate: DateTime(2026, 9, 7),
  totalStaff: total,
  presentCount: present,
  lateCount: late,
  leaveCount: leave,
  officialDutyCount: officialDuty,
  absentCount: absent,
  noRecordCount: noRecord,
  workHoursConfigured: configured,
);

Future<void> _pump(
  WidgetTester tester, {
  Future<StaffWorkHours?> Function()? loadWorkHours,
  Future<StaffAttendanceSummary?> Function()? loadSummary,
  Future<void> Function({
    required String workStartTime,
    required String workEndTime,
    required int lateGraceMinutes,
  })?
  saveWorkHours,
}) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: SchoolAdminAttendanceSettingsPage(
        loadWorkHours: loadWorkHours ?? () async => null,
        loadSummary: loadSummary ?? () async => null,
        saveWorkHours: saveWorkHours,
      ),
    ),
  );
}

void main() {
  testWidgets('real work hours are rendered', (tester) async {
    await _pump(tester, loadWorkHours: () async => _hours(start: '07:30:00'));
    await tester.pumpAndSettle();

    // TimeOfDay.format(context) renders per-locale (12-hour with AM/PM by
    // default in tests), not the raw HH:mm the service sent — match loosely.
    expect(find.textContaining('7:30'), findsOneWidget);
  });

  testWidgets('no configured hours shows an honest notice, not a guess', (
    tester,
  ) async {
    await _pump(tester);
    await tester.pumpAndSettle();

    expect(find.textContaining('ยังไม่มีการตั้งเวลาปฏิบัติงาน'), findsOneWidget);
  });

  testWidgets('a slow load shows progress, not an empty result', (
    tester,
  ) async {
    final gate = Future.delayed(
      const Duration(milliseconds: 200),
      () => _hours(),
    );
    await _pump(tester, loadWorkHours: () => gate);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('saving calls the real seam with the picked values', (
    tester,
  ) async {
    String? capturedStart;
    String? capturedEnd;
    int? capturedGrace;
    await _pump(
      tester,
      loadWorkHours: () async => _hours(start: '08:00:00', end: '16:30:00', grace: 15),
      saveWorkHours:
          ({
            required workStartTime,
            required workEndTime,
            required lateGraceMinutes,
          }) async {
            capturedStart = workStartTime;
            capturedEnd = workEndTime;
            capturedGrace = lateGraceMinutes;
          },
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('บันทึกเวลาปฏิบัติงาน'));
    await tester.pumpAndSettle();

    expect(capturedStart, '08:00:00');
    expect(capturedEnd, '16:30:00');
    expect(capturedGrace, 15);
    expect(find.text('บันทึกเวลาปฏิบัติงานแล้ว'), findsOneWidget);
  });

  testWidgets('a failed save shows an error, not a false success', (
    tester,
  ) async {
    await _pump(
      tester,
      loadWorkHours: () async => _hours(),
      saveWorkHours:
          ({
            required workStartTime,
            required workEndTime,
            required lateGraceMinutes,
          }) async => throw StateError('rpc rejected'),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('บันทึกเวลาปฏิบัติงาน'));
    await tester.pumpAndSettle();

    expect(find.text('บันทึกไม่สำเร็จ กรุณาลองใหม่'), findsOneWidget);
    expect(find.text('บันทึกเวลาปฏิบัติงานแล้ว'), findsNothing);
  });

  testWidgets('real attendance summary is rendered when present', (
    tester,
  ) async {
    await _pump(
      tester,
      loadWorkHours: () async => _hours(),
      loadSummary: () async => _summary(present: 7, late: 2),
    );
    await tester.pumpAndSettle();

    expect(find.text('7'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets(
    'an unconfigured-hours summary says lateness is unknowable, not zero',
    (tester) async {
      await _pump(
        tester,
        loadSummary: () async => _summary(configured: false, late: 0),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('ตัวเลข "มาสาย" ยังไม่มีความหมาย'),
        findsOneWidget,
      );
    },
  );
}
