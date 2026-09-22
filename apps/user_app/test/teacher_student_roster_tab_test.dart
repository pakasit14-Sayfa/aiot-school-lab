import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/teacher_redesign_prototype/teacher_courses_page.dart';
import 'package:shared_core/shared_core.dart';

/// แท็บ "นักเรียน" ของหน้ารายละเอียดวิชา เคยแปะ `'room': 'ม.4/1'` ให้นักเรียน
/// ทุกคนทุกวิชา และตัด 8 ตัวแรกของ uuid มาโชว์เป็น "รหัส xxxxxxxx" — ทั้งคู่
/// ไม่ใช่ข้อมูลจริง (list_course_students ไม่คืนรหัสนักเรียน) ตอนนี้ใช้ห้อง
/// ของรายวิชาและอีเมลจริง และโหลดล้มต้องไม่ดูเหมือน "ยังไม่มีนักเรียน"
TeacherCourseModel _course({List<String> rooms = const ['ม.5/3']}) =>
    TeacherCourseModel(
      id: 'course-1',
      code: 'ว30201',
      name: 'ฟิสิกส์ประยุกต์กับ IoT',
      category: 'วิทยาศาสตร์',
      rooms: rooms,
      studentCount: 1,
      activeAssignments: 0,
      pendingGradingCount: 0,
      completionRate: 0,
      coverGradient: const [Color(0xFF3B82F6), Color(0xFF60A5FA)],
      accentColor: const Color(0xFF3B82F6),
      nextPeriodText: '',
    );

CourseStudent _student() => CourseStudent(
  studentId: 'a1b2c3d4-0000-4000-8000-000000000001',
  firstName: 'สมชาย',
  lastName: 'ใจดี',
  email: 'somchai@aiot-school-lab.local',
  enrolledAt: DateTime(2026, 9, 1),
);

CourseStudent _student2() => CourseStudent(
  studentId: 'a1b2c3d4-0000-4000-8000-000000000002',
  firstName: 'สมหญิง',
  lastName: 'ตั้งใจ',
  email: 'somying@aiot-school-lab.local',
  enrolledAt: DateTime(2026, 9, 1),
);

Future<void> _pump(
  WidgetTester tester, {
  required TeacherCourseModel course,
  required Future<List<CourseStudent>> Function(String) loadStudents,
}) async {
  tester.view.physicalSize = const Size(1200, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: TeacherStudentRosterTab(
            course: course,
            loadStudents: loadStudents,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  _retryTests();
  _roomStatedOnceTests();
  testWidgets(
    'a student row shows the course room and real email, never a fake room or uuid-prefix code',
    (tester) async {
      await _pump(
        tester,
        course: _course(),
        loadStudents: (_) async => [_student()],
      );

      expect(find.textContaining('สมชาย'), findsWidgets);
      expect(find.textContaining('ห้อง ม.5/3'), findsOneWidget);
      expect(find.text('somchai@aiot-school-lab.local'), findsOneWidget);
      expect(find.textContaining('ม.4/1'), findsNothing);
      expect(find.textContaining('a1b2c3d4'), findsNothing);
      expect(find.textContaining('รหัส '), findsNothing);
    },
  );

  testWidgets(
    'a course without a room shows only the email, not an invented room',
    (tester) async {
      await _pump(
        tester,
        course: _course(rooms: const []),
        loadStudents: (_) async => [_student()],
      );

      expect(find.text('somchai@aiot-school-lab.local'), findsOneWidget);
      expect(find.textContaining('ห้อง '), findsNothing);
      expect(find.textContaining('ม.4/1'), findsNothing);
    },
  );

  testWidgets('a failed roster load is distinct from an empty roster', (
    tester,
  ) async {
    await _pump(
      tester,
      course: _course(),
      loadStudents: (_) async =>
          throw Exception('PostgrestException: roster_boom'),
    );

    expect(find.text('โหลดรายชื่อนักเรียนไม่สำเร็จ'), findsOneWidget);
    expect(find.text('ยังไม่มีนักเรียนลงทะเบียนในรายวิชานี้'), findsNothing);
    expect(find.textContaining('roster_boom'), findsNothing);
  });
}

/// โหลดล้มแล้วกด "ลองใหม่" สำเร็จ — การ์ดล้มเหลวต้องหาย (เคยค้างเพราะ
/// `_loadFailed` ไม่ถูกรีเซ็ตในทางสำเร็จ)
void _retryTests() {
  testWidgets(
    'a successful retry clears the failed state and shows the roster',
    (tester) async {
      var calls = 0;
      await _pump(
        tester,
        course: _course(),
        loadStudents: (_) async {
          calls++;
          if (calls == 1) throw Exception('first load fails');
          return [_student()];
        },
      );
      expect(find.text('โหลดรายชื่อนักเรียนไม่สำเร็จ'), findsOneWidget);

      await tester.tap(find.text('ลองใหม่'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('โหลดรายชื่อนักเรียนไม่สำเร็จ'), findsNothing);
      expect(find.textContaining('สมชาย'), findsWidgets);
    },
  );
}

/// 2026-09-21: ห้องของรายวิชาเหมือนกันทุกแถวอยู่แล้ว (นักเรียนเข้าวิชาผ่าน
/// ตารางเรียนของห้อง) การแปะป้ายห้องซ้ำทุกแถวจึงกินความกว้างจอมือถือโดยไม่
/// เพิ่มข้อมูล — แบบเดียวกับป้าย "เรียนปกติ (Active)" ที่ถอดไปก่อนหน้านี้
/// ตอนนี้บอกห้องครั้งเดียวที่หัวแท็บ
void _roomStatedOnceTests() {
  testWidgets(
    'the course room is stated once in the header, not on every row',
    (tester) async {
      await _pump(
        tester,
        course: _course(),
        loadStudents: (_) async => [_student(), _student2()],
      );

      expect(find.textContaining('สมชาย'), findsOneWidget);
      expect(find.textContaining('สมหญิง'), findsOneWidget);
      expect(find.textContaining('ห้อง ม.5/3'), findsOneWidget);
      expect(find.text('นักเรียน 2 คน'), findsOneWidget);
    },
  );
}
