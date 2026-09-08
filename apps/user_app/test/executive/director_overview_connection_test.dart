import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/shared_core.dart';
import 'package:my_first_app/pages/executive_redesign_prototype/controllers/director_overview_controller.dart';
import 'package:my_first_app/pages/executive_redesign_prototype/pages/director_overview_page.dart';

DirectorOverviewData data({bool empty = false}) => DirectorOverviewData(
  counts: empty ? {} : {'student': 3, 'teacher': 1},
  devices: [],
  incidents: [],
  tracks: [],
  notices: [],
  energy: empty
      ? []
      : [UtilityTrendPoint(day: DateTime(2026, 9, 8), value: 12.5)],
  water: [],
);
Widget page(DirectorOverviewController c, {ValueChanged<int>? navigate}) =>
    MaterialApp(
      home: Scaffold(
        body: DirectorOverviewPage(
          controller: c,
          onNavigate: navigate ?? (_) {},
          sensorStreamOverride: Stream<SensorModel?>.value(null),
          rawReadingsStreamOverride: Stream.value(<Map<String, dynamic>>[]),
        ),
      ),
    );
void main() {
  testWidgets('loading error retry empty never invent totals or events', (
    t,
  ) async {
    final pending = Completer<DirectorOverviewData>();
    var calls = 0;
    final c = DirectorOverviewController(
      loader: (_) =>
          calls++ == 0 ? pending.future : Future.value(data(empty: true)),
    );
    addTearDown(c.dispose);
    await t.pumpWidget(page(c));
    expect(find.text('กำลังโหลดภาพรวม'), findsOneWidget);
    expect(find.text('3 คน'), findsNothing);
    pending.completeError(StateError('secret'));
    await t.pumpAndSettle();
    expect(find.text('โหลดภาพรวมไม่สำเร็จ'), findsOneWidget);
    expect(find.textContaining('secret'), findsNothing);
    await t.tap(find.text('ลองอีกครั้ง'));
    await t.pumpAndSettle();
    expect(find.text('ยังไม่มีข้อมูลภาพรวม'), findsOneWidget);
    expect(find.textContaining('ทะเลาะวิวาท'), findsNothing);
  });
  testWidgets(
    'real values and navigation work on phone; missing trends stay unknown',
    (t) async {
      await t.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final c = DirectorOverviewController(loader: (_) async => data());
      addTearDown(c.dispose);
      int? target;
      await t.pumpWidget(page(c, navigate: (v) => target = v));
      await t.pumpAndSettle();
      expect(find.text('3 คน'), findsOneWidget);
      await t.ensureVisible(find.text('3 คน'));
      await t.tap(find.text('3 คน'));
      expect(target, 2);
      expect(find.text('รวม 12.50 kWh ในวันที่มีข้อมูล'), findsOneWidget);
      expect(find.text('ยังไม่มีข้อมูลย้อนหลัง'), findsOneWidget);
      expect(find.text('ข้อมูลจำลอง'), findsNothing);
      expect(t.takeException(), isNull);
    },
  );
  test('stale period reads cannot overwrite a new period', () async {
    final a = Completer<DirectorOverviewData>();
    final b = Completer<DirectorOverviewData>();
    final c = DirectorOverviewController(
      loader: (days) => days == 7 ? a.future : b.future,
    );
    addTearDown(c.dispose);
    final one = c.load();
    final two = c.load(period: 30);
    b.complete(data());
    await two;
    a.complete(data(empty: true));
    await one;
    expect(c.days, 30);
    expect(c.data!.counts['student'], 3);
  });
}
