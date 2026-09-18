// ASM-7: ครูตรวจงานนักเรียนตาม Rubric — เปิดจากปุ่ม "ตรวจงาน"/"ดูผล" ใน
// teacher_grading_page.dart. เชื่อมกับ AssignmentService/GradeService/
// RubricService จริงแล้ว (2026-08-21) — เดิม mock ล้วน
//
// หมายเหตุสำคัญ: assignments.rubric_id มีในฐานข้อมูลแต่ไม่มี RPC ไหนตั้งค่า
// นี้เลย (create_assignment/update_assignment ไม่รับ rubric_id) เกณฑ์การ
// ประเมินเลยยัง "ผูกอัตโนมัติ" กับใบงานไม่ได้จริง — หน้านี้จึงให้ครูเลือก
// Rubric เองจากรายการที่มี (ผ่าน RubricService.listMyRubrics) แทน ถ้าจะทำ
// ให้ผูกอัตโนมัติในอนาคต ต้องเพิ่ม p_rubric_id ใน create_assignment/
// update_assignment ก่อน (migration ใหม่ ไม่ใช่แก้ของเดิม)
//
// คุณสมบัติ AI ช่วยตรวจ (AI-1/AI-2/AI-9/AI-10 ในโค้ด mock เดิม) ไม่มี backend
// รองรับเลย ตัดออกทั้งหมดจากหน้านี้ — ไม่ควรโชว์ AI suggestion ปลอมให้ครูเห็น
//
// ช่อง "ฉันเป็นผู้ปกครองของนักเรียนคนนี้ด้วย (CoI)" ในของเดิมก็ตัดออก เพราะ
// create_grade ตรวจจับ CoI เองจาก parent_links ฝั่งเซิร์ฟเวอร์เสมอ (Decision
// Log: coi_flag ต้องไม่ให้ client ตั้งเอง) ไม่ต้องมีช่องให้ครูติ๊กเลย
import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' hide RubricModel;
import 'package:shared_core/shared_core.dart' as core show RubricModel;
import 'package:url_launcher/url_launcher.dart';

import 'teacher_redesign_prototype_page.dart' show TeacherPalette;
import 'teacher_rubric_page.dart'
    show RubricModel, RubricCriterion, RubricLevel;
import 'teacher_shared_widgets.dart'
    show TeacherMockPageShell, TeacherStatusChip;

class _RosterEntry {
  _RosterEntry({
    required this.studentId,
    required this.studentName,
    required this.submissionId,
    this.attachments = const [],
    this.groupName,
  });

  final String studentId;
  final String studentName;
  final String submissionId;
  final List<SubmissionAttachment> attachments;

  /// PBL-10: set for a group submission — the row stands for the whole
  /// group; studentName is the member who submitted first.
  final String? groupName;
  String? gradeId;
  num? score;
  num? maxScore;
  bool confirmed = false;

  bool get isGraded => score != null;
}

class _ScoringResult {
  _ScoringResult({required this.score, required this.feedback});

  final double score;
  final String feedback;
}

class TeacherSubmissionRosterPage extends StatefulWidget {
  const TeacherSubmissionRosterPage({
    super.key,
    required this.assignmentId,
    required this.courseId,
    required this.worksheetTitle,
    required this.courseLabel,
    this.listSubmissions,
    this.listMyRubrics,
    this.getRubric,
    this.createGrade,
    this.updateGrade,
    this.confirmGrade,
    this.giveFeedback,
    this.getSubmissionAttachmentDownloadUrl,
  });

  final String assignmentId;
  final String courseId;
  final String worksheetTitle;
  final String courseLabel;

  /// Read/write seams threaded to the corresponding AssignmentService/
  /// RubricService/GradeService static calls in production.
  final Future<List<SubmissionRoster>> Function(String assignmentId)?
  listSubmissions;
  final Future<List<core.RubricModel>> Function()? listMyRubrics;
  final Future<core.RubricModel> Function(String rubricId)? getRubric;
  final Future<String> Function({
    required String studentId,
    required String courseId,
    required num score,
    required num maxScore,
  })?
  createGrade;
  final Future<void> Function({
    required String gradeId,
    required num score,
    required num maxScore,
  })?
  updateGrade;
  final Future<void> Function(String gradeId)? confirmGrade;
  final Future<void> Function({
    required String submissionId,
    required String body,
  })?
  giveFeedback;
  final Future<String> Function(String attachmentId)?
  getSubmissionAttachmentDownloadUrl;

