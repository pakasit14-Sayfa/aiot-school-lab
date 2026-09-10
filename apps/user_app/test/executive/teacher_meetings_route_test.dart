import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/teacher_redesign_prototype/teacher_notifications_page.dart';
import 'package:my_first_app/pages/executive_redesign_prototype/pages/director_meetings_page.dart';
import 'package:shared_core/shared_core.dart';

void main() {
  test('meeting notices including private summons route to meetings', () {
    for (final type in [
      'meeting_invite',
      'meeting_summons',
      'meeting_minutes_final',
      'meeting_addendum',
    ]) {
      final mapped = mapRealNotifications([
        AppNotification(
          id: 'n1',
          type: type,
          title: 'notice',
          createdAt: DateTime(2026),
        ),
      ]).single;
      expect(mapped.targetRoute, 'meeting');
      expect(mapped.category, 'meeting');
    }
  });
  testWidgets('teacher register does not offer organizer or approval actions', (
    tester,
  ) async {
    final service = MeetingService(
      token: () => 'session',
      rpc: (_, _) async => [],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DirectorMeetingsPage(service: service, allowOrganize: false),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('สร้างประชุม / เรียกพบ'), findsNothing);
    expect(find.text('คำขอเข้าพบ / จัดประชุม'), findsNothing);
    expect(find.text('ปฏิทินบุคลากร'), findsOneWidget);
  });
}
