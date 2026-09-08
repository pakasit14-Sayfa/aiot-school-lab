import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/models/school_homeroom_attendance.dart';
import 'package:my_first_app/pages/executive_redesign_prototype/controllers/classroom_attendance_controller.dart';
import 'package:my_first_app/pages/executive_redesign_prototype/widgets/classroom_attendance_card.dart';

SchoolHomeroomAttendance row(
  String grade, {
  int present = 0,
  int unknown = 5,
}) => SchoolHomeroomAttendance(
  gradeLevel: grade,
  room: '1',
  studentCount: 5,
  present: present,
  late: 0,
  absent: 0,
  excused: 0,
  unknown: unknown,
);

void main() {
  testWidgets('loading then empty stays distinct from zero attendance', (
    tester,
  ) async {
    final pending = Completer<List<SchoolHomeroomAttendance>>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ClassroomAttendanceCard(
            controller: ClassroomAttendanceController(
              grade: 'ม.1',
              room: '1',
              loader: (_) => pending.future,
            ),
          ),
        ),
      ),
    );
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    pending.complete([]);
    await tester.pumpAndSettle();
    expect(find.text('ยังไม่มีข้อมูลกลุ่มนักเรียนของห้องนี้'), findsOneWidget);
    expect(find.textContaining('0.0%'), findsNothing);
  });

  testWidgets(
    'same room number in another grade cannot replace unknown attendance',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClassroomAttendanceCard(
              controller: ClassroomAttendanceController(
                grade: 'ม.1',
                room: '1',
                loader: (_) async => [
                  row('ม.2', present: 5, unknown: 0),
                  row('ม.1'),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('ยังไม่เช็คชื่อ 5'), findsOneWidget);
      expect(find.text('มา 0'), findsOneWidget);
      expect(find.textContaining('100.0%'), findsNothing);
      expect(
        find.text('ยังไม่มีผลเช็คชื่อสำหรับคำนวณอัตรามาเรียน'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'failure can retry and counts only recorded students in percentage',
    (tester) async {
      var fail = true;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClassroomAttendanceCard(
              controller: ClassroomAttendanceController(
                grade: 'ม.1',
                room: '1',
                loader: (_) async {
                  if (fail) throw StateError('raw_private_error');
                  return [row('ม.1', present: 2, unknown: 3)];
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('โหลดข้อมูลเช็คชื่อไม่สำเร็จ'),
        findsOneWidget,
      );
      expect(find.textContaining('raw_private_error'), findsNothing);
      fail = false;
      await tester.tap(find.text('โหลดใหม่'));
      await tester.pumpAndSettle();
      expect(
        find.text('อัตรามาเรียน 100.0% จากผู้ที่เช็คชื่อแล้ว 2 คน'),
        findsOneWidget,
      );
      expect(find.text('ยังไม่เช็คชื่อ 3'), findsOneWidget);
    },
  );

  test('changing date ignores an earlier slower response', () async {
    final first = Completer<List<SchoolHomeroomAttendance>>();
    final second = Completer<List<SchoolHomeroomAttendance>>();
    var calls = 0;
    final c = ClassroomAttendanceController(
      grade: 'ม.1',
      room: '1',
      loader: (_) => calls++ == 0 ? first.future : second.future,
    );
    final a = c.load(DateTime(2026, 9, 7));
    final b = c.load(DateTime(2026, 9, 8));
    second.complete([row('ม.1', present: 5, unknown: 0)]);
    await b;
    first.complete([row('ม.1')]);
    await a;
    expect(c.data!.present, 5);
    expect(c.date, DateTime(2026, 9, 8));
    c.dispose();
  });
}
