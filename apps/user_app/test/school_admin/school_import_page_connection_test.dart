import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/school_admin/school_import_page.dart';
import 'package:shared_core/shared_core.dart';

/// Guards the security decision recorded on 2026-09-07.
///
/// Importing users used to create immediately-usable accounts with a
/// guessable password. Verified against the running database, all three
/// layers were true at once:
///   1. `import_school_users_batch_for_school_admin` hardcodes
///      `crypt('Test1234!', ...)` for every imported account
///   2. its INSERT never sets `must_change_password`, whose column default
///      is `false`
///   3. no Dart code anywhere in the repo reads `must_change_password`, so
///      no forced-change flow exists to fall back on
/// Accounts are created `status = 'active'`, so importing 500 students meant
/// 500 accounts anyone could sign into knowing only the email address.
///
/// (History) Per task_plan §"Security defects", the user-import path stayed disabled
/// until a real credential delivery/reset flow exists. Building, room and
/// device imports create no credentials and are unaffected.

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1500, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(const MaterialApp(home: SchoolImportPage()));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    currentUserModel = const UserModel(
      uid: 'admin-1',
      name: 'ผู้ดูแล ทดสอบ',
      email: 'admin@school.test',
      role: UserRole.schoolAdmin,
      schoolId: 'school-1',
    );
  });

  tearDown(() => currentUserModel = null);

  /// รอบ 2026-09-07 การนำเข้าผู้ใช้ถูกปิดเพราะรหัส 'Test1234!' เหมือนกันทุกคน —
  /// ตั้งแต่ 20260914020000 หลังบ้านออกรหัสชั่วคราวต่อคน + บังคับเปลี่ยน
  /// จึงเปิดใช้ได้ ไม่มีชิป "(ปิดชั่วคราว)" และปุ่มนำเข้าไม่ถูกล็อกตามชนิดข้อมูล
  testWidgets('user-creating import types are no longer marked as disabled', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('นักเรียน'), findsWidgets);
    expect(find.text('นักเรียน (ปิดชั่วคราว)'), findsNothing);
    expect(find.text('ครูและบุคลากร (ปิดชั่วคราว)'), findsNothing);

    await tester.tap(find.text('นักเรียน').first);
    await tester.pumpAndSettle();
    expect(find.text('ปิดชั่วคราวด้วยเหตุผลด้านความปลอดภัย'), findsNothing);
  });

  /// กล่องรหัสชั่วคราว: แสดงทุกบัญชี ดาวน์โหลดเป็น CSV ได้จริง
  testWidgets(
    'the credentials dialog lists each new account and downloads a real CSV',
    (tester) async {
      String? savedName;
      List<int>? savedBytes;
      late BuildContext ctx;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              ctx = context;
              return const Scaffold(body: SizedBox());
            },
          ),
        ),
      );
      showImportedCredentialsDialog(
        ctx,
        const [
          ImportedCredential(
            row: 1,
            email: 'a@school.test',
            tempPassword: 'Xk3pQ7mN2r',
          ),
          ImportedCredential(
            row: 2,
            email: 'b@school.test',
            tempPassword: 'Ht8wZ4cL6v',
          ),
        ],
        downloadBytesOverride:
            ({required filename, required bytes, required mimeType}) {
              savedName = filename;
              savedBytes = bytes;
            },
      );
      await tester.pumpAndSettle();

      expect(find.text('a@school.test'), findsOneWidget);
      expect(find.text('Xk3pQ7mN2r'), findsOneWidget);
      expect(
        find.textContaining('ต้องตั้งรหัสใหม่ในการเข้าสู่ระบบครั้งแรก'),
        findsOneWidget,
      );

      await tester.tap(find.text('ดาวน์โหลด CSV'));
      await tester.pumpAndSettle();
      expect(savedName, startsWith('temp_passwords_'));
      final csv = utf8.decode(savedBytes!);
      expect(csv, contains('b@school.test,Ht8wZ4cL6v'));
    },
  );
}
