import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/parent_redesign_prototype/pages/parent/parent_messages_page.dart';
import 'package:shared_core/shared_core.dart';

Widget _app({
  required ParentNotificationsLoader loader,
  ParentNotificationReadMarker? markRead,
}) => MaterialApp(
  home: ParentMessagesPage(
    notificationsLoader: loader,
    markRead: markRead ?? (_) async {},
  ),
);

void main() {
  testWidgets('shows explicit empty state without sample messages', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1000));
    await tester.pumpWidget(_app(loader: () async => const []));
    await tester.pumpAndSettle();

    expect(find.text('ยังไม่มีข้อมูล'), findsWidgets);
    expect(find.text('ครูสมหญิง (ครูประจำชั้น ม.2/1)'), findsNothing);
    expect(find.text('เตรียมอุปกรณ์วิชาวิทยาศาสตร์'), findsNothing);
  });

  testWidgets('keeps load failures distinct from empty data', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 700));
    await tester.pumpWidget(
      _app(loader: () async => throw Exception('network_error')),
    );
    await tester.pumpAndSettle();

    expect(find.text('ไม่สามารถโหลดข้อมูลได้'), findsOneWidget);
    expect(find.text('ลองอีกครั้ง'), findsOneWidget);
    expect(find.text('ยังไม่มีข้อมูล'), findsNothing);
  });

  testWidgets('renders notifications and marks unread notification as read', (
    tester,
  ) async {
    String? markedId;
    final items = [
      AppNotification(
        id: 'notification-1',
        type: 'assignment',
        title: 'มีงานใหม่',
        body: 'รายงานการทดลอง',
        createdAt: DateTime(2026, 9, 3, 9),
      ),
      AppNotification(
        id: 'notification-2',
        type: 'grade',
        title: 'ประกาศคะแนนแล้ว',
        createdAt: DateTime(2026, 9, 2, 9),
        readAt: DateTime(2026, 9, 2, 10),
      ),
    ];
    await tester.binding.setSurfaceSize(const Size(1000, 1000));
    await tester.pumpWidget(
      _app(loader: () async => items, markRead: (id) async => markedId = id),
    );
    await tester.pumpAndSettle();

    expect(find.text('มีงานใหม่'), findsOneWidget);
    expect(find.text('ประกาศคะแนนแล้ว'), findsOneWidget);
    expect(find.text('รายงานการทดลอง'), findsOneWidget);
    await tester.tap(find.text('มีงานใหม่'));
    await tester.pumpAndSettle();
    expect(markedId, 'notification-1');
  });
}
