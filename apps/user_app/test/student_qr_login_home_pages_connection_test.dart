import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/student/course_list_page.dart';
import 'package:my_first_app/pages/student/course_detail_page.dart';
import 'package:my_first_app/pages/student/lesson_view_page.dart';
import 'package:shared_core/shared_core.dart';

/// 3 หน้านี้เคยถูกเข้าใจผิดว่าเป็น dead code (grep หา `pages/student/` ไม่เจอ
/// เพราะ `home_page.dart` import แบบพาธสัมพัทธ์ว่า `'student/course_list_page.dart'`)
/// ของจริงเข้าถึงได้จากโปรดักชัน: `student_qr_login_page` (ล็อกอินด้วย QR จาก
/// แท็บเล็ตในแล็บ) → `pushNamedAndRemoveUntil('/home')` → `HomePage` →
/// `CourseListPage` → `CourseDetailPage` → `LessonViewPage`
///
/// ทั้ง 3 ไฟล์เคยยัดข้อความ exception ดิบ (`$e`) ลงหน้าจอนักเรียนรวม 13 จุด
/// เทสต์ชุดนี้ล็อกไว้ว่าโหลดพัง = ข้อความคงที่ที่อ่านรู้เรื่อง ไม่ใช่ stack trace
void main() {
  Future<void> pumpAndSettleQuick(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  group('CourseListPage (เปิดจากหน้าแรกหลังล็อกอิน QR)', () {
    testWidgets('รายวิชาจริงต้องมาจากหลังบ้าน', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CourseListPage(
            loadCoursesFn: () async => const [
              CourseSummary(
                id: 'c-1',
                subjectName: 'ฟิสิกส์ประยุกต์กับ IoT',
                gradeLevel: 'ม.5',
                room: 'ม.5/3',
                status: 'published',
                termId: 't-1',
              ),
            ],
          ),
        ),
      );
      await pumpAndSettleQuick(tester);

      expect(find.textContaining('ฟิสิกส์ประยุกต์กับ IoT'), findsWidgets);
    });

    testWidgets('โหลดพังต้องไม่โชว์ exception ดิบให้นักเรียนเห็น', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CourseListPage(
            loadCoursesFn: () async =>
                throw Exception('PostgrestException: permission denied'),
          ),
        ),
      );
      await pumpAndSettleQuick(tester);

      expect(
        find.text('โหลดรายวิชาไม่สำเร็จ กรุณาลองใหม่อีกครั้ง'),
        findsOneWidget,
      );
      expect(find.textContaining('PostgrestException'), findsNothing);
      expect(find.textContaining('permission denied'), findsNothing);
    });
  });

  group('LessonViewPage', () {
    LessonDetail lesson() => const LessonDetail(
      id: 'l-1',
      courseId: 'c-1',
      title: 'บทที่ 1: รู้จักเซนเซอร์ PM2.5',
      content: const {'text': 'เนื้อหาบทเรียน'},
      status: 'published',
      publishedAt: null,
      materials: [],
      sensorLinks: [],
      progressPct: 50,
      completed: false,
    );

    testWidgets('โหลดบทเรียนพังต้องไม่โชว์ exception ดิบ', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LessonViewPage(
            lessonId: 'l-1',
            loadLesson: (_) async =>
                throw Exception('StateError: lesson_unreachable'),
          ),
        ),
      );
      await pumpAndSettleQuick(tester);

      expect(
        find.text('โหลดบทเรียนไม่สำเร็จ กรุณาลองใหม่อีกครั้ง'),
        findsOneWidget,
      );
      expect(find.textContaining('lesson_unreachable'), findsNothing);
    });

    testWidgets('กด "เรียนจบแล้ว" ไม่สำเร็จ ต้องบอกว่าไม่สำเร็จ ไม่ใช่เงียบ', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LessonViewPage(
            lessonId: 'l-1',
            loadLesson: (_) async => lesson(),
            markCompleteFn: (_) async =>
                throw Exception('StateError: mark_failed_secret'),
          ),
        ),
      );
      await pumpAndSettleQuick(tester);

      final button = find.textContaining('เรียนจบ');
      expect(button, findsWidgets);
      await tester.tap(button.first);
      await pumpAndSettleQuick(tester);

      expect(
        find.text('บันทึกสถานะไม่สำเร็จ กรุณาลองใหม่อีกครั้ง'),
        findsOneWidget,
      );
      expect(find.textContaining('mark_failed_secret'), findsNothing);
    });
  });

  // CourseDetailPage ครอบด้วย widget test ไม่ได้: หน้านี้ฝัง
  // `model_viewer_plus` ซึ่งต้องมี `WebViewPlatform.instance` จริง เทสต์เลย
  // ล้มตั้งแต่ initState ก่อนถึงข้อความ error ที่อยากตรวจ — ฝั่งข้อความของหน้า
  // นั้นแก้ให้ไม่โชว์ exception ดิบแล้วเหมือนกัน (11 จุด) แต่ยืนยันด้วยเทสต์
  // ไม่ได้จนกว่าจะมี fake WebViewPlatform ให้ใช้
}
