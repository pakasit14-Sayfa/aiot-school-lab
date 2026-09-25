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
      // เชลล์เองมี SingleChildScrollView อยู่แล้วรอบ builder — ห่ามเพิ่มอีกชั้น
      // ในนี้ (เคยทำแล้วหน้าลากเลื่อนไม่ได้เลย เพราะ Scrollable ซ้อนกัน
      // แนวเดียวกันแย่ง gesture arena กัน) ลากลงเพื่อรีเฟรชจึงส่งผ่าน
      // onRefresh ให้เชลล์เป็นคนห่อ RefreshIndicator ให้แทน
      onRefresh: _loadClasses,
      builder: (context, isDesktop) {
        if (_loadingClasses) {
          return const Padding(
            padding: EdgeInsets.only(top: 80),
            child: Center(
              child: CircularProgressIndicator(color: TeacherPalette.primary),
            ),
          );
        }

        return Center(
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
        );
      },
    );
  }

  // เดิมสลับ Column (มือถือ) / Row (จอกว้าง) — โหมดมือถือเอาปุ่มรีเฟรช
  // ไปไว้คนละแถวจากหัวข้อ ทำให้เหลือแถวที่มีแค่ปุ่มเล็ก ๆ ลอยอยู่ชิดขวา
  // พื้นที่ว่างเยอะเปล่าประโยชน์ — รวมเป็น Row เดียวทุกขนาดจอแทน ปุ่มรีเฟรช
  // อยู่ติดหัวข้อเสมอ การ์ดจึงสูงเท่าที่เนื้อหาต้องการจริง ไม่มีแถวว่าง
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5DEEF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF6F0FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.how_to_reg_rounded,
              color: Color(0xFF542E85),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    const Text(
                      'เช็คชื่อนักเรียน',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF35204E),
                        letterSpacing: -0.2,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F0FA),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _mode == AttendanceMode.homeroom
                            ? 'โฮมรูม'
                            : 'รายวิชา',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF542E85),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                const Text(
                  'บันทึกเวลาเรียน ติดตามการมาเรียน และวิเคราะห์ความพร้อมเพรียงของนักเรียนรายวัน',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // แท็บสองโหมด (โฮมรูม/รายวิชา) — เดิมเป็นกล่องเทาที่มีแท็บลอยขาว+เงา
  // ข้างในสองบรรทัด (ชื่อ+จำนวนห้อง) เปลี่ยนเป็น segmented control ทรง
  // เม็ดยาบรรทัดเดียว ให้โทนเดียวกับฟิลด์/ปุ่มที่ปรับไปแล้วข้างล่าง
  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F0FA),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegTab(
              label: 'นักเรียนประจำชั้น',
              count: _homerooms.length,
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
          const SizedBox(width: 4),
          Expanded(
            child: _SegTab(
              label: 'รายวิชาที่สอน',
              count: _courses.length,
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

  // การ์ดใหญ่ใบเดียวที่เคยห่อฟิลด์+ปุ่มไว้ด้วยกันเปลี่ยนเป็นการ์ดลอยแยก
  // ทีละชิ้น (ขาว มุมโค้ง 16 เงานุ่ม) ตามตัวอย่างที่เจ้าของงานอนุมัติแล้ว —
  // แต่ละฟิลด์จึงเด่นเป็นอิสระ ไม่ต้องมีกรอบรวมซ้อนอีกชั้น
  static const List<BoxShadow> _floatingCardShadow = [
    BoxShadow(color: Color(0x1435204E), blurRadius: 16, offset: Offset(0, 6)),
  ];

  Widget _buildSelectorAndControlBar() {
    final isHomeroom = _mode == AttendanceMode.homeroom;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 800;

        final classDropdown = Container(
          constraints: BoxConstraints(maxWidth: isNarrow ? double.infinity : 320),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: _floatingCardShadow,
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

        final dateField = InkWell(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: _floatingCardShadow,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.calendar_month_rounded,
                  size: 18,
                  color: Color(0xFF542E85),
                ),
                const SizedBox(width: 10),
                Text(
                  _dateLabelFormatted,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
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
          ),
        );

        final markAllButton = OutlinedButton.icon(
          onPressed: () => _markAll('present'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 13),
            foregroundColor: const Color(0xFF10B981),
            backgroundColor: const Color(0xFFECFDF5),
            side: BorderSide.none,
            shape: const StadiumBorder(),
          ),
          icon: const Icon(Icons.done_all_rounded, size: 18),
          label: const Text(
            'เช็คมาทุกคน',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
        );

        final saveButton = FilledButton.icon(
          onPressed: (_roster.isEmpty || _saving) ? null : _save,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF542E85),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: const StadiumBorder(),
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
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
          ),
        );

        // แถวปุ่ม: จอแคบแบ่งครึ่งเท่ากันเหมือนตัวอย่าง จอกว้างให้ปุ่มกว้าง
        // ตามเนื้อหาแล้วชิดขวา ไม่ต้องยืดเต็มแถว
        final quickActions = isNarrow
            ? Row(
                children: [
                  if (_roster.isNotEmpty) ...[
                    Expanded(child: markAllButton),
                    const SizedBox(width: 10),
                  ],
                  Expanded(child: saveButton),
                ],
              )
            : Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (_roster.isNotEmpty) markAllButton,
                  saveButton,
                ],
              );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              classDropdown,
              const SizedBox(height: 10),
              dateField,
              const SizedBox(height: 10),
              quickActions,
            ],
          );
        }

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
              children: [classDropdown, dateField],
            ),
            quickActions,
          ],
        );
      },
    );
  }

  // การ์ด KPI เดิม (ไอคอน+ค่า+คำอธิบาย 3 บรรทัด, กรอบสี, เงา) เปลี่ยนเป็น
  // ชิปแบนตามตัวอย่างที่เจ้าของงานอนุมัติแล้ว — ตัวเลขใหญ่+ป้ายกำกับพอ
  // ไม่ต้องมีไอคอน/เงา/บรรทัดคำอธิบายซ้ำ
  Widget _buildKpiSummaryGrid() {
    final presentCount = _countOf('present');
    final lateCount = _countOf('late');
    final excusedCount = _countOf('excused');
    final absentCount = _countOf('absent');

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isMobile = width < 680;
        final cardWidth = isMobile ? (width - 12) / 2 : (width - 36) / 4;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildKpiChip(
              label: 'มาเรียน',
              value: '$presentCount คน',
              color: const Color(0xFF10B981),
              bgColor: const Color(0xFFECFDF5),
              borderColor: const Color(0xFFA7F3D0),
              width: cardWidth,
            ),
            _buildKpiChip(
              label: 'มาสาย',
              value: '$lateCount คน',
              color: const Color(0xFFF59E0B),
              bgColor: const Color(0xFFFFFBEB),
              borderColor: const Color(0xFFFDE68A),
              width: cardWidth,
            ),
            _buildKpiChip(
              label: 'ลากิจ / ลาป่วย',
              value: '$excusedCount คน',
              color: const Color(0xFF8B5CF6),
              bgColor: const Color(0xFFF5F3FF),
              borderColor: const Color(0xFFDDD6FE),
              width: cardWidth,
            ),
            _buildKpiChip(
              label: 'ขาดเรียน',
              value: '$absentCount คน',
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

  Widget _buildKpiChip({
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
    required Color borderColor,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: color,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
            ),
            overflow: TextOverflow.ellipsis,
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
          // Header inside roster card — the search field used to be a fixed
          // 220px box next to a Spacer, which overflowed by ~172px on phone
          // widths. Below ~480 it now drops to its own full-width row.
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 480;

              final titleRow = Row(
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
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
                  if (!isNarrow) const Spacer(),
                ],
              );

              final searchField = TextField(
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
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    titleRow,
                    const SizedBox(height: 10),
                    searchField,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: titleRow),
                  const SizedBox(width: 16),
                  SizedBox(width: 220, child: searchField),
                ],
              );
            },
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
            // กล่องเดียว หลายแถว คั่นด้วยเส้น — ตาม DESIGN_SYSTEM.md
            // "รายการบนมือถือ" แทนการ์ดแยกที่มีเงา+มุมโค้งต่อแถว (เดิมกิน
            // ความสูงเกือบเท่าตัวโดยไม่เพิ่มข้อมูล)
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(14),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (int idx = 0; idx < filtered.length; idx++) ...[
                    if (idx > 0)
                      const Divider(
                        height: 1,
                        indent: 62,
                        color: Color(0xFFE2E8F0),
                      ),
                    _RosterRow(
                      row: filtered[idx],
                      statusDefs: _statusDefs,
                      onChanged: () => setState(() {}),
                    ),
                  ],
                ],
              ),
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

