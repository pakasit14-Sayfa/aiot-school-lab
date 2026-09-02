import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/executive_redesign_prototype/pages/director_overview_page.dart';

void main() {
  group('DirectorOverviewPage Comprehensive Responsive Audit', () {
    testWidgets('Dynamically resizes across all screen form factors without overflow or exception', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Start at standard desktop
      tester.view.physicalSize = const Size(1440, 900);
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
      expect(tester.takeException(), isNull);

      final screenSizes = [
        const Size(1920, 1080), // 1080p
        const Size(1440, 900),  // Desktop Large
        const Size(1200, 800),  // Desktop Medium
        const Size(980, 800),   // Desktop Breakpoint
        const Size(950, 800),   // Compact Tablet Transition
        const Size(834, 1194),  // iPad Air
        const Size(768, 1024),  // iPad Mini
        const Size(500, 800),   // Phablet
        const Size(414, 896),   // iPhone 11 Pro Max
        const Size(390, 844),   // iPhone 14
        const Size(360, 780),   // Android Compact
        const Size(320, 568),   // Small Phone
        const Size(1440, 900),  // Expand back to Desktop
      ];


      for (final size in screenSizes) {
        tester.view.physicalSize = size;
        await tester.pump();
        final exception = tester.takeException();
        expect(
          exception,
          isNull,
          reason: 'Failed responsive layout at size: ${size.width}x${size.height}',
        );
      }
    });
  });
}
