import 'dart:async';
import '../models/sensor_model.dart';

class RealtimeService {
  static final SensorModel _mockSensor = SensorModel(
    updatedAt: DateTime.now(),
    temperature: 25.0,
    humidity: 60.0,
    pm25: 10.0,
    co2: 400.0,
    tvoc: 0.1,
    lux: 300.0,
  );

  static Stream<SensorModel?> sensorStream({
    required String schoolId,
    required String building,
    required String floor,
    required String room,
  }) {
    return Stream.periodic(const Duration(seconds: 5), (count) => _mockSensor);
  }

  static Future<SensorModel?> getSensorOnce({
    required String schoolId,
    required String building,
    required String floor,
    required String room,
  }) async {
    return _mockSensor;
  }

  static Stream<Map<String, bool>> switchStream({
    required String schoolId,
    required String building,
    required String floor,
    required String room,
  }) {
    return Stream.value({'light': true, 'water': false});
  }

  static Future<void> setSwitch({
    required String schoolId,
    required String building,
    required String floor,
    required String room,
    required String device,
    required bool value,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  static Stream<Map<String, SensorModel>> buildingSensorStream({
    required String schoolId,
    required String building,
  }) {
    return Stream.value({
      '1/101': _mockSensor,
      '1/102': _mockSensor,
    });
  }

  static void enableOffline() {
    // No-op for mock
  }
}
