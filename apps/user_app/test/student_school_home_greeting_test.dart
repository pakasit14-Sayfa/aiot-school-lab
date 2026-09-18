import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/student_redesign_prototype/widgets/student_variant_school_home.dart';

// Found on the first production login from the iOS simulator (2026-09-17
// 22:11): the student home hero said "สวัสดีตอนเช้า" at night while the login
// page — one tap earlier — correctly said "ตอนเย็น". The hero text was a
// string literal. This pins the buckets to the login page's.
void main() {
  test('greeting follows the hour with the login page buckets', () {
    expect(greetingForHour(0), 'สวัสดีตอนดึก');
    expect(greetingForHour(4), 'สวัสดีตอนดึก');
    expect(greetingForHour(5), 'สวัสดีตอนเช้า');
    expect(greetingForHour(11), 'สวัสดีตอนเช้า');
    expect(greetingForHour(12), 'สวัสดีตอนบ่าย');
    expect(greetingForHour(16), 'สวัสดีตอนบ่าย');
    expect(greetingForHour(17), 'สวัสดีตอนเย็น');
    expect(greetingForHour(22), 'สวัสดีตอนเย็น');
  });
}
