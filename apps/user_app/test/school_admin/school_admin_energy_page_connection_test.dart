import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/school_admin/school_admin_energy_page.dart';
import 'package:shared_core/shared_core.dart';

/// Before this suite the page could not tell a director anything true when the
/// data was missing. `catch (_) {}` swallowed every failure, and each card fell
/// back to a hardcoded figure copied out of the screenshot fixture — 4.5 ฿/unit,
/// 88.5/100 "ดีเยี่ยม", 4520.5 kWh, a four-building usage split, and an
/// insights panel asserting "ตรวจพบเครื่องปรับอากาศ… เกิน 8 ชม." and
/// "ประหยัดงบประมาณได้ประมาณ ฿2,860". An empty school, a failed request and a
/// real reading all rendered identically. These tests pin the four states
/// apart and pin the invented numbers out.

const _energy = EnergyUsageSummary(
  deviceCount: 14,
  totalKwh: 4520.5,
  electricityRateThb: 4.5,
  isRateDefault: false,
  estimatedCostThb: 20342.25,
  disclaimer: 'ค่าบริการประมาณการเพื่อการบริหารจัดการภายใน',
);

const _water = WaterUsageSummary(
  deviceCount: 8,
  totalM3: 340.2,
  waterRateThb: 18.0,
  isRateDefault: true,
  estimatedCostThb: 6123.6,
  disclaimer: 'ค่าบริการประมาณการเพื่อการบริหารจัดการภายใน',
);

const _energyScore = UtilityEfficiencyScore(
  score: 88.5,
  label: 'ดีเยี่ยม',
  current: 4520.5,
  previous: 5160.0,
);

Future<void> _pump(
  WidgetTester tester, {
  EnergySummaryLoader? energy,
  WaterSummaryLoader? water,
  UtilityTrendLoader? energyTrend,
  UtilityTrendLoader? waterTrend,
  UtilityScoreLoader? energyScore,
  UtilityScoreLoader? waterScore,
  EnergyPageDownloadBytes? downloadBytesOverride,
}) async {
  tester.view.physicalSize = const Size(1400, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: SchoolAdminEnergyPage(
        loadEnergySummary: energy ?? (_) async => null,
        loadWaterSummary: water ?? (_) async => null,
        loadEnergyTrend: energyTrend ?? () async => const <UtilityTrendPoint>[],
        loadWaterTrend: waterTrend ?? () async => const <UtilityTrendPoint>[],
        loadEnergyScore: energyScore ?? () async => null,
        loadWaterScore: waterScore ?? () async => null,
        downloadBytesOverride: downloadBytesOverride,
      ),
    ),
  );
}

