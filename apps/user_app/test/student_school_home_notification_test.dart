import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/shared_core.dart';
import '../lib/pages/notifications_page.dart';
import '../lib/pages/student_redesign_prototype/widgets/student_variant_school_home.dart';

// SchoolAnnouncementsCard is the exact widget StudentVariantSchoolHome's
// build() mounts for both of the school-home entry points (the header
// "ดูทั้งหมด" button and the announcement card body). Testing it directly
// — instead of the full StudentVariantSchoolHome page — avoids mounting
// AiotWeatherSensorsCard's real-time device polling and
// SchoolEncouragementCard's periodic timer, neither of which are owned by
// this account and which leave a widget-test sandbox with pending timers
// regardless of any notification-related fix.

AppNotification _note(String id) => AppNotification(
  id: id,
  type: 'announcement',
  title: id,
  body: 'body of $id',
  createdAt: DateTime(2026, 9, 5),
);

void main() {
  testWidgets('empty account shows the honest ยังไม่มีประกาศ state, no fabricated card', (
    tester,
  ) async {
    var viewedCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SchoolAnnouncementsCard(
            notification: null,
            onViewed: () => viewedCount++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('ยังไม่มีประกาศ'), findsOneWidget);
    expect(viewedCount, 0);
  });

  testWidgets('a real notification renders its title and body', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SchoolAnnouncementsCard(
            notification: _note('เปิดเทอมภาคเรียนที่ 2'),
            onViewed: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('เปิดเทอมภาคเรียนที่ 2'), findsOneWidget);
    expect(
      find.text('body of เปิดเทอมภาคเรียนที่ 2'),
      findsOneWidget,
    );
    expect(find.text('ยังไม่มีประกาศ'), findsNothing);
  });

  testWidgets(
    'the header "ดูทั้งหมด" button opens the real inbox and awaits it before reporting back',
    (tester) async {
      var viewedCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SchoolAnnouncementsCard(
              notification: null,
              onViewed: () => viewedCount++,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('ดูทั้งหมด'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.byType(NotificationsPage),
        findsOneWidget,
        reason: 'must navigate to the real production inbox page',
      );
      expect(
        viewedCount,
        0,
        reason: 'onViewed must not fire until navigation actually returns',
      );

      Navigator.of(tester.element(find.byType(NotificationsPage))).pop();
      await tester.pumpAndSettle();

      expect(
        viewedCount,
        1,
        reason: 'popping the inbox must trigger exactly one canonical reload',
      );
    },
  );

  testWidgets(
    'tapping the announcement card itself opens the real inbox and awaits it before reporting back',
    (tester) async {
      var viewedCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SchoolAnnouncementsCard(
              notification: _note('มีการบ้านใหม่'),
              onViewed: () => viewedCount++,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('มีการบ้านใหม่'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(NotificationsPage), findsOneWidget);
      expect(viewedCount, 0);

      Navigator.of(tester.element(find.byType(NotificationsPage))).pop();
      await tester.pumpAndSettle();

      expect(viewedCount, 1);
    },
  );
}
