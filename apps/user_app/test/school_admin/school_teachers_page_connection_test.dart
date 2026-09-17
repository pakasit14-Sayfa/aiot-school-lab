import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/school_admin/school_teachers_page.dart';
import 'package:shared_core/shared_core.dart';

/// Pins loading / data / empty / error apart for the teacher/staff roster.
/// Guards the same multi-role bug as the student page (filtering must use
/// `hasRole`, not `role == teacher`) and the write→read-back→confirm
/// contract on suspend/reactivate/rename/homeroom-assignment mutations.

UserModel _teacher({
  String uid = 'tch-1',
  String name = 'สมหญิง รักเรียน',
  String email = 'somying@school.test',
  String status = 'active',
  List<UserRole> allRoles = const [UserRole.teacher],
}) => UserModel(
  uid: uid,
  name: name,
  email: email,
  role: allRoles.first,
  allRoles: allRoles,
  status: status,
);

HomeroomAssignment _assignment({
  String id = 'asg-1',
  String gradeLevel = 'ม.1',
  String room = '1',
  String? teacherId = 'tch-1',
}) => HomeroomAssignment(
  assignmentId: id,
  gradeLevel: gradeLevel,
  room: room,
  teacherId: teacherId,
  studentCount: 20,
);

Future<void> _pump(
  WidgetTester tester, {
  Future<List<UserModel>> Function()? loadUsers,
  Future<List<HomeroomAssignment>> Function()? loadHomerooms,
  Future<String?> Function(String gradeLevel, String room, String teacherId)?
  setHomeroomTeacher,
  Future<bool> Function(String assignmentId)? removeHomeroomTeacher,
  Future<void> Function(String uid)? suspendUser,
  Future<void> Function(String uid)? reactivateUser,
  Future<void> Function(String uid, String name)? updateName,
  Future<StaffInvitationTicket> Function({required String email, required UserRole role})?
  createInvitation,
  Future<List<SchoolBuildingRecord>> Function()? loadBuildings,
  Future<void> Function({required String buildingId, required String? managerName})?
  setBuildingManager,
}) async {
  tester.view.physicalSize = const Size(1500, 3200);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: SchoolTeachersPage(
        loadUsers: loadUsers ?? () async => <UserModel>[],
        loadHomerooms: loadHomerooms ?? () async => <HomeroomAssignment>[],
        setHomeroomTeacher: setHomeroomTeacher,
        removeHomeroomTeacher: removeHomeroomTeacher,
        suspendUser: suspendUser,
        reactivateUser: reactivateUser,
        updateName: updateName,
        createInvitation: createInvitation,
        loadBuildings: loadBuildings ?? () async => const <SchoolBuildingRecord>[],
        setBuildingManager: setBuildingManager,
      ),
    ),
  );
}

SchoolBuildingRecord _building({String id = 'bld-1', String name = 'อาคาร 1', String manager = ''}) =>
    SchoolBuildingRecord(
      id: id, schoolId: 'school-1', name: name, code: 'B1', floors: 2, roomsCount: 4,
      managerName: manager, devicesCount: 0, trainingKitsCount: 0, status: 'active', note: '',
    );

