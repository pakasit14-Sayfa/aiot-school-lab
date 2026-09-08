import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/school_admin/school_admin_esg_page.dart';
import 'package:shared_core/shared_core.dart';

/// The worst failure mode of this page was not a fake number — it was a fake
/// *verdict*. Both pillar scores read `?? 0.0`, so a school with no meter data
/// (and a school whose load had just failed) averaged to 0/100 and was graded
/// "ต้องปรับปรุง" in red, on a page a director may forward upward. It also
/// labelled electricity emissions as "ลดคาร์บอน" — carbon *reduced* — so using
/// more power made the reduction look bigger, and it asserted that leak
/// detection and a carbon-reduction programme were operational when nothing in
/// the schema models either.

const _energy = EnergyUsageSummary(
  deviceCount: 14,
  totalKwh: 1000.0,
  electricityRateThb: 4.5,
  isRateDefault: false,
  estimatedCostThb: 4500.0,
  disclaimer: 'ค่าบริการประมาณการเพื่อการบริหารจัดการภายใน',
);

const _water = WaterUsageSummary(
  deviceCount: 8,
  totalM3: 340.2,
  waterRateThb: 18.0,
  isRateDefault: false,
  estimatedCostThb: 6123.6,
  disclaimer: 'ค่าบริการประมาณการเพื่อการบริหารจัดการภายใน',
);

const _energyScore = UtilityEfficiencyScore(
  score: 88.0,
  label: 'ดีเยี่ยม',
  current: 1000.0,
  previous: 1200.0,
);

const _waterScore = UtilityEfficiencyScore(
  score: 80.0,
  label: 'ดี',
  current: 340.2,
  previous: 357.0,
);

/// A score the backend could not compute — the shape returned when there is
/// not enough history to compare periods.
const _noVerdict = UtilityEfficiencyScore(
  score: null,
  label: null,
  current: 0,
  previous: 0,
);

DeviceSchedule _schedule({
  required String id,
  required bool enabled,
  DateTime? lastTriggeredAt,
}) => DeviceSchedule(
  id: id,
  deviceId: 'device-$id',
  deviceName: 'แอร์ห้องเรียน',
  deviceLocation: 'อาคาร 1',
  schoolId: 'school-1',
  label: 'ปิดแอร์หลังเลิกเรียน',
  command: const {'action': 'off'},
  daysOfWeek: const [1, 2, 3, 4, 5],
  timeOfDay: '17:00',
  enabled: enabled,
  createdBy: 'admin',
  createdAt: DateTime(2026, 9, 1),
  lastTriggeredAt: lastTriggeredAt,
);

Future<void> _pump(
  WidgetTester tester, {
  EsgScoreLoader? energyScore,
  EsgScoreLoader? waterScore,
  EsgEnergySummaryLoader? energySummary,
  EsgWaterSummaryLoader? waterSummary,
  EsgScheduleLoader? schedules,
}) async {
  tester.view.physicalSize = const Size(1400, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: SchoolAdminEsgPage(
        loadEnergyScore: energyScore ?? () async => null,
        loadWaterScore: waterScore ?? () async => null,
        loadEnergySummary: energySummary ?? () async => null,
        loadWaterSummary: waterSummary ?? () async => null,
        loadSchedules: schedules ?? () async => const <DeviceSchedule>[],
      ),
    ),
  );
}

