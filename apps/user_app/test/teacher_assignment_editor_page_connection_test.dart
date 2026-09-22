import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/teacher_redesign_prototype/teacher_assignment_editor_page.dart';
import 'package:shared_core/shared_core.dart';

/// This file had two real bugs fixed this session: submittedCount/rubric
/// were invented rather than fetched, and editing an assignment always
/// saved against courses.first.id instead of the assignment's own real
/// course — a teacher with 2+ courses could silently move an assignment
/// to the wrong one. These tests pin both down.

const _courseA = CourseSummary(
  id: 'course-a',
  subjectName: 'คณิตศาสตร์',
  gradeLevel: 'ม.1',
  room: '101',
  status: 'active',
  termId: 'term-1',
);
const _courseB = CourseSummary(
  id: 'course-b',
  subjectName: 'วิทยาศาสตร์',
  gradeLevel: 'ม.1',
  room: '102',
  status: 'active',
  termId: 'term-1',
);

const _assignmentInB = AssignmentSummary(
  id: 'asg-1',
  type: 'homework',
  title: 'แบบฝึกหัดวิทยาศาสตร์',
  dueAt: null,
  status: 'published',
);

final _roster = [
  CourseStudent(
    studentId: 's1',
    firstName: 'สมชาย',
    lastName: 'ใจดี',
    email: 'a@test',
    enrolledAt: DateTime(2026, 1, 1),
  ),
  CourseStudent(
    studentId: 's2',
    firstName: 'สมหญิง',
    lastName: 'ใจงาม',
    email: 'b@test',
    enrolledAt: DateTime(2026, 1, 1),
  ),
];

final _submissions = [
  SubmissionRoster(
    submissionId: 'sub-1',
    studentId: 's1',
    studentFirstName: 'สมชาย',
    studentLastName: 'ใจดี',
    status: 'submitted',
    currentVersion: 1,
    latestContent: 'ทำเสร็จแล้ว',
    submittedAt: DateTime(2026, 9, 1),
    latestAttachments: [],
  ),
];