void main() {
  testWidgets('a multi-role teacher is still listed as staff', (
    tester,
  ) async {
    // active_role collapsed to student, but all_roles still includes
    // teacher — `role == teacher` would have dropped this person entirely.
    await _pump(
      tester,
      loadUsers: () async => [
        _teacher(allRoles: const [UserRole.student, UserRole.teacher]),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text('สมหญิง รักเรียน'), findsOneWidget);
  });

  testWidgets('homeroom assignment is read from list_homeroom_assignments', (
    tester,
  ) async {
    await _pump(
      tester,
      loadUsers: () async => [_teacher()],
      loadHomerooms: () async => [_assignment()],
    );
    await tester.pumpAndSettle();

    expect(find.text('ม.1/1'), findsWidgets);
  });

  testWidgets('a teacher with no homeroom is disclosed honestly', (
    tester,
  ) async {
    await _pump(tester, loadUsers: () async => [_teacher()]);
    await tester.pumpAndSettle();

    expect(find.text('ยังไม่ได้เป็นครูประจำชั้น'), findsWidgets);
  });

  testWidgets('no teachers says so, distinct from a failed load', (
    tester,
  ) async {
    await _pump(tester);
    await tester.pumpAndSettle();

    expect(find.text('ยังไม่มีข้อมูล'), findsWidgets);
    expect(find.text('ยังไม่มีบัญชีที่มีบทบาทครูในโรงเรียนนี้'), findsOneWidget);
  });

  testWidgets('a failed load is distinct from empty, with retry', (
    tester,
  ) async {
    var calls = 0;
    await _pump(
      tester,
      loadUsers: () async {
        calls++;
        throw StateError('backend detail that must stay internal');
      },
    );
    await tester.pumpAndSettle();

    expect(find.text('โหลดรายชื่อบุคลากรไม่สำเร็จ'), findsOneWidget);
    expect(find.textContaining('backend detail'), findsNothing);
    expect(calls, 1);

    await tester.tap(find.text('ลองใหม่').first);
    await tester.pumpAndSettle();
    expect(calls, 2, reason: 'retry must actually re-issue the load');
  });

  testWidgets('a slow load shows progress, not an empty result', (
    tester,
  ) async {
    final gate = Completer<List<UserModel>>();
    await _pump(tester, loadUsers: () => gate.future);
    await tester.pump();

    expect(find.text('กำลังโหลดรายชื่อบุคลากร…'), findsOneWidget);
    expect(find.text('ยังไม่มีบัญชีที่มีบทบาทครูในโรงเรียนนี้'), findsNothing);

    gate.complete([_teacher()]);
    await tester.pumpAndSettle();
    expect(find.text('กำลังโหลดรายชื่อบุคลากร…'), findsNothing);
  });

  testWidgets('suspend only reports success once the read-back confirms it', (
    tester,
  ) async {
    await _pump(
      tester,
      loadUsers: () async => [_teacher(status: 'active')],
      suspendUser: (uid) async {
        // Write succeeds but never actually flips the flag.
      },
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('ระงับ'));
    await tester.pumpAndSettle();

    expect(find.textContaining('ยืนยันกับระบบเรียบร้อย'), findsNothing);
    expect(find.textContaining('ระบบยังไม่ยืนยันการเปลี่ยนแปลง'), findsOneWidget);
  });

  testWidgets('suspend reports success once the read-back actually confirms', (
    tester,
  ) async {
    var suspended = false;
    await _pump(
      tester,
      loadUsers: () async =>
          [_teacher(status: suspended ? 'suspended' : 'active')],
      suspendUser: (uid) async => suspended = true,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('ระงับ'));
    await tester.pumpAndSettle();

    expect(find.textContaining('ยืนยันกับระบบเรียบร้อย'), findsOneWidget);
  });

  testWidgets('"เพิ่มบุคลากรรายคน" issues a real invitation through create_staff_invitation', (
    tester,
  ) async {
    String? sentEmail;
    await _pump(
      tester,
      createInvitation: ({required email, required role}) async {
        sentEmail = email;
        return const StaffInvitationTicket(token: 'inv_teacher_1', expiresAt: null);
      },
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('เพิ่มบุคลากรรายคน'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'อีเมลผู้ถูกเชิญ'), 'kru@school.test');
    await tester.tap(find.text('สร้างคำเชิญ'));
    await tester.pumpAndSettle();

    expect(sentEmail, 'kru@school.test');
    expect(find.text('inv_teacher_1'), findsOneWidget);
  });

  testWidgets('"กำหนดครูประจำอาคาร" writes the chosen teacher through set_school_building_manager', (
    tester,
  ) async {
    String? sentBuilding, sentManager;
    await _pump(
      tester,
      loadUsers: () async => [_teacher(uid: 't-1', name: 'ครูสมชาย ใจดี')],
      loadBuildings: () async => [_building()],
      setBuildingManager: ({required buildingId, required managerName}) async {
        sentBuilding = buildingId;
        sentManager = managerName;
      },
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('กำหนดครูประจำอาคาร'));
    await tester.pumpAndSettle();
    final managerDropdown = find.byWidgetPredicate((w) => w is DropdownButtonFormField<String?>);
    await tester.tap(managerDropdown.last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('ครูสมชาย ใจดี').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('บันทึก'));
    await tester.pumpAndSettle();

    expect(sentBuilding, 'bld-1');
    expect(sentManager, 'ครูสมชาย ใจดี');
  });

  testWidgets('assigning a homeroom does not throw while the dialog closes (prod crash 2026-09-17)', (
    tester,
  ) async {
    // On production the save hit Flutter's `_dependents.isEmpty` assertion:
    // the dialog's TextEditingControllers were disposed right after
    // showDialog returned, while the fields were still animating out.
    String? sent;
    await _pump(
      tester,
      loadUsers: () async => [_teacher()],
      setHomeroomTeacher: (grade, room, teacherId) async {
        sent = '$grade/$room';
        return 'hr-1';
      },
      loadHomerooms: () async => sent == null
          ? const []
          : [
              HomeroomAssignment(
                assignmentId: 'hr-1',
                gradeLevel: 'ม.1',
                room: '1',
                teacherId: _teacher().uid,
                teacherName: _teacher().name,
                studentCount: 3,
              ),
            ],
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('มอบหมายครูประจำชั้น').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'ระดับชั้น'), 'ม.1');
    await tester.enterText(find.widgetWithText(TextField, 'ห้อง'), '1');
    await tester.tap(find.widgetWithText(FilledButton, 'บันทึก'));
    // Pump frame by frame through the close animation — this is where the
    // assertion used to fire.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull);
    }
    await tester.pumpAndSettle();
    expect(sent, 'ม.1/1');
    expect(tester.takeException(), isNull);
  });
}
