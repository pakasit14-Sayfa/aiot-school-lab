import 'package:flutter/foundation.dart';
import 'package:shared_core/shared_core.dart';

import 'school_admin_async_state.dart';

/// D6 timetable, v2 (2026-09-21): school overview → room → day. Every seam
/// is an RPC from 20260919000000/20260920030000/20260921000000; the page
/// never reads a table directly.
class SchoolTimetableController extends ChangeNotifier {
  final Future<List<Term>> Function() loadTerms;
  final Future<List<SchoolPeriod>> Function() loadPeriods;
  final Future<List<TimetableRoomOverview>> Function(String termId)
  loadOverview;
  final Future<List<ClassSchedule>> Function(
    String termId,
    String gradeLevel,
    String room,
  )
  loadSchedules;
  final Future<List<TeacherSubject>> Function() loadTeacherSubjects;
  final Future<List<StaffDirectoryEntry>> Function() loadStaff;
  final Future<List<TeacherWeekSlot>> Function(String termId, String teacherId)
  loadTeacherWeek;
  final Future<List<TeacherConflict>> Function(String termId) loadConflicts;
  final Future<void> Function({
    required String termId,
    required String gradeLevel,
    required String room,
    required String subjectName,
    required String? teacherId,
    required int periodNo,
    required int dayOfWeek,
  })
  setSlot;
  final Future<void> Function({
    required String termId,
    required String gradeLevel,
    required String room,
    required int periodNo,
    required int dayOfWeek,
  })
  clearSlot;
  final Future<void> Function(List<SchoolPeriod> periods) savePeriods;
  final Future<int> Function({
    required String fromTermId,
    required String fromGradeLevel,
    required String fromRoom,
    required String toTermId,
    required String toGradeLevel,
    required String toRoom,
  })
  copyRoom;
  final Future<int> Function({
    required String termId,
    required String gradeLevel,
    required String room,
  })
  clearRoom;

  SchoolTimetableController({
    required this.loadTerms,
    required this.loadPeriods,
    required this.loadOverview,
    required this.loadSchedules,
    required this.loadTeacherSubjects,
    required this.loadStaff,
    required this.loadTeacherWeek,
    required this.loadConflicts,
    required this.setSlot,
    required this.clearSlot,
    required this.savePeriods,
    required this.copyRoom,
    required this.clearRoom,
  });

  SchoolAdminAsyncState _state = const SchoolAdminLoading<void>();
  SchoolAdminAsyncState get state => _state;

  List<Term> _terms = [];
  List<Term> get terms => _terms;

  List<SchoolPeriod> _periods = [];
  List<SchoolPeriod> get periods => _periods;
  List<SchoolPeriod> get lessonPeriods =>
      _periods.where((p) => !p.isBreak).toList();

  List<TimetableRoomOverview> _rooms = [];
  List<TimetableRoomOverview> get rooms => _rooms;

  List<TeacherConflict> _conflicts = [];
  List<TeacherConflict> get conflicts => _conflicts;

  List<TeacherSubject> _teacherSubjects = [];
  List<TeacherSubject> get teacherSubjects => _teacherSubjects;

  List<StaffDirectoryEntry> _staff = [];

  /// Only accounts with the teacher role — the slot RPC rejects anyone else.
  List<StaffDirectoryEntry> get teachers =>
      _staff.where((s) => s.roles.contains('teacher')).toList();

  String? _selectedTermId;
  String? get selectedTermId => _selectedTermId;

  TimetableRoomOverview? _selectedRoom;
  TimetableRoomOverview? get selectedRoom => _selectedRoom;

  List<ClassSchedule> _schedules = [];
  List<ClassSchedule> get schedules => _schedules;
  bool _roomLoading = false;
  bool get roomLoading => _roomLoading;

  int _selectedDay = _todayOrMonday();
  int get selectedDay => _selectedDay;

  final Map<String, List<TeacherWeekSlot>> _teacherWeekCache = {};

