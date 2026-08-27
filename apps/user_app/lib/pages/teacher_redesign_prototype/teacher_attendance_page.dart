// เช็คชื่อนักเรียน — สองโหมด: (1) นักเรียนประจำชั้นที่ครูดูแล
// (homeroom_assignments + homeroom_attendance_records) และ (2) นักเรียน
// ในรายวิชาที่ครูสอน (attendance_records เดิม ซึ่งมี RPC/AttendanceService
// พร้อมอยู่แล้วแต่ไม่เคยมีหน้าจอเรียกใช้จริงมาก่อน)
import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import 'teacher_redesign_prototype_page.dart' show TeacherPalette;
import 'teacher_shared_widgets.dart'
    show TeacherMockPageShell, TeacherSectionCard;

enum _AttendanceMode { homeroom, course }

const List<(String, String, Color)> _statusOptions = [
  ('present', 'มา', TeacherPalette.green),
  ('late', 'สาย', TeacherPalette.orange),
  ('excused', 'ลา', TeacherPalette.iris),
  ('absent', 'ขาด', TeacherPalette.red),
];

class _RosterRow {
  _RosterRow({
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
  const TeacherAttendancePage({super.key});

  @override
  State<TeacherAttendancePage> createState() => _TeacherAttendancePageState();
}

class _TeacherAttendancePageState extends State<TeacherAttendancePage> {
  _AttendanceMode _mode = _AttendanceMode.homeroom;
  bool _loadingClasses = true;
  List<HomeroomAssignment> _homerooms = [];
  List<CourseSummary> _courses = [];
  HomeroomAssignment? _selectedHomeroom;
  CourseSummary? _selectedCourse;
  DateTime _selectedDate = DateTime.now();
  bool _loadingRoster = false;
  bool _saving = false;
  String? _error;
  List<_RosterRow> _roster = [];

  @override
  void initState() {
    super.initState();
    _loadClasses();
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
      setState(() {
        _homerooms = homerooms;
        _courses = courses;
        _selectedHomeroom = homerooms.isNotEmpty ? homerooms.first : null;
        _selectedCourse = courses.isNotEmpty ? courses.first : null;
        _mode = homerooms.isNotEmpty
            ? _AttendanceMode.homeroom
            : _AttendanceMode.course;
        _loadingClasses = false;
      });
      await _loadRoster();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingClasses = false;
        _error = 'โหลดรายชื่อห้อง/รายวิชาไม่สำเร็จ';
      });
    }
  }

  Future<void> _loadRoster() async {
    final isHomeroom = _mode == _AttendanceMode.homeroom;
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
              (i) => _RosterRow(
                studentId: i.studentId,
                studentName: i.studentName,
                studentCode: i.studentCode,
                status: i.status ?? 'present',
              ),
            )
            .toList();
        _loadingRoster = false;
      });
    } catch (_) {
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
      final isHomeroom = _mode == _AttendanceMode.homeroom;
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
        SnackBar(content: Text('บันทึกการเช็คชื่อแล้ว ($count คน)')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกไม่สำเร็จ ลองใหม่อีกครั้ง')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String get _dateLabel =>
      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year + 543}';

  int _countOf(String status) => _roster.where((r) => r.status == status).length;

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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildModeSelector(),
            const SizedBox(height: 14),
            _buildSelectorCard(),
            const SizedBox(height: 14),
            if (_error != null) _buildErrorBanner(),
            if (_loadingRoster)
              const Padding(
                padding: EdgeInsets.only(top: 40),
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
        );
      },
    );
  }

  Widget _buildModeSelector() {
    return Row(
      children: [
        Expanded(
          child: _ModeTab(
            label: 'นักเรียนประจำชั้น',
            icon: Icons.co_present_rounded,
            selected: _mode == _AttendanceMode.homeroom,
            enabled: _homerooms.isNotEmpty,
            onTap: () {
              if (_homerooms.isEmpty) return;
              setState(() => _mode = _AttendanceMode.homeroom);
              _loadRoster();
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ModeTab(
            label: 'รายวิชาที่สอน',
            icon: Icons.menu_book_rounded,
            selected: _mode == _AttendanceMode.course,
            enabled: _courses.isNotEmpty,
            onTap: () {
              if (_courses.isEmpty) return;
              setState(() => _mode = _AttendanceMode.course);
              _loadRoster();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSelectorCard() {
    final isHomeroom = _mode == _AttendanceMode.homeroom;
    return TeacherSectionCard(
      title: isHomeroom ? 'ห้องประจำชั้น' : 'รายวิชาที่สอน',
      icon: isHomeroom ? Icons.co_present_rounded : Icons.menu_book_rounded,
      trailing: _roster.isNotEmpty
          ? FilledButton.icon(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: TeacherPalette.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: _saving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_rounded, size: 16),
              label: const Text('บันทึกการเช็คชื่อ'),
            )
          : null,
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 260,
            child: isHomeroom
                ? DropdownButtonFormField<HomeroomAssignment>(
                    value: _selectedHomeroom,
                    isExpanded: true,
                    decoration: _fieldDecoration('ห้องประจำชั้น'),
                    items: _homerooms
                        .map(
                          (h) => DropdownMenuItem(
                            value: h,
                            child: Text(
                              '${h.gradeLevel}/${h.room} (${h.studentCount} คน)',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (h) {
                      setState(() => _selectedHomeroom = h);
                      _loadRoster();
                    },
                  )
                : DropdownButtonFormField<CourseSummary>(
                    value: _selectedCourse,
                    isExpanded: true,
                    decoration: _fieldDecoration('รายวิชา'),
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
          OutlinedButton.icon(
            onPressed: _pickDate,
            style: OutlinedButton.styleFrom(
              foregroundColor: TeacherPalette.primary,
              side: const BorderSide(color: TeacherPalette.skyBright),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.calendar_today_rounded, size: 16),
            label: Text(_dateLabel),
          ),
          if (_roster.isNotEmpty) _buildStatusSummary(),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      filled: true,
      fillColor: TeacherPalette.skyLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: TeacherPalette.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: TeacherPalette.primary, width: 1.4),
      ),
    );
  }

  Widget _buildStatusSummary() {
    return Wrap(
      spacing: 8,
      children: _statusOptions.map((opt) {
        final (value, label, color) = opt;
        final count = _countOf(value);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$label $count',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 11.5,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildErrorBanner() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: TeacherPalette.red.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: TeacherPalette.red.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: TeacherPalette.red,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _error!,
                style: const TextStyle(
                  color: TeacherPalette.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final noClasses = _mode == _AttendanceMode.homeroom
        ? _homerooms.isEmpty
        : _courses.isEmpty;
    return TeacherSectionCard(
      title: 'รายชื่อนักเรียน',
      icon: Icons.groups_2_rounded,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Column(
            children: [
              Icon(
                noClasses ? Icons.info_outline_rounded : Icons.person_off_rounded,
                color: TeacherPalette.skyMid,
                size: 32,
              ),
              const SizedBox(height: 10),
              Text(
                noClasses
                    ? (_mode == _AttendanceMode.homeroom
                          ? 'คุณยังไม่ได้รับมอบหมายเป็นครูประจำชั้น'
                          : 'คุณยังไม่มีรายวิชาที่สอนอยู่')
                    : 'ไม่มีนักเรียนในรายชื่อนี้',
                style: const TextStyle(
                  color: TeacherPalette.softText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRosterCard() {
    return TeacherSectionCard(
      title: 'รายชื่อนักเรียน',
      icon: Icons.groups_2_rounded,
      trailing: Text(
        '${_roster.length} คน',
        style: const TextStyle(
          color: TeacherPalette.muted,
          fontWeight: FontWeight.w700,
          fontSize: 12.5,
        ),
      ),
      child: Column(
        children: _roster
            .map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _RosterTile(row: r, onChanged: () => setState(() {})),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _RosterTile extends StatelessWidget {
  const _RosterTile({required this.row, required this.onChanged});

  final _RosterRow row;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: TeacherPalette.skyLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 19,
            backgroundColor: TeacherPalette.primary.withValues(alpha: 0.14),
            child: Text(
              row.studentName.isNotEmpty ? row.studentName.substring(0, 1) : '?',
              style: const TextStyle(
                color: TeacherPalette.primary,
                fontWeight: FontWeight.w900,
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
                    color: TeacherPalette.ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                if (row.studentCode.isNotEmpty)
                  Text(
                    row.studentCode,
                    style: const TextStyle(
                      color: TeacherPalette.muted,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Wrap(
            spacing: 6,
            children: _statusOptions.map((opt) {
              final (value, label, color) = opt;
              final selected = row.status == value;
              return _StatusPill(
                label: label,
                color: color,
                selected: selected,
                onTap: () {
                  row.status = value;
                  onChanged();
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? color : TeacherPalette.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : TeacherPalette.softText,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  const _ModeTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? TeacherPalette.skyVivid : TeacherPalette.skyLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? TeacherPalette.primary : TeacherPalette.border,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? TeacherPalette.primary : TeacherPalette.softText,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: selected ? TeacherPalette.primary : TeacherPalette.softText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
