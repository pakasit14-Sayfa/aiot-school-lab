import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/executive_redesign_prototype/theme/app_palette.dart';
import 'package:my_first_app/pages/executive_redesign_prototype/widgets/director_navigation_shell.dart';
import 'package:shared_core/shared_core.dart';

/// `DirectorNavigationShell` had no test file at all — the notification
/// badge/panel called `NotificationService` directly with no injection
/// seam, so nothing verified the badge actually reflects real unread
/// counts (it used to be a hardcoded `dot: true`, always on) or that the
/// panel renders real notification rows rather than something invented.
/// `loadNotificationCategories`/`loadNotifications` close that gap the same
/// way `loadReports`/`listSchoolDevices` etc. do on other executive pages.

AppNotification _notification({
  String id = 'n1',
  String type = 'meeting_invite',
  String title = 'เชิญเข้าร่วมประชุม',
  String? body = 'ประชุมคณะกรรมการบริหารประจำเดือน',
  DateTime? createdAt,
  DateTime? readAt,
  String category = 'meeting',
}) => AppNotification(
  id: id,
  type: type,
  title: title,
  body: body,
  createdAt: createdAt ?? DateTime(2026, 9, 15, 8),
  readAt: readAt,
  category: category,
);

NotificationCategory _category({
  required String category,
  required int total,
  required int unread,
}) => NotificationCategory.fromRow({
  'category': category,
  'total': total,
  'unread': unread,
});

Future<void> _pump(
  WidgetTester tester, {
  Future<List<NotificationCategory>> Function()? loadNotificationCategories,
  Future<List<AppNotification>> Function(String?)? loadNotifications,
}) async {
  tester.view.physicalSize = const Size(1500, 2200);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  currentUserModel = const UserModel(
    uid: 'dir-1',
    name: 'สมศรี ทดสอบ',
    email: 'director.real@aiot-school-lab.local',
    role: UserRole.executive,
    schoolId: 'school-1',
  );
  addTearDown(() => currentUserModel = null);

  await tester.pumpWidget(
    MaterialApp(
      home: DirectorNavigationShell(
        loadNotificationCategories: loadNotificationCategories,
        loadNotifications: loadNotifications,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// The bell's dot is a plain circular `Container` colored `AppPalette.danger`
/// — matching on that directly proves the *actual* indicator on screen, not
/// just that some unrelated widget exists.
bool _hasRedDot(WidgetTester tester) {
  final containers = tester.widgetList<Container>(find.byType(Container));
  for (final c in containers) {
    final decoration = c.decoration;
    if (decoration is BoxDecoration &&
        decoration.shape == BoxShape.circle &&
        decoration.color == AppPalette.danger &&
        c.constraints?.maxWidth == 8) {
      return true;
    }
  }
  return false;
}

void main() {
  testWidgets(
    'the bell shows no dot when the real category totals have nothing unread',
    (tester) async {
      await _pump(
        tester,
        loadNotificationCategories: () async => [
          _category(category: 'meeting', total: 2, unread: 0),
          _category(category: 'request', total: 1, unread: 0),
        ],
      );

      expect(_hasRedDot(tester), isFalse);
    },
  );

  testWidgets(
    'the bell shows a dot only because the real category totals say so',
    (tester) async {
      await _pump(
        tester,
        loadNotificationCategories: () async => [
          _category(category: 'meeting', total: 2, unread: 1),
        ],
      );

      expect(_hasRedDot(tester), isTrue);
    },
  );

  testWidgets(
    'opening the panel renders the injected notification, not invented content',
    (tester) async {
      await _pump(
        tester,
        loadNotifications: (category) async => [
          _notification(
            id: 'n1',
            title: 'ทดสอบแจ้งเตือนจริงจากฐานข้อมูล',
            body: 'เนื้อหาแจ้งเตือนที่ฉีดเข้ามาจากเทสต์โดยตรง',
          ),
        ],
      );

      await tester.tap(find.byIcon(Icons.notifications_none_rounded));
      await tester.pumpAndSettle();

      expect(find.text('ทดสอบแจ้งเตือนจริงจากฐานข้อมูล'), findsOneWidget);
      expect(
        find.text('เนื้อหาแจ้งเตือนที่ฉีดเข้ามาจากเทสต์โดยตรง'),
        findsOneWidget,
      );
    },
  );

  testWidgets('an empty real result says so honestly, not a fake list', (
    tester,
  ) async {
    await _pump(tester, loadNotifications: (category) async => []);

    await tester.tap(find.byIcon(Icons.notifications_none_rounded));
    await tester.pumpAndSettle();

    expect(find.text('ยังไม่มีการแจ้งเตือน'), findsOneWidget);
  });

  testWidgets('a failed real load is stated, not silently swallowed', (
    tester,
  ) async {
    await _pump(
      tester,
      loadNotifications: (category) async =>
          throw StateError('notifications_unreachable'),
    );

    await tester.tap(find.byIcon(Icons.notifications_none_rounded));
    await tester.pumpAndSettle();

    expect(find.text('โหลดการแจ้งเตือนไม่สำเร็จ'), findsOneWidget);
    expect(find.textContaining('notifications_unreachable'), findsNothing);
  });

  testWidgets(
    'search really navigates: picking a result changes the visible page',
    (tester) async {
      await _pump(tester);

      await tester.tap(find.byIcon(Icons.search_rounded));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'รายงาน');
      await tester.pumpAndSettle();
      await tester.tap(find.text('รายงาน').last);
      await tester.pumpAndSettle();

      // The dialog is gone and the top bar's own title (fontSize 24, the
      // one _topBar renders from `menuItems[selectedIndex].title`) now
      // reads the page that was picked — checked by that exact style
      // rather than plain text, because the sidebar's own nav entry for
      // "รายงาน" is always on screen at this width regardless of which
      // page is actually selected, so matching on text alone would pass
      // even if the tap had silently failed to navigate.
      expect(find.text('ค้นหาเมนูและคำสั่ง 🔍'), findsNothing);
      expect(
        find.byWidgetPredicate(
          (w) => w is Text && w.data == 'รายงาน' && w.style?.fontSize == 24,
        ),
        findsOneWidget,
      );
    },
  );
}
