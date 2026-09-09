import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/teacher_redesign_prototype/teacher_courses_page.dart';
import 'package:shared_core/shared_core.dart';

/// หน้ารายวิชาของครูเคยมีลิสต์ระดับโมดูล `mockTeacherCourses` ที่ seed รายวิชา
/// ปลอมไว้ 6 ตัว (ว31281 "วิทยาการคำนวณ & AI เบื้องต้น" 82 คน ฯลฯ) รายการนี้
/// ถูกทับด้วยของจริงเฉพาะตอนโหลดสำเร็จ และหน้ารายละเอียดวิชายังหยิบตัวแรกของ
/// ลิสต์มาแสดงผ่าน fallback `?? .first` ได้ตลอด เทสต์ชุดนี้ล็อกไว้ว่าไม่มี
/// รายวิชาที่ไม่ได้มาจากหลังบ้านโผล่บนจอในสถานะไหนเลย
void main() {
  Future<void> pumpPage(
    WidgetTester tester, {
    required Future<List<CourseSummary>> Function() loadCourses,
  }) async {
    tester.view.physicalSize = const Size(1400, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: TeacherCoursesPage(
          loadCourses: loadCourses,
          loadCourseStudents: (_) async => <CourseStudent>[],
        ),
      ),
    );
  }

  void expectNoSeededCourses() {
    expect(find.textContaining('วิทยาการคำนวณ & AI เบื้องต้น'), findsNothing);
    expect(find.textContaining('ว31281'), findsNothing);
  }

  testWidgets('ครูที่ยังไม่มีรายวิชาจริงต้องไม่เห็นรายวิชาปลอม', (tester) async {
    await pumpPage(tester, loadCourses: () async => <CourseSummary>[]);
    await tester.pump();

    expectNoSeededCourses();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('โหลดพังต้องขึ้นข้อความผิดพลาด ไม่ใช่รายวิชาปลอม และไม่โชว์ error ดิบ', (
    tester,
  ) async {
    await pumpPage(
      tester,
      loadCourses: () async => throw Exception('PostgrestException: boom'),
    );
    await tester.pump();

    expectNoSeededCourses();
    expect(find.text('โหลดรายวิชาไม่สำเร็จ กรุณาลองใหม่อีกครั้ง'), findsOneWidget);
    // ข้อความ exception ดิบต้องไม่หลุดขึ้นจอ
    expect(find.textContaining('PostgrestException'), findsNothing);
    expect(find.text('ลองใหม่'), findsOneWidget);
  });

  testWidgets('ระหว่างโหลดต้องเป็นสถานะกำลังโหลด ไม่ใช่รายวิชาปลอมค้างจอ', (
    tester,
  ) async {
    await pumpPage(
      tester,
      loadCourses: () => Future<List<CourseSummary>>.delayed(
        const Duration(seconds: 1),
        () => <CourseSummary>[],
      ),
    );
    await tester.pump();

    expectNoSeededCourses();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expectNoSeededCourses();
  });

  testWidgets('รายวิชาที่แสดงต้องมาจากหลังบ้านล้วน', (tester) async {
    await pumpPage(
      tester,
      loadCourses: () async => [
        const CourseSummary(
          id: 'course-real-1',
          subjectName: 'ฟิสิกส์ประยุกต์กับ IoT',
          gradeLevel: 'ม.5',
          room: 'ม.5/3',
          status: 'published',
          termId: 'term-1',
        ),
      ],
    );
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('ฟิสิกส์ประยุกต์กับ IoT'), findsWidgets);
    expectNoSeededCourses();
  });

  testWidgets('เปิดหน้ารายละเอียดวิชาโดยไม่มีวิชาต้องบอกตรง ๆ ไม่ใช่โชว์วิชาปลอม', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: TeacherCourseDetailPage()),
    );
    await tester.pump();

    expect(
      find.text('ยังไม่มีข้อมูลรายวิชา — กรุณาเปิดจากรายการรายวิชาของคุณ'),
      findsOneWidget,
    );
    expectNoSeededCourses();
  });
}
