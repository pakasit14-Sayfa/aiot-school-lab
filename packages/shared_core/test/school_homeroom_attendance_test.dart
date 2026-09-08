import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/models/school_homeroom_attendance.dart';

void main() {
  test('room labels already containing the grade are not duplicated', () {
    SchoolHomeroomAttendance row(String room) => SchoolHomeroomAttendance(
      gradeLevel: 'ม.4',
      room: room,
      studentCount: 1,
      present: 0,
      late: 0,
      absent: 0,
      excused: 0,
      unknown: 1,
    );
    expect(row('ม.4/1').roomLabel, 'ม.4/1');
    expect(row('1').roomLabel, 'ม.4/1');
  });
  test(
    'unrecorded students never become present or absent or a zero percent attendance',
    () {
      final data = SchoolHomeroomAttendance.fromRow({
        'student_count': 2,
        'present_count': 0,
        'late_count': 0,
        'absent_count': 0,
        'excused_count': 0,
        'unknown_count': 2,
      });
      expect(data.recorded, 0);
      expect(data.attendancePercent, isNull);
      expect(data.unknown, 2);
      expect(data.roomLabel, 'ยังไม่ระบุชั้น / ห้อง');
    },
  );
  test(
    'incomplete aggregate is rejected instead of showing a fabricated zero',
    () {
      expect(
        () => SchoolHomeroomAttendance.fromRow({'student_count': 2}),
        throwsA(isA<TypeError>()),
      );
    },
  );
}
