import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/executive_redesign_prototype/pages/director_overview_page.dart';

void main() {
  testWidgets('DirectorOverviewPage displays current Thai day, month, year as clean text in hero card', (tester) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DirectorOverviewPage(
            onNavigate: (_) {},
            sensorStreamOverride: const Stream.empty(),
            rawReadingsStreamOverride: const Stream.empty(),
          ),
        ),
      ),
    );
    await tester.pump();

    // 1. Verify "ศูนย์ควบคุมสำหรับผู้อำนวยการโรงเรียน"
    expect(find.text('ศูนย์ควบคุมสำหรับผู้อำนวยการโรงเรียน'), findsOneWidget);

    // 2. Verify date/month/year is displayed as text
    expect(find.textContaining('สิงหาคม'), findsWidgets);
    expect(find.textContaining('2569'), findsWidgets);

    // 3. Verify "ภาพรวมข้อมูล" and period tabs
    expect(find.text('ภาพรวมข้อมูล'), findsOneWidget);
    expect(find.text('รายวัน'), findsWidgets);
    expect(find.text('สัปดาห์'), findsWidgets);
    expect(find.text('เดือน'), findsWidgets);

    // 4. Verify sensor card header is present
    expect(find.text('ข้อมูลเซนเซอร์สภาพอากาศ AIoT'), findsOneWidget);
  });
}
