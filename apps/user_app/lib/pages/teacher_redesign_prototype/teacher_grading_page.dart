// PROTOTYPE ONLY: "ตรวจงาน" — mock queue of submissions to grade, split into
// ด่วน/ปกติ/ตรวจแล้ว/ร่าง buckets, filterable by ชั้นเรียน/ห้องเรียน, plus a
// "สร้างใบงาน" form where the teacher picks a publish status
// (เผยแพร่/ยังไม่เผยแพร่) for the new worksheet.
// UI/UX only, mock data, no backend.

import 'package:flutter/material.dart';

import 'teacher_redesign_prototype_page.dart' show TeacherPalette;
import 'teacher_shared_widgets.dart';
import 'teacher_submission_review_page.dart' show TeacherSubmissionRosterPage;

enum _GradingBucket { urgent, normal, done }

class _GradingItemMock {
  const _GradingItemMock({
    required this.title,
    required this.course,
    required this.room,
    required this.submitted,
    required this.total,
    required this.deadline,
    required this.bucket,
    this.isPublished = true,
  });

  final String title;
  final String course;
  final String room;
  final int submitted;
  final int total;
  final String deadline;
  final _GradingBucket bucket;

  /// ชั้นเรียนที่ตัดมาจากห้อง เช่น "ม.5/1" -> "ม.5" ใช้กรองแบบหยาบก่อน
  /// ค่อยกรองละเอียดเป็นห้องอีกที
  String get grade => room.contains('/') ? room.split('/').first : room;

  /// สถานะเผยแพร่ของใบงาน — ใบงานตัวอย่างเดิมทั้งหมดถือว่าเผยแพร่แล้ว
  /// (นักเรียนเห็นและส่งงานได้) ใบงานใหม่ที่ครูสร้างเลือกได้ว่าจะเผยแพร่
  /// ทันทีหรือเก็บเป็นร่างไว้ก่อน — ร่างจะไม่ถูกนับในหมวด ด่วน/ปกติ/
  /// ตรวจแล้ว เพราะยังไม่มีนักเรียนส่งงานจริง ไปอยู่หมวด "ร่าง" แทน
  final bool isPublished;
}

final _initialItems = [
  _GradingItemMock(
    title: 'ใบงาน: วัดค่า PM2.5 รอบเช้า',
    course: 'AIOT-501',
    room: 'ม.5/1',
    submitted: 28,
    total: 32,
    deadline: 'ปิดรับ 2 ชม.',
    bucket: _GradingBucket.urgent,
  ),
  _GradingItemMock(
    title: 'รายงาน: ระบบรดน้ำอัตโนมัติ',
    course: 'PBL-110',
    room: 'ม.5/1',
    submitted: 14,
    total: 32,
    deadline: 'ปิดรับวันนี้ 18:00',
    bucket: _GradingBucket.urgent,
  ),
  _GradingItemMock(
    title: 'แบบฝึกหัด: แรงและการเคลื่อนที่',
    course: 'PHYS-302',
    room: 'ม.6/2',
    submitted: 22,
    total: 28,
    deadline: 'ปิดรับพรุ่งนี้',
    bucket: _GradingBucket.normal,
  ),
  _GradingItemMock(
    title: 'ใบงาน: ห่วงโซ่อาหารในระบบนิเวศ',
    course: 'BIO-204',
    room: 'ม.4/3',
    submitted: 26,
    total: 30,
    deadline: 'ปิดรับ 3 วัน',
    bucket: _GradingBucket.normal,
  ),
  _GradingItemMock(
    title: 'ใบงาน: เซนเซอร์ความชื้นเบื้องต้น',
    course: 'AIOT-501',
    room: 'ม.5/1',
    submitted: 32,
    total: 32,
    deadline: 'ตรวจแล้ว',
    bucket: _GradingBucket.done,
  ),
  _GradingItemMock(
    title: 'แบบทดสอบย่อย: หน่วยที่ 3',
    course: 'PHYS-302',
    room: 'ม.6/2',
    submitted: 28,
    total: 28,
    deadline: 'ตรวจแล้ว',
    bucket: _GradingBucket.done,
  ),
];

