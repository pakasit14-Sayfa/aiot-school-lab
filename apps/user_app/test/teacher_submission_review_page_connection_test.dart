import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/teacher_redesign_prototype/teacher_submission_review_page.dart';
import 'package:shared_core/shared_core.dart';

final _submission = SubmissionRoster(
  submissionId: 'sub-1',
  studentId: 's-1',
  studentFirstName: 'สมชาย',
  studentLastName: 'ใจดี',
  status: 'submitted',
  currentVersion: 1,
  latestContent: 'คำตอบ',
  submittedAt: DateTime(2026, 9, 1),
);

final _rubricSummary = RubricModel(id: 'rubric-1', title: 'เกณฑ์ตรวจงาน');

final _rubricDetail = RubricModel(
  id: 'rubric-1',
  title: 'เกณฑ์ตรวจงาน',
  criteria: [
    RubricCriterionModel(
      id: 'c-1',
      name: 'ความถูกต้อง',
      maxScore: 10,
      sortOrder: 0,
      levels: [
        {'name': 'ดีมาก', 'score': 10, 'description': 'ถูกต้องครบถ้วน'},
        {'name': 'พอใช้', 'score': 5, 'description': 'ถูกบางส่วน'},
      ],
    ),
  ],
);

Future<void> _pump(
  WidgetTester tester, {
  Future<List<SubmissionRoster>> Function(String assignmentId)? listSubmissions,
  Future<List<RubricModel>> Function()? listMyRubrics,
  Future<RubricModel> Function(String rubricId)? getRubric,
  Future<String> Function({
    required String studentId,
    required String courseId,
    required num score,
    required num maxScore,
  })?
  createGrade,
  Future<void> Function(String gradeId)? confirmGrade,
  Future<void> Function({required String submissionId, required String body})?
  giveFeedback,
}) async {
  tester.view.physicalSize = const Size(1200, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: TeacherSubmissionRosterPage(
        assignmentId: 'asg-1',
        courseId: 'course-1',
        worksheetTitle: 'ใบงานทดสอบ',
        courseLabel: 'คณิตศาสตร์ · ม.1/1',
        listSubmissions: listSubmissions ?? (_) async => [_submission],
        listMyRubrics: listMyRubrics ?? () async => [_rubricSummary],
        getRubric: getRubric ?? (_) async => _rubricDetail,
        createGrade: createGrade,
        confirmGrade: confirmGrade,
        giveFeedback: giveFeedback,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'a real submitted roster entry shows the real student name, not fabricated data',
    (tester) async {
      await _pump(tester);
      expect(find.text('สมชาย ใจดี'), findsOneWidget);
      expect(find.text('ตรวจแล้ว 0 / 1 คน'), findsOneWidget);
    },
  );

  testWidgets(
    'scoring a student calls the real createGrade RPC with the real student/course id, then gives feedback',
    (tester) async {
      String? gradedStudentId;
      String? gradedCourseId;
      num? gradedScore;
      String? feedbackSubmissionId;
      String? feedbackBody;
      await _pump(
        tester,
        createGrade:
            ({
              required studentId,
              required courseId,
              required score,
              required maxScore,
            }) async {
              gradedStudentId = studentId;
              gradedCourseId = courseId;
              gradedScore = score;
              return 'grade-1';
            },
        giveFeedback: ({required submissionId, required body}) async {
          feedbackSubmissionId = submissionId;
          feedbackBody = body;
        },
      );

      // Pick the rubric first (required before scoring is enabled).
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('เกณฑ์ตรวจงาน').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('ให้คะแนน'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('ดีมาก'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'ทำได้ดีมาก');
      await tester.pumpAndSettle();
      await tester.tap(find.text('บันทึกคะแนน'));
      await tester.pumpAndSettle();

      expect(gradedStudentId, 's-1');
      expect(gradedCourseId, 'course-1');
      expect(gradedScore, 10.0);
      expect(feedbackSubmissionId, 'sub-1');
      expect(feedbackBody, 'ทำได้ดีมาก');
    },
  );

  testWidgets('zero real submissions shows an honest empty state', (
    tester,
  ) async {
    await _pump(tester, listSubmissions: (_) async => const []);
    expect(find.text('ยังไม่มีนักเรียนส่งงานนี้'), findsOneWidget);
  });

  testWidgets(
    'a real load failure shows an honest error, no leaked exception text',
    (tester) async {
      await _pump(
        tester,
        listSubmissions: (_) async =>
            throw StateError('backend detail that must stay internal'),
      );
      expect(find.text('โหลดรายชื่อนักเรียนไม่สำเร็จ'), findsOneWidget);
      expect(find.textContaining('backend detail'), findsNothing);
    },
  );
}
