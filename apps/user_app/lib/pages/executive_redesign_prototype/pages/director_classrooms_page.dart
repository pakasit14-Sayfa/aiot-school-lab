import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_core/models/school_homeroom_attendance.dart';

import '../theme/app_palette.dart';
import '../widgets/director_common_widgets.dart';
import '../widgets/classroom_attendance_card.dart';
import '../controllers/classroom_attendance_controller.dart';

/// Read seams so loading / data / empty / failure can each be driven in a test.
typedef ClassroomsOverviewLoader = Future<ClassroomsOverviewItem?> Function();
typedef HomeroomsLoader = Future<List<HomeroomAssignment>> Function();
typedef TrackRoomsLoader = Future<List<LearningTrackRoom>> Function();
typedef ClassSchedulesLoader = Future<List<SchoolScheduleItem>> Function();
typedef HomeroomAttendanceLoader =
    Future<List<SchoolHomeroomAttendance>> Function();
typedef ClassroomLearningLoader =
    Future<List<ClassroomLearningSummary>> Function();
typedef ClassroomWorkActivityLoader =
    Future<List<ClassroomWorkActivity>> Function();
typedef ClassroomWorkDetailsLoader =
    Future<List<ClassroomWorkDetails>> Function();
typedef SupportCasesLoader = Future<List<StudentSupportCase>> Function();
typedef AssignmentRosterLoader =
    Future<List<ClassroomAssignmentRosterItem>> Function(String assignmentId);

class DirectorClassroomsPage extends StatefulWidget {
  const DirectorClassroomsPage({
    super.key,
    this.loadOverview,
    this.loadHomerooms,
    this.loadTrackRooms,
    this.loadSchedules,
    this.loadAttendance,
    this.loadLearning,
    this.loadWorkActivity,
    this.loadWorkDetails,
    this.loadSupportCases,
    this.loadAssignmentRoster,
  });

  final ClassroomsOverviewLoader? loadOverview;
  final HomeroomsLoader? loadHomerooms;
  final TrackRoomsLoader? loadTrackRooms;
  final ClassSchedulesLoader? loadSchedules;
  final HomeroomAttendanceLoader? loadAttendance;
  final ClassroomLearningLoader? loadLearning;
  final ClassroomWorkActivityLoader? loadWorkActivity;
  final ClassroomWorkDetailsLoader? loadWorkDetails;
  final SupportCasesLoader? loadSupportCases;
  final AssignmentRosterLoader? loadAssignmentRoster;

  @override
  State<DirectorClassroomsPage> createState() => _DirectorClassroomsPageState();
}

class _DirectorClassroomsPageState extends State<DirectorClassroomsPage> {
  _ClassroomData? selectedRoom;

  ClassroomsOverviewItem? _overview;

  // Loading and failure used to be indistinguishable from real data: the
  // summary tiles fell back to the hardcoded '36' / '1,248' / '64' whenever
  // _overview was null, so a failed load silently showed a director invented
  // numbers as if they were this school's.
  bool _overviewLoading = true;
  bool _overviewFailed = false;

  List<HomeroomAssignment> _homerooms = const [];
  List<LearningTrackRoom> _trackRooms = const [];
  List<SchoolScheduleItem> _schedules = const [];
  List<SchoolHomeroomAttendance> _attendance = const [];
  List<ClassroomLearningSummary> _learning = const [];
  List<ClassroomWorkActivity> _workActivity = const [];
  List<ClassroomWorkDetails> _workDetails = const [];
  List<StudentSupportCase> _supportCases = const [];

  @override
  void initState() {
    super.initState();
    _loadClassroomsOverview();
  }

  Future<void> _loadClassroomsOverview() async {
    if (mounted) {
      setState(() {
        _overviewLoading = true;
        _overviewFailed = false;
      });
    }
    try {
      final results = await Future.wait<Object?>([
        widget.loadOverview?.call() ?? ExecutiveService.getClassroomsOverview(),
        widget.loadHomerooms?.call() ??
            HomeroomService.listHomeroomAssignments(),
        widget.loadTrackRooms?.call() ?? LearningTrackService.listTrackRooms(),
        widget.loadSchedules?.call() ??
            ExecutiveService.listAllSchoolSchedules(),
        widget.loadAttendance?.call() ??
            HomeroomService.listSchoolAttendance(DateTime.now()),
        widget.loadLearning?.call() ??
            ExecutiveService.listClassroomLearningSummary(),
        widget.loadWorkActivity?.call() ??
            ExecutiveService.listClassroomWorkActivity(),
        widget.loadWorkDetails?.call() ??
            ExecutiveService.listClassroomWorkDetails(),
        widget.loadSupportCases?.call() ??
            StudentSupportService.listCasesByRoom(),
      ]);
      final overview = results[0] as ClassroomsOverviewItem?;
      if (!mounted) return;
      setState(() {
        _homerooms = results[1] as List<HomeroomAssignment>;
        _trackRooms = results[2] as List<LearningTrackRoom>;
        _schedules = results[3] as List<SchoolScheduleItem>;
        _attendance = results[4] as List<SchoolHomeroomAttendance>;
        _learning = results[5] as List<ClassroomLearningSummary>;
        _workActivity = results[6] as List<ClassroomWorkActivity>;
        _workDetails = results[7] as List<ClassroomWorkDetails>;
        _supportCases = results[8] as List<StudentSupportCase>;
        _overview = overview;
        _overviewLoading = false;
      });
    } catch (e) {
      debugPrint('DirectorClassroomsPage overview load failed: $e');
      if (!mounted) return;
      setState(() {
        _overviewLoading = false;
        _overviewFailed = true;
      });
    }
  }

  String searchText = '';
  String selectedGrade = 'ทุกระดับชั้น';
  String selectedTrack = 'ทุกสายการเรียน';
  String selectedAssignmentFilter = 'ทั้งหมด';