const _allFilter = 'ทั้งหมด';

class TeacherGradingPage extends StatefulWidget {
  const TeacherGradingPage({super.key});

  @override
  State<TeacherGradingPage> createState() => _TeacherGradingPageState();
}

class _TeacherGradingPageState extends State<TeacherGradingPage> {
  final List<_GradingItemMock> _items = List.of(_initialItems);
  String _gradeFilter = _allFilter;
  String _roomFilter = _allFilter;
  int _bucketIndex = 0; // 0=ด่วน 1=ปกติ 2=ตรวจแล้ว 3=ร่าง

  List<String> get _grades => [
    _allFilter,
    ...{for (final i in _items) i.grade}.toList()..sort(),
  ];

  List<String> get _roomsForSelectedGrade => [
    _allFilter,
    ...{
      for (final i in _items)
        if (_gradeFilter == _allFilter || i.grade == _gradeFilter) i.room,
    }.toList()..sort(),
  ];

  void _setGradeFilter(String grade) {
    setState(() {
      _gradeFilter = grade;
      // ถ้าห้องที่เลือกไว้ไม่ได้อยู่ในชั้นใหม่ที่กรอง ให้รีเซ็ตกลับ "ทั้งหมด"
      final stillValid =
          grade == _allFilter ||
          _items.any((i) => i.grade == grade && i.room == _roomFilter);
      if (!stillValid) _roomFilter = _allFilter;
    });
  }

  Future<void> _openCreateWorksheetSheet() async {
    final result = await showModalBottomSheet<_GradingItemMock>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _CreateWorksheetSheet(),
    );
    if (result == null) return;
    setState(() => _items.insert(0, result));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.isPublished
              ? 'สร้างและเผยแพร่ใบงาน "${result.title}" แล้ว (mock)'
              : 'บันทึกใบงาน "${result.title}" เป็นร่างแล้ว (mock)',
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _items.where((i) {
      if (_gradeFilter != _allFilter && i.grade != _gradeFilter) return false;
      if (_roomFilter != _allFilter && i.room != _roomFilter) return false;
      return true;
    }).toList();

    final buckets = [
      filtered
          .where((i) => i.isPublished && i.bucket == _GradingBucket.urgent)
          .toList(),
      filtered
          .where((i) => i.isPublished && i.bucket == _GradingBucket.normal)
          .toList(),
      filtered
          .where((i) => i.isPublished && i.bucket == _GradingBucket.done)
          .toList(),
      filtered.where((i) => !i.isPublished).toList(),
    ];

    return TeacherMockPageShell(
      title: 'ตรวจงาน',
      activeMenuLabel: 'ตรวจงาน',
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: _PillActionButton(
            icon: Icons.add_circle_rounded,
            label: 'สร้างใบงาน',
            onTap: _openCreateWorksheetSheet,
          ),
        ),
      ],
      builder: (context, isDesktop) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BucketStatRow(
              buckets: buckets,
              selectedIndex: _bucketIndex,
              onSelected: (i) => setState(() => _bucketIndex = i),
            ),
            const SizedBox(height: 16),
            _GradeRoomFilterRow(
              grades: _grades,
              rooms: _roomsForSelectedGrade,
              selectedGrade: _gradeFilter,
              selectedRoom: _roomFilter,
              onGradeChanged: _setGradeFilter,
              onRoomChanged: (room) => setState(() => _roomFilter = room),
            ),
            const SizedBox(height: 12),
            _GradingList(items: buckets[_bucketIndex]),
          ],
        );
      },
    );
  }
}

class _PillActionButton extends StatelessWidget {
  const _PillActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: TeacherPalette.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
      ),
    );
  }
}

