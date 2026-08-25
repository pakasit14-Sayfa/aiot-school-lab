import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/models/super_admin_model.dart';

void main() {
  group('SchoolPlatformRecord.fromJson', () {
    test('parses school record correctly with calculated license days', () {
      final now = DateTime.now();
      final futureDate = now.add(const Duration(days: 45));

      final school = SchoolPlatformRecord.fromJson({
        'id': '3aa16a57-5c39-4327-acf2-53c5d9a57599',
        'school_code': 'SCH-202608-0001',
        'name': 'โรงเรียนสาธิต AIoT',
        'province': 'กรุงเทพมหานคร',
        'admin_email': 'admin@satit.local',
        'package_name': 'Enterprise',
        'status': 'active',
        'max_users': 500,
        'max_devices': 300,
        'users_count': 120,
        'devices_total': 40,
        'devices_online': 35,
        'buildings_count': 3,
        'rooms_count': 15,
        'alerts_count': 1,
        'license_expires_at': futureDate.toIso8601String(),
        'last_sync_at': now.toIso8601String(),
      });

      expect(school.id, '3aa16a57-5c39-4327-acf2-53c5d9a57599');
      expect(school.schoolCode, 'SCH-202608-0001');
      expect(school.name, 'โรงเรียนสาธิต AIoT');
      expect(school.status, 'active');
      expect(school.usersCount, 120);
      expect(school.devicesOnline, 35);
      expect(school.devicesTotal, 40);
      expect(school.buildingsCount, 3);
      expect(school.roomsCount, 15);
      expect(school.alertsCount, 1);
      expect(school.licenseDaysLeft, inInclusiveRange(44, 46));
    });

    test('handles fallback defaults on missing fields', () {
      final school = SchoolPlatformRecord.fromJson({});
      expect(school.schoolCode, '-');
      expect(school.packageName, 'Basic');
      expect(school.status, 'active');
      expect(school.maxUsers, 100);
      expect(school.usersCount, 0);
      expect(school.licenseDaysLeft, 365);
    });
  });

  group('DeviceControlDataModel.fromJson', () {
    test('parses full device control payload', () {
      final data = DeviceControlDataModel.fromJson({
        'schools': [
          {
            'database_id': 'sch-1',
            'school_code': 'SCH-01',
            'name': 'โรงเรียน A',
            'province': 'กทม.',
            'package_name': 'Standard',
            'status': 'active',
            'total_devices': 10,
            'online_devices': 8,
            'open_alerts': 0,
          }
        ],
        'devices': [
          {
            'database_id': 'dev-1',
            'school_id': 'sch-1',
            'school_name': 'โรงเรียน A',
            'category_code': 'RLY',
            'device_code': 'RLY-01',
            'name': 'สวิตช์ไฟหลัก',
            'building': 'อาคาร 1',
            'room': 'ห้อง 101',
            'status': 'online',
            'online': true,
            'metadata': {'power': true, 'mode': 'auto'},
          }
        ],
        'commands': [],
        'approvals': [
          {
            'id': 'app-1',
            'school_id': 'sch-1',
            'school_name': 'โรงเรียน A',
            'device_id': 'dev-1',
            'device_name': 'สวิตช์ไฟหลัก',
            'command': 'power_off',
            'requested_by': 'usr-1',
            'requester_name': 'สมชาย',
            'status': 'pending',
            'notes': 'ปิดระบบประจำวัน',
          }
        ],
        'permissions': [
          {
            'email': 'admin@sch1.local',
            'full_name': 'แอดมิน สมบัติ',
            'role': 'school_admin',
            'school_name': 'โรงเรียน A',
          }
        ],
        'logs': [
          {
            'id': 'log-1',
            'device_id': 'dev-1',
            'school_id': 'sch-1',
            'event_type': 'command_queued',
            'message': 'ส่งคำสั่ง power_off สำเร็จ',
          }
        ],
        'current_user_id': 'user-super-1',
        'current_role': 'super_admin',
      });

      expect(data.schools.length, 1);
      expect(data.schools.first.name, 'โรงเรียน A');
      expect(data.devices.length, 1);
      expect(data.devices.first.isPoweredOn, isTrue);
      expect(data.devices.first.controlMode, 'auto');
      expect(data.approvals.length, 1);
      expect(data.approvals.first.status, 'pending');
      expect(data.approvals.first.requesterName, 'สมชาย');
      expect(data.permissions.length, 1);
      expect(data.logs.length, 1);
      expect(data.currentRole, 'super_admin');
    });
  });
}
