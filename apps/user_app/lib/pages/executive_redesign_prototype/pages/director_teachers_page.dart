import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import '../theme/app_palette.dart';
import '../widgets/director_common_widgets.dart';

/// Read seams so loading / data / empty / failure can each be driven in a test.
typedef StaffDirectoryLoader = Future<List<StaffDirectoryEntry>> Function();
typedef DepartmentsLoader = Future<List<SchoolDepartment>> Function();

class DirectorTeachersPage extends StatefulWidget {
  const DirectorTeachersPage({super.key, this.loadStaff, this.loadDepartments});

  final StaffDirectoryLoader? loadStaff;
  final DepartmentsLoader? loadDepartments;

  @override
  State<DirectorTeachersPage> createState() => _DirectorTeachersPageState();
}

class _DirectorTeachersPageState extends State<DirectorTeachersPage> {
  String searchText = '';
  String selectedDepartment = 'ทุกฝ่าย';
  String selectedRole = 'ทุกประเภท';
  String selectedStatus = 'ทุกสถานะ';

  List<StaffDirectoryEntry> _staff = const [];
  List<SchoolDepartment> _departments = const [];
  bool _loading = true;
  bool _loadFailed = false;

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
    } catch (e) {
      debugPrint('DirectorTeachersPage load failed: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
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

  final List<String> departments = const [
    'ทุกฝ่าย',
    'ฝ่ายบริหาร',
    'ฝ่ายวิชาการ',
    'ฝ่ายกิจการนักเรียน',
    'ฝ่ายบุคคลและธุรการ',
    'ฝ่ายอาคารสถานที่และสิ่งแวดล้อม',
    'ฝ่ายเทคโนโลยีและระบบ',
  ];

  final List<String> roles = const [
    'ทุกประเภท',
    'ผู้บริหาร',
    'ครูผู้สอน',
    'หัวหน้าฝ่าย',
    'เจ้าหน้าที่',
    'บุคลากรสนับสนุน',
  ];

  final List<String> statuses = const [
    'ทุกสถานะ',
    'มาปฏิบัติงาน',
    'เข้าสอน',
    'ลา',
    'มาสาย',
    'ประชุม/อบรม',
  ];

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

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: _todayStatusCard()),
                  const SizedBox(width: 16),
                  Expanded(flex: 4, child: _directorFollowUpCard()),
                ],
              );
            },
          ),
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
          selectedDepartment == 'ทุกฝ่าย' ||
          groups.contains(selectedDepartment);

      // Matches on membership in `roles`, not equality against one collapsed
      // role — an account holding both teacher and school_admin belongs in
      // both filters.
      final matchesRole =
          selectedRole == 'ทุกประเภท' ||
          person.roles.any((r) => _roleLabels[r] == selectedRole);

      final matchesStatus =
          selectedStatus == 'ทุกสถานะ' ||
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

    final items = [
      _SummaryItem(
        title: 'ครูและบุคลากรทั้งหมด',
        value: figure(_staff.length),
        subtitle:
            'ครู ${figure(teacherCount)} • ผู้ดูแลระบบ ${figure(adminCount)}',
        icon: Icons.groups_rounded,
        color: AppPalette.softPink,
      ),
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
        int columns = 6;
        if (constraints.maxWidth < 720) {
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
            mainAxisExtent: 118,
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
                      fontSize: 9.3,
                      color: AppPalette.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    item.value,
                    style: const TextStyle(
                      fontSize: 21,
                      height: 1.05,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 8.3,
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

  /// Was "สถานะบุคลากรวันนี้": present / on leave / late headcounts with a
  /// breakdown ("ลาป่วย 2 คน • ลากิจ 1 คน"). There is no staff attendance
  /// table anywhere in the schema, and `leave_requests` is *student* leave —
  /// it has `student_id` and `parent_id` NOT NULL — so none of it could have
  /// come from the database.
  Widget _todayStatusCard() {
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 14),
            decoration: BoxDecoration(
              color: AppPalette.pageBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.badge_outlined,
                  size: 30,
                  color: AppPalette.textMuted,
                ),
                SizedBox(height: 8),
                Text(
                  'ยังไม่มีระบบลงเวลาปฏิบัติงานของบุคลากร',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: AppPalette.textDark,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'การมาปฏิบัติงาน การลา และการมาสายของครู ยังไม่ได้ถูกบันทึกไว้ในระบบ',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: AppPalette.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The follow-up card listed items like "ครูลา 2 คนในฝ่ายวิชาการ" with a
  /// severity and a suggested action — every one derived from the invented
  /// attendance figures, and every one naming a real department. It is an
  /// honest gap until staff attendance and staff leave are modelled.
  Widget _directorFollowUpCard() {
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
            decoration: BoxDecoration(
              color: AppPalette.pageBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'ยังไม่มีข้อมูลการมาปฏิบัติงานและการลาของบุคลากร '
              'จึงยังไม่มีประเด็นที่ระบบยืนยันได้',
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
                  fontSize: 10.5,
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
            ...filtered.map(_personnelCard),
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
            hintStyle: const TextStyle(fontSize: 10),
            prefixIcon: const Icon(
              Icons.search_rounded,
              size: 18,
              color: AppPalette.primaryPink,
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

        final department = _dropdownBox(
          value: selectedDepartment,
          items: departments,
          icon: Icons.account_tree_rounded,
          onChanged: (value) {
            if (value == null) return;
            setState(() => selectedDepartment = value);
          },
        );

        final role = _dropdownBox(
          value: selectedRole,
          items: roles,
          icon: Icons.badge_rounded,
          onChanged: (value) {
            if (value == null) return;
            setState(() => selectedRole = value);
          },
        );

        final status = _dropdownBox(
          value: selectedStatus,
          items: statuses,
          icon: Icons.fact_check_rounded,
          onChanged: (value) {
            if (value == null) return;
            setState(() => selectedStatus = value);
          },
        );

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

  /// One staff row. Carries name, position, groups, roles and account status —
  /// everything `list_staff_directory` can answer.
  ///
  /// Gone with the data that never existed: the attendance percentage, the
  /// teaching-compliance percentage and the task-progress bar. There is no
  /// staff attendance table, nothing records whether a teacher started a
  /// period, and no task tracker exists — so all three were assessments of a
  /// named colleague that no system had made.
  Widget _personnelCard(StaffDirectoryEntry person) {
    final groups = [
      ...person.administrativeDepartments,
      ...person.subjectGroups,
    ];
    final statusColor = person.isActive
        ? AppPalette.success
        : AppPalette.textMuted;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPalette.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 19,
            backgroundColor: AppPalette.tint(AppPalette.primaryPink, 0.12),
            child: Text(
              _firstLetter(person.fullName),
              style: const TextStyle(
                color: AppPalette.primaryPink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  person.fullName,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppPalette.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  person.positionTitle ?? 'ยังไม่ได้ระบุตำแหน่ง',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppPalette.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  groups.isEmpty
                      ? 'ยังไม่ได้สังกัดฝ่าย/กลุ่มสาระ'
                      : groups.join(' • '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: AppPalette.textMuted,
                  ),
                ),
                if (person.headsDepartments.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    'หัวหน้า: ${person.headsDepartments.join(', ')}',
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: AppPalette.primaryPinkDark,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppPalette.tint(statusColor, 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  person.isActive ? 'ใช้งานอยู่' : 'ระงับการใช้งาน',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _roleLabel(person),
                style: const TextStyle(
                  fontSize: 9,
                  color: AppPalette.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                person.phone ?? person.email,
                style: const TextStyle(
                  fontSize: 8.5,
                  color: AppPalette.textMuted,
                ),
              ),
            ],
          ),
        ],
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
