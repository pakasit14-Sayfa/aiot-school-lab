import 'package:flutter/foundation.dart';
import 'package:shared_core/models/meeting_model.dart';
import 'package:shared_core/services/meeting_service.dart';
import 'package:shared_core/models/staff_org_model.dart';
import 'package:shared_core/models/staff_request_model.dart';
import 'package:shared_core/services/staff_org_service.dart';

class DirectorMeetingsController extends ChangeNotifier {
  DirectorMeetingsController(this.service);
  final MeetingService service;
  bool loading = true;
  String? error;
  List<MeetingRecord> meetings = const [];
  bool _disposed = false;
  int _generation = 0;

  Future<void> load() async {
    final generation = ++_generation;
    loading = true;
    error = null;
    _notify();
    try {
      final result = await service.list();
      if (_disposed || generation != _generation) return;
      meetings = result;
    } catch (e) {
      if (_disposed || generation != _generation) return;
      debugPrint('Meeting load failed: ${e.runtimeType}');
      error = e is MeetingNotSignedIn
          ? 'กรุณาเข้าสู่ระบบ'
          : 'ไม่สามารถโหลดข้อมูลประชุมได้';
      meetings = const [];
    }
    if (_disposed || generation != _generation) return;
    loading = false;
    _notify();
  }

  List<String> get types =>
      meetings.map((m) => m.type).toSet().toList()..sort();
  List<MeetingRecord> filtered(String query, String? type) => meetings
      .where(
        (m) =>
            (type == null || m.type == type) &&
            ('${m.title} ${m.organizer ?? ''} ${m.location ?? ''}')
                .toLowerCase()
                .contains(query.trim().toLowerCase()),
      )
      .toList();

  Future<MeetingDetail> create(MeetingDraft draft) => service.create(draft);
  Future<List<MeetingCalendarEntry>> calendar() => service.calendar();
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

String meetingError(Object error) {
  if (error is MeetingNotSignedIn) return 'กรุณาเข้าสู่ระบบ';
  if (error is MeetingUnconfirmed || error is StaffRequestUnconfirmed) {
    return 'ยังยืนยันผลบันทึกไม่ได้ กรุณาโหลดข้อมูลใหม่และตรวจสอบก่อนทำซ้ำ';
  }
  final text = error.toString();
  if (text.contains('invalid_session')) {
    return 'เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่';
  }
  if (text.contains('forbidden')) {
    return 'คุณไม่มีสิทธิ์ทำรายการนี้ หรือสิทธิ์มีการเปลี่ยนแปลง';
  }
  if (text.contains('minutes_already_final')) {
    return 'รายงานถูกปิดแล้ว กรุณาโหลดใหม่และใช้บันทึกเพิ่มเติม';
  }
  if (text.contains('invalid_time') || text.contains('end_before_start')) {
    return 'เวลาสิ้นสุดต้องอยู่หลังเวลาเริ่ม';
  }
  if (text.contains('one_on_one') || text.contains('attendee')) {
    return 'กรุณาตรวจสอบผู้เข้าร่วมและประเภทการประชุม';
  }
  return 'ทำรายการไม่สำเร็จ กรุณาตรวจสอบการเชื่อมต่อแล้วลองใหม่';
}

class MeetingDirectoryController extends ChangeNotifier {
  bool loading = true;
  String? error;
  List<StaffDirectoryEntry> staff = [];
  List<SchoolDepartment> departments = [];
  bool _disposed = false;
  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final result = await Future.wait([
        StaffOrgService.listStaffDirectory(),
        StaffOrgService.listDepartments(),
      ]);
      if (_disposed) return;
      staff = (result[0] as List<StaffDirectoryEntry>)
          .where((s) => s.isActive)
          .toList();
      departments = result[1] as List<SchoolDepartment>;
    } catch (_) {
      if (_disposed) return;
      error = 'ไม่สามารถโหลดรายชื่อบุคลากรและฝ่ายได้';
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
