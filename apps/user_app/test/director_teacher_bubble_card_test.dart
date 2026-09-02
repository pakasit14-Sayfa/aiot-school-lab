import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/executive_redesign_prototype/pages/director_overview_page.dart';

void main() {
  testWidgets('DirectorOverviewPage renders teacher bubble cluster and legends', (tester) async {
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

    // Verify Title and View Report button
    expect(find.text('ภาพรวมครูและการสอน'), findsOneWidget);
    expect(find.text('ดูรายงาน'), findsNWidgets(2));

    // Verify 4 Pastel Bubbles
    expect(find.text('48%'), findsOneWidget);
    expect(find.text('32%'), findsOneWidget);
    expect(find.text('13%'), findsOneWidget);
    expect(find.text('7%'), findsOneWidget);

    // Verify 4 Category Legends
    expect(find.text('สอนในตารางปกติ'), findsOneWidget);
    expect(find.text('กิจกรรม & แล็บ'), findsOneWidget);
    expect(find.text('จัดครูสอนแทน'), findsOneWidget);
    expect(find.text('เตรียมสอน/ประชุม'), findsOneWidget);

    // Tap on the 48% bubble to trigger drill-down modal
    await tester.tap(find.text('48%'));
    await tester.pumpAndSettle();

    expect(find.text('การสอนตามตารางวิชาการ'), findsOneWidget);
  });
}
