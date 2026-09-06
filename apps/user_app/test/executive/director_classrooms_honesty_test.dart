import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/executive_redesign_prototype/pages/director_classrooms_page.dart';
import 'package:shared_core/shared_core.dart';

/// One real call — `getClassroomsOverview` for three summary tiles — sat on
/// top of a school that did not exist: a 205-line const list of classrooms,
/// each with a homeroom teacher's name, an attendance percentage, and
/// learning, behaviour and environment scores; a Green Score leaderboard
/// ranking those rooms against each other; per-room assignment lists with
/// invented teachers and titles; subject scores computed as
/// `base + (learningScore - 92)`; and a "สิ่งที่ผู้อำนวยการควรติดตาม" card
/// that turned all of it into recommended actions.
///
/// Room, grade, track, homeroom teacher, student count and the next period
/// are real and executive-readable, so those are wired. The scores are not
/// merely unwired — behaviour, environment and green scores have no source
/// table and no formula anywhere in the project.

HomeroomAssignment _homeroom({
  required String grade,
  required String room,
  String? teacher,
  int students = 30,
}) => HomeroomAssignment(
  assignmentId: 'as-$grade-$room',
  gradeLevel: grade,
  room: room,
  teacherId: teacher == null ? null : 't-$teacher',
  teacherName: teacher,
  studentCount: students,
);

Future<void> _pump(
  WidgetTester tester, {
  List<HomeroomAssignment>? homerooms,
  List<LearningTrackRoom>? tracks,
  List<SchoolScheduleItem>? schedules,
  bool fail = false,
}) async {
  tester.view.physicalSize = const Size(1500, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: DirectorClassroomsPage(
          loadOverview: () async {
            if (fail) throw StateError('classrooms_unreachable');
            return null;
          },
          loadHomerooms: () async => homerooms ?? const <HomeroomAssignment>[],
          loadTrackRooms: () async => tracks ?? const <LearningTrackRoom>[],
          loadSchedules: () async => schedules ?? const <SchoolScheduleItem>[],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the invented school is gone', (tester) async {
    await _pump(tester);

    for (final invented in <String>[
      'ครูจิราพร ตั้งใจ',
      'ครูพรทิพย์ รักษ์ดี',
      'Reading Reflection: My School Life',
      'ผลการเรียนต่ำกว่าเกณฑ์',
      'ขาดเรียนต่อเนื่อง',
      'สภาพแวดล้อมในห้อง',
      'ภาพรวมการเรียนของห้องอยู่ในเกณฑ์ดี',
      'คนมีงานที่ยังไม่ส่ง',
      'หากต่ำกว่า 92%',
    ]) {
      expect(
        find.textContaining(invented),
        findsNothing,
        reason: 'ยังพบของที่แต่งขึ้น: $invented',
      );
    }
  });

  testWidgets('rooms come from the homeroom assignments', (tester) async {
    await _pump(
      tester,
      homerooms: [
        _homeroom(grade: 'ม.1', room: '1', teacher: 'ครูทดสอบ ก', students: 28),
        _homeroom(grade: 'ม.2', room: '3', students: 31),
      ],
      tracks: [
        LearningTrackRoom(
          gradeLevel: 'ม.1',
          room: '1',
          studentCount: 28,
          trackId: 'tr-1',
          trackName: 'วิทย์-คณิต',
        ),
      ],
    );

    expect(find.textContaining('ม.1/1'), findsWidgets);
    expect(find.textContaining('ม.2/3'), findsWidgets);
    expect(find.textContaining('ครูทดสอบ ก'), findsWidgets);
    // A room with no homeroom teacher says so rather than borrowing a name.
    expect(find.textContaining('ยังไม่มีครูประจำชั้น'), findsWidgets);
    // A room outside the track map is not assigned one.
    expect(find.textContaining('ยังไม่ระบุสาย'), findsWidgets);
    expect(find.textContaining('วิทย์-คณิต'), findsWidgets);
  });

  testWidgets('no homerooms means no rooms, not a demo school', (
    tester,
  ) async {
    await _pump(tester);

    for (final invented in <String>['ม.6/1', 'ม.3/2', 'ม.4/1']) {
      expect(find.textContaining(invented), findsNothing, reason: invented);
    }
  });

  testWidgets('the green score leaderboard is an honest gap', (tester) async {
    await _pump(tester);

    expect(
      find.textContaining('ยังไม่มีเกณฑ์และข้อมูลสำหรับจัดอันดับห้องเรียน'),
      findsOneWidget,
    );
    // The section heading survives; what must not is a per-room verdict.
    expect(
      find.textContaining('ยังไม่มีข้อมูลรายห้องสำหรับการมาเรียน'),
      findsNothing,
    );
    expect(find.text('96'), findsNothing);
  });

  testWidgets('a failed overview does not print invented totals', (
    tester,
  ) async {
    await _pump(tester, fail: true);

    // The three tiles used to fall back to '36', '1,248' and '64'.
    for (final invented in <String>['36', '1,248', '64']) {
      expect(find.text(invented), findsNothing, reason: invented);
    }
    expect(find.textContaining('classrooms_unreachable'), findsNothing);
  });
}
