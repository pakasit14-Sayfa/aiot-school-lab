// PROTOTYPE — UI/UX เท่านั้น mock ทั้งหมด ยังไม่ผูก Supabase จริง
//
// LRN-12: ครูยืนยันคะแนนสะสม G-Score ก่อนแสดงผลให้นักเรียน — ระบบ (LRN-11)
// สะสมยอดรอยืนยันไว้เมื่อนักเรียนเรียนจบบทเรียน/ส่งงานตรงเวลา แต่ต้องผ่าน
// หน้านี้ก่อนนักเรียนถึงจะเห็นคะแนนจริง สอดคล้องหลักการ "ครูยืนยันขั้นสุดท้าย
// เสมอ" ที่ล็อกไว้ในวอลต์ — เพิ่มเมื่อ 2026-08-16 หลังพบว่า G-Score เดิมให้
// คะแนนอัตโนมัติทันทีไม่มีขั้นตอนนี้เลย (ดู student_redesign_prototype/
// NOTES.md และวอลต์ LRN-11/LRN-12 สำหรับที่มา)

import 'package:flutter/material.dart';

import 'teacher_redesign_prototype_page.dart' show TeacherPalette;
import 'teacher_shared_widgets.dart'
    show TeacherMockPageShell, TeacherSectionCard;
import 'teacher_student_support_page.dart' show TeacherStudentSupportPage;

/// dropdown ทางลัดไปหน้า prototype อื่นที่กำลังสร้างคู่กันในเซสชันนี้
/// แต่ยังไม่ได้ผูกเข้าเมนู sidebar จริง — วางไว้ข้างปุ่มแฮมเบอร์เกอร์
/// (จอแคบ) / ข้างชื่อหน้า (จอกว้าง) ผ่าน TeacherMockPageShell.
/// extraLeadingAction เอาไว้ก่อน ลบทิ้งได้ทันทีที่ผูกเข้าเมนูจริงแล้ว
Widget _buildWipMenu(BuildContext context) {
  return PopupMenuButton<VoidCallback>(
    tooltip: 'หน้าอื่นที่กำลังพัฒนา',
    icon: const Icon(Icons.explore_outlined, color: TeacherPalette.primary),
    onSelected: (action) => action(),
    itemBuilder: (context) => [
      PopupMenuItem<VoidCallback>(
        value: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TeacherStudentSupportPage()),
        ),
        child: const Text('นักเรียนที่ต้องการการสนับสนุน (AI-4..8)'),
      ),
    ],
  );
}

class _PendingGScoreEntry {
  _PendingGScoreEntry({
    required this.studentName,
    required this.courseName,
    required this.activityTitle,
    required this.points,
    required this.dateLabel,
  });

  final String studentName;
  final String courseName;
  final String activityTitle;
  final int points;
  final String dateLabel;
  bool confirmed = false;
}

List<_PendingGScoreEntry> _mockPendingEntries() => [
  _PendingGScoreEntry(
    studentName: 'ด.ช. ธนกร ใจดี',
    courseName: 'ม.5/2 AIoT สมาร์ตแล็บ',
    activityTitle: 'ส่งใบงาน: วิเคราะห์ข้อมูล PM2.5 จากเซนเซอร์จริง',
    points: 30,
    dateLabel: 'วันนี้ 10:12 น.',
  ),
  _PendingGScoreEntry(
    studentName: 'ด.ญ. พิมพ์ชนก แสงทอง',
    courseName: 'ม.5/2 AIoT สมาร์ตแล็บ',
    activityTitle: 'เรียนจบบทเรียน: การอ่านค่าเซนเซอร์วัดแสงแบบเรียลไทม์',
    points: 15,
    dateLabel: 'วันนี้ 09:40 น.',
  ),
  _PendingGScoreEntry(
    studentName: 'ด.ช. ปารมี ศรีสุข',
    courseName: 'ม.4/1 ฟิสิกส์ประยุกต์',
    activityTitle: 'ส่งใบงาน: พลังงานและการประหยัดไฟฟ้าในห้องเรียน',
    points: 25,
    dateLabel: 'เมื่อวาน 16:05 น.',
  ),
  _PendingGScoreEntry(
    studentName: 'ด.ญ. กัญญาพัชร รุ่งเรือง',
    courseName: 'ม.5/2 AIoT สมาร์ตแล็บ',
    activityTitle: 'เรียนจบบทเรียน: พื้นฐานเซนเซอร์และไมโครคอนโทรลเลอร์',
    points: 15,
    dateLabel: 'เมื่อวาน 14:22 น.',
  ),
];

