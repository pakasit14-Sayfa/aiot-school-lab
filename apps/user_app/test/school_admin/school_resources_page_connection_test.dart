import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/school_admin/school_resources_page.dart';
import 'package:shared_core/shared_core.dart';

/// This page used to carry ~170 lines of `static const` chart data: totals
/// like "428.5 kWh", costs like "฿1,885.40", period-over-period deltas like
/// "ลดลง 3.2%", and captions asserting analysis the system never performed
/// ("Peak: 14:00 - 16:00 น.", "เสาร์-อาทิตย์ ปิดทำการประหยัดได้ 65%"). The
/// only real call it made — getSchoolUtilityRates — threw its result away.
/// These tests keep the four states apart and keep the invented figures out.

EnergyUsageSummary _energy({double kwh = 210.0, int devices = 4}) =>
    EnergyUsageSummary(
      deviceCount: devices,
      totalKwh: kwh,
      electricityRateThb: 4.2,
      isRateDefault: false,
      estimatedCostThb: kwh * 4.2,
      disclaimer: '',
    );

WaterUsageSummary _water({double m3 = 11.0, int devices = 2}) =>
    WaterUsageSummary(
      deviceCount: devices,
      totalM3: m3,
      waterRateThb: 18,
      isRateDefault: false,
      estimatedCostThb: m3 * 18,
      disclaimer: '',
    );

List<UtilityTrendPoint> _trend(List<double> values) => [
  for (var i = 0; i < values.length; i++)
    UtilityTrendPoint(day: DateTime(2026, 9, i + 1), value: values[i]),
];

Future<void> _pump(
  WidgetTester tester, {
  Future<EnergyUsageSummary?> Function(String)? energySummary,
  Future<WaterUsageSummary?> Function(String)? waterSummary,
  Future<List<UtilityTrendPoint>> Function(int)? energyTrend,
  Future<UtilityEfficiencyScore?> Function()? energyScore,
  Future<List<SchoolSensorAlertRecord>> Function()? alerts,
  SchoolResourcesDownloadBytes? downloadBytesOverride,
}) async {
  tester.view.physicalSize = const Size(1600, 3600);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: SchoolResourcesPage(
        loadEnergySummary: energySummary ?? (_) async => _energy(),
        loadWaterSummary: waterSummary ?? (_) async => _water(),
        loadEnergyTrend: energyTrend ?? (_) async => _trend([10, 30, 20]),
        loadWaterTrend: (_) async => _trend([1, 2, 3]),
        loadEnergyScore: energyScore ?? () async => null,
        loadWaterScore: () async => null,
        loadAlerts: alerts ?? () async => const [],
        downloadBytesOverride: downloadBytesOverride,
      ),
    ),
  );
}

