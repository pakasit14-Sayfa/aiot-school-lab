import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/executive_redesign_prototype/pages/director_overview_page.dart';

void main() {
  testWidgets('DirectorOverviewPage renders new summary card design with colored header banners', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1440, 900);
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

    // Verify 4 Titles inside header banners
    expect(find.text('นักเรียนทั้งหมด'), findsOneWidget);
    expect(find.text('ครูและบุคลากร'), findsOneWidget);
    expect(find.text('ความปลอดภัย & ฉุกเฉิน'), findsOneWidget);
    expect(find.text('อุปกรณ์ IoT ในห้องเรียน'), findsOneWidget);

    // Verify units and affordances
    expect(find.text('คน'), findsAtLeastNWidgets(2));
    expect(find.text('เหตุการณ์'), findsOneWidget);
    expect(find.text('ดูข้อมูล'), findsAtLeastNWidgets(4));

    // Tap on the Students card to verify dialog opening
    await tester.tap(find.text('นักเรียนทั้งหมด'));
    await tester.pumpAndSettle();

    expect(find.text('การเข้าเรียนของนักเรียน'), findsOneWidget);
  });
}
