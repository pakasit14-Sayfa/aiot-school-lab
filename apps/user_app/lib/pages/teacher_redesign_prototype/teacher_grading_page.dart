// PROTOTYPE ONLY: "ตรวจงาน" — mock queue of submissions to grade, split into
// ด่วน/ปกติ/ตรวจแล้ว/ร่าง tabs, plus a "สร้างใบงาน" form where the teacher
// picks a publish status (เผยแพร่/ยังไม่เผยแพร่) for the new worksheet.
// UI/UX only, mock data, no backend.

import 'package:flutter/material.dart';

import 'teacher_redesign_prototype_page.dart' show TeacherPalette;
import 'teacher_shared_widgets.dart';

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

  /// สถานะเผยแพร่ของใบงาน — ใบงานตัวอย่างเดิมทั้งหมดถือว่าเผยแพร่แล้ว
  /// (นักเรียนเห็นและส่งงานได้) ใบงานใหม่ที่ครูสร้างเลือกได้ว่าจะเผยแพร่
  /// ทันทีหรือเก็บเป็นร่างไว้ก่อน — ร่างจะไม่ถูกนับในแท็บ ด่วน/ปกติ/
  /// ตรวจแล้ว เพราะยังไม่มีนักเรียนส่งงานจริง ไปอยู่แท็บ "ร่าง" แทน
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

class TeacherGradingPage extends StatefulWidget {
  const TeacherGradingPage({super.key});

  @override
  State<TeacherGradingPage> createState() => _TeacherGradingPageState();
}

class _TeacherGradingPageState extends State<TeacherGradingPage> {
  final List<_GradingItemMock> _items = List.of(_initialItems);

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
    final drafts = _items.where((i) => !i.isPublished).toList();
    final urgent = _items
        .where((i) => i.isPublished && i.bucket == _GradingBucket.urgent)
        .toList();
    final normal = _items
        .where((i) => i.isPublished && i.bucket == _GradingBucket.normal)
        .toList();
    final done = _items
        .where((i) => i.isPublished && i.bucket == _GradingBucket.done)
        .toList();

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: TeacherPalette.page,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: TeacherPalette.ink,
          title: const Text(
            'ตรวจงาน',
            style: TextStyle(
              color: TeacherPalette.ink,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton.icon(
                onPressed: _openCreateWorksheetSheet,
                icon: const Icon(Icons.add_rounded, size: 17),
                label: const Text('สร้างใบงาน'),
                style: FilledButton.styleFrom(
                  backgroundColor: TeacherPalette.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            labelColor: TeacherPalette.primary,
            unselectedLabelColor: TeacherPalette.muted,
            indicatorColor: TeacherPalette.primary,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
            tabs: [
              Tab(text: 'ด่วน (${urgent.length})'),
              Tab(text: 'ปกติ (${normal.length})'),
              Tab(text: 'ตรวจแล้ว (${done.length})'),
              Tab(text: 'ร่าง (${drafts.length})'),
            ],
          ),
        ),
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 900;
                return ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isDesktop ? 900 : 640),
                  child: TabBarView(
                    children: [
                      _GradingList(items: urgent, isDesktop: isDesktop),
                      _GradingList(items: normal, isDesktop: isDesktop),
                      _GradingList(items: done, isDesktop: isDesktop),
                      _GradingList(items: drafts, isDesktop: isDesktop),
                    ],
                  ),
                );
              },
            ),
          ),
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
          color: TeacherPalette.page,
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
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
  const _GradingList({required this.items, required this.isDesktop});

  final List<_GradingItemMock> items;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'ไม่มีงานในหมวดนี้',
            style: TextStyle(
              color: TeacherPalette.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isGrid = constraints.maxWidth >= 620;
          final cardWidth = isGrid
              ? (constraints.maxWidth - 14) / 2
              : constraints.maxWidth;
          return Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              for (final item in items)
                SizedBox(
                  width: cardWidth,
                  child: _GradingCard(item: item, isDesktop: isDesktop),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _GradingCard extends StatelessWidget {
  const _GradingCard({required this.item, required this.isDesktop});

  final _GradingItemMock item;
  final bool isDesktop;

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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TeacherPalette.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // แถบสีบางด้านบนบอกความเร่งด่วน/สถานะ แทนแท่งสีข้างซ้าย
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
          ),
          Padding(
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
                    onPressed: () => showTeacherMockAction(
                      context,
                      !item.isPublished
                          ? 'เผยแพร่: ${item.title}'
                          : 'ตรวจงาน: ${item.title}',
                    ),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
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
        ],
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
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