void main() {
  testWidgets('the old hardcoded chart figures are gone', (tester) async {
    await _pump(tester);
    await tester.pumpAndSettle();

    expect(find.textContaining('428.5 kWh'), findsNothing);
    expect(find.textContaining('฿1,885.40'), findsNothing);
    expect(find.textContaining('Peak: 14:00'), findsNothing);
    expect(find.textContaining('ประหยัดได้ 65%'), findsNothing);
  });

  testWidgets('totals and derived stats come from the real trend', (
    tester,
  ) async {
    await _pump(tester, energyTrend: (_) async => _trend([10, 30, 20]));
    await tester.pumpAndSettle();

    expect(find.textContaining('210.0 kWh'), findsWidgets);
    // peak / average / lowest are computed from the trend points, not typed in
    expect(find.textContaining('30.0 kWh'), findsWidgets);
    expect(find.textContaining('20.0 kWh'), findsWidgets);
    expect(find.textContaining('10.0 kWh'), findsWidgets);
  });

  testWidgets(
    'period-over-period change is computed from the backend current/previous',
    (tester) async {
      await _pump(
        tester,
        energyScore: () async => const UtilityEfficiencyScore(
          score: 80,
          label: 'ดี',
          current: 90,
          previous: 100,
        ),
      );
      await tester.pumpAndSettle();

      // 90 vs 100 is a real 10% drop; nothing here is a typed-in constant.
      expect(find.textContaining('ลดลง 10.0%'), findsWidgets);
    },
  );

  testWidgets('no previous period says so rather than inventing a delta', (
    tester,
  ) async {
    await _pump(
      tester,
      energyScore: () async => const UtilityEfficiencyScore(
        score: null,
        label: null,
        current: 90,
        previous: 0,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('ไม่มีข้อมูลเทียบ'), findsWidgets);
  });

  testWidgets('no meters reports that, and does not claim live IoT sync', (
    tester,
  ) async {
    await _pump(
      tester,
      energySummary: (_) async => null,
      waterSummary: (_) async => null,
      energyTrend: (_) async => const [],
    );
    await tester.pumpAndSettle();

    expect(find.text('ยังไม่มีข้อมูล'), findsWidgets);
    // The badge used to be a hardcoded `true`, so it stayed green on a school
    // with no meters at all.
    expect(find.text('IoT Live Sync'), findsNothing);
  });

  testWidgets('a failed load is distinguishable from having no data', (
    tester,
  ) async {
    await _pump(
      tester,
      energySummary: (_) async =>
          throw StateError('backend detail that must stay internal'),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('โหลดไม่สำเร็จ'), findsWidgets);
    expect(find.textContaining('backend detail'), findsNothing);
  });

  testWidgets('the anomaly list shows real alerts, not invented incidents', (
    tester,
  ) async {
    await _pump(
      tester,
      alerts: () async => [
        SchoolSensorAlertRecord(
          id: 'a1',
          deviceId: 'd1',
          deviceName: 'มิเตอร์ไฟอาคาร 1',
          deviceCode: 'ELEC-01',
          schoolId: 's1',
          metric: 'energy_kwh',
          value: 620,
          triggeredAt: DateTime(2026, 9, 7, 9, 5),
          status: 'new',
        ),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('มิเตอร์ไฟอาคาร 1'), findsOneWidget);
    // The fabricated ones must not come back.
    expect(find.textContaining('เปิดเครื่องปรับอากาศทิ้งไว้'), findsNothing);
    expect(find.textContaining('0.35 m³/ชม.'), findsNothing);
  });

  testWidgets('no alerts says so instead of showing example incidents', (
    tester,
  ) async {
    await _pump(tester, alerts: () async => const []);
    await tester.pumpAndSettle();

    expect(
      find.text('ยังไม่มีข้อมูล — ยังไม่มีค่าที่เกินเกณฑ์ที่ตั้งไว้'),
      findsOneWidget,
    );
  });

  testWidgets('export downloads a real CSV built from the loaded figures', (
    tester,
  ) async {
    String? downloadedFilename;
    List<int>? downloadedBytes;

    await _pump(
      tester,
      downloadBytesOverride:
          ({
            required String filename,
            required List<int> bytes,
            required String mimeType,
          }) {
            downloadedFilename = filename;
            downloadedBytes = bytes;
          },
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('ส่งออกรายงาน'));
    await tester.pump();

    expect(downloadedFilename, contains('resources_report_'));
    expect(downloadedBytes, isNotNull);
    final csv = utf8.decode(downloadedBytes!, allowMalformed: true);
    expect(csv, contains('electricity'));
    expect(csv, contains('water'));
    expect(find.text('ส่งออกรายงานแล้ว'), findsOneWidget);
  });

  testWidgets('loading is not shown as an empty state', (tester) async {
    final gate = Completer<EnergyUsageSummary?>();
    await _pump(tester, energySummary: (_) => gate.future);
    await tester.pump();

    expect(find.textContaining('กำลังโหลด…'), findsWidgets);
    gate.complete(_energy());
    await tester.pumpAndSettle();
    expect(find.textContaining('กำลังโหลด…'), findsNothing);
  });
}
