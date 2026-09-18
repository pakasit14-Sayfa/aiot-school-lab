/// Time-of-day greeting shared by the login page and the Student home hero
/// so the two screens never disagree.
///
/// Buckets (2026-09-18, after the owner saw "สวัสดีตอนเช้า" at 22:11 and
/// again at 00:52): 0–4 ดึก · 5–11 เช้า · 12–16 บ่าย · 17–23 เย็น.
String greetingForHour(int hour) {
  if (hour < 5) return 'สวัสดีตอนดึก';
  if (hour < 12) return 'สวัสดีตอนเช้า';
  if (hour < 17) return 'สวัสดีตอนบ่าย';
  return 'สวัสดีตอนเย็น';
}
