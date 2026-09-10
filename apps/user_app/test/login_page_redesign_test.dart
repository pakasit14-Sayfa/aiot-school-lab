import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/login_page.dart';

/// ล็อกการตัดสินใจของหน้า login ที่ออกแบบใหม่ 2026-09-09 ไว้กันหลุดกลับ
void main() {
  Future<void> pumpLogin(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    await tester.pump();
  }

  /// ปุ่ม Google/Apple เดิมเป็น `Container` ที่มีแต่ไอคอน ไม่มี onTap สักตัว
  /// และทำงานไม่ได้อยู่แล้วเพราะระบบนี้ไม่ได้ใช้ Supabase Auth (ใช้ session
  /// token ของตัวเอง — hard rule 1) การโชว์ทางเข้าที่ไม่มีอยู่จริงทำให้ผู้ใช้
  /// ที่กดแล้วไม่มีอะไรเกิดขึ้นเข้าใจว่าระบบพัง
  testWidgets('ต้องไม่มีปุ่มเข้าสู่ระบบด้วย Google/Apple ที่กดไม่ได้', (
    tester,
  ) async {
    await pumpLogin(tester);

    expect(find.text('or login with'), findsNothing);
    expect(find.byIcon(Icons.apple), findsNothing);
    expect(find.byIcon(Icons.g_mobiledata), findsNothing);
  });

  testWidgets('ข้อความบนหน้าต้องเป็นภาษาไทยทั้งหมด', (tester) async {
    await pumpLogin(tester);

    // ของเดิมหัวการ์ด ช่องกรอก และปุ่ม เป็นอังกฤษปนอยู่กลางแอปภาษาไทย
    expect(find.text('Welcome back'), findsNothing);
    expect(find.text('Login'), findsNothing);
    expect(find.text('Forgot Password?'), findsNothing);
    expect(find.text('Username'), findsNothing);
    expect(find.text('Password'), findsNothing);

    expect(find.text('เข้าสู่ระบบ'), findsWidgets);
    expect(find.text('ลืมรหัสผ่าน?'), findsOneWidget);
  });

  /// เดิม `labelText: ''` มีแต่ hint ซึ่งหายทันทีที่เริ่มพิมพ์ — กรอกไปแล้ว
  /// จะไม่มีอะไรบอกว่าช่องไหนคืออะไร
  testWidgets('ช่องกรอกต้องมี label จริง ไม่ใช่มีแต่ hint ที่หายตอนพิมพ์', (
    tester,
  ) async {
    await pumpLogin(tester);

    expect(find.text('อีเมล'), findsOneWidget);
    expect(find.text('รหัสผ่าน'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'teacher@x.ac.th');
    await tester.pump();

    // label ยังอยู่หลังพิมพ์แล้ว (ลอยขึ้นไปด้านบนช่อง)
    expect(find.text('อีเมล'), findsOneWidget);
  });

  /// เดิมกด Enter ที่ช่องรหัสผ่านแล้วไม่มีอะไรเกิดขึ้น ต้องเอื้อมไปกดปุ่ม
  /// ทุกครั้ง — สำคัญมากบนเว็บและแท็บเล็ตที่มีคีย์บอร์ด
  testWidgets('กด Enter ที่ช่องรหัสผ่านต้องส่งฟอร์ม', (tester) async {
    await pumpLogin(tester);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.first, 'schooladmin@aiot-school-lab.local');
    await tester.enterText(fields.last, 'Test1234!');
    await tester.pump();

    // ยังไม่กด Enter — ปุ่มต้องยังเป็นสถานะปกติ
    expect(find.text('กำลังเข้าสู่ระบบ…'), findsNothing);

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // ปุ่มเปลี่ยนเป็นสถานะกำลังทำงาน = เส้นทาง "กด Enter แล้วส่งฟอร์ม"
    // ถูกเรียกจริง (ในเทสต์ Supabase ยังไม่ init การเรียกจึงค้างอยู่ตรงนี้
    // ซึ่งไม่เป็นไร สิ่งที่ต้องพิสูจน์คือฟอร์มถูกส่ง)
    expect(find.text('กำลังเข้าสู่ระบบ…'), findsOneWidget);
  });

  testWidgets('ทางเข้าสำหรับคนที่ยังไม่มีบัญชี ต้องยังอยู่ครบทั้ง 2 ทาง', (
    tester,
  ) async {
    await pumpLogin(tester);

    expect(find.text('ยังไม่มีบัญชี?'), findsOneWidget);
    expect(
      find.text('มีรหัสเชิญจากโรงเรียน — สร้างบัญชี'),
      findsOneWidget,
    );
    expect(
      find.text('ผู้ปกครอง — มีรหัสผูกบัญชีนักเรียน'),
      findsOneWidget,
    );
  });

  /// การจับคู่เครื่องแล็บด้วย QR มีครบทั้ง backend และหน้าจอ แต่เดิมเข้าถึงได้
  /// จากเมนูในเชลล์นักเรียน **หลังล็อกอินแล้ว** เท่านั้น — คนที่ต้องใช้จริงคือ
  /// คนที่ยังไม่ได้ล็อกอินและยืนอยู่หน้าแท็บเล็ตในแล็บ
  testWidgets('ต้องมีทางเข้าด้วย QR สำหรับเครื่องแล็บบนหน้า login', (
    tester,
  ) async {
    await pumpLogin(tester);

    expect(
      find.text('เข้าสู่ระบบด้วย QR (เครื่องแล็บ)'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.qr_code_2_rounded), findsOneWidget);
    // และต้องอธิบายว่ามันทำอะไร ไม่ใช่ปุ่มลอย ๆ
    expect(
      find.textContaining('ให้นักเรียนที่ล็อกอินแล้วสแกน'),
      findsOneWidget,
    );
  });
}
