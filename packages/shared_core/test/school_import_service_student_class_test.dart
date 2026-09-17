import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/services/school_import_service.dart';

/// 2026-09-17: student rows carry grade_level/room to the import RPC, which
/// writes student_profiles. "ห้องเรียน" in the template is "ม.1/1".
void main() {
  test('"ม.1/1" in ห้องเรียน becomes grade_level ม.1 + room 1', () {
    final rows = SchoolImportService.validateRows('นักเรียน', [
      {'รหัสนักเรียน': 'S1', 'ชื่อ-สกุล': 'ก ข', 'อีเมล': 'a@x.th', 'ห้องเรียน': 'ม.1/1'},
    ]);
    expect(rows.single.payload['grade_level'], 'ม.1');
    expect(rows.single.payload['room'], '1');
    expect(rows.single.detail, 'ม.1/1');
  });

  test('a separate ระดับชั้น column wins over splitting', () {
    final rows = SchoolImportService.validateRows('นักเรียน', [
      {'ชื่อ-สกุล': 'ก ข', 'ระดับชั้น': 'ป.6', 'ห้องเรียน': '2'},
    ]);
    expect(rows.single.payload['grade_level'], 'ป.6');
    expect(rows.single.payload['room'], '2');
  });

  test('teacher rows never carry grade_level/room', () {
    final rows = SchoolImportService.validateRows('ครูและบุคลากร', [
      {'ชื่อ-สกุล': 'ครู ก', 'ห้องเรียน': 'ม.1/1'},
    ]);
    expect(rows.single.payload.containsKey('grade_level'), isFalse);
  });
}
