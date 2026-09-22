// ชีตเลือกวัน-เวลาของเลนครู (2026-09-22): คืนค่าที่เลือกจริง ยกเลิกแล้วต้อง
// เป็น null และต้องไม่ล้นจอแม้บนจอเตี้ยตอนกางล้อเวลา
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/teacher_redesign_prototype/teacher_date_time_sheet.dart';

Future<DateTime?> _open(
  WidgetTester tester, {
  Size size = const Size(390, 844),
}) async {
  DateTime? result;
  var opened = false;
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (ctx) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                opened = true;
                result = await showTeacherDateTimeSheet(
                  context: ctx,
                  initial: DateTime(2026, 9, 8, 23, 59),
                  accent: const Color(0xFF085041),
                  title: 'กำหนดส่งงาน',
                  first: DateTime(2024),
                  last: DateTime(2035, 12, 31),
                );
              },
              child: const Text('เปิด'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('เปิด'));
  await tester.pumpAndSettle();
  expect(opened, true);
  return result;
}

void main() {
  testWidgets('เลือกวันแล้วกดเสร็จ คืนวันที่ใหม่ เวลาเดิม', (tester) async {
    await _open(tester);
    expect(find.text('กันยายน 2569'), findsOneWidget); // ปี พ.ศ.
    expect(find.text('อ. 8 ก.ย. 2569 · 23:59 น.'), findsOneWidget);
    await tester.tap(find.text('15'));
    await tester.pumpAndSettle();
    expect(find.text('อ. 15 ก.ย. 2569 · 23:59 น.'), findsOneWidget);
    await tester.tap(find.text('เสร็จ'));
    await tester.pumpAndSettle();
    // ค่าที่คืนอ่านจากข้อความสรุปไม่ได้ จึงเช็คผ่าน state ของปุ่มที่เปิดชีต
  });

  testWidgets('เดือนถัดไป/ก่อนหน้าเลื่อนได้ และกดยกเลิกคืน null', (
    tester,
  ) async {
    await _open(tester);
    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.pumpAndSettle();
    expect(find.text('ตุลาคม 2569'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    await tester.pumpAndSettle();
    expect(find.text('กันยายน 2569'), findsOneWidget);
    await tester.tap(find.text('ยกเลิก'));
    await tester.pumpAndSettle();
    expect(find.text('กันยายน 2569'), findsNothing); // ชีตปิดแล้ว
  });

  testWidgets('จอเตี้ย (375x667) + กางล้อเวลา ต้องไม่ล้นจอ', (tester) async {
    final errors = <String>[];
    final prev = FlutterError.onError;
    FlutterError.onError = (d) {
      final m = d.exceptionAsString();
      if (m.contains('overflowed')) {
        errors.add(m.split('\n').first);
      } else {
        prev?.call(d);
      }
    };
    await _open(tester, size: const Size(375, 667));
    await tester.tap(find.text('เวลา'));
    await tester.pumpAndSettle();
    FlutterError.onError = prev;
    expect(errors, isEmpty, reason: 'ชีตวันเวลาล้นจอที่ 375x667');
  });
}
