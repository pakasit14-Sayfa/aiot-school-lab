import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/main.dart';

void main() {
  testWidgets('signed-out user sees the real login screen', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(seconds: 1));

    // หน้า login ออกแบบใหม่ 2026-09-09 — ข้อความเปลี่ยนจากอังกฤษเป็นไทย
    // ทั้งหมด (ดู login_page_redesign_test.dart ที่ล็อกรายละเอียดไว้)
    expect(find.text('EDUSMART'), findsOneWidget);
    expect(find.text('เข้าสู่ระบบ'), findsWidgets);
    expect(find.text('ลืมรหัสผ่าน?'), findsOneWidget);
  });
}
