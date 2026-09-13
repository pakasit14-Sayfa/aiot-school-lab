// เช็คชื่อนักเรียน — สองโหมด: (1) นักเรียนประจำชั้นที่ครูดูแล
// (homeroom_assignments + homeroom_attendance_records) และ (2) นักเรียน
// ในรายวิชาที่ครูสอน (attendance_records)
import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import 'teacher_redesign_prototype_page.dart' show TeacherPalette;
import 'teacher_shared_widgets.dart' show TeacherMockPageShell;

enum AttendanceMode { homeroom, course }

class AttendanceStudentRow {
  AttendanceStudentRow({
    required this.studentId,
    required this.studentName,
    required this.studentCode,
    required this.status,
  });

  final String studentId;
  final String studentName;
  final String studentCode;
  String status;
}

class TeacherAttendancePage extends StatefulWidget {
  const TeacherAttendancePage({
    super.key,
    this.initialHomerooms,
    this.initialCourses,
    this.initialRoster,
  });

  final List<HomeroomAssignment>? initialHomerooms;
  final List<CourseSummary>? initialCourses;
  final List<AttendanceStudentRow>? initialRoster;

  @override
  State<TeacherAttendancePage> createState() => _TeacherAttendancePageState();
}

class _TeacherAttendancePageState extends State<TeacherAttendancePage> {
  AttendanceMode _mode = AttendanceMode.homeroom;
  bool _loadingClasses = true;
  List<HomeroomAssignment> _homerooms = [];
  List<CourseSummary> _courses = [];
  HomeroomAssignment? _selectedHomeroom;
  CourseSummary? _selectedCourse;
  DateTime _selectedDate = DateTime.now();
  bool _loadingRoster = false;
  bool _saving = false;
  String? _error;
  List<AttendanceStudentRow> _roster = [];
  String _searchQuery = '';

  static const List<(String, String, Color, IconData)> _statusDefs = [
    ('present', 'มาเรียน', Color(0xFF10B981), Icons.check_circle_rounded),
    ('late', 'มาสาย', Color(0xFFF59E0B), Icons.access_time_filled_rounded),
    ('excused', 'ลา', Color(0xFF8B5CF6), Icons.assignment_turned_in_rounded),
    ('absent', 'ขาดเรียน', Color(0xFFEF4444), Icons.cancel_rounded),
  ];

