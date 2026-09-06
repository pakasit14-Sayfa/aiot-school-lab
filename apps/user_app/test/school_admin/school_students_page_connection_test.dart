import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/school_admin/school_students_page.dart';
import 'package:shared_core/shared_core.dart';

/// Pins loading / data / empty / error apart for the student roster, and
/// guards the multi-role membership bug: filtering must use `hasRole`
/// (checks `all_roles`) rather than `role == student`, because a
/// multi-role account's collapsed `active_role` reflects whichever role was
/// granted last — comparing against a single role dropped real students
/// from the list before. Also guards the write→read-back→confirm contract
/// on suspend/reactivate/rename mutations.

UserModel _student({
  String uid = 'stu-1',
  String name = 'สมชาย ใจดี',
  String email = 'somchai@school.test',
  String status = 'active',
  List<UserRole> allRoles = const [UserRole.student],
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
}) => HomeroomAssignment(
  assignmentId: id,
  gradeLevel: gradeLevel,
  room: room,
  studentCount: 1,
);

HomeroomRosterItem _roster({
  String studentId = 'stu-1',
  String studentName = 'สมชาย ใจดี',
  String studentCode = 'STU001',
}) => HomeroomRosterItem(
  studentId: studentId,
  studentName: studentName,
  studentCode: studentCode,
);

Future<void> _pump(
  WidgetTester tester, {
  Future<List<UserModel>> Function()? loadUsers,
  Future<List<HomeroomAssignment>> Function()? loadHomerooms,
  Future<List<HomeroomRosterItem>> Function(String gradeLevel, String room)?
  loadRoster,
  Future<void> Function(String uid)? suspendUser,
  Future<void> Function(String uid)? reactivateUser,
  Future<void> Function(String uid, String name)? updateName,
}) async {
  tester.view.physicalSize = const Size(1500, 3200);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: SchoolStudentsPage(
        loadUsers: loadUsers ?? () async => <UserModel>[],
        loadHomerooms: loadHomerooms ?? () async => <HomeroomAssignment>[],
        loadRoster: loadRoster ?? (_, _) async => <HomeroomRosterItem>[],
        suspendUser: suspendUser,
        reactivateUser: reactivateUser,
        updateName: updateName,
      ),
    ),
  );
}

void main() {
  testWidgets('a multi-role student is still listed as a student', (
    tester,
  ) async {
    // active_role collapsed to teacher, but all_roles still includes
    // student — the old `role == student` check would have dropped this
    // person from the roster entirely.
    await _pump(
      tester,
      loadUsers: () async => [
        _student(allRoles: const [UserRole.teacher, UserRole.student]),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text('สมชาย ใจดี'), findsOneWidget);
  });

  testWidgets('grade/room/student code come from homeroom roster, not users', (
    tester,
  ) async {
    await _pump(
      tester,
      loadUsers: () async => [_student()],
      loadHomerooms: () async => [_assignment()],
      loadRoster: (gradeLevel, room) async => [_roster()],
    );
    await tester.pumpAndSettle();

    expect(find.text('ม.1/1'), findsOneWidget);
  });

  testWidgets('an unplaced student is disclosed, not defaulted to ม.1', (
    tester,
  ) async {
    await _pump(tester, loadUsers: () async => [_student()]);
    await tester.pumpAndSettle();

    expect(find.text('ยังไม่ได้จัดห้องเรียน'), findsWidgets);
  });

  testWidgets('no students says so, distinct from a failed load', (
    tester,
  ) async {
    await _pump(tester);
    await tester.pumpAndSettle();

    expect(find.text('ยังไม่มีข้อมูล'), findsWidgets);
    expect(find.text('ยังไม่มีบัญชีนักเรียนในโรงเรียนนี้'), findsOneWidget);
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

    expect(find.text('โหลดรายชื่อนักเรียนไม่สำเร็จ'), findsOneWidget);
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

    expect(find.text('กำลังโหลดรายชื่อนักเรียน…'), findsOneWidget);
    expect(find.text('ยังไม่มีบัญชีนักเรียนในโรงเรียนนี้'), findsNothing);

    gate.complete([_student()]);
    await tester.pumpAndSettle();
    expect(find.text('กำลังโหลดรายชื่อนักเรียน…'), findsNothing);
  });

  testWidgets('suspend only reports success once the read-back confirms it', (
    tester,
  ) async {
    await _pump(
      tester,
      loadUsers: () async => [_student(status: 'active')],
      suspendUser: (uid) async {
        // Write call succeeds but never actually flips the flag —
        // must not be reported as success.
      },
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ระงับบัญชีชั่วคราว'));
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
          [_student(status: suspended ? 'suspended' : 'active')],
      suspendUser: (uid) async => suspended = true,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ระงับบัญชีชั่วคราว'));
    await tester.pumpAndSettle();

    expect(find.textContaining('ยืนยันกับระบบเรียบร้อย'), findsOneWidget);
  });
}
