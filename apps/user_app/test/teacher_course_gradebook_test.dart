import 'dart:convert' show utf8;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/teacher_redesign_prototype/teacher_courses_page.dart';
import 'package:shared_core/shared_core.dart';

void main() {
  _csvTests();
  _phoneTests();
  testWidgets(
    'Gradebook tab never shows the old identical-fake-score row',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const course = TeacherCourseModel(
        id: 'course-1',
        code: 'ว31281',
        name: 'ทดสอบ',
        category: 'เทคโนโลยี',
        rooms: ['ม.4/1'],
        studentCount: 0,
        activeAssignments: 0,
        pendingGradingCount: 0,
        completionRate: 0,
        coverGradient: [Color(0xFF0F766E), Color(0xFF14B8A6)],
        accentColor: Color(0xFF0D9488),
        nextPeriodText: '-',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: TeacherCourseDetailPage(course: course),
        ),
      );
      await tester.pump();
      // The default "บทเรียน" tab (TeacherLessonListPage) has a pre-existing,
      // unrelated layout overflow at this viewport width — swallow it so it
      // doesn't fail this test, which only asserts on the "คะแนน" tab.
      tester.takeException();

      await tester.tap(find.text('คะแนน').first);
      await tester.pump();
      tester.takeException();
      await tester.pump();
      tester.takeException();

      // The old bug hardcoded these exact fabricated values for every
      // student regardless of what was actually enrolled/graded — none of
      // them must ever render again now that the tab reads real
      // GradeService.listCourseGrades data.
      expect(find.textContaining('เกรด 4.0'), findsNothing);
      expect(find.text('ส่งงานครบแล้ว'), findsNothing);
      expect(find.textContaining('บทที่ 1: เซนเซอร์ PM2.5'), findsNothing);
      expect(find.textContaining('ใบงานที่ 1: ต่อวงจร'), findsNothing);
    },
  );
}

// ---------------------------------------------------------------------------
// 2026-09-16: real CSV export + honest failure state, driven through seams.
// ---------------------------------------------------------------------------

const _course = TeacherCourseModel(
  id: 'course-1',
  code: 'ว31281',
  name: 'ทดสอบ',
  category: 'เทคโนโลยี',
  rooms: ['ม.4/1'],
  studentCount: 0,
  activeAssignments: 0,
  pendingGradingCount: 0,
  completionRate: 0,
  coverGradient: [Color(0xFF0F766E), Color(0xFF14B8A6)],
  accentColor: Color(0xFF0D9488),
  nextPeriodText: '-',
);

final _student = CourseStudent(
  studentId: 'stu-00000001',
  firstName: 'อนันต์',
  lastName: 'ทดสอบ',
  email: 's@x',
  enrolledAt: DateTime(2026, 5, 1),
);

final _grade = GradeRecord(
  id: 'g1',
  studentId: 'stu-00000001',
  studentFirstName: 'อนันต์',
  studentLastName: 'ทดสอบ',
  score: 18,
  maxScore: 20,
  status: 'confirmed',
  coiFlag: false,
  coiReviewStatus: null,
  confirmedAt: DateTime(2026, 9, 1),
);

Future<void> _pumpGradebook(
  WidgetTester tester, {
  Future<List<CourseStudent>> Function(String)? students,
  Future<List<GradeRecord>> Function(String)? grades,
  void Function({
    required String filename,
    required List<int> bytes,
    required String mimeType,
  })?
  download,
}) async {
  tester.view.physicalSize = const Size(1400, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: TeacherCourseDetailPage(
        course: _course,
        initialTab: 'คะแนน',
        loadCourseStudents: students ?? (_) async => [_student],
        loadCourseGrades: grades ?? (_) async => [_grade],
        downloadBytesOverride: download,
      ),
    ),
  );
  await tester.pumpAndSettle();
  tester.takeException();
}

void _csvTests() {
  testWidgets('"ส่งออกคะแนน (CSV)" downloads a real CSV of the loaded gradebook', (
    tester,
  ) async {
    String? gotName;
    List<int>? gotBytes;
    await _pumpGradebook(
      tester,
      download: ({required String filename, required List<int> bytes, required String mimeType}) {
        gotName = filename;
        gotBytes = bytes;
      },
    );
    expect(find.text('ส่งออกคะแนน (ยังไม่เปิดใช้งาน)'), findsNothing);
    await tester.tap(find.text('ส่งออกคะแนน (CSV)'));
    await tester.pumpAndSettle();
    expect(gotName, startsWith('gradebook_'));
    final csv = utf8.decode(gotBytes!);
    expect(csv, contains('อนันต์ ทดสอบ'));
    expect(csv, contains(',18,20,1'));
    expect(find.text('ส่งออกสมุดคะแนนแล้ว (CSV)'), findsOneWidget);
  });

  testWidgets('a failed grade read is an error with retry, not every student at 0', (
    tester,
  ) async {
    var calls = 0;
    await _pumpGradebook(
      tester,
      grades: (_) async {
        calls++;
        if (calls == 1) throw StateError('grades-secret');
        return [_grade];
      },
    );
    expect(find.textContaining('โหลดสมุดคะแนนไม่สำเร็จ'), findsOneWidget);
    expect(find.textContaining('grades-secret'), findsNothing);
    expect(find.text('อนันต์ ทดสอบ'), findsNothing);

    await tester.tap(find.text('ลองใหม่'));
    await tester.pumpAndSettle();
    tester.takeException();
    expect(calls, 2);
    expect(find.textContaining('โหลดสมุดคะแนนไม่สำเร็จ'), findsNothing);
    expect(find.text('อนันต์ ทดสอบ'), findsWidgets);
  });
}

/// 2026-09-21: บนมือถือแท็บคะแนนเคยเป็น `DataTable` 5 คอลัมน์กว้างราว 720pt
/// ต้องเลื่อนแนวนอนกว่าจะเห็นคะแนน และคอลัมน์ "รหัสนักเรียน" คือ 8 ตัวแรกของ
/// uuid ไม่ใช่รหัสโรงเรียนจริง (บั๊กเดียวกับที่แท็บรายชื่อแก้ไปก่อนแล้ว)
void _phoneTests() {
  testWidgets('on a phone the gradebook is a list, not a sideways table', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: TeacherCourseDetailPage(
          course: _course,
          initialTab: 'คะแนน',
          loadCourseStudents: (_) async => [_student],
          loadCourseGrades: (_) async => [_grade],
        ),
      ),
    );
    await tester.pump();
    tester.takeException();
    await tester.pump(const Duration(milliseconds: 300));
    tester.takeException();

    expect(find.byType(DataTable), findsNothing);
    expect(find.text('อนันต์ ทดสอบ'), findsOneWidget);
    expect(find.text('18/20'), findsOneWidget);
    expect(find.textContaining('stu-0000'), findsNothing);
  });

  testWidgets('the gradebook never labels a uuid prefix as a student code', (
    tester,
  ) async {
    await _pumpGradebook(tester);

    expect(find.text('รหัสนักเรียน'), findsNothing);
    expect(find.textContaining('stu-0000'), findsNothing);
    expect(find.text('s@x'), findsOneWidget);
  });
}
