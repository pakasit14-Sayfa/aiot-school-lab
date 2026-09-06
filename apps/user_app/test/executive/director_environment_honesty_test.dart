import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/executive_redesign_prototype/pages/director_environment_page.dart';
import 'package:shared_core/shared_core.dart';

/// This page fetched seven real results and then displayed none of them.
///
/// `_loadUtilityData()` awaited both utility summaries, both 7-day trends,
/// both efficiency scores and the latest sensor readings, assigned them to
/// fields, and every field went unread — the analyzer had been reporting six
/// `unused_field` warnings the whole time. What rendered instead was a block
/// the file itself labelled `// MOCK DATA`:
///
///   - summary cards fixed at ฿82,150, 18,450 kWh, 640 ลบ.ม., PM2.5 38, CO₂ 720
///   - a six-building electricity split and a four-way water split
///   - five air-quality zones with invented PM2.5/CO₂/temperature readings
///   - "AI คาดการณ์ค่าใช้จ่ายสิ้นเดือน" — ฿137,000 at "ความมั่นใจ 92%",
///     described as a model trained on twelve months of history
///   - three "AI" recommendations, one asserting that building 2 turns its
///     air conditioning on 40 minutes before class
///   - tariff tables quoting an energy charge to four decimal places, the
///     current Ft, and a monthly service fee
///
/// None of it existed. There is no AI, no twelve-month history, no per-building
/// metering (`devices.building` is null on every row), no hourly data, and
/// `school_settings` holds a single flat rate per utility.

EnergyUsageSummary _energy({int devices = 4, double kwh = 1000}) =>
    EnergyUsageSummary(
      deviceCount: devices,
      totalKwh: kwh,
      electricityRateThb: 4.5,
      isRateDefault: false,
      estimatedCostThb: kwh * 4.5,
      disclaimer: 'ค่าบริการประมาณการเพื่อการบริหารจัดการภายใน',
    );

WaterUsageSummary _water({int devices = 2, double m3 = 100}) =>
    WaterUsageSummary(
      deviceCount: devices,
      totalM3: m3,
      waterRateThb: 18,
      isRateDefault: true,
      estimatedCostThb: m3 * 18,
      disclaimer: 'ค่าบริการประมาณการเพื่อการบริหารจัดการภายใน',
    );

Map<String, dynamic> _reading(
  String metric,
  num value, {
  String location = 'อาคาร 1',
}) => <String, dynamic>{
  'metric': metric,
  'value': value,
  'location': location,
  'device_name': 'sensor-1',
  'ts': DateTime.now().toIso8601String(),
};

Future<void> _pump(
  WidgetTester tester, {
  List<Object?>? results,
  bool fail = false,
}) async {
  tester.view.physicalSize = const Size(1500, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: DirectorEnvironmentPage(
          loadAll: () async {
            if (fail) throw StateError('utility_unreachable');
            return results ??
                <Object?>[
                  null,
                  null,
                  const <UtilityTrendPoint>[],
                  const <UtilityTrendPoint>[],
                  null,
                  null,
                  const <Map<String, dynamic>>[],
                ];
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('none of the mock block survives', (tester) async {
    await _pump(tester);

    for (final invented in <String>[
      '฿82,150',
      '18,450',
      'PM2.5 เฉลี่ย',
      'AI คาดการณ์ค่าใช้จ่ายสิ้นเดือน',
      'ความมั่นใจ 92%',
      '฿137,000',
      'AI พบว่าอาคาร 2 เปิดแอร์ก่อนเข้าเรียน',
      'คำแนะนำจาก AI เพื่อลดค่าใช้จ่าย',
      '4.1839 บาท/หน่วย',
      'ค่า Ft (งวดปัจจุบัน)',
      '1 - 21 ส.ค. 2569',
      'ใช้ไฟสูงสุดช่วง 13.50 น.',
    ]) {
      // 'PM2.5 เฉลี่ย' is a legitimate card title, so only the invented
      // values and claims are checked here.
      if (invented == 'PM2.5 เฉลี่ย') continue;
      expect(
        find.textContaining(invented),
        findsNothing,
        reason: 'ยังพบของที่แต่งขึ้น: $invented',
      );
    }
  });

  testWidgets('summary cards show the loaded figures', (tester) async {
    await _pump(
      tester,
      results: <Object?>[
        _energy(kwh: 1234),
        _water(m3: 56),
        const <UtilityTrendPoint>[],
        const <UtilityTrendPoint>[],
        null,
        null,
        [_reading('pm25', 42), _reading('co2', 810)],
      ],
    );

    expect(find.text('1234'), findsWidgets);
    expect(find.text('56'), findsWidgets);
    expect(find.text('42'), findsWidgets);
    expect(find.text('810'), findsWidgets);
    expect(find.textContaining('จากมิเตอร์ 4 จุด'), findsOneWidget);
  });

  testWidgets('a school with no meters is not reported as using zero', (
    tester,
  ) async {
    await _pump(
      tester,
      results: <Object?>[
        _energy(devices: 0, kwh: 0),
        _water(devices: 0, m3: 0),
        const <UtilityTrendPoint>[],
        const <UtilityTrendPoint>[],
        null,
        null,
        const <Map<String, dynamic>>[],
      ],
    );

    expect(find.text('ยังไม่มีมิเตอร์ที่ส่งค่า'), findsNWidgets(2));
    expect(find.text('ยังไม่มีข้อมูล'), findsWidgets);
  });

  testWidgets('air-quality zones come from the sensors, not a fixed list', (
    tester,
  ) async {
    await _pump(
      tester,
      results: <Object?>[
        null,
        null,
        const <UtilityTrendPoint>[],
        const <UtilityTrendPoint>[],
        null,
        null,
        [
          _reading('pm25', 20, location: 'ห้องสมุด'),
          _reading('co2', 600, location: 'ห้องสมุด'),
        ],
      ],
    );

    expect(find.text('ห้องสมุด'), findsWidgets);
    // The five zones this page used to invent.
    for (final invented in <String>[
      'อาคารเรียน 2',
      'อาคารเรียน 3',
      'ห้องปฏิบัติการ',
    ]) {
      expect(find.text(invented), findsNothing, reason: invented);
    }
  });

  testWidgets('no sensors means no air-quality verdict', (tester) async {
    await _pump(tester);

    expect(find.text('ยังไม่มีเซนเซอร์ที่ส่งค่าคุณภาพอากาศ'), findsOneWidget);
  });

  testWidgets('a failed load is stated and hides the raw error', (
    tester,
  ) async {
    await _pump(tester, fail: true);

    expect(
      find.textContaining('โหลดข้อมูลการใช้ทรัพยากรไม่สำเร็จ'),
      findsOneWidget,
    );
    expect(find.textContaining('utility_unreachable'), findsNothing);
    expect(find.text('โหลดไม่สำเร็จ'), findsWidgets);
  });
}