void main() {
  testWidgets('shows a loading indicator before the first load settles', (
    tester,
  ) async {
    final completer = Completer<UtilityEfficiencyScore?>();
    await _pump(tester, energyScore: () => completer.future);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsWidgets);
    expect(find.text('ยังไม่มีข้อมูล'), findsNothing);

    completer.complete(null);
    await tester.pumpAndSettle();
  });

  testWidgets('grades the school only on pillars that returned a score', (
    tester,
  ) async {
    await _pump(
      tester,
      energyScore: () async => _energyScore,
      waterScore: () async => _waterScore,
      energySummary: () async => _energy,
      waterSummary: () async => _water,
    );
    await tester.pumpAndSettle();

    // (88 + 80) / 2 = 84 -> "ดี"
    expect(find.text('84'), findsOneWidget);
    expect(find.text('ระดับ: ดี'), findsOneWidget);
    expect(find.text('88/100 (ดีเยี่ยม)'), findsOneWidget);
    expect(find.text('80/100 (ดี)'), findsOneWidget);
    expect(find.textContaining('เฉลี่ยจากด้านที่มีข้อมูล'), findsOneWidget);
  });

  testWidgets('one missing pillar averages over the other, not over zero', (
    tester,
  ) async {
    await _pump(
      tester,
      energyScore: () async => _energyScore,
      waterScore: () async => _noVerdict,
      energySummary: () async => _energy,
    );
    await tester.pumpAndSettle();

    // 88 alone, NOT (88 + 0) / 2 = 44 which would read "ต้องปรับปรุง".
    expect(find.text('88'), findsOneWidget);
    expect(find.text('ระดับ: ดีเยี่ยม'), findsNothing);
    expect(find.text('ระดับ: ดี'), findsOneWidget);
    expect(find.text('44'), findsNothing);
    expect(find.text('ระดับ: ต้องปรับปรุง'), findsNothing);
    expect(find.textContaining('(1 ด้าน)'), findsOneWidget);
  });

  testWidgets('no data is never graded as a failing school', (tester) async {
    await _pump(tester);
    await tester.pumpAndSettle();

    expect(find.text('—'), findsOneWidget);
    expect(find.text('ยังไม่มีคะแนน'), findsOneWidget);
    expect(find.text('ระดับ: ยังไม่มีข้อมูล'), findsOneWidget);
    // The verdict this page used to hand an unmeasured school.
    expect(find.text('ระดับ: ต้องปรับปรุง'), findsNothing);
    expect(find.text('0'), findsNothing);
    expect(find.text('0/100 (ไม่มีข้อมูล)'), findsNothing);

    // Consumption chips say there is no reading rather than reporting zero.
    expect(find.text('ไฟฟ้า: ยังไม่มีข้อมูล'), findsOneWidget);
    expect(find.text('น้ำ: ยังไม่มีข้อมูล'), findsOneWidget);
    expect(find.text('คาร์บอนจากไฟฟ้า: ยังไม่มีข้อมูล'), findsOneWidget);
    expect(find.textContaining('0 kWh'), findsNothing);
    expect(find.textContaining('~0 kg CO₂e'), findsNothing);
  });

  testWidgets('carbon is reported as emitted, not as reduced', (tester) async {
    await _pump(tester, energySummary: () async => _energy);
    await tester.pumpAndSettle();

    // 1000 kWh x 0.499 kg CO2e/kWh = 499
    expect(find.text('คาร์บอนจากไฟฟ้า ~499 kg CO₂e'), findsOneWidget);
    // The old label claimed this figure was carbon *saved*, which inverted its
    // meaning: consuming more made the "reduction" grow.
    expect(find.textContaining('ลดคาร์บอน'), findsNothing);
  });

  testWidgets('no meters means no consumption figure and no 0 kg CO₂e', (
    tester,
  ) async {
    // Same trap as the energy page: `coalesce(sum(...), 0)` yields a complete
    // row of zeroes for a school with no metering hardware, which rendered as
    // "ไฟฟ้า 0 kWh" and "~0 kg CO₂e" — both measurement claims.
    const noMeters = EnergyUsageSummary(
      deviceCount: 0,
      totalKwh: 0,
      electricityRateThb: 4.5,
      isRateDefault: true,
      estimatedCostThb: 0,
      disclaimer: 'ค่าบริการประมาณการเพื่อการบริหารจัดการภายใน',
    );

    await _pump(tester, energySummary: () async => noMeters);
    await tester.pumpAndSettle();

    expect(find.text('ไฟฟ้า: ยังไม่มีข้อมูล'), findsOneWidget);
    expect(find.text('คาร์บอนจากไฟฟ้า: ยังไม่มีข้อมูล'), findsOneWidget);
    expect(find.textContaining('0 kWh'), findsNothing);
    expect(find.textContaining('kg CO₂e'), findsNothing);
  });

  testWidgets('a failed load is stated and is distinct from empty', (
    tester,
  ) async {
    await _pump(tester, energyScore: () async => throw StateError('boom'));
    await tester.pumpAndSettle();

    expect(
      find.text('โหลดข้อมูล ESG ไม่สำเร็จ คะแนนและตัวเลขที่แสดงอาจไม่เป็นปัจจุบัน'),
      findsOneWidget,
    );
    expect(find.text('ระดับ: โหลดไม่สำเร็จ'), findsOneWidget);
    expect(find.text('ระดับ: ยังไม่มีข้อมูล'), findsNothing);
    expect(find.text('ระดับ: ต้องปรับปรุง'), findsNothing);
    expect(find.textContaining('StateError'), findsNothing);
    expect(find.textContaining('boom'), findsNothing);
  });

  testWidgets('retry after a failure clears the error and grades normally', (
    tester,
  ) async {
    bool first = true;
    await _pump(
      tester,
      energyScore: () async {
        if (first) {
          first = false;
          throw StateError('transient');
        }
        return _energyScore;
      },
      waterScore: () async => _waterScore,
    );
    await tester.pumpAndSettle();
    expect(find.text('ระดับ: โหลดไม่สำเร็จ'), findsOneWidget);

    await tester.tap(find.text('ลองใหม่'));
    await tester.pumpAndSettle();

    expect(find.text('84'), findsOneWidget);
    expect(find.text('ระดับ: โหลดไม่สำเร็จ'), findsNothing);
  });

  testWidgets('the auto power-cut measure reports real configured schedules', (
    tester,
  ) async {
    await _pump(
      tester,
      schedules: () async => [
        _schedule(id: '1', enabled: true, lastTriggeredAt: DateTime(2026, 9, 5)),
        _schedule(id: '2', enabled: true),
        _schedule(id: '3', enabled: false),
      ],
    );
    await tester.pumpAndSettle();

    // Two enabled, one disabled — and the most recent real run date.
    expect(find.text('เปิดใช้งาน 2 รายการ'), findsOneWidget);
    expect(find.textContaining('ทำงานล่าสุด 5/9/2026'), findsOneWidget);
  });

  testWidgets('with no schedules the measure says so instead of "เปิดใช้งาน"', (
    tester,
  ) async {
    await _pump(tester);
    await tester.pumpAndSettle();

    expect(find.text('ยังไม่ได้ตั้งค่า'), findsOneWidget);
    expect(find.text('เปิดใช้งาน'), findsNothing);
  });

  testWidgets('measures the system cannot observe are gone', (tester) async {
    await _pump(tester, energySummary: () async => _energy);
    await tester.pumpAndSettle();

    // Nothing in the schema detects leaks or stores a carbon target, so
    // claiming these are "พร้อมทำงาน" / "ตามแผนงาน" was unverifiable.
    for (final claim in <String>[
      'การตรวจจับน้ำรั่วไหล (Water Leakage Detection)',
      'เป้าหมายลดการปล่อยคาร์บอน (Carbon Footprint Target)',
      'พร้อมทำงาน',
      'ตามแผนงาน',
    ]) {
      expect(find.textContaining(claim), findsNothing, reason: claim);
    }

    // The methodology card is the honest part of this page and stays.
    expect(
      find.textContaining('ขอบเขตและที่มาของข้อมูล'),
      findsOneWidget,
    );
  });

  testWidgets('export downloads a real CSV built from the loaded figures', (
    tester,
  ) async {
    String? downloadedFilename;
    List<int>? downloadedBytes;

    tester.view.physicalSize = const Size(1400, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MaterialApp(
        home: SchoolAdminEsgPage(
          loadEnergyScore: () async => _energyScore,
          loadWaterScore: () async => _waterScore,
          loadEnergySummary: () async => _energy,
          loadWaterSummary: () async => _water,
          loadSchedules: () async => const <DeviceSchedule>[],
          downloadBytesOverride:
              ({
                required String filename,
                required List<int> bytes,
                required String mimeType,
              }) {
                downloadedFilename = filename;
                downloadedBytes = bytes;
              },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('ส่งออกรายงาน ESG'));
    await tester.pump();

    expect(downloadedFilename, contains('esg_report_'));
    expect(downloadedBytes, isNotNull);
    final csv = utf8.decode(downloadedBytes!, allowMalformed: true);
    expect(csv, contains('energy_total_kwh'));
    expect(csv, contains('1000.0'));
    expect(find.text('ส่งออกรายงาน ESG แล้ว'), findsOneWidget);
  });

  testWidgets('export with no measured data refuses instead of downloading an empty file', (
    tester,
  ) async {
    var downloadCalled = false;
    await _pump(tester);
    await tester.pumpAndSettle();

    // No override supplied above via _pump, so rebuild directly with one
    // that would flag if called.
    tester.view.physicalSize = const Size(1400, 2600);
    await tester.pumpWidget(
      MaterialApp(
        home: SchoolAdminEsgPage(
          loadEnergyScore: () async => null,
          loadWaterScore: () async => null,
          loadEnergySummary: () async => null,
          loadWaterSummary: () async => null,
          loadSchedules: () async => const <DeviceSchedule>[],
          downloadBytesOverride:
              ({
                required String filename,
                required List<int> bytes,
                required String mimeType,
              }) {
                downloadCalled = true;
              },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('ส่งออกรายงาน ESG'));
    await tester.pump();

    expect(downloadCalled, isFalse);
    expect(find.text('ยังไม่มีข้อมูลพลังงาน/น้ำให้ส่งออก'), findsOneWidget);
  });
}
