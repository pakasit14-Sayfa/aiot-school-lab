import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/executive_redesign_prototype/pages/director_teachers_page.dart';
import 'package:shared_core/shared_core.dart';

/// This page did not import `shared_core` and invented an entire staff body:
/// 151 lines of personnel with names like นายสมชาย ใจดี, each with a position,
/// a ฝ่าย, a กลุ่มสาระ, an attendance percentage, a teaching-compliance
/// percentage and a task-progress figure; six departments with present and
/// on-leave head counts; ten subject groups with their own attendance and
/// follow-up counts; and a card telling the director to follow up on
/// "ครูลา 2 คนในฝ่ายวิชาการ".
///
/// It now reads `list_staff_directory` and `list_departments`, added in
/// 20260907000000 because the school confirmed it uses ฝ่าย and กลุ่มสาระ.
/// What that migration cannot supply is still absent rather than defaulted:
/// there is no staff attendance table, nothing records whether a teacher
/// started a period, and `leave_requests` is student leave (student_id and
/// parent_id NOT NULL), so attendance, lateness and teaching compliance are
/// gone rather than shown as zero.

StaffDirectoryEntry _staff({
  required String name,
  List<String> roles = const ['teacher'],
  List<String> admin = const [],
  List<String> subjects = const [],
  List<String> heads = const [],
  String? position,
  String status = 'active',
}) => StaffDirectoryEntry(
  userId: 'u-$name',
  fullName: name,
  email: '$name@test.local',
  status: status,
  roles: roles,
  administrativeDepartments: admin,
  subjectGroups: subjects,
  headsDepartments: heads,
  positionTitle: position,
);

SchoolDepartment _dept({
  required String name,
  String kind = 'administrative',
  int members = 0,
  String? head,
}) => SchoolDepartment(
  departmentId: 'd-$name',
  name: name,
  kind: kind,
  sortOrder: 0,
  memberCount: members,
  headName: head,
);

StaffAttendanceSummary _summary({
  int total = 0,
  int present = 0,
  int late = 0,
  int leave = 0,
  int officialDuty = 0,
  int absent = 0,
  int noRecord = 0,
  bool hoursConfigured = true,
}) => StaffAttendanceSummary(
  workDate: DateTime(2026, 9, 7),
  totalStaff: total,
  presentCount: present,
  lateCount: late,
  leaveCount: leave,
  officialDutyCount: officialDuty,
  absentCount: absent,
  noRecordCount: noRecord,
  workHoursConfigured: hoursConfigured,
);

