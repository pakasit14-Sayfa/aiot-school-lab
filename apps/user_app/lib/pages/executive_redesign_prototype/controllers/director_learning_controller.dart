import 'package:flutter/foundation.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_core/models/school_homeroom_attendance.dart';

class DirectorLearningController extends ChangeNotifier {
  DirectorLearningController({
    Future<ClassroomsOverviewItem?> Function()? overview,
    Future<List<LearningTrackOverview>> Function()? tracks,
    Future<List<LearningTrackRoom>> Function()? rooms,
    Future<List<SchoolHomeroomAttendance>> Function(DateTime)? attendance,
    Future<List<StudentSupportCase>> Function()? cases,
    Future<List<StudentSupportIntervention>> Function(String)? interventions,
    DateTime? date,
  }) : _overview = overview ?? ExecutiveService.getClassroomsOverview,
       _tracks = tracks ?? LearningTrackService.getOverview,
       _rooms = rooms ?? LearningTrackService.listTrackRooms,
       _attendance = attendance ?? HomeroomService.listSchoolAttendance,
       _cases = cases ?? StudentSupportService.listCases,
       _interventions =
           interventions ?? StudentSupportService.listInterventions,
       date = date ?? DateTime.now();
  final Future<ClassroomsOverviewItem?> Function() _overview;
  final Future<List<LearningTrackOverview>> Function() _tracks;
  final Future<List<LearningTrackRoom>> Function() _rooms;
  final Future<List<SchoolHomeroomAttendance>> Function(DateTime) _attendance;
  final Future<List<StudentSupportCase>> Function() _cases;
  final Future<List<StudentSupportIntervention>> Function(String)
  _interventions;
  DateTime date;
  ClassroomsOverviewItem? overview;
  List<LearningTrackOverview> tracks = [];
  List<LearningTrackRoom> rooms = [];
  List<SchoolHomeroomAttendance> attendance = [];
  List<StudentSupportCase> cases = [];
  bool loading = true, _disposed = false;
  int _generation = 0;
  String? error;
  Future<void> load({DateTime? onDate}) async {
    if (_disposed) return;
    if (onDate != null) date = onDate;
    final generation = ++_generation;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final data = await Future.wait<Object?>([
        _overview(),
        _tracks(),
        _rooms(),
        _attendance(date),
        _cases(),
      ]);
      if (_disposed || generation != _generation) return;
      final freshOverview = data[0] as ClassroomsOverviewItem?;
      if (freshOverview == null) throw StateError('overview_missing');
      overview = freshOverview;
      tracks = data[1] as List<LearningTrackOverview>;
      rooms = data[2] as List<LearningTrackRoom>;
      attendance = data[3] as List<SchoolHomeroomAttendance>;
      cases = data[4] as List<StudentSupportCase>;
    } catch (_) {
      if (_disposed || generation != _generation) return;
      overview = null;
      tracks = [];
      rooms = [];
      attendance = [];
      cases = [];
      error = 'ไม่สามารถโหลดข้อมูลนักเรียนได้ กรุณาลองอีกครั้ง';
    }
    loading = false;
    notifyListeners();
  }

  bool get isEmpty =>
      overview != null &&
      overview!.activeStudentCount == 0 &&
      overview!.roomCount == 0 &&
      overview!.courseCount == 0 &&
      overview!.assignmentsDueThisWeek == 0 &&
      tracks.isEmpty &&
      attendance.isEmpty &&
      cases.isEmpty;
  List<String> get grades =>
      attendance.map((r) => r.gradeLevel ?? '').toSet().toList()..sort();
  List<SchoolHomeroomAttendance> filteredAttendance(
    String? grade,
    String? track,
  ) => attendance
      .where(
        (r) =>
            (grade == null || (r.gradeLevel ?? '') == grade) &&
            (track == null ||
                rooms.any(
                  (room) =>
                      room.trackId == track &&
                      room.gradeLevel == r.gradeLevel &&
                      room.room == r.room,
                )),
      )
      .toList();
  Future<List<StudentSupportIntervention>> history(String id) =>
      _interventions(id);
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
