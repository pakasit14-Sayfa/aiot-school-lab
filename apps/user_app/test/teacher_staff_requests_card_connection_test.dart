import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/teacher_redesign_prototype/teacher_staff_requests_card.dart';
import 'package:shared_core/services/staff_request_service.dart';

/// 2026-09-17: create_staff_request / cancel_staff_request had no caller in
/// the app. This card is the teacher's entry point; the fake RPC below is a
/// tiny in-memory backend so every assertion is about the real contract.
Map<String, dynamic> _row(String id, String status, {String type = 'meet_request', String subject = 'ขอเข้าพบ'}) => {
  'request_id': id,
  'requester_id': 'teacher',
  'requester_name': 'ครู',
  'request_type': type,
  'subject': subject,
  'start_date': '2026-09-20',
  'status': status,
};

class _FakeBackend {
  final rows = <Map<String, dynamic>>[];
  final calls = <String>[];
  bool failCreate = false;
  bool cancelDoesNothing = false;

  Future<dynamic> rpc(String name, Map<String, dynamic> p) async {
    calls.add(name);
    switch (name) {
      case 'list_staff_requests':
        return List.of(rows);
      case 'create_staff_request':
        if (failCreate) throw StateError('secret-backend');
        expect(p['p_token'], 'session');
        final id = 'r${rows.length + 1}';
        rows.add(_row(id, 'pending_executive',
            type: p['p_request_type'] as String, subject: p['p_subject'] as String));
        return id;
      case 'cancel_staff_request':
        if (!cancelDoesNothing) {
          final r = rows.firstWhere((x) => x['request_id'] == p['p_request_id']);
          r['status'] = 'cancelled';
        }
        return null;
    }
    throw UnimplementedError(name);
  }
}

Future<_FakeBackend> _pump(WidgetTester tester, {List<Map<String, dynamic>> seed = const []}) async {
  final backend = _FakeBackend()..rows.addAll(seed.map((r) => Map.of(r)));
  tester.view.physicalSize = const Size(900, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: TeacherStaffRequestsCard(
          service: StaffRequestService(token: () => 'session', rpc: backend.rpc),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return backend;
}

void main() {
  testWidgets('no requests is an honest empty state', (tester) async {
    await _pump(tester);
    expect(find.text('ยังไม่มีคำขอ'), findsOneWidget);
    expect(find.text('ยื่นคำขอ'), findsOneWidget);
  });

  testWidgets('filing a request calls create_staff_request and lists the backend row', (
    tester,
  ) async {
    final backend = await _pump(tester);
    await tester.tap(find.text('ยื่นคำขอ'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'เรื่อง'), 'ขอพบเรื่องงบแล็บ');
    await tester.enterText(
      find.widgetWithText(TextField, 'วันที่ขอเข้าพบ (ปี-เดือน-วัน)'),
      '2026-09-20',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'ยื่นคำขอ').last);
    await tester.pumpAndSettle();

    expect(backend.calls, contains('create_staff_request'));
    expect(find.textContaining('ขอพบเรื่องงบแล็บ'), findsOneWidget);
    expect(find.textContaining('รอผู้อำนวยการ'), findsWidgets);
    expect(find.textContaining('ยื่นคำขอแล้ว'), findsOneWidget);
  });

  testWidgets('a failed create is reported in the sheet, never as filed', (tester) async {
    final backend = await _pump(tester);
    backend.failCreate = true;
    await tester.tap(find.text('ยื่นคำขอ'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'เรื่อง'), 'x');
    await tester.enterText(find.widgetWithText(TextField, 'วันที่ขอเข้าพบ (ปี-เดือน-วัน)'), '2026-09-20');
    await tester.tap(find.widgetWithText(FilledButton, 'ยื่นคำขอ').last);
    await tester.pumpAndSettle();
    expect(find.text('ยื่นคำขอไม่สำเร็จ กรุณาลองใหม่อีกครั้ง'), findsOneWidget);
    expect(find.textContaining('secret-backend'), findsNothing);
    expect(find.textContaining('ยื่นคำขอแล้ว'), findsNothing);
  });

  testWidgets('cancel is confirmed by read-back; a row that stays pending is a failure', (
    tester,
  ) async {
    final backend = await _pump(tester, seed: [_row('r1', 'pending_executive')]);
    backend.cancelDoesNothing = true;
    await tester.tap(find.text('ยกเลิก'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'ยกเลิกคำขอ'));
    await tester.pumpAndSettle();
    expect(backend.calls, contains('cancel_staff_request'));
    expect(find.text('ยกเลิกไม่สำเร็จ คำขอยังอยู่ในคิว'), findsOneWidget);
    expect(find.textContaining('รอผู้อำนวยการ'), findsWidgets);
  });

  testWidgets('a real cancel shows the request as cancelled', (tester) async {
    await _pump(tester, seed: [_row('r1', 'pending_executive')]);
    await tester.tap(find.text('ยกเลิก'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'ยกเลิกคำขอ'));
    await tester.pumpAndSettle();
    expect(find.textContaining('ยกเลิกแล้ว'), findsWidgets);
    expect(find.text('ยกเลิก'), findsNothing); // no cancel button on a cancelled row
  });
}