  static int _todayOrMonday() {
    final d = DateTime.now().weekday; // 1 = Mon … 7 = Sun
    return d >= 1 && d <= 5 ? d : 1;
  }

  Future<void> load() async {
    _state = const SchoolAdminLoading<void>();
    notifyListeners();
    try {
      final terms = await loadTerms();
      _terms = terms;
      if (terms.isNotEmpty) {
        final today = DateTime.now();
        _selectedTermId ??=
            (terms.where((t) => t.containsDate(today)).firstOrNull ??
                    terms.first)
                .termId;
      }
      _periods = await loadPeriods();
      _teacherSubjects = await loadTeacherSubjects();
      _staff = await loadStaff();
      _teacherWeekCache.clear();
      await _reloadOverview();
      if (_selectedRoom != null) await _reloadRoom();
      _state = const SchoolAdminData<void>(null);
    } catch (e, st) {
      debugPrint('SchoolTimetableController.load failed: $e\n$st');
      _state = SchoolAdminError<void>(message: e.toString());
    }
    notifyListeners();
  }

  Future<void> _reloadOverview() async {
    final termId = _selectedTermId;
    if (termId == null) {
      _rooms = [];
      _conflicts = [];
      return;
    }
    _rooms = await loadOverview(termId);
    _conflicts = await loadConflicts(termId);
    // keep the open room's numbers fresh
    if (_selectedRoom != null) {
      _selectedRoom = _rooms
          .where((r) => r.roomKey == _selectedRoom!.roomKey)
          .firstOrNull;
    }
  }

  Future<void> _reloadRoom() async {
    final room = _selectedRoom;
    final termId = _selectedTermId;
    if (room == null || termId == null) {
      _schedules = [];
      return;
    }
    _schedules = await loadSchedules(termId, room.gradeLevel, room.room);
  }

  Future<void> selectTerm(String termId) async {
    if (_selectedTermId == termId) return;
    _selectedTermId = termId;
    _teacherWeekCache.clear();
    _state = const SchoolAdminLoading<void>();
    notifyListeners();
    try {
      await _reloadOverview();
      await _reloadRoom();
      _state = const SchoolAdminData<void>(null);
    } catch (e) {
      _state = SchoolAdminError<void>(message: e.toString());
    }
    notifyListeners();
  }

  Future<void> openRoom(TimetableRoomOverview room) async {
    _selectedRoom = room;
    _roomLoading = true;
    _schedules = [];
    notifyListeners();
    try {
      await _reloadRoom();
    } catch (e) {
      _state = SchoolAdminError<void>(message: e.toString());
    }
    _roomLoading = false;
    notifyListeners();
  }

  void closeRoom() {
    _selectedRoom = null;
    _schedules = [];
    notifyListeners();
  }

  void selectDay(int day) {
    if (day < 1 || day > 5 || day == _selectedDay) return;
    _selectedDay = day;
    notifyListeners();
  }

  ClassSchedule? slotAt(int dayOfWeek, int periodNo) => _schedules
      .where((s) => s.dayOfWeek == dayOfWeek && s.periodNo == periodNo)
      .firstOrNull;

  /// Subjects this room already has this term, with the teacher on each,
  /// most-used first — the quick-pick list in the slot sheet.
  List<RoomSubject> get roomSubjects {
    final byName = <String, RoomSubject>{};
    for (final s in _schedules) {
      final cur = byName[s.subjectName];
      byName[s.subjectName] = RoomSubject(
        subjectName: s.subjectName,
        teacherId: s.teacherId ?? cur?.teacherId,
        teacherName: s.teacherName ?? cur?.teacherName,
        slotsPerWeek: (cur?.slotsPerWeek ?? 0) + 1,
      );
    }
    final list = byName.values.toList()
      ..sort((a, b) => b.slotsPerWeek.compareTo(a.slotsPerWeek));
    return list;
  }

