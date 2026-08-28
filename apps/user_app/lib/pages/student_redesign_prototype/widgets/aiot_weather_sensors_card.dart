import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import '../../aiot_dashboard_page.dart';
import 'student_redesign_palette.dart';

class AiotWeatherSensorsCard extends StatelessWidget {
  const AiotWeatherSensorsCard({super.key, this.height});

  final double? height;

  static ({String subtitle, String level}) _pm25Status(double v) {
    if (v <= 25) return (subtitle: 'สภาพอากาศดีมาก', level: 'ปกติ');
    if (v <= 50) return (subtitle: 'สภาพอากาศปานกลาง', level: 'ปกติ');
    return (subtitle: 'ฝุ่นสูง ควรระวัง', level: 'ไม่ปลอดภัย');
  }

  static ({String subtitle, String level}) _tempStatus(double v) {
    if (v >= 20 && v <= 30) return (subtitle: 'อุณหภูมิกำลังดี', level: 'ปกติ');
    return (subtitle: 'อุณหภูมิสูง/ต่ำกว่าปกติ', level: 'ไม่ปลอดภัย');
  }

  static ({String subtitle, String level}) _humidityStatus(double v) {
    if (v >= 40 && v <= 70) {
      return (subtitle: 'สภาพแวดล้อมเหมาะสม', level: 'ปกติ');
    }
    return (subtitle: 'ความชื้นสูง/ต่ำกว่าปกติ', level: 'ไม่ปลอดภัย');
  }

