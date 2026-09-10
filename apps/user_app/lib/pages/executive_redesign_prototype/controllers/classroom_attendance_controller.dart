import 'package:flutter/foundation.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_core/models/school_homeroom_attendance.dart';

class ClassroomAttendanceController extends ChangeNotifier {
  ClassroomAttendanceController({
    required this.grade,
    required this.room,
    this.loader,
  });
  final String grade, room;
  final Future<List<SchoolHomeroomAttendance>> Function(DateTime)? loader;
  DateTime date = DateTime.now();
  SchoolHomeroomAttendance? data;
  bool loading = true, _disposed = false;
  String? error;
  int _generation = 0;

  Future<void> load([DateTime? selected]) async {
    date = selected ?? date;
    final generation = ++_generation;
    loading = true;
    error = null;
    data = null;
    notifyListeners();
    try {
      final rows = await (loader ?? HomeroomService.listSchoolAttendance)(date);
      if (_disposed || generation != _generation) return;
      // The raw grade and room together identify the cohort. Never match only
      // room number, or an unknown room to another grade's first classroom.
      for (final row in rows) {
        if (row.gradeLevel == grade && row.room == room) data = row;
      }
    } catch (_) {
      if (_disposed || generation != _generation) return;
      error = 'โหลดข้อมูลเช็คชื่อไม่สำเร็จ กรุณาลองอีกครั้ง';
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
