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

/// One enrolled student's progress on a lesson (`list_lesson_progress`).
/// A student who never opened the lesson is still a row: 0% / not completed.
class LessonStudentProgress {
  final String studentId;
  final String firstName;
  final String lastName;
  final String email;
  final double progressPct;
  final bool completed;
  final DateTime? completedAt;
  final DateTime? updatedAt;

  const LessonStudentProgress({
    required this.studentId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.progressPct,
    required this.completed,
    required this.completedAt,
    required this.updatedAt,
  });

  String get fullName => '$firstName $lastName'.trim();

  /// Never opened the lesson: no progress row at all.
  bool get opened => updatedAt != null;

  factory LessonStudentProgress.fromRow(Map<String, dynamic> row) {
    return LessonStudentProgress(
      studentId: row['student_id'] as String,
      firstName: (row['first_name'] as String?) ?? '',
      lastName: (row['last_name'] as String?) ?? '',
      email: (row['email'] as String?) ?? '',
      progressPct: ((row['progress_pct'] as num?) ?? 0).toDouble(),
      completed: (row['completed'] as bool?) ?? false,
      completedAt: row['completed_at'] == null
          ? null
          : DateTime.parse(row['completed_at'] as String),
      updatedAt: row['updated_at'] == null
          ? null
          : DateTime.parse(row['updated_at'] as String),
    );
  }
}

/// ชนิดของบล็อกเนื้อหาในบทเรียนหนึ่งบล็อก — mirror ของค่าที่เก็บเป็นสตริงใน
/// `lessons.content -> 'blocks' -> [] -> 'type'` (jsonb ไม่มี enum บังคับ
/// ค่าที่อ่านไม่รู้จักจะตกมาเป็น [ContentBlockType.text] เสมอ)
///
/// เดิมประกาศไว้ในไฟล์หน้าจอของครู (`teacher_lesson_editor_page.dart`) ทำให้
/// ฝั่งนักเรียนเอาไปใช้ไม่ได้ จึงอ่านได้แค่ `content['body']` ข้อความแบน ๆ
/// และการจัดรูปแบบที่ครูตั้งใจไว้หายไปทั้งหมด — ย้ายมาไว้ตรงกลางเพื่อให้ทั้ง
/// สองเลนอ่านโครงสร้างเดียวกัน
enum ContentBlockType {
  heading,
  text,
  bulletList,
  image,
  video,
  fileDownload,
  externalLink,
  calloutWarning,
  summaryBox,
  sensorChart,
}

/// หนึ่งบล็อกเนื้อหา — เขียนโดยหน้าแก้ไขบทเรียนของครู อ่านโดยหน้าบทเรียน
/// ของนักเรียนและหน้าดูตัวอย่างของครู
///
/// ฟิลด์เป็น mutable เพราะตัวแก้ไขผูก `TextEditingController` เข้ากับบล็อก
/// โดยตรงและแก้ค่าในที่
class ContentBlockModel {
  ContentBlockModel({
    required this.id,
    required this.type,
    this.text = '',
    this.mediaUrl = '',
    this.caption = '',
    this.sensorDeviceId = '',
    this.sensorMetric = '',
    this.timeRange = '',
  });

  factory ContentBlockModel.fromJson(Map json, {required String fallbackId}) {
    final typeName = json['type'] as String? ?? 'text';
    return ContentBlockModel(
      id: json['id'] as String? ?? fallbackId,
      type: ContentBlockType.values.firstWhere(
        (t) => t.name == typeName,
        orElse: () => ContentBlockType.text,
      ),
      text: json['text'] as String? ?? '',
      mediaUrl: json['mediaUrl'] as String? ?? '',
      caption: json['caption'] as String? ?? '',
      sensorDeviceId: json['sensorDeviceId'] as String? ?? '',
      sensorMetric: json['sensorMetric'] as String? ?? '',
      timeRange: json['timeRange'] as String? ?? '',
    );
  }

  final String id;
  ContentBlockType type;
  String text;
  String mediaUrl;
  String caption;
  String sensorDeviceId;
  String sensorMetric;
  String timeRange;

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'text': text,
    'mediaUrl': mediaUrl,
    'caption': caption,
    'sensorDeviceId': sensorDeviceId,
    'sensorMetric': sensorMetric,
    'timeRange': timeRange,
  };
}

/// อ่านบล็อกออกจาก `lessons.content` — คืนลิสต์ว่างเมื่อบทเรียนนั้นถูกสร้าง
/// ก่อนมีตัวแก้ไขแบบบล็อก (มีแต่ `content['body']`) ผู้เรียกต้องตกกลับไป
/// แสดง body แทน ไม่ใช่แสดงหน้าว่าง
List<ContentBlockModel> lessonBlocksFromContent(Map<String, dynamic>? content) {
  final raw = content?['blocks'];
  if (raw is! List) return [];
  final blocks = <ContentBlockModel>[];
  for (var i = 0; i < raw.length; i++) {
    final item = raw[i];
    if (item is Map) {
      blocks.add(ContentBlockModel.fromJson(item, fallbackId: 'b-$i'));
    }
  }
  return blocks;
}

/// ข้อความแบนที่เก็บคู่ไว้ใน `content['body']` — ยังต้องเขียนต่อไปเพราะเป็น
/// สิ่งที่หน้าจอรุ่นเก่า (`pages/student/lesson_view_page.dart`,
/// `pages/teacher/lesson_form_page.dart`) อ่าน และเป็น fallback ของบทเรียน
/// ที่ยังไม่มีบล็อก
///
/// ตัดบล็อกหัวข้อออก (หน้านักเรียนโชว์ชื่อบทเรียนอยู่แล้ว) และตัดบล็อก
/// "สื่อแนบ:" ที่ระบบสร้างให้อัตโนมัติ (ไฟล์แนบมีหัวข้อของตัวเองแยกต่างหาก)
String lessonBodyFromBlocks(List<ContentBlockModel> blocks) => blocks
    .where(
      (b) =>
          b.text.trim().isNotEmpty &&
          b.type != ContentBlockType.heading &&
          !b.text.trimLeft().startsWith('สื่อแนบ:'),
    )
    .map((b) => b.text.trim())
    .join('\n\n');