  static ({String subtitle, String level}) _luxStatus(double v) {
    if (v >= 300) return (subtitle: 'แสงสว่างเพียงพอสำหรับอ่านหนังสือ', level: 'ปกติ');
    if (v >= 150) return (subtitle: 'แสงสว่างพอใช้ อาจต้องเปิดไฟเพิ่ม', level: 'ปกติ');
    return (subtitle: 'แสงสว่างน้อยกว่ามาตรฐาน', level: 'ไม่ปลอดภัย');
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: SoftCard(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: SchoolPalette.green,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x662F8F5B),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'ข้อมูลเซนเซอร์สภาพอากาศ AIoT',
                    style: TextStyle(
                      color: SchoolPalette.ink,
                      fontSize: 17.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            StreamBuilder<SensorModel?>(
              stream: RealtimeService.sensorStream(
                schoolId: currentUserModel?.schoolId ?? '',
                building: '',
                floor: '',
                room: '',
              ),
              builder: (context, snapshot) {
                final sensor = snapshot.data;
                if (sensor == null || sensor.updatedAt == null) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'ยังไม่มีข้อมูลเซนเซอร์จากอุปกรณ์ในโรงเรียน',
                      style: TextStyle(
                        color: SchoolPalette.muted,
                        fontSize: 12.5,
                      ),
                    ),
                  );
                }
                final pm25 = _pm25Status(sensor.pm25);
                final temp = _tempStatus(sensor.temperature);
                final humidity = _humidityStatus(sensor.humidity);
                final lux = _luxStatus(sensor.lux);
                return Column(
                  children: [
                    AiotSensorItemTile(
                      icon: Icons.air_rounded,
                      title: 'ฝุ่น PM2.5 (เซนเซอร์ในโรงเรียน)',
                      value: sensor.pm25.toStringAsFixed(0),
                      unit: 'µg/m³',
                      subtitle: pm25.subtitle,
                      level: pm25.level,
                      freshness: sensor.freshnessOf('pm25'),
                      timeLabel: sensor.relativeTimeLabel('pm25'),
                      showDivider: true,
                    ),
                    AiotSensorItemTile(
                      icon: Icons.thermostat_rounded,
                      title: 'อุณหภูมิ (เซนเซอร์ในโรงเรียน)',
                      value: sensor.temperature.toStringAsFixed(1),
                      unit: '°C',
                      subtitle: temp.subtitle,
                      level: temp.level,
                      freshness: sensor.freshnessOf('temperature'),
                      timeLabel: sensor.relativeTimeLabel('temperature'),
                      showDivider: true,
                    ),
                    AiotSensorItemTile(
                      icon: Icons.water_drop_rounded,
                      title: 'ความชื้นสัมพัทธ์',
                      value: sensor.humidity.toStringAsFixed(0),
                      unit: '%RH',
                      subtitle: humidity.subtitle,
                      level: humidity.level,
                      freshness: sensor.freshnessOf('humidity'),
                      timeLabel: sensor.relativeTimeLabel('humidity'),
                      showDivider: true,
                    ),
                    AiotSensorItemTile(
                      icon: Icons.wb_sunny_rounded,
                      title: 'ความเข้มแสง',
                      value: sensor.lux.toStringAsFixed(0),
                      unit: 'lux',
                      subtitle: lux.subtitle,
                      level: lux.level,
                      freshness: sensor.freshnessOf('light_lux'),
                      timeLabel: sensor.relativeTimeLabel('light_lux'),
                      showDivider: false,
                    ),
                  ],
                );
              },
            ),
            if (height != null) const Spacer() else const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 32,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AiotDashboardPage(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 14,
                ),
                label: const Text(
                  'ไปหน้า AIoT Dashboard',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 28, 127, 70),
                  foregroundColor: Colors.white,
                  elevation: 1,
                  shadowColor: const Color.fromARGB(
                    255,
                    28,
                    127,
                    70,
                  ).withValues(alpha: 0.25),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AiotSensorItemTile extends StatelessWidget {
  const AiotSensorItemTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.level,
    this.value,
    this.unit,
    this.freshness = SensorFreshness.noData,
    this.timeLabel,
    this.showDivider = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String level;
  final String? value;
  final String? unit;
  final SensorFreshness freshness;
  final String? timeLabel;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 560;
        final isNormal = level == 'ปกติ';

        // สีไอคอนแยกตามชนิดเซนเซอร์ (เหมือนการ์ดฝั่งครู _AiotSensorRow)
        // แทนที่จะใช้สีเขียวเดียวทั้งหมดแบบเดิม
        Color iconBgColor;
        Color iconColor;
        if (icon == Icons.air_rounded) {
          iconBgColor = const Color(0xFFE0F2FE);
          iconColor = const Color(0xFF0284C7);
        } else if (icon == Icons.thermostat_rounded) {
          iconBgColor = const Color(0xFFFFF7ED);
          iconColor = const Color(0xFFEA580C);
        } else if (icon == Icons.water_drop_rounded) {
          iconBgColor = const Color(0xFFEFF6FF);
          iconColor = const Color(0xFF2563EB);
        } else {
          iconBgColor = const Color(0xFFFFF1F2);
          iconColor = const Color(0xFFE11D48);
        }

        final badgeBgColor = isNormal
            ? const Color(0xFFECFDF5)
            : const Color(0xFFFEF2F2);
        final badgeTextColor = isNormal
            ? const Color(0xFF059669)
            : const Color(0xFFDC2626);
        final badgeDotColor = isNormal
            ? const Color(0xFF10B981)
            : const Color(0xFFEF4444);
        final badgeBorderColor = isNormal
            ? const Color(0xFFA7F3D0).withValues(alpha: 0.6)
            : const Color(0xFFFECACA).withValues(alpha: 0.6);

        return Container(
          padding: EdgeInsets.only(
            top: isCompact ? 9 : 10,
            bottom: showDivider ? (isCompact ? 9 : 10) : 0,
          ),
          decoration: BoxDecoration(
            border: showDivider
                ? const Border(
                    bottom: BorderSide(color: Color(0xFFE8EEF3), width: 1),
                  )
                : null,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: isCompact ? 60 : 60),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: const Color(0xFF475569),
                          fontSize: isCompact ? 12.5 : 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (value != null) const SizedBox(height: 1),
                      if (value != null)
                        Text.rich(
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          TextSpan(
                            children: [
                              TextSpan(
                                text: value!,
                                style: TextStyle(
                                  color: iconColor,
                                  fontWeight: FontWeight.w900,
                                  fontSize: isCompact ? 16.5 : 17,
                                ),
                              ),
                              if (unit != null) ...[
                                const TextSpan(text: ' '),
                                TextSpan(
                                  text: unit!,
                                  style: TextStyle(
                                    color: iconColor.withValues(alpha: 0.8),
                                    fontWeight: FontWeight.w800,
                                    fontSize: isCompact ? 10.5 : 11,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: SchoolPalette.muted,
                          fontSize: isCompact ? 10.5 : 10.8,
                          fontWeight: FontWeight.w600,
                          height: 1.12,
                        ),
                      ),
                      if (timeLabel != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'อัปเดต $timeLabel',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: freshness.color,
                            fontSize: isCompact ? 9.5 : 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Badge เดียวต่อแถว: สด/ล่าช้าเล็กน้อย → โชว์ระดับความปลอดภัย
                // (ปกติ/ไม่ปลอดภัย); เซนเซอร์ไม่ทำงาน/ไม่มีข้อมูล → โชว์สถานะ
                // นั้นแทน ไม่โชว์ทั้งสองอันซ้อนกัน (จะขัดแย้งกันเอง)
                if (freshness == SensorFreshness.live ||
                    freshness == SensorFreshness.delayed)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: badgeBgColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: badgeBorderColor, width: 1.0),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: badgeDotColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: badgeDotColor.withValues(alpha: 0.35),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          level,
                          style: TextStyle(
                            color: badgeTextColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: freshness.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: freshness.color.withValues(alpha: 0.3),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: freshness.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          freshness.label,
                          style: TextStyle(
                            color: freshness.color,
                            fontWeight: FontWeight.w800,
                            fontSize: 9.5,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
