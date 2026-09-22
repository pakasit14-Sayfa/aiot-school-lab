import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/executive_redesign_prototype/pages/director_student_followup_page.dart';
import 'package:shared_core/shared_core.dart';

/// director_learning_page.dart's "งานติดตามที่ยังไม่รองรับ" card used to have
/// 3 onPressed:null buttons because none of this existed: no table, no RPC,
/// no service. This page is the real backend behind those 3 buttons plus a
/// 4th domain (scholarships) the card only mentioned in its subtitle text.
/// Every action here calls a real RPC from
/// 20260911020000_student_followup_system.sql — nothing here is local-state
/// only.

SchoolStudentOption _student(String id, String name) =>
    SchoolStudentOption(studentId: id, studentName: name, room: 'ม.4/1');

StaffDirectoryEntry _teacher(String id, String name) => StaffDirectoryEntry(
  userId: id,
  fullName: name,
  email: '$id@test.local',
  status: 'active',
  roles: const ['teacher'],
  administrativeDepartments: const [],
  headsDepartments: const [],
  subjectGroups: const [],
);

Future<void> _pump(
  WidgetTester tester, {
  StudentSearchLoader? loadStudents,
  StaffDirectoryLoader? loadStaff,
  HomeVisitsLoader? loadHomeVisits,
  CreateHomeVisitFn? createHomeVisit,
  SdqSummaryLoader? loadSdq,
  RecordSdqFn? recordSdq,
  ScholarshipsLoader? loadScholarships,
  ScholarshipAwardsLoader? loadScholarshipAwards,
  CreateScholarshipFn? createScholarship,
  NominateAwardFn? nominateAward,
  SetAwardStatusFn? setAwardStatus,
  DirectivesLoader? loadDirectives,
  CreateDirectiveFn? createDirective,
}) async {
  tester.view.physicalSize = const Size(1400, 2200);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: DirectorStudentFollowupPage(
          loadStudents:
              loadStudents ?? (_) async => [_student('s1', 'นักเรียนทดสอบ')],
          loadStaff: loadStaff ?? () async => [_teacher('t1', 'ครูทดสอบ')],
          loadHomeVisits: loadHomeVisits ?? () async => const [],
          createHomeVisit: createHomeVisit,
          loadSdq: loadSdq ?? () async => const [],
          recordSdq: recordSdq,
          loadScholarships: loadScholarships ?? () async => const [],
          loadScholarshipAwards:
              loadScholarshipAwards ?? ({scholarshipId}) async => const [],
          createScholarship: createScholarship,
          nominateAward: nominateAward,
          setAwardStatus: setAwardStatus,
          loadDirectives: loadDirectives ?? () async => const [],
          createDirective: createDirective,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('all 4 tabs render with real empty states, no fake content', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text('ยังไม่มีการบันทึกเยี่ยมบ้าน'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('SDQ'));
    await tester.pumpAndSettle();
    expect(find.text('ยังไม่มีการประเมิน SDQ'), findsOneWidget);
    expect(find.textContaining('ไม่ใช่ผลวินิจฉัย'), findsOneWidget);

    await tester.tap(find.text('ทุนการศึกษา'));
    await tester.pumpAndSettle();
    expect(find.text('ยังไม่มีทุนการศึกษาในระบบ'), findsOneWidget);

    await tester.tap(find.text('สั่งการติดตาม'));
    await tester.pumpAndSettle();
    expect(find.text('ยังไม่มีคำสั่งติดตามที่มอบหมาย'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('populated data renders real fields, not placeholders', (
    tester,
  ) async {
    await _pump(
      tester,
      loadHomeVisits: () async => [
        HomeVisit(
          visitId: 'v1',
          studentId: 's1',
          studentName: 'นักเรียนทดสอบ',
          visitedByName: 'ครูทดสอบ',
          visitDate: DateTime(2026, 9, 1),
          purpose: 'ติดตามการขาดเรียน',
          followUpNeeded: true,
          createdAt: DateTime(2026, 9, 1),
        ),
      ],
      loadSdq: () async => [
        SchoolSdqSummaryRow(
          assessmentId: 'a1',
          studentId: 's1',
          studentName: 'นักเรียนทดสอบ',
          assessmentDate: DateTime(2026, 9, 1),
          totalDifficultiesScore: 22,
        ),
      ],
      loadScholarships: () async => [
        Scholarship(
          scholarshipId: 'sc1',
          name: 'ทุนเรียนดี',
          awardCount: 1,
          createdAt: DateTime(2026, 9, 1),
        ),
      ],
      loadScholarshipAwards: ({scholarshipId}) async => [
        ScholarshipAward(
          awardId: 'aw1',
          scholarshipId: 'sc1',
          scholarshipName: 'ทุนเรียนดี',
          studentId: 's1',
          studentName: 'นักเรียนทดสอบ',
          status: 'applied',
          createdAt: DateTime(2026, 9, 1),
        ),
      ],
      loadDirectives: () async => [
        ExecutiveDirective(
          directiveId: 'd1',
          title: 'ติดตามผลการเรียน',
          counterpartyName: 'ครูทดสอบ',
          status: 'pending',
          createdAt: DateTime(2026, 9, 1),
        ),
      ],
    );

    expect(find.text('ติดตามการขาดเรียน'), findsOneWidget);
    expect(find.text('ต้องติดตามต่อ'), findsOneWidget);

    await tester.tap(find.text('SDQ'));
    await tester.pumpAndSettle();
    expect(find.text('22/40'), findsOneWidget);

    await tester.tap(find.text('ทุนการศึกษา'));
    await tester.pumpAndSettle();
    expect(find.text('ทุนเรียนดี'), findsOneWidget);
    expect(find.text('รอพิจารณา'), findsOneWidget);

    await tester.tap(find.text('สั่งการติดตาม'));
    await tester.pumpAndSettle();
    expect(find.text('ติดตามผลการเรียน'), findsOneWidget);
    expect(find.text('รอรับทราบ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('creating a home visit calls the real RPC-backed callback', (
    tester,
  ) async {
    Map<String, dynamic>? captured;
    await _pump(
      tester,
      createHomeVisit:
          ({
            required studentId,
            required visitDate,
            required purpose,
            familySituation,
            followUpNeeded = false,
            followUpNotes,
          }) async {
            captured = {
              'studentId': studentId,
              'purpose': purpose,
              'followUpNeeded': followUpNeeded,
            };
            return 'new-visit-id';
          },
    );

    await tester.tap(find.text('+ บันทึกการเยี่ยมบ้าน'));
    await tester.pumpAndSettle();
    // Student picker dialog opens first.
    expect(
      find.text('เลือกนักเรียน'),
      findsOneWidget,
      reason: 'picker did not open',
    );
    await tester.tap(find.text('นักเรียนทดสอบ'));
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(TextField, 'วัตถุประสงค์การเยี่ยม *'),
      findsOneWidget,
      reason: 'home visit form did not open after picking student',
    );

    await tester.enterText(
      find.widgetWithText(TextField, 'วัตถุประสงค์การเยี่ยม *'),
      'เยี่ยมบ้านตามระบบดูแล',
    );
    await tester.pump();
    final saveButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'บันทึก'),
    );
    expect(
      saveButton.onPressed,
      isNotNull,
      reason: 'save button still disabled',
    );
    await tester.tap(find.text('บันทึก'));
    await tester.pumpAndSettle();

    expect(captured, isNotNull);
    expect(captured!['studentId'], 's1');
    expect(captured!['purpose'], 'เยี่ยมบ้านตามระบบดูแล');
    expect(find.textContaining('บันทึกการเยี่ยมบ้านแล้ว'), findsOneWidget);
  });

  testWidgets('a failed create shows a real failure, not a fake success', (
    tester,
  ) async {
    await _pump(
      tester,
      createHomeVisit:
          ({
            required studentId,
            required visitDate,
            required purpose,
            familySituation,
            followUpNeeded = false,
            followUpNotes,
          }) async => throw StateError('rpc_unreachable'),
    );

    await tester.tap(find.text('+ บันทึกการเยี่ยมบ้าน'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('นักเรียนทดสอบ'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'วัตถุประสงค์การเยี่ยม *'),
      'ทดสอบล้มเหลว',
    );
    await tester.pump();
    await tester.tap(find.text('บันทึก'));
    await tester.pumpAndSettle();

    expect(find.textContaining('บันทึกไม่สำเร็จ'), findsOneWidget);
    expect(find.textContaining('rpc_unreachable'), findsNothing);
  });
}
