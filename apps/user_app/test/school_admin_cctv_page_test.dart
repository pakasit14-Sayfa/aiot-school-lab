import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/shared_core.dart';

void main() {
  test('CameraAccessGrantItem correctly reflects isActive from row', () {
    final activeRow = {
      'grant_id': '00000000-0000-0000-0000-000000000001',
      'camera_name': 'ทางเข้าโรงเรียน',
      'location': 'ประตู 1',
      'building': 'อาคาร 1',
      'room': '101',
      'user_id': '00000000-0000-0000-0000-000000000002',
      'user_name': 'นายสมชาย ครูประจำชั้น',
      'user_email': 'somchai@school.local',
      'user_role': 'teacher',
      'reason': 'ดูแลความปลอดภัย',
      'valid_from': '2026-08-20T00:00:00.000Z',
      'valid_until': '2030-08-30T00:00:00.000Z',
      'granted_at': '2026-08-20T00:00:00.000Z',
      'granted_by_name': 'แอดมิน',
      'is_active': true,
    };

    final revokedRow = {
      'grant_id': '00000000-0000-0000-0000-000000000003',
      'camera_name': 'ทางเข้าโรงเรียน',
      'location': 'ประตู 1',
      'building': 'อาคาร 1',
      'room': '101',
      'user_id': '00000000-0000-0000-0000-000000000004',
      'user_name': 'นายสมศักดิ์ บุคลากรภายนอก',
      'user_email': 'somsak@school.local',
      'user_role': 'staff',
      'reason': 'ซ่อมบำรุงระบบ',
      'valid_from': '2026-08-20T00:00:00.000Z',
      'valid_until': '2030-08-30T00:00:00.000Z',
      'granted_at': '2026-08-20T00:00:00.000Z',
      'granted_by_name': 'แอดมิน',
      'is_active': false, // revoked
    };

    final activeGrant = CameraAccessGrantItem.fromRow(activeRow);
    final revokedGrant = CameraAccessGrantItem.fromRow(revokedRow);

    expect(activeGrant.isActive, isTrue);
    expect(revokedGrant.isActive, isFalse);
    expect(revokedGrant.validUntil, DateTime.utc(2030, 8, 30));
  });
}
