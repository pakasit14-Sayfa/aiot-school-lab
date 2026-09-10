import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/executive_redesign_prototype/controllers/director_overview_controller.dart';
import 'package:my_first_app/pages/executive_redesign_prototype/pages/director_overview_page.dart';
import 'package:shared_core/shared_core.dart';

/// "การเข้าเรียนของนักเรียน" กับ "การมาปฏิบัติหน้าที่ของครู" เคยอยู่บนหน้า
/// ภาพรวมของ ผอ. เวอร์ชัน 7 ก.ย. แต่ตัวเลขทั้งบล็อกเป็นของแต่งขึ้น (ติดป้าย
/// "ข้อมูลจำลอง") จึงถูกรื้อออกตอนล้างข้อมูลปลอม — เอากลับมาแล้วโดยผูกกับ
/// `list_school_homeroom_attendance` และ `get_staff_attendance_summary` จริง
///
/// เทสต์ชุดนี้ล็อกไว้ว่า: ตัวเลขบนจอมาจากข้อมูลที่ส่งเข้ามาเท่านั้น และเมื่อ
/// ไม่มีข้อมูลต้องบอกสาเหตุ ไม่ใช่โชว์ 0 ให้เข้าใจว่า "ไม่มีใครมาโรงเรียน"
void main() {
  DirectorOverviewData data({
    List<SchoolHomeroomAttendance> rooms = const [],
    StaffAttendanceSummary? staff,
  }) => DirectorOverviewData(
    counts: const {'student': 3, 'teacher': 1},
    devices: const [],
    incidents: const [],
    tracks: const [],
    notices: const [],
    energy: const [],
    water: const [],
    studentAttendance: rooms,
    staffAttendance: staff,
    subjectGroups: const [],
  );

  Future<void> pump(WidgetTester t, DirectorOverviewData d) async {
    await t.binding.setSurfaceSize(const Size(1400, 3000));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final c = DirectorOverviewController(loader: (_) async => d);
    addTearDown(c.dispose);
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DirectorOverviewPage(
            controller: c,
            onNavigate: (_) {},
            sensorStreamOverride: Stream<SensorModel?>.value(null),
            rawReadingsStreamOverride: Stream.value(<Map<String, dynamic>>[]),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
  }

  testWidgets('ตัวเลขการเข้าเรียนต้องรวมมาจากห้องจริงที่ส่งเข้ามา', (t) async {
    await pump(
      t,
      data(
        rooms: const [
          SchoolHomeroomAttendance(
            gradeLevel: 'ม.4',
            room: 'ม.4/1',
            studentCount: 30,
            present: 25,
            late: 2,
            absent: 1,
            excused: 2,
            unknown: 0,
          ),
          SchoolHomeroomAttendance(
            gradeLevel: 'ม.5',
            room: 'ม.5/2',
            studentCount: 28,
            present: 20,
            late: 1,
            absent: 3,
            excused: 4,
            unknown: 0,
          ),
        ],
      ),
    );

    expect(find.text('การเข้าเรียนของนักเรียน'), findsOneWidget);
    expect(find.text('45'), findsOneWidget); // มาเรียน 25+20
    expect(find.text('จาก 58 คน'), findsOneWidget); // นักเรียนรวม 30+28
    expect(find.textContaining('เช็กชื่อแล้ว 2 ห้อง'), findsOneWidget);
  });

  testWidgets('ยังไม่เช็กชื่อ ต้องบอกว่ายังไม่เช็ก ไม่ใช่โชว์ 0 คน', (t) async {
    await pump(t, data());

    expect(find.text('ยังไม่มีการเช็กชื่อของวันนี้'), findsOneWidget);
    expect(
      find.textContaining('เมื่อครูประจำชั้นบันทึกการเข้าเรียน'),
      findsOneWidget,
    );
  });

  testWidgets('การลงเวลาของครูต้องมาจากสรุปจริง', (t) async {
    await pump(
      t,
      data(
        staff: StaffAttendanceSummary(
          workDate: DateTime(2026, 9, 10),
          totalStaff: 12,
          presentCount: 9,
          lateCount: 1,
          leaveCount: 1,
          officialDutyCount: 1,
          absentCount: 0,
          noRecordCount: 0,
          workHoursConfigured: true,
        ),
      ),
    );

    expect(find.text('การมาปฏิบัติหน้าที่ของครู'), findsOneWidget);
    expect(find.text('9'), findsOneWidget);
    expect(find.text('จาก 12 คน'), findsOneWidget);
    expect(find.textContaining('บุคลากรทั้งหมด 12 คน'), findsOneWidget);
  });

  /// เคสที่เกิดจริงในโรงเรียนที่ยังไม่ได้ตั้งค่า: `staff_check_in` โยน
  /// `work_hours_not_configured` ครูจึงลงเวลาไม่ได้เลยสักคน ถ้าโชว์ 0 เฉย ๆ
  /// ผู้บริหารจะอ่านว่าไม่มีครูมาโรงเรียนวันนี้
  testWidgets('ยังไม่ตั้งเวลาปฏิบัติงาน ต้องบอกสาเหตุ ไม่ใช่โชว์ศูนย์', (
    t,
  ) async {
    await pump(
      t,
      data(
        staff: StaffAttendanceSummary(
          workDate: DateTime(2026, 9, 10),
          totalStaff: 12,
          presentCount: 0,
          lateCount: 0,
          leaveCount: 0,
          officialDutyCount: 0,
          absentCount: 0,
          noRecordCount: 12,
          workHoursConfigured: false,
        ),
      ),
    );

    expect(
      find.text('ยังไม่ได้ตั้งเวลาปฏิบัติงานของโรงเรียน'),
      findsOneWidget,
    );
    expect(find.text('มาปฏิบัติงาน'), findsNothing);
  });
}
