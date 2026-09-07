import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_core/shared_core.dart';
import 'package:my_first_app/pages/role_router.dart';
import 'package:my_first_app/pages/super_admin/super_admin_hub_page.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('RoleRouter routes super_admin to SuperAdminHubPage landing page', (tester) async {
    tester.view.physicalSize = const Size(1200, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    currentUserModel = const UserModel(
      uid: 'test-super-admin-id',
      email: 'admin@aiot-school-lab.local',
      role: UserRole.superAdmin,
      name: 'Super Admin User',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: RoleRouter(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(SuperAdminHubPage), findsOneWidget);
    // At this width (>= 980) SuperAdminNavigationShell embeds the hub page
    // with its own AppBar suppressed (`embedded: true`), so the AppBar
    // title text never renders here — assert on the quick-action panel
    // title instead, which SuperAdminHubPage always renders in its body
    // regardless of the embedded flag.
    expect(find.text('ศูนย์สั่งการหลัก (Platform Control Hub)'), findsOneWidget);
  });
}