  List<String> get grades => [
    'ทุกระดับชั้น',
    ...({for (final r in classrooms) r.grade}.toList()..sort()),
  ];

  List<String> get tracks => [
    'ทุกสายการเรียน',
    ...({for (final r in classrooms) r.track}.toList()..sort()),
  ];

  final List<String> assignmentFilters = const [
    'ทั้งหมด',
    'กำลังดำเนินการ',
    'ใกล้ครบกำหนด',
    'เลยกำหนด',
    'ส่งครบ',
    'ฉบับร่าง',
    'ยังไม่มีนักเรียน',
  ];

  /// Built from three executive-readable RPCs, not written by hand.
  ///
  /// This was a 205-line const list of every room in a school that does not
  /// exist — ม.1/1 through ม.6/x, each with a homeroom teacher's name, a
  /// student count, and five scores. `list_homeroom_assignments` supplies the
  /// room, grade, teacher and student count; `list_learning_track_rooms` the
  /// track; `list_all_school_schedules` the next period.
  ///
  /// The behaviour, environment and green scores are gone. Nothing in the
  /// schema computes them and no formula for them is written down anywhere,
  /// so every one of those numbers was an invention presented as an
  /// assessment of a real classroom.
  List<_ClassroomData> get classrooms {
    final trackByRoom = <String, String>{
      for (final t in _trackRooms)
        if (t.trackName != null) '${t.gradeLevel}/${t.room}': t.trackName!,
    };

    final palette = [
      AppPalette.primaryPink,
      AppPalette.learningBlue,
      AppPalette.environmentGreen,
      AppPalette.behaviorYellow,
      AppPalette.chartPink2,
    ];
    final attendanceByRoom = <String, SchoolHomeroomAttendance>{
      for (final item in _attendance)
        if (item.gradeLevel != null && item.room != null)
          '${item.gradeLevel}/${item.room}': item,
    };
    final learningByRoom = <String, ClassroomLearningSummary>{
      for (final item in _learning) '${item.gradeLevel}/${item.room}': item,
    };
    final workByRoom = <String, ClassroomWorkActivity>{
      for (final item in _workActivity) '${item.gradeLevel}/${item.room}': item,
    };

    final rows = <_ClassroomData>[];
    for (var i = 0; i < _homerooms.length; i++) {
      final h = _homerooms[i];
      final key = '${h.gradeLevel}/${h.room}';
      rows.add(
        _ClassroomData(
          room: key,
          grade: h.gradeLevel,
          track: trackByRoom[key] ?? 'ยังไม่ระบุสาย',
          roomNumber: h.room,
          homeroomTeacher: h.teacherName ?? 'ยังไม่มีครูประจำชั้น',
          students: h.studentCount,
          attendance: attendanceByRoom[key],
          learning: learningByRoom[key],
          workActivity: workByRoom[key],
          supportCases: _supportCases
              .where(
                (item) =>
                    item.gradeLevel == h.gradeLevel && item.room == h.room,
              )
              .toList(),
          nextClass: _nextClassFor(h.gradeLevel, h.room),
          color: palette[i % palette.length],
        ),
      );
    }
    rows.sort((a, b) => a.room.compareTo(b.room));
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    if (selectedRoom != null) {
      return _classroomDetailPage(selectedRoom!);
    }

    return _classroomOverviewPage();
  }

