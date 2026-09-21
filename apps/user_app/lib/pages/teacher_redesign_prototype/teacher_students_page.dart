// เชื่อมกับ CourseService จริงแล้ว (2026-08-16) — เดิม mock ล้วน
//
// รายชื่อนักเรียนตอนนี้โหลดจริงจาก listCourseStudents ของทุกรายวิชาที่ครู
// สอน — ตัดสถานะ "ส่งงานครบ/งานค้าง/ต้องติดตาม" ทิ้ง เพราะเป็นตัวเลขที่
// สคีมาจริงไม่มีรองรับ (ต้องคำนวณจากการส่งงานทุกชิ้นซึ่งเป็นงานแยกต่างหาก
// ไม่ใช่สิ่งที่ควรเดา) เหลือแค่ข้อมูลที่ real ID จริง: ชื่อ/อีเมล/รายวิชาที่
// ลงทะเบียน/วันที่ลงทะเบียน
import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import 'teacher_redesign_prototype_page.dart' show TeacherPalette;
import 'teacher_shared_widgets.dart';

class _StudentRosterEntry {
  const _StudentRosterEntry({
    required this.studentId,
    required this.name,
    required this.email,
    required this.room,
    required this.enrolledAt,
  });

  final String studentId;
  final String name;
  final String email;
  final String room;
  final DateTime enrolledAt;
}

class TeacherStudentsPage extends StatefulWidget {
  const TeacherStudentsPage({
    super.key,
    this.initialRoomFilter,
    this.loadCourses,
    this.loadCourseStudents,
  });

  /// ห้องที่ให้กรองไว้ล่วงหน้าตอนเปิดหน้า — ใช้เวลากดมาจากหน้ารายละเอียด
  /// วิชา (ครูอยากเห็นเฉพาะนักเรียนของวิชานั้น ไม่ใช่ทุกวิชาปนกัน) ปล่อย
  /// ว่างไว้ถ้าเปิดจากเมนูหลัก (เห็นนักเรียนทุกห้อง)
  final List<String>? initialRoomFilter;

  /// Read seams threaded to the corresponding CourseService static calls
  /// in production.
  final Future<List<CourseSummary>> Function()? loadCourses;
  final Future<List<CourseStudent>> Function(String courseId)?
  loadCourseStudents;

  @override
  State<TeacherStudentsPage> createState() => _TeacherStudentsPageState();
}

class _TeacherStudentsPageState extends State<TeacherStudentsPage> {
  late Set<String> _selectedRooms = {...?widget.initialRoomFilter};
  bool _loading = true;
  String? _loadError;
  List<_StudentRosterEntry> _roster = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final loadCourses = widget.loadCourses ?? CourseService.listMyCourses;
      final loadStudents =
          widget.loadCourseStudents ?? CourseService.listCourseStudents;
      final courses = await loadCourses();
      final roster = <_StudentRosterEntry>[];
      for (final c in courses) {
        final room = c.room ?? c.gradeLevel ?? c.subjectName;
        List<CourseStudent> students;
        try {
          students = await loadStudents(c.id);
        } catch (_) {
          students = const [];
        }
        for (final s in students) {
          roster.add(
            _StudentRosterEntry(
              studentId: s.studentId,
              name: '${s.firstName} ${s.lastName}',
              email: s.email,
              room: room,
              enrolledAt: s.enrolledAt,
            ),
          );
        }
      }
      if (!mounted) return;
      setState(() {
        _roster = roster;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = 'โหลดรายชื่อนักเรียนไม่สำเร็จ';
        _loading = false;
      });
    }
  }

  List<String> get _allRooms =>
      _roster.map((s) => s.room).toSet().toList()..sort();

  List<_StudentRosterEntry> get _visibleStudents => _selectedRooms.isEmpty
      ? _roster
      : _roster.where((s) => _selectedRooms.contains(s.room)).toList();

  @override
  Widget build(BuildContext context) {
    return TeacherMockPageShell(
      title: 'นักเรียน',
      onRefresh: _load,
      activeMenuLabel: 'นักเรียน',
      builder: (context, isDesktop) {
        if (_loading) {
          return const Padding(
            padding: EdgeInsets.all(48),
            child: Center(
              child: CircularProgressIndicator(color: TeacherPalette.primary),
            ),
          );
        }
        if (_loadError != null) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _loadError!,
                  style: const TextStyle(
                    color: Color(0xFFDC2626),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(onPressed: _load, child: const Text('ลองใหม่')),
              ],
            ),
          );
        }
        final visible = _visibleStudents;
        final total = visible.length;
        final roomCount = visible.map((s) => s.room).toSet().length;
        final isFiltered = _selectedRooms.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isFiltered)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: TeacherPalette.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: TeacherPalette.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.filter_alt_rounded,
                      size: 16,
                      color: TeacherPalette.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'กรองเฉพาะห้อง: ${_selectedRooms.join(', ')}',
                        style: const TextStyle(
                          color: TeacherPalette.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _selectedRooms = {}),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'ล้างตัวกรอง',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // ชิปกรองตามห้อง — เลือกได้หลายห้องพร้อมกัน เพราะครูอาจอยาก
            // เทียบสองห้องที่ตัวเองสอนวิชาเดียวกันอยู่
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final room in _allRooms) ...[
                    _RoomChip(
                      label: room,
                      selected: _selectedRooms.contains(room),
                      onTap: () => setState(() {
                        if (_selectedRooms.contains(room)) {
                          _selectedRooms.remove(room);
                        } else {
                          _selectedRooms.add(room);
                        }
                      }),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = isDesktop ? 2 : 2;
                return GridView.count(
                  crossAxisCount: columns,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: isDesktop ? 2.2 : 1.5,
                  children: [
                    TeacherStatCard(
                      label: 'นักเรียนทั้งหมด',
                      value: '$total',
                      icon: Icons.groups_2_rounded,
                      color: TeacherPalette.primary,
                    ),
                    TeacherStatCard(
                      label: 'จำนวนห้อง/รายวิชา',
                      value: '$roomCount',
                      icon: Icons.meeting_room_rounded,
                      color: TeacherPalette.skyDeep,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            TeacherSectionCard(
              title: 'รายชื่อนักเรียน',
              icon: Icons.groups_2_rounded,
              child: visible.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'ไม่พบนักเรียนในห้องที่เลือก',
                        style: TextStyle(
                          color: TeacherPalette.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < visible.length; i++) ...[
                          _StudentRow(student: visible[i]),
                          if (i != visible.length - 1)
                            const Divider(height: 18, color: Color(0xFFE8EEF3)),
                        ],
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _RoomChip extends StatelessWidget {
  const _RoomChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? TeacherPalette.primary.withValues(alpha: 0.12)
          : Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? TeacherPalette.primary : TeacherPalette.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? TeacherPalette.primary : TeacherPalette.muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _StudentRow extends StatelessWidget {
  const _StudentRow({required this.student});

  final _StudentRosterEntry student;

  @override
  Widget build(BuildContext context) {
    // Tapping a row used to raise the "UI Prototype" snackbar. There is no
    // per-student page in this lane to open, so the row is not tappable.
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: TeacherPalette.primary.withValues(alpha: 0.14),
              child: Text(
                student.name.isNotEmpty ? student.name.substring(0, 1) : '?',
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
                    student.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: TeacherPalette.ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${student.room} · ${student.email}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: TeacherPalette.muted,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
