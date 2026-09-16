import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/student_redesign_prototype/widgets/school_utility_trend_card.dart';
import 'package:shared_core/shared_core.dart';

/// This card discloses its demo fallback ("ข้อมูลจำลอง" badge) whenever a
/// school has zero real energy/water meters — the demo-vs-real branch
/// logic is deliberately subtle (a real deviceCount: 0 must not silently
/// borrow the demo numbers unless BOTH are missing). These tests pin it
/// down against real seams rather than trusting the comment.

const _realEnergy = EnergyUsageSummary(
  deviceCount: 2,
  totalKwh: 150,
  electricityRateThb: 4.2,
  isRateDefault: false,
  estimatedCostThb: 630,
  disclaimer: '',
);

const _realWater = WaterUsageSummary(
  deviceCount: 1,
  totalM3: 8,
  waterRateThb: 18,
  isRateDefault: false,
  estimatedCostThb: 144,
  disclaimer: '',
);

const _zeroEnergy = EnergyUsageSummary(
  deviceCount: 0,
  totalKwh: 0,
  electricityRateThb: 4.2,
  isRateDefault: true,
  estimatedCostThb: 0,
  disclaimer: '',
);

Future<void> _pump(
  WidgetTester tester, {
  Future<EnergyUsageSummary?> Function({String period})?
  getEnergyUsageSummary,
  Future<WaterUsageSummary?> Function({String period})? getWaterUsageSummary,
}) async {
  tester.view.physicalSize = const Size(900, 500);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SchoolUtilityTrendCard(
          height: 300,
          getEnergyUsageSummary: getEnergyUsageSummary ?? ({period = 'week'}) async => null,
          getWaterUsageSummary: getWaterUsageSummary ?? ({period = 'week'}) async => null,
          getEnergyUsageTrend: ({days = 7}) async => const [],
          getWaterUsageTrend: ({days = 7}) async => const [],
          getEnergyEfficiencyScore: () async => null,
          getWaterEfficiencyScore: () async => null,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle(const Duration(milliseconds: 1600));
}

void main() {
  testWidgets('real meters with real usage show the real numbers, no demo badge', (
    tester,
  ) async {
    await _pump(
      tester,
      getEnergyUsageSummary: ({period = 'week'}) async => _realEnergy,
      getWaterUsageSummary: ({period = 'week'}) async => _realWater,
    );
    expect(find.textContaining('150'), findsOneWidget);
    expect(find.textContaining('8.0'), findsOneWidget);
    expect(find.text('ข้อมูลจำลอง'), findsNothing);
  });

  testWidgets('zero meters on both utilities is an honest empty state — no demo numbers, no badge', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text('ข้อมูลจำลอง'), findsNothing);
    // The old fixed demo totals (285 kWh / 12.5 m³) must never render.
    expect(find.textContaining('285'), findsNothing);
    expect(find.textContaining('12.5'), findsNothing);
    expect(find.textContaining('ยังไม่มีมิเตอร์ไฟฟ้า/น้ำ'), findsOneWidget);
  });

  testWidgets('a failed load is an error with retry, never the demo numbers', (
    tester,
  ) async {
    var calls = 0;
    await _pump(
      tester,
      getEnergyUsageSummary: ({period = 'week'}) async {
        calls++;
        if (calls == 1) throw StateError('secret');
        return _realEnergy;
      },
      getWaterUsageSummary: ({period = 'week'}) async => _realWater,
    );
    expect(find.textContaining('โหลดข้อมูลพลังงานไม่สำเร็จ'), findsOneWidget);
    expect(find.textContaining('285'), findsNothing);
    expect(find.textContaining('secret'), findsNothing);
    await tester.tap(find.text('ลองใหม่'));
    await tester.pumpAndSettle(const Duration(milliseconds: 1600));
    expect(calls, 2);
    expect(find.textContaining('150'), findsOneWidget);
  });

  testWidgets('a real zero-device energy summary is not silently swapped for the demo numbers when water is real', (
    tester,
  ) async {
    // Only water has a real meter — energy genuinely has zero devices.
    // This must show the real "no energy data" state, not the demo 285
    // kWh, and must not show the demo badge (this isn't the all-missing
    // demo case).
    await _pump(
      tester,
      getEnergyUsageSummary: ({period = 'week'}) async => _zeroEnergy,
      getWaterUsageSummary: ({period = 'week'}) async => _realWater,
    );
    expect(find.text('ข้อมูลจำลอง'), findsNothing);
    expect(find.textContaining('285'), findsNothing);
    expect(find.textContaining('8.0'), findsOneWidget);
  });
}
