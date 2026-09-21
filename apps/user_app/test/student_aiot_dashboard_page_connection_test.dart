import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/student_redesign_prototype/widgets/student_aiot_dashboard_page.dart';
import 'package:shared_core/shared_core.dart';

/// The Student AIoT dashboard replaced the shared Material-blue page on
/// 2026-09-18. It must show the readings the streams deliver — never a
/// fabricated value — and say so honestly when there are none. Pumped at
/// iPhone size (390×844) because that is where the old page overflowed.
Future<void> _pump(
  WidgetTester tester, {
  required Stream<SensorModel?> sensor,
  Stream<List<Map<String, dynamic>>>? raw,
}) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: StudentAiotDashboardPage(
        sensorStreamOverride: sensor,
        rawReadingsStreamOverride: raw ?? Stream.value(const []),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the real readings from the streams, with offline badges', (
    tester,
  ) async {
    final stale = DateTime.now().toUtc().subtract(const Duration(days: 15));
    await _pump(
      tester,
      sensor: Stream.value(
        SensorModel(
          pm25: 39.8,
          co2: 448,
          tvoc: 46,
          temperature: 30.5,
          humidity: 41,
          lux: 56,
          updatedAt: stale,
          metricUpdatedAt: {
            'pm25': stale,
            'co2': stale,
            'tvoc': stale,
            'temperature': stale,
            'humidity': stale,
            'light_lux': stale,
          },
        ),
      ),
      raw: Stream.value([
        {'metric': 'aqi', 'value': 1, 'ts': stale.toIso8601String()},
        {
          'metric': 'gas_mq2_percent',
          'value': 9,
          'ts': stale.toIso8601String(),
        },
      ]),
    );
    // Values come from the model, not from anywhere else.
    expect(find.text('40'), findsOneWidget); // pm25 39.8 → 0 decimals
    expect(find.text('30.5'), findsOneWidget);
    expect(find.text('448'), findsOneWidget);
    expect(find.text('9'), findsOneWidget); // MQ-2 raw percent
    expect(find.text('ดีมาก'), findsOneWidget); // AQI-UBA 1
    // Overall: pm25 39.8 is past the danger threshold → honest headline.
    expect(find.text('คุณภาพอากาศแย่'), findsOneWidget);
    // Every reading is 15 days old → none online.
    expect(find.text('ออนไลน์ 0/8 เซนเซอร์'), findsOneWidget);
    expect(find.textContaining('ไม่ออนไลน์ • 15 วันที่แล้ว'), findsWidgets);
    expect(find.text('เซนเซอร์ไม่ทำงาน'), findsNothing);
  });

  testWidgets('a metric the device never reported shows no value, not zero', (
    tester,
  ) async {
    final now = DateTime.now().toUtc();
    await _pump(
      tester,
      sensor: Stream.value(
        SensorModel(pm25: 12, updatedAt: now, metricUpdatedAt: {'pm25': now}),
      ),
    );
    expect(find.text('12'), findsOneWidget);
    expect(find.text('ออนไลน์ 1/8 เซนเซอร์'), findsOneWidget);
    // temperature/humidity/co2/tvoc/lux are absent → "—", never "0".
    expect(find.text('—'), findsNWidgets(7));
    expect(find.text('0'), findsNothing);
    expect(find.text('0.0'), findsNothing);
  });

  testWidgets('no sensor at all shows the honest empty state', (tester) async {
    await _pump(tester, sensor: Stream.value(null));
    expect(find.text('ยังไม่มีข้อมูลเซนเซอร์'), findsOneWidget);
    expect(find.text('คุณภาพอากาศดี'), findsNothing);
  });
}