void main() {
  testWidgets('shows a loading indicator before the first load settles', (
    tester,
  ) async {
    final completer = Completer<EnergyUsageSummary?>();
    await _pump(tester, energy: (_) => completer.future);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    // Loading must not borrow the empty-state wording.
    expect(find.text('ยังไม่มีข้อมูล'), findsNothing);

    completer.complete(null);
    await tester.pumpAndSettle();
  });

  testWidgets('renders only backend figures when data is present', (
    tester,
  ) async {
    await _pump(
      tester,
      energy: (_) async => _energy,
      water: (_) async => _water,
      energyScore: () async => _energyScore,
    );
    await tester.pumpAndSettle();

    expect(find.text('4520.5 kWh'), findsOneWidget);
    expect(find.text('340.2 ลบ.ม.'), findsOneWidget);
    expect(find.text('89 / 100'), findsOneWidget);
    // Cost is the sum of the two real costs, not a standalone invention.
    expect(find.text('฿26466'), findsOneWidget);
    // deviceCount and disclaimer are fetched by the RPC precisely so the page
    // can disclose how a figure was reached; both used to be discarded.
    expect(find.textContaining('จากมิเตอร์ 14 จุด'), findsOneWidget);
    expect(
      find.textContaining('ค่าบริการประมาณการเพื่อการบริหารจัดการภายใน'),
      findsOneWidget,
    );
    // isRateDefault: the water rate is the system default and must say so;
    // the electricity rate is the school's own and must not.
    expect(
      find.textContaining('อัตรา ฿18.00 / ลบ.ม. (อัตรากลาง'),
      findsOneWidget,
    );
    expect(find.text('อัตรา ฿4.50 / หน่วย'), findsOneWidget);

    expect(
      find.text(
        'โหลดข้อมูลการใช้พลังงานไม่สำเร็จ ตัวเลขที่แสดงอาจไม่เป็นปัจจุบัน',
      ),
      findsNothing,
    );
  });

  testWidgets('an empty school states so and invents no readings', (
    tester,
  ) async {
    await _pump(tester);
    await tester.pumpAndSettle();

    // Every KPI says there is nothing rather than showing a fallback.
    expect(find.text('ยังไม่มีข้อมูล'), findsWidgets);
    expect(find.text('ยังไม่มีมิเตอร์ที่ส่งค่า'), findsNWidgets(2));
    expect(find.text('ยังเทียบกับช่วงก่อนหน้าไม่ได้'), findsOneWidget);
    expect(
      find.text('ยังไม่มีข้อมูลประวัติการใช้งานในช่วง 7 วันที่ผ่านมา'),
      findsOneWidget,
    );
    expect(
      find.text('ยังไม่มีข้อมูลมากพอจะเทียบกับช่วงก่อนหน้า'),
      findsOneWidget,
    );

    // The exact fallbacks this page used to print with an empty database.
    for (final invented in <String>[
      '4520.5 kWh',
      '340.2 ลบ.ม.',
      'อัตรา ฿4.50 / หน่วย',
      '89 / 100',
      '88/100',
      '79/100',
    ]) {
      expect(find.text(invented), findsNothing, reason: 'invented: $invented');
    }
    // An empty school must not be reported as a failed load.
    expect(find.textContaining('โหลดไม่สำเร็จ'), findsNothing);
  });

  testWidgets('a school with no meters is not reported as consuming 0.0 kWh', (
    tester,
  ) async {
    // Found by opening the page against the real local database: the RPC sums
    // with `coalesce(sum(...), 0)`, so a school with no metering hardware gets
    // a well-formed row of zeroes and the page printed "0.0 kWh · ประมาณ ฿0 ·
    // จากมิเตอร์ 0 จุด" — a measurement claim about a school nothing measures.
    const noMeters = EnergyUsageSummary(
      deviceCount: 0,
      totalKwh: 0,
      electricityRateThb: 4.5,
      isRateDefault: true,
      estimatedCostThb: 0,
      disclaimer: 'ค่าบริการประมาณการเพื่อการบริหารจัดการภายใน',
    );
    const noWaterMeters = WaterUsageSummary(
      deviceCount: 0,
      totalM3: 0,
      waterRateThb: 18,
      isRateDefault: true,
      estimatedCostThb: 0,
      disclaimer: 'ค่าบริการประมาณการเพื่อการบริหารจัดการภายใน',
    );

    await _pump(
      tester,
      energy: (_) async => noMeters,
      water: (_) async => noWaterMeters,
    );
    await tester.pumpAndSettle();

    expect(find.text('0.0 kWh'), findsNothing);
    expect(find.text('0.0 ลบ.ม.'), findsNothing);
    expect(find.textContaining('จากมิเตอร์ 0 จุด'), findsNothing);
    expect(find.text('ยังไม่มีมิเตอร์ที่ส่งค่า'), findsNWidgets(2));
    // Nor as having measured 0.0 against a previous period of 0.0.
    expect(find.textContaining('เทียบช่วงก่อน 0.0'), findsNothing);
    expect(find.text('ยังไม่มีข้อมูลเทียบช่วงก่อนหน้า'), findsNWidgets(2));
  });

  testWidgets('a failed load is stated, and is distinct from empty', (
    tester,
  ) async {
    await _pump(tester, energy: (_) async => throw StateError('boom'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'โหลดข้อมูลการใช้พลังงานไม่สำเร็จ ตัวเลขที่แสดงอาจไม่เป็นปัจจุบัน',
      ),
      findsOneWidget,
    );
    expect(find.text('โหลดไม่สำเร็จ'), findsWidgets);
    // Failure must not read as "this school has no meters".
    expect(find.text('ยังไม่มีข้อมูล'), findsNothing);
    // No raw backend text reaches the screen.
    expect(find.textContaining('StateError'), findsNothing);
    expect(find.textContaining('boom'), findsNothing);
  });

  testWidgets('retry after a failure clears the error and shows real data', (
    tester,
  ) async {
    bool firstCall = true;
    await _pump(
      tester,
      energy: (_) async {
        if (firstCall) {
          firstCall = false;
          throw StateError('transient');
        }
        return _energy;
      },
      water: (_) async => _water,
    );
    await tester.pumpAndSettle();
    expect(find.text('โหลดไม่สำเร็จ'), findsWidgets);

    await tester.tap(find.text('ลองใหม่'));
    await tester.pumpAndSettle();

    expect(find.text('4520.5 kWh'), findsOneWidget);
    expect(find.text('โหลดไม่สำเร็จ'), findsNothing);
  });

  testWidgets('per-building usage is an honest gap, never the old fake split', (
    tester,
  ) async {
    await _pump(
      tester,
      energy: (_) async => _energy,
      water: (_) async => _water,
      energyScore: () async => _energyScore,
    );
    await tester.pumpAndSettle();

    expect(find.text('ยังไม่มีข้อมูลรายอาคาร'), findsOneWidget);
    // No RPC aggregates usage per building and `devices.building` is null on
    // every row, so these can only ever have been invented.
    for (final invented in <String>[
      'อาคารเรียน 1 (ประถม)',
      'อาคารเรียน 2 (มัธยม)',
      'โรงฝึกงาน AIoT Lab',
      '1,420 kWh (31%)',
    ]) {
      expect(find.text(invented), findsNothing, reason: 'invented: $invented');
    }
  });

  testWidgets('insights are derived from the real comparison only', (
    tester,
  ) async {
    await _pump(
      tester,
      energy: (_) async => _energy,
      energyScore: () async => _energyScore,
    );
    await tester.pumpAndSettle();

    // (4520.5 - 5160.0) / 5160.0 = -12.4%
    expect(
      find.textContaining('การใช้ไฟฟ้าลดลง 12.4% เทียบช่วงก่อนหน้า'),
      findsOneWidget,
    );
    // Nothing in the schema tracks appliance runtime, leaks, or a budget
    // baseline — the page must not claim to have observed them.
    for (final invented in <String>[
      'ตรวจพบเครื่องปรับอากาศ',
      'ไม่มีสัญญาณท่อรั่วซึม',
      '฿2,860',
    ]) {
      expect(
        find.textContaining(invented),
        findsNothing,
        reason: 'invented: $invented',
      );
    }
  });

  testWidgets('export downloads a real CSV built from the loaded figures', (
    tester,
  ) async {
    String? downloadedFilename;
    List<int>? downloadedBytes;

    await _pump(
      tester,
      energy: (_) async => _energy,
      water: (_) async => _water,
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
    await tester.pumpAndSettle();
    await tester.tap(find.text('ส่งออกเป็น CSV'));
    await tester.pump();

    expect(downloadedFilename, contains('energy_report_'));
    expect(downloadedFilename, endsWith('.csv'));
    expect(downloadedBytes, isNotNull);
    final csv = utf8.decode(downloadedBytes!, allowMalformed: true);
    expect(csv, contains('energy_total_kwh'));
    expect(csv, contains('4520.5'));
    expect(find.text('ส่งออกรายงานแล้ว (CSV)'), findsOneWidget);
  });

  testWidgets(
    'export downloads a real Excel file built from the loaded figures',
    (tester) async {
      String? downloadedFilename;
      List<int>? downloadedBytes;

      await _pump(
        tester,
        energy: (_) async => _energy,
        water: (_) async => _water,
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
      await tester.pumpAndSettle();
      await tester.tap(find.text('ส่งออกเป็น Excel'));
      await tester.pump();

      expect(downloadedFilename, endsWith('.xlsx'));
      expect(downloadedBytes, isNotNull);
      expect(downloadedBytes![0], 0x50);
      expect(downloadedBytes![1], 0x4B);
      expect(find.text('ส่งออกรายงานแล้ว (Excel)'), findsOneWidget);
    },
  );

  testWidgets(
    'export with no measured data refuses instead of downloading an empty file',
    (tester) async {
      var downloadCalled = false;
      await _pump(
        tester,
        downloadBytesOverride:
            ({
              required String filename,
              required List<int> bytes,
              required String mimeType,
            }) {
              downloadCalled = true;
            },
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('ส่งออกรายงาน'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ส่งออกเป็น CSV'));
      await tester.pump();

      expect(downloadCalled, isFalse);
      expect(find.text('ยังไม่มีข้อมูลพลังงาน/น้ำให้ส่งออก'), findsOneWidget);
    },
  );
}
