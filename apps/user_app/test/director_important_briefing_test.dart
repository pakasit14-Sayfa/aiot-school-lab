import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/executive_redesign_prototype/pages/director_overview_page.dart';

void main() {
  testWidgets('DirectorOverviewPage renders redesigned executive briefing cards with interactive filters', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1440, 2400);
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DirectorOverviewPage(
            onNavigate: (_) {},
            sensorStreamOverride: const Stream.empty(),
          ),
        ),
      ),
    );
    await tester.pump();

    // Verify Title
    expect(find.text('สิ่งที่ควรทราบวันนี้'), findsOneWidget);

    // Verify Filter Tabs
    expect(find.text('ทั้งหมด (6)'), findsOneWidget);
    expect(find.text('ต้องติดตาม (4)'), findsOneWidget);
    expect(find.text('ข้อมูล & นัดหมาย (2)'), findsOneWidget);

    // Verify urgent brawl item and status are present
    expect(find.text('ตรวจพบเหตุทะเลาะวิวาท'), findsOneWidget);
    expect(find.text('ต้องดำเนินการด่วน'), findsOneWidget);
    expect(find.text('ความปลอดภัย'), findsOneWidget);
    expect(find.text('ดูกล้อง CCTV'), findsOneWidget);

    // Tap on filter 'ข้อมูล & นัดหมาย (2)'
    await tester.tap(find.text('ข้อมูล & นัดหมาย (2)'));
    await tester.pump();

    // Brawl card should be filtered out
    expect(find.text('ตรวจพบเหตุทะเลาะวิวาท'), findsNothing);
    // Meeting card should remain
    expect(find.text('มีนัดประชุมฝ่ายบริหารวันนี้'), findsOneWidget);
    expect(find.text('ตามกำหนดการ'), findsOneWidget);

    // Tap on meeting card to open modal
    await tester.tap(find.text('มีนัดประชุมฝ่ายบริหารวันนี้'));
    await tester.pumpAndSettle();

    expect(find.text('บันทึกรับทราบ'), findsOneWidget);
    expect(find.text('สถานะปัจจุบัน: ตามกำหนดการ'), findsOneWidget);
  });
}
