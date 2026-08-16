// PROTOTYPE — UI/UX เท่านั้น mock ทั้งหมด ยังไม่ผูก Supabase จริง
//
// AI-4/AI-5/AI-6/AI-7/AI-8: หน้ารวม "นักเรียนที่ต้องการการสนับสนุน" —
// ระบบวิเคราะห์พฤติกรรมการเรียน (ส่งงานช้า/ไม่ดูบทเรียน/คะแนนตก) แล้วสร้าง
// รายการแจ้งเตือนให้ครู (dedup ต่อคน ไม่แจ้งซ้ำถี่ๆ ตาม AI-5 Exception 1)
// ครูเปิดดูเหตุผล+ข้อมูลประกอบ แล้วบันทึกการติดตาม/มอบหมายกิจกรรมเสริมที่ AI
// แนะนำ (เลือกเองเสมอ ไม่ auto-assign ตาม AI-7 BR1) — เพิ่มเมื่อ 2026-08-16
// ดู teacher_redesign_prototype/NOTES.md สำหรับที่มา

import 'package:flutter/material.dart';

import 'teacher_redesign_prototype_page.dart' show TeacherPalette;
import 'teacher_shared_widgets.dart'
    show TeacherMockPageShell, TeacherStatusChip;

enum _FollowUpStatus { pending, inProgress, improved, escalated }

extension on _FollowUpStatus {
  String get label => switch (this) {
    _FollowUpStatus.pending => 'รอติดตาม',
    _FollowUpStatus.inProgress => 'กำลังติดตาม',
    _FollowUpStatus.improved => 'ดีขึ้นแล้ว',
    _FollowUpStatus.escalated => 'ส่งต่อผู้เชี่ยวชาญ',
  };

  Color get color => switch (this) {
    _FollowUpStatus.pending => TeacherPalette.muted,
    _FollowUpStatus.inProgress => const Color(0xFFD97706),
    _FollowUpStatus.improved => const Color(0xFF10B981),
    _FollowUpStatus.escalated => const Color(0xFFDC2626),
  };
}

class _RiskFlag {
  _RiskFlag({
    required this.studentName,
    required this.studentNo,
    required this.courseLabel,
    required this.riskLevel,
    required this.reasons,
    required this.dataSnapshot,
    required this.suggestedActivities,
    this.status = _FollowUpStatus.pending,
    this.followUpNote,
  });

  final String studentName;
  final String studentNo;
  final String courseLabel;
  final String riskLevel; // 'สูง' / 'ปานกลาง'
  final List<String> reasons; // AI-4: เหตุผลของการแจ้งเตือน
  final Map<String, String>
  dataSnapshot; // ข้อมูลประกอบ (คะแนน/ส่งงาน/เข้าเรียน)
  final List<String> suggestedActivities; // AI-7
  _FollowUpStatus status;
  String? followUpNote;
  List<String> assignedActivities = [];
}

List<_RiskFlag> _mockRiskFlags() => [
  _RiskFlag(
    studentName: 'ด.ช. อภิสิทธิ์ วงศ์สวัสดิ์',
    studentNo: 'ม.5/2 เลขที่ 12',
    courseLabel: 'AIoT สมาร์ตแล็บ',
    riskLevel: 'สูง',
    reasons: const [
      'ส่งใบงานล่าช้ากว่ากำหนด 3 ครั้งติดต่อกัน',
      'คะแนนแบบทดสอบย่อยลดลงจากค่าเฉลี่ยเดิม 18%',
      'ไม่เปิดดูบทเรียนล่าสุด 2 บทเรียน',
    ],
    dataSnapshot: const {
      'คะแนนเฉลี่ยล่าสุด': '58% (จากเดิม 76%)',
      'ใบงานที่ส่งตรงเวลา': '2 จาก 6 ครั้งล่าสุด',
      'การเข้าเรียน': '85% (2 ครั้งขาด ไม่แจ้งลา)',
    },
    suggestedActivities: const [
      'บทเรียนทบทวน: พื้นฐานเซนเซอร์และไมโครคอนโทรลเลอร์ (ฉบับย่อ)',
      'ใบงานฝึกเพิ่มเติม: อ่านค่าเซนเซอร์เบื้องต้น (ระดับง่าย)',
    ],
  ),
  _RiskFlag(
    studentName: 'ด.ญ. ณัฐธิดา ไพศาล',
    studentNo: 'ม.4/1 เลขที่ 7',
    courseLabel: 'ฟิสิกส์ประยุกต์',
    riskLevel: 'ปานกลาง',
    reasons: const [
      'ไม่ส่งใบงานล่าสุด 1 ครั้ง',
      'คะแนนแบบฝึกหัดลดลงเล็กน้อยจากค่าเฉลี่ยเดิม 8%',
    ],
    dataSnapshot: const {
      'คะแนนเฉลี่ยล่าสุด': '70% (จากเดิม 78%)',
      'ใบงานที่ส่งตรงเวลา': '4 จาก 5 ครั้งล่าสุด',
      'การเข้าเรียน': '100%',
    },
    suggestedActivities: const ['วิดีโอทบทวน: แรงและการเคลื่อนที่เบื้องต้น'],
    status: _FollowUpStatus.inProgress,
    followUpNote:
        'คุยกับนักเรียนแล้ว แจ้งว่าติดกิจกรรมชมรม จะส่งงานให้ครบภายในสัปดาห์นี้',
  ),
];

