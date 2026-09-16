import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import '../theme/app_palette.dart';
import '../widgets/director_common_widgets.dart';

/// Read seams so loading / data / empty / failure can each be driven in a test.
typedef StaffDirectoryLoader = Future<List<StaffDirectoryEntry>> Function();
typedef DepartmentsLoader = Future<List<SchoolDepartment>> Function();
typedef StaffAttendanceSummaryLoader =
    Future<StaffAttendanceSummary?> Function();
typedef StaffLeaveLoader = Future<List<StaffLeaveRequest>> Function();
typedef PeriodsNeedingSubstituteLoader =
    Future<List<PeriodNeedingSubstitute>> Function(DateTime date);
typedef RecordSubstitutionFn =
    Future<String> Function({
      required String classScheduleId,
      required DateTime date,
      required String originalTeacherId,
      required String substituteTeacherId,
      String? note,
    });

class DirectorTeachersPage extends StatefulWidget {
  const DirectorTeachersPage({
    super.key,
    this.loadStaff,
    this.loadDepartments,
    this.loadAttendanceSummary,
    this.loadLeaveRequests,
    this.loadPeriodsNeedingSubstitute,
    this.recordSubstitution,
  });

  final StaffDirectoryLoader? loadStaff;
  final DepartmentsLoader? loadDepartments;
  final StaffAttendanceSummaryLoader? loadAttendanceSummary;
  final StaffLeaveLoader? loadLeaveRequests;
  final PeriodsNeedingSubstituteLoader? loadPeriodsNeedingSubstitute;
  final RecordSubstitutionFn? recordSubstitution;

  @override
  State<DirectorTeachersPage> createState() => _DirectorTeachersPageState();
}

class _DirectorTeachersPageState extends State<DirectorTeachersPage> {
  String searchText = '';
  String selectedDepartment = _anyDepartment;
  String selectedRole = _anyRole;
  String selectedStatus = _anyStatus;

  List<StaffDirectoryEntry> _staff = const [];
  List<SchoolDepartment> _departments = const [];

  /// Null while loading and after a failure — never a zeroed summary, so the
  /// card cannot show "มาปฏิบัติงาน 0 คน" when it simply could not read.
  StaffAttendanceSummary? _attendance;
  List<StaffLeaveRequest> _pendingLeave = const [];

  /// Attendance is loaded separately from the directory: the directory can
  /// succeed while attendance fails, and one failing must not blank the other.
  bool _attendanceFailed = false;
  bool _loading = true;
  bool _loadFailed = false;

