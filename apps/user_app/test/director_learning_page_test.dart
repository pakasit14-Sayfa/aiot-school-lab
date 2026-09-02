import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/executive_redesign_prototype/pages/director_learning_page.dart';

void main() {
  group('DirectorLearningPage Redesign Tests', () {
    testWidgets('Renders all student executive command sections and handles interactions', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1440, 2400);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DirectorLearningPage(),
          ),
        ),
      );
      await tester.pump();

      // 1. Header
      expect(find.text('ศูนย์ภาพรวมและพัฒนานักเรียน'), findsOneWidget);
      expect(find.text('นักเรียนทั้งหมด 1,248 คน (ออนไลน์)'), findsOneWidget);

      // 2. Summary Cards
      expect(find.text('นักเรียนทั้งหมด'), findsOneWidget);
      expect(find.text('มาเรียนวันนี้'), findsOneWidget);
      expect(find.text('ขาดเรียน / ลา'), findsOneWidget);
      expect(find.text('มาสายวันนี้'), findsOneWidget);
      expect(find.text('เคสดูแลช่วยเหลือด่วน'), findsOneWidget);

      // 3. Urgent Watchlist
      expect(find.textContaining('EXECUTIVE WATCHLIST'), findsOneWidget);
      expect(find.text('ด.ช. ภานุวัฒน์ วิเศษสุข'), findsOneWidget);

      // 4. Academic Program Analytics
      expect(find.textContaining('การวิเคราะห์ผลการเรียนและสายการเรียน'), findsOneWidget);
      expect(find.text('วิทย์ - คณิต'), findsAtLeastNWidgets(1));
      expect(find.text('สายภาษา'), findsAtLeastNWidgets(1));
      expect(find.text('สายทั่วไป'), findsAtLeastNWidgets(1));

      // 5. Attendance & Student Care
      expect(find.textContaining('การมาเรียนแยกตามระดับชั้น'), findsOneWidget);
      expect(find.textContaining('ระบบดูแลช่วยเหลือนักเรียน'), findsOneWidget);

      // 6. Grade Deep Dive
      expect(find.textContaining('ข้อมูลเจาะลึกรายระดับชั้น'), findsOneWidget);

      // 7. Follow-up section
      expect(find.textContaining('ข้อเสนอแนะเชิงบริหารและงานติดตาม'), findsOneWidget);

      // 8. Test Open Student Care Modal
      final viewHistoryButtons = find.text('ดูประวัติ');
      expect(viewHistoryButtons, findsWidgets);
      await tester.tap(viewHistoryButtons.first);
      await tester.pumpAndSettle();

      expect(find.text('ประเด็นที่ต้องติดตาม: ขาดเรียนต่อเนื่อง 3 วันติด (ไม่มีใบลา)'), findsOneWidget);
      expect(find.text('เสร็จสิ้น'), findsOneWidget);
      await tester.tap(find.text('เสร็จสิ้น'));
      await tester.pumpAndSettle();
    });

    testWidgets('Responsive audit across small mobile, standard phone, tablet, and desktop', (tester) async {
      final testSizes = [
        const Size(320, 568),
        const Size(390, 844),
        const Size(768, 1024),
        const Size(1440, 900),
      ];

      for (final size in testSizes) {
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = size;

        FlutterErrorDetails? errorCaught;
        final oldHandler = FlutterError.onError;
        FlutterError.onError = (details) {
          errorCaught = details;
        };

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: DirectorLearningPage(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        FlutterError.onError = oldHandler;

        if (errorCaught != null) {
          debugPrint('>>> ERROR AT $size: ${errorCaught?.summary}');
          debugPrint('>>> CONTEXT: ${errorCaught?.context}');
        }
        expect(errorCaught, isNull, reason: 'Layout overflow at $size');
      }

      tester.view.resetPhysicalSize();
    });
  });
}
