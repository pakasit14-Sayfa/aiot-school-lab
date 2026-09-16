import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/executive_redesign_prototype/pages/director_reports_page.dart';
import 'package:shared_core/shared_core.dart';

/// This page did not import `shared_core`. It shipped 191 lines of report
/// files — `Attendance_Daily_20-08-2569.pdf`, 2.4 MB, 18 หน้า, sent by
/// นางสาวอรทัย พัฒนกิจ, หัวหน้าฝ่ายวิชาการ — six summary numbers
/// (128 / 102 / 8 / 12 / 3 / 2), and 31 lines of "รายงานที่กำลังรอส่ง" with
/// due dates and "ส่งแล้ว 3/6". The schema had no report table at all:
/// `course_files` is course-scoped coursework.
///
/// It now reads `list_school_reports`, `get_school_report_summary` and
/// `list_report_requirements` from 20260907020000. Two things the old page
/// asserted are gone rather than defaulted: the page count of an uploaded
/// file, which nothing can compute, and 'เกินกำหนด' as a status a filed
/// report can hold — lateness belongs to a requirement's due date.

SchoolReport _report({
  String id = 'r1',
  String title = 'รายงานทดสอบ',
  String fileName = 'test.pdf',
  String fileType = 'pdf',
  String reportType = 'monthly',
  String status = 'submitted',
  int sizeBytes = 2400000,
  String? department,
  String? position,
  String? reviewer,
  DateTime? reviewedAt,
  String? reviewNote,
}) => SchoolReport(
  reportId: id,
  title: title,
  reportType: reportType,
  fileName: fileName,
  fileType: fileType,
  sizeBytes: sizeBytes,
  status: status,
  submittedBy: 'u1',
  submitterName: 'ครูผู้ส่ง ทดสอบ',
  submitterPosition: position,
  submittedAt: DateTime(2026, 9, 7, 16, 42),
  departmentName: department,
  reviewerName: reviewer,
  reviewedAt: reviewedAt,
  reviewNote: reviewNote,
);

SchoolReportSummary _summary({
  int total = 0,
  int awaiting = 0,
  int approved = 0,
  int revision = 0,
  int thisMonth = 0,
  int open = 0,
  int overdue = 0,
}) => SchoolReportSummary(
  totalReports: total,
  awaitingReview: awaiting,
  approved: approved,
  needsRevision: revision,
  submittedThisMonth: thisMonth,
  openRequirements: open,
  overdueRequirements: overdue,
);

ReportRequirement _requirement({
  int expected = 2,
  int filed = 0,
  bool overdue = false,
  List<String> missing = const ['ฝ่ายวิชาการ'],
  DateTime? due,
}) => ReportRequirement(
  requirementId: 'q1',
  title: 'รายงานประจำเดือน',
  reportType: 'monthly',
  expectedCount: expected,
  filedCount: filed,
  isOverdue: overdue,
  missingDepartments: missing,
  dueDate: due,
);

