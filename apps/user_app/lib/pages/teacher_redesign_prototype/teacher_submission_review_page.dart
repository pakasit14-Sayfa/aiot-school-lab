// PROTOTYPE — UI/UX เท่านั้น mock ทั้งหมด ยังไม่ผูก Supabase จริง
//
// ASM-7: ครูตรวจงานนักเรียนตาม Rubric — เปิดจากปุ่ม "ตรวจงาน"/"ดูผล" ใน
// teacher_grading_page.dart (ก่อนหน้านี้ปุ่มนั้นเป็นแค่ showTeacherMockAction
// ลอย ๆ ไม่มีหน้าเปิดงานนักเรียนแล้วให้คะแนนทีละเกณฑ์จริง) เพิ่มเมื่อ
// 2026-08-16 — ดู student_redesign_prototype/NOTES.md ไม่เกี่ยว ดู
// teacher_redesign_prototype/NOTES.md สำหรับที่มา

import 'package:flutter/material.dart';

import 'teacher_redesign_prototype_page.dart' show TeacherPalette;
import 'teacher_rubric_page.dart'
    show RubricModel, RubricCriterion, RubricLevel;
import 'teacher_shared_widgets.dart'
    show TeacherMockPageShell, TeacherStatusChip;

RubricModel _mockAssignmentRubric() => RubricModel(
  id: 'rubric-review-mock',
  title: 'เกณฑ์ประเมินใบงาน/โครงงาน',
  description: 'ใช้ประเมินใบงานทั่วไปที่ไม่ได้ผูก Rubric เฉพาะกิจกรรม',
  scope: 'ใช้ร่วมข้ามวิชา',
  isLocked: true,
  usedCount: 0,
  updatedAt: '-',
  criteria: [
    RubricCriterion(
      id: 'c1',
      title: 'ความถูกต้องของเนื้อหา/ข้อมูล',
      maxPoints: 10,
      levels: [
        RubricLevel(
          name: 'ดีมาก (10)',
          score: 10,
          description: 'ถูกต้องครบถ้วน มีการอ้างอิงข้อมูลจริงชัดเจน',
        ),
        RubricLevel(
          name: 'ดี (8)',
          score: 8,
          description: 'ถูกต้องเป็นส่วนใหญ่ มีจุดคลาดเคลื่อนเล็กน้อย',
        ),
        RubricLevel(
          name: 'พอใช้ (6)',
          score: 6,
          description: 'มีเนื้อหาถูกต้องบางส่วน ยังขาดรายละเอียด',
        ),
        RubricLevel(
          name: 'ต้องปรับปรุง (4)',
          score: 4,
          description: 'เนื้อหาคลาดเคลื่อนมาก หรือไม่ตรงโจทย์',
        ),
      ],
    ),
    RubricCriterion(
      id: 'c2',
      title: 'การนำเสนอและความเรียบร้อย',
      maxPoints: 10,
      levels: [
        RubricLevel(
          name: 'ดีมาก (10)',
          score: 10,
          description: 'จัดรูปแบบเป็นระบบ อ่านง่าย มีภาพประกอบเหมาะสม',
        ),
        RubricLevel(
          name: 'ดี (8)',
          score: 8,
          description: 'จัดรูปแบบเรียบร้อย อ่านเข้าใจได้',
        ),
        RubricLevel(
          name: 'พอใช้ (6)',
          score: 6,
          description: 'จัดรูปแบบพอใช้ได้ มีจุดสับสนบ้าง',
        ),
        RubricLevel(
          name: 'ต้องปรับปรุง (4)',
          score: 4,
          description: 'จัดรูปแบบไม่เป็นระบบ อ่านยาก',
        ),
      ],
    ),
  ],
);

class _SubmissionMock {
  _SubmissionMock({
    required this.studentName,
    required this.studentNo,
    this.score,
    this.feedback,
    this.aiSuggestedLevelIndex,
    this.aiSuggestedFeedback,
    this.aiAnomalyNote,
    this.aiUnavailableReason,
  });

  final String studentName;
  final String studentNo;
  double? score;
  String? feedback;

  // AI-1/AI-2: ดัชนีระดับ (index ใน RubricCriterion.levels) ที่ AI เสนอต่อ
  // เกณฑ์แต่ละข้อ (key = criterion id) + ร่างข้อเสนอแนะที่ AI เขียนไว้ —
  // เป็นแค่ "ข้อเสนอ" เสมอ ไม่มีผลจนกว่าครูจะยืนยัน (AI-1 BR1)
  final Map<String, int>? aiSuggestedLevelIndex;
  final String? aiSuggestedFeedback;

