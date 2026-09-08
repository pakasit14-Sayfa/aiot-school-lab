import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/teacher_redesign_prototype/teacher_leave_approval_page.dart';
import 'package:shared_core/shared_core.dart';

final _request = LeaveRequestForReview(
  leaveId: 'leave-1',
  studentId: 's-1',
  studentName: 'สมชาย ใจดี',
  leaveType: 'sick',
  startDate: DateTime(2026, 9, 8),
  endDate: DateTime(2026, 9, 8),
  reason: 'ไข้หวัดใหญ่',
  status: 'pending',
  createdAt: DateTime(2026, 9, 7),
);

Future<void> _pump(
  WidgetTester tester, {
  Future<List<LeaveRequestForReview>> Function()? listPendingLeaveRequests,
  Future<void> Function({
    required String leaveId,
    required String status,
    String? reviewNote,
  })?
  reviewLeaveRequest,
}) async {
  tester.view.physicalSize = const Size(1200, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: TeacherLeaveApprovalPage(
        listPendingLeaveRequests: listPendingLeaveRequests ?? () async => [_request],
        reviewLeaveRequest: reviewLeaveRequest,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a real pending request shows the real student/reason, not fabricated data', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text('สมชาย ใจดี'), findsOneWidget);
    expect(find.textContaining('ไข้หวัดใหญ่'), findsOneWidget);
    expect(find.text('ลาป่วย'), findsOneWidget);
  });

  testWidgets('approving calls the real RPC with the real leave id and approved status', (
    tester,
  ) async {
    String? reviewedId;
    String? reviewedStatus;
    await _pump(
      tester,
      reviewLeaveRequest: ({required leaveId, required status, reviewNote}) async {
        reviewedId = leaveId;
        reviewedStatus = status;
      },
    );

    await tester.tap(find.text('อนุมัติ'));
    await tester.pumpAndSettle();

    expect(reviewedId, 'leave-1');
    expect(reviewedStatus, 'approved');
  });

  testWidgets('rejecting calls the real RPC with the real leave id and rejected status', (
    tester,
  ) async {
    String? reviewedStatus;
    await _pump(
      tester,
      reviewLeaveRequest: ({required leaveId, required status, reviewNote}) async {
        reviewedStatus = status;
      },
    );

    await tester.tap(find.text('ไม่อนุมัติ'));
    await tester.pumpAndSettle();

    expect(reviewedStatus, 'rejected');
  });

  testWidgets('zero pending requests shows an honest empty state', (
    tester,
  ) async {
    await _pump(tester, listPendingLeaveRequests: () async => const []);
    expect(find.text('ไม่มีคำขอลาเรียนรอดำเนินการ'), findsOneWidget);
  });

  testWidgets('a real load failure shows an honest error, no leaked exception text', (
    tester,
  ) async {
    await _pump(
      tester,
      listPendingLeaveRequests: () async =>
          throw StateError('backend detail that must stay internal'),
    );
    expect(find.text('โหลดคำขอลาไม่สำเร็จ'), findsOneWidget);
    expect(find.textContaining('backend detail'), findsNothing);
  });
}
