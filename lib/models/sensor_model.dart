import 'package:flutter/material.dart';

enum SensorLevel { good, moderate, danger }

class SensorModel {
  final double pm25;
  final double co2;
  final double tvoc;
  final double temperature;
  final double humidity;
  final double lux;
  final DateTime? updatedAt;

  const SensorModel({
    this.pm25 = 0,
    this.co2 = 0,
    this.tvoc = 0,
    this.temperature = 0,
    this.humidity = 0,
    this.lux = 0,
    this.updatedAt,
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
    if (levels.any((l) => l == SensorLevel.moderate)) return SensorLevel.moderate;
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