  /// Teachers recorded for a subject (teacher_subjects); empty means "no
  /// one yet — offer everyone".
  List<TeacherSubject> teachersFor(String subjectName) => _teacherSubjects
      .where((t) => t.subjectName.trim() == subjectName.trim())
      .toList();

  /// Where else this teacher is at (day, period) this term — null when free.
  /// Cached per teacher for the life of the term selection.
  Future<TeacherWeekSlot?> teacherClash({
    required String teacherId,
    required int dayOfWeek,
    required int periodNo,
  }) async {
    final termId = _selectedTermId;
    final room = _selectedRoom;
    if (termId == null || room == null) return null;
    final week = _teacherWeekCache[teacherId] ??= await loadTeacherWeek(
      termId,
      teacherId,
    );
    return week
        .where(
          (w) =>
              w.dayOfWeek == dayOfWeek &&
              w.periodNo == periodNo &&
              w.roomKey != room.roomKey,
        )
        .firstOrNull;
  }

  Future<void> assignSlot({
    required int periodNo,
    required int dayOfWeek,
    required String subjectName,
    required String teacherId,
  }) async {
    final termId = _selectedTermId;
    final room = _selectedRoom;
    if (termId == null || room == null) return;
    await setSlot(
      termId: termId,
      gradeLevel: room.gradeLevel,
      room: room.room,
      subjectName: subjectName,
      teacherId: teacherId,
      periodNo: periodNo,
      dayOfWeek: dayOfWeek,
    );
    _teacherWeekCache.remove(teacherId);
    await _reloadRoom();
    await _reloadOverview();
    notifyListeners();
  }

  Future<void> clearSlotAt({
    required int periodNo,
    required int dayOfWeek,
  }) async {
    final termId = _selectedTermId;
    final room = _selectedRoom;
    if (termId == null || room == null) return;
    final prev = slotAt(dayOfWeek, periodNo);
    await clearSlot(
      termId: termId,
      gradeLevel: room.gradeLevel,
      room: room.room,
      periodNo: periodNo,
      dayOfWeek: dayOfWeek,
    );
    if (prev?.teacherId != null) _teacherWeekCache.remove(prev!.teacherId);
    await _reloadRoom();
    await _reloadOverview();
    notifyListeners();
  }

  /// Replaces the school's period table, then reloads it from the backend
  /// (never trusts the local list).
  Future<void> replacePeriods(List<SchoolPeriod> periods) async {
    await savePeriods(periods);
    _periods = await loadPeriods();
    await _reloadOverview();
    await _reloadRoom();
    notifyListeners();
  }

  Future<int> copyIntoSelectedRoom({
    required String fromTermId,
    required String fromGradeLevel,
    required String fromRoom,
  }) async {
    final termId = _selectedTermId;
    final room = _selectedRoom;
    if (termId == null || room == null) return 0;
    final n = await copyRoom(
      fromTermId: fromTermId,
      fromGradeLevel: fromGradeLevel,
      fromRoom: fromRoom,
      toTermId: termId,
      toGradeLevel: room.gradeLevel,
      toRoom: room.room,
    );
    _teacherWeekCache.clear();
    await _reloadRoom();
    await _reloadOverview();
    notifyListeners();
    return n;
  }

  Future<int> clearSelectedRoom() async {
    final termId = _selectedTermId;
    final room = _selectedRoom;
    if (termId == null || room == null) return 0;
    final n = await clearRoom(
      termId: termId,
      gradeLevel: room.gradeLevel,
      room: room.room,
    );
    _teacherWeekCache.clear();
    await _reloadRoom();
    await _reloadOverview();
    notifyListeners();
    return n;
  }
}

/// A subject the open room already has this term.
class RoomSubject {
  const RoomSubject({
    required this.subjectName,
    required this.teacherId,
    required this.teacherName,
    required this.slotsPerWeek,
  });
  final String subjectName;
  final String? teacherId;
  final String? teacherName;
  final int slotsPerWeek;
}
