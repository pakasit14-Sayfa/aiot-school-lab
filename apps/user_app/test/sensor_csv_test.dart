import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/utils/sensor_csv.dart';
import 'package:shared_core/shared_core.dart';

/// PBL-8: the CSV carries exactly the readings it was given, plus
/// min/avg/max computed from them, in a form Excel opens (UTF-8 BOM).
void main() {
  test('buildSensorCsv writes metadata, stats and every reading', () {
    final bytes = buildSensorCsv(
      deviceName: 'ฝุ่นหน้าห้อง',
      metricName: 'ฝุ่น PM2.5',
      unit: 'µg/m³',
      from: DateTime.utc(2026, 9, 10, 1),
      to: DateTime.utc(2026, 9, 10, 3),
      points: [
        SensorDataPoint(ts: DateTime.utc(2026, 9, 10, 1), value: 20),
        SensorDataPoint(ts: DateTime.utc(2026, 9, 10, 2), value: 35.5),
        SensorDataPoint(ts: DateTime.utc(2026, 9, 10, 3), value: 30),
      ],
      note: 'ฝุ่นขึ้นตอนเช้า',
    );
    expect(bytes.sublist(0, 3), [0xEF, 0xBB, 0xBF]);
    final text = utf8.decode(bytes.sublist(3));
    final lines = const LineSplitter().convert(text);
    expect(lines[0], '"อุปกรณ์","ฝุ่นหน้าห้อง"');
    expect(lines[1], '"ค่าที่วัด","ฝุ่น PM2.5 (µg/m³)"');
    expect(lines[3], '"จำนวนจุดข้อมูล",3');
    expect(lines[4], '"ต่ำสุด",20.00');
    expect(lines[5], '"เฉลี่ย",28.50');
    expect(lines[6], '"สูงสุด",35.50');
    expect(lines[7], '"บันทึกของนักเรียน","ฝุ่นขึ้นตอนเช้า"');
    expect(lines[9], '"เวลา","ค่า (µg/m³)"');
    // three data rows, values verbatim
    expect(lines.length, 13);
    expect(lines[10], endsWith(',20.0'));
    expect(lines[11], endsWith(',35.5'));
    expect(lines[12], endsWith(',30.0'));
  });

  test('a quote inside a note is escaped, never breaks the row', () {
    final bytes = buildSensorCsv(
      deviceName: 'd',
      metricName: 'm',
      unit: 'u',
      from: DateTime.utc(2026, 9, 10),
      to: DateTime.utc(2026, 9, 11),
      points: const [],
      note: 'he said "hi"',
    );
    final text = utf8.decode(bytes.sublist(3));
    expect(text, contains('"บันทึกของนักเรียน","he said ""hi"""'));
    expect(text, isNot(contains('ต่ำสุด'))); // no stats without readings
  });

  test('file name is Thai-readable and filesystem-safe', () {
    final name = sensorCsvFileName(
      metricName: 'ฝุ่น PM2.5 / ห้อง:1',
      from: DateTime(2026, 9, 10, 8),
    );
    expect(name, 'เซนเซอร์-ฝุ่น-PM2.5-ห้อง-1-10-9-2569.csv');
  });
}
