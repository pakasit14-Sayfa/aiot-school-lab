import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/school_admin/school_permissions_page.dart';
import 'package:shared_core/shared_core.dart';

/// หน้า "จัดการสิทธิ์" เคยเก็บค่าจากไดอะล็อกครบ 3 อย่าง (บทบาท · ขอบเขต ·
/// สถานะบัญชี) แต่ตอนกดบันทึกส่งไปหลังบ้านแค่ `role` แล้วขึ้นข้อความ
/// "บันทึกการแก้ไขสิทธิ์เรียบร้อยแล้ว" เสมอ — ผู้ดูแลโรงเรียนที่กดระงับบัญชี
/// จะเชื่อว่าบัญชีนั้นถูกระงับแล้ว ทั้งที่ยังเข้าใช้งานได้ตามปกติ
void main() {
  UserModel user({String status = 'active'}) => UserModel(
    uid: 'u-1',
    name: 'ครูสมชาย ใจดี',
    email: 'somchai@school.ac.th',
    role: UserRole.teacher,
    building: 'อาคารเรียน A',
    status: status,
  );

  Future<void> openEditDialog(WidgetTester tester) async {
    await tester.pumpAndSettle();
    final menu = find.byType(PopupMenuButton<String>);
    expect(menu, findsWidgets, reason: 'ต้องเจอเมนูของแถวผู้ใช้');
    await tester.tap(menu.first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('แก้ไขสิทธิ์').last);
    await tester.pumpAndSettle();
  }

  Widget page({
    required List<UserModel> users,
    Future<void> Function(String uid)? suspend,
    Future<void> Function(String uid)? reactivate,
  }) => MaterialApp(
    home: SchoolPermissionsPage(
      loadUsers: () async => users,
      loadLogs: () async => const <SchoolAdminAuditLog>[],
      loadPermissionMatrix: () async => const <RolePermissionEntry>[],
      updateRole: ({required String uid, required UserRole role}) async {},
      suspendUser: suspend ?? (_) async {},
      reactivateUser: reactivate ?? (_) async {},
    ),
  );

  setUp(() => TestWidgetsFlutterBinding.ensureInitialized());

  testWidgets('ขอบเขตการเข้าถึงต้องไม่ใช่ช่องที่แก้ได้ เพราะบันทึกไม่ได้จริง', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(page(users: [user()]));
    await openEditDialog(tester);

    // ค่าจริงจากโปรไฟล์ยังต้องเห็น
    expect(find.text('อาคารเรียน A'), findsWidgets);
    // แต่ต้องบอกว่าแก้ที่นี่ไม่ได้ และไม่มีตัวเลือกที่แต่งขึ้นให้กด
    expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
    expect(find.textContaining('แก้ที่หน้าข้อมูลบุคลากร'), findsOneWidget);
    expect(find.text('เฉพาะชั้นเรียนที่สอน'), findsNothing);
    expect(find.text('ม.1/1'), findsNothing);

    // "รอตรวจสอบ" ไม่เคยมีอยู่จริงในระบบ (มีแค่ active/suspended)
    expect(find.text('รอตรวจสอบ'), findsNothing);
  });

  testWidgets('ระงับบัญชีไม่สำเร็จ ต้องไม่ขึ้นว่าบันทึกเรียบร้อย', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    // หลังบ้านโยน error — และถึงโหลดใหม่ สถานะก็ยังเป็น active เหมือนเดิม
    await tester.pumpWidget(
      page(
        users: [user()],
        suspend: (_) async => throw Exception('permission denied'),
      ),
    );
    await openEditDialog(tester);

    // 2 ตัวแรกคือ filter ของหน้าที่อยู่หลังไดอะล็อก ตัวสุดท้ายคือสถานะบัญชี
    final statusDropdown = find.byType(DropdownButton<String>).last;
    await tester.tap(statusDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('ระงับ').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('บันทึกการแก้ไข'));
    await tester.pumpAndSettle();

    expect(find.text('บันทึกการแก้ไขสิทธิ์เรียบร้อยแล้ว'), findsNothing);
    expect(find.textContaining('ไม่สำเร็จ'), findsWidgets);
    // และต้องไม่โยน exception ดิบขึ้นจอ
    expect(find.textContaining('permission denied'), findsNothing);
  });

  testWidgets('กดระงับแล้วหลังบ้านไม่เปลี่ยนตาม ต้องบอกว่าไม่สำเร็จ', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    // เรียกผ่านไม่ error แต่โหลดกลับมาแล้วยังเป็น active — คือไม่สำเร็จจริง
    await tester.pumpWidget(page(users: [user()], suspend: (_) async {}));
    await openEditDialog(tester);

    // 2 ตัวแรกคือ filter ของหน้าที่อยู่หลังไดอะล็อก ตัวสุดท้ายคือสถานะบัญชี
    final statusDropdown = find.byType(DropdownButton<String>).last;
    await tester.tap(statusDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('ระงับ').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('บันทึกการแก้ไข'));
    await tester.pumpAndSettle();

    expect(find.text('บันทึกการแก้ไขสิทธิ์เรียบร้อยแล้ว'), findsNothing);
    expect(
      find.text('เปลี่ยนสถานะบัญชีไม่สำเร็จ กรุณาลองใหม่อีกครั้ง'),
      findsOneWidget,
    );
  });
}
