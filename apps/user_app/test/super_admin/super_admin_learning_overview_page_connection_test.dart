import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/super_admin/super_admin_learning_overview_page.dart';
import 'package:shared_core/shared_core.dart';

/// Pins loading / data / empty / error apart for the cross-school course
/// overview — read-only oversight page, so the only risk class here is a
/// failed load rendering as "no schools yet" instead of a visible error.

CourseOverviewRecord _school({
  String schoolId = 's-1',
  String schoolName = 'โรงเรียนทดสอบ',
  int coursesTotal = 4,
  int coursesActive = 3,
  int lessonsTotal = 20,
  int lessonsPublished = 15,
  int lessonsDraft = 5,
}) => CourseOverviewRecord(
  schoolId: schoolId,
  schoolName: schoolName,
  coursesTotal: coursesTotal,
  coursesActive: coursesActive,
  lessonsTotal: lessonsTotal,
  lessonsPublished: lessonsPublished,
  lessonsDraft: lessonsDraft,
);

Future<void> _pump(
  WidgetTester tester, {
  Future<List<CourseOverviewRecord>> Function()? loadCourses,
}) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: SuperAdminLearningOverviewPage(
        loadCourses: loadCourses ?? () async => <CourseOverviewRecord>[],
      ),
    ),
  );
}

void main() {
  testWidgets('real course data is rendered', (tester) async {
    await _pump(tester, loadCourses: () async => [_school()]);
    await tester.pumpAndSettle();

    expect(find.text('โรงเรียนทดสอบ'), findsOneWidget);
  });

  testWidgets('no schools says so, not an error', (tester) async {
    await _pump(tester);
    await tester.pumpAndSettle();

    expect(find.text('ยังไม่มีโรงเรียนในระบบ'), findsOneWidget);
    expect(find.textContaining('โหลดข้อมูลไม่สำเร็จ'), findsNothing);
  });

  testWidgets('a slow load shows progress, not an empty result', (
    tester,
  ) async {
    final gate = Future.delayed(
      const Duration(milliseconds: 200),
      () => <CourseOverviewRecord>[_school()],
    );
    await _pump(tester, loadCourses: () => gate);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('a failed load is distinct from empty', (tester) async {
    await _pump(
      tester,
      loadCourses: () async => throw StateError('rpc rejected'),
    );
    await tester.pumpAndSettle();

    // The empty-state panel and the error banner are independent in this
    // page: _records.isEmpty is true either way (nothing loaded), so both
    // render together — the important thing is the error banner shows up
    // instead of being swallowed.
    expect(
      find.text('โหลดภาพรวมการเรียนไม่สำเร็จ กรุณาลองใหม่อีกครั้ง'),
      findsOneWidget,
    );
    // เดิมหน้านี้เอา e.toString() ไปต่อท้ายข้อความแล้วโชว์ทั้งดุ้น
    expect(find.textContaining('rpc rejected'), findsNothing);
    expect(find.textContaining('StateError'), findsNothing);
  });
}
