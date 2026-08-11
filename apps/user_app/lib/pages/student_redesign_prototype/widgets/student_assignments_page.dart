import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'student_redesign_palette.dart';

class StudentAssignmentsPage extends StatefulWidget {
  const StudentAssignmentsPage({super.key});

  @override
  State<StudentAssignmentsPage> createState() => _StudentAssignmentsPageState();
}

class _StudentAssignmentsPageState extends State<StudentAssignmentsPage> {
  int _selectedFilterIndex = 0;

  final List<String> _filters = [
    'ทั้งหมด (6)',
    'ด่วนต้องส่ง (2)',
    'กำลังทำ (2)',
    'ตรวจแล้ว (2)',
  ];

  static const _assignments = <AssignmentCardItem>[
    AssignmentCardItem(
      subject: 'วิชา AIoT สมาร์ตแล็บ',
      subjectCode: 'AIOT-501',
      subjectIcon: Icons.memory_rounded,
      title: 'ใบงานที่ 4: การคำนวณและประมวลผลค่าฝุ่น PM2.5 จากเซนเซอร์',
      dueDateText: 'กำหนดส่ง วันนี้ 23:59 น.',
      statusLabel: 'ด่วนที่สุด',
      statusColor: Color(0xFFDC2626),
      statusBg: Color(0xFFFEF2F2),
      gscorePoints: '+30',
      filterGroup: 1,
    ),
    AssignmentCardItem(
      subject: 'วิชา ฟิสิกส์ประยุกต์',
      subjectCode: 'PHYS-302',
      subjectIcon: Icons.bolt_rounded,
      title: 'รายงานการทดลองที่ 2: การหักเหของแสงผ่านปริซึมแก้ว',
      dueDateText: 'กำหนดส่ง พรุ่งนี้ 16:00 น.',
      statusLabel: 'ค้างส่ง',
      statusColor: Color(0xFFD97706),
      statusBg: Color(0xFFFFFBEB),
      gscorePoints: '+25',
      filterGroup: 1,
    ),
    AssignmentCardItem(
      subject: 'วิชา คณิตศาสตร์เพิ่มเติม',
      subjectCode: 'MATH-401',
      subjectIcon: Icons.calculate_rounded,
      title: 'แบบฝึกหัดเรื่อง: ความน่าจะเป็นและการจัดหมู่สถิติ',
      dueDateText: 'กำหนดส่ง 5 ส.ค. 2569',
      statusLabel: 'ร่างไว้ 50%',
      statusColor: Color(0xFF2563EB),
      statusBg: Color(0xFFEFF6FF),
      gscorePoints: '+20',
      filterGroup: 2,
    ),
    AssignmentCardItem(
      subject: 'วิชา ชีววิทยา',
      subjectCode: 'BIO-108',
      subjectIcon: Icons.eco_rounded,
      title: 'ใบงานสรุปวงจรชีวิตของแมลง',
      dueDateText: 'ส่งแล้ว วันนี้ 09:20 น.',
      statusLabel: 'ส่งแล้ว รอตรวจ',
      statusColor: Color(0xFF0284C7),
      statusBg: Color(0xFFEFF8FF),
      gscorePoints: '+18',
      filterGroup: 2,
      isCompleted: true,
    ),
    AssignmentCardItem(
      subject: 'วิชา วิทยาศาสตร์กายภาพ',
      subjectCode: 'SCI-204',
      subjectIcon: Icons.science_rounded,
      title: 'สรุปการวิเคราะห์สภาวะโลกร้อนและก๊าซเรือนกระจก',
      dueDateText: 'ส่งแล้ว 28 ก.ค. 2569',
      statusLabel: 'ตรวจแล้ว A+',
      statusColor: SchoolPalette.deepGreen,
      statusBg: SchoolPalette.softGreenBg,
      gscorePoints: '+30',
      score: '100/100',
      filterGroup: 3,
      isCompleted: true,
    ),
    AssignmentCardItem(
      subject: 'วิชา ชีววิทยา',
      subjectCode: 'BIO-105',
      subjectIcon: Icons.nature_people_rounded,
      title: 'ใบงานบันทึกการสังเกตการณ์การสังเคราะห์แสงของพืช',
      dueDateText: 'ส่งแล้ว 25 ก.ค. 2569',
      statusLabel: 'ตรวจแล้ว A',
      statusColor: SchoolPalette.deepGreen,
      statusBg: SchoolPalette.softGreenBg,
      gscorePoints: '+28',
      score: '95/100',
      filterGroup: 3,
      isCompleted: true,
    ),
  ];