class TeacherGScoreConfirmPage extends StatefulWidget {
  const TeacherGScoreConfirmPage({super.key});

  @override
  State<TeacherGScoreConfirmPage> createState() =>
      _TeacherGScoreConfirmPageState();
}

class _TeacherGScoreConfirmPageState extends State<TeacherGScoreConfirmPage> {
  late final List<_PendingGScoreEntry> _entries = _mockPendingEntries();

  List<_PendingGScoreEntry> get _pending =>
      _entries.where((e) => !e.confirmed).toList();

  void _showConfirmedSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _confirmOne(_PendingGScoreEntry entry) {
    setState(() => entry.confirmed = true);
    _showConfirmedSnackBar(
      'ยืนยันคะแนน +${entry.points} G-Score ให้ ${entry.studentName} แล้ว',
    );
  }

  void _confirmAll() {
    if (_pending.isEmpty) return;
    final count = _pending.length;
    setState(() {
      for (final e in _pending) {
        e.confirmed = true;
      }
    });
    _showConfirmedSnackBar('ยืนยันคะแนน G-Score ทั้งหมด $count รายการแล้ว');
  }

  @override
  Widget build(BuildContext context) {
    return TeacherMockPageShell(
      title: 'ยืนยันคะแนน G-Score',
      activeMenuLabel: 'คะแนน',
      extraLeadingAction: Builder(builder: _buildWipMenu),
      builder: (context, isDesktop) {
        final pending = _pending;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Text(
                'LRN-12: คะแนน G-Score ที่ระบบสะสมไว้จะยังไม่แสดงให้นักเรียนเห็น '
                'จนกว่าครูจะยืนยันที่นี่ — เห็นเฉพาะนักเรียนในรายวิชาที่คุณสอน',
                style: TextStyle(
                  color: Color(0xFF1D4ED8),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 14),
            TeacherSectionCard(
              title: 'รอยืนยัน (${pending.length} รายการ)',
              icon: Icons.pending_actions_rounded,
              trailing: pending.isEmpty
                  ? null
                  : TextButton.icon(
                      onPressed: _confirmAll,
                      icon: const Icon(Icons.done_all_rounded, size: 16),
                      label: const Text('ยืนยันทั้งหมด'),
                    ),
              child: pending.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'ไม่มีรายการรอยืนยันแล้ว',
                          style: TextStyle(
                            color: TeacherPalette.muted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < pending.length; i++) ...[
                          if (i != 0) const Divider(height: 20),
                          _PendingRow(
                            entry: pending[i],
                            onConfirm: () => _confirmOne(pending[i]),
                          ),
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

class _PendingRow extends StatelessWidget {
  const _PendingRow({required this.entry, required this.onConfirm});

  final _PendingGScoreEntry entry;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.star_rounded,
            color: Color(0xFFD97706),
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.studentName,
                style: const TextStyle(
                  color: TeacherPalette.ink,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                entry.activityTitle,
                style: const TextStyle(
                  color: TeacherPalette.softText,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${entry.courseName} · ${entry.dateLabel}',
                style: const TextStyle(
                  color: TeacherPalette.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '+${entry.points}',
              style: const TextStyle(
                color: Color(0xFFD97706),
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: TeacherPalette.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'ยืนยัน',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
