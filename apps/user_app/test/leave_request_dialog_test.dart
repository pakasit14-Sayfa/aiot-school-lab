import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/parent_redesign_prototype/pages/parent/leave_request_dialog.dart';

Future<void> _openDialog(
  WidgetTester tester, {
  required String? studentId,
  required LeaveRequestSubmitter submitter,
  VoidCallback? onSubmitted,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => LeaveRequestFormDialog(
                studentId: studentId,
                submitter: submitter,
                now: () => DateTime(2026, 9, 3),
                onSubmitted: onSubmitted ?? () {},
              ),
            ),
            child: const Text('เปิดแบบฟอร์ม'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('เปิดแบบฟอร์ม'));
  await tester.pumpAndSettle();
}

Future<void> _tapSubmit(WidgetTester tester) async {
  final submit = find.text('ส่งคำขอลาเรียน');
  await tester.ensureVisible(submit);
  await tester.tap(submit);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('requires a reason before submitting', (tester) async {
    var calls = 0;
    await _openDialog(
      tester,
      studentId: 'student-1',
      submitter:
          ({
            required studentId,
            required leaveType,
            required startDate,
            required endDate,
            required reason,
            attachmentFile,
          }) async {
            calls++;
          },
    );

    await _tapSubmit(tester);

    expect(find.text('กรุณาระบุเหตุผลการลา'), findsOneWidget);
    expect(calls, 0);
  });

  testWidgets('keeps missing linked student distinct from submit failure', (
    tester,
  ) async {
    var calls = 0;
    await _openDialog(
      tester,
      studentId: null,
      submitter:
          ({
            required studentId,
            required leaveType,
            required startDate,
            required endDate,
            required reason,
            attachmentFile,
          }) async {
            calls++;
          },
    );
    await tester.enterText(find.byType(TextField), 'ป่วยมีไข้');

    await _tapSubmit(tester);

    expect(
      find.text('ไม่สามารถส่งใบลาได้ เนื่องจากไม่พบข้อมูลนักเรียน'),
      findsOneWidget,
    );
    expect(calls, 0);
  });

  testWidgets('submits real form values through the service seam', (
    tester,
  ) async {
    String? submittedStudentId;
    String? submittedType;
    String? submittedReason;
    DateTime? submittedStart;
    DateTime? submittedEnd;
    var callbackCalled = false;

    await _openDialog(
      tester,
      studentId: 'student-1',
      onSubmitted: () => callbackCalled = true,
      submitter:
          ({
            required studentId,
            required leaveType,
            required startDate,
            required endDate,
            required reason,
            attachmentFile,
          }) async {
            submittedStudentId = studentId;
            submittedType = leaveType;
            submittedReason = reason;
            submittedStart = startDate;
            submittedEnd = endDate;
          },
    );
    await tester.enterText(find.byType(TextField), 'ป่วยมีไข้');

    await _tapSubmit(tester);

    expect(submittedStudentId, 'student-1');
    expect(submittedType, 'sick');
    expect(submittedReason, 'ป่วยมีไข้');
    expect(submittedStart, DateTime(2026, 9, 3));
    expect(submittedEnd, DateTime(2026, 9, 3));
    expect(callbackCalled, isTrue);
    expect(find.byType(LeaveRequestFormDialog), findsNothing);
  });
}
