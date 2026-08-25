import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/parent_redesign_prototype/pages/parent/parent_attendance_page.dart';

void main() {
  testWidgets('ParentAttendancePage shows honest empty states with 0 mock timestamps', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));

    await tester.pumpWidget(
      const MaterialApp(
        home: ParentAttendancePage(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify honest empty state messages are rendered
    expect(find.text('ยังไม่มีประวัติการเช็คชื่อวันนี้'), findsWidgets);
    expect(find.text('ยังไม่มีข้อมูลการเข้าเรียนประจำคาบในวันนี้'), findsOneWidget);
    expect(find.text('ยังไม่มีประวัติการมาเรียน'), findsOneWidget);

    // Verify fake mock timestamps and hardcoded items DO NOT exist
    expect(find.text('07:41'), findsNothing);
    expect(find.text('08:26'), findsNothing);
    expect(find.text('21 ส.ค. 2569'), findsNothing);
    expect(find.text('ตรวจพบการเข้าโรงเรียนเรียบร้อย'), findsNothing);
  });
}