Future<void> _pump(
  WidgetTester tester, {
  List<StaffDirectoryEntry>? staff,
  List<SchoolDepartment>? departments,
  StaffAttendanceSummary? attendance,
  List<StaffLeaveRequest>? pendingLeave,
  bool fail = false,
  bool attendanceFails = false,
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
        body: DirectorTeachersPage(
          loadStaff: () async {
            if (fail) throw StateError('staff_unreachable');
            return staff ?? const <StaffDirectoryEntry>[];
          },
          loadDepartments: () async =>
              departments ?? const <SchoolDepartment>[],
          loadAttendanceSummary: () async {
            if (attendanceFails) throw StateError('attendance_unreachable');
            return attendance;
          },
          loadLeaveRequests: () async =>
              pendingLeave ?? const <StaffLeaveRequest>[],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the invented staff body is gone', (tester) async {
    await _pump(tester);

    for (final invented in <String>[
      'นายสมชาย ใจดี',
      'รองผู้อำนวยการฝ่ายวิชาการ',
      'ครูลา 2 คนในฝ่ายวิชาการ',
      'ลาป่วย 2',
      'คิดเป็น 95.3%',
      'คาบสอนที่เริ่มตรงเวลา',
    ]) {
      expect(
        find.textContaining(invented),
        findsNothing,
        reason: 'ยังพบของที่แต่งขึ้น: $invented',
      );
    }
  });

  testWidgets('staff and departments come from the backend', (tester) async {
    await _pump(
      tester,
      staff: [
        _staff(
          name: 'ครูสมหมาย ทดสอบ',
          admin: ['ฝ่ายวิชาการ'],
          subjects: ['วิทยาศาสตร์'],
          heads: ['วิทยาศาสตร์'],
          position: 'ครูชำนาญการ',
        ),
        _staff(name: 'ครูไม่สังกัด ทดสอบ'),
      ],
      departments: [
        _dept(name: 'ฝ่ายวิชาการ', members: 1, head: 'ครูสมหมาย ทดสอบ'),
        _dept(name: 'วิทยาศาสตร์', kind: 'subject_group', members: 1),
      ],
    );

    expect(find.textContaining('ครูสมหมาย ทดสอบ'), findsWidgets);
    expect(find.text('ครูชำนาญการ'), findsWidgets);
    expect(find.textContaining('ฝ่ายวิชาการ • วิทยาศาสตร์'), findsOneWidget);
    expect(find.textContaining('หัวหน้า: วิทยาศาสตร์'), findsWidgets);
    // Somebody with no groups says so rather than being filed under a
    // borrowed department.
    expect(find.text('ยังไม่ได้สังกัดฝ่าย/กลุ่มสาระ'), findsOneWidget);
    // A department with nobody marked as head does not borrow one.
    expect(find.text('ยังไม่ได้ระบุหัวหน้ากลุ่มสาระ'), findsOneWidget);
  });

  testWidgets('counts are derived, and only from what exists', (tester) async {
    await _pump(
      tester,
      staff: [
        _staff(name: 'ก', roles: ['teacher']),
        _staff(name: 'ข', roles: ['teacher', 'school_admin']),
      ],
      departments: [
        _dept(name: 'ฝ่ายวิชาการ'),
        _dept(name: 'วิทยาศาสตร์', kind: 'subject_group'),
      ],
    );

    // Both hold teacher; one also holds school_admin. Counting membership
    // rather than a collapsed single role is what keeps a dual-role account
    // in the teacher figure.
    expect(find.text('2'), findsWidgets);
    expect(find.text('ครู 2 • ผู้ดูแลระบบ 1'), findsOneWidget);
    // The four cards with no source are gone entirely.
    for (final removed in <String>[
      'มาปฏิบัติงานวันนี้',
      'มาสาย',
      'เข้าสอนตามตาราง',
      'ประชุม / อบรม',
    ]) {
      expect(find.text(removed), findsNothing, reason: removed);
    }
  });

  testWidgets('today\'s attendance comes from the summary RPC', (tester) async {
    await _pump(
      tester,
      staff: [_staff(name: 'ก'), _staff(name: 'ข')],
      attendance: _summary(
        total: 6,
        present: 3,
        late: 1,
        leave: 1,
        absent: 0,
        noRecord: 1,
      ),
    );

    expect(find.text('มาปฏิบัติงาน'), findsOneWidget);
    expect(find.text('บุคลากรทั้งหมด 6 คน'), findsOneWidget);
    // ยังไม่ลงเวลา must stay a separate figure from ขาดงาน: silence is not
    // evidence of absence.
    expect(find.text('ยังไม่ลงเวลา'), findsOneWidget);
    expect(find.text('ขาดงาน'), findsOneWidget);
  });

  testWidgets('unset work hours are stated, not shown as nobody late', (
    tester,
  ) async {
    await _pump(
      tester,
      attendance: _summary(total: 4, noRecord: 4, hoursConfigured: false),
    );

    expect(find.text('โรงเรียนยังไม่ได้ตั้งเวลาปฏิบัติงาน'), findsOneWidget);
    expect(
      find.textContaining('ระบบจึงยังตัดสินไม่ได้ว่าใครมาสาย'),
      findsOneWidget,
    );
  });

  testWidgets('follow-up items are counts, never authored', (tester) async {
    await _pump(
      tester,
      attendance: _summary(total: 5, present: 3, late: 2, noRecord: 0),
      pendingLeave: [
        StaffLeaveRequest(
          requestId: 'r1',
          userId: 'u1',
          fullName: 'ครูทดสอบ',
          leaveType: 'sick',
          startDate: DateTime(2026, 9, 7),
          endDate: DateTime(2026, 9, 7),
          status: 'pending',
          createdAt: DateTime(2026, 9, 6),
        ),
      ],
    );

    expect(find.text('มีคำขอลาที่ยังไม่ได้พิจารณา 1 รายการ'), findsOneWidget);
    expect(find.text('มาสายวันนี้ 2 คน'), findsOneWidget);
    // Nothing is claimed about the counts that were zero.
    expect(find.textContaining('ขาดงานวันนี้'), findsNothing);
    expect(find.textContaining('ยังไม่ได้ลงเวลาวันนี้'), findsNothing);
  });

  testWidgets('a clean day says so instead of filling the space', (
    tester,
  ) async {
    await _pump(tester, attendance: _summary(total: 3, present: 3));

    expect(find.text('ไม่มีประเด็นที่ระบบยืนยันได้ในวันนี้'), findsOneWidget);
  });

  testWidgets('unreadable attendance is not a zeroed day', (tester) async {
    await _pump(tester, attendanceFails: true);

    expect(find.text('โหลดข้อมูลการลงเวลาไม่สำเร็จ'), findsOneWidget);
    expect(find.text('ยังไม่ทราบประเด็นที่ต้องติดตาม'), findsOneWidget);
    expect(find.textContaining('attendance_unreachable'), findsNothing);
    // No count is invented in place of the read that failed.
    expect(find.text('มาปฏิบัติงาน'), findsNothing);
  });

  testWidgets('filter options are built from the data', (tester) async {
    await _pump(
      tester,
      staff: [
        _staff(name: 'ก', roles: ['teacher'], admin: ['ฝ่ายวิชาการ']),
        _staff(name: 'ข', roles: ['executive'], status: 'suspended'),
      ],
      departments: [
        _dept(name: 'ฝ่ายวิชาการ'),
        _dept(name: 'วิทยาศาสตร์', kind: 'subject_group'),
      ],
    );

    final departmentDropdown = tester.widget<DropdownButton<String>>(
      find.byType(DropdownButton<String>).first,
    );
    expect(
      departmentDropdown.items?.map((i) => i.value).toList(),
      ['ทุกฝ่าย', 'ฝ่ายวิชาการ', 'วิทยาศาสตร์'],
      reason: 'ตัวเลือกฝ่ายต้องมาจาก departments ที่โหลดมา',
    );

    final statusDropdown = tester.widget<DropdownButton<String>>(
      find.byType(DropdownButton<String>).at(2),
    );
    expect(
      statusDropdown.items?.map((i) => i.value).toList(),
      ['ทุกสถานะ', 'ระงับการใช้งาน', 'ใช้งานอยู่'],
      reason: 'สถานะต้องเป็นสถานะบัญชีจริงที่ตัวกรองเทียบได้',
    );

    // The five invented ฝ่าย and the six attendance states that the status
    // filter used to offer — none of which its own comparison could match.
    for (final invented in <String>[
      'ฝ่ายอาคารสถานที่และสิ่งแวดล้อม',
      'ฝ่ายเทคโนโลยีและระบบ',
      'บุคลากรสนับสนุน',
      'ประชุม/อบรม',
    ]) {
      expect(find.text(invented), findsNothing, reason: invented);
    }
  });

  testWidgets('a failed load is stated and shows no counts', (tester) async {
    await _pump(tester, fail: true);

    expect(
      find.textContaining('โหลดข้อมูลบุคลากรไม่สำเร็จ'),
      findsOneWidget,
    );
    expect(find.text('—'), findsWidgets);
    expect(find.textContaining('staff_unreachable'), findsNothing);
  });
}
