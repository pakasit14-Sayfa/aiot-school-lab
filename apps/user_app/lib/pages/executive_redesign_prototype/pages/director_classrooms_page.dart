import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import '../theme/app_palette.dart';
import '../widgets/director_common_widgets.dart';

class DirectorClassroomsPage extends StatefulWidget {
  const DirectorClassroomsPage({super.key});

  @override
  State<DirectorClassroomsPage> createState() =>
      _DirectorClassroomsPageState();
}

class _DirectorClassroomsPageState
    extends State<DirectorClassroomsPage> {
  _ClassroomData? selectedRoom;

  ClassroomsOverviewItem? _overview;

  // Loading and failure used to be indistinguishable from real data: the
  // summary tiles fell back to the hardcoded '36' / '1,248' / '64' whenever
  // _overview was null, so a failed load silently showed a director invented
  // numbers as if they were this school's.
  bool _overviewLoading = true;
  bool _overviewFailed = false;

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
      final overview = await ExecutiveService.getClassroomsOverview();
      if (!mounted) return;
      setState(() {
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

  final List<_ClassroomData> classrooms = const [
    _ClassroomData(
      room: 'ม.1/1',
      grade: 'ม.1',
      track: 'ทั่วไป',
      roomNumber: '101',
      homeroomTeacher: 'ครูพิมพ์ชนก รุ่งเรือง',
      students: 36,
      attendance: 95,
      learningScore: 92,
      behaviorScore: 94,
      environmentScore: 93,
      assignmentsThisWeek: 8,
      overdueStudents: 4,
      followUpStudents: 3,
      nextClass: 'คณิตศาสตร์ 10:20 น.',
      color: AppPalette.chartPink,
    ),
    _ClassroomData(
      room: 'ม.1/2',
      grade: 'ม.1',
      track: 'ทั่วไป',
      roomNumber: '102',
      homeroomTeacher: 'ครูสมชาย ใจดี',
      students: 35,
      attendance: 94,
      learningScore: 91,
      behaviorScore: 93,
      environmentScore: 94,
      assignmentsThisWeek: 7,
      overdueStudents: 5,
      followUpStudents: 4,
      nextClass: 'วิทยาศาสตร์ 11:10 น.',
      color: AppPalette.learningBlue,
    ),
    _ClassroomData(
      room: 'ม.2/1',
      grade: 'ม.2',
      track: 'ทั่วไป',
      roomNumber: '201',
      homeroomTeacher: 'ครูอรทัย พัฒนกิจ',
      students: 36,
      attendance: 96,
      learningScore: 94,
      behaviorScore: 92,
      environmentScore: 95,
      assignmentsThisWeek: 9,
      overdueStudents: 2,
      followUpStudents: 2,
      nextClass: 'ภาษาอังกฤษ 09:30 น.',
      color: AppPalette.environmentGreen,
    ),
    _ClassroomData(
      room: 'ม.2/2',
      grade: 'ม.2',
      track: 'ทั่วไป',
      roomNumber: '202',
      homeroomTeacher: 'ครูศุภชัย สายดี',
      students: 34,
      attendance: 93,
      learningScore: 90,
      behaviorScore: 91,
      environmentScore: 93,
      assignmentsThisWeek: 8,
      overdueStudents: 6,
      followUpStudents: 5,
      nextClass: 'ภาษาไทย 13:00 น.',
      color: AppPalette.chartCream,
    ),
    _ClassroomData(
      room: 'ม.3/1',
      grade: 'ม.3',
      track: 'ทั่วไป',
      roomNumber: '301',
      homeroomTeacher: 'ครูนันต์ พัฒนกิจ',
      students: 35,
      attendance: 88,
      learningScore: 91,
      behaviorScore: 90,
      environmentScore: 94,
      assignmentsThisWeek: 10,
      overdueStudents: 9,
      followUpStudents: 6,
      nextClass: 'สังคมศึกษา 10:20 น.',
      color: AppPalette.warning,
    ),
    _ClassroomData(
      room: 'ม.3/2',
      grade: 'ม.3',
      track: 'ทั่วไป',
      roomNumber: '302',
      homeroomTeacher: 'ครูจิราพร ตั้งใจ',
      students: 35,
      attendance: 92,
      learningScore: 89,
      behaviorScore: 91,
      environmentScore: 92,
      assignmentsThisWeek: 9,
      overdueStudents: 7,
      followUpStudents: 5,
      nextClass: 'คณิตศาสตร์ 14:00 น.',
      color: AppPalette.chartPink2,
    ),
    _ClassroomData(
      room: 'ม.4/1',
      grade: 'ม.4',
      track: 'วิทย์ - คณิต',
      roomNumber: '401',
      homeroomTeacher: 'ครูกิตติศักดิ์ แสงทอง',
      students: 32,
      attendance: 95,
      learningScore: 96,
      behaviorScore: 94,
      environmentScore: 92,
      assignmentsThisWeek: 11,
      overdueStudents: 3,
      followUpStudents: 2,
      nextClass: 'ฟิสิกส์ 09:30 น.',
      color: AppPalette.primaryPink,
    ),
    _ClassroomData(
      room: 'ม.4/2',
      grade: 'ม.4',
      track: 'สายภาษา',
      roomNumber: '402',
      homeroomTeacher: 'ครูพรทิพย์ รักษ์ดี',
      students: 31,
      attendance: 93,
      learningScore: 92,
      behaviorScore: 93,
      environmentScore: 95,
      assignmentsThisWeek: 10,
      overdueStudents: 4,
      followUpStudents: 3,
      nextClass: 'ภาษาจีน 11:10 น.',
      color: AppPalette.learningBlue,
    ),
    _ClassroomData(
      room: 'ม.5/1',
      grade: 'ม.5',
      track: 'วิทย์ - คณิต',
      roomNumber: '501',
      homeroomTeacher: 'ครูธนภัทร พงษ์ดี',
      students: 33,
      attendance: 91,
      learningScore: 94,
      behaviorScore: 92,
      environmentScore: 91,
      assignmentsThisWeek: 12,
      overdueStudents: 8,
      followUpStudents: 6,
      nextClass: 'เคมี 13:00 น.',
      color: AppPalette.chartPink,
    ),
    _ClassroomData(
      room: 'ม.5/2',
      grade: 'ม.5',
      track: 'สายภาษา',
      roomNumber: '502',
      homeroomTeacher: 'ครูวิภา สายภาษา',
      students: 31,
      attendance: 90,
      learningScore: 89,
      behaviorScore: 90,
      environmentScore: 93,
      assignmentsThisWeek: 10,
      overdueStudents: 9,
      followUpStudents: 8,
      nextClass: 'ภาษาอังกฤษ 14:00 น.',
      color: AppPalette.warning,
    ),
    _ClassroomData(
      room: 'ม.6/1',
      grade: 'ม.6',
      track: 'วิทย์ - คณิต',
      roomNumber: '601',
      homeroomTeacher: 'ครูปณิธาน เก่งวิทย์',
      students: 34,
      attendance: 86,
      learningScore: 95,
      behaviorScore: 94,
      environmentScore: 95,
      assignmentsThisWeek: 9,
      overdueStudents: 5,
      followUpStudents: 5,
      nextClass: 'คณิตศาสตร์ 10:20 น.',
      color: AppPalette.danger,
    ),
    _ClassroomData(
      room: 'ม.6/2',
      grade: 'ม.6',
      track: 'สายภาษา',
      roomNumber: '602',
      homeroomTeacher: 'ครูอริสา ภาษาดี',
      students: 32,
      attendance: 92,
      learningScore: 93,
      behaviorScore: 95,
      environmentScore: 96,
      assignmentsThisWeek: 8,
      overdueStudents: 3,
      followUpStudents: 3,
      nextClass: 'ภาษาจีน 09:30 น.',
      color: AppPalette.environmentGreen,
    ),
  ];

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

  final List<_GreenScore> greenScores = const [
    _GreenScore('ม.6/1', '6/1', 'วิทย์-คณิต', 96, _Trend.up,
        AppPalette.primaryPink),
    _GreenScore('ม.5/2', '5/2', 'ศิลป์-ภาษา', 94, _Trend.up,
        AppPalette.learningBlue),
    _GreenScore('ม.4/1', '4/1', 'วิทย์-คณิต', 92, _Trend.down,
        AppPalette.chartCream),
    _GreenScore('ม.6/2', '6/2', 'ศิลป์-คำนวณ', 90, _Trend.up,
        AppPalette.heroPink),
    _GreenScore('ม.3/1', '3/1', 'ทั่วไป', 88, _Trend.same,
        AppPalette.behaviorYellow),
    _GreenScore('ม.5/1', '5/1', 'วิทย์-คณิต', 86, _Trend.down,
        AppPalette.chartPink2),
    _GreenScore('ม.2/2', '2/2', 'ทั่วไป', 84, _Trend.up,
        AppPalette.chartBlue),
    _GreenScore('ม.1/1', '1/1', 'ทั่วไป', 82, _Trend.same,
        AppPalette.primaryPinkDark),
  ];

  Widget _greenScoreSection() {
    final top3 = greenScores.take(3).toList();
    final rest = greenScores.skip(3).toList();

    return Container(
      width: double.infinity,
      decoration: directorWhiteCard(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppPalette.tint(AppPalette.primaryPink, 0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: AppPalette.primaryPink,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 11),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ภาพรวมห้องเรียนที่ดีที่สุด',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'จัดอันดับจากการมาเรียน ผลการเรียน พฤติกรรม และการส่งงาน • คะแนนเต็ม 100',
                        style: TextStyle(
                          fontSize: 9.5,
                          color: AppPalette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppPalette.tint(AppPalette.primaryPink, 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'เดือนนี้',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: AppPalette.primaryPinkDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFDF0F6), Color(0xFFF8DEEA)],
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: _podiumItem(top3[1], 2)),
                const SizedBox(width: 8),
                Expanded(child: _podiumItem(top3[0], 1, big: true)),
                const SizedBox(width: 8),
                Expanded(child: _podiumItem(top3[2], 3)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
            child: Column(
              children: [
                for (int i = 0; i < rest.length; i++)
                  _greenRankRow(rest[i], i + 4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _podiumItem(_GreenScore room, int rank, {bool big = false}) {
    final medal = rank == 1
        ? const Color(0xFFE3B341)
        : rank == 2
            ? const Color(0xFFA9BCC9)
            : const Color(0xFFCB9A6B);
    final avatarSize = big ? 60.0 : 48.0;
    final pedestalHeight = rank == 1
        ? 68.0
        : rank == 2
            ? 50.0
            : 38.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (big)
          const Padding(
            padding: EdgeInsets.only(bottom: 3),
            child: Icon(
              Icons.workspace_premium_rounded,
              size: 22,
              color: Color(0xFFE3B341),
            ),
          ),
        SizedBox(
          height: avatarSize + 10,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Container(
                width: avatarSize,
                height: avatarSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppPalette.tint(room.color, 0.16),
                  shape: BoxShape.circle,
                  border: Border.all(color: medal, width: 2.5),
                ),
                child: Text(
                  room.short,
                  style: TextStyle(
                    fontSize: big ? 15 : 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppPalette.textDark,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                child: Container(
                  width: 21,
                  height: 21,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: medal,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Text(
                    '$rank',
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 7),
        Text(
          room.room,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: big ? 12.5 : 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          room.track,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 8.2,
            color: AppPalette.textMuted,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppPalette.tint(AppPalette.primaryPink, 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${room.score}',
                style: TextStyle(
                  fontSize: big ? 13.5 : 12,
                  fontWeight: FontWeight.w800,
                  color: AppPalette.primaryPinkDark,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 1),
                child: Text(
                  ' /100',
                  style: TextStyle(
                    fontSize: 7.5,
                    fontWeight: FontWeight.w700,
                    color: AppPalette.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: pedestalHeight,
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                medal,
                AppPalette.tint(medal, 0.55),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            boxShadow: [
              BoxShadow(
                color: AppPalette.tint(medal, 0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            '$rank',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _greenRankRow(_GreenScore room, int rank) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppPalette.pageBg,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppPalette.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              rank < 10 ? '0$rank' : '$rank',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppPalette.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppPalette.tint(room.color, 0.16),
              shape: BoxShape.circle,
            ),
            child: Text(
              room.short,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: AppPalette.textDark,
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room.room,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  room.track,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 8.6,
                    color: AppPalette.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${room.score}',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: AppPalette.primaryPinkDark,
            ),
          ),
          const SizedBox(width: 2),
          const Padding(
            padding: EdgeInsets.only(bottom: 1),
            child: Text(
              '/100',
              style: TextStyle(fontSize: 8, color: AppPalette.textMuted),
            ),
          ),
          const SizedBox(width: 8),
          _trendIcon(room.trend),
        ],
      ),
    );
  }

  Widget _trendIcon(_Trend trend) {
    switch (trend) {
      case _Trend.up:
        return const Icon(
          Icons.arrow_drop_up_rounded,
          color: AppPalette.success,
          size: 24,
        );
      case _Trend.down:
        return const Icon(
          Icons.arrow_drop_down_rounded,
          color: AppPalette.danger,
          size: 24,
        );
      case _Trend.same:
        return const Icon(
          Icons.remove_rounded,
          color: AppPalette.textMuted,
          size: 15,
        );
    }
  }

  List<_ClassroomData> _filteredClassrooms() {
    final query = searchText.trim().toLowerCase();

    return classrooms.where((room) {
      final matchesSearch = query.isEmpty ||
          room.room.toLowerCase().contains(query) ||
          room.roomNumber.toLowerCase().contains(query) ||
          room.homeroomTeacher.toLowerCase().contains(query) ||
          room.track.toLowerCase().contains(query);

      final matchesGrade =
          selectedGrade == 'ทุกระดับชั้น' ||
          room.grade == selectedGrade;

      final matchesTrack =
          selectedTrack == 'ทุกสายการเรียน' ||
          room.track == selectedTrack;

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
          gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(
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
              hintText:
                  'ค้นหาห้อง เช่น ม.1/1, เลขห้อง หรือครูประจำชั้น...',
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
                borderSide:
                    const BorderSide(color: AppPalette.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: AppPalette.border),
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
              Expanded(
                flex: 3,
                child: search,
              ),
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
          Icon(
            icon,
            size: 17,
            color: AppPalette.primaryPink,
          ),
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
                        child: Text(
                          item,
                          overflow: TextOverflow.ellipsis,
                        ),
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
                      SizedBox(
                        height: 225,
                        child: _classroomCard(filtered[i]),
                      ),
                      if (i != filtered.length - 1)
                        const SizedBox(height: 10),
                    ],
                  ],
                );
              }

              final int columns =
                  constraints.maxWidth < 1050 ? 2 : 3;

              return GridView.builder(
                itemCount: filtered.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    SliverGridDelegateWithFixedCrossAxisCount(
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
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 30,
              ),
              alignment: Alignment.center,
              child: const Text(
                'ไม่พบห้องเรียนตามเงื่อนไข',
                style: TextStyle(
                  fontSize: 10.5,
                  color: AppPalette.textMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _classroomCard(_ClassroomData room) {
    final needsAttention = room.attendance < 92 ||
        room.overdueStudents >= 8 ||
        room.followUpStudents >= 6;

    return InkWell(
      borderRadius: BorderRadius.circular(19),
      onTap: () {
        setState(() => selectedRoom = room);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: needsAttention
              ? AppPalette.tint(AppPalette.warning, 0.05)
              : AppPalette.tint(room.color, 0.05),
          borderRadius: BorderRadius.circular(19),
          border: Border.all(
            color: needsAttention
                ? AppPalette.tint(AppPalette.warning, 0.22)
                : AppPalette.tint(room.color, 0.16),
          ),
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
                if (needsAttention)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppPalette.tint(
                        AppPalette.warning,
                        0.12,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'ควรติดตาม',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: AppPalette.warning,
                      ),
                    ),
                  )
                else
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
                _roomMetric(
                  'มาเรียน',
                  '${room.attendance}%',
                  AppPalette.learningBlue,
                ),
                _roomMetric(
                  'การเรียน',
                  '${room.learningScore}%',
                  AppPalette.environmentGreen,
                ),
              ],
            ),
            const SizedBox(height: 10),
            _roomInfoRow(
              Icons.assignment_rounded,
              'งานสัปดาห์นี้',
              '${room.assignmentsThisWeek} งาน',
            ),
            _roomInfoRow(
              Icons.assignment_late_rounded,
              'ค้าง/ส่งช้า',
              '${room.overdueStudents} คน',
            ),
            _roomInfoRow(
              Icons.schedule_rounded,
              'คาบถัดไป',
              room.nextClass,
            ),
            const Spacer(),
            Row(
              children: [
                Text(
                  'ติดตาม ${room.followUpStudents} คน',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: room.followUpStudents >= 6
                        ? AppPalette.warning
                        : AppPalette.environmentGreen,
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

  Widget _roomMetric(
    String label,
    String value,
    Color color,
  ) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(
          horizontal: 7,
          vertical: 8,
        ),
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

  Widget _roomInfoRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: AppPalette.textMuted,
          ),
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
    final filteredAssignments =
        selectedAssignmentFilter == 'ทั้งหมด'
            ? assignments
            : assignments
                .where(
                  (item) =>
                      item.status == selectedAssignmentFilter,
                )
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
                    child: _learningOverviewCard(
                      room,
                      subjects,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 4,
                    child: _directorAttentionCard(room),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 16),
          _assignmentsSection(
            room,
            filteredAssignments,
          ),
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
                  Expanded(
                    child: _todayTimetableCard(timetable),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _teacherActivityCard(activities),
                  ),
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
                  style: TextStyle(
                    fontSize: 9.5,
                    color: AppPalette.textMuted,
                  ),
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
      _DetailSummary(
        title: 'มาเรียนวันนี้',
        value: '${room.attendance}%',
        subtitle:
            '${((room.students * room.attendance) / 100).round()} คน',
        icon: Icons.how_to_reg_rounded,
        color: AppPalette.softBlue,
      ),
      _DetailSummary(
        title: 'ภาพรวมการเรียน',
        value: '${room.learningScore}%',
        subtitle: 'คะแนนเฉลี่ยห้อง',
        icon: Icons.analytics_rounded,
        color: AppPalette.softMint,
      ),
      _DetailSummary(
        title: 'งานสัปดาห์นี้',
        value: '${room.assignmentsThisWeek}',
        subtitle: 'ทุกวิชารวมกัน',
        icon: Icons.assignment_rounded,
        color: AppPalette.softCream,
      ),
      _DetailSummary(
        title: 'ส่งช้า / ค้าง',
        value: '${room.overdueStudents}',
        subtitle: 'นักเรียน',
        icon: Icons.assignment_late_rounded,
        color: AppPalette.softPink2,
      ),
      _DetailSummary(
        title: 'ต้องติดตาม',
        value: '${room.followUpStudents}',
        subtitle: 'นักเรียน',
        icon: Icons.visibility_rounded,
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
          gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(
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
                  Icon(
                    item.icon,
                    size: 18,
                    color: AppPalette.textDark,
                  ),
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
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'เปรียบเทียบคะแนนเฉลี่ยของแต่ละรายวิชา เพื่อดูว่าวิชาใดอยู่ในเกณฑ์ดีและวิชาใดควรติดตาม',
            style: TextStyle(
              fontSize: 10,
              color: AppPalette.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          ...subjects.map(
            (subject) => _subjectProgress(subject),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: AppPalette.tint(
                room.learningScore >= 93
                    ? AppPalette.environmentGreen
                    : AppPalette.warning,
                0.08,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              room.learningScore >= 93
                  ? 'ภาพรวมการเรียนของห้องอยู่ในเกณฑ์ดี ควรรักษาระดับและติดตามเฉพาะรายวิชาที่คะแนนต่ำกว่าค่าเฉลี่ย'
                  : 'ภาพรวมการเรียนมีบางรายวิชาที่ควรติดตาม แนะนำให้ดูงานค้างและนักเรียนที่คะแนนต่ำกว่าเกณฑ์เพิ่มเติม',
              style: const TextStyle(
                fontSize: 9.5,
                height: 1.4,
                color: AppPalette.textMuted,
              ),
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
                valueColor:
                    AlwaysStoppedAnimation<Color>(color),
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

  Widget _directorAttentionCard(_ClassroomData room) {
    final issues = <_AttentionItem>[
      _AttentionItem(
        title: 'งานค้าง / ส่งช้า',
        detail:
            '${room.overdueStudents} คนมีงานที่ยังไม่ส่งหรือส่งเกินกำหนด ควรให้ครูประจำชั้นติดตามร่วมกับครูผู้สอน',
        status: room.overdueStudents >= 8
            ? 'ควรติดตาม'
            : 'เฝ้าดู',
        color: room.overdueStudents >= 8
            ? AppPalette.warning
            : AppPalette.learningBlue,
        icon: Icons.assignment_late_rounded,
      ),
      _AttentionItem(
        title: 'การมาเรียน',
        detail:
            'วันนี้มาเรียน ${room.attendance}% หากต่ำกว่า 92% ควรตรวจสอบนักเรียนขาดเรียนต่อเนื่องและการลาป่วย',
        status: room.attendance < 92
            ? 'ควรตรวจสอบ'
            : 'ปกติ',
        color: room.attendance < 92
            ? AppPalette.warning
            : AppPalette.environmentGreen,
        icon: Icons.how_to_reg_rounded,
      ),
      _AttentionItem(
        title: 'นักเรียนที่ต้องดูแล',
        detail:
            '${room.followUpStudents} คนอยู่ในกลุ่มติดตามด้านการเรียน การมาเรียน หรือพฤติกรรม',
        status: room.followUpStudents >= 6
            ? 'สำคัญ'
            : 'ติดตาม',
        color: room.followUpStudents >= 6
            ? AppPalette.danger
            : AppPalette.chartPink,
        icon: Icons.visibility_rounded,
      ),
      _AttentionItem(
        title: 'สภาพแวดล้อมในห้อง',
        detail:
            'คะแนนการดูแลห้องเรียน ${room.environmentScore}% ครอบคลุมความสะอาด การจัดโต๊ะ และการใช้ทรัพยากร',
        status: room.environmentScore >= 93
            ? 'ปกติ'
            : 'ควรปรับปรุง',
        color: room.environmentScore >= 93
            ? AppPalette.environmentGreen
            : AppPalette.warning,
        icon: Icons.cleaning_services_rounded,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'สิ่งที่ผู้อำนวยการควรทราบ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'สรุปเฉพาะประเด็นสำคัญของห้องนี้ ไม่ต้องเปิดดูรายชื่อนักเรียนทั้งหมด',
            style: TextStyle(
              fontSize: 10,
              color: AppPalette.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          ...issues.map(_attentionTile),
        ],
      ),
    );
  }

  Widget _attentionTile(_AttentionItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppPalette.tint(item.color, 0.06),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: AppPalette.tint(item.color, 0.14),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              item.icon,
              size: 17,
              color: item.color,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            AppPalette.tint(item.color, 0.11),
                        borderRadius:
                            BorderRadius.circular(20),
                      ),
                      child: Text(
                        item.status,
                        style: TextStyle(
                          fontSize: 7.8,
                          fontWeight: FontWeight.w700,
                          color: item.color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  item.detail,
                  style: const TextStyle(
                    fontSize: 8.8,
                    height: 1.4,
                    color: AppPalette.textMuted,
                  ),
                ),
              ],
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'ดูว่าครูแต่ละวิชาลงงานอะไร กำหนดส่งเมื่อไร นักเรียนส่งแล้วกี่คน และคะแนนเฉลี่ยของงาน',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppPalette.textMuted,
                    ),
                  ),
                ],
              );

              final filter = _assignmentFilterDropdown();

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    heading,
                    const SizedBox(height: 10),
                    filter,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: heading),
                  SizedBox(
                    width: 190,
                    child: filter,
                  ),
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
                style: TextStyle(
                  fontSize: 10,
                  color: AppPalette.textMuted,
                ),
              ),
            )
          else
            ...assignments.map(
              (assignment) =>
                  _assignmentTile(room, assignment),
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
                  child: Text(
                    item,
                    style: const TextStyle(fontSize: 9.5),
                  ),
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

  Widget _assignmentTile(
    _ClassroomData room,
    _AssignmentData assignment,
  ) {
    final statusColor = _assignmentStatusColor(
      assignment.status,
    );

    return InkWell(
      borderRadius: BorderRadius.circular(17),
      onTap: () => _showAssignmentDetail(
        room,
        assignment,
      ),
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
                      Expanded(
                        child: _assignmentMainInfo(
                          assignment,
                        ),
                      ),
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
                      _tag(
                        assignment.status,
                        statusColor,
                      ),
                    ],
                  ),
                ],
              );
            }

            return Row(
              children: [
                _assignmentIcon(assignment),
                const SizedBox(width: 11),
                Expanded(
                  flex: 3,
                  child: _assignmentMainInfo(assignment),
                ),
                Expanded(
                  child: _assignmentListInfo(
                    'กำหนดส่ง',
                    assignment.dueDate,
                  ),
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
                    color:
                        AppPalette.tint(statusColor, 0.10),
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
      child: Icon(
        assignment.icon,
        color: assignment.color,
        size: 20,
      ),
    );
  }

  Widget _assignmentMainInfo(
    _AssignmentData assignment,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          assignment.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 10.8,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${assignment.subject} • ${assignment.teacher}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 8.7,
            color: AppPalette.textMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'มอบหมาย ${assignment.assignedDate}',
          style: const TextStyle(
            fontSize: 8.2,
            color: AppPalette.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _assignmentListInfo(
    String label,
    String value,
  ) {
    return Column(
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
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 9.2,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _tag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
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

  Widget _todayTimetableCard(
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
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'ดูรายวิชา ครูผู้สอน และสถานะการเรียนของแต่ละคาบ',
            style: TextStyle(
              fontSize: 10,
              color: AppPalette.textMuted,
            ),
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
                  Container(
                    width: 1,
                    height: 38,
                    color: AppPalette.border,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
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

  Widget _teacherActivityCard(
    List<_TeacherActivity> activities,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'กิจกรรมล่าสุดของครูผู้สอน',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'ดูว่าครูลงงาน ตรวจงาน หรือบันทึกข้อมูลอะไรให้ห้องนี้ล่าสุด',
            style: TextStyle(
              fontSize: 10,
              color: AppPalette.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          ...activities.map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 9),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      color:
                          AppPalette.tint(item.color, 0.10),
                      borderRadius:
                          BorderRadius.circular(11),
                    ),
                    child: Icon(
                      item.icon,
                      size: 17,
                      color: item.color,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
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
    final supportItems = [
      _SupportItem(
        title: 'ผลการเรียนต่ำกว่าเกณฑ์',
        count: room.followUpStudents > 3 ? 4 : 2,
        detail:
            'มีคะแนนต่ำกว่า 70% อย่างน้อย 2 รายวิชา',
        icon: Icons.trending_down_rounded,
        color: AppPalette.chartPink,
      ),
      _SupportItem(
        title: 'งานค้างหลายวิชา',
        count: room.overdueStudents > 6 ? 5 : 2,
        detail:
            'มีงานค้างตั้งแต่ 3 งานขึ้นไปในสัปดาห์นี้',
        icon: Icons.assignment_late_rounded,
        color: AppPalette.warning,
      ),
      _SupportItem(
        title: 'ขาดเรียนต่อเนื่อง',
        count: room.attendance < 92 ? 3 : 1,
        detail:
            'ขาดเรียนเกินเกณฑ์ที่โรงเรียนกำหนด',
        icon: Icons.person_off_rounded,
        color: AppPalette.danger,
      ),
      _SupportItem(
        title: 'พฤติกรรมที่ต้องติดตาม',
        count: room.behaviorScore < 92 ? 3 : 1,
        detail:
            'มีบันทึกจากครูประจำชั้นหรือครูผู้สอน',
        icon: Icons.visibility_rounded,
        color: AppPalette.behaviorYellow,
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'นักเรียนที่ต้องติดตามในห้อง',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'สรุปเป็นประเภทเพื่อให้ผู้อำนวยการเห็นภาพรวม ไม่แสดงรายชื่อนักเรียนทั้งหมดในหน้าหลัก',
            style: TextStyle(
              fontSize: 10,
              color: AppPalette.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 620) {
                return Column(
                  children: [
                    for (int i = 0;
                        i < supportItems.length;
                        i++) ...[
                      _supportCard(supportItems[i]),
                      if (i != supportItems.length - 1)
                        const SizedBox(height: 9),
                    ],
                  ],
                );
              }

              return GridView.builder(
                itemCount: supportItems.length,
                shrinkWrap: true,
                physics:
                    const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  mainAxisExtent: 128,
                ),
                itemBuilder: (context, index) {
                  return _supportCard(
                    supportItems[index],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _supportCard(_SupportItem item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppPalette.tint(item.color, 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppPalette.tint(item.color, 0.14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            item.icon,
            size: 19,
            color: item.color,
          ),
          const Spacer(),
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${item.count} คน',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: item.color,
            ),
          ),
          Text(
            item.detail,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 7.8,
              color: AppPalette.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  void _showAssignmentDetail(
    _ClassroomData room,
    _AssignmentData assignment,
  ) {
    final missing = room.students - assignment.submitted;
    final statusColor =
        _assignmentStatusColor(assignment.status);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            assignment.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      _tag(
                        assignment.subject,
                        assignment.color,
                      ),
                      _tag(
                        assignment.status,
                        statusColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _detailRow(
                    'ครูผู้สอน',
                    assignment.teacher,
                  ),
                  _detailRow(
                    'มอบหมายวันที่',
                    assignment.assignedDate,
                  ),
                  _detailRow(
                    'กำหนดส่ง',
                    assignment.dueDate,
                  ),
                  _detailRow(
                    'ส่งแล้ว',
                    '${assignment.submitted}/${room.students} คน',
                  ),
                  _detailRow(
                    'ยังไม่ส่ง',
                    '$missing คน',
                  ),
                  _detailRow(
                    'คะแนนเฉลี่ย',
                    '${assignment.averageScore}%',
                  ),
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
              onPressed: () =>
                  Navigator.pop(dialogContext),
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
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MOCK DETAIL DATA
  // ---------------------------------------------------------------------------

  List<_AssignmentData> _assignmentsFor(
    _ClassroomData room,
  ) {
    final offset =
        int.tryParse(room.grade.replaceAll('ม.', '')) ?? 1;

    return [
      _AssignmentData(
        subject: 'คณิตศาสตร์',
        teacher: 'ครูอรทัย พัฒนกิจ',
        title: 'แบบฝึกหัดสมการและการแก้โจทย์',
        assignedDate: '19 ส.ค.',
        dueDate: '22 ส.ค.',
        submitted: (room.students - 3).clamp(
          0,
          room.students,
        ),
        averageScore: 88 + (offset % 4),
        status: 'ใกล้ครบกำหนด',
        description:
            'ทำแบบฝึกหัดท้ายบท พร้อมแสดงวิธีทำอย่างละเอียด ส่งผ่านระบบก่อนเวลา 18:00 น.',
        icon: Icons.calculate_rounded,
        color: AppPalette.learningBlue,
      ),
      _AssignmentData(
        subject: 'วิทยาศาสตร์',
        teacher: 'ครูกิตติศักดิ์ แสงทอง',
        title: 'สรุปผลการทดลองและตอบคำถามท้ายกิจกรรม',
        assignedDate: '18 ส.ค.',
        dueDate: '23 ส.ค.',
        submitted: (room.students - 5).clamp(
          0,
          room.students,
        ),
        averageScore: 91,
        status: 'กำลังดำเนินการ',
        description:
            'จัดทำสรุปผลการทดลองเป็นรายกลุ่ม แนบภาพผลการทดลองและตอบคำถามวิเคราะห์ท้ายกิจกรรม',
        icon: Icons.science_rounded,
        color: AppPalette.environmentGreen,
      ),
      _AssignmentData(
        subject: 'ภาษาอังกฤษ',
        teacher: 'ครูพรทิพย์ รักษ์ดี',
        title: 'Reading Reflection: My School Life',
        assignedDate: '17 ส.ค.',
        dueDate: '21 ส.ค.',
        submitted: (room.students - room.overdueStudents)
            .clamp(0, room.students),
        averageScore: 86,
        status: room.overdueStudents >= 6
            ? 'เลยกำหนด'
            : 'ใกล้ครบกำหนด',
        description:
            'อ่านบทความที่กำหนดและเขียน Reflection 150-200 คำ พร้อมคำศัพท์ใหม่อย่างน้อย 10 คำ',
        icon: Icons.translate_rounded,
        color: AppPalette.chartPink,
      ),
      _AssignmentData(
        subject: 'ภาษาไทย',
        teacher: 'ครูจิราพร ตั้งใจ',
        title: 'วิเคราะห์ใจความสำคัญจากบทอ่าน',
        assignedDate: '15 ส.ค.',
        dueDate: '19 ส.ค.',
        submitted: room.students,
        averageScore: 93,
        status: 'ตรวจแล้ว',
        description:
            'วิเคราะห์ใจความสำคัญ แนวคิด และข้อคิดจากบทอ่าน พร้อมเขียนสรุปด้วยภาษาของตนเอง',
        icon: Icons.menu_book_rounded,
        color: AppPalette.chartCream,
      ),
      _AssignmentData(
        subject: 'สังคมศึกษา',
        teacher: 'ครูวรพล ขยันงาน',
        title: 'Infographic สิทธิและหน้าที่ของพลเมือง',
        assignedDate: '20 ส.ค.',
        dueDate: '27 ส.ค.',
        submitted: (room.students - 8).clamp(
          0,
          room.students,
        ),
        averageScore: 0,
        status: 'กำลังดำเนินการ',
        description:
            'สร้าง Infographic เป็นรายคู่ สรุปสิทธิ หน้าที่ และตัวอย่างการเป็นพลเมืองที่ดีในโรงเรียน',
        icon: Icons.public_rounded,
        color: AppPalette.behaviorYellow,
      ),
    ];
  }

  List<_SubjectPerformance> _subjectsFor(
    _ClassroomData room,
  ) {
    final adjustment = room.learningScore - 92;

    int score(int base) =>
        (base + adjustment).clamp(70, 99);

    return [
      _SubjectPerformance(
        'ภาษาไทย',
        'ครูจิราพร ตั้งใจ',
        score(91),
      ),
      _SubjectPerformance(
        'คณิตศาสตร์',
        'ครูอรทัย พัฒนกิจ',
        score(89),
      ),
      _SubjectPerformance(
        'วิทยาศาสตร์',
        'ครูกิตติศักดิ์ แสงทอง',
        score(94),
      ),
      _SubjectPerformance(
        'สังคมศึกษา',
        'ครูวรพล ขยันงาน',
        score(90),
      ),
      _SubjectPerformance(
        'ภาษาอังกฤษ',
        'ครูพรทิพย์ รักษ์ดี',
        score(88),
      ),
    ];
  }

  List<_TimetableItem> _timetableFor(
    _ClassroomData room,
  ) {
    return const [
      _TimetableItem(
        time: '08:30',
        subject: 'ภาษาไทย',
        teacher: 'ครูจิราพร ตั้งใจ',
        room: 'ห้องเรียนประจำ',
        status: 'สอนแล้ว',
        color: AppPalette.environmentGreen,
      ),
      _TimetableItem(
        time: '09:30',
        subject: 'คณิตศาสตร์',
        teacher: 'ครูอรทัย พัฒนกิจ',
        room: 'ห้องเรียนประจำ',
        status: 'สอนแล้ว',
        color: AppPalette.environmentGreen,
      ),
      _TimetableItem(
        time: '10:20',
        subject: 'วิทยาศาสตร์',
        teacher: 'ครูกิตติศักดิ์ แสงทอง',
        room: 'ห้องปฏิบัติการ',
        status: 'กำลังสอน',
        color: AppPalette.primaryPink,
      ),
      _TimetableItem(
        time: '13:00',
        subject: 'ภาษาอังกฤษ',
        teacher: 'ครูพรทิพย์ รักษ์ดี',
        room: 'ห้องเรียนประจำ',
        status: 'รอสอน',
        color: AppPalette.learningBlue,
      ),
      _TimetableItem(
        time: '14:00',
        subject: 'สังคมศึกษา',
        teacher: 'ครูวรพล ขยันงาน',
        room: 'ห้องเรียนประจำ',
        status: 'รอสอน',
        color: AppPalette.learningBlue,
      ),
    ];
  }

  List<_TeacherActivity> _teacherActivitiesFor(
    _ClassroomData room,
  ) {
    return const [
      _TeacherActivity(
        title: 'ครูอรทัยลงงานคณิตศาสตร์ใหม่',
        detail:
            'แบบฝึกหัดสมการและการแก้โจทย์ กำหนดส่งวันที่ 22 ส.ค.',
        time: 'วันนี้ 08:12 น.',
        icon: Icons.assignment_rounded,
        color: AppPalette.learningBlue,
      ),
      _TeacherActivity(
        title: 'ครูจิราพรตรวจงานภาษาไทยครบแล้ว',
        detail:
            'ตรวจงานวิเคราะห์ใจความสำคัญครบทุกคน คะแนนเฉลี่ย 93%',
        time: 'เมื่อวาน 16:45 น.',
        icon: Icons.fact_check_rounded,
        color: AppPalette.environmentGreen,
      ),
      _TeacherActivity(
        title: 'ครูพรทิพย์แจ้งนักเรียนงานค้าง',
        detail:
            'มีนักเรียนบางส่วนยังไม่ส่ง Reading Reflection ระบบส่งแจ้งเตือนแล้ว',
        time: 'เมื่อวาน 14:10 น.',
        icon: Icons.notifications_active_rounded,
        color: AppPalette.warning,
      ),
      _TeacherActivity(
        title: 'ครูประจำชั้นบันทึกการติดตาม',
        detail:
            'อัปเดตนักเรียนที่ต้องดูแลด้านการมาเรียนและงานค้าง',
        time: '18 ส.ค. 15:30 น.',
        icon: Icons.edit_note_rounded,
        color: AppPalette.chartPink,
      ),
    ];
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

class _ClassroomData {
  final String room;
  final String grade;
  final String track;
  final String roomNumber;
  final String homeroomTeacher;
  final int students;
  final int attendance;
  final int learningScore;
  final int behaviorScore;
  final int environmentScore;
  final int assignmentsThisWeek;
  final int overdueStudents;
  final int followUpStudents;
  final String nextClass;
  final Color color;

  const _ClassroomData({
    required this.room,
    required this.grade,
    required this.track,
    required this.roomNumber,
    required this.homeroomTeacher,
    required this.students,
    required this.attendance,
    required this.learningScore,
    required this.behaviorScore,
    required this.environmentScore,
    required this.assignmentsThisWeek,
    required this.overdueStudents,
    required this.followUpStudents,
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

  const _SubjectPerformance(
    this.subject,
    this.teacher,
    this.score,
  );
}

class _AttentionItem {
  final String title;
  final String detail;
  final String status;
  final Color color;
  final IconData icon;

  const _AttentionItem({
    required this.title,
    required this.detail,
    required this.status,
    required this.color,
    required this.icon,
  });
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

class _SupportItem {
  final String title;
  final int count;
  final String detail;
  final IconData icon;
  final Color color;

  const _SupportItem({
    required this.title,
    required this.count,
    required this.detail,
    required this.icon,
    required this.color,
  });
}

enum _Trend { up, down, same }

class _GreenScore {
  final String room;
  final String short;
  final String track;
  final int score;
  final _Trend trend;
  final Color color;

  const _GreenScore(
    this.room,
    this.short,
    this.track,
    this.score,
    this.trend,
    this.color,
  );
}
