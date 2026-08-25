import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/shared_core.dart';

void main() {
  group('SchoolBuildingModel Tests', () {
    test('SchoolBuildingRecord parses fromRow correctly', () {
      final row = {
        'id': 'bld-1',
        'school_id': 'sch-1',
        'name': 'อาคารเรียน A',
        'code': 'BLD-A',
        'floors': 3,
        'rooms_count': 12,
        'manager_name': 'นายวิชาญ แก้วคำ',
        'devices_count': 46,
        'training_kits_count': 6,
        'status': 'active',
        'note': 'อาคารเรียนหลัก',
      };

      final bld = SchoolBuildingRecord.fromRow(row);
      expect(bld.id, 'bld-1');
      expect(bld.name, 'อาคารเรียน A');
      expect(bld.floors, 3);
      expect(bld.roomsCount, 12);
      expect(bld.devicesCount, 46);
      expect(bld.trainingKitsCount, 6);
    });

    test('SchoolRoomRecord parses fromRow correctly', () {
      final row = {
        'id': 'room-1',
        'school_id': 'sch-1',
        'building_id': 'bld-1',
        'building_name': 'อาคารเรียน A',
        'name': 'ห้องเรียน 101',
        'code': 'A-101',
        'floor': 'ชั้น 1',
        'room_type': 'ห้องเรียน',
        'capacity': 40,
        'teacher_name': 'นางสาวอรทัย วัฒนชัย',
        'devices_count': 5,
        'training_kits_count': 1,
        'status': 'active',
        'resource_status': 'ปกติ',
      };

      final room = SchoolRoomRecord.fromRow(row);
      expect(room.id, 'room-1');
      expect(room.buildingName, 'อาคารเรียน A');
      expect(room.name, 'ห้องเรียน 101');
      expect(room.capacity, 40);
      expect(room.teacherName, 'นางสาวอรทัย วัฒนชัย');
    });

    test('SchoolAdminDashboardSummary parses from JSON correctly', () {
      final json = {
        'school_id': 'sch-1',
        'school_name': 'โรงเรียนตัวอย่าง',
        'school_code': 'SCH-0001',
        'students_count': 500,
        'teachers_count': 40,
        'devices_count': 100,
        'devices_online': 95,
        'buildings_count': 4,
        'rooms_count': 30,
        'open_alerts_count': 2,
      };

      final summary = SchoolAdminDashboardSummary.fromJson(json);
      expect(summary.schoolName, 'โรงเรียนตัวอย่าง');
      expect(summary.studentsCount, 500);
      expect(summary.devicesOnline, 95);
      expect(summary.openAlertsCount, 2);
    });
  });
}
