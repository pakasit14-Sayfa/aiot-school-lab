import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import 'teacher_redesign_prototype_page.dart' show TeacherPalette;
import 'teacher_shared_widgets.dart'
    show TeacherMockPageShell, TeacherStatusChip;

class TeacherStudentSupportPage extends StatefulWidget {
  const TeacherStudentSupportPage({super.key});

  @override
  State<TeacherStudentSupportPage> createState() =>
      _TeacherStudentSupportPageState();
}

class _TeacherStudentSupportPageState extends State<TeacherStudentSupportPage> {
  bool _isLoading = true;
  List<StudentSupportCase> _cases = [];
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _loadCases();
  }

  Future<void> _loadCases() async {
    setState(() => _isLoading = true);
    try {
      if (AuthService.sessionToken != null) {
        final data = await StudentSupportService.listCases(
          status: _statusFilter,
        );
        if (mounted) {
          setState(() {
            _cases = data;
            _isLoading = false;
          });
        }
      } else {
        _loadFallbackMock();
      }
    } catch (_) {
      _loadFallbackMock();
    }
  }

  void _loadFallbackMock() {
    if (!mounted) return;
    setState(() {
      _cases = [
        StudentSupportCase(
          caseId: 'mock-1',
          studentId: 's1',
          studentName: 'ด.ช. อภิสิทธิ์ วงศ์สวัสดิ์',
          studentEmail: 'apisit@school.ac.th',
          courseName: 'AIoT สมาร์ตแล็บ (ม.5/2)',
          category: 'academic',
          riskLevel: 'high',
          status: 'open',
          title: 'ส่งใบงานล่าช้ากว่ากำหนด 3 ครั้งติดต่อกัน และคะแนนลดลง',
          notes: 'คะแนนเฉลี่ยล่าสุด 58% (จากเดิม 76%), ขาดเรียน 2 ครั้ง',
          createdByName: 'ครูสมศักดิ์',
          interventionCount: 0,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 4)),
        ),
        StudentSupportCase(
          caseId: 'mock-2',
          studentId: 's2',
          studentName: 'ด.ญ. ณัฐธิดา ไพศาล',
          studentEmail: 'natthida@school.ac.th',
          courseName: 'ฟิสิกส์ประยุกต์ (ม.4/1)',
          category: 'behavioral',
          riskLevel: 'medium',
          status: 'in_progress',
          title: 'ไม่ส่งใบงานล่าสุด และเริ่มขาดสมาธิในการทำแล็บ',
          notes: 'คุยกับนักเรียนแล้ว แจ้งว่าติดกิจกรรมชมรม จะทยอยส่งงานให้ครบ',
          createdByName: 'ครูสมศรี',
          interventionCount: 1,
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];
      _isLoading = false;
    });
  }

  Future<void> _openDetail(StudentSupportCase item) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SupportCaseDetailSheet(
        item: item,
        onChanged: _loadCases,
      ),
    );
  }

  Future<void> _openCreateCaseDialog() async {
    final titleCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String category = 'academic';
    String riskLevel = 'medium';
    String? selectedStudentId;

    // Load actual students from school
    List<CourseStudent> students = [];
    try {
      final courses = await CourseService.listMyCourses();
      if (courses.isNotEmpty) {
        final list = await CourseService.listCourseStudents(courses.first.id);
        students = list;
      }
    } catch (_) {}

    if (!mounted) return;

    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final bottom = MediaQuery.of(context).viewInsets.bottom;
          return Container(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottom),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: TeacherPalette.border,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'เปิดเคสดูแลช่วยเหลือนักเรียน',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: TeacherPalette.ink,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (students.isNotEmpty) ...[
                    const Text(
                      'เลือกนักเรียน',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: TeacherPalette.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: selectedStudentId,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      hint: const Text('เลือกนักเรียนในห้องเรียน'),
                      items: students
                          .map(
                            (s) => DropdownMenuItem(
                              value: s.studentId,
                              child: Text(s.fullName),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        setSheetState(() {
                          selectedStudentId = val;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                  ] else ...[
                    const Text(
                      'ชื่อนักเรียน',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: TeacherPalette.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'เช่น ด.ช. มานะ สุขใจ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  const Text(
                    'หมวดหมู่ปัญหา',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: TeacherPalette.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'academic',
                        child: Text('ด้านการเรียน (วิชาการ/งานค้าง)'),
                      ),
                      DropdownMenuItem(
                        value: 'behavioral',
                        child: Text('ด้านพฤติกรรม & การเข้าเรียน'),
                      ),
                      DropdownMenuItem(
                        value: 'emotional',
                        child: Text('ด้านสภาพจิตใจ อารมณ์ & ครอบครัว'),
                      ),
                      DropdownMenuItem(
                        value: 'safety',
                        child: Text('ด้านความปลอดภัย & เหตุฉุกเฉิน'),
                      ),
                    ],
                    onChanged: (val) => setSheetState(() => category = val!),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'ระดับความเสี่ยง',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: TeacherPalette.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: riskLevel,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'low',
                        child: Text('🟢 เฝ้าระวังทั่วไป (Low)'),
                      ),
                      DropdownMenuItem(
                        value: 'medium',
                        child: Text('🟡 ปานกลาง / ต้องติดตาม (Medium)'),
                      ),
                      DropdownMenuItem(
                        value: 'high',
                        child: Text('🔴 เร่งด่วน / วิกฤต (High)'),
                      ),
                    ],
                    onChanged: (val) => setSheetState(() => riskLevel = val!),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'หัวข้อปัญหา / พฤติกรรมที่สังเกตได้',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: TeacherPalette.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      hintText: 'เช่น ไม่ส่งงาน 3 ชิ้น, ดูเครียดผิดปกติ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'บันทึกรายละเอียดเพิ่มเติม',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: TeacherPalette.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: notesCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'ระบุข้อมูลเพิ่มเติมเพื่อใช้วางแผนช่วยเหลือ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: TeacherPalette.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: const StadiumBorder(),
                      ),
                      onPressed: () async {
                        if (titleCtrl.text.trim().isEmpty) return;
                        if (AuthService.sessionToken != null &&
                            selectedStudentId != null) {
                          try {
                            await StudentSupportService.createCase(
                              studentId: selectedStudentId!,
                              category: category,
                              riskLevel: riskLevel,
                              title: titleCtrl.text.trim(),
                              notes: notesCtrl.text.trim(),
                            );
                          } catch (_) {}
                        }
                        if (ctx.mounted) Navigator.pop(ctx, true);
                      },
                      child: const Text('บันทึกเปิดเคส'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (created == true) {
      _loadCases();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('เปิดเคสช่วยเหลือนักเรียนสำเร็จแล้ว'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return TeacherMockPageShell(
      title: 'นักเรียนที่ต้องการการสนับสนุน',
      activeMenuLabel: 'ช่วยเหลือนักเรียน',
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: FilledButton.icon(
            onPressed: _openCreateCaseDialog,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('เปิดเคสช่วยเหลือ'),
            style: FilledButton.styleFrom(
              backgroundColor: TeacherPalette.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: const StadiumBorder(),
              textStyle: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
      builder: (context, isDesktop) {
        if (_isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ),
          );
        }

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
                'AI-4 / AI-6: ระบบดูแลช่วยเหลือนักเรียน — บันทึกข้อสังเกตและวางแผนช่วยเหลือ '
                'ตามดุลยพินิจของครูผู้สอน ข้อมูลจะประสานงานร่วมกันกับครูในโรงเรียนเพื่อติดตามผล',
                style: TextStyle(
                  color: Color(0xFF1D4ED8),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _filterChip('ทั้งหมด', null),
                const SizedBox(width: 8),
                _filterChip('เปิดเคสใหม่', 'open'),
                const SizedBox(width: 8),
                _filterChip('กำลังช่วยเหลือ', 'in_progress'),
                const SizedBox(width: 8),
                _filterChip('ส่งต่อแนะแนว', 'escalated'),
                const SizedBox(width: 8),
                _filterChip('ปิดเคสสำเร็จ', 'resolved'),
              ],
            ),
            const SizedBox(height: 14),
            if (_cases.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: TeacherPalette.border),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 40,
                      color: Color(0xFF10B981),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'ไม่พบบันทึกนักเรียนกลุ่มเสี่ยงในหมวดนี้',
                      style: TextStyle(
                        color: TeacherPalette.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            else
              for (final c in _cases) ...[
                _CaseCard(item: c, onTap: () => _openDetail(c)),
                const SizedBox(height: 12),
              ],
          ],
        );
      },
    );
  }

  Widget _filterChip(String label, String? status) {
    final selected = _statusFilter == status;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() => _statusFilter = status);
        _loadCases();
      },
      selectedColor: TeacherPalette.primary.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: selected ? TeacherPalette.primary : TeacherPalette.muted,
        fontWeight: FontWeight.w800,
        fontSize: 12,
      ),
      side: BorderSide(
        color: selected ? TeacherPalette.primary : TeacherPalette.border,
      ),
      shape: const StadiumBorder(),
    );
  }
}

