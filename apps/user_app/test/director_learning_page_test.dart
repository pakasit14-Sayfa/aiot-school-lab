import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/executive_redesign_prototype/pages/director_learning_page.dart';
import 'package:my_first_app/pages/executive_redesign_prototype/controllers/director_learning_controller.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_core/models/school_homeroom_attendance.dart';

const summary = ClassroomsOverviewItem(
  roomCount: 2,
  courseCount: 4,
  activeStudentCount: 3,
  assignmentsDueThisWeek: 1,
);
const empty = ClassroomsOverviewItem(
  roomCount: 0,
  courseCount: 0,
  activeStudentCount: 0,
  assignmentsDueThisWeek: 0,
);
const attendance = [
  SchoolHomeroomAttendance(
    gradeLevel: 'ม.1',
    room: '1',
    studentCount: 2,
    present: 1,
    late: 0,
    absent: 0,
    excused: 0,
    unknown: 1,
  ),
  SchoolHomeroomAttendance(
    gradeLevel: 'ม.2',
    room: '1',
    studentCount: 1,
    present: 0,
    late: 0,
    absent: 0,
    excused: 0,
    unknown: 1,
  ),
];
DirectorLearningController fixture({
  Future<ClassroomsOverviewItem?> Function()? overview,
  Future<List<SchoolHomeroomAttendance>> Function(DateTime)? loadAttendance,
}) => DirectorLearningController(
  overview: overview ?? () async => summary,
  tracks: () async => const [
    LearningTrackOverview(
      trackId: 't1',
      name: 'สายจริง',
      color: '#112233',
      sortOrder: 0,
      studentCount: 2,
      roomCount: 1,
    ),
  ],
  rooms: () async => const [
    LearningTrackRoom(
      gradeLevel: 'ม.1',
      room: '1',
      studentCount: 2,
      trackId: 't1',
      trackName: 'สายจริง',
    ),
  ],
  attendance: loadAttendance ?? (_) async => attendance,
  cases: () async => [],
  interventions: (_) async => [],
);
Widget page(DirectorLearningController controller) => MaterialApp(
  home: Scaffold(body: DirectorLearningPage(controller: controller)),
);

void main() {
  testWidgets(
    'loading, error, retry and empty are distinct without fabricated totals',
    (tester) async {
      final pending = Completer<ClassroomsOverviewItem?>();
      var attempt = 0;
      final controller = DirectorLearningController(
        overview: () => ++attempt == 1 ? pending.future : Future.value(empty),
        tracks: () async => [],
        rooms: () async => [],
        attendance: (_) async => [],
        cases: () async => [],
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(page(controller));
      expect(find.text('กำลังโหลดข้อมูลนักเรียน'), findsOneWidget);
      expect(find.text('ภาพรวมปัจจุบันของโรงเรียน'), findsNothing);
      pending.completeError(StateError('private diagnostic'));
      await tester.pumpAndSettle();
      expect(find.text('โหลดข้อมูลไม่สำเร็จ'), findsOneWidget);
      expect(find.textContaining('private diagnostic'), findsNothing);
      await tester.tap(find.text('ลองอีกครั้ง'));
      await tester.pumpAndSettle();
      expect(find.text('ยังไม่มีข้อมูลนักเรียนหรือการเรียน'), findsOneWidget);
    },
  );
  testWidgets(
    'real counts, unknown attendance, missing grades and effective filters',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = fixture();
      addTearDown(controller.dispose);
      await tester.pumpWidget(page(controller));
      await tester.pumpAndSettle();
      expect(find.text('3 คน'), findsOneWidget);
      expect(
        find.text('มา 1 · สาย 0 · ขาด 0 · ลา 0 · ยังไม่เช็คชื่อ 1'),
        findsOneWidget,
      );
      expect(find.text('ยังไม่มีข้อมูลการเช็คชื่อ'), findsOneWidget);
      expect(find.text('ยังไม่มีคะแนนที่ยืนยันแล้ว'), findsOneWidget);
      expect(find.textContaining('1,248'), findsNothing);
      await tester.tap(find.widgetWithText(ChoiceChip, 'ม.2'));
      await tester.pumpAndSettle();
      expect(find.text('ม.1/1 · 2 คน'), findsNothing);
      expect(find.text('ม.2/1 · 1 คน'), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, 'สายจริง'));
      await tester.pumpAndSettle();
      expect(find.text('ยังไม่มีข้อมูลนักเรียนในตัวกรองนี้'), findsOneWidget);
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'สั่งการติดตาม'),
            )
            .onPressed,
        isNull,
      );
    },
  );
  test('switching date discards late results from the earlier date', () async {
    final old = Completer<List<SchoolHomeroomAttendance>>();
    final controller = fixture(
      loadAttendance: (date) => date.day == 1 ? old.future : Future.value([]),
    );
    addTearDown(controller.dispose);
    final first = controller.load(onDate: DateTime(2026, 9, 1));
    await controller.load(onDate: DateTime(2026, 9, 2));
    old.complete(attendance);
    await first;
    expect(controller.date, DateTime(2026, 9, 2));
    expect(controller.attendance, isEmpty);
  });
  testWidgets('responsive at 320, 390, 768 and 1440 pixels', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = fixture();
    addTearDown(controller.dispose);
    await tester.pumpWidget(page(controller));
    for (final size in [
      const Size(320, 568),
      const Size(390, 844),
      const Size(768, 1024),
      const Size(1440, 900),
    ]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'Layout at $size');
    }
  });
}