  // AI-9: ธงเตือนคะแนนผิดปกติ (คำเตือนเฉยๆ ไม่บล็อก — BR1)
  final String? aiAnomalyNote;

  // AI-1 Exception 1: บางชนิดงาน (เช่นไฟล์วิดีโอ) AI วิเคราะห์ไม่ได้เลย
  final String? aiUnavailableReason;

  // AI-10: ร่องรอยเมื่อครูแก้ไขคะแนนจากที่ AI เสนอ
  String? aiDeviationReason;
  bool coiFlagged = false;

  bool get isGraded => score != null;
  bool get hasAiSuggestion => aiSuggestedLevelIndex != null;
}

List<_SubmissionMock> _mockSubmissions() => [
  _SubmissionMock(
    studentName: 'ด.ช. ธนกร ใจดี',
    studentNo: 'เลขที่ 1',
    aiSuggestedLevelIndex: const {'c1': 0, 'c2': 1},
    aiSuggestedFeedback:
        'อธิบายข้อมูลเซนเซอร์ได้ถูกต้องและครบถ้วนมาก ลองเพิ่มภาพประกอบ'
        'ให้จัดวางเป็นระบบขึ้นอีกนิดจะดียิ่งขึ้น',
  ),
  _SubmissionMock(
    studentName: 'ด.ญ. พิมพ์ชนก แสงทอง',
    studentNo: 'เลขที่ 2',
    aiSuggestedLevelIndex: const {'c1': 0, 'c2': 0},
    aiSuggestedFeedback: 'ทำได้ดีมากทั้งเนื้อหาและการนำเสนอ',
    aiAnomalyNote:
        'คะแนนที่เสนอ (20/20) สูงกว่าค่าเฉลี่ยของห้องนี้มาก ควรตรวจสอบเพิ่มเติมก่อนยืนยัน',
  ),
  _SubmissionMock(
    studentName: 'ด.ช. ปารมี ศรีสุข',
    studentNo: 'เลขที่ 3',
    score: 18,
    feedback: 'ทำได้ดีมาก อธิบายข้อมูลเซนเซอร์ได้ชัดเจน',
  ),
  _SubmissionMock(
    studentName: 'ด.ญ. กัญญาพัชร รุ่งเรือง',
    studentNo: 'เลขที่ 4',
    aiUnavailableReason: 'ส่งงานเป็นไฟล์วิดีโอ — AI วิเคราะห์รูปแบบนี้ไม่ได้',
  ),
  _SubmissionMock(
    studentName: 'ด.ช. กิตติศักดิ์ ขยันยิ่ง',
    studentNo: 'เลขที่ 5',
    score: 14,
    feedback: 'เนื้อหาถูกต้อง แต่การนำเสนอควรจัดรูปแบบให้เป็นระบบกว่านี้',
  ),
];

class _ScoringResult {
  _ScoringResult({
    required this.score,
    required this.feedback,
    required this.coiFlagged,
    this.aiDeviationReason,
  });

  final double score;
  final String feedback;
  final bool coiFlagged;
  final String? aiDeviationReason;
}

class TeacherSubmissionRosterPage extends StatefulWidget {
  const TeacherSubmissionRosterPage({
    super.key,
    required this.worksheetTitle,
    required this.courseLabel,
  });

  final String worksheetTitle;
  final String courseLabel;

  @override
  State<TeacherSubmissionRosterPage> createState() =>
      _TeacherSubmissionRosterPageState();
}