  List<AssignmentCardItem> get _visibleAssignments {
    if (_selectedFilterIndex == 0) return _assignments;
    return _assignments
        .where((item) => item.filterGroup == _selectedFilterIndex)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        // เพจนี้ถูกใช้ทั้งเป็นแท็บหลัก (ไม่มีอะไรให้ pop) และถูก push
        // มาจากที่อื่น (การ์ดงานค้าง, quick action ฯลฯ) — โชว์ปุ่มย้อนกลับ
        // เฉพาะตอนที่ pop ได้จริงเท่านั้น ไม่งั้นจะมีปุ่มย้อนกลับค้างอยู่บนแท็บ
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: SchoolPalette.ink,
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text(
          'ใบงานและการบ้านของฉัน',
          style: TextStyle(
            color: SchoolPalette.ink,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;
                final isDesktop = screenWidth >= 1024;
                final horizontalPadding = screenWidth < 520 ? 14.0 : 16.0;

                return ConstrainedBox(
                  // เดิม 1000px บนจอกว้าง ทำให้ช่องว่างขวามือของการ์ด
                  // (แถวล่างที่มี Spacer คั่นกลาง) ห่างเกินไป — ลดลงให้
                  // เท่ากับหน้าบทเรียนเพื่อความสม่ำเสมอ
                  constraints: BoxConstraints(maxWidth: isDesktop ? 720 : 640),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummaryHeader(context),
                        const SizedBox(height: 18),
                        _buildFilterPills(),
                        const SizedBox(height: 16),
                        _buildAssignmentList(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: SchoolPalette.glassBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: SchoolPalette.softGreenBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: SchoolPalette.glassBorder),
                ),
                child: const Icon(
                  Icons.assignment_turned_in_rounded,
                  color: SchoolPalette.deepGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'สรุปงานประจำสัปดาห์',
                      style: TextStyle(
                        color: SchoolPalette.navy,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ตรวจสอบกำหนดส่งงานเพื่อไม่ให้พลาดคะแนน G-Score',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: SchoolPalette.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final tiles = [
                _SummaryStatTile(
                  value: '2',
                  label: 'ด่วนต้องส่ง',
                  color: const Color(0xFFDC2626),
                  bgTint: const Color(0xFFFEF2F2),
                  icon: Icons.priority_high_rounded,
                ),
                _SummaryStatTile(
                  value: '1',
                  label: 'กำลังทำ',
                  color: const Color(0xFF2563EB),
                  bgTint: const Color(0xFFEFF6FF),
                  icon: Icons.edit_note_rounded,
                ),
                _SummaryStatTile(
                  value: '2',
                  label: 'ตรวจแล้ว',
                  color: SchoolPalette.deepGreen,
                  bgTint: SchoolPalette.softGreenBg,
                  icon: Icons.check_circle_outline_rounded,
                ),
              ];

              if (constraints.maxWidth < 420) {
                return Column(
                  children: [
                    for (var i = 0; i < tiles.length; i++) ...[
                      tiles[i],
                      if (i != tiles.length - 1) const SizedBox(height: 8),
                    ],
                  ],
                );
              }

              return Row(
                children: [
                  for (var i = 0; i < tiles.length; i++) ...[
                    Expanded(child: tiles[i]),
                    if (i != tiles.length - 1) const SizedBox(width: 8),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPills() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(_filters.length, (index) {
          final isSelected = _selectedFilterIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: isSelected,
              label: Text(_filters[index]),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : SchoolPalette.navy,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                fontSize: 12.5,
              ),
              selectedColor: SchoolPalette.deepGreen,
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
                side: BorderSide(
                  color: isSelected
                      ? SchoolPalette.deepGreen
                      : SchoolPalette.glassBorder,
                ),
              ),
              onSelected: (selected) {
                setState(() => _selectedFilterIndex = index);
              },
            ),
          );
        }),
      ),
    );
  }