  @override
  State<TeacherSubmissionRosterPage> createState() =>
      _TeacherSubmissionRosterPageState();
}

class _TeacherSubmissionRosterPageState
    extends State<TeacherSubmissionRosterPage> {
  bool _loading = true;
  String? _loadError;
  List<_RosterEntry> _roster = [];

  List<dynamic> _rubricSummaries =
      []; // shared_core RubricModel, unnamed on purpose (hidden import)
  RubricModel? _selectedRubric;
  bool _loadingRubric = false;

  int get _gradedCount => _roster.where((s) => s.isGraded).length;

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
      final loadSubmissions =
          widget.listSubmissions ?? AssignmentService.listSubmissions;
      final loadRubrics = widget.listMyRubrics ?? RubricService.listMyRubrics;
      final results = await Future.wait([
        loadSubmissions(widget.assignmentId),
        loadRubrics(),
      ]);
      final submissions = (results[0] as List<SubmissionRoster>)
          .where((s) => s.status != 'not_submitted')
          .toList();

      // ตั้งใจไม่ดึง GradeService.listCourseGrades มา cross-reference สถานะ
      // "ตรวจแล้ว" ให้ตอนโหลดหน้า — grades ผูกกับ student_id+course_id
      // เท่านั้น ไม่มี assignment_id เลย (ไม่มีคอลัมน์นี้ในตาราง grades) ถ้า
      // วิชานี้มีหลายใบงาน จะแยกไม่ออกว่าคะแนนที่เจอเป็นของใบงานไหน เอามาโชว์
      // ตรงนี้เสี่ยงโชว์คะแนนใบงานอื่นทับใบงานนี้ผิดๆ — ปลอดภัยกว่าที่จะให้
      // ครูเห็นสถานะ "ตรวจแล้ว" เฉพาะที่ให้คะแนนจริงในเซสชันนี้เท่านั้น
      // (ตามด้วยการ์ดในหน้า "คะแนนของฉัน"/"ผลการเรียน" อื่นแทน) ถ้าจะทำให้
      // ถูกต้องสมบูรณ์ ต้องเพิ่มคอลัมน์ assignment_id ในตาราง grades ก่อน
      final roster = submissions.map((s) {
        return _RosterEntry(
          studentId: s.studentId,
          studentName: '${s.studentFirstName} ${s.studentLastName}',
          submissionId: s.submissionId,
          attachments: s.latestAttachments,
          groupName: s.groupName,
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _roster = roster;
        _rubricSummaries = results[1] as List;
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

  Future<void> _pickRubric(String rubricId) async {
    setState(() => _loadingRubric = true);
    try {
      final getRubric = widget.getRubric ?? RubricService.getRubric;
      final d = await getRubric(rubricId);
      final rubric = RubricModel(
        id: d.id,
        title: d.title,
        description: d.description ?? '',
        scope: 'เกณฑ์การประเมินโรงเรียน',
        isLocked: false,
        usedCount: 0,
        updatedAt: '-',
        criteria: d.criteria
            .map(
              (c) => RubricCriterion(
                id: c.id,
                title: c.name,
                maxPoints: c.maxScore.toDouble(),
                levels: (c.levels ?? []).map((l) {
                  final map = l as Map<String, dynamic>;
                  return RubricLevel(
                    name: map['name'] as String? ?? '',
                    score: (map['score'] as num?)?.toDouble() ?? 0.0,
                    description: map['description'] as String? ?? '',
                  );
                }).toList(),
              ),
            )
            .toList(),
      );
      if (!mounted) return;
      setState(() {
        _selectedRubric = rubric;
        _loadingRubric = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingRubric = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('โหลดเกณฑ์ไม่สำเร็จ')));
    }
  }

  Future<void> _openScoring(_RosterEntry entry) async {
    final rubric = _selectedRubric;
    if (rubric == null) return;
    final result = await showModalBottomSheet<_ScoringResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _ScoringSheet(rubric: rubric, studentName: entry.studentName),
    );
    if (result == null || !mounted) return;

    try {
      final create = widget.createGrade ?? GradeService.createGrade;
      final update = widget.updateGrade ?? GradeService.updateGrade;
      final feedback = widget.giveFeedback ?? AssignmentService.giveFeedback;
      String gradeId;
      if (entry.gradeId == null) {
        gradeId = await create(
          studentId: entry.studentId,
          courseId: widget.courseId,
          score: result.score,
          maxScore: rubric.totalMaxPoints,
        );
      } else {
        gradeId = entry.gradeId!;
        await update(
          gradeId: gradeId,
          score: result.score,
          maxScore: rubric.totalMaxPoints,
        );
      }
      if (result.feedback.isNotEmpty) {
        await feedback(submissionId: entry.submissionId, body: result.feedback);
      }
      if (!mounted) return;
      setState(() {
        entry.gradeId = gradeId;
        entry.score = result.score;
        entry.maxScore = rubric.totalMaxPoints;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('บันทึกคะแนนไม่สำเร็จ')));
    }
  }

  Future<void> _confirmGrade(_RosterEntry entry) async {
    if (entry.gradeId == null) return;
    try {
      final confirm = widget.confirmGrade ?? GradeService.confirmGrade;
      await confirm(entry.gradeId!);
      if (!mounted) return;
      setState(() => entry.confirmed = true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ยืนยันคะแนนไม่สำเร็จ')));
    }
  }

  Future<void> _openAttachment(SubmissionAttachment attachment) async {
    try {
      final getUrl =
          widget.getSubmissionAttachmentDownloadUrl ??
          AssignmentService.getSubmissionAttachmentDownloadUrl;
      final url = await getUrl(attachment.id);
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('เปิดไฟล์แนบไม่สำเร็จ')));
    }
  }

  void _viewAttachments(_RosterEntry entry) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ไฟล์แนบของ ${entry.studentName}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 12),
              for (final a in entry.attachments)
                Material(
                  type: MaterialType.transparency,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.attach_file_rounded),
                    title: Text(a.fileName ?? 'ไฟล์แนบ'),
                    trailing: const Icon(Icons.download_rounded),
                    onTap: () {
                      Navigator.pop(ctx);
                      _openAttachment(a);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TeacherMockPageShell(
      title: 'ตรวจงาน: ${widget.worksheetTitle}',
      activeMenuLabel: 'ตรวจงาน',
      builder: (context, isDesktop) {
        if (_loading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (_loadError != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(_loadError!),
            ),
          );
        }
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
              'ตรวจแล้ว $_gradedCount / ${_roster.length} คน'
              '${_selectedRubric != null ? ' · เกณฑ์: ${_selectedRubric!.title}' : ''}',
              style: const TextStyle(
                color: TeacherPalette.ink,
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            _RubricPicker(
              rubrics: _rubricSummaries,
              selectedId: _selectedRubric?.id,
              loading: _loadingRubric,
              onSelect: _pickRubric,
            ),
            const SizedBox(height: 16),
            if (_roster.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('ยังไม่มีนักเรียนส่งงานนี้'),
              )
            else
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
                    for (var i = 0; i < _roster.length; i++) ...[
                      if (i != 0) const Divider(height: 22),
                      _RosterRow(
                        entry: _roster[i],
                        canScore: _selectedRubric != null,
                        onScore: () => _openScoring(_roster[i]),
                        onConfirm: () => _confirmGrade(_roster[i]),
                        onViewAttachments: () => _viewAttachments(_roster[i]),
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

class _RubricPicker extends StatelessWidget {
  const _RubricPicker({
    required this.rubrics,
    required this.selectedId,
    required this.loading,
    required this.onSelect,
  });

  final List<dynamic> rubrics;
  final String? selectedId;
  final bool loading;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TeacherPalette.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.rule_folder_outlined,
            size: 18,
            color: TeacherPalette.muted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: rubrics.isEmpty
                ? const Text(
                    'ยังไม่มีเกณฑ์การประเมิน (Rubric) ในระบบ — สร้างที่หน้า Rubric ก่อน',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: TeacherPalette.muted,
                    ),
                  )
                : DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: selectedId,
                      hint: const Text(
                        'เลือกเกณฑ์การประเมิน (Rubric) ก่อนให้คะแนน',
                        style: TextStyle(fontSize: 12.5),
                      ),
                      items: [
                        for (final r in rubrics)
                          DropdownMenuItem<String>(
                            value: r.id as String,
                            child: Text(
                              r.title as String,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                      ],
                      onChanged: loading
                          ? null
                          : (v) {
                              if (v != null) onSelect(v);
                            },
                    ),
                  ),
          ),
          if (loading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }
}

class _RosterRow extends StatelessWidget {
  const _RosterRow({
    required this.entry,
    required this.canScore,
    required this.onScore,
    required this.onConfirm,
    required this.onViewAttachments,
  });

  final _RosterEntry entry;
  final bool canScore;
  final VoidCallback onScore;
  final VoidCallback onConfirm;
  final VoidCallback onViewAttachments;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: entry.isGraded
                  ? const Color(0xFFECFDF5)
                  : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              entry.isGraded
                  ? Icons.check_circle_rounded
                  : Icons.person_outline_rounded,
              size: 18,
              color: entry.isGraded
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
                  entry.studentName,
                  style: const TextStyle(
                    color: TeacherPalette.ink,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (entry.groupName != null)
                  Text(
                    'งานกลุ่ม · ${entry.groupName} (ส่งโดย ${entry.studentName})',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: TeacherPalette.primary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                if (entry.isGraded && entry.confirmed)
                  const Text(
                    'ยืนยันคะแนนแล้ว',
                    style: TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          if (entry.attachments.isNotEmpty) ...[
            IconButton(
              onPressed: onViewAttachments,
              tooltip: 'ไฟล์แนบ (${entry.attachments.length})',
              icon: Badge(
                label: Text('${entry.attachments.length}'),
                child: const Icon(Icons.attach_file_rounded, size: 18),
              ),
            ),
            const SizedBox(width: 4),
          ],
          if (entry.isGraded)
            TeacherStatusChip(
              label:
                  '${entry.score!.toStringAsFixed(0)}/${entry.maxScore!.toStringAsFixed(0)}',
              color: const Color(0xFF10B981),
            ),
          const SizedBox(width: 8),
          if (entry.isGraded && !entry.confirmed) ...[
            OutlinedButton(
              onPressed: canScore ? onScore : null,
              style: OutlinedButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
              ),
              child: const Text('แก้ไข', style: TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: 6),
            ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: TeacherPalette.primary,
                foregroundColor: Colors.white,
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'ยืนยัน',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
            ),
          ] else if (!entry.isGraded)
            ElevatedButton(
              onPressed: canScore ? onScore : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: TeacherPalette.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'ให้คะแนน',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
            ),
        ],
      ),
    );
  }
}

class _ScoringSheet extends StatefulWidget {
  const _ScoringSheet({required this.rubric, required this.studentName});

  final RubricModel rubric;
  final String studentName;

  @override
  State<_ScoringSheet> createState() => _ScoringSheetState();
}

class _ScoringSheetState extends State<_ScoringSheet> {
  late final Map<String, RubricLevel?> _selected = {
    for (final c in widget.rubric.criteria) c.id: null,
  };
  final TextEditingController _feedbackCtrl = TextEditingController();

  double get _total =>
      _selected.values.fold(0.0, (sum, level) => sum + (level?.score ?? 0));

  bool get _allScored => _selected.values.every((v) => v != null);

  @override
  void dispose() {
    _feedbackCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_allScored) return;
    Navigator.pop(
      context,
      _ScoringResult(score: _total, feedback: _feedbackCtrl.text.trim()),
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
                      widget.studentName,
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
                        !_allScored ? 'ให้คะแนนครบทุกเกณฑ์ก่อน' : 'บันทึกคะแนน',
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
          Material(
            type: MaterialType.transparency,
            child: RadioListTile<RubricLevel>(
              value: level,
              groupValue: selected,
              onChanged: (v) {
                if (v != null) onSelect(v);
              },
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(
                level.name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                level.description,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: TeacherPalette.muted,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