class _TeacherSubmissionRosterPageState
    extends State<TeacherSubmissionRosterPage> {
  late final List<_SubmissionMock> _submissions = _mockSubmissions();
  late final RubricModel _rubric = _mockAssignmentRubric();

  int get _gradedCount => _submissions.where((s) => s.isGraded).length;

  Future<void> _openScoring(_SubmissionMock submission) async {
    final result = await showModalBottomSheet<_ScoringResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ScoringSheet(rubric: _rubric, submission: submission),
    );
    if (result == null || !mounted) return;
    setState(() {
      submission.score = result.score;
      submission.feedback = result.feedback;
      submission.coiFlagged = result.coiFlagged;
      submission.aiDeviationReason = result.aiDeviationReason;
    });
  }

  @override
  Widget build(BuildContext context) {
    return TeacherMockPageShell(
      title: 'ตรวจงาน: ${widget.worksheetTitle}',
      activeMenuLabel: 'ตรวจงาน',
      builder: (context, isDesktop) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.courseLabel,
              style: const TextStyle(
                color: TeacherPalette.muted,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'ตรวจแล้ว $_gradedCount / ${_submissions.length} คน · เกณฑ์: ${_rubric.title}',
              style: const TextStyle(
                color: TeacherPalette.ink,
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: TeacherPalette.border),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < _submissions.length; i++) ...[
                    if (i != 0) const Divider(height: 22),
                    _RosterRow(
                      submission: _submissions[i],
                      maxScore: _rubric.totalMaxPoints,
                      onTap: () => _openScoring(_submissions[i]),
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

class _RosterRow extends StatelessWidget {
  const _RosterRow({
    required this.submission,
    required this.maxScore,
    required this.onTap,
  });

  final _SubmissionMock submission;
  final double maxScore;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: submission.isGraded
                    ? const Color(0xFFECFDF5)
                    : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                submission.isGraded
                    ? Icons.check_circle_rounded
                    : Icons.person_outline_rounded,
                size: 18,
                color: submission.isGraded
                    ? const Color(0xFF10B981)
                    : TeacherPalette.muted,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    submission.studentName,
                    style: const TextStyle(
                      color: TeacherPalette.ink,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    submission.studentNo,
                    style: const TextStyle(
                      color: TeacherPalette.muted,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (!submission.isGraded && submission.hasAiSuggestion) ...[
                    const SizedBox(height: 3),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          size: 12,
                          color: Color(0xFF7C3AED),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          submission.aiAnomalyNote != null
                              ? 'AI เสนอคะแนนแล้ว · ควรตรวจสอบเพิ่มเติม'
                              : 'AI เสนอคะแนนแล้ว รอครูตรวจสอบ',
                          style: TextStyle(
                            color: submission.aiAnomalyNote != null
                                ? const Color(0xFFD97706)
                                : const Color(0xFF7C3AED),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ] else if (!submission.isGraded &&
                      submission.aiUnavailableReason != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      submission.aiUnavailableReason!,
                      style: const TextStyle(
                        color: TeacherPalette.muted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (submission.isGraded)
              TeacherStatusChip(
                label:
                    '${submission.score!.toStringAsFixed(0)}/${maxScore.toStringAsFixed(0)}',
                color: const Color(0xFF10B981),
              ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: submission.isGraded
                    ? Colors.white
                    : TeacherPalette.primary,
                foregroundColor: submission.isGraded
                    ? TeacherPalette.primary
                    : Colors.white,
                side: submission.isGraded
                    ? const BorderSide(color: TeacherPalette.border)
                    : null,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                submission.isGraded ? 'แก้คะแนน' : 'ให้คะแนน',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoringSheet extends StatefulWidget {
  const _ScoringSheet({required this.rubric, required this.submission});

  final RubricModel rubric;
  final _SubmissionMock submission;

  @override
  State<_ScoringSheet> createState() => _ScoringSheetState();
}

class _ScoringSheetState extends State<_ScoringSheet> {
  // key = criterion id, value = ระดับที่เลือก (null = ยังไม่เลือก)
  late final Map<String, RubricLevel?> _selected = {
    for (final c in widget.rubric.criteria) c.id: null,
  };
  late final TextEditingController _feedbackCtrl = TextEditingController(
    text: widget.submission.feedback ?? '',
  );
  late final TextEditingController _deviationReasonCtrl =
      TextEditingController();
  late bool _coiFlagged = widget.submission.coiFlagged;

  double get _total =>
      _selected.values.fold(0.0, (sum, level) => sum + (level?.score ?? 0));

  bool get _allScored => _selected.values.every((v) => v != null);

  // AI-9/AI-10: ครูเลือกต่างจากที่ AI เสนอในเกณฑ์ไหนบ้าง (นับเฉพาะเกณฑ์ที่
  // ให้คะแนนแล้ว) — ใช้ตัดสินว่าต้องโชว์ช่องเหตุผลการแก้ไขไหม
  bool get _deviatedFromAi {
    final aiSuggestion = widget.submission.aiSuggestedLevelIndex;
    if (aiSuggestion == null) return false;
    for (final criterion in widget.rubric.criteria) {
      final picked = _selected[criterion.id];
      if (picked == null) continue;
      final suggestedIndex = aiSuggestion[criterion.id];
      if (suggestedIndex == null) continue;
      if (criterion.levels.indexOf(picked) != suggestedIndex) return true;
    }
    return false;
  }

  void _applyAiSuggestion() {
    final aiSuggestion = widget.submission.aiSuggestedLevelIndex;
    if (aiSuggestion == null) return;
    setState(() {
      for (final criterion in widget.rubric.criteria) {
        final idx = aiSuggestion[criterion.id];
        if (idx != null && idx < criterion.levels.length) {
          _selected[criterion.id] = criterion.levels[idx];
        }
      }
      if (_feedbackCtrl.text.trim().isEmpty &&
          widget.submission.aiSuggestedFeedback != null) {
        _feedbackCtrl.text = widget.submission.aiSuggestedFeedback!;
      }
    });
  }

  @override
  void dispose() {
    _feedbackCtrl.dispose();
    _deviationReasonCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_allScored) return;
    Navigator.pop(
      context,
      _ScoringResult(
        score: _total,
        feedback: _feedbackCtrl.text.trim(),
        coiFlagged: _coiFlagged,
        aiDeviationReason: _deviatedFromAi
            ? (_deviationReasonCtrl.text.trim().isEmpty
                  ? null
                  : _deviationReasonCtrl.text.trim())
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
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
                      widget.submission.studentName,
                      style: const TextStyle(
                        color: TeacherPalette.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.rubric.title,
                      style: const TextStyle(
                        color: TeacherPalette.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (widget.submission.aiUnavailableReason != null) ...[
                      _InfoBanner(
                        icon: Icons.info_outline_rounded,
                        color: TeacherPalette.muted,
                        text:
                            'AI วิเคราะห์งานนี้ไม่ได้ (${widget.submission.aiUnavailableReason}) '
                            '— ให้คะแนนเองทั้งหมด',
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (widget.submission.aiAnomalyNote != null) ...[
                      _InfoBanner(
                        icon: Icons.warning_amber_rounded,
                        color: const Color(0xFFD97706),
                        text: widget.submission.aiAnomalyNote!,
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (widget.submission.hasAiSuggestion) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F3FF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFDDD6FE)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 16,
                                  color: Color(0xFF7C3AED),
                                ),
                                const SizedBox(width: 6),
                                const Expanded(
                                  child: Text(
                                    'AI แนะนำคะแนนเบื้องต้น (ยังไม่มีผลจนกว่าครูจะยืนยัน)',
                                    style: TextStyle(
                                      color: Color(0xFF6D28D9),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            TextButton(
                              onPressed: _applyAiSuggestion,
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF6D28D9),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'ใช้ตามที่ AI แนะนำทั้งหมด',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    for (final criterion in widget.rubric.criteria) ...[
                      _CriterionScorer(
                        criterion: criterion,
                        selected: _selected[criterion.id],
                        onSelect: (level) =>
                            setState(() => _selected[criterion.id] = level),
                      ),
                      const SizedBox(height: 16),
                    ],
                    const Text(
                      'ข้อเสนอแนะ',
                      style: TextStyle(
                        color: TeacherPalette.ink,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _feedbackCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'เขียนข้อเสนอแนะให้นักเรียน...',
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
                    if (_deviatedFromAi) ...[
                      const SizedBox(height: 14),
                      const Text(
                        'เหตุผลที่แก้ไขจากคะแนนที่ AI เสนอ (ไม่บังคับ)',
                        style: TextStyle(
                          color: TeacherPalette.ink,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _deviationReasonCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText:
                              'เช่น งานจริงมีรายละเอียดมากกว่าที่ AI อ่านได้...',
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
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      value: _coiFlagged,
                      onChanged: (v) =>
                          setState(() => _coiFlagged = v ?? false),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                      title: const Text(
                        'ฉันเป็นผู้ปกครองของนักเรียนคนนี้ด้วย (CoI)',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: const Text(
                        'ระบบจะติด coi_flag และบันทึก audit ตาม AUTH-8 BR3 — ยังยืนยันคะแนนได้ตามปกติ',
                        style: TextStyle(fontSize: 11),
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
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'คะแนนรวม ${_total.toStringAsFixed(0)}/${widget.rubric.totalMaxPoints.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: TeacherPalette.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _allScored ? _save : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TeacherPalette.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        !_allScored
                            ? 'ให้คะแนนครบทุกเกณฑ์ก่อน'
                            : (widget.submission.hasAiSuggestion
                                  ? (_deviatedFromAi
                                        ? 'ยืนยันคะแนน (แก้ไขจาก AI)'
                                        : 'ยืนยันตามที่ AI แนะนำ')
                                  : 'บันทึกคะแนน'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CriterionScorer extends StatelessWidget {
  const _CriterionScorer({
    required this.criterion,
    required this.selected,
    required this.onSelect,
  });

  final RubricCriterion criterion;
  final RubricLevel? selected;
  final ValueChanged<RubricLevel> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          criterion.title,
          style: const TextStyle(
            color: TeacherPalette.ink,
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        for (final level in criterion.levels)
          RadioListTile<RubricLevel>(
            value: level,
            groupValue: selected,
            onChanged: (v) {
              if (v != null) onSelect(v);
            },
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(
              level.name,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              level.description,
              style: const TextStyle(
                fontSize: 11.5,
                color: TeacherPalette.muted,
              ),
            ),
          ),
      ],
    );
  }
}