/// แถวสถิติ 4 หมวด (ด่วน/ปกติ/ตรวจแล้ว/ร่าง) ที่เป็นทั้งตัวเลขสรุปและปุ่ม
/// สลับหมวดในตัวเดียวกัน — แตะการ์ดไหนก็สลับไปหมวดนั้นทันที แทนแท็บข้อความ
/// เฉยๆ แบบเดิม ให้เห็นภาพรวมงานค้างตั้งแต่แรกเห็นโดยไม่ต้องอ่านตัวเลข
class _BucketStatRow extends StatelessWidget {
  const _BucketStatRow({
    required this.buckets,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<List<_GradingItemMock>> buckets;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _labels = ['ด่วน', 'ปกติ', 'ตรวจแล้ว', 'ร่าง'];
  static const _icons = [
    Icons.bolt_rounded,
    Icons.assignment_outlined,
    Icons.check_circle_rounded,
    Icons.edit_note_rounded,
  ];
  static const _colors = [
    TeacherPalette.red,
    TeacherPalette.skyDeep,
    TeacherPalette.primary,
    TeacherPalette.muted,
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 560;
        final gap = 10.0;
        final cardWidth = isNarrow
            ? (constraints.maxWidth - gap) / 2
            : (constraints.maxWidth - gap * 3) / 4;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (int i = 0; i < 4; i++)
              SizedBox(
                width: cardWidth,
                child: _BucketStatCard(
                  label: _labels[i],
                  count: buckets[i].length,
                  icon: _icons[i],
                  color: _colors[i],
                  selected: selectedIndex == i,
                  onTap: () => onSelected(i),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _BucketStatCard extends StatelessWidget {
  const _BucketStatCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? color : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? color : TeacherPalette.border,
              width: selected ? 0 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : const [
                    BoxShadow(
                      color: Color(0x060F172A),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: selected ? Colors.white : color),
              const SizedBox(height: 10),
              Text(
                '$count',
                style: TextStyle(
                  color: selected ? Colors.white : TeacherPalette.ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.9)
                      : TeacherPalette.muted,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ตัวกรองชั้นเรียน/ห้องเรียนแบบ dropdown pill แถวเดียว ประหยัดพื้นที่แนวตั้ง
/// กว่าชิปหลายแถว — เลือกชั้นก่อนแล้วรายการห้องจะกรองตามชั้นที่เลือกให้
/// อัตโนมัติ ช่วยครูที่สอนหลายห้อง/หลายชั้นหาใบงานที่ต้องการตรวจได้เร็วขึ้น
class _GradeRoomFilterRow extends StatelessWidget {
  const _GradeRoomFilterRow({
    required this.grades,
    required this.rooms,
    required this.selectedGrade,
    required this.selectedRoom,
    required this.onGradeChanged,
    required this.onRoomChanged,
  });

  final List<String> grades;
  final List<String> rooms;
  final String selectedGrade;
  final String selectedRoom;
  final ValueChanged<String> onGradeChanged;
  final ValueChanged<String> onRoomChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _FilterDropdownPill(
          icon: Icons.class_outlined,
          prefixLabel: 'ชั้นเรียน',
          value: selectedGrade,
          options: grades,
          onChanged: onGradeChanged,
        ),
        const SizedBox(width: 8),
        _FilterDropdownPill(
          icon: Icons.door_front_door_outlined,
          prefixLabel: 'ห้องเรียน',
          value: selectedRoom,
          options: rooms,
          onChanged: onRoomChanged,
        ),
        if (selectedGrade != _allFilter || selectedRoom != _allFilter) ...[
          const SizedBox(width: 8),
          InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () {
              onGradeChanged(_allFilter);
              onRoomChanged(_allFilter);
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Text(
                'ล้างตัวกรอง',
                style: TextStyle(
                  color: TeacherPalette.red,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _FilterDropdownPill extends StatelessWidget {
  const _FilterDropdownPill({
    required this.icon,
    required this.prefixLabel,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final IconData icon;
  final String prefixLabel;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final isAll = value == _allFilter;
    return PopupMenuButton<String>(
      onSelected: onChanged,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      offset: const Offset(0, 42),
      itemBuilder: (context) => [
        for (final option in options)
          PopupMenuItem(
            value: option,
            child: Text(
              option,
              style: TextStyle(
                fontWeight: option == value ? FontWeight.w900 : FontWeight.w600,
                color: option == value
                    ? TeacherPalette.primary
                    : TeacherPalette.ink,
              ),
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isAll
              ? Colors.white
              : TeacherPalette.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isAll ? TeacherPalette.border : TeacherPalette.primary,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isAll ? TeacherPalette.muted : TeacherPalette.primary,
            ),
            const SizedBox(width: 6),
            Text(
              isAll ? prefixLabel : value,
              style: TextStyle(
                color: isAll ? TeacherPalette.muted : TeacherPalette.primary,
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.expand_more_rounded,
              size: 16,
              color: isAll ? TeacherPalette.muted : TeacherPalette.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateWorksheetSheet extends StatefulWidget {
  const _CreateWorksheetSheet();

  @override
  State<_CreateWorksheetSheet> createState() => _CreateWorksheetSheetState();
}

class _CreateWorksheetSheetState extends State<_CreateWorksheetSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _courseCtrl = TextEditingController();
  final _roomCtrl = TextEditingController();
  bool _isPublished = true;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _courseCtrl.dispose();
    _roomCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _GradingItemMock(
        title: _titleCtrl.text.trim(),
        course: _courseCtrl.text.trim(),
        room: _roomCtrl.text.trim(),
        submitted: 0,
        total: 0,
        deadline: _isPublished ? 'เพิ่งเผยแพร่' : 'ยังไม่เผยแพร่',
        bucket: _GradingBucket.normal,
        isPublished: _isPublished,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: TeacherPalette.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: TeacherPalette.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const Text(
                  'สร้างใบงานใหม่',
                  style: TextStyle(
                    color: TeacherPalette.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16),
                _FormField(
                  controller: _titleCtrl,
                  label: 'ชื่อใบงาน',
                  hint: 'เช่น ใบงาน: วัดค่าฝุ่น PM2.5',
                ),
                const SizedBox(height: 12),
                _FormField(
                  controller: _courseCtrl,
                  label: 'รหัสวิชา',
                  hint: 'เช่น AIOT-501',
                ),
                const SizedBox(height: 12),
                _FormField(
                  controller: _roomCtrl,
                  label: 'ห้องเรียน',
                  hint: 'เช่น ม.5/1',
                ),
                const SizedBox(height: 16),
                const Text(
                  'สถานะ',
                  style: TextStyle(
                    color: TeacherPalette.ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _StatusChoiceTile(
                        label: 'เผยแพร่',
                        subtitle: 'นักเรียนเห็นและส่งงานได้ทันที',
                        icon: Icons.public_rounded,
                        selected: _isPublished,
                        onTap: () => setState(() => _isPublished = true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatusChoiceTile(
                        label: 'ยังไม่เผยแพร่',
                        subtitle: 'บันทึกเป็นร่างไว้ก่อน',
                        icon: Icons.edit_note_rounded,
                        selected: !_isPublished,
                        onTap: () => setState(() => _isPublished = false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: TeacherPalette.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: const StadiumBorder(),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    child: Text(
                      _isPublished ? 'สร้างและเผยแพร่' : 'บันทึกร่าง',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChoiceTile extends StatelessWidget {
  const _StatusChoiceTile({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? TeacherPalette.primary.withValues(alpha: 0.1)
          : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? TeacherPalette.primary : TeacherPalette.border,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? TeacherPalette.primary : TeacherPalette.muted,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected ? TeacherPalette.primary : TeacherPalette.ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: TeacherPalette.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
  });

  final TextEditingController controller;
  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: TeacherPalette.ink,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: (value) =>
              (value == null || value.trim().isEmpty) ? 'กรอกข้อมูลนี้' : null,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: TeacherPalette.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: TeacherPalette.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: TeacherPalette.primary,
                width: 1.6,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GradingList extends StatelessWidget {
  const _GradingList({required this.items});

  final List<_GradingItemMock> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: TeacherPalette.border),
        ),
        child: const Text(
          'ไม่มีงานในหมวดนี้',
          style: TextStyle(
            color: TeacherPalette.muted,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1180
            ? 3
            : (constraints.maxWidth >= 620 ? 2 : 1);
        final cardWidth = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - 14 * (columns - 1)) / columns;
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            for (final item in items)
              SizedBox(
                width: cardWidth,
                child: _GradingCard(item: item),
              ),
          ],
        );
      },
    );
  }
}

class _GradingCard extends StatelessWidget {
  const _GradingCard({required this.item});

  final _GradingItemMock item;

  @override
  Widget build(BuildContext context) {
    final isDone = item.bucket == _GradingBucket.done;
    final accent = !item.isPublished
        ? TeacherPalette.muted
        : switch (item.bucket) {
            _GradingBucket.urgent => TeacherPalette.red,
            _GradingBucket.normal => TeacherPalette.skyDeep,
            _GradingBucket.done => TeacherPalette.primary,
          };
    final ratio = item.total == 0 ? 0.0 : item.submitted / item.total;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: const BorderSide(color: TeacherPalette.border),
            right: const BorderSide(color: TeacherPalette.border),
            bottom: const BorderSide(color: TeacherPalette.border),
            left: BorderSide(color: accent, width: 5),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x060F172A),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // วงแหวนแสดงสัดส่วนส่งงานแล้ว แทนไอคอนเฉยๆ ให้เห็น
                  // ความคืบหน้าได้ทันทีโดยไม่ต้องอ่านตัวเลข
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: item.total == 0 ? 0 : ratio,
                          strokeWidth: 3,
                          backgroundColor: accent.withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation(accent),
                        ),
                        Icon(
                          isDone
                              ? Icons.check_rounded
                              : Icons.assignment_outlined,
                          size: 16,
                          color: accent,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: TeacherPalette.ink,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            if (!item.isPublished) ...[
                              const SizedBox(width: 6),
                              const TeacherStatusChip(
                                label: 'ร่าง',
                                color: TeacherPalette.muted,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item.course} · ${item.room}',
                          style: const TextStyle(
                            color: TeacherPalette.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _GradingMetaTag(
                    icon: Icons.groups_outlined,
                    label: 'ส่งแล้ว ${item.submitted}/${item.total} คน',
                    color: accent,
                  ),
                  _GradingMetaTag(
                    icon: Icons.schedule_rounded,
                    label: item.deadline,
                    color: accent,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    if (!item.isPublished) {
                      showTeacherMockAction(context, 'เผยแพร่: ${item.title}');
                      return;
                    }
                    // ASM-7: เปิดหน้ารายชื่อนักเรียนที่ส่งงาน → ให้คะแนน
                    // ทีละคนตาม Rubric จริง แทนที่จะเป็นแค่ mock action ลอยๆ
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TeacherSubmissionRosterPage(
                          worksheetTitle: item.title,
                          courseLabel: '${item.course} · ${item.room}',
                        ),
                      ),
                    );
                  },
                  icon: Icon(
                    !item.isPublished
                        ? Icons.publish_rounded
                        : (isDone
                              ? Icons.visibility_outlined
                              : Icons.rate_review_outlined),
                    size: 16,
                  ),
                  label: Text(
                    !item.isPublished
                        ? 'เผยแพร่'
                        : (isDone ? 'ดูผล' : 'ตรวจงาน'),
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    backgroundColor: isDone
                        ? TeacherPalette.muted.withValues(alpha: 0.5)
                        : accent,
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
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

class _GradingMetaTag extends StatelessWidget {
  const _GradingMetaTag({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: TeacherPalette.card,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: TeacherPalette.muted,
            ),
          ),
        ],
      ),
    );
  }
}