  static const List<String> _thaiMonths = [
    'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
    'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialHomerooms != null || widget.initialCourses != null) {
      _homerooms = widget.initialHomerooms ?? [];
      _courses = widget.initialCourses ?? [];
      _selectedHomeroom = _homerooms.isNotEmpty ? _homerooms.first : null;
      _selectedCourse = _courses.isNotEmpty ? _courses.first : null;
      _mode = _homerooms.isNotEmpty ? AttendanceMode.homeroom : AttendanceMode.course;
      _roster = widget.initialRoster ?? [];
      _loadingClasses = false;
    } else {
      _loadClasses();
    }
  }

  Future<void> _loadClasses() async {
    setState(() {
      _loadingClasses = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        HomeroomService.listMyHomeroomClasses(),
        CourseService.listMyCourses(),
      ]);
      final homerooms = results[0] as List<HomeroomAssignment>;
      final courses = (results[1] as List<CourseSummary>)
          .where((c) => c.isActive)
          .toList();
      if (!mounted) return;
      setState(() {
        _homerooms = homerooms;
        _courses = courses;
        _selectedHomeroom = homerooms.isNotEmpty ? homerooms.first : null;
        _selectedCourse = courses.isNotEmpty ? courses.first : null;
        _mode = homerooms.isNotEmpty
            ? AttendanceMode.homeroom
            : AttendanceMode.course;
        _loadingClasses = false;
      });
      await _loadRoster();
    } catch (e) {
      debugPrint('Error loading attendance rooms/courses: $e');
      if (!mounted) return;
      setState(() {
        _loadingClasses = false;
        _error = 'โหลดรายชื่อห้องหรือรายวิชาไม่สำเร็จ';
      });
    }
  }

  Future<void> _loadRoster() async {
    if (widget.initialRoster != null) return;
    final isHomeroom = _mode == AttendanceMode.homeroom;
    if (isHomeroom && _selectedHomeroom == null) {
      setState(() => _roster = []);
      return;
    }
    if (!isHomeroom && _selectedCourse == null) {
      setState(() => _roster = []);
      return;
    }

    setState(() {
      _loadingRoster = true;
      _error = null;
    });
    try {
      final items = isHomeroom
          ? await AttendanceService.listHomeroomAttendance(
              gradeLevel: _selectedHomeroom!.gradeLevel,
              room: _selectedHomeroom!.room,
              classDate: _selectedDate,
            )
          : await AttendanceService.listCourseAttendance(
              courseId: _selectedCourse!.id,
              classDate: _selectedDate,
            );
      if (!mounted) return;
      setState(() {
        _roster = items
            .map(
              (i) => AttendanceStudentRow(
                studentId: i.studentId,
                studentName: i.studentName,
                studentCode: i.studentCode,
                status: i.status ?? 'present',
              ),
            )
            .toList();
        _loadingRoster = false;
      });
    } catch (e) {
      debugPrint('Error loading attendance roster: $e');
      if (!mounted) return;
      setState(() {
        _loadingRoster = false;
        _error = 'โหลดรายชื่อนักเรียนไม่สำเร็จ';
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'เลือกวันที่เช็คชื่อ',
      confirmText: 'เลือก',
      cancelText: 'ยกเลิก',
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      await _loadRoster();
    }
  }

  Future<void> _save() async {
    if (_roster.isEmpty || _saving) return;
    setState(() => _saving = true);
    final records = _roster
        .map((r) => {'student_id': r.studentId, 'status': r.status})
        .toList();
    try {
      final isHomeroom = _mode == AttendanceMode.homeroom;
      final count = isHomeroom
          ? await AttendanceService.markHomeroomAttendance(
              gradeLevel: _selectedHomeroom!.gradeLevel,
              room: _selectedHomeroom!.room,
              classDate: _selectedDate,
              records: records,
            )
          : await AttendanceService.markAttendance(
              courseId: _selectedCourse!.id,
              classDate: _selectedDate,
              records: records,
            );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text('บันทึกการเช็คชื่อเรียบร้อยแล้ว ($count คน)'),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(child: Text('บันทึกไม่สำเร็จ กรุณาลองใหม่อีกครั้ง')),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _markAll(String status) {
    if (_roster.isEmpty) return;
    setState(() {
      for (final r in _roster) {
        r.status = status;
      }
    });
    final label = _statusDefs.firstWhere((s) => s.$1 == status).$2;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('กำหนดสถานะทุกคนเป็น "$label" แล้ว'),
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String get _dateLabelFormatted {
    final day = _selectedDate.day;
    final month = _thaiMonths[_selectedDate.month - 1];
    final year = _selectedDate.year + 543;
    return '$day $month $year';
  }

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  int _countOf(String status) => _roster.where((r) => r.status == status).length;

  List<AttendanceStudentRow> get _filteredRoster {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return _roster;
    return _roster.where((r) {
      return r.studentName.toLowerCase().contains(q) ||
          r.studentCode.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return TeacherMockPageShell(
      title: 'เช็คชื่อนักเรียน',
      activeMenuLabel: 'เช็คชื่อ',
      builder: (context, isDesktop) {
        if (_loadingClasses) {
          return const Padding(
            padding: EdgeInsets.only(top: 80),
            child: Center(
              child: CircularProgressIndicator(color: TeacherPalette.primary),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildModeSelector(),
                  const SizedBox(height: 16),
                  _buildSelectorAndControlBar(),
                  const SizedBox(height: 16),
                  if (_roster.isNotEmpty) ...[
                    _buildKpiSummaryGrid(),
                    const SizedBox(height: 16),
                  ],
                  if (_error != null) _buildErrorBanner(),
                  if (_loadingRoster)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: TeacherPalette.primary,
                        ),
                      ),
                    )
                  else if (_roster.isEmpty)
                    _buildEmptyState()
                  else
                    _buildRosterCard(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 650;
          final titleArea = Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF542E85), Color(0xFF7448A6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x28542E85),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.how_to_reg_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'เช็คชื่อนักเรียน',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E8FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE9D5FF)),
                          ),
                          child: Text(
                            _mode == AttendanceMode.homeroom
                                ? 'โฮมรูม'
                                : 'รายวิชา',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF7E22CE),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'บันทึกเวลาเรียน ติดตามการมาเรียน และวิเคราะห์ความพร้อมเพรียงของนักเรียนรายวัน',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final refreshBtn = IconButton.filledTonal(
            onPressed: () {
              _loadClasses();
            },
            tooltip: 'รีเฟรชข้อมูล',
            icon: const Icon(Icons.refresh_rounded, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF1F5F9),
              foregroundColor: const Color(0xFF334155),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleArea,
                const SizedBox(height: 12),
                Align(alignment: Alignment.centerRight, child: refreshBtn),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: titleArea),
              const SizedBox(width: 16),
              refreshBtn,
            ],
          );
        },
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModernModeTab(
              label: 'นักเรียนประจำชั้น (Homeroom)',
              sublabel: '${_homerooms.length} ห้องที่รับผิดชอบ',
              icon: Icons.co_present_rounded,
              selected: _mode == AttendanceMode.homeroom,
              enabled: _homerooms.isNotEmpty,
              onTap: () {
                if (_homerooms.isEmpty) return;
                setState(() => _mode = AttendanceMode.homeroom);
                _loadRoster();
              },
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _ModernModeTab(
              label: 'รายวิชาที่สอน (Courses)',
              sublabel: '${_courses.length} วิชาเปิดสอน',
              icon: Icons.auto_stories_rounded,
              selected: _mode == AttendanceMode.course,
              enabled: _courses.isNotEmpty,
              onTap: () {
                if (_courses.isEmpty) return;
                setState(() => _mode = AttendanceMode.course);
                _loadRoster();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorAndControlBar() {
    final isHomeroom = _mode == AttendanceMode.homeroom;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 800;

          final classDropdown = Container(
            constraints: BoxConstraints(maxWidth: isNarrow ? double.infinity : 320),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Row(
              children: [
                Icon(
                  isHomeroom ? Icons.meeting_room_rounded : Icons.menu_book_rounded,
                  size: 20,
                  color: const Color(0xFF542E85),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: isHomeroom
                        ? DropdownButton<HomeroomAssignment>(
                            value: _selectedHomeroom,
                            isExpanded: true,
                            hint: const Text('เลือกห้องประจำชั้น'),
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                            items: _homerooms
                                .map(
                                  (h) => DropdownMenuItem(
                                    value: h,
                                    child: Text(
                                      'ม.${h.gradeLevel}/${h.room} (${h.studentCount} คน)',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (h) {
                              setState(() => _selectedHomeroom = h);
                              _loadRoster();
                            },
                          )
                        : DropdownButton<CourseSummary>(
                            value: _selectedCourse,
                            isExpanded: true,
                            hint: const Text('เลือกรายวิชา'),
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                            items: _courses
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(
                                      c.subjectName,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (c) {
                              setState(() => _selectedCourse = c);
                              _loadRoster();
                            },
                          ),
                  ),
                ),
              ],
            ),
          );

          final dateButton = OutlinedButton.icon(
            onPressed: _pickDate,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              foregroundColor: const Color(0xFF0F172A),
              backgroundColor: const Color(0xFFF8FAFC),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(
              Icons.calendar_month_rounded,
              size: 18,
              color: Color(0xFF542E85),
            ),
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _dateLabelFormatted,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (_isToday) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'วันนี้',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF15803D),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );

          final quickActions = Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (_roster.isNotEmpty) ...[
                OutlinedButton.icon(
                  onPressed: () => _markAll('present'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    foregroundColor: const Color(0xFF10B981),
                    backgroundColor: const Color(0xFFECFDF5),
                    side: const BorderSide(color: Color(0xFFA7F3D0)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.done_all_rounded, size: 18),
                  label: const Text(
                    'เช็คมาทุกคน',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
              FilledButton.icon(
                onPressed: (_roster.isEmpty || _saving) ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF542E85),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_rounded, size: 18),
                label: Text(
                  _saving ? 'กำลังบันทึก...' : 'บันทึกการเช็คชื่อ',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          );

          return Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  classDropdown,
                  dateButton,
                ],
              ),
              quickActions,
            ],
          );
        },
      ),
    );
  }

  Widget _buildKpiSummaryGrid() {
    final total = _roster.length;
    final presentCount = _countOf('present');
    final lateCount = _countOf('late');
    final excusedCount = _countOf('excused');
    final absentCount = _countOf('absent');

    final presentPct = total > 0 ? ((presentCount / total) * 100).toStringAsFixed(0) : '0';

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isMobile = width < 680;
        final cardWidth = isMobile ? (width - 12) / 2 : (width - 36) / 4;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildKpiCard(
              title: 'มาเรียน',
              value: '$presentCount คน',
              subtitle: 'ความพร้อมเพรียง $presentPct%',
              icon: Icons.check_circle_rounded,
              color: const Color(0xFF10B981),
              bgColor: const Color(0xFFECFDF5),
              borderColor: const Color(0xFFA7F3D0),
              width: cardWidth,
            ),
            _buildKpiCard(
              title: 'มาสาย',
              value: '$lateCount คน',
              subtitle: 'เข้าห้องหลังเวลา',
              icon: Icons.access_time_filled_rounded,
              color: const Color(0xFFF59E0B),
              bgColor: const Color(0xFFFFFBEB),
              borderColor: const Color(0xFFFDE68A),
              width: cardWidth,
            ),
            _buildKpiCard(
              title: 'ลากิจ / ลาป่วย',
              value: '$excusedCount คน',
              subtitle: 'มีใบลาถูกต้อง',
              icon: Icons.assignment_turned_in_rounded,
              color: const Color(0xFF8B5CF6),
              bgColor: const Color(0xFFF5F3FF),
              borderColor: const Color(0xFFDDD6FE),
              width: cardWidth,
            ),
            _buildKpiCard(
              title: 'ขาดเรียน',
              value: '$absentCount คน',
              subtitle: 'ไม่ปรากฏตัว',
              icon: Icons.cancel_rounded,
              color: const Color(0xFFEF4444),
              bgColor: const Color(0xFFFEF2F2),
              borderColor: const Color(0xFFFECACA),
              width: cardWidth,
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required Color borderColor,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x040F172A),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFDC2626),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(
                color: Color(0xFF991B1B),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final noClasses = _mode == AttendanceMode.homeroom
        ? _homerooms.isEmpty
        : _courses.isEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 56),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              noClasses ? Icons.info_outline_rounded : Icons.people_outline_rounded,
              color: const Color(0xFF64748B),
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            noClasses
                ? (_mode == AttendanceMode.homeroom
                      ? 'คุณยังไม่ได้รับมอบหมายเป็นครูประจำชั้น'
                      : 'คุณยังไม่มีรายวิชาที่สอนในระบบ')
                : 'ไม่มีรายชื่อนักเรียนในห้องหรือวิชานี้',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'กรุณาตรวจสอบการมอบหมายภาระงานสอนหรือข้อมูลนักเรียนจากฝ่ายวิชาการ',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRosterCard() {
    final filtered = _filteredRoster;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header inside roster card
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.groups_2_rounded,
                  color: Color(0xFF542E85),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'รายชื่อนักเรียนทั้งหมด',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_roster.length} คน',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
              const Spacer(),
              // Search input
              SizedBox(
                width: 220,
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'ค้นหาชื่อ หรือรหัส...',
                    hintStyle: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF94A3B8),
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: Color(0xFF94A3B8),
                    ),
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Attendance Ratio Bar
          _buildAttendanceRatioBar(),
          const SizedBox(height: 16),

          // Students list
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 36),
              child: Center(
                child: Text(
                  'ไม่พบนักเรียนตรงกับคำค้น "$_searchQuery"',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, idx) {
                final row = filtered[idx];
                return _ModernRosterTile(
                  index: idx + 1,
                  row: row,
                  statusDefs: _statusDefs,
                  onChanged: () => setState(() {}),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAttendanceRatioBar() {
    final total = _roster.length;
    if (total == 0) return const SizedBox.shrink();

    final pCount = _countOf('present');
    final lCount = _countOf('late');
    final eCount = _countOf('excused');
    final aCount = _countOf('absent');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'สัดส่วนการเข้าเรียนวันนี้',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                ),
              ),
              Text(
                'มาเรียน ${((pCount / total) * 100).toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 7,
              child: Row(
                children: [
                  if (pCount > 0)
                    Expanded(
                      flex: pCount,
                      child: Container(color: const Color(0xFF10B981)),
                    ),
                  if (lCount > 0)
                    Expanded(
                      flex: lCount,
                      child: Container(color: const Color(0xFFF59E0B)),
                    ),
                  if (eCount > 0)
                    Expanded(
                      flex: eCount,
                      child: Container(color: const Color(0xFF8B5CF6)),
                    ),
                  if (aCount > 0)
                    Expanded(
                      flex: aCount,
                      child: Container(color: const Color(0xFFEF4444)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernModeTab extends StatelessWidget {
  const _ModernModeTab({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final String sublabel;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x0C0F172A),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF542E85)
                      : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: selected ? Colors.white : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                        color: selected
                            ? const Color(0xFF0F172A)
                            : const Color(0xFF64748B),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      sublabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? const Color(0xFF542E85)
                            : const Color(0xFF94A3B8),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModernRosterTile extends StatelessWidget {
  const _ModernRosterTile({
    required this.index,
    required this.row,
    required this.statusDefs,
    required this.onChanged,
  });

  final int index;
  final AttendanceStudentRow row;
  final List<(String, String, Color, IconData)> statusDefs;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x030F172A),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 620;

          final studentInfo = Row(
            children: [
              // Index number
              Container(
                width: 28,
                alignment: Alignment.center,
                child: Text(
                  '$index',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Student Avatar
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFF3E8FF),
                child: Text(
                  row.studentName.isNotEmpty
                      ? row.studentName.substring(0, 1)
                      : '?',
                  style: const TextStyle(
                    color: Color(0xFF542E85),
                    fontWeight: FontWeight.w900,
                    fontSize: 13.5,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.studentName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    if (row.studentCode.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'รหัสประจำตัว: ${row.studentCode}',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );

          final statusPicker = _ModernStatusDropdownPicker(
            currentStatus: row.status,
            statusDefs: statusDefs,
            onSelected: (newStatus) {
              row.status = newStatus;
              onChanged();
            },
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                studentInfo,
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: statusPicker,
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: studentInfo),
              const SizedBox(width: 12),
              statusPicker,
            ],
          );
        },
      ),
    );
  }
}

class _ModernStatusDropdownPicker extends StatelessWidget {
  const _ModernStatusDropdownPicker({
    required this.currentStatus,
    required this.statusDefs,
    required this.onSelected,
  });

  final String currentStatus;
  final List<(String, String, Color, IconData)> statusDefs;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final currentDef = statusDefs.firstWhere(
      (d) => d.$1 == currentStatus,
      orElse: () => statusDefs.first,
    );
    final (_, currentLabel, currentColor, currentIcon) = currentDef;

    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: PopupMenuThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          elevation: 6,
        ),
      ),
      child: PopupMenuButton<String>(
        initialValue: currentStatus,
        tooltip: 'คลิกเพื่อเปลี่ยนสถานะการมาเรียน',
        position: PopupMenuPosition.under,
        offset: const Offset(0, 6),
        onSelected: onSelected,
        itemBuilder: (context) {
          return statusDefs.map((def) {
            final (code, label, color, icon) = def;
            final isCurrent = currentStatus == code;
            return PopupMenuItem<String>(
              value: code,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 17),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                        color: isCurrent ? color : const Color(0xFF0F172A),
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isCurrent)
                    Icon(Icons.check_circle_rounded, color: color, size: 18)
                  else
                    const SizedBox(width: 18),
                ],
              ),
            );
          }).toList();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: currentColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: currentColor.withValues(alpha: 0.38),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(currentIcon, color: currentColor, size: 17),
              const SizedBox(width: 7),
              Text(
                currentLabel,
                style: TextStyle(
                  color: currentColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 5),
              Icon(
                Icons.arrow_drop_down_rounded,
                color: currentColor,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
