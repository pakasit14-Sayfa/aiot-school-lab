// Phone-width guard for the teacher lane (S3, 2026-09-21): pumps the courses
// list and every course-detail tab at 360/375/390/402 and fails on any
// RenderFlex overflow. Started life as a probe that found 7 sites.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/teacher_redesign_prototype/teacher_courses_page.dart';
import 'package:shared_core/shared_core.dart';

const _sizes = [Size(360, 640), Size(375, 667), Size(390, 844), Size(402, 874)];

const _course = TeacherCourseModel(
  id: 'fcf029bf',
  code: 'fcf029bf',
  name: 'คณิตศาสตร์',
  category: 'คณิตศาสตร์',
  rooms: ['ม.1/1'],
  studentCount: 3,
  activeAssignments: 2,
  pendingGradingCount: 0,
  completionRate: 0,
  coverGradient: [Color(0xFF0F766E), Color(0xFF14B8A6)],
  accentColor: Color(0xFF0D9488),
  nextPeriodText: 'ฉบับร่าง — ยังไม่เผยแพร่',
);

Future<void> _probe(
  WidgetTester tester,
  String label,
  Widget home, {
  int pumps = 3,
}) async {
  for (final size in _sizes) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    final errors = <String>[];
    final prev = FlutterError.onError;
    FlutterError.onError = (d) {
      final msg = d.exceptionAsString();
      if (msg.contains('overflowed')) {
        final creator = RegExp(r'(\w+)\.dart:(\d+)')
            .allMatches(d.toString())
            .map((m) => '${m.group(1)}:${m.group(2)}')
            .where((s) => !s.startsWith('framework') && !s.startsWith('flex'))
            .take(3)
            .join(' ← ');
        errors.add('${msg.split('\n').first}  @ $creator');
      } else {
        prev?.call(d);
      }
    };
    await tester.pumpWidget(MaterialApp(key: ValueKey(size), home: home));
    for (var i = 0; i < pumps; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    FlutterError.onError = prev;
    expect(errors, isEmpty, reason: '$label @ ${size.width.toInt()}');
  }
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
}

void main() {
  testWidgets('teacher courses list has no overflow at phone widths', (
    tester,
  ) async {
    await _probe(
      tester,
      'courses',
      TeacherCoursesPage(
        loadCourses: () async => const [
          CourseSummary(
            id: 'fcf029bf',
            subjectName: 'คณิตศาสตร์',
            gradeLevel: 'ม.1',
            room: 'ม.1/1',
            status: 'published',
            termId: 't',
          ),
        ],
      ),
    );
  });

  for (final tab in [
    'นักเรียน',
    'บทเรียน',
    'ใบงาน',
    'แบบทดสอบ',
    'กลุ่ม',
    'คะแนน',
  ]) {
    testWidgets('course detail tab $tab has no overflow at phone widths', (
      tester,
    ) async {
      await _probe(
        tester,
        'detail/$tab',
        TeacherCourseDetailPage(
          course: _course,
          initialTab: tab,
          loadCourseStudents: (_) async => [
            CourseStudent(
              studentId: 's1',
              firstName: 'Dashboard',
              lastName: 'Viewer',
              email: 'dashboard-viewer@aiot-school-lab.local',
              enrolledAt: DateTime(2026, 9, 1),
            ),
          ],
          loadCourseGrades: (_) async => const [],
        ),
      );
    });
  }
}
