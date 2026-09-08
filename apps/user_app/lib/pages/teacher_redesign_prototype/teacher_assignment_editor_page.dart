// PROTOTYPE: Teacher Assignment Editor & Management Page (ระบบสร้างและจัดการใบงาน)
// Wireframe MVP v1 Section 2.4.1 - 2.4.2
// Allows teachers to manage course assignments, create/edit worksheets/projects,
// toggle group work, attach Rubrics, bind AIoT sensor data streams, and publish assignments.

import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import 'teacher_grading_page.dart' show TeacherGradingPage;
import 'teacher_redesign_prototype_page.dart' show TeacherPalette;
import 'teacher_rubric_page.dart' show TeacherRubricPage;
import 'teacher_shared_widgets.dart' show TeacherMockPageShell, TeacherSearchInput;

/// Model สำหรับใบงาน (Assignment)
class AssignmentModel {
  AssignmentModel({
    required this.id,
    required this.courseId,
    required this.title,
    required this.instructions,
    required this.type, // 'ใบงานทดลอง', 'การบ้าน', 'โครงงาน AIoT'
    required this.courseName,
    required this.dueDate,
    required this.isGroupWork,
    required this.rubricId,
    required this.rubricTitle,
    required this.attachedSensorMetrics,
    required this.status, // 'ร่าง', 'เผยแพร่แล้ว'
    required this.submittedCount,
    required this.totalStudents,
    required this.updatedAt,
  });

  String id;
  String courseId;
  String title;
  String instructions;
  String type;
  String courseName;
  String dueDate;
  bool isGroupWork;
  String? rubricId;
  String rubricTitle;
  List<String> attachedSensorMetrics;
  String status;
  int submittedCount;
  int totalStudents;
  String updatedAt;

  bool get isPublished => status == 'เผยแพร่แล้ว';
}

class TeacherAssignmentEditorPage extends StatefulWidget {
  const TeacherAssignmentEditorPage({super.key});

  @override
  State<TeacherAssignmentEditorPage> createState() =>
      _TeacherAssignmentEditorPageState();
}

void openAssignmentFormModal(
  BuildContext context, {
  AssignmentModel? assignment,
  ValueChanged<AssignmentModel>? onSave,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _AssignmentFormSheet(
      assignment: assignment,
      onSave: onSave ?? (_) {},
    ),
  );
}

