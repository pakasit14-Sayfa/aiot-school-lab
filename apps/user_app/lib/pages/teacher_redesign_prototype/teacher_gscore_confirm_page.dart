// LRN-12: ครูยืนยันคะแนนสะสม G-Score ก่อนแสดงผลให้นักเรียน — เชื่อมกับ
// GScoreService จริงแล้ว (2026-08-21) เดิมเป็นหน้า placeholder บอกตรงๆ ว่า
// "ยังไม่มีตาราง/RPC รองรับ" ตอนนี้มีแล้ว: LRN-11 (สะสมแต้ม pending
// อัตโนมัติ) hook เข้า mark_lesson_complete/submit_assignment ตรงๆ, LRN-12
// (ยืนยันก่อนนักเรียนเห็น) คือหน้านี้ — ดู
// supabase/migrations/20260823030000_g_score.sql สำหรับที่มาเต็มๆ
import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import 'teacher_redesign_prototype_page.dart' show TeacherPalette;
import 'teacher_shared_widgets.dart'
    show TeacherMockPageShell, TeacherSectionCard;

class TeacherGScoreConfirmPage extends StatefulWidget {
  const TeacherGScoreConfirmPage({super.key});

  @override
  State<TeacherGScoreConfirmPage> createState() =>
      _TeacherGScoreConfirmPageState();
}

class _TeacherGScoreConfirmPageState extends State<TeacherGScoreConfirmPage> {
  bool _loading = true;
  String? _loadError;
  List<PendingGScoreEntry> _pending = [];
  final Set<String> _confirming = {};

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
      final pending = await GScoreService.listPendingGScore();
      if (!mounted) return;
      setState(() {
        _pending = pending;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = 'โหลดรายการรออนุมัติไม่สำเร็จ: $e';
        _loading = false;
      });
    }
  }

  Future<void> _confirm(PendingGScoreEntry entry) async {
    setState(() => _confirming.add(entry.id));
    try {
      await GScoreService.confirmGScore(entry.id);
      if (!mounted) return;
      setState(() {
        _pending.removeWhere((e) => e.id == entry.id);
        _confirming.remove(entry.id);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _confirming.remove(entry.id));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ยืนยันไม่สำเร็จ: $e')));
    }
  }

  String _sourceLabel(String source) => switch (source) {
    'lesson_completed' => 'เรียนจบบทเรียน',
    'assignment_on_time' => 'ส่งงานตรงเวลา',
    _ => source,
  };

  @override
  Widget build(BuildContext context) {
    return TeacherMockPageShell(
      title: 'ยืนยันคะแนน G-Score',
      activeMenuLabel: 'ยืนยัน G-Score',
      builder: (context, isDesktop) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.stars_rounded, size: 18, color: Color(0xFFD97706)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'G-Score: แต้มสะสม Gamification สำหรับนักเรียน โดยระบบจะคำนวณแต้มรออนุมัติเมื่อนักเรียนเรียนจบบทเรียน (+10) หรือส่งงานตรงเวลา (+15) '
                      'และจะแสดงผลในโปรไฟล์ของนักเรียนเมื่อครูกดยืนยันแล้วเท่านั้น (ตามหลักการ ครูยืนยันขั้นสุดท้ายเสมอ)',
                      style: TextStyle(
                        color: Color(0xFF92400E),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            TeacherSectionCard(
              title: 'รายการรออนุมัติคะแนน G-Score',
              icon: Icons.stars_rounded,
              child: _buildBody(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_loadError != null) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(child: Text(_loadError!)),
      );
    }
    if (_pending.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.stars_outlined, size: 56, color: Colors.amber.shade300),
              const SizedBox(height: 16),
              const Text(
                'ไม่มีรายการรออนุมัติในตอนนี้',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: TeacherPalette.ink,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'คะแนนใหม่จะขึ้นที่นี่อัตโนมัติเมื่อนักเรียนเรียนจบบทเรียนหรือส่งงานตรงเวลา',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: TeacherPalette.muted),
              ),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          for (var i = 0; i < _pending.length; i++) ...[
            if (i != 0) const Divider(height: 22),
            _PendingRow(
              entry: _pending[i],
              sourceLabel: _sourceLabel(_pending[i].source),
              confirming: _confirming.contains(_pending[i].id),
              onConfirm: () => _confirm(_pending[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _PendingRow extends StatelessWidget {
  const _PendingRow({
    required this.entry,
    required this.sourceLabel,
    required this.confirming,
    required this.onConfirm,
  });

  final PendingGScoreEntry entry;
  final String sourceLabel;
  final bool confirming;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFFFEF3C7),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.stars_rounded,
            size: 18,
            color: Color(0xFFD97706),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.studentFullName,
                style: const TextStyle(
                  color: TeacherPalette.ink,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '${entry.subjectName} · $sourceLabel',
                style: const TextStyle(
                  color: TeacherPalette.muted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '+${entry.points.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Color(0xFFD97706),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: confirming ? null : onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: TeacherPalette.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            minimumSize: Size.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: confirming
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'ยืนยัน',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
        ),
      ],
    );
  }
}
