/// A window of sensor data the current user is allowed to chart
/// (list_my_sensor_datasets): a teacher-pinned assignment dataset or a
/// published lesson's sensor link. PBL-7.
class ChartableDataset {
  const ChartableDataset({
    required this.source,
    required this.sourceId,
    required this.sourceTitle,
    required this.courseId,
    required this.deviceId,
    required this.deviceName,
    required this.location,
    required this.metric,
    required this.timeStart,
    required this.timeEnd,
    required this.label,
  });

  /// 'assignment' or 'lesson'.
  final String source;
  final String sourceId;
  final String sourceTitle;
  final String? courseId;
  final String deviceId;
  final String deviceName;
  final String? location;
  final String metric;

  /// Null bounds mean the teacher left that side open.
  final DateTime? timeStart;
  final DateTime? timeEnd;
  final String? label;

  factory ChartableDataset.fromRow(Map<String, dynamic> row) =>
      ChartableDataset(
        source: row['source'] as String,
        sourceId: row['source_id'] as String,
        sourceTitle: row['source_title'] as String? ?? '',
        courseId: row['course_id'] as String?,
        deviceId: row['device_id'] as String,
        deviceName: row['device_name'] as String? ?? '',
        location: row['location'] as String?,
        metric: row['metric'] as String,
        timeStart: row['time_start'] == null
            ? null
            : DateTime.parse(row['time_start'] as String).toUtc(),
        timeEnd: row['time_end'] == null
            ? null
            : DateTime.parse(row['time_end'] as String).toUtc(),
        label: row['label'] as String?,
      );
}

/// A saved chart (charts table): the query, never the numbers.
class SavedChart {
  const SavedChart({
    required this.id,
    required this.courseId,
    required this.chartType,
    required this.deviceId,
    required this.deviceName,
    required this.location,
    required this.metric,
    required this.timeStart,
    required this.timeEnd,
    required this.annotation,
    required this.createdAt,
  });

  final String id;
  final String? courseId;
  final String chartType;
  final String deviceId;
  final String deviceName;
  final String? location;
  final String metric;
  final DateTime timeStart;
  final DateTime timeEnd;
  final String? annotation;
  final DateTime createdAt;

  factory SavedChart.fromRow(Map<String, dynamic> row) => SavedChart(
    id: row['id'] as String,
    courseId: row['course_id'] as String?,
    chartType: row['chart_type'] as String,
    deviceId: row['device_id'] as String,
    deviceName: row['device_name'] as String? ?? '',
    location: row['location'] as String?,
    metric: row['metric'] as String,
    timeStart: DateTime.parse(row['time_start'] as String).toUtc(),
    timeEnd: DateTime.parse(row['time_end'] as String).toUtc(),
    annotation: row['annotation'] as String?,
    createdAt: DateTime.parse(row['created_at'] as String).toUtc(),
  );
}
