import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/teacher_redesign_prototype/teacher_parent_binding_approval_page.dart';
import 'package:shared_core/shared_core.dart';

final _link = ParentLink(
  id: 'link-1',
  studentId: 's-1',
  studentName: 'สมชาย ใจดี',
  parentId: 'p-1',
  parentName: 'สมหญิง ใจดี',
  parentEmail: 'somying@test.local',
  relationship: 'มารดา',
  status: 'pending',
  requestedAt: DateTime(2026, 9, 1),
);

Future<void> _pump(
  WidgetTester tester, {
  Future<List<ParentLink>> Function({String status, String? schoolId})?
  listParentLinks,
  Future<void> Function(String parentLinkId)? approveParentLink,
  Future<void> Function(String parentLinkId, {String? reason})?
  rejectParentLink,
}) async {
  tester.view.physicalSize = const Size(1200, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: TeacherParentBindingApprovalPage(
        listParentLinks:
            listParentLinks ?? ({status = 'pending', schoolId}) async => [_link],
        approveParentLink: approveParentLink,
        rejectParentLink: rejectParentLink,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'a real pending link shows the real parent/student/relationship, not fabricated data',
    (tester) async {
      await _pump(tester);
      expect(find.text('สมหญิง ใจดี'), findsOneWidget);
      expect(find.textContaining('somying@test.local'), findsOneWidget);
      expect(find.textContaining('สมชาย ใจดี'), findsOneWidget);
      expect(find.textContaining('มารดา'), findsOneWidget);
    },
  );

  testWidgets(
    'approving calls the real RPC with the real link id after confirming the dialog',
    (tester) async {
      String? approvedId;
      await _pump(
        tester,
        approveParentLink: (id) async {
          approvedId = id;
        },
      );

      await tester.tap(find.text('อนุมัติ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ยืนยันอนุมัติ'));
      await tester.pumpAndSettle();

      expect(approvedId, 'link-1');
    },
  );

  testWidgets(
    'rejecting requires a reason and calls the real RPC with the real link id + reason',
    (tester) async {
      String? rejectedId;
      String? rejectedReason;
      await _pump(
        tester,
        rejectParentLink: (id, {reason}) async {
          rejectedId = id;
          rejectedReason = reason;
        },
      );

      await tester.tap(find.text('ปฏิเสธ'));
      await tester.pumpAndSettle();

      // Confirm button stays disabled until a reason is entered.
      final confirmButtonFinder = find.widgetWithText(FilledButton, 'ปฏิเสธคำขอ');
      expect(tester.widget<FilledButton>(confirmButtonFinder).onPressed, isNull);

      await tester.enterText(find.byType(TextField), 'ข้อมูลไม่ตรงกับทะเบียนนักเรียน');
      await tester.pumpAndSettle();
      await tester.tap(confirmButtonFinder);
      await tester.pumpAndSettle();

      expect(rejectedId, 'link-1');
      expect(rejectedReason, 'ข้อมูลไม่ตรงกับทะเบียนนักเรียน');
    },
  );

  testWidgets('zero pending links shows an honest empty state', (tester) async {
    await _pump(tester, listParentLinks: ({status = 'pending', schoolId}) async => const []);
    expect(find.text('ไม่มีคำขอรออนุมัติแล้ว'), findsOneWidget);
  });

  testWidgets('a real load failure shows an honest error, no leaked exception text', (
    tester,
  ) async {
    await _pump(
      tester,
      listParentLinks: ({status = 'pending', schoolId}) async =>
          throw StateError('backend detail that must stay internal'),
    );
    expect(find.text('โหลดคำขอผูกบัญชีไม่สำเร็จ'), findsOneWidget);
    expect(find.textContaining('backend detail'), findsNothing);
  });

  /// ตั้งแต่ migration 20260909010000 ครูเห็น/อนุมัติได้เฉพาะนักเรียนในห้องที่
  /// ตัวเองเป็นครูประจำชั้น — ครูที่เคยเห็นคำขอทั้งโรงเรียนจะเห็นหน้าว่างเปล่า
  /// จึงต้องบอกขอบเขตไว้ ไม่ใช่ปล่อยให้เข้าใจว่าระบบพัง
  testWidgets('หน้าว่างต้องบอกด้วยว่าเห็นเฉพาะห้องที่ตัวเองเป็นครูประจำชั้น', (
    tester,
  ) async {
    await _pump(
      tester,
      listParentLinks: ({status = 'pending', schoolId}) async => [],
    );
    await tester.pumpAndSettle();

    expect(find.text('ไม่มีคำขอรออนุมัติแล้ว'), findsOneWidget);
    expect(
      find.textContaining('เฉพาะคำขอของนักเรียนในห้องที่คุณเป็น'),
      findsOneWidget,
    );
  });
}
