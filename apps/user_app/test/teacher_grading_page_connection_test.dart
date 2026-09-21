import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/teacher_redesign_prototype/teacher_grading_page.dart';
import 'package:shared_core/shared_core.dart';

/// ตรวจงาน (redesigned 2026-09-21): rows come from list_my_courses ×
/// list_assignments, counts are the RPC's own numbers, publish on a draft
/// reaches publish_assignment and is only reported as done when the
/// re-read shows it published.
const _course = CourseSummary(
  id: 'course-1',
  subjectName: 'คณิตศาสตร์',
  gradeLevel: 'ม.1',
  room: 'ม.1/1',
  status: 'active',
  termId: 'term-1',
);

AssignmentSummary _asg({
  String id = 'a1',
  String title = 'ใบงานเศษส่วน',
  String status = 'published',
  DateTime? dueAt,
  int submitted = 0,
  int pending = 0,
  int total = 3,
}) => AssignmentSummary(
  id: id,
  type: 'worksheet',
  title: title,
  dueAt: dueAt,
  status: status,
  submittedCount: submitted,
  pendingGradeCount: pending,
  totalStudents: total,
);

Future<void> _pump(
  WidgetTester tester, {
  required Future<List<CourseSummary>> Function() listMyCourses,
  required Future<List<AssignmentSummary>> Function(String) listAssignments,
  Future<void> Function(String)? publishAssignment,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: TeacherGradingPage(
        listMyCourses: listMyCourses,
        listAssignments: listAssignments,
        publishAssignment: publishAssignment ?? (_) async {},
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('rows show the RPC counts, not a placeholder', (tester) async {
    await _pump(
      tester,
      listMyCourses: () async => const [_course],
      listAssignments: (_) async => [
        _asg(
          dueAt: DateTime.now().add(const Duration(days: 3)),
          submitted: 1,
          pending: 1,
        ),
      ],
    );
    expect(find.text('ใบงานเศษส่วน'), findsOneWidget);
    expect(find.textContaining('ส่ง 1/3'), findsOneWidget);
    expect(find.textContaining('รอตรวจ 1'), findsWidgets); // chip + row
    expect(find.textContaining('0/0'), findsNothing);
  });

  testWidgets('overdue published work is grouped first under เลยกำหนดส่ง', (
    tester,
  ) async {
    await _pump(
      tester,
      listMyCourses: () async => const [_course],
      listAssignments: (_) async => [
        _asg(
          id: 'late',
          title: 'งานเก่า',
          dueAt: DateTime.now().subtract(const Duration(days: 20)),
        ),
        _asg(
          id: 'open',
          title: 'งานใหม่',
          dueAt: DateTime.now().add(const Duration(days: 2)),
        ),
        _asg(id: 'draft', title: 'งานร่าง', status: 'draft'),
      ],
    );
    expect(find.text('เลยกำหนดส่ง'), findsOneWidget);
    expect(find.text('กำลังเปิดรับ'), findsOneWidget);
    expect(find.text('ฉบับร่าง'), findsOneWidget);
    expect(find.textContaining('เลย 20 วัน'), findsOneWidget);
    // the "ด่วน/ปกติ/ส่งครบแล้ว/ร่าง" 4-tile block and the create button are gone
    expect(find.text('ด่วน'), findsNothing);
    expect(find.text('สร้างใบงาน'), findsNothing);
  });

  testWidgets(
    'a real load failure shows an honest error, no leaked exception text',
    (tester) async {
      await _pump(
        tester,
        listMyCourses: () async => throw Exception('backend detail'),
        listAssignments: (_) async => const [],
      );
      expect(find.text('โหลดใบงานไม่สำเร็จ'), findsOneWidget);
      expect(find.textContaining('backend detail'), findsNothing);
    },
  );

  testWidgets(
    '"เผยแพร่" on a draft calls publish_assignment and re-reads the list',
    (tester) async {
      var published = false;
      String? publishedId;
      await _pump(
        tester,
        listMyCourses: () async => const [_course],
        listAssignments: (_) async => [
          _asg(
            id: 'd1',
            title: 'ใบงานฉบับร่าง',
            status: published ? 'published' : 'draft',
          ),
        ],
        publishAssignment: (id) async {
          publishedId = id;
          published = true;
        },
      );
      await tester.tap(find.text('เผยแพร่'));
      await tester.pumpAndSettle();
      expect(publishedId, 'd1');
      expect(find.text('เผยแพร่ "ใบงานฉบับร่าง" แล้ว'), findsOneWidget);
      expect(
        find.text('ฉบับร่าง'),
        findsNothing,
      ); // moved out of drafts after re-read
    },
  );

  testWidgets(
    'a publish that the backend does not confirm is reported as failed',
    (tester) async {
      await _pump(
        tester,
        listMyCourses: () async => const [_course],
        listAssignments: (_) async => [
          _asg(id: 'd1', title: 'ใบงานฉบับร่าง', status: 'draft'),
        ],
        publishAssignment: (_) async {}, // silently does nothing
      );
      await tester.tap(find.text('เผยแพร่'));
      await tester.pumpAndSettle();
      expect(
        find.text('เผยแพร่ไม่สำเร็จ ใบงานยังเป็นฉบับร่าง'),
        findsOneWidget,
      );
      expect(find.textContaining('แล้ว'), findsNothing);
    },
  );
}