Future<void> _pump(
  WidgetTester tester, {
  Future<List<CourseSummary>> Function()? loadCourses,
  Future<List<AssignmentSummary>> Function(String courseId)?
  loadAssignmentsForCourse,
  Future<List<CourseStudent>> Function(String courseId)? loadCourseStudents,
  Future<List<SubmissionRoster>> Function(String assignmentId)? loadSubmissions,
  Future<List<RubricModel>> Function()? listMyRubrics,
  Future<void> Function({
    required String assignmentId,
    String? title,
    String? instructions,
    DateTime? dueAt,
    String? rubricId,
    bool? isGroup,
  })?
  updateAssignment,
  Future<void> Function(String assignmentId)? publishAssignment,
}) async {
  tester.view.physicalSize = const Size(1400, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: TeacherAssignmentEditorPage(
        loadCourses: loadCourses ?? () async => const [_courseB],
        loadAssignmentsForCourse:
            loadAssignmentsForCourse ?? (_) async => const [_assignmentInB],
        loadCourseStudents: loadCourseStudents ?? (_) async => _roster,
        loadSubmissions: loadSubmissions ?? (_) async => _submissions,
        listMyRubrics: listMyRubrics ?? () async => const [],
        updateAssignment: updateAssignment,
        publishAssignment: publishAssignment,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'submittedCount/totalStudents come from the real roster and submissions, not invented numbers',
    (tester) async {
      await _pump(tester);
      // 1 real submission out of 2 real roster students, not the old
      // hardcoded 0/30. ถ้อยคำเปลี่ยนเป็น 'ส่งแล้ว 1 จาก 2 คน' ตอน
      // ออกแบบการ์ดใหม่ 2026-09-22 — สิ่งที่เทสต์นี้ตรึงคือตัวเลขมาจาก
      // ข้อมูลจริง ไม่ใช่รูปประโยค
      // แถวแสดงเป็น '1/2' ตอนเปลี่ยนจากการ์ดเป็นแถว — ที่ตรึงคือตัวเลข
      // มาจาก roster และ submissions จริง ไม่ใช่รูปประโยค
      expect(find.text('1/2'), findsOneWidget);
    },
  );

  testWidgets(
    'editing an assignment calls updateAssignment with the real assignment id, and never re-derives the course from courses.first',
    (tester) async {
      String? updatedId;
      String? updatedRubricId;
      bool? updatedIsGroup;
      DateTime? updatedDueAt;
      var loadCoursesCalledDuringEdit = false;
      var publishCalls = 0;

      await _pump(
        tester,
        // courses.first would be course-a here if the edit path ever
        // wrongly fell back to it instead of assignment.courseId.
        loadCourses: () async {
          loadCoursesCalledDuringEdit = true;
          return const [_courseA, _courseB];
        },
        listMyRubrics: () async => [
          RubricModel(id: 'r-1', title: 'เกณฑ์วิทย์', usedCount: 0),
        ],
        loadAssignmentsForCourse: (_) async => updatedId == null
            ? [_assignmentInB]
            : [
                AssignmentSummary(
                  id: 'asg-1',
                  type: 'homework',
                  title: _assignmentInB.title,
                  dueAt: updatedDueAt,
                  status: 'published',
                  rubricId: updatedRubricId,
                  isGroup: updatedIsGroup!,
                  rubricTitle: 'เกณฑ์วิทย์',
                ),
              ],
        updateAssignment:
            ({
              required assignmentId,
              title,
              instructions,
              dueAt,
              rubricId,
              isGroup,
            }) async {
              updatedId = assignmentId;
              updatedRubricId = rubricId;
              updatedIsGroup = isGroup;
              updatedDueAt = dueAt;
            },
        publishAssignment: (assignmentId) async {
          publishCalls++;
        },
      );

      // Initial page load already calls loadCourses once for the list —
      // reset before the edit interaction so only the edit path counts.
      loadCoursesCalledDuringEdit = false;

      // แก้ไขย้ายเข้าเมนู ⋯ ตอนเปลี่ยนการ์ดเป็นแถว 2026-09-22 —
      // สิ่งที่เทสต์นี้ตรึงคือกดแก้ไขแล้วต้องส่ง assignment id จริงไป
      // ไม่ใช่ตำแหน่งของปุ่ม
      await tester.tap(find.byIcon(Icons.more_horiz_rounded).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('แก้ไขใบงาน').last);
      await tester.pumpAndSettle();

      // Pick the real rubric from the dropdown (previously discarded
      // silently — dropdown had 4 hardcoded fake choices sent nowhere).
      // ชีตแก้ไขใบงานถูกยุบเข้าหน้าฟอร์มเต็มจอ 2026-09-22 — แถวเกณฑ์ของ
      // หน้าฟอร์มแสดงค่า 'ไม่ใช้' เมื่อยังไม่ได้ผูกเกณฑ์
      // ที่เทสต์นี้ตรึงคือเกณฑ์ที่เลือกต้องถูกส่งเป็น rubricId จริง
      await tester.tap(find.text('ไม่ใช้'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('เกณฑ์วิทย์').last);
      await tester.pumpAndSettle();

      // PBL-10: flip "งานกลุ่ม" — until 2026-09-18 this toggle never
      // reached the backend.
      await tester.tap(find.byType(Switch).first);
      // วันที่เป็นแถวเปิดชีตเลือก — เปิดแล้วกดเสร็จ
      await tester.tap(find.text('ยังไม่กำหนด'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('เสร็จ'));
      await tester.pumpAndSettle();
      // หน้าฟอร์ม: ใบงานที่เผยแพร่แล้วปุ่มหลักคือ 'บันทึก' (ไม่ต้อง
      // เผยแพร่ซ้ำ) ส่วนใบงานร่างคือ 'มอบหมายให้นักเรียน'
      // ตรวจก่อนกดบันทึก — หลังบันทึกเสร็จหน้ารายการจะรีเฟรชตัวเอง
      // ซึ่งเรียก loadCourses โดยชอบธรรม ไม่ใช่การเดาวิชาให้ตอนแก้ไข
      final derivedCourseWhileEditing = loadCoursesCalledDuringEdit;

      await tester.tap(find.text('บันทึก'));
      await tester.pumpAndSettle();

      expect(updatedId, 'asg-1');
      expect(updatedRubricId, 'r-1');
      expect(updatedIsGroup, isTrue);
      // ใบงานนี้เผยแพร่อยู่แล้ว การกดบันทึกจึงต้องไม่สั่งเผยแพร่ซ้ำ —
      // เดิมชีตเรียก publish ทุกครั้งที่บันทึกใบงานที่เผยแพร่แล้ว
      expect(publishCalls, 0);
      expect(updatedDueAt, isNotNull);
      expect(find.textContaining('เรียบร้อยแล้ว'), findsOneWidget);
      expect(
        derivedCourseWhileEditing,
        false,
        reason:
            'editing must use assignment.courseId directly, never re-derive '
            'the course from courses.first',
      );
    },
  );
}
