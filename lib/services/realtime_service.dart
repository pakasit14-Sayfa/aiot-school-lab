import 'package:firebase_database/firebase_database.dart';
import '../models/sensor_model.dart';

class RealtimeService {
  static final _db = FirebaseDatabase.instance;

  // path: /schools/{schoolId}/facilities/{building}/{floor}/{room}/sensors
  static String _sensorPath(String schoolId, String building, String floor, String room) =>
      'schools/$schoolId/facilities/$building/$floor/$room/sensors';

  static String _switchPath(String schoolId, String building, String floor, String room) =>
      'schools/$schoolId/facilities/$building/$floor/$room/switches';

  // Stream ข้อมูลเซ็นเซอร์ห้องเดียว
  static Stream<SensorModel?> sensorStream({
    required String schoolId,
    required String building,
    required String floor,
    required String room,
  }) {
    final path = _sensorPath(schoolId, building, floor, room);
    return _db.ref(path).onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return null;
      return SensorModel.fromMap(data as Map<dynamic, dynamic>);
    });
  }

  // อ่านค่าเซ็นเซอร์ครั้งเดียว
  static Future<SensorModel?> getSensorOnce({
    required String schoolId,
    required String building,
    required String floor,
    required String room,
  }) async {
    final path = _sensorPath(schoolId, building, floor, room);
    final snapshot = await _db.ref(path).get();
    if (!snapshot.exists || snapshot.value == null) return null;
    return SensorModel.fromMap(snapshot.value as Map<dynamic, dynamic>);
  }

  // Stream สถานะสวิตช์ (ไฟ/น้ำ)
  static Stream<Map<String, bool>> switchStream({
    required String schoolId,
    required String building,
    required String floor,
    required String room,
  }) {
    final path = _switchPath(schoolId, building, floor, room);
    return _db.ref(path).onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return <String, bool>{};
      final map = data as Map<dynamic, dynamic>;
      return map.map((k, v) => MapEntry(k.toString(), v == true));
    });
  }

  // สั่งเปิด/ปิดอุปกรณ์ (Phase 4)
  static Future<void> setSwitch({
    required String schoolId,
    required String building,
    required String floor,
    required String room,
    required String device,
    required bool value,
  }) async {
    final path = '${_switchPath(schoolId, building, floor, room)}/$device';
    await _db.ref(path).set(value);
  }

  // Stream ทุกห้องในอาคาร (สำหรับ Building Admin)
  static Stream<Map<String, SensorModel>> buildingSensorStream({
    required String schoolId,
    required String building,
  }) {
    final path = 'schools/$schoolId/facilities/$building';
    return _db.ref(path).onValue.map((event) {
      final result = <String, SensorModel>{};
      final data = event.snapshot.value;
      if (data == null) return result;

      final floors = data as Map<dynamic, dynamic>;
      floors.forEach((floor, rooms) {
        if (rooms is Map) {
          rooms.forEach((room, roomData) {
            if (roomData is Map && roomData['sensors'] != null) {
              final key = '$floor/$room';
              result[key] = SensorModel.fromMap(
                  roomData['sensors'] as Map<dynamic, dynamic>);
            }
          });
        }
      });
      return result;
    });
  }

  // เปิด offline persistence
  static void enableOffline() {
    _db.setPersistenceEnabled(true);
    _db.setPersistenceCacheSizeBytes(10 * 1024 * 1024); // 10MB
  }
}
