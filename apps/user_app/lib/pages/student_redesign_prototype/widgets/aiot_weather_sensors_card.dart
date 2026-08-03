import 'package:flutter/material.dart';
import '../../aiot_dashboard_page.dart';
import 'student_redesign_palette.dart';

class AiotWeatherSensorsCard extends StatelessWidget {
  const AiotWeatherSensorsCard({super.key, this.height});

  final double? height;

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
                        color: Color(0x6643AC60),
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: SchoolPalette.green,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x3343AC60),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Text(
                    'LIVE ⚡',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 10.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const AiotSensorItemTile(
              icon: Icons.air_rounded,
              title: 'ฝุ่น PM2.5 (ห้องเรียนปลอดภัย)',
              value: '18',
              unit: 'µg/m³',
              subtitle: 'สภาพอากาศดีมาก',
              level: 'ดีมาก',
              color: Color(0xFF0284C7),
              showDivider: true,
            ),
            const AiotSensorItemTile(
              icon: Icons.thermostat_rounded,
              title: 'อุณหภูมิห้องเรียน',
              value: '28.5',
              unit: '°C',
              subtitle: 'อบอุ่นกำลังดี',
              level: 'เหมาะสม',
              color: Color(0xFFEA580C),
              showDivider: true,
            ),
            const AiotSensorItemTile(
              icon: Icons.water_drop_rounded,
              title: 'ความชื้นสัมพัทธ์',
              value: '62',
              unit: '%RH',
              subtitle: 'สภาพแวดล้อมเหมาะสม',
              level: 'ปกติ',
              color: Color(0xFF059669),
              showDivider: true,
            ),
            const AiotSensorItemTile(
              icon: Icons.wb_sunny_rounded,
              title: 'ดัชนีรังสี UV',
              value: 'UV 2',
              subtitle: 'ระดับปลอดภัย',
              level: 'ปลอดภัย',
              color: Color(0xFFD97706),
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
                  backgroundColor: SchoolPalette.green,
                  foregroundColor: Colors.white,
                  elevation: 1,
                  shadowColor: SchoolPalette.green.withValues(alpha: 0.25),
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
    required this.color,
    this.value,
    this.unit,
    this.showDivider = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String level;
  final Color color;
  final String? value;
  final String? unit;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 560;

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
                  width: isCompact ? 42 : 40,
                  height: isCompact ? 42 : 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: isCompact ? 22 : 23),
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
                                  color: color,
                                  fontWeight: FontWeight.w900,
                                  fontSize: isCompact ? 16.5 : 17,
                                ),
                              ),
                              if (unit != null) ...[
                                const TextSpan(text: ' '),
                                TextSpan(
                                  text: unit!,
                                  style: TextStyle(
                                    color: color,
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
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    level,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontSize: isCompact ? 10 : 10.5,
                    ),
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