  Widget _buildAssignmentList() {
    final items = _visibleAssignments;

    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: SchoolPalette.glassBorder),
        ),
        child: Column(
          children: [
            Icon(
              Icons.inbox_rounded,
              size: 36,
              color: SchoolPalette.muted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 8),
            const Text(
              'ไม่มีงานในหมวดนี้',
              style: TextStyle(
                color: SchoolPalette.muted,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: items.map((item) {
        return Padding(padding: const EdgeInsets.only(bottom: 12), child: item);
      }).toList(),
    );
  }
}

class _SummaryStatTile extends StatelessWidget {
  const _SummaryStatTile({
    required this.value,
    required this.label,
    required this.color,
    required this.bgTint,
    required this.icon,
  });

  final String value;
  final String label;
  final Color color;
  final Color bgTint;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgTint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$value งาน',
                style: TextStyle(
                  color: color,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                label,
                style: TextStyle(
                  color: color.withValues(alpha: 0.85),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One mock attached file — tracks its own fake upload progress so the row
/// can show "0 KB of 120 KB · กำลังอัปโหลด..." with a bar, then flip to a
/// green "เสร็จสมบูรณ์" check once done, matching the reference dialog.
class _MockAttachedFile {
  _MockAttachedFile({required this.name, required this.totalKb});

  final String name;
  final int totalKb;
  double progress = 0;

  bool get isUploading => progress < 1.0;
  int get uploadedKb => (totalKb * progress).round();
}

/// One row in the attached-files list — dog-eared PDF icon + name/status +
/// either an upload progress bar or a completed check / delete trash icon,
/// matching the "Upload Files" reference's file-row layout.
class _AttachedFileRow extends StatelessWidget {
  const _AttachedFileRow({required this.file, required this.onRemove});

  final _MockAttachedFile file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 34,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                  ),
                  Positioned(
                    left: -2,
                    bottom: -3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'PDF',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 7,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: SchoolPalette.navy,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          '${file.uploadedKb} KB of ${file.totalKb} KB · ',
                          style: const TextStyle(
                            color: SchoolPalette.muted,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (file.isUploading) ...[
                          const SizedBox(
                            width: 9,
                            height: 9,
                            child: CircularProgressIndicator(strokeWidth: 1.6),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'กำลังอัปโหลด...',
                            style: TextStyle(
                              color: Color(0xFFD97706),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ] else ...[
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 12,
                            color: SchoolPalette.deepGreen,
                          ),
                          const SizedBox(width: 3),
                          const Text(
                            'เสร็จสมบูรณ์',
                            style: TextStyle(
                              color: SchoolPalette.deepGreen,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (!file.isUploading)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: SchoolPalette.muted,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          if (file.isUploading) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: file.progress,
                minHeight: 4,
                backgroundColor: const Color(0xFFE2E8F0),
                color: const Color(0xFF2563EB),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Full-fidelity redesign of the submit sheet matching the "Upload Files"
/// reference: icon+title+subtitle header with a close button, a dashed
/// dropzone with a "Browse File" button, file rows with simulated upload
/// progress that flips to a completed check, an "OR" divider, and a
/// (non-functional, UI-only) "Import from URL Link" field.
class _AssignmentSubmitterSheet extends StatefulWidget {
  const _AssignmentSubmitterSheet({
    required this.subject,
    required this.subjectCode,
    required this.title,
    required this.dueDateText,
    required this.gscorePoints,
  });

  final String subject;
  final String subjectCode;
  final String title;
  final String dueDateText;
  final String gscorePoints;

  @override
  State<_AssignmentSubmitterSheet> createState() =>
      _AssignmentSubmitterSheetState();
}

class _AssignmentSubmitterSheetState extends State<_AssignmentSubmitterSheet> {
  final List<_MockAttachedFile> _files = [];
  final List<Timer> _timers = [];

  void _addFile(String name, int totalKb) {
    final file = _MockAttachedFile(name: name, totalKb: totalKb);
    setState(() => _files.add(file));
    // ยังไม่มีปลายทางเซิร์ฟเวอร์จริงให้อัปโหลดไปจริงๆ (UI-only prototype)
    // เลยจำลองแถบความคืบหน้าไว้ให้ดูมีอนิเมชันเหมือนกำลังส่งไฟล์
    final timer = Timer.periodic(const Duration(milliseconds: 220), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => file.progress = (file.progress + 0.22).clamp(0.0, 1.0));
      if (file.progress >= 1.0) timer.cancel();
    });
    _timers.add(timer);
  }

  // เปิดตัวเลือกไฟล์จริงของเครื่อง (ไม่ใช่ชื่อไฟล์จำลองอีกต่อไป) — ยังคง
  // ไม่มีการอัปโหลดขึ้นเซิร์ฟเวอร์จริง แค่เลือกไฟล์จากเครื่องได้จริง
  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'mp4'],
    );
    if (result == null || !mounted) return;
    for (final pickedFile in result.files) {
      final sizeKb = (pickedFile.size / 1024).ceil();
      _addFile(pickedFile.name, sizeKb <= 0 ? 1 : sizeKb);
    }
  }

  @override
  void dispose() {
    for (final timer in _timers) {
      timer.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Icon(
                  Icons.cloud_upload_outlined,
                  color: SchoolPalette.deepGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'อัปโหลดไฟล์งาน',
                      style: TextStyle(
                        color: SchoolPalette.navy,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: SchoolPalette.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.close_rounded,
                  color: SchoolPalette.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(height: 1, color: SchoolPalette.glassBorder),
          const SizedBox(height: 14),
          Text(
            '${widget.subject} (${widget.subjectCode}) · ${widget.dueDateText}'
            ' · ⭐ ${widget.gscorePoints} G-Score',
            style: const TextStyle(
              color: SchoolPalette.muted,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          // กรอบเส้นประ — วาดเองด้วย CustomPaint เพราะ Flutter ไม่มี
          // dashed border สำเร็จรูป ให้ตรงกับตัวอย่างที่ส่งมา
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _pickFiles,
            child: CustomPaint(
              painter: _DashedBorderPainter(
                color: const Color(0xFFCBD5E1),
                radius: 16,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 26),
                child: Column(
                  children: [
                    const Icon(
                      Icons.cloud_upload_outlined,
                      color: SchoolPalette.muted,
                      size: 30,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'เลือกไฟล์หรือลากมาวางที่นี่',
                      style: TextStyle(
                        color: SchoolPalette.navy,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'รองรับ JPEG, PNG, PDF และ MP4 ไม่เกิน 50MB',
                      style: TextStyle(
                        color: SchoolPalette.muted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton(
                      onPressed: _pickFiles,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: SchoolPalette.navy,
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('เลือกไฟล์'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_files.isNotEmpty) ...[
            const SizedBox(height: 12),
            Column(
              children: [
                for (var i = 0; i < _files.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _AttachedFileRow(
                      file: _files[i],
                      onRemove: () => setState(() => _files.removeAt(i)),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'หรือ',
                  style: TextStyle(
                    color: SchoolPalette.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                'นำเข้าจากลิงก์ไฟล์',
                style: TextStyle(
                  color: SchoolPalette.navy,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.info_outline_rounded,
                size: 13,
                color: SchoolPalette.muted.withValues(alpha: 0.7),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.link_rounded,
                  size: 16,
                  color: SchoolPalette.muted.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'วางลิงก์ไฟล์ที่นี่',
                    style: TextStyle(
                      color: SchoolPalette.muted,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: SchoolPalette.navy,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('ปิดหน้าต่าง'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'ส่งใบงานเรียบร้อยแล้ว! รับ ${widget.gscorePoints} G-Score',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text('ยืนยันการส่งงาน'),
                  style: FilledButton.styleFrom(
                    backgroundColor: SchoolPalette.deepGreen,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Hand-rolled dashed rounded-rect border — Flutter has no built-in dashed
/// border, and this keeps the dropzone visually matching the reference
/// without pulling in an external package for one shape.
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    const dashWidth = 6.0;
    const gapWidth = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + gapWidth;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) => false;
}

class AssignmentCardItem extends StatelessWidget {
  const AssignmentCardItem({
    super.key,
    required this.subject,
    required this.subjectCode,
    required this.subjectIcon,
    required this.title,
    required this.dueDateText,
    required this.statusLabel,
    required this.statusColor,
    required this.statusBg,
    required this.gscorePoints,
    required this.filterGroup,
    this.score,
    this.isCompleted = false,
  });

  final String subject;
  final String subjectCode;
  final IconData subjectIcon;
  final String title;
  final String dueDateText;
  final String statusLabel;
  final Color statusColor;
  final Color statusBg;
  final String gscorePoints;
  final int filterGroup;
  final String? score;
  final bool isCompleted;

  void _showAssignmentSubmitterModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AssignmentSubmitterSheet(
        subject: subject,
        subjectCode: subjectCode,
        title: title,
        dueDateText: dueDateText,
        gscorePoints: gscorePoints,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ดีไซน์เดียวกับการ์ดบทเรียน (มุมโค้ง 24, ขอบเขียวจาง, เงา 2 ชั้น)
    // ให้ทั้งสองหน้าดูเป็นชุดเดียวกัน
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFBEDCD0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
          BoxShadow(
            color: Color(0x0E0F172A),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () => _showAssignmentSubmitterModal(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // แถวป้ายบนสุด: สถานะ + วิชา — สไตล์ tag-row ของการ์ด
                // งาน (To do / High / Website ฯลฯ) แทนกล่องไอคอนซ้ายเดิม
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_statusBadgeIcon, size: 12, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            subjectIcon,
                            size: 12,
                            color: SchoolPalette.navy,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$subjectCode · $subject',
                            style: const TextStyle(
                              color: SchoolPalette.navy,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SchoolPalette.navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    height: 1.3,
                  ),
                ),
                // กำหนดส่งไปอยู่แถวล่างสุด (ไอคอนปฏิทิน) แล้ว — โชว์
                // บรรทัดย่อยตรงนี้เฉพาะตอนมีคะแนนเท่านั้น กันไม่ให้
                // dueDateText ซ้ำกันสองที่ในการ์ดเดียว
                if (score != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.subdirectory_arrow_right_rounded,
                        size: 14,
                        color: SchoolPalette.muted,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          'คะแนน $score',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: SchoolPalette.muted,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Container(height: 1, color: SchoolPalette.glassBorder),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            '⭐$gscorePoints',
                            style: const TextStyle(
                              color: Color(0xFFD97706),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              height: 1,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 13,
                            color: statusColor,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              dueDateText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                height: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // ป้าย CTA ชัดเจนแทนวงแหวน % เฉยๆ — ผู้ทดสอบจริงมองไม่
                    // ออกว่าการ์ดนี้กดแล้วทำอะไรได้ ต้องบอกตรงๆ ว่า "ส่งงาน"
                    // /"ดูคะแนน" พร้อมลูกศร ไม่ใช่ปล่อยให้เดาเอง
                    _buildActionPill(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// เดียวกับสถานะที่ใช้ตัดสินใจปุ่ม CTA — ให้ป้ายบนสุดของการ์ดกับปุ่ม
  /// ล่างสุดสื่อความหมายตรงกัน แทนที่จะใช้ไอคอนเอกสารเดิมทุกสถานะเหมือนกัน
  /// จนแยกไม่ออกว่าส่งไปแล้วหรือยังไม่ได้ส่ง
  IconData get _statusBadgeIcon {
    if (score != null) return Icons.grading_rounded;
    if (isCompleted) return Icons.check_circle_rounded;
    return Icons.assignment_late_rounded;
  }

  Widget _buildActionPill() {
    final String label;
    final IconData icon;
    if (score != null) {
      label = 'ดูคะแนน';
      icon = Icons.grading_rounded;
    } else if (isCompleted) {
      label = 'ดูสถานะงาน';
      icon = Icons.check_circle_rounded;
    } else {
      label = 'ส่งงาน';
      icon = Icons.upload_file_rounded;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.arrow_forward_rounded,
            size: 14,
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}
