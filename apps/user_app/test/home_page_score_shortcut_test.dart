import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/coming_soon_page.dart';
import 'package:my_first_app/pages/home_page.dart';
import 'package:my_first_app/pages/student_redesign_prototype/widgets/student_score_page.dart';
import 'package:shared_core/shared_core.dart';

/// หน้าแรกของเส้นทางล็อกอินด้วย QR (student_qr_login_page → '/home' → HomePage)
/// มีปุ่ม "คะแนนของฉัน" ที่เคยเปิด ComingSoonPage ("เร็ว ๆ นี้") ทั้งที่ระบบมี
/// หน้าคะแนนที่ต่อ GradeService/GScoreService จริงอยู่แล้ว — นักเรียนที่ล็อกอิน
/// จากแท็บเล็ตในแล็บจึงถูกบอกว่าฟีเจอร์ยังไม่มี ส่วนเพื่อนที่ล็อกอินตามปกติ
/// เปิดหน้าเดียวกันนี้ได้จาก 3 ทางในเลน redesign
void main() {
  Future<void> pumpHome(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(loadNotifications: () async => <AppNotification>[]),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('ปุ่ม "คะแนนของฉัน" ต้องเปิดหน้าคะแนนจริง ไม่ใช่ "เร็ว ๆ นี้"', (
    tester,
  ) async {
    await pumpHome(tester);

    final tile = find.text('คะแนนของฉัน');
    expect(tile, findsOneWidget);

    await tester.ensureVisible(tile);
    await tester.pump();
    await tester.tap(tile);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(StudentScorePage), findsOneWidget);
    expect(find.byType(ComingSoonPage), findsNothing);
  });
}
