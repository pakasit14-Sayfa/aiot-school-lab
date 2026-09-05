import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/shared_core.dart';
import '../lib/pages/notifications_page.dart';

AppNotification note(String id, String type, {bool read = false}) => AppNotification(
 id: id, type: type, title: id, createdAt: DateTime(2026, 9, 5),
 readAt: read ? DateTime(2026, 9, 5) : null);

void main() {
 testWidgets('filters display only matching canonical notifications', (tester) async {
  await tester.pumpWidget(MaterialApp(home: NotificationsPage(load: () async => [
   note('assignment row', 'assignment_published'),
   note('grade row', 'grade_confirmed'),
   note('lesson row', 'lesson_published'),
  ])));
  await tester.pumpAndSettle();
  await tester.tap(find.text('คะแนน'));
  await tester.pumpAndSettle();
  expect(find.text('grade row'), findsOneWidget);
  expect(find.text('assignment row'), findsNothing);
  expect(find.text('lesson row'), findsNothing);
 });

 testWidgets('empty inbox contains no fabricated updates', (tester) async {
  await tester.pumpWidget(MaterialApp(home: NotificationsPage(load: () async => [])));
  await tester.pumpAndSettle();
  expect(find.text('ยังไม่มีข้อมูล'), findsOneWidget);
  expect(find.textContaining('92/100'), findsNothing);
 });

 testWidgets('initial read error is visible and retry loads real data', (tester) async {
  var fail = true;
  await tester.pumpWidget(MaterialApp(home: NotificationsPage(load: () async {
   if(fail) throw StateError('secret SQL');
   return [note('real result','lesson_published')];
  })));
  await tester.pumpAndSettle();
  expect(find.textContaining('โหลดการแจ้งเตือนไม่สำเร็จ'), findsOneWidget);
  expect(find.textContaining('secret SQL'), findsNothing);
  expect(find.text('ยังไม่มีข้อมูล'), findsNothing);
  fail = false;
  await tester.tap(find.text('ลองใหม่'));
  await tester.pumpAndSettle();
  expect(find.text('real result'), findsOneWidget);
 });

 testWidgets('mark failure retains unread item and exposes safe error', (tester) async {
  await tester.pumpWidget(MaterialApp(home: NotificationsPage(
   load: () async => [note('unread row','grade_confirmed')],
   markRead: (_) async => throw StateError('private failure'),
  )));
  await tester.pumpAndSettle();
  await tester.tap(find.text('unread row'));
  await tester.pumpAndSettle();
  expect(find.textContaining('บันทึกสถานะอ่านไม่สำเร็จ'), findsOneWidget);
  await tester.tap(find.text('ยังไม่อ่าน'));
  await tester.pumpAndSettle();
  expect(find.text('unread row'), findsOneWidget);
 });

 testWidgets('read appears only after canonical reload', (tester) async {
  var read = false;
  await tester.pumpWidget(MaterialApp(home: NotificationsPage(
   load: () async => [note('read row','grade_confirmed',read:read)],
   markRead: (_) async { read = true; },
  )));
  await tester.pumpAndSettle();
  await tester.tap(find.text('read row'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('ยังไม่อ่าน'));
  await tester.pumpAndSettle();
  expect(find.text('read row'), findsNothing);
  expect(find.text('ไม่พบการแจ้งเตือนตามตัวกรองที่เลือก'), findsOneWidget);
 });
}

