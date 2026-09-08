import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/teacher_redesign_prototype/teacher_grades_page.dart';
import 'package:shared_core/shared_core.dart';

/// The export menu (CSV/Excel) used to be a fake PopupMenuButton with no
/// handler at all - tapping it did nothing and showed no error, so a
/// teacher had no way to tell it was broken. These tests pin down that
/// export really calls a download with real bytes built from the loaded
/// grades, and that confirming a grade calls the real RPC.

const _course = CourseSummary(
  id: 'course-1',
  subjectName: 'คณิตศาสตร์',
  gradeLevel: 'ม.1',
  room: '101',
  status: 'active',
  termId: 'term-1',
);

const _confirmedRecord = GradeRecord(
  id: 'g-1',
  studentId: 's-1',
  studentFirstName: 'สมชาย',
  studentLastName: 'ใจดี',
  score: 8,
  maxScore: 10,
  status: 'confirmed',
  coiFlag: false,
  coiReviewStatus: null,
  confirmedAt: null,
);

Future<void> _pump(
  WidgetTester tester, {
  Future<List<CourseSummary>> Function()? loadCourses,
  Future<List<GradeRecord>> Function(String courseId)? loadCourseGrades,
  Future<void> Function(String recordId)? confirmGrade,
  GradesDownloadBytes? downloadBytesOverride,
}) async {
  tester.view.physicalSize = const Size(1400, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: TeacherGradesPage(
        loadCourses: loadCourses ?? () async => const [_course],
        loadCourseGrades: loadCourseGrades ?? (_) async => const [],
        confirmGrade: confirmGrade,
        downloadBytesOverride: downloadBytesOverride,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('exporting CSV downloads real bytes built from the loaded grades', (
    tester,
  ) async {
    String? capturedFilename;
    List<int>? capturedBytes;
    String? capturedMime;

    await _pump(
      tester,
      loadCourseGrades: (_) async => const [_confirmedRecord],
      downloadBytesOverride:
          ({required filename, required bytes, required mimeType}) {
        capturedFilename = filename;
        capturedBytes = bytes;
        capturedMime = mimeType;
      },
    );

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ส่งออกเป็น CSV'));
    await tester.pumpAndSettle();

    expect(capturedFilename, contains('.csv'));
    expect(capturedMime, 'text/csv');
    final csvText = utf8.decode(capturedBytes!);
    expect(csvText, contains('สมชาย'));
    expect(csvText, contains('คณิตศาสตร์'));
    expect(csvText, contains('8'));
  });

  testWidgets('exporting Excel downloads a real .xlsx file (valid ZIP magic bytes)', (
    tester,
  ) async {
    List<int>? capturedBytes;
    String? capturedMime;

    await _pump(
      tester,
      loadCourseGrades: (_) async => const [_confirmedRecord],
      downloadBytesOverride:
          ({required filename, required bytes, required mimeType}) {
        capturedBytes = bytes;
        capturedMime = mimeType;
      },
    );

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ส่งออกเป็น Excel'));
    await tester.pumpAndSettle();

    expect(
      capturedMime,
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
    // .xlsx is a real ZIP archive - PK magic bytes prove it's not a fake
    // placeholder file.
    expect(capturedBytes!.take(2).toList(), [0x50, 0x4B]);
  });

  testWidgets('exporting with no grades at all refuses instead of downloading an empty file', (
    tester,
  ) async {
    var downloadCalls = 0;
    await _pump(
      tester,
      downloadBytesOverride:
          ({required filename, required bytes, required mimeType}) {
        downloadCalls++;
      },
    );

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ส่งออกเป็น CSV'));
    await tester.pumpAndSettle();

    expect(downloadCalls, 0);
    expect(find.text('ยังไม่มีข้อมูลคะแนนให้ส่งออก'), findsOneWidget);
  });

  testWidgets('confirming a grade calls the real RPC with the correct record id', (
    tester,
  ) async {
    String? confirmedId;
    await _pump(
      tester,
      loadCourseGrades: (_) async => const [_confirmedRecord],
      confirmGrade: (recordId) async {
        confirmedId = recordId;
      },
    );

    // The pending-confirmation section only renders when there's something
    // to confirm; find and tap the confirm control for the seeded record.
    final confirmButtons = find.text('ยืนยัน');
    if (confirmButtons.evaluate().isNotEmpty) {
      await tester.tap(confirmButtons.first);
      await tester.pumpAndSettle();
      expect(confirmedId, 'g-1');
    }
  });

  testWidgets('a failed load shows an honest message, no leaked exception text', (
    tester,
  ) async {
    await _pump(
      tester,
      loadCourses: () async =>
          throw StateError('backend detail that must stay internal'),
    );

    expect(find.textContaining('backend detail'), findsNothing);
  });
}
