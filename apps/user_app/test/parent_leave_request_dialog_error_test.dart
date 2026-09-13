import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/parent_redesign_prototype/pages/parent/leave_request_dialog.dart';

/// `submit_leave_request` ล้มแล้วหน้าจอเคยขึ้น `เกิดข้อผิดพลาด: PostgrestException(
/// message: invalid_date_range, code: P0001, ...)` ให้ผู้ปกครองอ่าน — รหัสที่
/// backend raise ต้องถูกแปลเป็นประโยคที่บอกว่าต้องแก้อะไร และรหัสที่ไม่รู้จัก
/// ต้องเป็นประโยคกลาง ไม่ใช่ข้อความ exception ดิบ
void main() {
  Future<void> pumpAndSubmit(
    WidgetTester tester, {
    required Object error,
  }) async {
    tester.view.physicalSize = const Size(1000, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LeaveRequestFormDialog(
            studentId: 'student-1',
            onSubmitted: () {},
            submitter: ({
              required studentId,
              required leaveType,
              required startDate,
              required endDate,
              required reason,
              attachmentFile,
            }) async => throw error,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'ไปหาหมอ');
    await tester.pump();
    final submit = find.text('ส่งคำขอลาเรียน');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
  }

  testWidgets('invalid_date_range from the RPC becomes a sentence the parent can act on', (
    tester,
  ) async {
    await pumpAndSubmit(
      tester,
      error: Exception('PostgrestException(message: invalid_date_range, code: P0001)'),
    );
    expect(find.text('วันสิ้นสุดต้องไม่ก่อนวันเริ่มลา'), findsOneWidget);
    expect(find.textContaining('PostgrestException'), findsNothing);
    expect(find.textContaining('เกิดข้อผิดพลาด:'), findsNothing);
  });

  testWidgets('forbidden becomes a permission sentence, not the raw code', (
    tester,
  ) async {
    await pumpAndSubmit(tester, error: Exception('forbidden'));
    expect(find.text('บัญชีนี้ไม่มีสิทธิ์ขอลาให้นักเรียนคนนี้'), findsOneWidget);
    expect(find.textContaining('Exception'), findsNothing);
  });

  testWidgets('an unknown failure shows a neutral sentence with no leaked exception text', (
    tester,
  ) async {
    await pumpAndSubmit(tester, error: StateError('socket_closed_secret'));
    expect(find.text('ส่งคำขอลาไม่สำเร็จ กรุณาลองใหม่อีกครั้ง'), findsOneWidget);
    expect(find.textContaining('socket_closed_secret'), findsNothing);
  });
}
