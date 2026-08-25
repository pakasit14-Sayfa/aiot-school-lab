import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/models/device_schedule_model.dart';

void main() {
  group('DeviceSchedule Model', () {
    test('parses fromRow properly with days and formatting', () {
      final row = {
        'id': '00000000-0000-0000-0000-000000000001',
        'device_id': '00000000-0000-0000-0000-000000000002',
        'device_name': 'แอร์ห้องเรียน 101',
        'device_location': 'อาคาร 1 ชั้น 1',
        'school_id': '00000000-0000-0000-0000-000000000003',
        'label': 'เปิดแอร์เช้าวันเรียน',
        'command': {'action': 'on'},
        'days_of_week': [1, 2, 3, 4, 5],
        'time_of_day': '08:00:00',
        'enabled': true,
        'created_by': '00000000-0000-0000-0000-000000000004',
        'created_at': '2026-08-25T08:00:00.000Z',
        'last_triggered_at': null,
      };

      final schedule = DeviceSchedule.fromRow(row);
      expect(schedule.id, '00000000-0000-0000-0000-000000000001');
      expect(schedule.deviceName, 'แอร์ห้องเรียน 101');
      expect(schedule.actionLabel, 'เปิดเครื่อง');
      expect(schedule.daysFormatted, 'จันทร์ - ศุกร์');
      expect(schedule.timeFormatted, '08:00 น.');
      expect(schedule.enabled, true);
    });

    test('formats custom days and off action', () {
      final row = {
        'id': '00000000-0000-0000-0000-000000000001',
        'device_id': '00000000-0000-0000-0000-000000000002',
        'device_name': 'ไฟทางเดิน',
        'device_location': 'อาคาร 1',
        'school_id': '00000000-0000-0000-0000-000000000003',
        'label': 'ปิดไฟกลางคืน',
        'command': {'action': 'off'},
        'days_of_week': [0, 6],
        'time_of_day': '22:30:00',
        'enabled': false,
        'created_by': '00000000-0000-0000-0000-000000000004',
        'created_at': '2026-08-25T08:00:00.000Z',
        'last_triggered_at': '2026-08-25T22:30:00.000Z',
      };

      final schedule = DeviceSchedule.fromRow(row);
      expect(schedule.actionLabel, 'ปิดเครื่อง');
      expect(schedule.daysFormatted, 'อา., ส.');
      expect(schedule.timeFormatted, '22:30 น.');
      expect(schedule.enabled, false);
      expect(schedule.lastTriggeredAt, isNotNull);
    });
  });
}
