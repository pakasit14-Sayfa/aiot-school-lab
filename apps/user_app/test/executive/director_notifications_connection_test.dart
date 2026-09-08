import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/models/notification_model.dart';
import 'package:shared_core/services/notification_service.dart';
import 'package:my_first_app/pages/executive_redesign_prototype/pages/director_notifications_page.dart';
import 'package:my_first_app/pages/executive_redesign_prototype/controllers/director_notifications_controller.dart';

class Inbox extends NotificationService {
  List<AppNotification> rows = [];
  bool fail = false, reject = false;
  Completer<List<AppNotification>>? pending;
  @override
  Future<List<AppNotification>> loadInbox(String? c) async {
    if (pending != null) return pending!.future;
    if (fail) throw StateError('secret');
    return rows;
  }

  @override
  Future<List<NotificationCategory>> loadCategories() async => rows.isEmpty
      ? []
      : [
          NotificationCategory.fromRow({
            'category': 'meeting',
            'total': rows.length,
            'unread': rows.where((n) => n.isUnread).length,
          }),
        ];
  @override
  Future<AppNotification> readAndVerify(String id) async {
    if (reject) throw StateError('unconfirmed');
    rows = rows
        .map(
          (n) => AppNotification(
            id: n.id,
            type: n.type,
            title: n.title,
            body: n.body,
            category: n.category,
            createdAt: n.createdAt,
            readAt: n.id == id ? DateTime.now() : n.readAt,
          ),
        )
        .toList();
    return rows.firstWhere((n) => n.id == id);
  }

  @override
  Future<void> readAllAndVerify() async {
    if (reject) throw StateError('unconfirmed');
    for (final n in [...rows]) {
      await readAndVerify(n.id);
    }
  }
}

AppNotification notice(String id) => AppNotification(
  id: id,
  type: 'meeting_invited',
  title: 'ประชุมจริง $id',
  category: 'meeting',
  createdAt: DateTime.now(),
);
void main() {
  testWidgets('loading, failure and empty never show invented incidents', (
    t,
  ) async {
    final s = Inbox()..pending = Completer<List<AppNotification>>();
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DirectorNotificationsPage(service: s)),
      ),
    );
    expect(find.text('กำลังโหลดการแจ้งเตือน'), findsOneWidget);
    s.pending!.completeError(StateError('secret'));
    await t.pumpAndSettle();
    expect(find.text('โหลดไม่สำเร็จ'), findsOneWidget);
    expect(find.textContaining('secret'), findsNothing);
    s.pending = null;
    await t.tap(find.text('ลองอีกครั้ง'));
    await t.pumpAndSettle();
    expect(find.text('ยังไม่มีการแจ้งเตือน'), findsOneWidget);
    expect(find.textContaining('ทะเลาะวิวาท'), findsNothing);
  });
  test(
    'read failure cannot claim success; confirmed state survives reload and bulk reads',
    () async {
      final s = Inbox()..rows = [notice('a'), notice('b')];
      final c = DirectorNotificationsController(s);
      addTearDown(c.dispose);
      await c.load();
      s.reject = true;
      expect(await c.markRead('a'), isFalse);
      expect(c.unread, 2);
      expect(c.actionError, isNotNull);
      s.reject = false;
      expect(await c.markRead('a'), isTrue);
      await c.load();
      expect(c.unread, 1);
      expect(await c.markRead(), isTrue);
      await c.load();
      expect(c.unread, 0);
    },
  );
  testWidgets('real data, search and phone layout', (t) async {
    await t.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final s = Inbox()..rows = [notice('a')];
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DirectorNotificationsPage(service: s)),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('ประชุมจริง a'), findsOneWidget);
    await t.enterText(find.byType(TextField), 'ไม่ตรง');
    await t.pumpAndSettle();
    expect(find.text('ไม่พบรายการที่ตรงกับตัวกรอง'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