class _CaseCard extends StatelessWidget {
  const _CaseCard({required this.item, required this.onTap});

  final StudentSupportCase item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final riskColor = switch (item.riskLevel) {
      'high' => const Color(0xFFDC2626),
      'medium' => const Color(0xFFD97706),
      _ => const Color(0xFF10B981),
    };

    final statusColor = switch (item.status) {
      'open' => TeacherPalette.muted,
      'in_progress' => const Color(0xFFD97706),
      'escalated' => const Color(0xFFDC2626),
      'resolved' => const Color(0xFF10B981),
      _ => TeacherPalette.muted,
    };

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
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
                      '${item.studentName} (${item.studentEmail})',
                      style: const TextStyle(
                        color: TeacherPalette.ink,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  TeacherStatusChip(
                    label: 'เสี่ยงระดับ${item.riskLevel.toUpperCase()}',
                    color: riskColor,
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${item.courseName} · หมวด${item.categoryLabel}',
                style: const TextStyle(
                  color: TeacherPalette.muted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.title,
                style: const TextStyle(
                  color: TeacherPalette.ink,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (item.notes != null && item.notes!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  item.notes!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: TeacherPalette.muted,
                    fontSize: 11.5,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  TeacherStatusChip(
                    label: item.statusLabel,
                    color: statusColor,
                  ),
                  const Spacer(),
                  Text(
                    'บันทึกช่วยเหลือ ${item.interventionCount} ครั้ง',
                    style: const TextStyle(
                      color: TeacherPalette.muted,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupportCaseDetailSheet extends StatefulWidget {
  const _SupportCaseDetailSheet({
    required this.item,
    required this.onChanged,
  });

  final StudentSupportCase item;
  final VoidCallback onChanged;

  @override
  State<_SupportCaseDetailSheet> createState() =>
      _SupportCaseDetailSheetState();
}

class _SupportCaseDetailSheetState extends State<_SupportCaseDetailSheet> {
  late String _status = widget.item.status;
  final TextEditingController _interventionCtrl = TextEditingController();
  String _actionType = 'counseling';
  bool _isLoadingInterventions = true;
  List<StudentSupportIntervention> _interventions = [];

  @override
  void initState() {
    super.initState();
    _loadInterventions();
  }

  @override
  void dispose() {
    _interventionCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInterventions() async {
    try {
      if (AuthService.sessionToken != null &&
          !widget.item.caseId.startsWith('mock-')) {
        final list = await StudentSupportService.listInterventions(
          widget.item.caseId,
        );
        if (mounted) {
          setState(() {
            _interventions = list;
            _isLoadingInterventions = false;
          });
        }
      } else {
        setState(() {
          _interventions = [
            StudentSupportIntervention(
              interventionId: 'i1',
              caseId: widget.item.caseId,
              actionType: 'counseling',
              notes: 'นัดพูดคุยหลังเลิกเรียนเพื่อสอบถามสาเหตุการส่งงานช้า',
              recordedByName: widget.item.createdByName,
              createdAt: DateTime.now().subtract(const Duration(days: 1)),
            ),
          ];
          _isLoadingInterventions = false;
        });
      }
    } catch (_) {
      setState(() => _isLoadingInterventions = false);
    }
  }

  Future<void> _addIntervention() async {
    if (_interventionCtrl.text.trim().isEmpty) return;

    if (AuthService.sessionToken != null &&
        !widget.item.caseId.startsWith('mock-')) {
      try {
        await StudentSupportService.addIntervention(
          caseId: widget.item.caseId,
          actionType: _actionType,
          notes: _interventionCtrl.text.trim(),
        );
        _interventionCtrl.clear();
        await _loadInterventions();
        widget.onChanged();
      } catch (_) {}
    } else {
      setState(() {
        _interventions.insert(
          0,
          StudentSupportIntervention(
            interventionId: 'i_${DateTime.now().millisecondsSinceEpoch}',
            caseId: widget.item.caseId,
            actionType: _actionType,
            notes: _interventionCtrl.text.trim(),
            recordedByName: 'คุณครู',
            createdAt: DateTime.now(),
          ),
        );
        _interventionCtrl.clear();
      });
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _status = newStatus);
    if (AuthService.sessionToken != null &&
        !widget.item.caseId.startsWith('mock-')) {
      try {
        await StudentSupportService.updateCaseStatus(
          caseId: widget.item.caseId,
          status: newStatus,
        );
        widget.onChanged();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      widget.item.studentName,
                      style: const TextStyle(
                        color: TeacherPalette.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${widget.item.courseName} · หมวด${widget.item.categoryLabel}',
                      style: const TextStyle(
                        color: TeacherPalette.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'เปลี่ยนสถานะการดูแล',
                      style: TextStyle(
                        color: TeacherPalette.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _status,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'open',
                          child: Text('🟢 เปิดเคสใหม่ (Open)'),
                        ),
                        DropdownMenuItem(
                          value: 'in_progress',
                          child: Text('🟡 กำลังช่วยเหลือ (In Progress)'),
                        ),
                        DropdownMenuItem(
                          value: 'escalated',
                          child: Text('🔴 ส่งต่อฝ่ายแนะแนว (Escalated)'),
                        ),
                        DropdownMenuItem(
                          value: 'resolved',
                          child: Text('✅ ปิดเคสสำเร็จ (Resolved)'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) _updateStatus(val);
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'บันทึกการติดตาม & ช่วยเหลือ (Timeline)',
                      style: TextStyle(
                        color: TeacherPalette.ink,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_isLoadingInterventions)
                      const Center(child: CircularProgressIndicator())
                    else if (_interventions.isEmpty)
                      const Text(
                        'ยังไม่มีบันทึกการช่วยเหลือ',
                        style: TextStyle(color: TeacherPalette.muted),
                      )
                    else
                      for (final iv in _interventions) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: TeacherPalette.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    iv.actionTypeLabel,
                                    style: const TextStyle(
                                      color: TeacherPalette.primary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    iv.recordedByName,
                                    style: const TextStyle(
                                      color: TeacherPalette.muted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                iv.notes,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: TeacherPalette.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    const SizedBox(height: 16),
                    const Text(
                      'เพิ่มบันทึกการช่วยเหลือใหม่',
                      style: TextStyle(
                        color: TeacherPalette.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _actionType,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'counseling',
                          child: Text('💬 การให้คำปรึกษา/พูดคุย'),
                        ),
                        DropdownMenuItem(
                          value: 'remedial_lesson',
                          child: Text('📖 สอนเสริม/ทบทวนบทเรียน'),
                        ),
                        DropdownMenuItem(
                          value: 'parent_meeting',
                          child: Text('📞 ติดต่อผู้ปกครอง'),
                        ),
                        DropdownMenuItem(
                          value: 'activity_assigned',
                          child: Text('📝 มอบหมายแบบฝึกหัดเสริม'),
                        ),
                        DropdownMenuItem(
                          value: 'observation',
                          child: Text('👀 บันทึกการสังเกตการณ์'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _actionType = val);
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _interventionCtrl,
                      decoration: InputDecoration(
                        hintText: 'รายละเอียดการพูดคุยหรือแนวทางช่วยเหลือ...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: _addIntervention,
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('บันทึก Timeline'),
                        style: FilledButton.styleFrom(
                          backgroundColor: TeacherPalette.primary,
                        ),
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
