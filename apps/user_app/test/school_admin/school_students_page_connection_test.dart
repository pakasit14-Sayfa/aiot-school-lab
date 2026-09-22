import 'dart:async';

import 'dart:convert';

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
  Future<List<SchoolStudentOption>> Function()? loadSchoolStudents,
  Future<void> Function(String uid, String gradeLevel, String room)?
  setStudentProfile,
  Future<List<HomeroomAssignment>> Function()? loadHomerooms,
  Future<List<HomeroomRosterItem>> Function(String gradeLevel, String room)?
  loadRoster,
  Future<void> Function(String uid)? suspendUser,
  Future<void> Function(String uid)? reactivateUser,
  Future<void> Function(String uid, String name)? updateName,
  Future<BulkImportResult> Function({
    required UserRole role,
    required List<Map<String, dynamic>> users,
  })?
  importUsers,
  void Function({
    required String filename,
    required List<int> bytes,
    required String mimeType,
  })?
  downloadBytesOverride,
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
        loadSchoolStudents:
            loadSchoolStudents ?? () async => <SchoolStudentOption>[],
        setStudentProfile: setStudentProfile,
        loadHomerooms: loadHomerooms ?? () async => <HomeroomAssignment>[],
        loadRoster: loadRoster ?? (_, _) async => <HomeroomRosterItem>[],
        suspendUser: suspendUser,
        reactivateUser: reactivateUser,
        updateName: updateName,
        importUsers: importUsers,
        downloadBytesOverride:
            downloadBytesOverride ??
            ({required filename, required bytes, required mimeType}) {},
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
    expect(
      find.textContaining('ระบบยังไม่ยืนยันการเปลี่ยนแปลง'),
      findsOneWidget,
    );
  });

  testWidgets('suspend reports success once the read-back actually confirms', (
    tester,
  ) async {
    var suspended = false;
    await _pump(
      tester,
      loadUsers: () async => [
        _student(status: suspended ? 'suspended' : 'active'),
      ],
      suspendUser: (uid) async => suspended = true,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ระงับบัญชีชั่วคราว'));
    await tester.pumpAndSettle();

    expect(find.textContaining('ยืนยันกับระบบเรียบร้อย'), findsOneWidget);
  });

  testWidgets(
    '"เพิ่มนักเรียนรายคน" creates the account through the import RPC and shows the temp password once',
    (tester) async {
      List<Map<String, dynamic>>? sent;
      UserRole? sentRole;
      await _pump(
        tester,
        importUsers: ({required role, required users}) async {
          sentRole = role;
          sent = users;
          return const BulkImportResult(
            success: true,
            insertedCount: 1,
            skipped: [],
            credentials: [
              ImportedCredential(
                row: 1,
                email: 'new@school.test',
                tempPassword: 'Qw7Rt4Yu9p',
              ),
            ],
          );
        },
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('เพิ่มนักเรียนรายคน'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'อีเมล'),
        'New@School.test',
      );
      await tester.enterText(find.widgetWithText(TextField, 'ชื่อ'), 'ใหม่');
      await tester.enterText(
        find.widgetWithText(TextField, 'นามสกุล'),
        'เรียนดี',
      );
      await tester.tap(find.text('สร้างบัญชี'));
      await tester.pumpAndSettle();

      expect(sentRole, UserRole.student);
      expect(sent, [
        {
          'email': 'new@school.test',
          'first_name': 'ใหม่',
          'last_name': 'เรียนดี',
          'student_code': '',
          // 2026-09-17: class fields travel with the row (empty = not set).
          'grade_level': '',
          'room': '',
        },
      ]);
      expect(find.text('Qw7Rt4Yu9p'), findsOneWidget);
      expect(
        find.text('ยังไม่มีระบบหลังบ้านรองรับ ใช้ "นำเข้ารายชื่อ" แทน'),
        findsNothing,
      );
    },
  );

  testWidgets('a duplicate email is reported in the form, not as success', (
    tester,
  ) async {
    await _pump(
      tester,
      importUsers: ({required role, required users}) async =>
          const BulkImportResult(
            success: true,
            insertedCount: 0,
            skipped: [SkippedRow(row: 1, reason: 'duplicate_email')],
          ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('เพิ่มนักเรียนรายคน'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'อีเมล'),
      'dup@school.test',
    );
    await tester.enterText(find.widgetWithText(TextField, 'ชื่อ'), 'ซ้ำ');
    await tester.tap(find.text('สร้างบัญชี'));
    await tester.pumpAndSettle();

    expect(find.text('อีเมลนี้มีบัญชีอยู่แล้ว'), findsOneWidget);
    expect(
      find.textContaining('แสดงครั้งเดียว'),
      findsNothing,
      reason: 'no credentials dialog',
    );
  });

  testWidgets('"ส่งออกรายชื่อ" downloads the filtered students as a real CSV', (
    tester,
  ) async {
    String? savedName;
    List<int>? savedBytes;
    await _pump(
      tester,
      loadUsers: () async => [
        _student(name: 'ส่งออก ทดสอบ', email: 'export@school.test'),
      ],
      downloadBytesOverride:
          ({required filename, required bytes, required mimeType}) {
            savedName = filename;
            savedBytes = bytes;
          },
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('ส่งออกรายชื่อ'));
    await tester.pumpAndSettle();

    expect(savedName, startsWith('students_'));
    expect(utf8.decode(savedBytes!), contains('export@school.test'));
  });

  // -------------------------------------------------------------------------
  // 2026-09-17: grade/room come from student_profiles (list_school_students)
  // and can be SET from this page (set_student_profile) — before this,
  // nothing in the app wrote student_profiles at all.
  // -------------------------------------------------------------------------

  testWidgets(
    'grade/room show from student_profiles even with no homeroom teacher yet',
    (tester) async {
      await _pump(
        tester,
        loadUsers: () async => [_student()],
        loadSchoolStudents: () async => [
          SchoolStudentOption(
            studentId: _student().uid,
            studentName: _student().name,
            gradeLevel: 'ม.2',
            room: '4',
          ),
        ],
      );
      await tester.pumpAndSettle();
      expect(find.text('ม.2/4'), findsOneWidget);
      // Only the summary tile's title says "ยังไม่ได้จัดห้องเรียน"; no row does.
      expect(find.text('ยังไม่ได้จัดห้องเรียน'), findsOneWidget);
    },
  );

  testWidgets(
    '"กำหนดระดับชั้น / ห้อง" calls set_student_profile and confirms by read-back',
    (tester) async {
      String? sentGrade, sentRoom;
      var saved = false;
      await _pump(
        tester,
        loadUsers: () async => [_student()],
        loadSchoolStudents: () async => [
          SchoolStudentOption(
            studentId: _student().uid,
            studentName: _student().name,
            gradeLevel: saved ? 'ม.3' : null,
            room: saved ? '2' : null,
          ),
        ],
        setStudentProfile: (uid, grade, room) async {
          expect(uid, _student().uid);
          sentGrade = grade;
          sentRoom = room;
          saved = true;
        },
      );
      await tester.pumpAndSettle();
      expect(find.text('ยังไม่ได้จัดห้องเรียน'), findsWidgets);

      await tester.tap(find.text(_student().name).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('กำหนดระดับชั้น / ห้อง'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'ระดับชั้น'),
        'ม.3',
      );
      await tester.enterText(find.widgetWithText(TextField, 'ห้อง'), '2');
      await tester.tap(find.widgetWithText(FilledButton, 'บันทึก'));
      await tester.pumpAndSettle();

      expect(sentGrade, 'ม.3');
      expect(sentRoom, '2');
      expect(find.text('ม.3/2'), findsOneWidget);
      expect(find.textContaining('บันทึกชั้น/ห้องแล้ว'), findsOneWidget);
    },
  );

  testWidgets(
    'a class save the backend does not reflect is reported as a failure',
    (tester) async {
      await _pump(
        tester,
        loadUsers: () async => [_student()],
        setStudentProfile:
            (_, _, _) async {}, // "succeeds" but read-back still empty
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(_student().name).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('กำหนดระดับชั้น / ห้อง'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'ระดับชั้น'),
        'ม.3',
      );
      await tester.enterText(find.widgetWithText(TextField, 'ห้อง'), '2');
      await tester.tap(find.widgetWithText(FilledButton, 'บันทึก'));
      await tester.pumpAndSettle();
      expect(find.textContaining('บันทึกชั้น/ห้องไม่สำเร็จ'), findsOneWidget);
      expect(find.text('ม.3/2'), findsNothing);
    },
  );
}
