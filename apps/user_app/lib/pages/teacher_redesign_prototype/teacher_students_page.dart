// PROTOTYPE ONLY: "นักเรียน" — mock roster with a per-student status so the
// teacher spots problems at a glance, filterable by room. UI/UX only, mock
// data, no backend.

import 'package:flutter/material.dart';

import 'teacher_redesign_prototype_page.dart' show TeacherPalette;
import 'teacher_shared_widgets.dart';

enum _StudentStatus { complete, pending, watch }

extension on _StudentStatus {
  String get label => switch (this) {
    _StudentStatus.complete => 'ส่งงานครบ',
    _StudentStatus.pending => 'งานค้าง',
    _StudentStatus.watch => 'ต้องติดตาม',
  };

  Color get color => switch (this) {
    _StudentStatus.complete => TeacherPalette.primary,
    _StudentStatus.pending => TeacherPalette.orange,
    _StudentStatus.watch => TeacherPalette.red,
  };
}

class _StudentMock {
  const _StudentMock({
    required this.name,
    required this.room,
    required this.status,
    required this.note,
  });

  final String name;
  final String room;
  final _StudentStatus status;
  final String note;
}

const _students = [
  _StudentMock(
    name: 'ณัฐวุฒิ ใจดี',
    room: 'ม.5/1',
    status: _StudentStatus.complete,
    note: 'ส่งงานล่าสุดครบทุกชิ้น',
  ),
  _StudentMock(
    name: 'ปวีณา สายทอง',
    room: 'ม.5/1',
    status: _StudentStatus.watch,
    note: 'ขาดส่งงาน 3 ชิ้นติดต่อกัน',
  ),
  _StudentMock(
    name: 'ธนกร วิจิตร',
    room: 'ม.5/1',
    status: _StudentStatus.pending,
    note: 'ค้างใบงาน AIoT บทที่ 4',
  ),
  _StudentMock(
    name: 'มนัสนันท์ ไพศาล',
    room: 'ม.5/2',
    status: _StudentStatus.complete,
    note: 'ส่งงานตรงเวลาทุกครั้ง',
  ),
  _StudentMock(
    name: 'ปิยะพงษ์ เจริญสุข',
    room: 'ม.5/2',
    status: _StudentStatus.pending,
    note: 'ค้างรายงานโครงงานเซนเซอร์',
  ),
  _StudentMock(
    name: 'กมลชนก ศรีสุข',
    room: 'ม.6/2',
    status: _StudentStatus.complete,
    note: 'คะแนนเฉลี่ยดีต่อเนื่อง',
  ),
  _StudentMock(
    name: 'อภิสิทธิ์ บุญมา',
    room: 'ม.6/2',
    status: _StudentStatus.watch,
    note: 'ขาดเรียน 2 ครั้งในสัปดาห์นี้',
  ),
  _StudentMock(
    name: 'ศิริพร แก้วมณี',
    room: 'ม.4/3',
    status: _StudentStatus.pending,
    note: 'ค้างส่งรายงานโครงงาน',
  ),
  _StudentMock(
    name: 'วรเมธ ทองสุข',
    room: 'ม.4/3',
    status: _StudentStatus.complete,
    note: 'ส่งงานตรงเวลาทุกครั้ง',
  ),
];

class TeacherStudentsPage extends StatefulWidget {
  const TeacherStudentsPage({super.key, this.initialRoomFilter});

  /// ห้องที่ให้กรองไว้ล่วงหน้าตอนเปิดหน้า — ใช้เวลากดมาจากหน้ารายละเอียด
  /// วิชา (ครูอยากเห็นเฉพาะนักเรียนของวิชานั้น ไม่ใช่ทุกวิชาปนกัน) ปล่อย
  /// ว่างไว้ถ้าเปิดจากเมนูหลัก (เห็นนักเรียนทุกห้อง)
  final List<String>? initialRoomFilter;

  @override
  State<TeacherStudentsPage> createState() => _TeacherStudentsPageState();
}

class _TeacherStudentsPageState extends State<TeacherStudentsPage> {
  late Set<String> _selectedRooms = {...?widget.initialRoomFilter};

  List<String> get _allRooms =>
      _students.map((s) => s.room).toSet().toList()..sort();

  List<_StudentMock> get _visibleStudents => _selectedRooms.isEmpty
      ? _students
      : _students.where((s) => _selectedRooms.contains(s.room)).toList();

  @override
  Widget build(BuildContext context) {
    final visible = _visibleStudents;
    final total = visible.length;
    final complete = visible
        .where((s) => s.status == _StudentStatus.complete)
        .length;
    final pending = visible
        .where((s) => s.status == _StudentStatus.pending)
        .length;
    final watch = visible.where((s) => s.status == _StudentStatus.watch).length;
    final isFiltered = _selectedRooms.isNotEmpty;

    return TeacherMockPageShell(
      title: 'นักเรียน',
      activeMenuLabel: 'นักเรียน',
      builder: (context, isDesktop) {
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
                final columns = isDesktop ? 4 : 2;
                return GridView.count(
                  crossAxisCount: columns,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: isDesktop ? 1.5 : 1.3,
                  children: [
                    TeacherStatCard(
                      label: 'นักเรียนทั้งหมด',
                      value: '$total',
                      icon: Icons.groups_2_rounded,
                      color: TeacherPalette.primary,
                    ),
                    TeacherStatCard(
                      label: 'ส่งงานครบ',
                      value: '$complete',
                      icon: Icons.check_circle_rounded,
                      color: TeacherPalette.skyDeep,
                    ),
                    TeacherStatCard(
                      label: 'งานค้าง',
                      value: '$pending',
                      icon: Icons.pending_actions_rounded,
                      color: TeacherPalette.orange,
                    ),
                    TeacherStatCard(
                      label: 'ต้องติดตาม',
                      value: '$watch',
                      icon: Icons.priority_high_rounded,
                      color: TeacherPalette.red,
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

  final _StudentMock student;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => showTeacherMockAction(context, student.name),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: student.status.color.withValues(alpha: 0.14),
                child: Text(
                  student.name.substring(0, 1),
                  style: TextStyle(
                    color: student.status.color,
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
                      '${student.room} · ${student.note}',
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
              const SizedBox(width: 8),
              TeacherStatusChip(
                label: student.status.label,
                color: student.status.color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
