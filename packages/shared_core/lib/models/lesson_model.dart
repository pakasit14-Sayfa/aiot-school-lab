class DeviceOption {
  final String id;
  final String name;
  final String type;
  final String? location;
  final String status;

  /// ชนิดอุปกรณ์ที่เป็น "เซนเซอร์" และ metric ที่แต่ละชนิดวัดได้ — mirror ของ
  /// enum `device_type` / `metric_type` ในฐานข้อมูล (20260715 initial_schema)
  /// เก็บไว้ที่เดียวใน Dart: อุปกรณ์ที่ไม่อยู่ในนี้ (relay, camera,
  /// emergency_button, warning_light, mini_pc, aiot_gateway) ไม่มีค่าอ่าน
  /// จึงห้ามเสนอเป็นแหล่งข้อมูลกราฟ เมื่อ migration เพิ่มชนิด/metric ใหม่
  /// ให้เพิ่มที่นี่ที่เดียว
  static const Map<String, List<String>> sensorMetricsByType = {
    'pm25_sensor': ['pm25'],
    'air_quality_sensor': [
      'pm25',
      'aqi',
      'co2',
      'tvoc',
      'temperature',
      'humidity',
      'gas_mq2_percent',
    ],
    'light_sensor': ['light_lux'],
    'energy_meter': ['energy_kwh', 'power_w'],
    'water_meter': ['water_flow_lmin', 'water_volume_l', 'water_m3'],
  };

  bool get isSensor => sensorMetricsByType.containsKey(type);

  /// metric ที่อุปกรณ์นี้วัดได้ — ว่างถ้าไม่ใช่เซนเซอร์
  List<String> get metrics => sensorMetricsByType[type] ?? const [];

  const DeviceOption({
    required this.id,
    required this.name,
    required this.type,
    required this.location,
    required this.status,
  });

  factory DeviceOption.fromRow(Map<String, dynamic> row) => DeviceOption(
    id: (row['device_id'] ?? row['id']) as String,
    name: (row['name'] ?? '') as String,
    type: (row['type'] ?? '') as String,
    location: row['location'] as String?,
    status: (row['status'] ?? 'offline') as String,
  );
}

class LessonSummary {
  final String id;
  final String title;
  final String status;
  final DateTime? publishedAt;
  final int materialsCount;
  final int sensorLinksCount;

  const LessonSummary({
    required this.id,
    required this.title,
    required this.status,
    required this.publishedAt,
    this.materialsCount = 0,
    this.sensorLinksCount = 0,
  });

  factory LessonSummary.fromRow(Map<String, dynamic> row) => LessonSummary(
    id: row['lesson_id'] as String,
    title: row['title'] as String,
    status: row['status'] as String,
    publishedAt: row['published_at'] == null
        ? null
        : DateTime.parse(row['published_at'] as String).toUtc(),
    materialsCount: (row['materials_count'] as num?)?.toInt() ?? 0,
    sensorLinksCount: (row['sensor_links_count'] as num?)?.toInt() ?? 0,
  );

  bool get isPublished => status == 'published';
}

class LessonMaterial {
  final String id;
  final String type;
  final String? title;
  final String url;
  final int sortOrder;

  const LessonMaterial({
    required this.id,
    required this.type,
    required this.title,
    required this.url,
    required this.sortOrder,
  });

  factory LessonMaterial.fromJson(Map<String, dynamic> json) => LessonMaterial(
    id: json['id'] as String,
    type: json['type'] as String,
    title: json['title'] as String?,
    url: json['url'] as String,
    sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
  );
}

class LessonSensorLink {
  final String id;
  final String deviceId;
  final String metric;
  final DateTime? timeStart;
  final DateTime? timeEnd;
  final String? caption;

  const LessonSensorLink({
    required this.id,
    required this.deviceId,
    required this.metric,
    required this.timeStart,
    required this.timeEnd,
    required this.caption,
  });

  factory LessonSensorLink.fromJson(Map<String, dynamic> json) =>
      LessonSensorLink(
        id: json['id'] as String,
        deviceId: json['device_id'] as String,
        metric: json['metric'] as String,
        timeStart: json['time_start'] == null
            ? null
            : DateTime.parse(json['time_start'] as String).toUtc(),
        timeEnd: json['time_end'] == null
            ? null
            : DateTime.parse(json['time_end'] as String).toUtc(),
        caption: json['caption'] as String?,
      );
}

class LessonDetail {
  final String id;
  final String courseId;
  final String title;
  final Map<String, dynamic>? content;
  final String status;
  final DateTime? publishedAt;
  final List<LessonMaterial> materials;
  final List<LessonSensorLink> sensorLinks;
  final num? progressPct;
  final bool? completed;

  const LessonDetail({
    required this.id,
    required this.courseId,
    required this.title,
    required this.content,
    required this.status,
    required this.publishedAt,
    required this.materials,
    required this.sensorLinks,
    required this.progressPct,
    required this.completed,
  });

  factory LessonDetail.fromRow(Map<String, dynamic> row) {
    final materials = (row['materials'] as List? ?? [])
        .map((item) => LessonMaterial.fromJson(item as Map<String, dynamic>))
        .toList();
    final sensorLinks = (row['sensor_links'] as List? ?? [])
        .map((item) => LessonSensorLink.fromJson(item as Map<String, dynamic>))
        .toList();

    return LessonDetail(
      id: row['lesson_id'] as String,
      courseId: row['course_id'] as String,
      title: row['title'] as String,
      content: row['content'] as Map<String, dynamic>?,
      status: row['status'] as String,
      publishedAt: row['published_at'] == null
          ? null
          : DateTime.parse(row['published_at'] as String).toUtc(),
      materials: materials,
      sensorLinks: sensorLinks,
      progressPct: row['progress_pct'] as num?,
      completed: row['completed'] as bool?,
    );
  }

  bool get isPublished => status == 'published';
}
