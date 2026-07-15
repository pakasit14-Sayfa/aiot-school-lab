import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

class SensorCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final SensorLevel level;
  final VoidCallback? onTap;

  const SensorCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.level,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = level.color;
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
                    child: Text(label,
                        style:
                            const TextStyle(fontSize: 13, color: Colors.grey)),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      level.label,
                      style: TextStyle(
                          fontSize: 11,
                          color: color,
                          fontWeight: FontWeight.bold),
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
                    child: Text(unit,
                        style:
                            const TextStyle(fontSize: 13, color: Colors.grey)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SensorGrid extends StatelessWidget {
  final SensorModel sensor;

  const SensorGrid({super.key, required this.sensor});

  @override
  Widget build(BuildContext context) {
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
          value: sensor.pm25.toStringAsFixed(1),
          unit: 'µg/m³',
          icon: Icons.blur_on,
          level: sensor.pm25Level,
        ),
        SensorCard(
          label: 'CO₂',
          value: sensor.co2.toStringAsFixed(0),
          unit: 'ppm',
          icon: Icons.co2,
          level: sensor.co2Level,
        ),
        SensorCard(
          label: 'อุณหภูมิ',
          value: sensor.temperature.toStringAsFixed(1),
          unit: '°C',
          icon: Icons.thermostat,
          level: sensor.tempLevel,
        ),
        SensorCard(
          label: 'ความชื้น',
          value: sensor.humidity.toStringAsFixed(0),
          unit: '%',
          icon: Icons.water_drop,
          level: sensor.humidityLevel,
        ),
        SensorCard(
          label: 'TVOC',
          value: sensor.tvoc.toStringAsFixed(2),
          unit: 'mg/m³',
          icon: Icons.science,
          level: sensor.tvocLevel,
        ),
        SensorCard(
          label: 'แสงสว่าง',
          value: sensor.lux.toStringAsFixed(0),
          unit: 'lux',
          icon: Icons.light_mode,
          level: sensor.luxLevel,
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
            colors: [color, color.withOpacity(0.7)],
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
                  const Text('สภาพแวดล้อมโดยรวม',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
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
                      style: const TextStyle(color: Colors.white60, fontSize: 11),
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
              const Text('ยังไม่มีข้อมูลจากเซ็นเซอร์',
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 4),
              const Text('ตรวจสอบการเชื่อมต่อ EdgeBox',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}
