import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/parent_redesign_prototype/widgets/parent_navigation_shell.dart';
import 'package:shared_core/shared_core.dart';

/// กระดิ่งบน AppBar ของผู้ปกครองเคยเป็น `onPressed: () {}` พร้อมจุดแดงถาวร —
/// ทุกคนเห็น "มีแจ้งเตือนใหม่" ตลอดเวลา กดแล้วไม่มีอะไรเกิดขึ้น ตอนนี้จุดแดง
/// ต้องมาจากรายการที่ยังไม่อ่านจริง และกดแล้วเปิดรายการจริง
AppNotification _note({required String id, DateTime? readAt}) =>
    AppNotification(
      id: id,
      type: 'announcement',
      title: 'ประกาศ $id',
      body: 'เนื้อหาของ $id',
      createdAt: DateTime(2026, 9, 10),
      readAt: readAt,
    );

Future<void> _pump(
  WidgetTester tester, {
  required Future<List<AppNotification>> Function() loadNotifications,
  Future<void> Function(String)? markNotificationRead,
}) async {
  // กระดิ่งอยู่บน AppBar ของเลย์เอาต์มือถือเท่านั้น (< 820px)
  await tester.binding.setSurfaceSize(const Size(600, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: ParentNavigationShell(
        loadNotifications: loadNotifications,
        markNotificationRead: markNotificationRead,
        pagesBuilder: (_, _) =>
            List.generate(7, (i) => Scaffold(body: Text('page-$i'))),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _unreadDot() => find.byWidgetPredicate(
  (w) =>
      w is Container &&
      w.decoration is BoxDecoration &&
      (w.decoration as BoxDecoration).color == const Color(0xFFDF5660) &&
      (w.decoration as BoxDecoration).shape == BoxShape.circle,
);

void main() {
  testWidgets(
    'no unread notifications → no red dot; the bell still opens the real (empty) list',
    (tester) async {
      await _pump(
        tester,
        loadNotifications: () async => [
          _note(id: 'n1', readAt: DateTime(2026, 9, 11)),
        ],
      );

      expect(_unreadDot(), findsNothing);

      await tester.tap(find.byTooltip('การแจ้งเตือน'));
      await tester.pumpAndSettle();
      expect(find.text('ประกาศ n1'), findsOneWidget);
    },
  );

  testWidgets('an unread notification shows the dot, and the sheet lists it', (
    tester,
  ) async {
    await _pump(tester, loadNotifications: () async => [_note(id: 'n2')]);

    expect(_unreadDot(), findsOneWidget);

    await tester.tap(find.byTooltip('การแจ้งเตือน'));
    await tester.pumpAndSettle();
    expect(find.text('ประกาศ n2'), findsOneWidget);
    expect(find.text('เนื้อหาของ n2'), findsOneWidget);
  });

  /// จุดแดงต้องเคลียร์ได้จากในแผ่นเอง: แตะรายการ → mark_notification_read →
  /// อ่านกลับ → readAt ไม่ null → จุดหาย (เดิมแผ่นไม่มีทางทำให้อ่านแล้วเลย)
  testWidgets(
    'tapping an unread row marks it read through the RPC and clears the dot',
    (tester) async {
      final marked = <String>[];
      final read = <String>{};
      await _pump(
        tester,
        loadNotifications: () async => [
          _note(
            id: 'n3',
            readAt: read.contains('n3') ? DateTime(2026, 9, 12) : null,
          ),
        ],
        markNotificationRead: (id) async {
          marked.add(id);
          read.add(id);
        },
      );
      expect(_unreadDot(), findsOneWidget);

      await tester.tap(find.byTooltip('การแจ้งเตือน'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ประกาศ n3'));
      await tester.pumpAndSettle();
      expect(marked, ['n3']);

      // ปิดแผ่น → shell โหลดใหม่ → ไม่มีของค้างอ่าน → จุดแดงหาย
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(_unreadDot(), findsNothing);
    },
  );

  testWidgets('an empty account says so — never a fake dot', (tester) async {
    await _pump(tester, loadNotifications: () async => const []);
    expect(_unreadDot(), findsNothing);
    await tester.tap(find.byTooltip('การแจ้งเตือน'));
    await tester.pumpAndSettle();
    expect(find.text('ยังไม่มีการแจ้งเตือน'), findsOneWidget);
  });

  testWidgets('a failed load says so — no dot, no leaked exception', (
    tester,
  ) async {
    await _pump(
      tester,
      loadNotifications: () async =>
          throw Exception('PostgrestException: notif_boom'),
    );
    expect(_unreadDot(), findsNothing);
    await tester.tap(find.byTooltip('การแจ้งเตือน'));
    await tester.pumpAndSettle();
    expect(find.text('โหลดการแจ้งเตือนไม่สำเร็จ'), findsOneWidget);
    expect(find.textContaining('notif_boom'), findsNothing);
  });
}
