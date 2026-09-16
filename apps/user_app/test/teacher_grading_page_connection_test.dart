import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/teacher_redesign_prototype/teacher_grading_page.dart';
import 'package:shared_core/shared_core.dart';

const _course = CourseSummary(
  id: 'course-1',
  subjectName: 'คณิตศาสตร์',
  gradeLevel: 'ม.1',
  room: '101',
  status: 'active',
  termId: 'term-1',
);

final _assignment = AssignmentSummary(
  id: 'asg-1',
  type: 'worksheet',
  title: 'ใบงานเศษส่วน',
  dueAt: DateTime.now().add(const Duration(hours: 5)),
  status: 'published',
);

final _submission = SubmissionRoster(
  submissionId: 'sub-1',
  studentId: 's-1',
  studentFirstName: 'สมชาย',
  studentLastName: 'ใจดี',
  status: 'submitted',
  currentVersion: 1,
  latestContent: null,
  submittedAt: DateTime.now(),
);

Future<void> _pump(
  WidgetTester tester, {
  Future<List<CourseSummary>> Function()? listMyCourses,
  Future<List<AssignmentSummary>> Function(String courseId)? listAssignments,
  Future<List<SubmissionRoster>> Function(String assignmentId)?
  listSubmissions,
  Future<String> Function({
    required String courseId,
    required String type,
    required String title,
    String? instructions,
    DateTime? dueAt,
    String? rubricId,
  })?
  createAssignment,
  Future<void> Function(String assignmentId)? publishAssignment,
}) async {
  tester.view.physicalSize = const Size(1200, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: TeacherGradingPage(
        listMyCourses: listMyCourses ?? () async => [_course],
        listAssignments: listAssignments ?? (_) async => [_assignment],
        listSubmissions: listSubmissions ?? (_) async => [_submission],
        createAssignment: createAssignment,
        publishAssignment: publishAssignment,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'a real published assignment due soon shows the real title/course/room in the urgent bucket',
    (tester) async {
      // Zero submissions so total stays 0, keeping it out of the "ส่งครบแล้ว"
      // bucket (submitted >= total && total > 0) and into "urgent" per its
      // real 5-hour deadline, matching the default _bucketIndex of 0.
      await _pump(tester, listSubmissions: (_) async => const []);
      expect(find.text('ใบงานเศษส่วน'), findsOneWidget);
      expect(find.textContaining('คณิตศาสตร์'), findsOneWidget);
      expect(find.textContaining('ส่งแล้ว 0/0 คน'), findsOneWidget);
    },
  );

  testWidgets(
    'creating a worksheet calls the real createAssignment RPC with the real course id and title, then publishes',
    (tester) async {
      String? sentCourseId;
      String? sentTitle;
      String? publishedId;
      await _pump(
        tester,
        createAssignment:
            ({
              required courseId,
              required type,
              required title,
              instructions,
              dueAt,
              rubricId,
            }) async {
              sentCourseId = courseId;
              sentTitle = title;
              return 'asg-new';
            },
        publishAssignment: (id) async {
          publishedId = id;
        },
      );

      await tester.tap(find.text('สร้างใบงาน'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField),
        'ใบงานทดสอบใหม่',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('สร้างและเผยแพร่'));
      await tester.pumpAndSettle();

      expect(sentCourseId, 'course-1');
      expect(sentTitle, 'ใบงานทดสอบใหม่');
      expect(publishedId, 'asg-new');
    },
  );

  testWidgets(
    'tapping "สร้างใบงาน" with zero real courses warns instead of opening a broken form',
    (tester) async {
      await _pump(tester, listMyCourses: () async => const []);
      await tester.tap(find.text('สร้างใบงาน'));
      await tester.pumpAndSettle();
      expect(
        find.text('ยังไม่มีรายวิชาที่สอนอยู่ ไม่สามารถสร้างใบงานได้'),
        findsOneWidget,
      );
    },
  );

  testWidgets('a real load failure shows an honest error, no leaked exception text', (
    tester,
  ) async {
    await _pump(
      tester,
      listMyCourses: () async =>
          throw StateError('backend detail that must stay internal'),
    );
    expect(find.text('โหลดใบงานไม่สำเร็จ'), findsOneWidget);
    expect(find.textContaining('backend detail'), findsNothing);
  });

  testWidgets('"เผยแพร่" on a draft calls publish_assignment and re-reads the list', (
    tester,
  ) async {
    var published = false;
    final draft = AssignmentSummary(
      id: 'asg-draft',
      type: 'worksheet',
      title: 'ใบงานฉบับร่าง',
      dueAt: DateTime.now().add(const Duration(days: 1)),
      status: 'draft',
    );
    await _pump(
      tester,
      listAssignments: (_) async => [
        AssignmentSummary(
          id: draft.id,
          type: draft.type,
          title: draft.title,
          dueAt: draft.dueAt,
          status: published ? 'published' : 'draft',
        ),
      ],
      listSubmissions: (_) async => const [],
      publishAssignment: (id) async {
        expect(id, 'asg-draft');
        published = true;
      },
    );
    // Draft bucket is the last tab; the card's primary button reads เผยแพร่.
    await tester.tap(find.text('ร่าง').first);
    await tester.pumpAndSettle();
    // FilledButton.icon is a private subclass — match by ButtonStyleButton.
    final button = find.ancestor(
      of: find.text('เผยแพร่'),
      matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
    );
    expect(button, findsOneWidget);
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(published, isTrue);
    expect(find.textContaining('UI Prototype'), findsNothing);
    expect(find.text('เผยแพร่ "ใบงานฉบับร่าง" แล้ว'), findsOneWidget);
  });

  testWidgets('a publish that the backend does not confirm is reported as failed', (
    tester,
  ) async {
    await _pump(
      tester,
      listAssignments: (_) async => [
        AssignmentSummary(
          id: 'asg-draft',
          type: 'worksheet',
          title: 'ใบงานฉบับร่าง',
          dueAt: DateTime.now().add(const Duration(days: 1)),
          status: 'draft',
        ),
      ],
      listSubmissions: (_) async => const [],
      publishAssignment: (_) async {}, // "succeeds" but nothing changes
    );
    await tester.tap(find.text('ร่าง').first);
    await tester.pumpAndSettle();
    await tester.tap(
      find.ancestor(
        of: find.text('เผยแพร่'),
        matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('เผยแพร่ไม่สำเร็จ ใบงานยังเป็นฉบับร่าง'), findsOneWidget);
    expect(find.textContaining('เผยแพร่ "ใบงานฉบับร่าง" แล้ว'), findsNothing);
  });
}
