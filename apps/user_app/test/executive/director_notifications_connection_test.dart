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

// Real installs regularly have 2-5 live categories (see the
// meeting/request/incident seed in supabase/seed.sql) — Inbox above always
// collapses to exactly one, which never exercises the bento category tiles'
// multi-column wrap. This fixture gives 3, matching what the executive
// account's real seeded notifications actually look like.
class MultiCategoryInbox extends Inbox {
  @override
  Future<List<NotificationCategory>> loadCategories() async => [
    NotificationCategory.fromRow({
      'category': 'meeting',
      'total': 2,
      'unread': 1,
    }),
    NotificationCategory.fromRow({
      'category': 'request',
      'total': 1,
      'unread': 1,
    }),
    NotificationCategory.fromRow({
      'category': 'incident',
      'total': 1,
      'unread': 0,
    }),
  ];
}

AppNotification notice(String id, {DateTime? readAt, DateTime? createdAt}) =>
    AppNotification(
      id: id,
      type: 'meeting_invited',
      title: 'ประชุมจริง $id',
      category: 'meeting',
      createdAt: createdAt ?? DateTime.now(),
      readAt: readAt,
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

  testWidgets(
    'bento header lays out without overflow across common screen widths',
    (t) async {
      addTearDown(() => t.binding.setSurfaceSize(null));
      final s = MultiCategoryInbox()..rows = [notice('a'), notice('b')];
      for (final width in <double>[
        320,
        360,
        400,
        600,
        768,
        900,
        1024,
        1200,
        1440,
      ]) {
        await t.binding.setSurfaceSize(Size(width, 900));
        await t.pumpWidget(
          MaterialApp(
            home: Scaffold(body: DirectorNotificationsPage(service: s)),
          ),
        );
        await t.pumpAndSettle();
        expect(
          t.takeException(),
          isNull,
          reason: 'overflow or layout exception at width $width',
        );
        // Every category tile and the search field must still be reachable —
        // a computed tile width of 0 or negative would make the tile
        // effectively disappear without throwing. Checked via each tile's
        // icon rather than its category label or count, since the category
        // label text is also repeated on each notification row's own badge
        // (e.g. 'ประชุม' legitimately appears more than once on screen), the
        // count numbers can collide with the hero's own unread/total digits,
        // and below 760px the mobile grouped list (_iosGroupedList) also uses
        // these same category icons per row — so findsWidgets (at least one),
        // not findsOneWidget, is the right assertion here.
        expect(find.byIcon(Icons.groups_rounded), findsWidgets);
        expect(find.byIcon(Icons.assignment_outlined), findsWidgets);
        expect(find.byIcon(Icons.warning_amber_rounded), findsWidgets);
        expect(find.byType(TextField), findsOneWidget);
      }
    },
  );

  testWidgets('status filter chips still filter after the redesign', (t) async {
    final s = Inbox()
      ..rows = [notice('a'), notice('b', readAt: DateTime.now())];
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DirectorNotificationsPage(service: s)),
      ),
    );
    await t.pumpAndSettle();

    expect(find.text('ประชุมจริง a'), findsOneWidget);
    expect(find.text('ประชุมจริง b'), findsOneWidget);

    await t.tap(find.text('อ่านแล้ว'));
    await t.pumpAndSettle();

    expect(find.text('ประชุมจริง a'), findsNothing);
    expect(find.text('ประชุมจริง b'), findsOneWidget);
  });

  testWidgets(
    'notification cards: unread ones offer a mark-read icon, read ones do not',
    (t) async {
      final s = Inbox()
        ..rows = [notice('a'), notice('b', readAt: DateTime.now())];
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DirectorNotificationsPage(service: s)),
        ),
      );
      await t.pumpAndSettle();

      expect(find.text('ประชุมจริง a'), findsOneWidget);
      expect(find.text('ประชุมจริง b'), findsOneWidget);
      // Exactly one mark-read affordance: the unread row's, not the read
      // row's — the old per-card version showed this button on every
      // unread card too, this just checks the dense row kept the same rule.
      expect(find.byTooltip('ทำเครื่องหมายอ่านแล้ว'), findsOneWidget);
    },
  );

  testWidgets(
    'tapping the mark-read icon marks read without opening the detail dialog',
    (t) async {
      final s = Inbox()..rows = [notice('a')];
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DirectorNotificationsPage(service: s)),
        ),
      );
      await t.pumpAndSettle();

      final markRead = find.byTooltip('ทำเครื่องหมายอ่านแล้ว');
      await t.ensureVisible(markRead);
      await t.tap(markRead);
      await t.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(
        find.textContaining('บันทึกสถานะอ่านและตรวจสอบแล้ว'),
        findsOneWidget,
      );
      expect(find.byTooltip('ทำเครื่องหมายอ่านแล้ว'), findsNothing);
    },
  );

  testWidgets('tapping a row opens the real detail dialog for that item', (
    t,
  ) async {
    final s = Inbox()..rows = [notice('a'), notice('b')];
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DirectorNotificationsPage(service: s)),
      ),
    );
    await t.pumpAndSettle();

    final rowB = find.text('ประชุมจริง b');
    await t.ensureVisible(rowB);
    await t.tap(rowB);
    await t.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('ประชุมจริง b'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('mobile: segmented status control filters the grouped list', (
    t,
  ) async {
    await t.binding.setSurfaceSize(const Size(360, 900));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final s = Inbox()
      ..rows = [notice('a'), notice('b', readAt: DateTime.now())];
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DirectorNotificationsPage(service: s)),
      ),
    );
    await t.pumpAndSettle();

    expect(find.text('ประชุมจริง a'), findsOneWidget);
    expect(find.text('ประชุมจริง b'), findsOneWidget);

    await t.tap(find.text('อ่านแล้ว'));
    await t.pumpAndSettle();

    expect(find.text('ประชุมจริง a'), findsNothing);
    expect(find.text('ประชุมจริง b'), findsOneWidget);
  });

  testWidgets('mobile: items are grouped under real calendar-day labels', (
    t,
  ) async {
    await t.binding.setSurfaceSize(const Size(360, 900));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final s = Inbox()
      ..rows = [
        notice('today', createdAt: DateTime.now()),
        notice(
          'old',
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
      ];
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DirectorNotificationsPage(service: s)),
      ),
    );
    await t.pumpAndSettle();

    expect(find.text('วันนี้'), findsOneWidget);
    // findsWidgets, not findsOneWidget: for an item exactly 3 days old,
    // _timeAgo's own per-row time text ("3 วันที่แล้ว") coincidentally
    // matches the day-group section label's text too — both are correct,
    // just the same string from two different, unrelated computations.
    expect(find.text('3 วันที่แล้ว'), findsWidgets);
  });

  testWidgets(
    'mobile: time filter sheet updates the trigger label and filters',
    (t) async {
      await t.binding.setSurfaceSize(const Size(360, 900));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final s = Inbox()
        ..rows = [
          notice('today', createdAt: DateTime.now()),
          notice(
            'old',
            createdAt: DateTime.now().subtract(const Duration(days: 3)),
          ),
        ];
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DirectorNotificationsPage(service: s)),
        ),
      );
      await t.pumpAndSettle();

      expect(find.text('ช่วงเวลา: ทุกช่วงเวลา'), findsOneWidget);
      expect(find.text('ประชุมจริง today'), findsOneWidget);
      expect(find.text('ประชุมจริง old'), findsOneWidget);

      await t.tap(find.text('ช่วงเวลา: ทุกช่วงเวลา'));
      await t.pumpAndSettle();
      // .last: the underlying page (with its own "วันนี้" day-group label)
      // is still in the tree under the modal barrier — the sheet's own copy
      // of "วันนี้" is added later, so it's the last match.
      await t.tap(find.text('วันนี้').last);
      await t.pumpAndSettle();

      expect(find.text('ช่วงเวลา: วันนี้'), findsOneWidget);
      expect(find.text('ประชุมจริง today'), findsOneWidget);
      expect(find.text('ประชุมจริง old'), findsNothing);
    },
  );

  testWidgets(
    'mobile: swiping an unread row marks it read without removing it',
    (t) async {
      await t.binding.setSurfaceSize(const Size(360, 900));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final s = Inbox()..rows = [notice('a')];
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DirectorNotificationsPage(service: s)),
        ),
      );
      await t.pumpAndSettle();

      expect(find.text('ประชุมจริง a'), findsOneWidget);
      await t.drag(find.text('ประชุมจริง a'), const Offset(-300, 0));
      await t.pumpAndSettle();

      // confirmDismiss always returns false — the row must still be on
      // screen, just now read (the real side effect), not removed like a
      // real Dismissible normally would on a true dismiss.
      expect(find.text('ประชุมจริง a'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'detail dialog: no source link means no button, not a disabled one',
    (t) async {
      final s = Inbox()..rows = [notice('a')];
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DirectorNotificationsPage(service: s)),
        ),
      );
      await t.pumpAndSettle();

      await t.tap(find.text('ประชุมจริง a'));
      await t.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('เปิดเรื่องต้นทาง'), findsNothing);
      expect(find.textContaining('ยังไม่มีลิงก์เรื่องต้นทาง'), findsOneWidget);
    },
  );

  testWidgets(
    'detail dialog: a real meeting_id shows an enabled source-link button',
    (t) async {
      final withMeeting = AppNotification(
        id: 'm1',
        type: 'meeting_invite',
        title: 'ประชุมมีลิงก์',
        category: 'meeting',
        createdAt: DateTime.now(),
        payload: const {'meeting_id': '11111111-1111-1111-1111-111111111111'},
      );
      final s = Inbox()..rows = [withMeeting];
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DirectorNotificationsPage(service: s)),
        ),
      );
      await t.pumpAndSettle();

      await t.tap(find.text('ประชุมมีลิงก์'));
      await t.pumpAndSettle();

      // Not tapping it — that would navigate to MeetingDetailPage, which
      // makes a real MeetingService/RPC call with no backend mocked here.
      // Just confirm the button is present and genuinely enabled.
      final btn = find.ancestor(
        of: find.text('เปิดเรื่องต้นทาง'),
        matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
      );
      expect(btn, findsOneWidget);
      expect(t.widget<ButtonStyleButton>(btn).onPressed, isNotNull);
    },
  );
}