Future<void> _pump(
  WidgetTester tester, {
  List<SchoolReport>? reports,
  SchoolReportSummary? summary,
  List<ReportRequirement>? requirements,
  List<SchoolDepartment>? departments,
  bool fail = false,
  Future<void> Function(String, String, String?)? review,
  List<SchoolReport>? afterReview,
}) async {
  tester.view.physicalSize = const Size(1500, 2800);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  var reads = 0;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: DirectorReportsPage(
          loadReports: () async {
            if (fail) throw StateError('reports_unreachable');
            reads++;
            if (reads > 1 && afterReview != null) return afterReview;
            return reports ?? const <SchoolReport>[];
          },
          loadSummary: () async {
            if (fail) throw StateError('reports_unreachable');
            return summary;
          },
          loadRequirements: () async =>
              requirements ?? const <ReportRequirement>[],
          loadDepartments: () async =>
              departments ?? const <SchoolDepartment>[],
          reviewReport: review,
          loadDownloadUrl: (_) async => 'https://example.invalid/x',
          submitReport:
              ({
                required String title,
                required String reportType,
                required String fileName,
                required Uint8List bytes,
                String? departmentId,
                String? description,
              }) async => 'new-id',
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// `FilledButton.icon` and `OutlinedButton.icon` build private subclasses, so
/// `widgetWithText` with the public type finds nothing.
Finder _buttonWithText(String label) => find.ancestor(
  of: find.text(label),
  matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
);

void main() {
  testWidgets('the invented register is gone', (tester) async {
    await _pump(tester);

    for (final invented in <String>[
      'Attendance_Daily_20-08-2569.pdf',
      'นางสาวอรทัย พัฒนกิจ',
      'ระบบอัตโนมัติ',
      '18 หน้า',
      '79.7% ของไฟล์ทั้งหมด',
    ]) {
      expect(
        find.textContaining(invented),
        findsNothing,
        reason: 'ยังพบของที่แต่งขึ้น: $invented',
      );
    }
    // The six summary numbers that had nothing behind them.
    expect(find.text('128'), findsNothing);
    expect(find.text('102'), findsNothing);
  });

  testWidgets('an empty register says so and shows no counts', (tester) async {
    await _pump(tester, summary: _summary());

    expect(find.text('ยังไม่มีรายงานในทะเบียน'), findsOneWidget);
    // Recent submissions and open requirements are one activity feed now —
    // when both are empty it says so once, not as two separate empty cards.
    expect(find.text('ยังไม่มีกิจกรรมรายงาน'), findsOneWidget);
  });

  testWidgets('a failed load is stated and every figure becomes —', (
    tester,
  ) async {
    await _pump(tester, fail: true);

    expect(find.textContaining('โหลดทะเบียนรายงานไม่สำเร็จ'), findsWidgets);
    expect(find.text('—'), findsWidgets);
    // Not a single zero is invented in place of the read that failed.
    expect(find.text('0'), findsNothing);
    expect(find.textContaining('reports_unreachable'), findsNothing);
  });

  testWidgets('rows and size come from the backend', (tester) async {
    await _pump(
      tester,
      reports: [_report(department: 'ฝ่ายวิชาการ', position: 'ครูชำนาญการ')],
      summary: _summary(total: 1, awaiting: 1, thisMonth: 1),
    );

    expect(find.textContaining('test.pdf'), findsWidgets);
    // 2,400,000 bytes formatted from the real column, not a typed "2.4 MB".
    expect(find.text('2.3 MB'), findsWidgets);
    expect(find.textContaining('ฝ่ายวิชาการ'), findsWidgets);
    expect(find.text('1'), findsWidgets);
  });

  testWidgets('a submitter with no ตำแหน่ง says so rather than borrowing one', (
    tester,
  ) async {
    await _pump(tester, reports: [_report()], summary: _summary(total: 1));

    await tester.tap(find.textContaining('รายงานทดสอบ').first);
    await tester.pumpAndSettle();

    expect(find.text('ยังไม่ได้ระบุตำแหน่ง'), findsOneWidget);
    expect(find.text('ไม่ได้สังกัดฝ่าย'), findsOneWidget);
    expect(find.text('ยังไม่ได้ตรวจ'), findsOneWidget);
    // No page count anywhere: nothing can compute one.
    expect(find.text('จำนวนหน้า'), findsNothing);
  });

  testWidgets('เกินกำหนด belongs to a requirement, not to a file', (
    tester,
  ) async {
    await _pump(
      tester,
      reports: [_report()],
      summary: _summary(total: 1, overdue: 1),
      requirements: [
        _requirement(
          expected: 2,
          filed: 1,
          overdue: true,
          missing: ['ฝ่ายกิจการนักเรียน'],
          due: DateTime(2026, 9, 1),
        ),
      ],
    );

    expect(find.text('ส่งแล้ว 1/2 ฝ่าย'), findsOneWidget);
    // Naming who has not filed is the part a director can act on.
    expect(find.text('ยังไม่ส่ง: ฝ่ายกิจการนักเรียน'), findsOneWidget);
    expect(find.text('รายการที่เลยกำหนดส่ง'), findsOneWidget);
    // The status filter cannot offer it, because no report carries it.
    final statusPillFinder = find.byType(PopupMenuButton<String>).at(3);
    final statusPill = tester.widget<PopupMenuButton<String>>(statusPillFinder);
    final statusItems = statusPill
        .itemBuilder(tester.element(statusPillFinder))
        .whereType<PopupMenuItem<String>>()
        .map((i) => i.value)
        .toList();
    expect(statusItems, ['ทุกสถานะ', 'ส่งแล้ว']);
  });

  testWidgets('filtering to nothing is not the same as an empty register', (
    tester,
  ) async {
    await _pump(
      tester,
      reports: [_report(department: 'ฝ่ายวิชาการ')],
      summary: _summary(total: 1),
      departments: [
        const SchoolDepartment(
          departmentId: 'd2',
          name: 'ฝ่ายกิจการนักเรียน',
          kind: 'administrative',
          sortOrder: 2,
          memberCount: 0,
        ),
      ],
    );

    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('ฝ่ายกิจการนักเรียน').last);
    await tester.pumpAndSettle();

    expect(find.text('ไม่พบไฟล์รายงานตามเงื่อนไข'), findsOneWidget);
    expect(find.textContaining('มีรายงานในทะเบียน 1 ไฟล์'), findsOneWidget);
    expect(find.text('ยังไม่มีรายงานในทะเบียน'), findsNothing);
  });

  testWidgets('approving re-reads and only then reports success', (
    tester,
  ) async {
    await _pump(
      tester,
      reports: [_report()],
      summary: _summary(total: 1, awaiting: 1),
      review: (_, _, _) async {},
      afterReview: [
        _report(
          status: 'approved',
          reviewer: 'ผู้อำนวยการ ทดสอบ',
          reviewedAt: DateTime(2026, 9, 7, 17),
        ),
      ],
    );

    await tester.tap(find.textContaining('รายงานทดสอบ').first);
    await tester.pumpAndSettle();
    await tester.tap(_buttonWithText('อนุมัติ'));
    await tester.pumpAndSettle();

    expect(find.text('อนุมัติรายงานแล้ว'), findsOneWidget);
    expect(find.text('อนุมัติแล้ว'), findsWidgets);
  });

  testWidgets('a review the backend did not apply is not called a success', (
    tester,
  ) async {
    await _pump(
      tester,
      reports: [_report()],
      summary: _summary(total: 1, awaiting: 1),
      review: (_, _, _) async {},
      // The re-read still says submitted: the write did not take.
      afterReview: [_report()],
    );

    await tester.tap(find.textContaining('รายงานทดสอบ').first);
    await tester.pumpAndSettle();
    await tester.tap(_buttonWithText('อนุมัติ'));
    await tester.pumpAndSettle();

    expect(
      find.text('บันทึกผลการตรวจไม่สำเร็จ สถานะยังไม่เปลี่ยน'),
      findsOneWidget,
    );
    expect(find.text('อนุมัติรายงานแล้ว'), findsNothing);
  });

  testWidgets('sending back for revision requires a reason', (tester) async {
    var reviewCalls = 0;
    await _pump(
      tester,
      reports: [_report()],
      summary: _summary(total: 1),
      review: (_, _, _) async => reviewCalls++,
    );

    await tester.tap(find.textContaining('รายงานทดสอบ').first);
    await tester.pumpAndSettle();
    await tester.tap(_buttonWithText('ให้แก้ไข'));
    await tester.pumpAndSettle();
    // Confirm with an empty reason.
    await tester.tap(_buttonWithText('ส่งกลับ'));
    await tester.pumpAndSettle();

    expect(find.text('ต้องระบุเหตุผลก่อนส่งกลับให้แก้ไข'), findsOneWidget);
    expect(reviewCalls, 0, reason: 'ต้องไม่ยิง RPC เมื่อยังไม่มีเหตุผล');
  });
}
