import 'package:flutter/material.dart';

enum SensorLevel { good, moderate, danger }

/// ความสดของค่าที่อ่านได้ล่าสุดของ metric หนึ่งตัว — แยกจาก [SensorLevel]
/// (ซึ่งบอกว่าค่านั้น "ปลอดภัยไหม") เพราะค่าเก่ามากๆ ก็ยัง "ปกติ" ได้ตามตัวเลข
/// แต่ไม่ควรให้ผู้ใช้เข้าใจว่าเป็นค่าสดตอนนี้
enum SensorFreshness { live, delayed, offline, noData }

extension SensorFreshnessExt on SensorFreshness {
  String get label => switch (this) {
    SensorFreshness.live => 'สด (Live)',
    SensorFreshness.delayed => 'ข้อมูลล่าช้า',
    SensorFreshness.offline => 'เซนเซอร์ไม่ทำงาน',
    SensorFreshness.noData => 'ไม่มีข้อมูล',
  };

  Color get color => switch (this) {
    SensorFreshness.live => const Color(0xFF16A34A),
    SensorFreshness.delayed => const Color(0xFFD97706),
    SensorFreshness.offline => const Color(0xFFDC2626),
    SensorFreshness.noData => const Color(0xFF94A3B8),
  };
}

class SensorModel {
  final double pm25;
  final double co2;
  final double tvoc;
  final double temperature;
  final double humidity;
  final double lux;
  final DateTime? updatedAt;

  /// เวลาที่แต่ละ metric อัปเดตล่าสุดจริงๆ — คนละอันกับ [updatedAt] (ซึ่งเป็นแค่
  /// ค่าล่าสุดสุดในบรรดา metric ทั้งหมด) เพราะแต่ละ metric อาจมาจากบอร์ด/ช่วง
  /// เวลาคนละอันกัน ใช้บอกความสด/ค่าเก่าของแต่ละตัวแยกกัน (เช่น pm25 สดวันนี้
  /// แต่ temperature เป็นข้อมูลเก่าจากเดือนก่อน)
  final Map<String, DateTime> metricUpdatedAt;

  const SensorModel({
    this.pm25 = 0,
    this.co2 = 0,
    this.tvoc = 0,
    this.temperature = 0,
    this.humidity = 0,
    this.lux = 0,
    this.updatedAt,
    this.metricUpdatedAt = const {},
  });

  factory SensorModel.fromMap(Map<dynamic, dynamic> map) {
    return SensorModel(
      pm25: _toDouble(map['pm25']),
      co2: _toDouble(map['co2']),
      tvoc: _toDouble(map['tvoc']),
      temperature: _toDouble(map['temperature']),
      humidity: _toDouble(map['humidity']),
      lux: _toDouble(map['lux']),
      updatedAt: map['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int)
          : null,
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  SensorLevel get pm25Level {
    if (pm25 < 12) return SensorLevel.good;
    if (pm25 < 35) return SensorLevel.moderate;
    return SensorLevel.danger;
  }

  SensorLevel get co2Level {
    if (co2 < 800) return SensorLevel.good;
    if (co2 < 1500) return SensorLevel.moderate;
    return SensorLevel.danger;
  }

  SensorLevel get tvocLevel {
    if (tvoc < 0.3) return SensorLevel.good;
    if (tvoc < 0.5) return SensorLevel.moderate;
    return SensorLevel.danger;
  }

  SensorLevel get tempLevel {
    if (temperature >= 20 && temperature <= 28) return SensorLevel.good;
    if (temperature > 28 && temperature <= 32) return SensorLevel.moderate;
    return SensorLevel.danger;
  }

  /// อายุของค่า metric นี้เทียบกับตอนนี้ — null ถ้าไม่เคยมีข้อมูลเลย
  Duration? ageOf(String metric) {
    final ts = metricUpdatedAt[metric];
    if (ts == null) return null;
    return DateTime.now().toUtc().difference(ts.toUtc());
  }

  /// เกณฑ์: สด ≤2 นาที, ล่าช้า ≤10 นาที, เกินนั้นถือว่าเซนเซอร์ไม่ทำงาน —
  /// บอร์ดจริงส่งค่าใหม่ทุก ~3-5 วิ ตอนทำงานปกติ ดังนั้นห่างเกิน 10 นาที
  /// แทบจะแปลว่า bridge/เน็ตเวิร์กเสียแน่ๆ ไม่ใช่แค่ดีเลย์ธรรมดา
  SensorFreshness freshnessOf(String metric) {
    final age = ageOf(metric);
    if (age == null) return SensorFreshness.noData;
    if (age <= const Duration(minutes: 2)) return SensorFreshness.live;
    if (age <= const Duration(minutes: 10)) return SensorFreshness.delayed;
    return SensorFreshness.offline;
  }

  /// ข้อความเวลาแบบอ่านง่าย เช่น "2 นาทีที่แล้ว", "5 ชม.ที่แล้ว", "34 วันที่แล้ว"
  String relativeTimeLabel(String metric) {
    final age = ageOf(metric);
    if (age == null) return 'ไม่มีข้อมูล';
    if (age.inSeconds < 60) return 'เมื่อสักครู่';
    if (age.inMinutes < 60) return '${age.inMinutes} นาทีที่แล้ว';
    if (age.inHours < 24) return '${age.inHours} ชม.ที่แล้ว';
    return '${age.inDays} วันที่แล้ว';
  }

  SensorLevel get humidityLevel {
    if (humidity >= 40 && humidity <= 70) return SensorLevel.good;
    if (humidity > 70 && humidity <= 80) return SensorLevel.moderate;
    return SensorLevel.danger;
  }

  SensorLevel get luxLevel {
    if (lux >= 300) return SensorLevel.good;
    if (lux >= 150) return SensorLevel.moderate;
    return SensorLevel.danger;
  }

  SensorLevel get overallLevel {
    final levels = [pm25Level, co2Level, tvocLevel, tempLevel, humidityLevel];
    if (levels.any((l) => l == SensorLevel.danger)) return SensorLevel.danger;
    if (levels.any((l) => l == SensorLevel.moderate)) {
      return SensorLevel.moderate;
    }
    return SensorLevel.good;
  }

  String get overallLabel {
    switch (overallLevel) {
      case SensorLevel.good:
        return 'คุณภาพอากาศดี';
      case SensorLevel.moderate:
        return 'คุณภาพอากาศปานกลาง';
      case SensorLevel.danger:
        return 'คุณภาพอากาศแย่';
    }
  }

  Color get overallColor {
    switch (overallLevel) {
      case SensorLevel.good:
        return const Color(0xFF2E7D32);
      case SensorLevel.moderate:
        return const Color(0xFFF57F17);
      case SensorLevel.danger:
        return const Color(0xFFC62828);
    }
  }
}

extension SensorLevelExt on SensorLevel {
  Color get color {
    switch (this) {
      case SensorLevel.good:
        return const Color(0xFF2E7D32);
      case SensorLevel.moderate:
        return const Color(0xFFF57F17);
      case SensorLevel.danger:
        return const Color(0xFFC62828);
    }
  }

  String get label {
    switch (this) {
      case SensorLevel.good:
        return 'ดี';
      case SensorLevel.moderate:
        return 'ปานกลาง';
      case SensorLevel.danger:
        return 'อันตราย';
    }
  }

  IconData get icon {
    switch (this) {
      case SensorLevel.good:
        return Icons.check_circle;
      case SensorLevel.moderate:
        return Icons.warning_amber;
      case SensorLevel.danger:
        return Icons.dangerous;
    }
  }
}
