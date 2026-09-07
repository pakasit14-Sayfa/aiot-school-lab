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

Future<void> _pump(
  WidgetTester tester, {
  List<StaffDirectoryEntry>? staff,
  List<SchoolDepartment>? departments,
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
        body: DirectorTeachersPage(
          loadStaff: () async {
            if (fail) throw StateError('staff_unreachable');
            return staff ?? const <StaffDirectoryEntry>[];
          },
          loadDepartments: () async =>
              departments ?? const <SchoolDepartment>[],
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

  testWidgets('staff attendance is an honest gap, not a zero', (tester) async {
    await _pump(tester);

    expect(
      find.text('ยังไม่มีระบบลงเวลาปฏิบัติงานของบุคลากร'),
      findsOneWidget,
    );
    expect(
      find.textContaining('ยังไม่มีข้อมูลการมาปฏิบัติงานและการลาของบุคลากร'),
      findsOneWidget,
    );
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
