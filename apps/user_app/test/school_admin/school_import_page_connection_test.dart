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
/// Per task_plan §"Security defects", the user-import path stays disabled
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

  testWidgets('user-creating import types are visibly marked as disabled', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('นักเรียน (ปิดชั่วคราว)'), findsOneWidget);
    expect(find.text('ครูและบุคลากร (ปิดชั่วคราว)'), findsOneWidget);

    // Types that create no credentials must stay usable.
    expect(find.text('อาคารและห้อง'), findsOneWidget);
    expect(find.text('อุปกรณ์'), findsOneWidget);
    expect(find.text('ชุดฝึก'), findsOneWidget);
  });

  testWidgets('the page does not default to a blocked type', (tester) async {
    await _pump(tester);

    // Defaulting to นักเรียน would land every admin on a dead-end screen.
    expect(find.text('เริ่มนำเข้าข้อมูล'), findsOneWidget);
    expect(
      find.text('ปิดชั่วคราวด้วยเหตุผลด้านความปลอดภัย'),
      findsNothing,
    );
  });

  testWidgets(
    'choosing a user type replaces the import action with a locked control',
    (tester) async {
      await _pump(tester);

      await tester.tap(find.text('นักเรียน (ปิดชั่วคราว)'));
      await tester.pumpAndSettle();

      expect(
        find.text('ปิดชั่วคราวด้วยเหตุผลด้านความปลอดภัย'),
        findsOneWidget,
      );
      expect(find.text('เริ่มนำเข้าข้อมูล'), findsNothing);

      // Genuinely disabled, not just relabelled. Matched by predicate because
      // FilledButton.icon builds a private subclass that find.byType misses.
      final disabled = find.byWidgetPredicate(
        (w) => w is ButtonStyleButton && w.onPressed == null,
      );
      expect(
        find.descendant(
          of: disabled,
          matching: find.text('ปิดชั่วคราวด้วยเหตุผลด้านความปลอดภัย'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('switching back to a safe type restores the import action', (
    tester,
  ) async {
    await _pump(tester);

    await tester.tap(find.text('ครูและบุคลากร (ปิดชั่วคราว)'));
    await tester.pumpAndSettle();
    expect(find.text('เริ่มนำเข้าข้อมูล'), findsNothing);

    await tester.tap(find.text('อุปกรณ์'));
    await tester.pumpAndSettle();
    expect(find.text('เริ่มนำเข้าข้อมูล'), findsOneWidget);
    expect(find.text('ปิดชั่วคราวด้วยเหตุผลด้านความปลอดภัย'), findsNothing);
  });
}