class TeacherStudentSupportPage extends StatefulWidget {
  const TeacherStudentSupportPage({super.key});

  @override
  State<TeacherStudentSupportPage> createState() =>
      _TeacherStudentSupportPageState();
}

class _TeacherStudentSupportPageState extends State<TeacherStudentSupportPage> {
  late final List<_RiskFlag> _flags = _mockRiskFlags();

  Future<void> _openDetail(_RiskFlag flag) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _RiskDetailSheet(flag: flag, onChanged: () => setState(() {})),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TeacherMockPageShell(
      title: 'นักเรียนที่ต้องการการสนับสนุน',
      activeMenuLabel: 'นักเรียน',
      builder: (context, isDesktop) {
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
                'AI-4: วิเคราะห์จากพฤติกรรมการเรียน (ส่งงาน/ดูบทเรียน/คะแนน) '
                'เท่านั้น ไม่ใช้ตัดสินนิสัยหรือบุคลิกส่วนบุคคล — เป็นข้อเสนอ '
                'ให้ครูตัดสินใจ ไม่ใช่การตัดสินใจอัตโนมัติ',
                style: TextStyle(
                  color: Color(0xFF1D4ED8),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 14),
            for (final flag in _flags) ...[
              _RiskCard(flag: flag, onTap: () => _openDetail(flag)),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }
}

class _RiskCard extends StatelessWidget {
  const _RiskCard({required this.flag, required this.onTap});

  final _RiskFlag flag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final riskColor = flag.riskLevel == 'สูง'
        ? const Color(0xFFDC2626)
        : const Color(0xFFD97706);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border(
            top: const BorderSide(color: TeacherPalette.border),
            right: const BorderSide(color: TeacherPalette.border),
            bottom: const BorderSide(color: TeacherPalette.border),
            left: BorderSide(color: riskColor, width: 5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${flag.studentName} · ${flag.studentNo}',
                    style: const TextStyle(
                      color: TeacherPalette.ink,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                TeacherStatusChip(
                  label: 'ความเสี่ยง${flag.riskLevel}',
                  color: riskColor,
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              flag.courseLabel,
              style: const TextStyle(
                color: TeacherPalette.muted,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              flag.reasons.first,
              style: const TextStyle(
                color: TeacherPalette.softText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (flag.reasons.length > 1)
              Text(
                '+ อีก ${flag.reasons.length - 1} เหตุผล',
                style: const TextStyle(
                  color: TeacherPalette.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            const SizedBox(height: 10),
            TeacherStatusChip(
              label: flag.status.label,
              color: flag.status.color,
            ),
          ],
        ),
      ),
    );
  }
}

class _RiskDetailSheet extends StatefulWidget {
  const _RiskDetailSheet({required this.flag, required this.onChanged});

  final _RiskFlag flag;
  final VoidCallback onChanged;

  @override
  State<_RiskDetailSheet> createState() => _RiskDetailSheetState();
}

class _RiskDetailSheetState extends State<_RiskDetailSheet> {
  late _FollowUpStatus _status = widget.flag.status;
  late final TextEditingController _noteCtrl = TextEditingController(
    text: widget.flag.followUpNote ?? '',
  );
  late final Set<String> _assigned = {...widget.flag.assignedActivities};

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  void _saveFollowUp() {
    widget.flag.status = _status;
    widget.flag.followUpNote = _noteCtrl.text.trim().isEmpty
        ? null
        : _noteCtrl.text.trim();
    widget.flag.assignedActivities = _assigned.toList();
    widget.onChanged();
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('บันทึกการติดตาม ${widget.flag.studentName} แล้ว'),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _toggleActivity(String activity) {
    setState(() {
      if (_assigned.contains(activity)) {
        _assigned.remove(activity);
      } else {
        _assigned.add(activity);
      }
    });
  }

  Future<void> _showAiSummary() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFF7C3AED),
              size: 20,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'สรุปผลการเรียน (AI ร่าง)',
                style: TextStyle(fontSize: 15),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            '${widget.flag.studentName} มีแนวโน้มผลการเรียนลดลงในช่วงที่ผ่านมา '
            'จุดที่ควรพัฒนา: ${widget.flag.reasons.join(", ")} '
            'จุดเด่น: ยังคงเข้าเรียนสม่ำเสมอและให้ความร่วมมือในชั้นเรียน '
            'ข้อเสนอแนะ: ติดตามการส่งงานอย่างใกล้ชิดในช่วง 2 สัปดาห์ถัดไป',
            style: const TextStyle(fontSize: 13, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ปิด'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'ตรวจสอบแล้ว — พร้อมใช้สรุปนี้ในรายงานผู้ปกครอง',
                  ),
                  backgroundColor: Color(0xFF10B981),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: TeacherPalette.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('ตรวจสอบแล้ว ใช้ในรายงาน'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final flag = widget.flag;
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    Text(
                      flag.studentName,
                      style: const TextStyle(
                        color: TeacherPalette.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${flag.studentNo} · ${flag.courseLabel}',
                      style: const TextStyle(
                        color: TeacherPalette.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'เหตุผลที่ถูกแจ้งเตือน',
                      style: TextStyle(
                        color: TeacherPalette.ink,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    for (final reason in flag.reasons)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• $reason',
                          style: const TextStyle(fontSize: 12.5),
                        ),
                      ),
                    const SizedBox(height: 16),
                    const Text(
                      'ข้อมูลประกอบ',
                      style: TextStyle(
                        color: TeacherPalette.ink,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          for (final entry in flag.dataSnapshot.entries)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      entry.key,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: TeacherPalette.muted,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    entry.value,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: TeacherPalette.ink,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          size: 15,
                          color: Color(0xFF7C3AED),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'AI แนะนำกิจกรรมเสริม (เลือกมอบหมายเอง)',
                          style: TextStyle(
                            color: Color(0xFF6D28D9),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    for (final activity in flag.suggestedActivities)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F3FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFDDD6FE)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  activity,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: () => _toggleActivity(activity),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: Size.zero,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                ),
                                child: Text(
                                  _assigned.contains(activity)
                                      ? 'มอบหมายแล้ว ✓'
                                      : 'มอบหมาย',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _showAiSummary,
                      icon: const Icon(Icons.summarize_rounded, size: 16),
                      label: const Text('สร้างสรุปผลการเรียน (AI ร่าง)'),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'สถานะการติดตาม',
                      style: TextStyle(
                        color: TeacherPalette.ink,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final s in _FollowUpStatus.values)
                          ChoiceChip(
                            label: Text(s.label),
                            selected: _status == s,
                            onSelected: (_) => setState(() => _status = s),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'บันทึกการติดตาม',
                      style: TextStyle(
                        color: TeacherPalette.ink,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _noteCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText:
                            'เช่น คุยกับนักเรียนแล้ว นัดติดตามอีกครั้งสัปดาห์หน้า...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: TeacherPalette.border,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: TeacherPalette.border,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: TeacherPalette.border)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveFollowUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TeacherPalette.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('บันทึกการติดตาม'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
