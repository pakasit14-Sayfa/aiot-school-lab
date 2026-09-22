import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/shared_core.dart';
import '../lib/pages/notifications_page.dart';
import '../lib/pages/student_redesign_prototype/widgets/student_navigation_prototype.dart';

// StudentNotificationBell is the exact widget both of the student shell's
// unread-badge entry points (mobile app bar, desktop top bar) construct —
// confirmed by reading student_navigation_prototype.dart's two call sites,
// both of which pass `loadNotifications: widget.loadNotifications` through
// unchanged. Testing it directly (rather than the whole
// StudentNavigationPrototype shell) avoids mounting the other 4 tabs the
// shell's IndexedStack always builds, several of which start real,
// non-injectable device/sensor polling that leaves pending timers in a
// widget-test sandbox — a pre-existing limitation of those unrelated
// files, out of this account's scope to change.

AppNotification _note(String id, {bool read = false}) => AppNotification(
  id: id,
  type: 'assignment_published',
  title: id,
  createdAt: DateTime(2026, 9, 5),
  readAt: read ? DateTime(2026, 9, 5) : null,
);

Finder _unreadBadgeDot() => find.byWidgetPredicate(
  (widget) =>
      widget is Container &&
      widget.decoration is BoxDecoration &&
      (widget.decoration as BoxDecoration).color == const Color(0xFFE11D48),
);

Widget _harness(
  Future<List<AppNotification>> Function()? load, {
  bool decorated = false,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Align(
        alignment: Alignment.topRight,
        child: StudentNotificationBell(
          loadNotifications: load,
          decorated: decorated,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'unread badge appears on first load and clears after the inbox is opened and popped',
    (tester) async {
      var callCount = 0;
      Future<List<AppNotification>> load() async {
        callCount++;
        // Call 1 is initState's badge load, call 2 is the preview modal's
        // own FutureBuilder, call 3 is the canonical reload after the
        // inbox pops. Only the first call reports an unread row; every
        // call after that reports none, simulating the server-confirmed
        // read state the canonical reload proves.
        return callCount == 1 ? [_note('unread-1')] : [];
      }

      await tester.pumpWidget(_harness(load));
      await tester.pumpAndSettle();

      expect(callCount, 1, reason: 'initState loads unread status once');
      expect(_unreadBadgeDot(), findsOneWidget);

      await tester.tap(find.byIcon(Icons.notifications_none_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('ดูการแจ้งเตือนทั้งหมด'), findsOneWidget);
      await tester.tap(find.text('ดูการแจ้งเตือนทั้งหมด'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.byType(NotificationsPage),
        findsOneWidget,
        reason: 'the inbox entry point must open the real production page',
      );

      Navigator.of(tester.element(find.byType(NotificationsPage))).pop();
      await tester.pumpAndSettle();

      expect(
        callCount,
        3,
        reason:
            'returning from the inbox must trigger a fresh canonical reload, not a cached read',
      );
      expect(_unreadBadgeDot(), findsNothing);
    },
  );

  testWidgets(
    'decorated (desktop) variant positions the badge on its own chrome',
    (tester) async {
      await tester.pumpWidget(
        _harness(() async => [_note('unread-1')], decorated: true),
      );
      await tester.pumpAndSettle();
      expect(_unreadBadgeDot(), findsOneWidget);
      expect(find.byType(Material), findsWidgets);
    },
  );

  testWidgets(
    'a load failure leaves the badge safely absent instead of crashing',
    (tester) async {
      await tester.pumpWidget(
        _harness(() async => throw StateError('offline')),
      );
      await tester.pumpAndSettle();
      expect(_unreadBadgeDot(), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'the preview modal shows the empty state honestly, not fabricated rows',
    (tester) async {
      await tester.pumpWidget(_harness(() async => []));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.notifications_none_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('ยังไม่มีการแจ้งเตือน'), findsOneWidget);
    },
  );
}
