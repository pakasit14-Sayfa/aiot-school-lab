import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/executive_redesign_prototype/pages/director_emergency_page.dart';

void main() {
  group('DirectorEmergencyPage Tests', () {
    testWidgets('Renders executive emergency command center elements and handles interactions', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1440, 2400);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DirectorEmergencyPage(),
          ),
        ),
      );
      await tester.pump();

      // 1. Verify Executive Header
      expect(find.text('ศูนย์บัญชาการเหตุฉุกเฉินและความปลอดภัย'), findsOneWidget);
      expect(find.text('ระบบ IoT & SOS: ออนไลน์ 100%'), findsOneWidget);

      // 2. Verify 4 Executive Summary Cards
      expect(find.text('SOS รอรับเรื่อง'), findsOneWidget);
      expect(find.text('เหตุที่กำลังติดตาม'), findsOneWidget);
      expect(find.text('ปิดเหตุแล้ววันนี้'), findsOneWidget);
      expect(find.text('ความพร้อมทีมครูเวร'), findsOneWidget);

      // 3. Verify Live Activity SOS Panel (Active State)
      expect(find.text('LIVE EMERGENCY • สัญญาณ SOS ฉุกเฉิน'), findsOneWidget);
      expect(find.text('SOS จากนักเรียน ห้อง ม.3/2'), findsAtLeastNWidgets(1));
      expect(find.text('รอรับ SOS ด่วน'), findsOneWidget);
      expect(find.text('🚨 รับ SOS และสั่งการ'), findsOneWidget);

      // 4. Test Accepting SOS Action
      await tester.tap(find.text('🚨 รับ SOS และสั่งการ'));
      await tester.pumpAndSettle();

      // Dialog opens showing details
      expect(find.text('ข้อมูลจุดเกิดเหตุ'), findsOneWidget);
      // Close dialog
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      // State is now accepted
      expect(find.text('✓ ผอ. รับเรื่องแล้ว'), findsOneWidget);
      expect(find.text('ปิดเหตุการณ์ (เสร็จสิ้น)'), findsOneWidget);

      // 5. Test Resolving SOS
      await tester.tap(find.text('ปิดเหตุการณ์ (เสร็จสิ้น)'));
      await tester.pumpAndSettle();

      // 6. Verify Redesigned Resolved Safety Card
      expect(find.text('สภาวะปกติ • เหตุการณ์ SOS ล่าสุดได้รับการแก้ไขเรียบร้อยแล้ว'), findsOneWidget);
      expect(find.text('บันทึกการระงับเหตุ: SOS ห้อง ม.3/2'), findsOneWidget);
      expect(find.text('สรุปผลการปฏิบัติการระงับเหตุ'), findsOneWidget);
      expect(find.text('ดูรายงานสรุปและไทม์ไลน์'), findsOneWidget);
      expect(find.text('ดูภาพย้อนหลัง CCTV'), findsOneWidget);

      // 8. Verify Active Incidents
      expect(find.text('ตรวจพบเหตุทะเลาะวิวาท'), findsAtLeastNWidgets(1));
      expect(find.text('ตรวจพบนักเรียนล้ม'), findsAtLeastNWidgets(1));

      // 9. Verify Response Teams
      expect(find.text('ทีมเผชิญเหตุและช่วยเหลือ'), findsOneWidget);
      expect(find.text('ครูเวรประจำวัน (อาคาร 1–3)'), findsOneWidget);
      expect(find.text('ครูห้องพยาบาล / อนามัยโรงเรียน'), findsOneWidget);

      // 10. Verify History Filter Tabs
      expect(find.text('ทั้งหมด (5)'), findsOneWidget);
      expect(find.text('ปิดเหตุแล้ว (2)'), findsOneWidget);

      // Filter by 'ปิดเหตุแล้ว (2)'
      await tester.tap(find.text('ปิดเหตุแล้ว (2)'));
      await tester.pumpAndSettle();

      expect(find.text('ตรวจพบควันในห้องวิทยาศาสตร์'), findsOneWidget);
    });

    testWidgets('Responsive Layout Audit across multiple form factors without overflow', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final testSizes = [
        const Size(320, 568),   // iPhone SE 1st gen
        const Size(375, 667),   // iPhone SE 2nd gen
        const Size(390, 844),   // iPhone 12/13/14
        const Size(430, 932),   // iPhone 14 Pro Max
        const Size(768, 1024),  // iPad Mini portrait
        const Size(834, 1194),  // iPad Pro 11-inch
        const Size(1024, 768),  // iPad landscape
        const Size(1280, 800),  // Standard Laptop
        const Size(1440, 900),  // MacBook Pro 15
        const Size(1920, 1080), // Desktop FHD
      ];

      for (final size in testSizes) {
        tester.view.physicalSize = size;

        FlutterErrorDetails? caughtError;
        final originalOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          if (details.exceptionAsString().contains('overflowed')) {
            caughtError = details;
          }
          originalOnError?.call(details);
        };

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: DirectorEmergencyPage(),
            ),
          ),
        );
        await tester.pump();

        FlutterError.onError = originalOnError;

        expect(
          caughtError,
          isNull,
          reason: 'Failed responsive layout at size: ${size.width}x${size.height}',
        );
      }
    });
  });
}
