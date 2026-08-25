import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/models/incident_model.dart';

void main() {
  group('SchoolSensorAlertRecord', () {
    test('parses fromRow correctly with full fields', () {
      final row = {
        'id': 'alert-123',
        'device_id': 'dev-456',
        'device_name': 'PM2.5 Sensor',
        'device_code': 'DEV-PM-001',
        'school_id': 'school-789',
        'threshold_id': 'thresh-001',
        'metric': 'pm25',
        'value': 75.5,
        'triggered_at': '2026-08-25T10:00:00Z',
        'status': 'new',
        'acknowledged_by': null,
        'acknowledged_by_name': null,
        'acknowledged_at': null,
      };

      final record = SchoolSensorAlertRecord.fromRow(row);
      expect(record.id, 'alert-123');
      expect(record.deviceId, 'dev-456');
      expect(record.deviceName, 'PM2.5 Sensor');
      expect(record.deviceCode, 'DEV-PM-001');
      expect(record.schoolId, 'school-789');
      expect(record.thresholdId, 'thresh-001');
      expect(record.metric, 'pm25');
      expect(record.value, 75.5);
      expect(record.status, 'new');
      expect(record.isNew, isTrue);
      expect(record.isAcknowledged, isFalse);
      expect(record.isResolved, isFalse);
    });

    test('parses fromRow with acknowledged status and null fallback values', () {
      final row = {
        'id': 'alert-999',
        'device_id': 'dev-999',
        'school_id': 'school-789',
        'value': 120,
        'status': 'acknowledged',
        'acknowledged_by': 'user-111',
        'acknowledged_by_name': 'สมชาย ใจดี',
        'acknowledged_at': '2026-08-25T10:30:00Z',
      };

      final record = SchoolSensorAlertRecord.fromRow(row);
      expect(record.id, 'alert-999');
      expect(record.deviceName, 'Unknown Device');
      expect(record.deviceCode, 'DEV-UNKNOWN');
      expect(record.metric, 'unknown');
      expect(record.value, 120.0);
      expect(record.isAcknowledged, isTrue);
      expect(record.acknowledgedByName, 'สมชาย ใจดี');
      expect(record.acknowledgedAt, isNotNull);
    });
  });
}
