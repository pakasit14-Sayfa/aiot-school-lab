import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_core/shared_core.dart';

/// PBL-8: turn a window of real readings into a CSV the teacher can open
/// in Excel/Sheets. Metadata lines first, then the data. Every number in
/// the file comes from `points` — nothing is computed except min/avg/max
/// over those same points. UTF-8 with BOM so Thai headers open correctly
/// in Excel.
Uint8List buildSensorCsv({
  required String deviceName,
  required String metricName,
  required String unit,
  required DateTime from,
  required DateTime to,
  required List<SensorDataPoint> points,
  String? note,
}) {
  String f(DateTime d) {
    final l = d.toLocal();
    return '${l.year}-${l.month.toString().padLeft(2, '0')}-${l.day.toString().padLeft(2, '0')} '
        '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}:${l.second.toString().padLeft(2, '0')}';
  }

  String cell(String v) => '"${v.replaceAll('"', '""')}"';
  final b = StringBuffer();
  b.writeln('${cell('อุปกรณ์')},${cell(deviceName)}');
  b.writeln('${cell('ค่าที่วัด')},${cell('$metricName ($unit)')}');
  b.writeln('${cell('ช่วงเวลา')},${cell('${f(from)} – ${f(to)}')}');
  b.writeln('${cell('จำนวนจุดข้อมูล')},${points.length}');
  if (points.isNotEmpty) {
    final values = points.map((p) => p.value).toList();
    final min = values.reduce((a, c) => a < c ? a : c);
    final max = values.reduce((a, c) => a > c ? a : c);
    final avg = values.reduce((a, c) => a + c) / values.length;
    b.writeln('${cell('ต่ำสุด')},${min.toStringAsFixed(2)}');
    b.writeln('${cell('เฉลี่ย')},${avg.toStringAsFixed(2)}');
    b.writeln('${cell('สูงสุด')},${max.toStringAsFixed(2)}');
  }
  if ((note ?? '').trim().isNotEmpty) {
    b.writeln('${cell('บันทึกของนักเรียน')},${cell(note!.trim())}');
  }
  b.writeln();
  b.writeln('${cell('เวลา')},${cell('ค่า ($unit)')}');
  for (final p in points) {
    b.writeln('${cell(f(p.ts))},${p.value}');
  }
  return Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(b.toString())]);
}

/// File name the teacher will see in the attachment list.
String sensorCsvFileName({required String metricName, required DateTime from}) {
  final l = from.toLocal();
  final safe = metricName.replaceAll(RegExp(r'[\\/:*?"<>|\s]+'), '-');
  return 'เซนเซอร์-$safe-${l.day}-${l.month}-${l.year + 543}.csv';
}