  Widget _classroomOverviewPage() {
    final filtered = _filteredClassrooms();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DirectorSectionHeader(
            title: 'ห้องเรียนและรายวิชา',
            subtitle:
                'ดูภาพรวมแต่ละห้อง การมาเรียน การเรียน งานที่ครูมอบหมาย รายวิชา และนักเรียนที่ควรติดตาม จากนั้นกดเข้าห้องเพื่อดูรายละเอียดเชิงลึก',
          ),
          const SizedBox(height: 14),
          _overviewSummary(),
          const SizedBox(height: 16),
          _greenScoreSection(),
          const SizedBox(height: 16),
          _searchAndFilters(),
          const SizedBox(height: 16),
          _classroomsSection(filtered),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // GREEN SCORE — อันดับห้องเรียนด้านสิ่งแวดล้อม
  // ---------------------------------------------------------------------------

  // The Green Score ranking that lived here — ม.6/1 96 คะแนน ↑, and eleven
  // more rooms — was a const list. No metric called a green score exists in
  // the schema, and no formula for one is written down in the project, so
  // every rank and every arrow was invented. `_greenScoreSection` now says
  // so instead of drawing a leaderboard of classrooms that were never
  // measured against each other.

  Widget _greenScoreSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: directorWhiteCard(),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Green Score รายห้อง',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppPalette.textDark,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'ยังไม่มีเกณฑ์และข้อมูลสำหรับจัดอันดับห้องเรียน — ระบบยังไม่ได้เก็บตัวชี้วัดด้านสิ่งแวดล้อมรายห้อง',
            style: TextStyle(
              fontSize: 10.5,
              height: 1.5,
              color: AppPalette.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  List<_ClassroomData> _filteredClassrooms() {
    final query = searchText.trim().toLowerCase();

    return classrooms.where((room) {
      final matchesSearch =
          query.isEmpty ||
          room.room.toLowerCase().contains(query) ||
          room.roomNumber.toLowerCase().contains(query) ||
          room.homeroomTeacher.toLowerCase().contains(query) ||
          room.track.toLowerCase().contains(query);

      final matchesGrade =
          selectedGrade == 'ทุกระดับชั้น' || room.grade == selectedGrade;

      final matchesTrack =
          selectedTrack == 'ทุกสายการเรียน' || room.track == selectedTrack;

      return matchesSearch && matchesGrade && matchesTrack;
    }).toList();
  }

  Widget _overviewSummary() {
    // No invented fallbacks. A director must be able to tell "the system is
    // still fetching", "this school genuinely has none", and "the load
    // failed" apart from a real figure — the old `?? '36'` / `?? '1,248'` /
    // `?? '64'` collapsed all three into numbers that looked authoritative.
    // The value slot is a large fixed-height number field, so the non-data
    // states go in the small subtitle line and the value stays a short
    // marker. Putting 'ยังไม่มีข้อมูล' in the value slot itself overflows
    // the tile by 24px — caught by infinite_height_layout_audit_test.
    String figure(String Function(ClassroomsOverviewItem) read) {
      final o = _overview;
      return o != null ? read(o) : '—';
    }

    String note(String whenLoaded) {
      if (_overview != null) return whenLoaded;
      if (_overviewLoading) return 'กำลังโหลด…';
      return _overviewFailed ? 'โหลดไม่สำเร็จ' : 'ยังไม่มีข้อมูล';
    }

    final roomCount = figure((o) => o.roomCount.toString());
    final studentCount = figure((o) => o.activeStudentCount.toString());
    final assignmentCount = figure((o) => o.assignmentsDueThisWeek.toString());

    final items = [
      _OverviewSummary(
        title: 'ห้องเรียนทั้งหมด',
        value: roomCount,
        subtitle: note('ในระบบโรงเรียน'),
        icon: Icons.meeting_room_rounded,
        color: AppPalette.softPink,
      ),
      _OverviewSummary(
        title: 'นักเรียนทั้งหมด',
        value: studentCount,
        subtitle: note('ทุกระดับชั้น'),
        icon: Icons.groups_rounded,
        color: AppPalette.softBlue,
      ),
      _OverviewSummary(
        title: 'งานที่มอบหมายสัปดาห์นี้',
        value: assignmentCount,
        subtitle: note('ทุกห้องรวมกัน'),
        icon: Icons.assignment_rounded,
        color: AppPalette.softCream,
      ),
      // 'งานที่ส่งช้า/ค้าง' was a hardcoded '67'. get_classrooms_overview
      // returns no such figure, so there is nothing truthful to show here —
      // it is marked unavailable rather than left displaying an invented
      // number of students who supposedly need following up.
      _OverviewSummary(
        title: 'งานที่ส่งช้า/ค้าง',
        value: '—',
        subtitle: 'ยังไม่มีข้อมูล',
        icon: Icons.assignment_late_rounded,
        color: AppPalette.softPink2,
      ),
      _OverviewSummary(
        title: 'ห้องที่ควรติดตาม',
        value: '—',
        subtitle: 'ยังไม่มีข้อมูลที่คำนวณได้จากระบบ',
        icon: Icons.visibility_rounded,
        color: AppPalette.softMint,
      ),
      _OverviewSummary(
        title: 'คะแนนการเรียนภาพรวม',
        value: '—',
        subtitle: 'ยังไม่มีข้อมูลที่คำนวณได้จากระบบ',
        icon: Icons.analytics_rounded,
        color: AppPalette.softBlue,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = 6;
        if (constraints.maxWidth < 700) {
          columns = 2;
        } else if (constraints.maxWidth < 1120) {
          columns = 3;
        }

        return GridView.builder(
          itemCount: items.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: columns == 2 ? 126 : 116,
          ),
          itemBuilder: (context, index) {
            final item = items[index];

            return Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: item.color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 31,
                    height: 31,
                    decoration: BoxDecoration(
                      color: AppPalette.tint(Colors.white, 0.82),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      item.icon,
                      size: 17,
                      color: AppPalette.textDark,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9.2,
                      color: AppPalette.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    item.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 8.2,
                      color: AppPalette.textMuted,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _searchAndFilters() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: directorWhiteCard(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 820;

          final search = TextField(
            onChanged: (value) {
              setState(() => searchText = value);
            },
            decoration: InputDecoration(
              hintText: 'ค้นหาห้อง เช่น ม.1/1, เลขห้อง หรือครูประจำชั้น...',
              hintStyle: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppPalette.primaryPink,
                size: 18,
              ),
              filled: true,
              fillColor: AppPalette.pageBg,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: const BorderSide(color: AppPalette.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: const BorderSide(color: AppPalette.border),
              ),
              // Theme's own focusedBorder is a 12px-radius rect
              // (buildRoleTheme) — without overriding it here too, focusing
              // this field would snap its corners from the pill shape to
              // that rect.
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: const BorderSide(
                  color: AppPalette.primaryPink,
                  width: 1.5,
                ),
              ),
            ),
          );

          final grade = _filterDropdown(
            value: selectedGrade,
            items: grades,
            icon: Icons.school_rounded,
            onChanged: (value) {
              if (value == null) return;
              setState(() => selectedGrade = value);
            },
          );

          final track = _filterDropdown(
            value: selectedTrack,
            items: tracks,
            icon: Icons.account_tree_rounded,
            onChanged: (value) {
              if (value == null) return;
              setState(() => selectedTrack = value);
            },
          );

          if (compact) {
            return Column(
              children: [
                search,
                const SizedBox(height: 9),
                Row(
                  children: [
                    Expanded(child: grade),
                    const SizedBox(width: 9),
                    Expanded(child: track),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(flex: 3, child: search),
              const SizedBox(width: 10),
              Expanded(child: grade),
              const SizedBox(width: 10),
              Expanded(child: track),
            ],
          );
        },
      ),
    );
  }

  Widget _filterDropdown({
    required String value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppPalette.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: AppPalette.primaryPink),
          const SizedBox(width: 7),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: AppPalette.textDark,
                ),
                items: items
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item,
                        child: Text(item, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _classroomsSection(List<_ClassroomData> filtered) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ห้องเรียน',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'กดห้องเรียนเพื่อดูงานที่ครูมอบหมาย คะแนนภาพรวม รายวิชา ตารางสอน และนักเรียนที่ต้องติดตาม',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppPalette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${filtered.length} ห้อง',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppPalette.primaryPinkDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Horizontal rows instead of a card grid — scans across many rooms
          // faster than a multi-column grid where comparing the same metric
          // between rooms means scanning up-down-up-down.
          for (int i = 0; i < filtered.length; i++) ...[
            _classroomRow(filtered[i]),
            if (i != filtered.length - 1) const SizedBox(height: 10),
          ],
          if (filtered.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
              alignment: Alignment.center,
              child: const Text(
                'ไม่พบห้องเรียนตามเงื่อนไข',
                style: TextStyle(fontSize: 10.5, color: AppPalette.textMuted),
              ),
            ),
        ],
      ),
    );
  }

  // Horizontal row instead of a grid card — reads left-to-right like a
  // roster line, and scans faster across many rooms than a multi-column
  // grid (comparing the same metric between two rooms means scanning
  // up-down-up-down instead of straight across). Same fields as the old
  // card (room code, track, room number, homeroom teacher, student count,
  // attendance/grade/submission metrics, next period) — none dropped,
  // just reflowed. The old card's "สาย" metric tile is gone: it showed
  // room.track a second time (already in the title line right above it),
  // not a late-arrival count the label implied.
  Widget _classroomRow(_ClassroomData room) {
    final badge = Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppPalette.tint(room.color, 0.11),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        room.room,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: room.color,
        ),
      ),
    );

    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${room.track} • ห้อง ${room.roomNumber}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(
          room.homeroomTeacher,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w500,
            color: AppPalette.textMuted,
          ),
        ),
      ],
    );

    final pills = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _roomPill('นักเรียน', '${room.students}', AppPalette.primaryPink),
        _roomPill(
          'มาเรียน',
          room.attendance?.attendancePercent == null
              ? '—'
              : '${room.attendance!.attendancePercent!.round()}%',
          AppPalette.environmentGreen,
        ),
        _roomPill(
          'คะแนนเฉลี่ย',
          room.learning?.averageGradePercent == null
              ? '—'
              : '${room.learning!.averageGradePercent!.round()}%',
          AppPalette.chartPink2,
        ),
        _roomPill(
          'ส่งงานแล้ว',
          room.workActivity == null
              ? '—'
              : '${room.workActivity!.submittedCount}/${room.workActivity!.expectedSubmissionCount}',
          AppPalette.learningBlue,
        ),
      ],
    );

    final info = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _roomInfoRow(Icons.person_rounded, 'ครูประจำชั้น', room.homeroomTeacher),
        _roomInfoRow(Icons.schedule_rounded, 'คาบถัดไป', room.nextClass),
      ],
    );

    const chevron = Icon(
      Icons.chevron_right_rounded,
      color: AppPalette.textMuted,
    );

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        setState(() => selectedRoom = room);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppPalette.tint(room.color, 0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppPalette.tint(room.color, 0.16)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 760) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      badge,
                      const SizedBox(width: 10),
                      Expanded(child: title),
                      chevron,
                    ],
                  ),
                  const SizedBox(height: 10),
                  pills,
                  const SizedBox(height: 10),
                  info,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                badge,
                const SizedBox(width: 12),
                SizedBox(width: 170, child: title),
                const SizedBox(width: 14),
                Expanded(child: pills),
                const SizedBox(width: 14),
                SizedBox(width: 150, child: info),
                const SizedBox(width: 6),
                chevron,
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _roomPill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: AppPalette.tint(color, 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: AppPalette.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _roomInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppPalette.textMuted),
          const SizedBox(width: 6),
          SizedBox(
            width: 75,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 8.6,
                color: AppPalette.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 8.8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ROOM DETAIL
  // ---------------------------------------------------------------------------

  Widget _classroomDetailPage(_ClassroomData room) {
    final assignments = _assignmentsFor(room);
    final filteredAssignments = selectedAssignmentFilter == 'ทั้งหมด'
        ? assignments
        : assignments
              .where((item) => item.status == selectedAssignmentFilter)
              .toList();

    final subjects = _subjectsFor(room);
    final timetable = _timetableFor(room);
    final activities = _teacherActivitiesFor(room);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _detailHeader(room),
          const SizedBox(height: 14),
          _roomSummaryCards(room),
          const SizedBox(height: 16),
          ClassroomAttendanceCard(
            key: ValueKey(room.room),
            controller: ClassroomAttendanceController(
              grade: room.grade,
              room: room.roomNumber,
            ),
          ),
          const SizedBox(height: 16),

          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 980) {
                return Column(
                  children: [
                    _learningOverviewCard(room, subjects),
                    const SizedBox(height: 16),
                    _directorAttentionCard(room),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: _learningOverviewCard(room, subjects),
                  ),
                  const SizedBox(width: 16),
                  Expanded(flex: 4, child: _directorAttentionCard(room)),
                ],
              );
            },
          ),

          const SizedBox(height: 16),
          _assignmentsSection(room, filteredAssignments),
          const SizedBox(height: 16),

          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 980) {
                return Column(
                  children: [
                    _todayTimetableCard(room, timetable),
                    const SizedBox(height: 16),
                    _teacherActivityCard(activities),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _todayTimetableCard(room, timetable)),
                  const SizedBox(width: 16),
                  Expanded(child: _teacherActivityCard(activities)),
                ],
              );
            },
          ),

          const SizedBox(height: 16),
          _studentSupportSection(room),
        ],
      ),
    );
  }

  Widget _detailHeader(_ClassroomData room) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: directorWhiteCard(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              setState(() {
                selectedRoom = null;
                selectedAssignmentFilter = 'ทั้งหมด';
              });
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppPalette.primaryPinkSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppPalette.primaryPinkDark,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 54,
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppPalette.tint(room.color, 0.11),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              room.room,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: room.color,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ห้อง ${room.room}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${room.track} • ห้อง ${room.roomNumber} • ครูประจำชั้น ${room.homeroomTeacher}',
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppPalette.textMuted,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'ดูภาพรวมการเรียน งานที่ครูมอบหมาย คะแนนแต่ละรายวิชา ตารางสอน และประเด็นที่ต้องติดตามของห้องนี้',
                  style: TextStyle(fontSize: 9.5, color: AppPalette.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _roomSummaryCards(_ClassroomData room) {
    final items = [
      _DetailSummary(
        title: 'นักเรียน',
        value: '${room.students}',
        subtitle: 'คนในห้อง',
        icon: Icons.groups_rounded,
        color: AppPalette.softPink,
      ),
      // Attendance, learning score, assignment counts and follow-up counts
      // used to render here as percentages and headcounts. None is computed
      // per room by any RPC today; the attendance and assignment ones are
      // reachable with new aggregates over tables that do exist, the scores
      // are not defined anywhere at all.
      _DetailSummary(
        title: 'สายการเรียน',
        value: room.track,
        subtitle: 'จากผังสายการเรียน',
        icon: Icons.route_rounded,
        color: AppPalette.softBlue,
      ),
      _DetailSummary(
        title: 'ครูประจำชั้น',
        value: room.homeroomTeacher,
        subtitle: 'ผู้รับผิดชอบห้อง',
        icon: Icons.person_rounded,
        color: AppPalette.softMint,
      ),
      _DetailSummary(
        title: 'คาบถัดไป',
        value: room.nextClass,
        subtitle: 'จากตารางสอนจริง',
        icon: Icons.schedule_rounded,
        color: AppPalette.softCream,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = 6;
        if (constraints.maxWidth < 700) {
          columns = 2;
        } else if (constraints.maxWidth < 1120) {
          columns = 3;
        }

        return GridView.builder(
          itemCount: items.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: columns == 2 ? 122 : 112,
          ),
          itemBuilder: (context, index) {
            final item = items[index];

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: item.color,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(item.icon, size: 18, color: AppPalette.textDark),
                  const Spacer(),
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 8.8,
                      color: AppPalette.textMuted,
                    ),
                  ),
                  Text(
                    item.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 8,
                      color: AppPalette.textMuted,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _learningOverviewCard(
    _ClassroomData room,
    List<_SubjectPerformance> subjects,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'คะแนนภาพรวมการเรียนของห้อง',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'เปรียบเทียบคะแนนเฉลี่ยของแต่ละรายวิชา เพื่อดูว่าวิชาใดอยู่ในเกณฑ์ดีและวิชาใดควรติดตาม',
            style: TextStyle(fontSize: 10, color: AppPalette.textMuted),
          ),
          const SizedBox(height: 14),
          ...subjects.map((subject) => _subjectProgress(subject)),
          if (subjects.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
              decoration: BoxDecoration(
                color: AppPalette.pageBg,
                borderRadius: BorderRadius.circular(12),
              ),
              // The verdict that used to sit here — "ภาพรวมการเรียนของห้องอยู่
              // ในเกณฑ์ดี" or its warning twin — was chosen by comparing an
              // invented learningScore against 93.
              child: const Text(
                'ยังไม่มีการรวมคะแนนรายวิชาต่อห้อง',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10.5, color: AppPalette.textMuted),
              ),
            ),
        ],
      ),
    );
  }

  Widget _subjectProgress(_SubjectPerformance subject) {
    final color = subject.score >= 93
        ? AppPalette.environmentGreen
        : subject.score >= 88
        ? AppPalette.learningBlue
        : AppPalette.warning;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 105,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject.subject,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subject.teacher,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 7.8,
                    color: AppPalette.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: subject.score / 100,
                minHeight: 8,
                backgroundColor: AppPalette.softTag,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 34,
            child: Text(
              '${subject.score}%',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The "สิ่งที่ผู้อำนวยการควรติดตาม" card used to list four issues per room
  /// — งานค้าง, การมาเรียน, นักเรียนที่ต้องดูแล, สภาพแวดล้อมในห้อง — each with
  /// a headcount, a severity and a recommended action. Every one of those
  /// numbers came from the invented per-room scores, so the card was advice
  /// derived from nothing, addressed to the person most likely to act on it.
  Widget _directorAttentionCard(_ClassroomData room) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'สิ่งที่ควรติดตาม',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppPalette.textDark,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
            decoration: BoxDecoration(
              color: AppPalette.pageBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'ยังไม่มีข้อมูลสรุปรายห้องสำหรับงานค้างหรือการติดตามนักเรียน '
              'ดูรายละเอียดได้ที่หน้าของครูประจำชั้นและระบบดูแลช่วยเหลือนักเรียน',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5,
                height: 1.5,
                color: AppPalette.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _assignmentsSection(
    _ClassroomData room,
    List<_AssignmentData> assignments,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 720;

              final heading = const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'งานที่ครูมอบหมายให้นักเรียน',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'ดูว่าครูแต่ละวิชาลงงานอะไร กำหนดส่งเมื่อไร และนักเรียนส่งแล้วกี่คน',
                    style: TextStyle(fontSize: 10, color: AppPalette.textMuted),
                  ),
                ],
              );

              final filter = _assignmentFilterDropdown();

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [heading, const SizedBox(height: 10), filter],
                );
              }

              return Row(
                children: [
                  Expanded(child: heading),
                  SizedBox(width: 190, child: filter),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          if (assignments.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              child: const Text(
                'ไม่มีงานตามตัวกรองนี้',
                style: TextStyle(fontSize: 10, color: AppPalette.textMuted),
              ),
            )
          else
            ...assignments.map(
              (assignment) => _assignmentTile(room, assignment),
            ),
        ],
      ),
    );
  }

  Widget _assignmentFilterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppPalette.pageBg,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppPalette.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedAssignmentFilter,
          isExpanded: true,
          items: assignmentFilters
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item, style: const TextStyle(fontSize: 9.5)),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              selectedAssignmentFilter = value;
            });
          },
        ),
      ),
    );
  }

  Widget _assignmentTile(_ClassroomData room, _AssignmentData assignment) {
    final statusColor = _assignmentStatusColor(assignment.status);

    return InkWell(
      borderRadius: BorderRadius.circular(17),
      onTap: () => _showAssignmentDetail(room, assignment),
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: AppPalette.border),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 720;

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _assignmentIcon(assignment),
                      const SizedBox(width: 10),
                      Expanded(child: _assignmentMainInfo(assignment)),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      _tag(
                        'ส่ง ${assignment.submitted}/${assignment.expected}',
                        AppPalette.learningBlue,
                      ),
                      _tag(
                        'เฉลี่ย ${assignment.averageScore}',
                        AppPalette.environmentGreen,
                      ),
                      _tag(assignment.status, statusColor),
                    ],
                  ),
                ],
              );
            }

            return Row(
              children: [
                _assignmentIcon(assignment),
                const SizedBox(width: 11),
                Expanded(flex: 3, child: _assignmentMainInfo(assignment)),
                Expanded(
                  child: _assignmentListInfo('กำหนดส่ง', assignment.dueDate),
                ),
                Expanded(
                  child: _assignmentListInfo(
                    'ส่งแล้ว',
                    '${assignment.submitted}/${assignment.expected}',
                  ),
                ),
                Expanded(
                  child: _assignmentListInfo(
                    'คะแนนเฉลี่ย',
                    assignment.averageScore,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppPalette.tint(statusColor, 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    assignment.status,
                    style: TextStyle(
                      fontSize: 8.3,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppPalette.textMuted,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _assignmentIcon(_AssignmentData assignment) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppPalette.tint(assignment.color, 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(assignment.icon, color: assignment.color, size: 20),
    );
  }

  Widget _assignmentMainInfo(_AssignmentData assignment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          assignment.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 10.8, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(
          '${assignment.subject} • ${assignment.teacher}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 8.7, color: AppPalette.textMuted),
        ),
        const SizedBox(height: 2),
        Text(
          'มอบหมาย ${assignment.assignedDate}',
          style: const TextStyle(fontSize: 8.2, color: AppPalette.textMuted),
        ),
      ],
    );
  }

  Widget _assignmentListInfo(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 8.2, color: AppPalette.textMuted),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 9.2, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _tag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppPalette.tint(color, 0.09),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 8.2,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Color _assignmentStatusColor(String status) {
    switch (status) {
      case 'ใกล้ครบกำหนด':
        return AppPalette.warning;
      case 'เลยกำหนด':
        return AppPalette.danger;
      case 'ส่งครบ':
        return AppPalette.environmentGreen;
      default:
        return AppPalette.learningBlue;
    }
  }

  Widget _todayTimetableCard(
    _ClassroomData room,
    List<_TimetableItem> timetable,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ตารางเรียนวันนี้',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            timetable.isEmpty
                ? 'ยังไม่มีคาบเรียนวันนี้ที่ตรงกับห้อง ${room.room} ในตารางสอนจริง'
                : 'แสดง ${timetable.length} คาบจากตารางสอนจริงของห้อง ${room.room}',
            style: TextStyle(fontSize: 10, color: AppPalette.textMuted),
          ),
          const SizedBox(height: 14),
          ...timetable.map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: AppPalette.tint(item.color, 0.06),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 58,
                    child: Text(
                      item.time,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: item.color,
                      ),
                    ),
                  ),
                  Container(width: 1, height: 38, color: AppPalette.border),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.subject,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${item.teacher} • ${item.room}',
                          style: const TextStyle(
                            fontSize: 8.5,
                            color: AppPalette.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _tag(item.status, item.color),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _teacherActivityCard(List<_TeacherActivity> activities) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'กิจกรรมล่าสุดของครูผู้สอน',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'ดูว่าครูลงงาน ตรวจงาน หรือบันทึกข้อมูลอะไรให้ห้องนี้ล่าสุด',
            style: TextStyle(fontSize: 10, color: AppPalette.textMuted),
          ),
          const SizedBox(height: 14),
          ...activities.map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      color: AppPalette.tint(item.color, 0.10),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(item.icon, size: 17, color: item.color),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 10.3,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          item.detail,
                          style: const TextStyle(
                            fontSize: 8.8,
                            height: 1.35,
                            color: AppPalette.textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.time,
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: item.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _studentSupportSection(_ClassroomData room) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'นักเรียนที่ต้องดูแลช่วยเหลือ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppPalette.textDark,
            ),
          ),
          SizedBox(height: 10),
          if (room.supportCases.isEmpty)
            const Text(
              'ยังไม่มีข้อมูลเคสของห้องนี้',
              style: TextStyle(fontSize: 10.5, color: AppPalette.textMuted),
            )
          else
            ...room.supportCases.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${item.studentName} • ${item.categoryLabel} • ${item.statusLabel}',
                  style: const TextStyle(fontSize: 10.5),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showAssignmentDetail(
    _ClassroomData room,
    _AssignmentData assignment,
  ) async {
    final missing = assignment.pending;
    final statusColor = _assignmentStatusColor(assignment.status);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: SizedBox(
          height: 60,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
    );
    late final List<ClassroomAssignmentRosterItem> roster;
    try {
      roster =
          await (widget.loadAssignmentRoster?.call(assignment.id) ??
              ExecutiveService.listAssignmentRoster(assignment.id));
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('โหลดรายชื่อนักเรียนไม่สำเร็จ')),
      );
      return;
    }
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            assignment.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      _tag(assignment.subject, assignment.color),
                      _tag(assignment.status, statusColor),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _detailRow('ครูผู้สอน', assignment.teacher),
                  _detailRow('มอบหมายวันที่', assignment.assignedDate),
                  _detailRow('กำหนดส่ง', assignment.dueDate),
                  _detailRow(
                    'ส่งแล้ว',
                    '${assignment.submitted}/${assignment.expected} คน',
                  ),
                  _detailRow('ยังไม่ส่ง', '$missing คน'),
                  _detailRow('คะแนนเฉลี่ย', assignment.averageScore),
                  const SizedBox(height: 12),
                  const Text(
                    'รายละเอียดงาน',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    assignment.description,
                    style: const TextStyle(
                      fontSize: 9.5,
                      height: 1.5,
                      color: AppPalette.textMuted,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'รายชื่อนักเรียนและสถานะการส่ง',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (roster.isEmpty)
                    const Text(
                      'ยังไม่มีรายชื่อนักเรียนในรายวิชานี้',
                      style: TextStyle(
                        fontSize: 9.5,
                        color: AppPalette.textMuted,
                      ),
                    )
                  else
                    ...roster.map(
                      (student) => Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Row(
                          children: [
                            Icon(
                              student.submissionStatus == 'ยังไม่ส่ง'
                                  ? Icons.radio_button_unchecked
                                  : Icons.check_circle,
                              size: 14,
                              color: student.submissionStatus == 'ยังไม่ส่ง'
                                  ? AppPalette.textMuted
                                  : AppPalette.environmentGreen,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                student.studentName,
                                style: const TextStyle(fontSize: 9.5),
                              ),
                            ),
                            Text(
                              student.submissionStatus,
                              style: const TextStyle(
                                fontSize: 8.5,
                                color: AppPalette.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('ปิด'),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 115,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 9.5,
                color: AppPalette.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MOCK DETAIL DATA
  // ---------------------------------------------------------------------------

  /// Assignment titles and per-assignment rosters need a detail RPC. The
  /// room-level count is available through ClassroomWorkActivity and is shown
  /// on the room card until that detail seam exists.
  ///
  /// Was five fully-written assignments per room — titles, descriptions,
  /// invented teacher names such as ครูพรทิพย์ รักษ์ดี, submission counts
  /// derived from the invented overdue count, and average scores. The
  /// `assignments`, `submissions` and `course_students` tables all exist, so
  /// this is reachable with a room-scoped aggregate; it simply does not exist
  /// yet, and a placeholder was never the honest stand-in.
  List<_AssignmentData> _assignmentsFor(_ClassroomData room) =>
      (_workDetails
              .where(
                (item) =>
                    item.gradeLevel == room.grade &&
                    item.room == room.roomNumber,
              )
              .expand((item) => item.assignments)
              .map(
                (item) => _AssignmentData(
                  id: item.assignmentId,
                  subject: 'งานของห้อง ${room.room}',
                  teacher: item.teacher.isEmpty
                      ? 'ยังไม่มีข้อมูลครูผู้สอน'
                      : item.teacher,
                  title: item.title,
                  assignedDate: item.createdAt == null
                      ? 'ยังไม่มีวันที่'
                      : _formatActivityTime(item.createdAt!),
                  dueDate: item.dueAt == null
                      ? 'ไม่มีกำหนดส่ง'
                      : _formatActivityTime(item.dueAt!),
                  submitted: item.submitted,
                  expected: item.expected,
                  pending: item.pending,
                  averageScore: '—',
                  status: _assignmentStatus(item),
                  description: item.instructions?.trim().isNotEmpty == true
                      ? item.instructions!.trim()
                      : 'ยังไม่มีรายละเอียดงาน',
                  icon: Icons.assignment_rounded,
                  color: AppPalette.learningBlue,
                ),
              )
              .toList())
          .cast<_AssignmentData>();

  /// Empty until per-subject results can be aggregated per room.
  ///
  /// Was eight subjects whose scores were computed as
  /// `base + (room.learningScore - 92)` — invented numbers adjusted by another
  /// invented number.
  List<_SubjectPerformance> _subjectsFor(_ClassroomData room) =>
      const <_SubjectPerformance>[];

  List<SchoolScheduleItem> _schedulesForRoom(String grade, String roomNumber) {
    final cohortRoom = _normaliseRoom('$grade/$roomNumber');
    final today = DateTime.now().weekday - 1;

    final matches = _schedules
        .where((schedule) {
          final scheduleRoom = schedule.room?.trim();
          if (scheduleRoom == null || scheduleRoom.isEmpty) return false;
          final normalized = _normaliseRoom(scheduleRoom);
          return cohortRoom == normalized;
        })
        .where((schedule) => schedule.dayOfWeek == today)
        .toList();

    matches.sort(
      (a, b) =>
          _timeToMinutes(a.startTime).compareTo(_timeToMinutes(b.startTime)),
    );
    return matches;
  }

  String _normaliseRoom(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');

  String _assignmentStatus(ClassroomAssignmentDetail item) {
    if (item.status == 'draft') return 'ฉบับร่าง';
    if (item.expected == 0) return 'ยังไม่มีนักเรียน';
    if (item.pending == 0) return 'ส่งครบ';
    final dueAt = item.dueAt;
    if (dueAt == null) return 'กำลังดำเนินการ';
    final now = DateTime.now();
    if (dueAt.isBefore(now)) return 'เลยกำหนด';
    if (dueAt.difference(now) <= const Duration(days: 3)) {
      return 'ใกล้ครบกำหนด';
    }
    return 'กำลังดำเนินการ';
  }

  int _timeToMinutes(String value) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(value.trim());
    if (match == null) return 24 * 60;
    return int.parse(match.group(1)!) * 60 + int.parse(match.group(2)!);
  }

  String _scheduleLabel(SchoolScheduleItem schedule) {
    final subject = schedule.subjectName.trim();
    return subject.isEmpty ? 'ยังไม่มีชื่อรายวิชา' : subject;
  }

  String _nextClassFor(String grade, String roomNumber) {
    final schedules = _schedulesForRoom(grade, roomNumber);
    if (schedules.isEmpty) return 'ยังไม่มีคาบวันนี้';

    final now = DateTime.now().hour * 60 + DateTime.now().minute;
    for (final schedule in schedules) {
      final start = _timeToMinutes(schedule.startTime);
      final end = _timeToMinutes(schedule.endTime);
      if (now >= start && now < end) {
        return '${_scheduleLabel(schedule)} (กำลังเรียน)';
      }
      if (start > now) return _scheduleLabel(schedule);
    }
    return '${_scheduleLabel(schedules.last)} (เรียนแล้ว)';
  }

  List<_TimetableItem> _timetableFor(_ClassroomData room) {
    final now = DateTime.now().hour * 60 + DateTime.now().minute;
    return _schedulesForRoom(room.grade, room.roomNumber).map((schedule) {
      final start = _timeToMinutes(schedule.startTime);
      final end = _timeToMinutes(schedule.endTime);
      final status = now >= start && now < end
          ? 'กำลังเรียน'
          : start > now
          ? 'คาบถัดไป'
          : 'เรียนแล้ว';
      final color = status == 'กำลังเรียน'
          ? AppPalette.environmentGreen
          : status == 'คาบถัดไป'
          ? AppPalette.learningBlue
          : AppPalette.textMuted;

      return _TimetableItem(
        time: '${schedule.startTime}–${schedule.endTime}',
        subject: _scheduleLabel(schedule),
        teacher: 'ยังไม่มีข้อมูลครูผู้สอน',
        room: schedule.room?.trim().isNotEmpty == true
            ? schedule.room!.trim()
            : 'ยังไม่มีห้อง',
        status: status,
        color: color,
      );
    }).toList();
  }

  List<_TeacherActivity> _teacherActivitiesFor(_ClassroomData room) {
    final details = _workDetails.where(
      (item) => item.gradeLevel == room.grade && item.room == room.roomNumber,
    );
    final activities = details.expand((item) => item.teacherActivities);
    return activities
        .map(
          (activity) => _TeacherActivity(
            title: activity.type == 'งาน' ? 'ครูมอบหมายงาน' : 'ครูสร้างบทเรียน',
            detail:
                '${activity.title} • ${activity.teacher.isEmpty ? 'ยังไม่มีข้อมูลชื่อครูผู้สอน' : activity.teacher}',
            time: activity.createdAt == null
                ? 'ยังไม่มีวันที่'
                : _formatActivityTime(activity.createdAt!),
            icon: activity.type == 'งาน'
                ? Icons.assignment_rounded
                : Icons.menu_book_rounded,
            color: AppPalette.learningBlue,
          ),
        )
        .toList();
  }

  String _formatActivityTime(DateTime value) {
    final local = value.toLocal();
    return '${local.day}/${local.month}/${local.year} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}

class _OverviewSummary {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _OverviewSummary({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class _DetailSummary {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _DetailSummary({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

/// One classroom, carrying only what the backend can actually answer.
///
/// Dropped from here: `attendance`, `learningScore`, `behaviorScore`,
/// `environmentScore`, `assignmentsThisWeek`, `overdueStudents` and
/// `followUpStudents`. Attendance and the assignment counts are computable in
/// principle — `homeroom_attendance_records`, `assignments` and `submissions`
/// all exist — but no RPC aggregates them per room, so they need backend work
/// rather than a default. Behaviour and environment scores have no source and
/// no defining formula anywhere in the project; they were pure invention
/// rendered as an assessment of a real class.
class _ClassroomData {
  final String room;
  final String grade;
  final String track;
  final String roomNumber;
  final String homeroomTeacher;
  final int students;
  final SchoolHomeroomAttendance? attendance;
  final ClassroomLearningSummary? learning;
  final ClassroomWorkActivity? workActivity;
  final List<StudentSupportCase> supportCases;
  final String nextClass;
  final Color color;

  const _ClassroomData({
    required this.room,
    required this.grade,
    required this.track,
    required this.roomNumber,
    required this.homeroomTeacher,
    required this.students,
    this.attendance,
    this.learning,
    this.workActivity,
    this.supportCases = const [],
    required this.nextClass,
    required this.color,
  });
}

class _AssignmentData {
  final String id;
  final String subject;
  final String teacher;
  final String title;
  final String assignedDate;
  final String dueDate;
  final int submitted;
  final int expected;
  final int pending;
  final String averageScore;
  final String status;
  final String description;
  final IconData icon;
  final Color color;

  const _AssignmentData({
    required this.id,
    required this.subject,
    required this.teacher,
    required this.title,
    required this.assignedDate,
    required this.dueDate,
    required this.submitted,
    required this.expected,
    required this.pending,
    required this.averageScore,
    required this.status,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class _SubjectPerformance {
  final String subject;
  final String teacher;
  final int score;

  const _SubjectPerformance(this.subject, this.teacher, this.score);
}

class _TimetableItem {
  final String time;
  final String subject;
  final String teacher;
  final String room;
  final String status;
  final Color color;

  const _TimetableItem({
    required this.time,
    required this.subject,
    required this.teacher,
    required this.room,
    required this.status,
    required this.color,
  });
}

class _TeacherActivity {
  final String title;
  final String detail;
  final String time;
  final IconData icon;
  final Color color;

  const _TeacherActivity({
    required this.title,
    required this.detail,
    required this.time,
    required this.icon,
    required this.color,
  });
}
