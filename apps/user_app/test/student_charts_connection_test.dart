import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/student_redesign_prototype/widgets/student_chart_builder_page.dart';
import 'package:my_first_app/pages/student_redesign_prototype/widgets/student_charts_page.dart';
import 'package:shared_core/shared_core.dart';

/// PBL-7: the list shows only what list_my_charts returns; the builder
/// offers only list_my_sensor_datasets, previews through sensor_history
/// with the chosen window, and saves through create_chart with exactly
/// that device / metric / window / note. Pumped at iPhone size.
final _ds = ChartableDataset(
  source: 'assignment',
  sourceId: 'asg-1',
  sourceTitle: 'วิเคราะห์ฝุ่น',
  courseId: 'c-1',
  deviceId: 'dev-1',
  deviceName: 'ฝุ่นหน้าห้อง',
  location: 'ม.1/1',
  metric: 'pm25',
  timeStart: DateTime.utc(2026, 9, 10, 0),
  timeEnd: DateTime.utc(2026, 9, 11, 0),
  label: 'ฝุ่น 1 วัน',
);

final _chart = SavedChart(
  id: 'ch-1',
  courseId: 'c-1',
  chartType: 'line',
  deviceId: 'dev-1',
  deviceName: 'ฝุ่นหน้าห้อง',
  location: 'ม.1/1',
  metric: 'pm25',
  timeStart: DateTime.utc(2026, 9, 10, 1),
  timeEnd: DateTime.utc(2026, 9, 10, 5),
  annotation: 'ช่วงเช้าฝุ่นสูง',
  createdAt: DateTime.utc(2026, 9, 18),
);

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  testWidgets(
    'list shows saved charts from the RPC and an honest empty state',
    (tester) async {
      _phone(tester);
      await tester.pumpWidget(
        MaterialApp(home: StudentChartsPage(loadCharts: () async => [_chart])),
      );
      await tester.pumpAndSettle();
      expect(find.text('ช่วงเช้าฝุ่นสูง'), findsOneWidget);
      expect(find.textContaining('ฝุ่นหน้าห้อง'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          home: StudentChartsPage(
            key: const Key('empty'),
            loadCharts: () async => const [],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('ยังไม่มีกราฟ'), findsOneWidget);
    },
  );

  testWidgets('deleting asks, then calls delete_chart with the id', (
    tester,
  ) async {
    _phone(tester);
    String? deleted;
    await tester.pumpWidget(
      MaterialApp(
        home: StudentChartsPage(
          loadCharts: () async => deleted == null ? [_chart] : const [],
          deleteChart: (id) async => deleted = id,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ลบ'));
    await tester.pumpAndSettle();
    expect(deleted, 'ch-1');
    expect(find.text('ยังไม่มีกราฟ'), findsOneWidget);
  });

  testWidgets(
    'builder: pick → preview with the dataset window → save with the note',
    (tester) async {
      _phone(tester);
      final previewCalls = <(String, String, DateTime, DateTime?)>[];
      Map<String, Object?>? saved;
      await tester.pumpWidget(
        MaterialApp(
          home: StudentChartBuilderPage(
            loadDatasets: () async => [_ds],
            getSensorHistory:
                ({
                  required String deviceId,
                  required String metric,
                  required DateTime from,
                  DateTime? to,
                }) async {
                  previewCalls.add((deviceId, metric, from, to));
                  return [
                    SensorDataPoint(
                      ts: DateTime.utc(2026, 9, 10, 1),
                      value: 20,
                    ),
                    SensorDataPoint(
                      ts: DateTime.utc(2026, 9, 10, 2),
                      value: 35,
                    ),
                  ];
                },
            createChart:
                ({
                  required String deviceId,
                  required String metric,
                  required DateTime timeStart,
                  required DateTime timeEnd,
                  String chartType = 'line',
                  String? courseId,
                  String? annotation,
                }) async {
                  saved = {
                    'deviceId': deviceId,
                    'metric': metric,
                    'from': timeStart,
                    'to': timeEnd,
                    'courseId': courseId,
                    'annotation': annotation,
                  };
                  return 'ch-new';
                },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('ฝุ่น 1 วัน'), findsOneWidget);
      // Nothing else is shown before a dataset is picked.
      expect(find.text('บันทึกกราฟ'), findsNothing);

      await tester.tap(find.text('ฝุ่น 1 วัน'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ดูตัวอย่างกราฟ'));
      await tester.pumpAndSettle();
      expect(previewCalls.single.$1, 'dev-1');
      expect(previewCalls.single.$2, 'pm25');
      expect(previewCalls.single.$3, DateTime.utc(2026, 9, 10, 0));
      expect(previewCalls.single.$4, DateTime.utc(2026, 9, 11, 0));
      expect(find.text('2 จุดข้อมูล'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'ฝุ่นขึ้นตอนเช้า');
      await tester.tap(find.text('บันทึกกราฟ'));
      await tester.pumpAndSettle();
      expect(saved?['deviceId'], 'dev-1');
      expect(saved?['metric'], 'pm25');
      expect(saved?['from'], DateTime.utc(2026, 9, 10, 0));
      expect(saved?['to'], DateTime.utc(2026, 9, 11, 0));
      expect(saved?['courseId'], 'c-1');
      expect(saved?['annotation'], 'ฝุ่นขึ้นตอนเช้า');
    },
  );

  testWidgets(
    'builder with no datasets explains why, offers nothing invented',
    (tester) async {
      _phone(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: StudentChartBuilderPage(loadDatasets: () async => const []),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('ยังไม่มีชุดข้อมูลให้สร้างกราฟ'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    },
  );
}
