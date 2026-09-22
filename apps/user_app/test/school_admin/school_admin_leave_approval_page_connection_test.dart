import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/school_admin/school_admin_leave_approval_page.dart';
import 'package:shared_core/shared_core.dart';

/// Pins loading / data / empty / error apart for the leave register, and
/// guards the write→confirm contract on approve/reject — a review that
/// reports success without the RPC actually applying is a serious bug
/// class here, since it decides real paid/unpaid leave.

StaffLeaveRequest _request({
  String id = 'req-1',
  String name = 'ครู สมศรี',
  String status = 'pending',
  String? reviewerName,
  String? reviewNote,
}) => StaffLeaveRequest(
  requestId: id,
  userId: 'u-1',
  fullName: name,
  leaveType: 'sick',
  startDate: DateTime(2026, 9, 10),
  endDate: DateTime(2026, 9, 10),
  status: status,
  createdAt: DateTime(2026, 9, 7),
  reason: 'ไข้หวัดใหญ่',
  reviewerName: reviewerName,
  reviewNote: reviewNote,
);

Future<void> _pump(
  WidgetTester tester, {
  Future<List<StaffLeaveRequest>> Function({String? status})? loadRequests,
  Future<List<StaffLeaveAttachment>> Function(String requestId)?
  loadAttachments,
  Future<void> Function({
    required String requestId,
    required bool approve,
    String? note,
  })?
  reviewRequest,
}) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: SchoolAdminLeaveApprovalPage(
        loadRequests: loadRequests ?? ({status}) async => <StaffLeaveRequest>[],
        loadAttachments:
            loadAttachments ?? (id) async => <StaffLeaveAttachment>[],
        reviewRequest: reviewRequest,
      ),
    ),
  );
}

void main() {
  testWidgets('real pending requests are rendered', (tester) async {
    await _pump(tester, loadRequests: ({status}) async => [_request()]);
    await tester.pumpAndSettle();

    expect(find.text('ครู สมศรี'), findsOneWidget);
  });

  testWidgets('no requests says so, not an error', (tester) async {
    await _pump(tester);
    await tester.pumpAndSettle();

    expect(find.text('ไม่พบคำขอลาในหมวดนี้'), findsOneWidget);
  });

  testWidgets('a failed load is distinct from empty, with retry', (
    tester,
  ) async {
    var calls = 0;
    await _pump(
      tester,
      loadRequests: ({status}) async {
        calls++;
        throw StateError('backend detail that must stay internal');
      },
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('โหลดข้อมูลไม่สำเร็จ'), findsOneWidget);
    expect(calls, 1);
  });

  testWidgets('a slow load shows progress, not an empty result', (
    tester,
  ) async {
    final gate = Future.delayed(
      const Duration(milliseconds: 200),
      () => [_request()],
    );
    await _pump(tester, loadRequests: ({status}) => gate);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('the detail sheet shows real attachments when present', (
    tester,
  ) async {
    await _pump(
      tester,
      loadRequests: ({status}) async => [_request()],
      loadAttachments: (id) async => [
        StaffLeaveAttachment(
          attachmentId: 'a-1',
          fileName: 'ใบรับรองแพทย์.pdf',
          fileType: 'pdf',
          sizeBytes: 2048,
          uploaderName: 'ครู สมศรี',
          uploadedAt: DateTime(2026, 9, 7),
        ),
      ],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('ครู สมศรี'));
    await tester.pumpAndSettle();

    expect(find.text('ใบรับรองแพทย์.pdf'), findsOneWidget);
  });

  testWidgets('an empty attachment list says so, not an error', (tester) async {
    await _pump(tester, loadRequests: ({status}) async => [_request()]);
    await tester.pumpAndSettle();

    await tester.tap(find.text('ครู สมศรี'));
    await tester.pumpAndSettle();

    expect(find.text('ไม่มีไฟล์แนบ'), findsOneWidget);
  });

  testWidgets(
    'approving only reports success once reviewRequest actually resolves',
    (tester) async {
      await _pump(
        tester,
        loadRequests: ({status}) async => [_request()],
        reviewRequest: ({required requestId, required approve, note}) async {
          throw StateError('rpc rejected');
        },
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('ครู สมศรี'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('อนุมัติ'));
      await tester.pumpAndSettle();

      expect(find.text('ดำเนินการไม่สำเร็จ กรุณาลองใหม่'), findsOneWidget);
      expect(find.text('อนุมัติการลาแล้ว'), findsNothing);
      // The sheet stays open on failure — it must not silently pop as if
      // the approval had gone through.
      expect(find.text('อนุมัติ'), findsOneWidget);
    },
  );

  testWidgets('approving succeeds and reloads when reviewRequest resolves', (
    tester,
  ) async {
    var approved = false;
    await _pump(
      tester,
      loadRequests: ({status}) async => [
        _request(status: approved ? 'approved' : 'pending'),
      ],
      reviewRequest: ({required requestId, required approve, note}) async {
        approved = true;
      },
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('ครู สมศรี'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('อนุมัติ'));
    await tester.pumpAndSettle();

    expect(find.text('อนุมัติการลาแล้ว'), findsOneWidget);
  });

  testWidgets('rejecting passes approve:false through to the real seam', (
    tester,
  ) async {
    bool? capturedApprove;
    await _pump(
      tester,
      loadRequests: ({status}) async => [_request()],
      reviewRequest: ({required requestId, required approve, note}) async {
        capturedApprove = approve;
      },
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('ครู สมศรี'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ปฏิเสธ'));
    await tester.pumpAndSettle();

    expect(capturedApprove, false);
  });

  testWidgets('a decided request shows the reviewer, not action buttons', (
    tester,
  ) async {
    await _pump(
      tester,
      loadRequests: ({status}) async => [
        _request(
          status: 'approved',
          reviewerName: 'ผู้ดูแลระบบ',
          reviewNote: 'อนุมัติ',
        ),
      ],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('ครู สมศรี'));
    await tester.pumpAndSettle();

    expect(find.text('อนุมัติ'), findsNothing);
    expect(find.text('ปฏิเสธ'), findsNothing);
    expect(find.textContaining('ตัดสินใจโดย ผู้ดูแลระบบ'), findsOneWidget);
  });

  /// เดิม `catch (_)` แค่ปิดสถานะโหลด — ใบลาที่แนบใบรับรองแพทย์มาแต่โหลด
  /// ไฟล์แนบไม่สำเร็จจะขึ้นว่า "ไม่มีไฟล์แนบ" ซึ่งอาจทำให้ผู้อนุมัติปฏิเสธ
  /// ใบลาเพราะคิดว่าครูไม่ได้แนบหลักฐาน
  testWidgets('โหลดไฟล์แนบไม่สำเร็จ ต้องไม่ขึ้นว่า "ไม่มีไฟล์แนบ"', (
    tester,
  ) async {
    await _pump(
      tester,
      loadRequests: ({status}) async => [_request()],
      loadAttachments: (id) async => throw Exception('attachments_unreachable'),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('ครู สมศรี'));
    await tester.pumpAndSettle();

    expect(find.textContaining('โหลดไฟล์แนบไม่สำเร็จ'), findsOneWidget);
    expect(find.text('ไม่มีไฟล์แนบ'), findsNothing);
    expect(find.textContaining('attachments_unreachable'), findsNothing);
  });
}
