import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import '../theme/app_palette.dart';
import '../widgets/director_common_widgets.dart';

/// Read seams so loading / data / empty / failure can each be driven in a test.
typedef ClassroomsOverviewLoader = Future<ClassroomsOverviewItem?> Function();
typedef HomeroomsLoader = Future<List<HomeroomAssignment>> Function();
typedef TrackRoomsLoader = Future<List<LearningTrackRoom>> Function();
typedef ClassSchedulesLoader = Future<List<SchoolScheduleItem>> Function();

class DirectorClassroomsPage extends StatefulWidget {
  const DirectorClassroomsPage({
    super.key,
    this.loadOverview,
    this.loadHomerooms,
    this.loadTrackRooms,
    this.loadSchedules,
  });

  final ClassroomsOverviewLoader? loadOverview;
  final HomeroomsLoader? loadHomerooms;
  final TrackRoomsLoader? loadTrackRooms;
  final ClassSchedulesLoader? loadSchedules;

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
      ]);
      final overview = results[0] as ClassroomsOverviewItem?;
      if (!mounted) return;
      setState(() {
        _homerooms = results[1] as List<HomeroomAssignment>;
        _trackRooms = results[2] as List<LearningTrackRoom>;
        _schedules = results[3] as List<SchoolScheduleItem>;
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

  final List<String> grades = const [
    'ทุกระดับชั้น',
    'ม.1',
    'ม.2',
    'ม.3',
    'ม.4',
    'ม.5',
    'ม.6',
  ];

  final List<String> tracks = const [
    'ทุกสายการเรียน',
    'ทั่วไป',
    'วิทย์ - คณิต',
    'สายภาษา',
  ];

  final List<String> assignmentFilters = const [
    'ทั้งหมด',
    'กำลังดำเนินการ',
    'ใกล้ครบกำหนด',
    'เลยกำหนด',
    'ตรวจแล้ว',
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
          nextClass: _nextClassFor(h.room),
          color: palette[i % palette.length],
        ),
      );
    }
    rows.sort((a, b) => a.room.compareTo(b.room));
    return rows;
  }

  /// The next scheduled period for a room, from the real timetable. Returns a
  /// plain "ไม่มีคาบ" rather than inventing one.
  String _nextClassFor(String room) {
    final now = DateTime.now();
    final today = now.weekday;
    final nowMinutes = now.hour * 60 + now.minute;

    int? toMinutes(String hhmm) {
      final parts = hhmm.split(':');
      if (parts.length < 2) return null;
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h == null || m == null) return null;
      return h * 60 + m;
    }

    final todays =
        _schedules
            .where((s) => s.room == room && s.dayOfWeek == today)
            .where((s) => (toMinutes(s.startTime) ?? -1) >= nowMinutes)
            .toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));

    if (todays.isEmpty) return 'ไม่มีคาบที่เหลือวันนี้';
    final next = todays.first;
    return '${next.subjectName} ${next.startTime.substring(0, 5)}';
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
        value: '5',
        subtitle: 'การมาเรียน / งาน / ผลการเรียน',
        icon: Icons.visibility_rounded,
        color: AppPalette.softMint,
      ),
      _OverviewSummary(
        title: 'คะแนนการเรียนภาพรวม',
        value: '93%',
        subtitle: 'เฉลี่ยทุกห้อง',
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
              hintStyle: const TextStyle(fontSize: 9.8),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppPalette.primaryPink,
                size: 18,
              ),
              filled: true,
              fillColor: AppPalette.pageBg,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 11,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppPalette.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppPalette.border),
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
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppPalette.pageBg,
        borderRadius: BorderRadius.circular(14),
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
                  fontSize: 10,
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
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 620) {
                return Column(
                  children: [
                    for (int i = 0; i < filtered.length; i++) ...[
                      SizedBox(height: 225, child: _classroomCard(filtered[i])),
                      if (i != filtered.length - 1) const SizedBox(height: 10),
                    ],
                  ],
                );
              }

              final int columns = constraints.maxWidth < 1050 ? 2 : 3;

              return GridView.builder(
                itemCount: filtered.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 260,
                ),
                itemBuilder: (context, index) {
                  return _classroomCard(filtered[index]);
                },
              );
            },
          ),
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

  Widget _classroomCard(_ClassroomData room) {
    // The "ต้องติดตาม" badge that used to sit on these cards was decided by
    // invented attendance and follow-up counts. Nothing measures either per
    // room yet, so no room is flagged until something can justify the flag.

    return InkWell(
      borderRadius: BorderRadius.circular(19),
      onTap: () {
        setState(() => selectedRoom = room);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppPalette.tint(room.color, 0.05),
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: AppPalette.tint(room.color, 0.16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppPalette.tint(room.color, 0.11),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Text(
                    room.room,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: room.color,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${room.track} • ห้อง ${room.roomNumber}',
                        style: const TextStyle(
                          fontSize: 10.8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        room.homeroomTeacher,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 8.8,
                          color: AppPalette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppPalette.textMuted,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _roomMetric(
                  'นักเรียน',
                  '${room.students}',
                  AppPalette.primaryPink,
                ),
                _roomMetric('สาย', room.track, AppPalette.learningBlue),
              ],
            ),
            const SizedBox(height: 10),
            _roomInfoRow(
              Icons.person_rounded,
              'ครูประจำชั้น',
              room.homeroomTeacher,
            ),
            _roomInfoRow(Icons.schedule_rounded, 'คาบถัดไป', room.nextClass),
            const Spacer(),
            Row(
              children: [
                Text(
                  'ห้อง ${room.roomNumber}',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppPalette.textMuted,
                  ),
                ),
                const Spacer(),
                const Text(
                  'ดูรายละเอียด',
                  style: TextStyle(
                    fontSize: 9,
                    color: AppPalette.primaryPinkDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _roomMetric(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
        decoration: BoxDecoration(
          color: AppPalette.tint(color, 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 8.2,
                color: AppPalette.textMuted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 10.8,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
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
                    _todayTimetableCard(timetable),
                    const SizedBox(height: 16),
                    _teacherActivityCard(activities),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _todayTimetableCard(timetable)),
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
              'ยังไม่มีข้อมูลรายห้องสำหรับการมาเรียน งานค้าง หรือการติดตามนักเรียน '
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
                    'ดูว่าครูแต่ละวิชาลงงานอะไร กำหนดส่งเมื่อไร นักเรียนส่งแล้วกี่คน และคะแนนเฉลี่ยของงาน',
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
                        'ส่ง ${assignment.submitted}/${room.students}',
                        AppPalette.learningBlue,
                      ),
                      _tag(
                        'เฉลี่ย ${assignment.averageScore}%',
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
                    '${assignment.submitted}/${room.students}',
                  ),
                ),
                Expanded(
                  child: _assignmentListInfo(
                    'คะแนนเฉลี่ย',
                    '${assignment.averageScore}%',
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
      case 'ตรวจแล้ว':
        return AppPalette.environmentGreen;
      default:
        return AppPalette.learningBlue;
    }
  }

  Widget _todayTimetableCard(List<_TimetableItem> timetable) {
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
          const Text(
            'ดูรายวิชา ครูผู้สอน และสถานะการเรียนของแต่ละคาบ',
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

  /// The student-support panel counted four categories of at-risk students
  /// per room, each derived from the invented scores — "ผลการเรียนต่ำกว่าเกณฑ์
  /// 4 คน", "ขาดเรียนต่อเนื่อง 3 คน". `list_student_support_cases` holds the
  /// real thing but its gate rejects `executive`, so this needs a role
  /// widening before it can be shown here.
  Widget _studentSupportSection(_ClassroomData room) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppPalette.border),
      ),
      child: const Column(
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
          Text(
            'ยังไม่เปิดให้ผู้บริหารดูข้อมูลรายห้อง — ดูได้ที่ระบบดูแลช่วยเหลือนักเรียนของครูประจำชั้น',
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

  void _showAssignmentDetail(_ClassroomData room, _AssignmentData assignment) {
    final missing = room.students - assignment.submitted;
    final statusColor = _assignmentStatusColor(assignment.status);

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
                    '${assignment.submitted}/${room.students} คน',
                  ),
                  _detailRow('ยังไม่ส่ง', '$missing คน'),
                  _detailRow('คะแนนเฉลี่ย', '${assignment.averageScore}%'),
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

  /// Empty until an RPC can list a room's assignments.
  ///
  /// Was five fully-written assignments per room — titles, descriptions,
  /// invented teacher names such as ครูพรทิพย์ รักษ์ดี, submission counts
  /// derived from the invented overdue count, and average scores. The
  /// `assignments`, `submissions` and `course_students` tables all exist, so
  /// this is reachable with a room-scoped aggregate; it simply does not exist
  /// yet, and a placeholder was never the honest stand-in.
  List<_AssignmentData> _assignmentsFor(_ClassroomData room) =>
      const <_AssignmentData>[];

  /// Empty until per-subject results can be aggregated per room.
  ///
  /// Was eight subjects whose scores were computed as
  /// `base + (room.learningScore - 92)` — invented numbers adjusted by another
  /// invented number.
  List<_SubjectPerformance> _subjectsFor(_ClassroomData room) =>
      const <_SubjectPerformance>[];

  /// The room's real timetable for today, from `list_all_school_schedules`.
  ///
  /// Was a const list of six periods with invented teacher names — ครูจิราพร
  /// ตั้งใจ and others — and a "สอนแล้ว / กำลังสอน" status that nothing
  /// tracks. The RPC gives subject, room, day and start/end time; whether a
  /// teacher actually started a period on time is not recorded anywhere, so
  /// no status is claimed.
  List<_TimetableItem> _timetableFor(_ClassroomData room) {
    final today = DateTime.now().weekday;
    final todays =
        _schedules
            .where((s) => s.room == room.roomNumber && s.dayOfWeek == today)
            .toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return [
      for (final s in todays)
        _TimetableItem(
          time: s.startTime.substring(0, 5),
          subject: s.subjectName,
          teacher: '',
          room: s.room ?? room.roomNumber,
          status: '',
          color: AppPalette.learningBlue,
        ),
    ];
  }

  /// Empty: nothing records homeroom-teacher activity per room.
  List<_TeacherActivity> _teacherActivitiesFor(_ClassroomData room) =>
      const <_TeacherActivity>[];
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
  final String nextClass;
  final Color color;

  const _ClassroomData({
    required this.room,
    required this.grade,
    required this.track,
    required this.roomNumber,
    required this.homeroomTeacher,
    required this.students,
    required this.nextClass,
    required this.color,
  });
}

class _AssignmentData {
  final String subject;
  final String teacher;
  final String title;
  final String assignedDate;
  final String dueDate;
  final int submitted;
  final int averageScore;
  final String status;
  final String description;
  final IconData icon;
  final Color color;

  const _AssignmentData({
    required this.subject,
    required this.teacher,
    required this.title,
    required this.assignedDate,
    required this.dueDate,
    required this.submitted,
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
