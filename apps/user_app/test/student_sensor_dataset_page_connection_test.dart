import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/student_redesign_prototype/widgets/student_sensor_dataset_page.dart';
import 'package:shared_core/shared_core.dart';

/// PBL-6 viewer: the readings come only from the injected sensor_history
/// call, with the dataset's device / metric / window; stats are computed
/// from those readings; an empty window says so.
final _ds = AssignmentSensorDataset(
  id: 'ds-1',
  deviceId: 'dev-1',
  metric: 'temperature',
  timeStart: DateTime.utc(2026, 9, 10, 1),
  timeEnd: DateTime.utc(2026, 9, 10, 3),
  label: 'อุณหภูมิห้องเช้า',
);

Future<void> _pump(
  WidgetTester tester, {
  required Future<List<SensorDataPoint>> Function({
    required String deviceId,
    required String metric,
    required DateTime from,
    DateTime? to,
  })
  history,
}) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: StudentSensorDatasetPage(
        dataset: _ds,
        assignmentTitle: 'แบบฝึกหัดบทที่ 3',
        getSensorHistory: history,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'asks sensor_history for exactly the pinned window and shows real stats',
    (tester) async {
      String? gotDevice;
      String? gotMetric;
      DateTime? gotFrom;
      DateTime? gotTo;
      await _pump(
        tester,
        history:
            ({
              required String deviceId,
              required String metric,
              required DateTime from,
              DateTime? to,
            }) async {
              gotDevice = deviceId;
              gotMetric = metric;
              gotFrom = from;
              gotTo = to;
              return [
                SensorDataPoint(ts: DateTime.utc(2026, 9, 10, 1), value: 28),
                SensorDataPoint(ts: DateTime.utc(2026, 9, 10, 2), value: 31),
                SensorDataPoint(ts: DateTime.utc(2026, 9, 10, 3), value: 30),
              ];
            },
      );
      expect(gotDevice, 'dev-1');
      expect(gotMetric, 'temperature');
      expect(gotFrom, DateTime.utc(2026, 9, 10, 1));
      expect(gotTo, DateTime.utc(2026, 9, 10, 3));
      expect(find.text('อุณหภูมิห้องเช้า'), findsOneWidget);
      // min/max also appear as chart axis labels → at least one each.
      expect(find.text('28'), findsWidgets); // min
      expect(find.text('31'), findsWidgets); // max
      expect(find.text('29.7'), findsOneWidget); // avg
      expect(find.textContaining('3 จุดข้อมูล'), findsOneWidget);
    },
  );

  testWidgets('an empty window is reported, not filled with sample data', (
    tester,
  ) async {
    await _pump(
      tester,
      history:
          ({
            required String deviceId,
            required String metric,
            required DateTime from,
            DateTime? to,
          }) async => const [],
    );
    expect(find.text('ไม่มีข้อมูลในช่วงเวลานี้'), findsOneWidget);
    expect(find.text('เฉลี่ย'), findsNothing);
  });
}