  DateTime _substituteDate = DateTime.now();
  List<PeriodNeedingSubstitute> _periodsNeedingSubstitute = const [];
  bool _substituteLoadFailed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final results = await Future.wait<Object?>([
        widget.loadStaff?.call() ?? StaffOrgService.listStaffDirectory(),
        widget.loadDepartments?.call() ?? StaffOrgService.listDepartments(),
      ]);
      if (!mounted) return;
      setState(() {
        _staff = results[0] as List<StaffDirectoryEntry>;
        _departments = results[1] as List<SchoolDepartment>;
        _loading = false;
      });
      await _loadAttendance();
      await _loadSubstitutes();
    } catch (e) {
      debugPrint('DirectorTeachersPage load failed: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  Future<void> _loadSubstitutes() async {
    try {
      final periods =
          await (widget.loadPeriodsNeedingSubstitute?.call(_substituteDate) ??
              ClassSubstitutionService.listPeriodsNeedingSubstitute(
                _substituteDate,
              ));
      if (!mounted) return;
      setState(() {
        _periodsNeedingSubstitute = periods;
        _substituteLoadFailed = false;
      });
    } catch (e) {
      debugPrint('DirectorTeachersPage substitute load failed: $e');
      if (!mounted) return;
      setState(() {
        _periodsNeedingSubstitute = const [];
        _substituteLoadFailed = true;
      });
    }
  }

  Future<void> _loadAttendance() async {
    try {
      final results = await Future.wait<Object?>([
        widget.loadAttendanceSummary?.call() ??
            StaffAttendanceService.getSummary(),
        widget.loadLeaveRequests?.call() ??
            StaffAttendanceService.listLeaveRequests(status: 'pending'),
      ]);
      if (!mounted) return;
      setState(() {
        _attendance = results[0] as StaffAttendanceSummary?;
        _pendingLeave = results[1] as List<StaffLeaveRequest>;
        _attendanceFailed = false;
      });
    } catch (e) {
      debugPrint('DirectorTeachersPage attendance load failed: $e');
      if (!mounted) return;
      setState(() {
        _attendance = null;
        _pendingLeave = const [];
        _attendanceFailed = true;
      });
    }
  }

  /// ฝ่าย, from `departments` where kind = administrative.
  ///
  /// Was a const list of six with per-department staff/present/on-leave counts
  /// and a workload percentage. Only the member count is real; attendance and
  /// workload have no source — there is no staff attendance table at all — so
  /// they are not shown.
  List<SchoolDepartment> get _administrative =>
      _departments.where((d) => d.isAdministrative).toList();

  /// กลุ่มสาระ, from the same table.
  List<SchoolDepartment> get _subjectGroups =>
      _departments.where((d) => d.isSubjectGroup).toList();

  /// Filter options are built from the data on screen, never written by
  /// hand. The three lists that used to sit here named six ฝ่าย, five staff
  /// categories and six attendance states that no query could ever match —
  /// the status filter in particular offered 'มาปฏิบัติงาน' / 'ลา' / 'มาสาย'
  /// while the code behind it compared against 'ใช้งานอยู่' / 'ระงับการใช้งาน',
  /// so picking any of them silently emptied the list.
  static const String _anyDepartment = 'ทุกฝ่าย';
  static const String _anyRole = 'ทุกประเภท';
  static const String _anyStatus = 'ทุกสถานะ';

  List<String> get _departmentOptions => [
    _anyDepartment,
    ..._administrative.map((d) => d.name),
    ..._subjectGroups.map((d) => d.name),
  ];

  List<String> get _roleOptions {
    final labels = <String>{};
    for (final person in _staff) {
      for (final role in person.roles) {
        final label = _roleLabels[role];
        if (label != null) labels.add(label);
      }
    }
    final sorted = labels.toList()..sort();
    return [_anyRole, ...sorted];
  }

  static const Map<String, String> _accountStatusLabels = {
    'active': 'ใช้งานอยู่',
    'suspended': 'ระงับการใช้งาน',
  };

  List<String> get _statusOptions {
    final labels = <String>{};
    for (final person in _staff) {
      final label = _accountStatusLabels[person.status];
      if (label != null) labels.add(label);
    }
    final sorted = labels.toList()..sort();
    return [_anyStatus, ...sorted];
  }

  /// A selection made before a reload may no longer exist in the data. Falling
  /// back to the "any" option keeps the dropdown consistent with the list it
  /// filters instead of asserting.
  String _safeSelection(String selected, List<String> options) =>
      options.contains(selected) ? selected : options.first;

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredPersonnel();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DirectorSectionHeader(
            title: 'ครูและบุคลากร',
            subtitle:
                'ภาพรวมบุคลากรทั้งโรงเรียน แยกตามฝ่าย กลุ่มสาระ ตำแหน่ง การมาปฏิบัติงาน ภาระงาน และประเด็นที่ผู้อำนวยการควรติดตาม',
          ),
          const SizedBox(height: 14),
          _summaryCards(),
          const SizedBox(height: 16),
          _departmentSection(),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 1050) {
                return Column(
                  children: [
                    _todayStatusCard(),
                    const SizedBox(height: 16),
                    _directorFollowUpCard(),
                  ],
                );
              }

              // IntrinsicHeight + stretch so the shorter follow-up card
              // matches the status card's height instead of floating short
              // beside it. Safe here: neither card's subtree has a
              // LayoutBuilder or a Column with its own vertical Expanded
              // child (_statusGrid is a Column of Rows with only
              // horizontal Expanded cells).
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 5, child: _todayStatusCard()),
                    const SizedBox(width: 16),
                    Expanded(flex: 4, child: _directorFollowUpCard()),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _substituteCoverageCard(),
          if (_loading) ...[
            const SizedBox(height: 20),
            const Center(child: CircularProgressIndicator()),
          ],
          if (_loadFailed) ...[const SizedBox(height: 12), _loadErrorBanner()],
          const SizedBox(height: 16),
          _subjectGroupsSection(),
          const SizedBox(height: 16),
          _personnelSection(filtered),
        ],
      ),
    );
  }

  /// Thai label for a backend role value. The filter used to offer
  /// 'ผู้บริหาร / ครูผู้สอน / …' against a `role` string that was written by
  /// hand per row; these map to what `user_roles` actually holds.
  static const Map<String, String> _roleLabels = {
    'executive': 'ผู้บริหาร',
    'school_admin': 'ผู้ดูแลระบบโรงเรียน',
    'teacher': 'ครูผู้สอน',
  };

  String _roleLabel(StaffDirectoryEntry p) =>
      p.roles.map((r) => _roleLabels[r] ?? r).join(' · ');

  List<StaffDirectoryEntry> _filteredPersonnel() {
    final query = searchText.trim().toLowerCase();

    return _staff.where((person) {
      final groups = [
        ...person.administrativeDepartments,
        ...person.subjectGroups,
      ];

      final matchesSearch =
          query.isEmpty ||
          person.fullName.toLowerCase().contains(query) ||
          person.email.toLowerCase().contains(query) ||
          (person.positionTitle ?? '').toLowerCase().contains(query) ||
          groups.any((g) => g.toLowerCase().contains(query));

      final matchesDepartment =
          selectedDepartment == _anyDepartment ||
          groups.contains(selectedDepartment);

      // Matches on membership in `roles`, not equality against one collapsed
      // role — an account holding both teacher and school_admin belongs in
      // both filters.
      final matchesRole =
          selectedRole == _anyRole ||
          person.roles.any((r) => _roleLabels[r] == selectedRole);

      final matchesStatus =
          selectedStatus == _anyStatus ||
          (selectedStatus == 'ใช้งานอยู่' && person.isActive) ||
          (selectedStatus == 'ระงับการใช้งาน' && !person.isActive);

      return matchesSearch && matchesDepartment && matchesRole && matchesStatus;
    }).toList();
  }

  /// Failure stated on the page. Without it an unreachable backend renders as
  /// a school with no staff at all.
  Widget _loadErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 20,
            color: Color(0xFFB91C1C),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'โหลดข้อมูลบุคลากรไม่สำเร็จ — รายชื่อที่แสดงอาจไม่ครบ',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF991B1B),
              ),
            ),
          ),
          TextButton(
            onPressed: _loading ? null : _load,
            child: const Text('ลองใหม่'),
          ),
        ],
      ),
    );
  }

  // "ครูและบุคลากรทั้งหมด" used to be one of 5 equal-weight pastel cards in a
  // grid — but it's the number the other 4 are all breakdowns of, so it's
  // now a hero on its own with the rest as a secondary 2x2 grid beside it,
  // same hero+grid pattern used on the Overview page's attendance cards.
  Widget _summaryCards() {
    // Counted from the loaded directory. All six were fixed strings — 86
    // staff, 82 present today, 3 on leave, 2 late, 96% of periods started on
    // time, 4 in meetings. Only the head counts have a source: nothing in the
    // schema records staff attendance, lateness, whether a period actually
    // started, or who is in a meeting, so those four cards are gone rather
    // than showing a zero that would read as "nobody came in today".
    final teacherCount = _staff.where((s) => s.hasRole('teacher')).length;
    final adminCount = _staff.where((s) => s.hasRole('school_admin')).length;
    final unassigned = _staff
        .where(
          (s) => s.administrativeDepartments.isEmpty && s.subjectGroups.isEmpty,
        )
        .length;
    final noPosition = _staff.where((s) => s.positionTitle == null).length;

    String figure(int n) => _loadFailed ? '—' : '$n';

    final heroItem = _SummaryItem(
      title: 'ครูและบุคลากรทั้งหมด',
      value: figure(_staff.length),
      subtitle:
          'ครู ${figure(teacherCount)} • ผู้ดูแลระบบ ${figure(adminCount)}',
      icon: Icons.groups_rounded,
      color: AppPalette.softPink,
    );
    final gridItems = [
      _SummaryItem(
        title: 'ฝ่าย',
        value: figure(_administrative.length),
        subtitle: 'ตามโครงสร้างของโรงเรียน',
        icon: Icons.account_tree_rounded,
        color: AppPalette.softBlue,
      ),
      _SummaryItem(
        title: 'กลุ่มสาระ',
        value: figure(_subjectGroups.length),
        subtitle: 'กลุ่มสาระการเรียนรู้',
        icon: Icons.menu_book_rounded,
        color: AppPalette.softMint,
      ),
      _SummaryItem(
        title: 'ยังไม่ได้สังกัด',
        value: figure(unassigned),
        subtitle: 'ยังไม่ได้กำหนดฝ่าย/กลุ่มสาระ',
        icon: Icons.person_search_rounded,
        color: AppPalette.softCream,
      ),
      _SummaryItem(
        title: 'ยังไม่ได้ระบุตำแหน่ง',
        value: figure(noPosition),
        subtitle: 'รอบันทึกวิทยฐานะ',
        icon: Icons.badge_outlined,
        color: AppPalette.softPink2,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final hero = _summaryHero(heroItem);
        final grid = _summaryGrid(gridItems);
        if (constraints.maxWidth < 640) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [hero, const SizedBox(height: 10), grid],
          );
        }
        // IntrinsicHeight + stretch so the hero matches the grid's height
        // instead of sizing to its own (much shorter) content — safe here
        // because neither hero nor grid contains a LayoutBuilder or a
        // Column with its own Expanded/Flexible child, the two things that
        // actually break under an ancestor IntrinsicHeight.
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 34, child: hero),
              const SizedBox(width: 10),
              Expanded(flex: 66, child: grid),
            ],
          ),
        );
      },
    );
  }

  Widget _summaryHero(_SummaryItem item) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppPalette.primaryPink, AppPalette.primaryPinkDark],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(46),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(item.icon, size: 17, color: Colors.white),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.value,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.subtitle,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Plain Column of Rows (each Row's own cells wrapped in Expanded) rather
  // than GridView — GridView needs an explicit extent and doesn't
  // participate safely in the IntrinsicHeight/stretch pairing with the hero
  // above; this does, for the same reason a Row's own main-axis Expanded is
  // safe under an ancestor's height-intrinsic query but a Column's isn't.
  Widget _summaryGrid(List<_SummaryItem> items) {
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += 2) {
      if (i > 0) rows.add(const SizedBox(height: 10));
      rows.add(
        Row(
          children: [
            Expanded(child: _summaryCell(items[i])),
            const SizedBox(width: 10),
            if (i + 1 < items.length)
              Expanded(child: _summaryCell(items[i + 1]))
            else
              const Spacer(),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }

  Widget _summaryCell(_SummaryItem item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: item.color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: AppPalette.tint(Colors.white, 0.7),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(item.icon, size: 12, color: AppPalette.textDark),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: AppPalette.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            item.value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            item.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 8.5, color: AppPalette.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _departmentSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ภาพรวมแยกตามฝ่าย',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'ผู้อำนวยการสามารถดูจำนวนบุคลากร การมาปฏิบัติงาน ภาระงาน และประเด็นที่ต้องติดตามของแต่ละฝ่ายได้ในภาพเดียว',
            style: TextStyle(fontSize: 10.5, color: AppPalette.textMuted),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              int columns = 3;
              if (constraints.maxWidth < 700) {
                columns = 1;
              } else if (constraints.maxWidth < 1080) {
                columns = 2;
              }

              return GridView.builder(
                itemCount: _administrative.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 205,
                ),
                itemBuilder: (context, index) {
                  return _departmentCard(_administrative[index]);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  /// One ฝ่าย, showing only what `departments` can answer: its name, how many
  /// staff are assigned, and who heads it.
  ///
  /// The card used to carry present/on-leave counts and a workload percentage
  /// per department. There is no staff-attendance table anywhere in the schema
  /// and no workload metric, so all three were invented — and unlike a wrong
  /// number on a dashboard, "ฝ่ายวิชาการ ลา 2 คน" is a claim about named
  /// colleagues.
  Widget _departmentCard(SchoolDepartment item) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _showDepartmentDetail(item),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selectedDepartment == item.name
                ? AppPalette.primaryPink
                : AppPalette.border,
            width: selectedDepartment == item.name ? 1.4 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 39,
                  height: 39,
                  decoration: BoxDecoration(
                    color: AppPalette.tint(AppPalette.primaryPink, 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_tree_rounded,
                    size: 20,
                    color: AppPalette.primaryPink,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: AppPalette.textDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${item.memberCount} คน',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppPalette.textDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              item.headName == null
                  ? 'ยังไม่ได้ระบุหัวหน้าฝ่าย'
                  : 'หัวหน้า: ${item.headName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: AppPalette.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  /// สถานะบุคลากรวันนี้ — counted by `get_staff_attendance_summary`.
  ///
  /// This card once showed present / on-leave / late head counts with a
  /// breakdown ("ลาป่วย 2 คน • ลากิจ 1 คน") that no table could produce:
  /// `leave_requests` is *student* leave (`student_id` and `parent_id` are
  /// both NOT NULL) and nothing recorded staff attendance at all. It was left
  /// as a stated gap in fe8e4e6 and comes back here on
  /// `20260907010000_staff_attendance.sql`.
  Widget _todayStatusCard() {
    final summary = _attendance;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'สถานะบุคลากรวันนี้',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppPalette.textDark,
            ),
          ),
          const SizedBox(height: 12),
          if (_loading)
            _attendanceNotice(
              icon: Icons.hourglass_empty_rounded,
              title: 'กำลังโหลดข้อมูลการลงเวลา',
            )
          else if (_attendanceFailed || summary == null)
            _attendanceNotice(
              icon: Icons.cloud_off_rounded,
              title: 'โหลดข้อมูลการลงเวลาไม่สำเร็จ',
              detail: 'ยังไม่ทราบสถานะการมาปฏิบัติงานวันนี้ ลองใหม่อีกครั้ง',
            )
          else ...[
            // Zero staff is a different statement from an unreadable day, and
            // both are different from "everyone is here".
            if (summary.totalStaff == 0)
              _attendanceNotice(
                icon: Icons.badge_outlined,
                title: 'ยังไม่มีบุคลากรในระบบ',
              )
            else ...[
              _statusGrid([
                _statusChip(
                  label: 'มาปฏิบัติงาน',
                  count: summary.presentCount,
                  icon: Icons.check_rounded,
                  color: const Color(0xFF059669),
                ),
                _statusChip(
                  label: 'มาสาย',
                  count: summary.lateCount,
                  icon: Icons.schedule_rounded,
                  color: const Color(0xFFD97706),
                ),
                _statusChip(
                  label: 'ลา',
                  count: summary.leaveCount,
                  icon: Icons.event_busy_rounded,
                  color: const Color(0xFF7C3AED),
                ),
                _statusChip(
                  label: 'ไปราชการ/อบรม',
                  count: summary.officialDutyCount,
                  icon: Icons.card_travel_rounded,
                  color: const Color(0xFF2563EB),
                ),
                _statusChip(
                  label: 'ขาดงาน',
                  count: summary.absentCount,
                  icon: Icons.person_off_rounded,
                  color: const Color(0xFFDC2626),
                ),
                // Kept visibly separate from ขาดงาน: nobody has asserted
                // anything about these people today.
                _statusChip(
                  label: 'ยังไม่ลงเวลา',
                  count: summary.noRecordCount,
                  icon: Icons.help_outline_rounded,
                  color: AppPalette.textMuted,
                ),
              ]),
              const SizedBox(height: 10),
              Text(
                'บุคลากรทั้งหมด ${summary.totalStaff} คน',
                style: const TextStyle(
                  fontSize: 10.5,
                  color: AppPalette.textMuted,
                ),
              ),
            ],
            if (!summary.workHoursConfigured) ...[
              const SizedBox(height: 10),
              // Without configured hours the backend refuses every check-in,
              // so 0 มาสาย means "unknowable", not "nobody was late".
              _attendanceNotice(
                icon: Icons.schedule_rounded,
                title: 'โรงเรียนยังไม่ได้ตั้งเวลาปฏิบัติงาน',
                detail:
                    'ระบบจึงยังตัดสินไม่ได้ว่าใครมาสาย และบุคลากรยังลงเวลาไม่ได้ '
                    'ผู้ดูแลระบบโรงเรียนเป็นผู้ตั้งค่านี้',
              ),
            ],
          ],
        ],
      ),
    );
  }

  // "ครูสอนแทน" — คาบของครูที่ลาอนุมัติแล้วในวันที่เลือก, จาก
  // `list_periods_needing_substitute`. RPC เดิมไม่เคยมีแนวคิดนี้เลยในระบบ
  // (เพิ่มพร้อมตาราง class_substitutions ใน migration
  // 20260910160000_teacher_workload_categories.sql) — การ์ดนี้คือจุดเดียวที่
  // ทำให้ตัวเลข "จัดครูสอนแทน" บนการ์ดภาพรวมของผู้บริหารมีข้อมูลจริงให้แสดง
  Widget _substituteCoverageCard() {
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
                child: Text(
                  'ครูสอนแทน',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppPalette.textDark,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _substituteDate,
                    firstDate: DateTime(now.year - 1),
                    lastDate: DateTime(now.year + 1),
                  );
                  if (picked == null) return;
                  setState(() => _substituteDate = picked);
                  await _loadSubstitutes();
                },
                icon: const Icon(Icons.calendar_today_rounded, size: 14),
                label: Text(
                  '${_substituteDate.day}/${_substituteDate.month}/${_substituteDate.year}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'คาบเรียนของครูที่ลาอนุมัติแล้วในวันที่เลือก',
            style: TextStyle(fontSize: 10.5, color: AppPalette.textMuted),
          ),
          const SizedBox(height: 12),
          if (_substituteLoadFailed)
            _attendanceNotice(
              icon: Icons.cloud_off_rounded,
              title: 'โหลดข้อมูลครูสอนแทนไม่สำเร็จ',
            )
          else if (_periodsNeedingSubstitute.isEmpty)
            _attendanceNotice(
              icon: Icons.check_circle_outline_rounded,
              title: 'ไม่มีคาบที่ต้องจัดครูสอนแทนในวันนี้',
            )
          else
            for (final period in _periodsNeedingSubstitute)
              _substitutePeriodTile(period),
        ],
      ),
    );
  }

  Widget _substitutePeriodTile(PeriodNeedingSubstitute period) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: period.alreadyCovered
            ? const Color(0xFFF0FDF4)
            : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: period.alreadyCovered
              ? const Color(0xFFBBF7D0)
              : const Color(0xFFFECACA),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${period.subjectName} • ${period.gradeLevel ?? "ไม่ระบุชั้น"}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${period.timeRangeLabel} น. • ห้อง ${period.room ?? "ไม่ระบุ"} • ครูประจำวิชา: ${period.originalTeacherName}',
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppPalette.textMuted,
                  ),
                ),
                if (period.alreadyCovered) ...[
                  const SizedBox(height: 4),
                  Text(
                    'ครูสอนแทน: ${period.substituteTeacherName ?? "ไม่ทราบชื่อ"}',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF15803D),
                    ),
                  ),
                  // red-team: การมอบหมายเดิมเขียนทับเงียบๆ ไม่มีร่องรอยว่าใคร
                  // เปลี่ยนอะไร — ตอนนี้แยกให้เห็นว่าเป็นการมอบหมายครั้งแรกหรือ
                  // แก้ไขภายหลัง และใครเป็นคนทำล่าสุดจริง (ไม่ใช่คนแรกเสมอไป)
                  if (period.assignedByName != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          '${period.reassigned ? "แก้ไขล่าสุดโดย" : "มอบหมายโดย"} ${period.assignedByName}',
                          style: const TextStyle(
                            fontSize: 9.5,
                            color: AppPalette.textMuted,
                          ),
                        ),
                        if (period.reassigned) ...[
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'แก้ไขแล้ว',
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFB45309),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (period.alreadyCovered)
            const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF15803D),
              size: 20,
            )
          else
            OutlinedButton(
              onPressed: () => _openAssignSubstituteDialog(period),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'มอบหมายครูสอนแทน',
                style: TextStyle(fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }

  // ต้องไม่ใช้ teacher_picker_dialog.dart — widget นั้นดึงรายชื่อจาก
  // DirectorMockData ที่แต่งขึ้นทั้งหมด ไม่ใช่ของจริง ใช้ _staff ที่หน้านี้โหลด
  // จริงจาก StaffOrgService แทน กรองเอาเฉพาะครู (ไม่รวมครูที่ลาอยู่คนเดิม)
  Future<void> _openAssignSubstituteDialog(
    PeriodNeedingSubstitute period,
  ) async {
    final candidates =
        _staff
            .where(
              (s) =>
                  s.hasRole('teacher') && s.userId != period.originalTeacherId,
            )
            .toList()
          ..sort((a, b) => a.fullName.compareTo(b.fullName));
    if (candidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่พบครูคนอื่นในระบบที่มอบหมายได้')),
      );
      return;
    }
    String? selected;
    var isSaving = false;
    final noteController = TextEditingController();
    final pageContext = context;
    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'มอบหมายครูสอนแทน\n${period.subjectName} (${period.timeRangeLabel} น.)',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ครูสอนแทน:',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: selected,
                  isExpanded: true,
                  hint: const Text('เลือกครู'),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: [
                    for (final c in candidates)
                      DropdownMenuItem(
                        value: c.userId,
                        child: Text(c.fullName),
                      ),
                  ],
                  onChanged: (val) => setDialogState(() => selected = val),
                ),
                const SizedBox(height: 14),
                const Text(
                  'หมายเหตุ (ถ้ามี):',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: noteController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(dialogCtx),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: (selected == null || isSaving)
                  ? null
                  : () async {
                      final substituteId = selected!;
                      setDialogState(() => isSaving = true);
                      try {
                        final record =
                            widget.recordSubstitution ??
                            ({
                              required String classScheduleId,
                              required DateTime date,
                              required String originalTeacherId,
                              required String substituteTeacherId,
                              String? note,
                            }) => ClassSubstitutionService.recordSubstitution(
                              classScheduleId: classScheduleId,
                              date: date,
                              originalTeacherId: originalTeacherId,
                              substituteTeacherId: substituteTeacherId,
                              note: note,
                            );
                        await record(
                          classScheduleId: period.classScheduleId,
                          date: _substituteDate,
                          originalTeacherId: period.originalTeacherId,
                          substituteTeacherId: substituteId,
                          note: noteController.text.trim().isNotEmpty
                              ? noteController.text.trim()
                              : null,
                        );
                        // Pop only after the RPC actually confirms the write —
                        // popping first would tell the user "saved" before
                        // the backend agreed, and hide a real failure behind
                        // a dialog that already looked done.
                        if (!dialogCtx.mounted) return;
                        Navigator.pop(dialogCtx);
                        if (!pageContext.mounted) return;
                        ScaffoldMessenger.of(pageContext).showSnackBar(
                          const SnackBar(
                            content: Text('มอบหมายครูสอนแทนเรียบร้อยแล้ว'),
                          ),
                        );
                        await _loadSubstitutes();
                      } catch (e) {
                        debugPrint('recordSubstitution failed: $e');
                        if (!dialogCtx.mounted) return;
                        setDialogState(() => isSaving = false);
                        ScaffoldMessenger.of(dialogCtx).showSnackBar(
                          const SnackBar(
                            content: Text('มอบหมายไม่สำเร็จ ลองอีกครั้ง'),
                          ),
                        );
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('บันทึก'),
            ),
          ],
        ),
      ),
    );
  }

  // 3-per-row grid (Column of Rows, not GridView/Wrap) so 6 chips form 2
  // even rows instead of wrapping unpredictably at odd widths.
  Widget _statusGrid(List<Widget> chips) {
    final rows = <Widget>[];
    for (var i = 0; i < chips.length; i += 3) {
      if (i > 0) rows.add(const SizedBox(height: 10));
      rows.add(
        Row(
          children: [
            Expanded(child: chips[i]),
            const SizedBox(width: 10),
            if (i + 1 < chips.length) ...[
              Expanded(child: chips[i + 1]),
              const SizedBox(width: 10),
            ] else
              const Expanded(child: SizedBox()),
            if (i + 2 < chips.length)
              Expanded(child: chips[i + 2])
            else
              const Expanded(child: SizedBox()),
          ],
        ),
      );
    }
    return Column(children: rows);
  }

  Widget _statusChip({
    required String label,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: AppPalette.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _attendanceNotice({
    required IconData icon,
    required String title,
    String? detail,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
      decoration: BoxDecoration(
        color: AppPalette.pageBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 26, color: AppPalette.textMuted),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: AppPalette.textDark,
            ),
          ),
          if (detail != null) ...[
            const SizedBox(height: 4),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                height: 1.45,
                color: AppPalette.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// สิ่งที่ควรติดตาม — derived from the same figures, not authored.
  ///
  /// The old card listed items like "ครูลา 2 คนในฝ่ายวิชาการ" with a severity
  /// and a suggested action, all computed from the invented attendance
  /// numbers. Every line here is a count the backend returned, and when there
  /// is nothing to report it says so rather than filling the space.
  ///
  /// Each item's color/icon now matches the _statusChip it was derived from
  /// (มาสาย → the same amber as the "มาสาย" chip, ยังไม่ลงเวลา → the same
  /// grey), so a flag visually traces back to the number it came from
  /// instead of every flag looking identical regardless of what it's about.
  List<_FollowUpItem> _followUpItems() {
    final summary = _attendance;
    if (summary == null) return const [];

    return [
      if (_pendingLeave.isNotEmpty)
        _FollowUpItem(
          text: 'มีคำขอลาที่ยังไม่ได้พิจารณา ${_pendingLeave.length} รายการ',
          icon: Icons.event_busy_rounded,
          color: const Color(0xFF7C3AED),
        ),
      if (summary.lateCount > 0)
        _FollowUpItem(
          text: 'มาสายวันนี้ ${summary.lateCount} คน',
          icon: Icons.schedule_rounded,
          color: const Color(0xFFD97706),
        ),
      if (summary.absentCount > 0)
        _FollowUpItem(
          text: 'ขาดงานวันนี้ ${summary.absentCount} คน',
          icon: Icons.person_off_rounded,
          color: const Color(0xFFDC2626),
        ),
      if (summary.noRecordCount > 0)
        _FollowUpItem(
          text: 'ยังไม่ได้ลงเวลาวันนี้ ${summary.noRecordCount} คน',
          icon: Icons.help_outline_rounded,
          color: AppPalette.textMuted,
        ),
    ];
  }

  Widget _directorFollowUpCard() {
    final items = _followUpItems();
    final unavailable = _loading || _attendanceFailed || _attendance == null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'สิ่งที่ควรติดตาม',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppPalette.textDark,
            ),
          ),
          const SizedBox(height: 12),
          if (unavailable)
            _attendanceNotice(
              icon: Icons.help_outline_rounded,
              title: 'ยังไม่ทราบประเด็นที่ต้องติดตาม',
              detail: 'ต้องอ่านข้อมูลการลงเวลาและการลาได้ก่อน',
            )
          else if (items.isEmpty)
            _attendanceNotice(
              icon: Icons.check_circle_outline_rounded,
              title: 'ไม่มีประเด็นที่ระบบยืนยันได้ในวันนี้',
            )
          else
            ...items.map(
              (item) => Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: item.color,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(item.icon, size: 15, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.text,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                          color: AppPalette.textDark,
                        ),
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

  Widget _subjectGroupsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ครูผู้สอนแยกตามกลุ่มสาระ',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'ดูจำนวนครู การมาปฏิบัติงาน ภาพรวมการเข้าสอน และจำนวนครูที่ต้องติดตามของแต่ละกลุ่มสาระ',
            style: TextStyle(fontSize: 10.5, color: AppPalette.textMuted),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              int columns = 4;
              if (constraints.maxWidth < 650) {
                columns = 1;
              } else if (constraints.maxWidth < 980) {
                columns = 2;
              }

              return GridView.builder(
                itemCount: _subjectGroups.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  mainAxisExtent: 145,
                ),
                itemBuilder: (context, index) {
                  final item = _subjectGroups[index];
                  // Was six invented metrics per group: teacher count,
                  // attendance %, teaching-compliance % and a follow-up
                  // headcount. Only the member count exists — nothing records
                  // staff attendance, and nothing records whether a teacher
                  // started a period, so "เข้าสอน 96%" was a claim about
                  // colleagues that no system had measured.
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppPalette.tint(AppPalette.learningBlue, 0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppPalette.tint(AppPalette.learningBlue, 0.16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: AppPalette.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${item.memberCount} คน',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: AppPalette.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.headName == null
                              ? 'ยังไม่ได้ระบุหัวหน้ากลุ่มสาระ'
                              : 'หัวหน้า: ${item.headName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 9.5,
                            color: AppPalette.textMuted,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _personnelSection(List<StaffDirectoryEntry> filtered) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'รายชื่อครูและบุคลากร',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'ค้นหาชื่อ ตำแหน่ง ฝ่าย หรือกลุ่มสาระ และกรองตามสถานะการทำงาน',
            style: TextStyle(fontSize: 10.5, color: AppPalette.textMuted),
          ),
          const SizedBox(height: 14),
          _filterArea(),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'พบ ${filtered.length} คน',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppPalette.textMuted,
                ),
              ),
              const Spacer(),
              if (selectedDepartment != 'ทุกฝ่าย' ||
                  selectedRole != 'ทุกประเภท' ||
                  selectedStatus != 'ทุกสถานะ' ||
                  searchText.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      searchText = '';
                      selectedDepartment = 'ทุกฝ่าย';
                      selectedRole = 'ทุกประเภท';
                      selectedStatus = 'ทุกสถานะ';
                    });
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('ล้างตัวกรอง'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (filtered.isEmpty)
            _emptyPersonnel()
          else
            for (var i = 0; i < filtered.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              _personnelRow(filtered[i]),
            ],
        ],
      ),
    );
  }

  Widget _filterArea() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 900;

        final search = TextField(
          onChanged: (value) {
            setState(() => searchText = value);
          },
          decoration: InputDecoration(
            hintText: 'ค้นหาชื่อ ตำแหน่ง ฝ่าย หรือกลุ่มสาระ...',
            hintStyle: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              size: 18,
              color: AppPalette.primaryPink,
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
            // Theme's own focusedBorder is a 12px-radius rect (buildRoleTheme) —
            // without overriding it here too, focusing this field would snap
            // its corners from the pill shape to that rect.
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: const BorderSide(
                color: AppPalette.primaryPink,
                width: 1.5,
              ),
            ),
          ),
        );

        final department = _dropdownBox(
          value: _safeSelection(selectedDepartment, _departmentOptions),
          items: _departmentOptions,
          icon: Icons.account_tree_rounded,
          onChanged: (value) {
            if (value == null) return;
            setState(() => selectedDepartment = value);
          },
        );

        final role = _dropdownBox(
          value: _safeSelection(selectedRole, _roleOptions),
          items: _roleOptions,
          icon: Icons.badge_rounded,
          onChanged: (value) {
            if (value == null) return;
            setState(() => selectedRole = value);
          },
        );

        final status = _statusSegmented();

        if (compact) {
          return Column(
            children: [
              search,
              const SizedBox(height: 9),
              Row(
                children: [
                  Expanded(child: department),
                  const SizedBox(width: 8),
                  Expanded(child: role),
                ],
              ),
              const SizedBox(height: 9),
              status,
            ],
          );
        }

        return Row(
          children: [
            Expanded(flex: 3, child: search),
            const SizedBox(width: 9),
            Expanded(child: department),
            const SizedBox(width: 9),
            Expanded(child: role),
            const SizedBox(width: 9),
            Expanded(child: status),
          ],
        );
      },
    );
  }

  Widget _dropdownBox({
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
                        child: Text(
                          item,
                          maxLines: 1,
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

  /// Segmented pill toggle for the account-status filter, replacing a
  /// dropdown. Options still come from `_statusOptions` (only statuses that
  /// actually exist among loaded staff, plus "ทุกสถานะ") — this is a layout
  /// change only, not a return to a fixed/hardcoded option list.
  Widget _statusSegmented() {
    final options = _statusOptions;
    final selected = _safeSelection(selectedStatus, options);

    return Container(
      key: const Key('statusSegmented'),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppPalette.pageBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          for (final option in options)
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => selectedStatus = option),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: option == selected ? Colors.white : null,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: option == selected
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    option,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: option == selected
                          ? AppPalette.textDark
                          : AppPalette.textMuted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// One staff row. Same fields `_personnelCard` used to show — name,
  /// position, groups, role, contact, head badge and account status —
  /// reflowed onto a soft floating card matching the tile pattern in
  /// `director_emergency_page.dart` (radius 18, thin light border, blur-10
  /// shadow at 3% opacity, a rounded icon box instead of a bare avatar
  /// circle) instead of the flat 4px-radius table row this replaced.
  ///
  /// Accent uses learningBlueDark instead of primaryPink — pink stays for
  /// brand/header moments, structural accents (avatar box, "หัวหน้า" label)
  /// use blue so it doesn't repeat on every single row of a long roster.
  ///
  /// Gone with the data that never existed: the attendance percentage, the
  /// teaching-compliance percentage and the task-progress bar. There is no
  /// staff attendance table, nothing records whether a teacher started a
  /// period, and no task tracker exists — so all three were assessments of a
  /// named colleague that no system had made.
  // Flat pageBg tile instead of a bordered/shadowed white card — matches the
  // icon-badge rows already shipped on this page ("สิ่งที่ควรติดตาม"), not a
  // new visual language.
  static final BoxDecoration _softCard = BoxDecoration(
    color: AppPalette.pageBg,
    borderRadius: BorderRadius.circular(18),
  );

  Widget _personnelRow(StaffDirectoryEntry person) {
    final groups = [
      ...person.administrativeDepartments,
      ...person.subjectGroups,
    ];
    final statusColor = person.isActive
        ? AppPalette.success
        : AppPalette.textMuted;

    final avatar = Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: AppPalette.tint(AppPalette.learningBlueDark, 0.12),
        borderRadius: BorderRadius.circular(9),
      ),
      alignment: Alignment.center,
      child: Text(
        _firstLetter(person.fullName),
        style: const TextStyle(
          color: AppPalette.learningBlueDark,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );

    final nameBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          person.fullName,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: AppPalette.textDark,
          ),
        ),
        if (person.headsDepartments.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            'หัวหน้า: ${person.headsDepartments.join(', ')}',
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: AppPalette.learningBlueDark,
            ),
          ),
        ],
        const SizedBox(height: 2),
        // No italic — Noto Sans Thai has no real italic forms for Thai
        // glyphs, so a synthetic slant just misaligns tone marks. Muted
        // color alone signals "unset" instead.
        Text(
          person.positionTitle ?? 'ยังไม่ได้ระบุตำแหน่ง',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppPalette.textMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${_roleLabel(person)} · ${person.phone ?? person.email}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppPalette.textMuted,
          ),
        ),
      ],
    );

    final deptPill = Container(
      constraints: const BoxConstraints(maxWidth: 190),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        groups.isEmpty ? 'ยังไม่ได้สังกัดฝ่าย/กลุ่มสาระ' : groups.join(' • '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: AppPalette.textMuted,
        ),
      ),
    );

    // Icon-badge pill — same language as the "สิ่งที่ควรติดตาม" rows
    // (colored squircle icon on a soft-tint pill) instead of plain text.
    final statusBadge = Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 10, 4),
      decoration: BoxDecoration(
        color: AppPalette.tint(statusColor, 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 15,
            height: 15,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Icon(
              person.isActive ? Icons.check_rounded : Icons.pause_rounded,
              size: 10,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            person.isActive ? 'ใช้งานอยู่' : 'ระงับการใช้งาน',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: statusColor,
            ),
          ),
        ],
      ),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: _softCard,
      child: LayoutBuilder(
        builder: (context, box) {
          if (box.maxWidth < 680) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                avatar,
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: nameBlock),
                          const SizedBox(width: 8),
                          statusBadge,
                        ],
                      ),
                      const SizedBox(height: 6),
                      deptPill,
                    ],
                  ),
                ),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              avatar,
              const SizedBox(width: 12),
              Expanded(child: nameBlock),
              const SizedBox(width: 10),
              deptPill,
              const SizedBox(width: 10),
              statusBadge,
            ],
          );
        },
      ),
    );
  }

  Widget _emptyPersonnel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
      decoration: BoxDecoration(
        color: AppPalette.pageBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        children: [
          Icon(Icons.search_off_rounded, size: 34, color: AppPalette.textMuted),
          SizedBox(height: 8),
          Text(
            'ไม่พบบุคลากรตามตัวกรอง',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'ลา':
        return AppPalette.warning;
      case 'มาสาย':
        return AppPalette.danger;
      case 'ประชุม/อบรม':
        return AppPalette.learningBlue;
      case 'เข้าสอน':
        return AppPalette.primaryPink;
      default:
        return AppPalette.success;
    }
  }

  String _firstLetter(String name) {
    final clean = name
        .replaceFirst('นาย', '')
        .replaceFirst('นางสาว', '')
        .replaceFirst('นาง', '')
        .trim();

    return clean.isEmpty ? '?' : clean.substring(0, 1);
  }

  void _showDepartmentDetail(SchoolDepartment item) {
    final people = _staff
        .where(
          (person) =>
              person.administrativeDepartments.contains(item.name) ||
              person.subjectGroups.contains(item.name),
        )
        .toList();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            item.name,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          content: SizedBox(
            width: 620,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.isAdministrative ? 'ฝ่าย' : 'กลุ่มสาระการเรียนรู้',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppPalette.textMuted,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Present / on-leave / average-workload rows are gone with
                  // the data that never backed them.
                  _dialogRow('บุคลากรทั้งหมด', '${item.memberCount} คน'),
                  _dialogRow('หัวหน้า', item.headName ?? 'ยังไม่ได้ระบุ'),
                  const SizedBox(height: 14),
                  const Text(
                    'บุคลากรในฝ่าย',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  if (people.isEmpty)
                    const Text(
                      'ยังไม่มีข้อมูลรายบุคคลตัวอย่างในฝ่ายนี้',
                      style: TextStyle(
                        fontSize: 9.5,
                        color: AppPalette.textMuted,
                      ),
                    )
                  else
                    ...people.map(
                      (person) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: AppPalette.tint(
                            AppPalette.primaryPink,
                            0.12,
                          ),
                          child: Text(
                            _firstLetter(person.fullName),
                            style: const TextStyle(
                              color: AppPalette.primaryPink,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        title: Text(
                          person.fullName,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          person.positionTitle ?? 'ยังไม่ได้ระบุตำแหน่ง',
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppPalette.textMuted,
                          ),
                        ),
                        trailing: Text(
                          person.status,
                          style: TextStyle(
                            fontSize: 8.8,
                            fontWeight: FontWeight.w700,
                            color: _statusColor(person.status),
                          ),
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

  Widget _dialogRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 9.8,
                color: AppPalette.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 10.2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _SummaryItem({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class _FollowUpItem {
  final String text;
  final IconData icon;
  final Color color;

  const _FollowUpItem({
    required this.text,
    required this.icon,
    required this.color,
  });
}