class _TeacherAssignmentEditorPageState
    extends State<TeacherAssignmentEditorPage> {
  String _searchQuery = '';
  String _selectedTab =
      'ทั้งหมด'; // 'ทั้งหมด', 'เผยแพร่แล้ว', 'ร่าง', 'งานกลุ่ม'

  // เดิม seed ด้วยใบงานตัวอย่าง 3 ใบตอนเปิดหน้า แล้วเขียนทับแค่ตอน
  // `list.isNotEmpty` — วิชาที่ยังไม่มีใบงานจริงเลยจะเห็นใบงานตัวอย่างค้าง
  // อยู่ตลอดไป ตอนนี้เริ่มจากลิสต์ว่างจริง
  List<AssignmentModel> _assignments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRealAssignments();
  }

  Future<void> _loadRealAssignments() async {
    if (mounted) setState(() => _loading = true);
    try {
      final courses = await CourseService.listMyCourses();
      if (courses.isEmpty) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final course = courses.first;
      final list = await AssignmentService.listAssignments(course.id);

      // นับนักเรียนในวิชาครั้งเดียว ใช้ร่วมกันทุกใบงานของวิชานี้ แทน
      // hardcode 28/30 ตายตัวทุกใบงาน
      int totalStudents = 0;
      try {
        final roster = await CourseService.listCourseStudents(course.id);
        totalStudents = roster.length;
      } catch (_) {
        // เหลือ 0 — โชว์ 'ยังไม่มีข้อมูล' ตรงๆ ดีกว่าเดา
      }

      final mapped = <AssignmentModel>[];
      for (final a in list) {
        int submittedCount = 0;
        try {
          final subs = await AssignmentService.listSubmissions(a.id);
          submittedCount = subs
              .where((s) => s.submittedAt != null)
              .length;
        } catch (_) {
          // เหลือ 0 — ไม่ใช่ของปลอม แค่ยังไม่รู้ค่าจริง
        }

        mapped.add(
          AssignmentModel(
            id: a.id,
            courseId: course.id,
            title: a.title,
            instructions: a.instructions ?? '',
            type: a.type == 'project'
                ? 'โครงงาน AIoT'
                : (a.type == 'experiment' ? 'ใบงานทดลอง' : 'การบ้าน'),
            courseName: course.subjectName,
            dueDate: a.dueAt != null
                ? a.dueAt!.toLocal().toString().substring(0, 16)
                : 'ไม่มีกำหนดส่ง',
            isGroupWork: a.isGroup,
            rubricId: a.rubricId,
            rubricTitle: a.rubricTitle ?? 'ยังไม่ได้กำหนด Rubric',
            attachedSensorMetrics: const [],
            status: a.status == 'published' ? 'เผยแพร่แล้ว' : 'ร่าง',
            submittedCount: submittedCount,
            totalStudents: totalStudents,
            updatedAt: a.createdAt != null
                ? 'สร้างเมื่อ ${a.createdAt!.toLocal().toString().substring(0, 10)}'
                : 'ยังไม่มีข้อมูล',
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        _assignments = mapped;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading assignments from RPC: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openCreateEditForm({AssignmentModel? existingAssignment}) {
    openAssignmentFormModal(
      context,
      assignment: existingAssignment,
      onSave: (savedItem) {
        setState(() {
          final idx = _assignments.indexWhere((a) => a.id == savedItem.id);
          if (idx >= 0) {
            _assignments[idx] = savedItem;
          } else {
            _assignments.insert(0, savedItem);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${savedItem.isPublished ? "เผยแพร่" : "บันทึกร่าง"} ใบงาน "${savedItem.title}" เรียบร้อยแล้ว',
            ),
            backgroundColor: savedItem.isPublished
                ? const Color(0xFF10B981)
                : const Color(0xFF0EA5E9),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _assignments.where((a) {
      final matchQuery =
          a.title.contains(_searchQuery) ||
          a.instructions.contains(_searchQuery) ||
          a.courseName.contains(_searchQuery);
      if (_selectedTab == 'เผยแพร่แล้ว') {
        return matchQuery && a.isPublished;
      } else if (_selectedTab == 'ร่าง') {
        return matchQuery && !a.isPublished;
      } else if (_selectedTab == 'งานกลุ่ม') {
        return matchQuery && a.isGroupWork;
      }
      return matchQuery;
    }).toList();

    return TeacherMockPageShell(
      title: 'จัดการใบงานและโจทย์ทดลอง',
      activeMenuLabel: 'ตรวจงาน',
      actions: [
        ElevatedButton.icon(
          onPressed: () => _openCreateEditForm(),
          icon: const Icon(Icons.add_task_rounded, size: 18),
          label: const Text(
            'สร้างใบงานใหม่',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: TeacherPalette.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
        ),
      ],
      builder: (context, isDesktop) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(isDesktop ? 24 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filter & Search Header Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: TeacherPalette.border),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x080F172A),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    TeacherSearchInput(
                      hintText: 'ค้นหาชื่อใบงาน, คำสั่ง หรือเซนเซอร์ที่ผูกไว้...',
                      value: _searchQuery,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      onClear: () => setState(() => _searchQuery = ''),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text(
                          'สถานะ:',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: TeacherPalette.muted,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Wrap(
                          spacing: 8,
                          children:
                              ['ทั้งหมด', 'เผยแพร่แล้ว', 'ร่าง', 'งานกลุ่ม']
                                  .map(
                                    (tab) => ChoiceChip(
                                      label: Text(tab),
                                      selected: _selectedTab == tab,
                                      onSelected: (sel) {
                                        if (sel) {
                                          setState(() => _selectedTab = tab);
                                        }
                                      },
                                      selectedColor: TeacherPalette.primary
                                          .withValues(alpha: 0.15),
                                      labelStyle: TextStyle(
                                        color: _selectedTab == tab
                                            ? TeacherPalette.primary
                                            : TeacherPalette.muted,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      side: BorderSide(
                                        color: _selectedTab == tab
                                            ? TeacherPalette.primary
                                            : const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Assignment Cards Loop
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (filtered.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: TeacherPalette.border),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.assignment_late_outlined,
                        size: 48,
                        color: TeacherPalette.muted,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'ไม่พบใบงานตามเงื่อนไขที่ระบุ',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: TeacherPalette.ink,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return _AssignmentCardItem(
                      assignment: item,
                      onTapEdit: () =>
                          _openCreateEditForm(existingAssignment: item),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

/// การ์ดแสดงผลใบงานแต่ละรายการ
class _AssignmentCardItem extends StatelessWidget {
  const _AssignmentCardItem({
    required this.assignment,
    required this.onTapEdit,
  });

  final AssignmentModel assignment;
  final VoidCallback onTapEdit;

  @override
  Widget build(BuildContext context) {
    final isPublished = assignment.isPublished;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: TeacherPalette.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isPublished
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isPublished
                      ? Icons.assignment_turned_in_rounded
                      : Icons.edit_document,
                  color: isPublished
                      ? const Color(0xFF10B981)
                      : const Color(0xFF64748B),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E8FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            assignment.type,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF7E22CE),
                            ),
                          ),
                        ),
                        if (assignment.isGroupWork) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.groups_rounded,
                                  size: 11,
                                  color: Color(0xFF0284C7),
                                ),
                                SizedBox(width: 3),
                                Text(
                                  'งานกลุ่ม',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0284C7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      assignment.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: TeacherPalette.ink,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      assignment.instructions,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: TeacherPalette.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isPublished
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isPublished
                        ? const Color(0xFFA7F3D0)
                        : const Color(0xFFFDE68A),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: isPublished
                            ? const Color(0xFF10B981)
                            : const Color(0xFFD97706),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      assignment.status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isPublished
                            ? const Color(0xFF059669)
                            : const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Details Metadata Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.event_available_rounded,
                      size: 14,
                      color: TeacherPalette.muted,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'กำหนดส่ง:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: TeacherPalette.muted,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      assignment.dueDate,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: TeacherPalette.ink,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.fact_check_outlined,
                      size: 14,
                      color: TeacherPalette.primary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        assignment.rubricTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: TeacherPalette.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                if (assignment.attachedSensorMetrics.isNotEmpty) ...[
                  const Divider(height: 14),
                  Row(
                    children: [
                      const Icon(
                        Icons.sensors_rounded,
                        size: 14,
                        color: Color(0xFF0284C7),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'ผูกเซนเซอร์ AIoT:',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Wrap(
                        spacing: 6,
                        children: assignment.attachedSensorMetrics
                            .map(
                              (m) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0F2FE),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  m,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0284C7),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Submission Progress Bar & Bottom Actions
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ส่งแล้ว ${assignment.submittedCount}/${assignment.totalStudents} คน',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: TeacherPalette.ink,
                          ),
                        ),
                        Text(
                          '${((assignment.submittedCount / assignment.totalStudents) * 100).round()}%',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: TeacherPalette.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value:
                            assignment.submittedCount /
                            assignment.totalStudents,
                        minHeight: 6,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          TeacherPalette.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Action Buttons
              OutlinedButton.icon(
                onPressed: onTapEdit,
                icon: const Icon(Icons.edit_outlined, size: 15),
                label: const Text('แก้ไข'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: TeacherPalette.ink,
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  minimumSize: const Size(0, 38),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TeacherGradingPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.fact_check_rounded, size: 15),
                label: const Text('ตรวจงาน'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TeacherPalette.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 38),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Modal Sheet สำหรับสร้าง/แก้ไขใบงาน
class _AssignmentFormSheet extends StatefulWidget {
  const _AssignmentFormSheet({required this.assignment, required this.onSave});

  final AssignmentModel? assignment;
  final ValueChanged<AssignmentModel> onSave;

  @override
  State<_AssignmentFormSheet> createState() => _AssignmentFormSheetState();
}

class _AssignmentFormSheetState extends State<_AssignmentFormSheet> {
  late TextEditingController _titleController;
  late TextEditingController _instructionsController;
  late TextEditingController _dueDateController;
  late String _type;
  late bool _isGroupWork;

  // เดิม dropdown "เลือก Rubric" เป็นสตริง hardcode ตายตัว 1 ค่า และ
  // `_handleSave` ไม่เคยส่ง rubric ที่เลือกไปที่ backend เลย ทั้งที่
  // assignments.rubric_id มีอยู่จริงและ create_assignment/update_assignment
  // รับ p_rubric_id อยู่แล้ว — ตอนนี้โหลด rubric จริงและส่งค่าจริง
  List<RubricModel> _rubrics = [];
  bool _rubricsLoading = true;
  String? _selectedRubricId;

  @override
  void initState() {
    super.initState();
    final a = widget.assignment;
    _titleController = TextEditingController(text: a?.title ?? '');
    _instructionsController = TextEditingController(
      text: a?.instructions ?? '',
    );
    _dueDateController = TextEditingController(
      text: a?.dueDate ?? '18 ส.ค. 2026 (23:59 น.)',
    );
    _type = a?.type ?? 'ใบงานทดลอง';
    _isGroupWork = a?.isGroupWork ?? false;
    _selectedRubricId = a?.rubricId;
    _loadRubrics();
  }

  Future<void> _loadRubrics() async {
    try {
      final list = await RubricService.listMyRubrics();
      if (!mounted) return;
      setState(() {
        _rubrics = list;
        _rubricsLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading rubrics: $e');
      if (mounted) setState(() => _rubricsLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _instructionsController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }

  Future<void> _handleSave({required bool publish}) async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกชื่อใบงาน'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    String assignedId;
    String realCourseId;
    String realCourseName;

    try {
      if (widget.assignment != null) {
        // แก้ไขใบงานเดิม — ใช้วิชาเดิมของใบงาน ไม่ใช่ courses.first เสมอ
        // (บั๊กเดียวกับที่เคยแก้ใน exam_builder/lesson_editor — ครูมีหลาย
        // วิชา courses.first อาจไม่ใช่วิชาของใบงานนี้เลย)
        realCourseId = widget.assignment!.courseId;
        realCourseName = widget.assignment!.courseName;
        assignedId = widget.assignment!.id;
        await AssignmentService.updateAssignment(
          assignmentId: assignedId,
          title: title,
          instructions: _instructionsController.text.trim(),
          rubricId: _selectedRubricId,
        );
      } else {
        final courses = await CourseService.listMyCourses();
        if (courses.isEmpty) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'ไม่พบรายวิชาของคุณในระบบ กรุณาสร้างรายวิชาก่อนสร้างใบงาน',
              ),
              backgroundColor: Color(0xFFEF4444),
            ),
          );
          return;
        }
        final course = courses.first;
        realCourseId = course.id;
        realCourseName = course.subjectName;

        final typeEnum = _type == 'โครงงาน AIoT'
            ? 'project'
            : (_type == 'ใบงานทดลอง' ? 'worksheet' : 'homework');

        assignedId = await AssignmentService.createAssignment(
          courseId: course.id,
          type: typeEnum,
          title: title,
          instructions: _instructionsController.text.trim(),
          rubricId: _selectedRubricId,
        );
      }

      if (publish) {
        await AssignmentService.publishAssignment(assignedId);
      }
    } catch (e) {
      debugPrint('Error saving assignment to Supabase: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('บันทึกใบงานไม่สำเร็จ: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

    final selectedRubricTitle = _selectedRubricId == null
        ? 'ยังไม่ได้กำหนด Rubric'
        : (_rubrics
                  .where((r) => r.id == _selectedRubricId)
                  .map((r) => r.title)
                  .firstOrNull ??
              'ยังไม่ได้กำหนด Rubric');

    final newAssignment = AssignmentModel(
      id: assignedId,
      courseId: realCourseId,
      title: title,
      instructions: _instructionsController.text.trim(),
      type: _type,
      courseName: realCourseName,
      dueDate: _dueDateController.text.trim(),
      isGroupWork: _isGroupWork,
      rubricId: _selectedRubricId,
      rubricTitle: selectedRubricTitle,
      attachedSensorMetrics: widget.assignment?.attachedSensorMetrics ?? const [],
      status: publish ? 'เผยแพร่แล้ว' : 'ร่าง',
      submittedCount: widget.assignment?.submittedCount ?? 0,
      totalStudents: widget.assignment?.totalStudents ?? 0,
      updatedAt: widget.assignment?.updatedAt ?? 'สร้างเมื่อวันนี้',
    );

    widget.onSave(newAssignment);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.assignment != null;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: TeacherPalette.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.add_task_rounded,
                          color: TeacherPalette.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isEditMode ? 'แก้ไขใบงาน' : 'สร้างใบงานใหม่',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: TeacherPalette.ink,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const Divider(height: 24),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'ชื่อใบงาน / หัวข้อโจทย์ *',
                        hintText:
                            'เช่น ใบงานทดลองที่ 3: การวัดและวิเคราะห์ค่าฝุ่น PM2.5',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _instructionsController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'คำสั่งงาน / รายละเอียดคำอธิบาย',
                        hintText:
                            'อธิบายขั้นตอนการทำโจทย์ การทดลอง หรือรูปแบบการส่งงาน',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _type,
                            onChanged: (val) {
                              if (val != null) setState(() => _type = val);
                            },
                            decoration: InputDecoration(
                              labelText: 'ประเภทงาน',
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: {'ใบงานทดลอง', 'การบ้าน', 'โครงงาน AIoT', _type}
                                .map(
                                  (t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(t),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _dueDateController,
                            decoration: InputDecoration(
                              labelText: 'กำหนดส่งงาน',
                              suffixIcon: const Icon(
                                Icons.calendar_today_rounded,
                                size: 18,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Group Work Switch
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.groups_rounded,
                                color: Color(0xFF0284C7),
                              ),
                              SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'กำหนดเป็นงานกลุ่ม',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: TeacherPalette.ink,
                                    ),
                                  ),
                                  Text(
                                    'นักเรียนทำโจทย์ร่วมกันและส่งงานเพียง 1 คนต่อกลุ่ม',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: TeacherPalette.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Switch(
                            value: _isGroupWork,
                            activeColor: const Color(0xFF0284C7),
                            onChanged: (val) =>
                                setState(() => _isGroupWork = val),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Rubric Selector Header & Dropdown
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'ผูก Rubric เกณฑ์การประเมิน',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: TeacherPalette.ink,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TeacherRubricPage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.open_in_new_rounded, size: 14),
                          label: const Text('จัดการ Rubric ทั้งหมด'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // เดิม dropdown มีตัวเลือกที่แต่งขึ้นเอง 4 ตัวเลือกตายตัว
                    // เลือกแล้วไม่เคยถูกส่งไป backend เลย — ตอนนี้โหลด rubric
                    // จริงของครูคนนี้ผ่าน RubricService และส่ง rubricId จริง
                    if (_rubricsLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    else
                      DropdownButtonFormField<String?>(
                        value: _selectedRubricId,
                        onChanged: (val) =>
                            setState(() => _selectedRubricId = val),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('ไม่มี Rubric (ประเมินคะแนนดิบ)'),
                          ),
                          ..._rubrics.map(
                            (r) => DropdownMenuItem<String?>(
                              value: r.id,
                              child: Text(
                                r.title,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 20),

                    // AIoT Sensors Selector Section — เดิมมีชิปให้เลือกแต่ไม่
                    // เคยถูกส่งไป backend เลย (ไม่มี RPC เขียนลง
                    // assignment_sensor_datasets จากหน้านี้) ปิดไว้พร้อม
                    // เหตุผลแทนให้เลือกได้แล้วทิ้งของที่เลือก
                    const Text(
                      'ผูกชุดข้อมูลเซนเซอร์ AIoT (สำหรับให้โจทย์ดึงค่า)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: TeacherPalette.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'ยังไม่รองรับการผูกชุดข้อมูลเซนเซอร์จากหน้านี้ในเวอร์ชันนี้',
                      style: TextStyle(
                        fontSize: 12,
                        color: TeacherPalette.muted,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              // Footer Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _handleSave(publish: false),
                    icon: const Icon(Icons.save_as_rounded, size: 16),
                    label: const Text('บันทึกร่าง'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: TeacherPalette.ink,
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size(0, 44),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => _handleSave(publish: true),
                    icon: const Icon(Icons.send_rounded, size: 16),
                    label: const Text('เผยแพร่ใบงาน'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TeacherPalette.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
