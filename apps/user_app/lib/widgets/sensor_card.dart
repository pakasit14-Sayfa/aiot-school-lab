import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

class SensorCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final SensorLevel level;
  final SensorFreshness freshness;
  final String? timeLabel;
  final VoidCallback? onTap;
  // MQ-2 ไม่มีเกณฑ์ calibrate จริง — ห้ามฟันธงเป็น SensorLevel (ปกติ/
  // ปานกลาง/เกิน) ลอยๆ ใช้ override นี้แทนเพื่อโชว์ป้าย "ดิบ" สีเทากลาง
  final String? badgeLabelOverride;
  final Color? badgeColorOverride;

  const SensorCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.level,
    this.freshness = SensorFreshness.noData,
    this.timeLabel,
    this.onTap,
    this.badgeLabelOverride,
    this.badgeColorOverride,
  });

  @override
  Widget build(BuildContext context) {
    // Badge เดียว: สด/ล่าช้าเล็กน้อย -> โชว์ระดับความปลอดภัย (ปกติ/ไม่ปลอดภัย);
    // เซนเซอร์ไม่ทำงาน/ไม่มีข้อมูล -> โชว์สถานะนั้นแทน ไม่โชว์ทั้งคู่ซ้อนกัน
    final showLevelBadge =
        freshness == SensorFreshness.live ||
        freshness == SensorFreshness.delayed;
    final resolvedColor = badgeColorOverride ?? level.color;
    final badgeColor = showLevelBadge ? resolvedColor : freshness.color;
    final badgeLabel = showLevelBadge
        ? (badgeLabelOverride ?? level.label)
        : freshness.label;
    final color = resolvedColor;
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badgeLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: badgeColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      unit,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ),
                ],
              ),
              if (timeLabel != null) ...[
                const SizedBox(height: 4),
                Text(
                  'อัปเดต $timeLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: freshness.color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class SensorGrid extends StatelessWidget {
  final SensorModel sensor;
  // aqi/gas_mq2_percent ไม่ใช่ field บน SensorModel (มาจาก sensor_latest
  // แบบ raw row ต่างหาก) — ส่งเข้ามาจากหน้าที่ query แยกไว้แล้ว (ดู
  // aiot_dashboard_page.dart)
  final ({double value, DateTime? ts})? aqiReading;
  final ({double value, DateTime? ts})? gasReading;

  const SensorGrid({
    super.key,
    required this.sensor,
    this.aqiReading,
    this.gasReading,
  });

  // ยืนยันกับผู้ทำ firmware แล้ว (2026-08-31): นี่คือดัชนี AQI-UBA ของชิป
  // ENS160 สเกล 1-5 (ตาม German UBA) ไม่ใช่ AQI มาตรฐาน 0-500 ของ US EPA/
  // กรมควบคุมมลพิษไทย
  static String _aqiUbaLabel(double value) {
    switch (value.round()) {
      case 1:
        return 'ดีมาก';
      case 2:
        return 'ดี';
      case 3:
        return 'ปานกลาง';
      case 4:
        return 'แย่';
      case 5:
        return 'ไม่ปลอดภัย';
      default:
        return 'ไม่ทราบระดับ';
    }
  }

  static SensorLevel _aqiUbaSensorLevel(double value) {
    final rounded = value.round();
    if (rounded <= 2) return SensorLevel.good;
    if (rounded == 3) return SensorLevel.moderate;
    return SensorLevel.danger;
  }

  static SensorFreshness _rawFreshnessOf(DateTime? ts) {
    if (ts == null) return SensorFreshness.noData;
    final age = DateTime.now().toUtc().difference(ts.toUtc());
    if (age <= const Duration(minutes: 2)) return SensorFreshness.live;
    if (age <= const Duration(minutes: 10)) return SensorFreshness.delayed;
    return SensorFreshness.offline;
  }

  static String _rawRelativeTimeLabel(DateTime? ts) {
    if (ts == null) return 'ไม่มีข้อมูล';
    final age = DateTime.now().toUtc().difference(ts.toUtc());
    if (age.inSeconds < 60) return 'เมื่อสักครู่';
    if (age.inMinutes < 60) return '${age.inMinutes} นาทีที่แล้ว';
    if (age.inHours < 24) return '${age.inHours} ชม.ที่แล้ว';
    return '${age.inDays} วันที่แล้ว';
  }

  @override
  Widget build(BuildContext context) {
    // SensorModel defaults an absent metric to 0, indistinguishable from
    // a real 0 reading — check metricUpdatedAt per metric before trusting
    // the value (same fix as director_overview_page.dart /
    // aiot_weather_sensors_card.dart's identical bug).
    final hasPm25 = sensor.metricUpdatedAt.containsKey('pm25');
    final hasCo2 = sensor.metricUpdatedAt.containsKey('co2');
    final hasTemp = sensor.metricUpdatedAt.containsKey('temperature');
    final hasHumidity = sensor.metricUpdatedAt.containsKey('humidity');
    final hasTvoc = sensor.metricUpdatedAt.containsKey('tvoc');
    final hasLux = sensor.metricUpdatedAt.containsKey('light_lux');

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.4,
      children: [
        SensorCard(
          label: 'PM2.5',
          value: hasPm25 ? sensor.pm25.toStringAsFixed(1) : '-',
          unit: 'µg/m³',
          icon: Icons.blur_on,
          level: sensor.pm25Level,
          freshness: sensor.freshnessOf('pm25'),
          timeLabel: sensor.relativeTimeLabel('pm25'),
        ),
        SensorCard(
          // ยืนยันกับผู้ทำ firmware แล้ว (2026-08-31): บอร์ดใช้ชิปแก๊ส
          // ENS160 ค่า "co2" ที่ส่งเข้าระบบคือ eCO2 (Equivalent CO2) ที่
          // ชิปคำนวณจาก VOCs/hydrogen ภายใน ไม่ใช่การวัด CO2 ตรงแบบ
          // เซนเซอร์ NDIR
          label: 'eCO2 (ประมาณการ)',
          value: hasCo2 ? sensor.co2.toStringAsFixed(0) : '-',
          unit: 'ppm',
          icon: Icons.co2,
          level: sensor.co2Level,
          freshness: sensor.freshnessOf('co2'),
          timeLabel: sensor.relativeTimeLabel('co2'),
        ),
        SensorCard(
          label: 'อุณหภูมิ',
          value: hasTemp ? sensor.temperature.toStringAsFixed(1) : '-',
          unit: '°C',
          icon: Icons.thermostat,
          level: sensor.tempLevel,
          freshness: sensor.freshnessOf('temperature'),
          timeLabel: sensor.relativeTimeLabel('temperature'),
        ),
        SensorCard(
          label: 'ความชื้น',
          value: hasHumidity ? sensor.humidity.toStringAsFixed(0) : '-',
          unit: '%',
          icon: Icons.water_drop,
          level: sensor.humidityLevel,
          freshness: sensor.freshnessOf('humidity'),
          timeLabel: sensor.relativeTimeLabel('humidity'),
        ),
        SensorCard(
          // ใช้เกณฑ์ SensorModel.tvocLevel ที่มีอยู่แล้ว — แต่ยังไม่ยืนยัน
          // 100% ว่าหน่วยที่ ENS160 ส่งมาคือ ppb หรือ mg/m³ ตามที่กำกับไว้
          // ที่นี่ ถ้าคลาดเคลื่อน ระดับอาจผิดไปด้วย — ควรยืนยันหน่วยกับ
          // ผู้ทำ firmware อีกครั้ง
          label: 'TVOC',
          value: hasTvoc ? sensor.tvoc.toStringAsFixed(2) : '-',
          unit: 'mg/m³',
          icon: Icons.science,
          level: sensor.tvocLevel,
          freshness: sensor.freshnessOf('tvoc'),
          timeLabel: sensor.relativeTimeLabel('tvoc'),
        ),
        SensorCard(
          label: 'แสงสว่าง',
          value: hasLux ? sensor.lux.toStringAsFixed(0) : '-',
          unit: 'lux',
          icon: Icons.light_mode,
          level: sensor.luxLevel,
          freshness: sensor.freshnessOf('light_lux'),
          timeLabel: sensor.relativeTimeLabel('light_lux'),
        ),
        SensorCard(
          label: 'AQI-UBA (ENS160)',
          value: aqiReading != null
              ? aqiReading!.value.toStringAsFixed(0)
              : '-',
          unit: aqiReading != null ? _aqiUbaLabel(aqiReading!.value) : '',
          icon: Icons.eco,
          level: aqiReading != null
              ? _aqiUbaSensorLevel(aqiReading!.value)
              : SensorLevel.good,
          freshness: _rawFreshnessOf(aqiReading?.ts),
          timeLabel: aqiReading != null
              ? _rawRelativeTimeLabel(aqiReading!.ts)
              : null,
        ),
        SensorCard(
          // MQ-2 ตอบสนองต่อทั้งแก๊สติดไฟและควันจริงตามสเปกชิป แต่ส่งออกมา
          // เป็นสัญญาณตัวเลขเดียวรวมกัน แยกไม่ออกว่าเกิดจากแก๊สหรือควัน —
          // ห้ามเขียนค่าเป็น "แก๊ส/ควัน X%" เฉยๆ ต้องกำกับ "(ดิบ)" เสมอ
          // จนกว่าจะ calibrate เป็น ppm จริง — ไม่มีสีระดับ (ปกติ/ปานกลาง/
          // เกิน) เพราะไม่มีเกณฑ์ calibrate จริง
          label: 'แก๊ส/ควัน (MQ-2)',
          value: gasReading != null
              ? gasReading!.value.toStringAsFixed(0)
              : '-',
          unit: '% (ดิบ)',
          icon: Icons.local_fire_department,
          level: SensorLevel.good,
          badgeLabelOverride: gasReading != null ? 'ดิบ' : null,
          badgeColorOverride: gasReading != null
              ? const Color(0xFF64748B)
              : null,
          freshness: _rawFreshnessOf(gasReading?.ts),
          timeLabel: gasReading != null
              ? _rawRelativeTimeLabel(gasReading!.ts)
              : null,
        ),
      ],
    );
  }
}

class OverallAirQualityCard extends StatelessWidget {
  final SensorModel sensor;

  const OverallAirQualityCard({super.key, required this.sensor});

  @override
  Widget build(BuildContext context) {
    final color = sensor.overallColor;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(sensor.overallLevel.icon, color: Colors.white, size: 48),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'สภาพแวดล้อมโดยรวม',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sensor.overallLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (sensor.updatedAt != null)
                    Text(
                      'อัปเดต: ${_formatTime(sensor.updatedAt!)}',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'เมื่อกี้';
    if (diff.inMinutes < 60) return '${diff.inMinutes} นาทีที่แล้ว';
    return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')} น.';
  }
}

class SensorLoadingCard extends StatelessWidget {
  const SensorLoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('กำลังโหลดข้อมูลเซ็นเซอร์...'),
            ],
          ),
        ),
      ),
    );
  }
}

class SensorNoDataCard extends StatelessWidget {
  const SensorNoDataCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.sensors_off, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text(
                'ยังไม่มีข้อมูลจากเซ็นเซอร์',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 4),
              const Text(
                'ตรวจสอบการเชื่อมต่อ EdgeBox',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
