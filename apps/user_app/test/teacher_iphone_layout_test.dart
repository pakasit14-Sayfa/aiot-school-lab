// Phone-width guard for the teacher lane (S3, 2026-09-21): pumps the courses
// list and every course-detail tab at 360/375/390/402 and fails on any
// RenderFlex overflow. Started life as a probe that found 7 sites.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/teacher_redesign_prototype/teacher_assignment_detail_page.dart';
import 'package:my_first_app/pages/teacher_redesign_prototype/teacher_assignment_editor_page.dart';
import 'package:my_first_app/pages/teacher_redesign_prototype/teacher_assignment_form_page.dart';
import 'package:my_first_app/pages/teacher_redesign_prototype/teacher_courses_page.dart';
import 'package:my_first_app/pages/teacher_redesign_prototype/teacher_exam_builder_page.dart';
import 'package:my_first_app/pages/teacher_redesign_prototype/teacher_grading_page.dart';
import 'package:my_first_app/pages/teacher_redesign_prototype/teacher_lesson_editor_page.dart';
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

  // Grading-flow redesign (2026-09-21): list → assignment page → form.
  final asg = AssignmentSummary(
    id: 'a1',
    type: 'worksheet',
    title: 'ใบงานเรื่องเศษส่วนและทศนิยม บทที่ 3 (งานยาวเพื่อทดสอบการตัดบรรทัด)',
    instructions: 'ทำข้อ 1-10',
    dueAt: DateTime(2026, 10, 1, 23, 59),
    status: 'published',
    rubricTitle: 'เกณฑ์การให้คะแนนชิ้นงานทดลองวิทยาศาสตร์',
    submittedCount: 2,
    pendingGradeCount: 1,
    totalStudents: 3,
    datasetCount: 1,
  );
  final students = [
    for (final n in ['หนึ่ง', 'สอง', 'สาม'])
      CourseStudent(
        studentId: 's$n',
        firstName: 'นักเรียนชื่อยาวมาก$n',
        lastName: 'นามสกุลยาวมากเช่นกัน',
        email: '$n@aiot-school-lab.local',
        enrolledAt: DateTime(2026, 9, 1),
      ),
  ];
  final detail = AssignmentDetail(
    id: 'a1',
    courseId: 'c1',
    type: 'worksheet',
    title: asg.title,
    instructions: asg.instructions,
    dueAt: asg.dueAt,
    status: 'published',
    sensorDatasets: [
      AssignmentSensorDataset(
        id: 'ds1',
        deviceId: 'dev1',
        metric: 'temperature',
        timeStart: DateTime(2026, 9, 1, 8),
        timeEnd: DateTime(2026, 9, 5, 16),
        label: 'อุณหภูมิห้องเรียนตลอดสัปดาห์แรกของเดือน',
      ),
    ],
  );
  const course = CourseSummary(
    id: 'c1',
    subjectName: 'คณิตศาสตร์',
    gradeLevel: 'ม.1',
    room: 'ม.1/1',
    status: 'published',
    termId: 't',
  );

  testWidgets('grading list has no overflow at phone widths', (tester) async {
    await _probe(
      tester,
      'grading',
      TeacherGradingPage(
        listMyCourses: () async => const [course],
        listAssignments: (_) async => [
          asg,
          asg.copyWith(status: 'draft'),
          asg.copyWith(dueAt: DateTime(2026, 8, 1)),
        ],
        publishAssignment: (_) async {},
      ),
    );
  });

  testWidgets('assignment page has no overflow at phone widths', (
    tester,
  ) async {
    await _probe(
      tester,
      'assignment',
      TeacherAssignmentDetailPage(
        assignment: asg,
        courseId: 'c1',
        courseName: 'คณิตศาสตร์',
        loadStudents: (_) async => students,
        loadSubmissions: (_) async => const [],
        loadDetail: (_) async => detail,
      ),
    );
  });

  testWidgets('assignment form has no overflow at phone widths', (
    tester,
  ) async {
    await _probe(
      tester,
      'form',
      TeacherAssignmentFormPage(
        courseId: 'c1',
        courseName: 'คณิตศาสตร์',
        existing: asg,
        listMyRubrics: () async => [
          RubricModel(
            id: 'r1',
            title: 'เกณฑ์การให้คะแนนชิ้นงานทดลองวิทยาศาสตร์',
            criteriaCount: 4,
          ),
        ],
        loadAssignmentDetail: (_) async => detail,
        listDevices: () async => const [
          DeviceOption(
            id: 'dev1',
            name: 'เซนเซอร์คุณภาพอากาศห้อง ม.1/1',
            type: 'air_quality_sensor',
            location: 'อาคาร 2 ชั้น 3',
            status: 'online',
          ),
        ],
      ),
    );
  });

  // หน้านี้เคย overflow จริงที่แถบบน (เห็น "OVERFLOWED BY" บนเครื่อง
  // 2026-09-21): แถบบนใส่ปุ่มย้อนกลับ ไอคอน ช่องชื่อบทเรียน ป้ายสถานะบันทึก
  // และปุ่มอีกสองปุ่มไว้บรรทัดเดียว — กันไม่ให้กลับมาอีก
  testWidgets('lesson editor has no overflow at phone widths', (tester) async {
    await _probe(
      tester,
      'lesson editor',
      TeacherLessonEditorPage(
        lesson: LessonModel(
          id: '',
          courseCode: 'MATH101',
          courseName: 'คณิตศาสตร์',
          title: 'รายวิชาทดสอบ',
          status: LessonStatus.published,
          lastEdited: 'เมื่อสักครู่',
          materialsCount: 0,
          sensorChartsCount: 1,
          blocks: [
            ContentBlockModel(
              id: 'b1',
              type: ContentBlockType.heading,
              text: 'รายวิชาทดสอบ',
            ),
            ContentBlockModel(
              id: 'b2',
              type: ContentBlockType.text,
              text: 'เรียงความ ทดสอบ',
            ),
            ContentBlockModel(
              id: 'b3',
              type: ContentBlockType.sensorChart,
              sensorDeviceId: 'เซนเซอร์ห้อง ม.1/1',
              sensorMetric: 'temperature',
              timeRange: '24 ชม.',
            ),
          ],
          materials: const [],
          sensorLinks: const [],
        ),
        listDevices: () async => const <DeviceOption>[],
      ),
    );
  });

  // หน้าดูตัวอย่างเคยล้นขอบขวาจริง (เห็น RIGHT OVERFLOWED บนเครื่อง
  // 2026-09-22): แถบแจ้งเตือนจัดข้อความกึ่งกลางในแถวที่ไม่ยอมตัดบรรทัด
  testWidgets('lesson preview has no overflow at phone widths', (tester) async {
    await _probe(
      tester,
      'lesson preview',
      TeacherLessonPreviewPage(
        lesson: LessonModel(
          id: '',
          courseCode: 'MATH101',
          courseName: 'คณิตศาสตร์',
          title: 'รายวิชาทดสอบ',
          status: LessonStatus.published,
          lastEdited: 'เมื่อสักครู่',
          materialsCount: 0,
          sensorChartsCount: 1,
          blocks: [
            ContentBlockModel(
              id: 'b1',
              type: ContentBlockType.heading,
              text: 'รายวิชาทดสอบ',
            ),
            ContentBlockModel(
              id: 'b2',
              type: ContentBlockType.text,
              text: 'เรียงความ ทดสอบ',
            ),
            // บล็อกกราฟที่ยังไม่ผูกอุปกรณ์ — เคสที่เคยพิมพ์ '()' ออกมา
            ContentBlockModel(id: 'b3', type: ContentBlockType.sensorChart),
            ContentBlockModel(
              id: 'b4',
              type: ContentBlockType.fileDownload,
              materialId: 'm1',
              caption: 'ใบความรู้ที่ต้องอ่านก่อนเข้าคาบเรียนสัปดาห์หน้า',
            ),
            ContentBlockModel(
              id: 'b5',
              type: ContentBlockType.externalLink,
              mediaUrl: 'https://example.invalid/aiot/temperature-lab-guide',
              caption: 'คู่มือการทดลองฉบับเต็ม',
            ),
          ],
          materials: [
            LessonMaterialModel(
              id: 'm1',
              title: 'ใบความรู้เรื่องเซนเซอร์อุณหภูมิในห้องเรียน.pdf',
              type: 'pdf',
              url: 'https://example.invalid/a.pdf',
            ),
          ],
          sensorLinks: [
            LessonSensorLinkModel(
              id: 's1',
              deviceName: 'เซนเซอร์ห้องปฏิบัติการวิทยาศาสตร์ ชั้น 2',
              metric: 'temperature',
              timeRange: '08:00 - 16:00',
              caption: 'อุณหภูมิระหว่างคาบเรียน',
            ),
          ],
        ),
      ),
    );
  });
  // 2026-09-22: เห็น RIGHT OVERFLOWED BY 77 PIXELS ที่แถวชิปสถานะ และ
  // BY 38 PIXELS ที่แถวล่างของการ์ด (ส่งแล้ว x คน / % / ปุ่มแก้ไข+ตรวจงาน)
  testWidgets('assignment editor has no overflow at phone widths', (
    tester,
  ) async {
    await _probe(
      tester,
      'assignment editor',
      TeacherAssignmentEditorPage(
        loadCourses: () async => const [course],
        loadAssignmentsForCourse: (_) async => [
          asg.copyWith(status: 'draft'),
          asg,
        ],
        loadCourseStudents: (_) async => students,
        loadSubmissions: (_) async => const [],
        listMyRubrics: () async => const <RubricModel>[],
        listDevices: () async => const <DeviceOption>[],
        loadAssignmentDetail: (_) async => detail,
      ),
    );
  });

  testWidgets('exam builder has no overflow at phone widths', (tester) async {
    await _probe(
      tester,
      'exam builder',
      TeacherExamBuilderPage(
        courseId: 'c1',
        courseCode: 'fcf029bf',
        courseName: 'คณิตศาสตร์',
        listMyCourses: () async => const [course],
      ),
    );
  });
}
