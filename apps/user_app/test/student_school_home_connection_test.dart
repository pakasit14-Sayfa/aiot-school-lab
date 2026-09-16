import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/student_redesign_prototype/widgets/student_variant_school_home.dart';
import 'package:shared_core/shared_core.dart';

/// Whole-page connection test for the student home. Until 2026-09-16 the
/// page could not be pumped at all: AiotWeatherSensorsCard subscribed to
/// RealtimeService in initState and SchoolEncouragementCard ran a periodic
/// timer, so the only coverage was of individual sub-cards.
const _course = CourseSummary(
  id: 'course-1',
  subjectName: 'วิทยาศาสตร์',
  gradeLevel: 'ม.1',
  room: '101',
  status: 'active',
  termId: 'term-1',
);

Future<void> _pump(
  WidgetTester tester, {
  Future<List<CourseSummary>> Function()? loadCourses,
  Future<List<CourseGrade>> Function()? loadGrades,
  Future<List<AppNotification>> Function()? loadNotifications,
}) async {
  tester.view.physicalSize = const Size(1200, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: StudentVariantSchoolHome(
          loadCourses: loadCourses ?? () async => const [_course],
          loadGrades: loadGrades ?? () async => const [],
          loadNotifications: loadNotifications ?? () async => const [],
          loadLessons: (_) async => const [],
          loadAssignments: (_) async => const [],
          loadSubmissionVersions: (_) async => const [],
          sensorStreamOverride: const Stream.empty(),
          rawReadingsStreamOverride: const Stream.empty(),
          utilityCardBuilder: (h) => SizedBox(
            height: h,
            child: const Text('utility-card-stub'),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    currentUserModel = const UserModel(
      uid: 'stu-1',
      email: 'student@aiot-school-lab.local',
      name: 'นักเรียน ทดสอบ',
      role: UserRole.student,
      schoolId: 'school-1',
    );
  });
  tearDown(() => currentUserModel = null);

  testWidgets('the home page renders from real seams with honest empty states', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text('ยังไม่มีประกาศ'), findsOneWidget);
    expect(find.text('ยังไม่มีคะแนนที่ยืนยันแล้ว'), findsOneWidget);
    expect(find.text('utility-card-stub'), findsOneWidget);
    expect(find.textContaining('โหลดข้อมูลหน้าแรกไม่สำเร็จ'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failed read shows the error banner, hides the exception, and retry re-issues the load', (
    tester,
  ) async {
    var calls = 0;
    await _pump(
      tester,
      loadCourses: () async {
        calls++;
        if (calls == 1) throw StateError('home-secret');
        return const [_course];
      },
    );
    expect(find.textContaining('โหลดข้อมูลหน้าแรกไม่สำเร็จ'), findsOneWidget);
    expect(find.textContaining('home-secret'), findsNothing);

    await tester.tap(find.text('ลองใหม่'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.textContaining('โหลดข้อมูลหน้าแรกไม่สำเร็จ'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