class _SegTab extends StatelessWidget {
  const _SegTab({
    required this.label,
    required this.count,
    required this.icon,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final int count;
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
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF542E85) : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? Colors.white : const Color(0xFF7448A6),
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                    color: selected ? Colors.white : const Color(0xFF35204E),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 1,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    color: selected ? Colors.white : const Color(0xFF542E85),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// หนึ่งแถวในกล่องรายชื่อ (วงกลมอักษรแรก 34pt · ชื่อ 15/w800 · เมตา 12/muted
/// ตาม DESIGN_SYSTEM.md) — ไม่มีเงา/ขอบ/มุมโค้งของตัวเอง เพราะกรอบมาจาก
/// กล่องแม่ใน _buildRosterCard ที่ห่อแถวทั้งหมดไว้ใบเดียว
class _RosterRow extends StatelessWidget {
  const _RosterRow({
    required this.row,
    required this.statusDefs,
    required this.onChanged,
  });

  final AttendanceStudentRow row;
  final List<(String, String, Color, IconData)> statusDefs;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFF3E8FF),
              shape: BoxShape.circle,
            ),
            child: Text(
              row.studentName.isNotEmpty
                  ? row.studentName.substring(0, 1)
                  : '?',
              style: const TextStyle(
                color: Color(0xFF542E85),
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  row.studentName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                if (row.studentCode.isNotEmpty)
                  Text(
                    'รหัสประจำตัว: ${row.studentCode}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _StatusSegmentedPicker(
            currentStatus: row.status,
            statusDefs: statusDefs,
            onSelected: (newStatus) {
              row.status = newStatus;
              onChanged();
            },
          ),
        ],
      ),
    );
  }
}

/// แทนที่ dropdown เดิม (กด → เปิดเมนู → เลือก, 2 จังหวะ) ด้วยปุ่ม 4 ปุ่ม
/// กดสถานะได้ตรง ๆ จังหวะเดียว — ตามตัวอย่างที่เจ้าของงานอนุมัติแล้ว
class _StatusSegmentedPicker extends StatelessWidget {
  const _StatusSegmentedPicker({
    required this.currentStatus,
    required this.statusDefs,
    required this.onSelected,
  });

  final String currentStatus;
  final List<(String, String, Color, IconData)> statusDefs;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final def in statusDefs)
            _SegButton(
              def: def,
              active: currentStatus == def.$1,
              onTap: () => onSelected(def.$1),
            ),
        ],
      ),
    );
  }
}

class _SegButton extends StatelessWidget {
  const _SegButton({
    required this.def,
    required this.active,
    required this.onTap,
  });

  final (String, String, Color, IconData) def;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (_, label, color, icon) = def;
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 27,
          height: 27,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: active ? color : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 15,
            color: active ? Colors.white : const Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }
}
