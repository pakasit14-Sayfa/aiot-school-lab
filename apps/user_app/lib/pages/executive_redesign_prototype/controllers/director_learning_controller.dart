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
    Future<List<AutoFlaggedStudent>> Function()? autoFlags,
    Future<String?> Function(AutoFlaggedStudent)? openCase,
    Future<StudentFollowupSummary?> Function()? followupSummary,
    DateTime? date,
  }) : _overview = overview ?? ExecutiveService.getClassroomsOverview,
       _tracks = tracks ?? LearningTrackService.getOverview,
       _rooms = rooms ?? LearningTrackService.listTrackRooms,
       _attendance = attendance ?? HomeroomService.listSchoolAttendance,
       _cases = cases ?? StudentSupportService.listCases,
       _interventions =
           interventions ?? StudentSupportService.listInterventions,
       _autoFlags =
           autoFlags ?? StudentSupportService.listExecutiveAutoFlaggedStudents,
       _openCase = openCase ?? StudentSupportService.openExecutiveCaseFromFlag,
       _followupSummary =
           followupSummary ?? StudentFollowupService.getSummary,
       date = date ?? DateTime.now();
  final Future<ClassroomsOverviewItem?> Function() _overview;
  final Future<List<LearningTrackOverview>> Function() _tracks;
  final Future<List<LearningTrackRoom>> Function() _rooms;
  final Future<List<SchoolHomeroomAttendance>> Function(DateTime) _attendance;
  final Future<List<StudentSupportCase>> Function() _cases;
  final Future<List<StudentSupportIntervention>> Function(String)
  _interventions;
  final Future<List<AutoFlaggedStudent>> Function() _autoFlags;
  final Future<String?> Function(AutoFlaggedStudent) _openCase;
  final Future<StudentFollowupSummary?> Function() _followupSummary;
  DateTime date;
  ClassroomsOverviewItem? overview;
  List<LearningTrackOverview> tracks = [];
  List<LearningTrackRoom> rooms = [];
  List<SchoolHomeroomAttendance> attendance = [];
  List<StudentSupportCase> cases = [];
  List<AutoFlaggedStudent> flaggedStudents = [];
  // Loaded outside the main Future.wait (see load()) so a hiccup in this
  // still-new subsystem can't take the whole page down — it degrades to
  // null (card shows a retry affordance) instead of failing every other
  // real, previously-working section of this page.
  StudentFollowupSummary? followupSummary;
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
        _autoFlags(),
      ]);
      if (_disposed || generation != _generation) return;
      final freshOverview = data[0] as ClassroomsOverviewItem?;
      if (freshOverview == null) throw StateError('overview_missing');
      overview = freshOverview;
      tracks = data[1] as List<LearningTrackOverview>;
      rooms = data[2] as List<LearningTrackRoom>;
      attendance = data[3] as List<SchoolHomeroomAttendance>;
      cases = data[4] as List<StudentSupportCase>;
      final flags = data[5] as List<AutoFlaggedStudent>;
      flaggedStudents = flags.where((flag) {
        return !cases.any(
          (item) =>
              item.studentId == flag.studentId &&
              _caseMatchesSignal(item, flag) &&
              (item.status == 'open' || item.status == 'in_progress'),
        );
      }).toList();
    } catch (_) {
      if (_disposed || generation != _generation) return;
      overview = null;
      tracks = [];
      rooms = [];
      attendance = [];
      cases = [];
      flaggedStudents = [];
      error = 'ไม่สามารถโหลดข้อมูลนักเรียนได้ กรุณาลองอีกครั้ง';
    }
    try {
      followupSummary = await _followupSummary();
    } catch (e) {
      debugPrint('DirectorLearningController followupSummary failed: $e');
      followupSummary = null;
    }
    if (_disposed || generation != _generation) return;
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

  Future<void> openCaseFromFlag(AutoFlaggedStudent student) async {
    final caseId = await _openCase(student);
    if (caseId == null || caseId.isEmpty) throw StateError('case_open_failed');
    await load();
    if (error != null || !cases.any((item) => item.caseId == caseId)) {
      throw StateError('case_open_not_confirmed');
    }
  }

  static bool _caseMatchesSignal(
    StudentSupportCase item,
    AutoFlaggedStudent signal,
  ) =>
      item.title == '${signal.reason}: ${signal.detail}' ||
      item.title.startsWith('${signal.reason}:');

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
