import 'package:flutter/foundation.dart';
import 'package:shared_core/shared_core.dart';

class DirectorOverviewData {
  const DirectorOverviewData({
    required this.counts,
    required this.devices,
    required this.incidents,
    required this.tracks,
    required this.notices,
    required this.energy,
    required this.water,
    required this.studentAttendance,
    required this.staffAttendance,
    required this.subjectGroups,
  });
  final Map<String, int> counts;
  final List<DeviceOption> devices;
  final List<IncidentSummaryItem> incidents;
  final List<LearningTrackOverview> tracks;
  final List<AppNotification> notices;
  final List<UtilityTrendPoint> energy, water;

  /// สัดส่วนครูตามกลุ่มสาระจริงจากระบบ (`list_departments` kind=subject_group)
  /// — แทนที่กราฟฟองสบู่ "สอนตารางปกติ/กิจกรรม/สอนแทน/เตรียมสอน" เวอร์ชัน 7 ก.ย.
  /// ที่เป็นตัวเลขแต่งขึ้น (ไม่มีคอลัมน์จำแนกประเภทคาบสอนในระบบเลย)
  final List<SchoolDepartment> subjectGroups;

  /// การเข้าเรียนของนักเรียนรายห้อง และการมาปฏิบัติหน้าที่ของครู "ของวันนี้"
  /// — 2 บล็อกนี้เคยอยู่บนหน้าภาพรวมเวอร์ชัน 7 ก.ย. แต่เป็นตัวเลขที่แต่งขึ้น
  /// (ติดป้าย "ข้อมูลจำลอง") เลยถูกรื้อออกตอนล้างข้อมูลปลอม ตอนนี้มี RPC จริง
  /// รองรับทั้งคู่แล้ว จึงเอากลับมาได้โดยไม่ต้องแต่งตัวเลข
  final List<SchoolHomeroomAttendance> studentAttendance;
  final StaffAttendanceSummary? staffAttendance;
  bool get isEmpty =>
      counts.values.every((n) => n == 0) &&
      devices.isEmpty &&
      incidents.isEmpty &&
      tracks.isEmpty &&
      notices.isEmpty &&
      energy.isEmpty &&
      water.isEmpty &&
      studentAttendance.isEmpty &&
      staffAttendance == null &&
      subjectGroups.isEmpty;
}

class DirectorOverviewController extends ChangeNotifier {
  DirectorOverviewController({this.loader});
  final Future<DirectorOverviewData> Function(int days)? loader;
  DirectorOverviewData? data;
  DateTime? loadedAt;
  bool loading = true, _disposed = false;
  String? error;
  int days = 7, _generation = 0;

  static Future<DirectorOverviewData> fetch(int days) async {
    if (AuthService.sessionToken == null) throw StateError('not_signed_in');
    final r = await Future.wait<Object?>([
      UserAdminService.countUsersByRole(),
      LessonService.listSchoolDevices(),
      IncidentService.getIncidentSummary(),
      LearningTrackService.getOverview(),
      NotificationService.listMyNotifications(),
      UtilityService.getEnergyUsageTrend(days: days),
      UtilityService.getWaterUsageTrend(days: days),
      // ทั้งคู่เป็นข้อมูล "วันนี้" ไม่ผูกกับช่วงเวลาที่เลือกด้านบน (RPC รับ
      // วันเดียว) — ป้ายบนการ์ดจึงต้องบอกวันที่ให้ชัด ไม่ใช่ปล่อยให้เข้าใจว่า
      // เป็นยอดรวมของทั้งสัปดาห์/เดือนตามตัวเลือกที่เลือกอยู่
      HomeroomService.listSchoolAttendance(DateTime.now()),
      StaffAttendanceService.getSummary(),
      StaffOrgService.listDepartments(kind: 'subject_group'),
    ]);
    return DirectorOverviewData(
      counts: r[0] as Map<String, int>,
      devices: r[1] as List<DeviceOption>,
      incidents: r[2] as List<IncidentSummaryItem>,
      tracks: r[3] as List<LearningTrackOverview>,
      notices: r[4] as List<AppNotification>,
      energy: r[5] as List<UtilityTrendPoint>,
      water: r[6] as List<UtilityTrendPoint>,
      studentAttendance: r[7] as List<SchoolHomeroomAttendance>,
      staffAttendance: r[8] as StaffAttendanceSummary?,
      subjectGroups: r[9] as List<SchoolDepartment>,
    );
  }

  Future<void> load({int? period}) async {
    days = period ?? days;
    final generation = ++_generation;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final result = await (loader ?? fetch)(days);
      if (_disposed || generation != _generation) return;
      data = result;
      loadedAt = DateTime.now();
    } catch (_) {
      if (_disposed || generation != _generation) return;
      data = null;
      error = 'โหลดภาพรวมไม่สำเร็จ กรุณาลองอีกครั้ง';
    }
    loading = false;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
