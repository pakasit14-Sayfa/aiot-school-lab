import 'package:flutter/foundation.dart';
import 'package:shared_core/shared_core.dart';

import 'school_admin_async_state.dart';

class SchoolTimetableController extends ChangeNotifier {
  final Future<List<Term>> Function() loadTerms;
  final Future<List<SchoolRoom>> Function() loadRooms;
  final Future<List<SchoolPeriod>> Function() loadPeriods;
  final Future<List<ClassSchedule>> Function(
    String termId,
    String gradeLevel,
    String room,
  )
  loadSchedules;
  final Future<List<TeacherSubject>> Function() loadTeacherSubjects;
  final Future<List<StaffDirectoryEntry>> Function() loadStaff;
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

  SchoolTimetableController({
    required this.loadTerms,
    required this.loadRooms,
    required this.loadPeriods,
    required this.loadSchedules,
    required this.loadTeacherSubjects,
    required this.loadStaff,
    required this.setSlot,
    required this.clearSlot,
    required this.savePeriods,
  });

  SchoolAdminAsyncState _state = const SchoolAdminLoading<void>();
  SchoolAdminAsyncState get state => _state;

  List<Term> _terms = [];
  List<Term> get terms => _terms;

  List<SchoolRoom> _rooms = [];
  List<SchoolRoom> get rooms => _rooms;

  List<SchoolPeriod> _periods = [];
  List<SchoolPeriod> get periods => _periods;

  List<ClassSchedule> _schedules = [];
  List<ClassSchedule> get schedules => _schedules;

  List<TeacherSubject> _teacherSubjects = [];
  List<TeacherSubject> get teacherSubjects => _teacherSubjects;

  List<StaffDirectoryEntry> _staff = [];
  List<StaffDirectoryEntry> get staff => _staff;

  String? _selectedTermId;
  String? get selectedTermId => _selectedTermId;

  SchoolRoom? _selectedRoom;
  SchoolRoom? get selectedRoom => _selectedRoom;

  Future<void> load() async {
    _state = const SchoolAdminLoading<void>();
    notifyListeners();

    try {
      final terms = await loadTerms();
      final rooms = await loadRooms();
      final periods = await loadPeriods();
      final rawTeacherSubjects = await loadTeacherSubjects();
      final staff = await loadStaff();

      // The RPC returns teacher_name; fall back to the staff directory only
      // for rows that arrive without one.
      _teacherSubjects = rawTeacherSubjects.map((ts) {
        if (ts.fullName.isNotEmpty) return ts;
        final staffMember = staff
            .where((s) => s.userId == ts.teacherId)
            .firstOrNull;
        return TeacherSubject(
          teacherId: ts.teacherId,
          subjectName: ts.subjectName,
          fullName: staffMember?.fullName ?? 'ไม่ทราบชื่อ',
        );
      }).toList();

      _terms = terms;
      _rooms = rooms;
      _periods = periods;
      _staff = staff;

      if (terms.isNotEmpty) {
        // Default to the term running today, not whatever list_terms
        // happens to return first.
        final today = DateTime.now();
        _selectedTermId =
            (terms.where((t) => t.containsDate(today)).firstOrNull ??
                    terms.first)
                .termId;
      }
      if (rooms.isNotEmpty) {
        _selectedRoom = rooms.first;
      }

      await _loadSchedulesForSelectedRoom();

      _state = const SchoolAdminData<void>(null);
    } catch (e) {
      _state = SchoolAdminError<void>(message: e.toString());
    }
    notifyListeners();
  }

  void selectTerm(String termId) {
    if (_selectedTermId == termId) return;
    _selectedTermId = termId;
    _state = const SchoolAdminLoading<void>();
    notifyListeners();

    _loadSchedulesForSelectedRoom()
        .then((_) {
          _state = const SchoolAdminData<void>(null);
          notifyListeners();
        })
        .catchError((e) {
          _state = SchoolAdminError<void>(message: e.toString());
          notifyListeners();
        });
  }

  void selectRoom(SchoolRoom room) {
    if (_selectedRoom?.gradeLevel == room.gradeLevel &&
        _selectedRoom?.room == room.room)
      return;
    _selectedRoom = room;
    _state = const SchoolAdminLoading<void>();
    notifyListeners();

    _loadSchedulesForSelectedRoom()
        .then((_) {
          _state = const SchoolAdminData<void>(null);
          notifyListeners();
        })
        .catchError((e) {
          _state = SchoolAdminError<void>(message: e.toString());
          notifyListeners();
        });
  }

  Future<void> _loadSchedulesForSelectedRoom() async {
    if (_selectedTermId == null || _selectedRoom == null) {
      _schedules = [];
      return;
    }
    _schedules = await loadSchedules(
      _selectedTermId!,
      _selectedRoom!.gradeLevel,
      _selectedRoom!.room,
    );
  }

  Future<void> assignSlot({
    required int periodNo,
    required int dayOfWeek,
    required String subjectName,
    required String? teacherId,
  }) async {
    if (_selectedTermId == null || _selectedRoom == null) return;
    try {
      await setSlot(
        termId: _selectedTermId!,
        gradeLevel: _selectedRoom!.gradeLevel,
        room: _selectedRoom!.room,
        subjectName: subjectName,
        teacherId: teacherId,
        periodNo: periodNo,
        dayOfWeek: dayOfWeek,
      );
      await _loadSchedulesForSelectedRoom();
      notifyListeners();
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> clearSlotAt({
    required int periodNo,
    required int dayOfWeek,
  }) async {
    if (_selectedTermId == null || _selectedRoom == null) return;
    try {
      await clearSlot(
        termId: _selectedTermId!,
        gradeLevel: _selectedRoom!.gradeLevel,
        room: _selectedRoom!.room,
        periodNo: periodNo,
        dayOfWeek: dayOfWeek,
      );
      await _loadSchedulesForSelectedRoom();
      notifyListeners();
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Replaces the school's period table, then reloads it from the backend
  /// (never trusts the local list).
  Future<void> replacePeriods(List<SchoolPeriod> periods) async {
    await savePeriods(periods);
    _periods = await loadPeriods();
    await _loadSchedulesForSelectedRoom();
    notifyListeners();
  }
}
