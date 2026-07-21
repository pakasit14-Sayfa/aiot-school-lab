import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/services/realtime_service.dart';

Map<String, dynamic> row(
  String metric,
  num value, {
  String location = 'อาคาร 1/101',
  String device = 'd1',
  String ts = '2026-07-20T09:00:00+00:00',
}) {
  return {
    'device_id': device,
    'device_name': 'เซนเซอร์ $device',
    'location': location,
    'metric': metric,
    'ts': ts,
    'value': value,
  };
}

void main() {
  group('modelForRoom', () {
    test('maps metrics onto SensorModel fields', () {
      final model = RealtimeService.modelForRoom([
        row('temperature', 28.4),
        row('humidity', 61.2),
        row('pm25', 12),
        row('light_lux', 350),
      ], '101');

      expect(model, isNotNull);
      expect(model!.temperature, 28.4);
      expect(model.humidity, 61.2);
      expect(model.pm25, 12);
      expect(model.lux, 350);
      expect(model.updatedAt, DateTime.parse('2026-07-20T09:00:00+00:00'));
    });

    test('prefers devices whose location matches the room', () {
      final model = RealtimeService.modelForRoom([
        row('temperature', 25, location: 'อาคาร 1/101'),
        row('temperature', 33, location: 'อาคาร 2/205', device: 'd2'),
      ], '205');
      expect(model!.temperature, 33);
    });

    test('falls back to all devices when no location matches', () {
      final model = RealtimeService.modelForRoom(
        [row('temperature', 25)],
        'ห้องที่ไม่มีจริง',
      );
      expect(model!.temperature, 25);
    });

    test('returns null when there are no readings', () {
      expect(RealtimeService.modelForRoom([], '101'), isNull);
    });

    test('keeps the newest value when two devices report the same metric', () {
      final model = RealtimeService.modelForRoom([
        row('temperature', 25, ts: '2026-07-20T08:00:00+00:00'),
        row('temperature', 29, device: 'd2', ts: '2026-07-20T09:30:00+00:00'),
      ], '');
      expect(model!.temperature, 29);
      expect(model.updatedAt, DateTime.parse('2026-07-20T09:30:00+00:00'));
    });
  });

  group('modelsByDevice', () {
    test('groups readings per device location', () {
      final models = RealtimeService.modelsByDevice([
        row('temperature', 28, location: '1/101'),
        row('humidity', 60, location: '1/101'),
        row('temperature', 30, location: '1/102', device: 'd2'),
      ], '');

      expect(models.keys, containsAll(['1/101', '1/102']));
      expect(models['1/101']!.humidity, 60);
      expect(models['1/102']!.temperature, 30);
    });

    test('uses device name when location is empty', () {
      final models = RealtimeService.modelsByDevice(
        [row('temperature', 28, location: '')],
        '',
      );
      expect(models.keys.single, 'เซนเซอร์ d1');
    });
  });
}
