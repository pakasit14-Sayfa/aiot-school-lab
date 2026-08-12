// PROTOTYPE: Teacher Assignment Editor & Management Page (ระบบสร้างและจัดการใบงาน)
// Wireframe MVP v1 Section 2.4.1 - 2.4.2
// Allows teachers to manage course assignments, create/edit worksheets/projects,
// toggle group work, attach Rubrics, bind AIoT sensor data streams, and publish assignments.

import 'package:flutter/material.dart';

import 'teacher_grading_page.dart' show TeacherGradingPage;
import 'teacher_redesign_prototype_page.dart' show TeacherPalette;
import 'teacher_rubric_page.dart' show TeacherRubricPage;
import 'teacher_shared_widgets.dart' show TeacherMockPageShell;

/// Model สำหรับใบงาน (Assignment)
class AssignmentModel {
  AssignmentModel({
    required this.id,
    required this.title,
    required this.instructions,
    required this.type, // 'ใบงานทดลอง', 'การบ้าน', 'โครงงาน AIoT'
    required this.courseName,
    required this.dueDate,
    required this.isGroupWork,
    required this.rubricTitle,
    required this.attachedSensorMetrics,
    required this.status, // 'ร่าง', 'เผยแพร่แล้ว'
    required this.submittedCount,
    required this.totalStudents,
    required this.updatedAt,
  });

  String id;
  String title;
  String instructions;
  String type;
  String courseName;
  String dueDate;
  bool isGroupWork;
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

class _TeacherAssignmentEditorPageState
    extends State<TeacherAssignmentEditorPage> {
  String _searchQuery = '';
  String _selectedTab =
      'ทั้งหมด'; // 'ทั้งหมด', 'เผยแพร่แล้ว', 'ร่าง', 'งานกลุ่ม'

  late List<AssignmentModel> _assignments;

  @override
  void initState() {
    super.initState();
    _assignments = _getMockAssignments();
  }

  List<AssignmentModel> _getMockAssignments() {
    return [
      AssignmentModel(
        id: 'assign-1',
        title: 'ใบงานทดลองที่ 3: การวัดและวิเคราะห์ค่าฝุ่น PM2.5 ในห้องเรียน',
        instructions:
            'ให้นักเรียนใช้ชุดทดลอง AIoT อ่านค่า PM2.5 บันทึกค่าลงตาราง และวิเคราะห์ช่วงเวลาที่มีฝุ่นสูง พร้อมเสนอแนวทางแก้ไข',
        type: 'ใบงานทดลอง',
        courseName: 'ม.5/2 การออกแบบเทคโนโลยี',
        dueDate: '15 ส.ค. 2026 (23:59 น.)',
        isGroupWork: true,
        rubricTitle: 'เกณฑ์ประเมินโครงงาน STEM & AIoT (มาตรฐานโรงเรียน)',
        attachedSensorMetrics: ['PM2.5', 'อุณหภูมิ', 'ความชื้น'],
        status: 'เผยแพร่แล้ว',
        submittedCount: 22,
        totalStudents: 28,
        updatedAt: '10 ส.ค. 2026',
      ),
      AssignmentModel(
        id: 'assign-2',
        title: 'การบ้านบทที่ 2: วงจรรวมและการต่อสายสัญญาณไมโครคอนโทรลเลอร์',
        instructions:
            'วาดไดอะแกรมการต่อวงจรเซนเซอร์วัดความชื้นป้อนเข้ากับ ESP32 พร้อมเขียนคำอธิบายการทำงาน',
        type: 'การบ้าน',
        courseName: 'ม.5/2 การออกแบบเทคโนโลยี',
        dueDate: '18 ส.ค. 2026 (17:00 น.)',
        isGroupWork: false,
        rubricTitle: 'เกณฑ์ตรวจใบงานทดลองเซนเซอร์ (ม.5/2)',
        attachedSensorMetrics: ['อุณหภูมิ'],
        status: 'เผยแพร่แล้ว',
        submittedCount: 14,
        totalStudents: 28,
        updatedAt: '11 ส.ค. 2026',
      ),
      AssignmentModel(
        id: 'assign-3',
        title: 'โครงงานปลายภาค: ระบบเตือนภัยและเปิดพัดลมระบายอากาศอัตโนมัติ',
        instructions:
            'ออกแบบและสร้างต้นแบบฮาร์ดแวร์ AIoT ที่สามารถตรวจจับอุณหภูมิเกิน threshold แล้วสั่งเปิดพัดลมโมดูลรีเลย์อัตโนมัติ',
        type: 'โครงงาน AIoT',
        courseName: 'ม.5/2 การออกแบบเทคโนโลยี',
        dueDate: '30 ส.ค. 2026 (23:59 น.)',
        isGroupWork: true,
        rubricTitle: 'เกณฑ์ประเมินโครงงาน STEM & AIoT (มาตรฐานโรงเรียน)',
        attachedSensorMetrics: ['อุณหภูมิ', 'รีเลย์พัดลม', 'PM2.5'],
        status: 'ร่าง',
        submittedCount: 0,
        totalStudents: 28,
        updatedAt: '12 ส.ค. 2026',
      ),
    ];
  }

  void _openCreateEditForm({AssignmentModel? existingAssignment}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AssignmentFormSheet(
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
      ),
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
                    TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText:
                            'ค้นหาชื่อใบงาน, คำสั่ง หรือเซนเซอร์ที่ผูกไว้...',
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: TeacherPalette.muted,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
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
              if (filtered.isEmpty)
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
  late String _selectedRubric;
  late List<String> _selectedSensors;

  final List<String> _availableSensors = [
    'PM2.5',
    'อุณหภูมิ',
    'ความชื้น',
    'ดัชนี UV',
    'รีเลย์พัดลม',
  ];

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
    _selectedRubric =
        a?.rubricTitle ?? 'เกณฑ์ประเมินโครงงาน STEM & AIoT (มาตรฐานโรงเรียน)';
    _selectedSensors = List.from(
      a?.attachedSensorMetrics ?? ['PM2.5', 'อุณหภูมิ'],
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _instructionsController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }

  void _handleSave({required bool publish}) {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกชื่อใบงาน'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    final newAssignment = AssignmentModel(
      id:
          widget.assignment?.id ??
          'assign-${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text.trim(),
      instructions: _instructionsController.text.trim(),
      type: _type,
      courseName: 'ม.5/2 การออกแบบเทคโนโลยี',
      dueDate: _dueDateController.text.trim(),
      isGroupWork: _isGroupWork,
      rubricTitle: _selectedRubric,
      attachedSensorMetrics: _selectedSensors,
      status: publish ? 'เผยแพร่แล้ว' : 'ร่าง',
      submittedCount: widget.assignment?.submittedCount ?? 0,
      totalStudents: widget.assignment?.totalStudents ?? 28,
      updatedAt: 'วันนี้',
    );

    widget.onSave(newAssignment);
    Navigator.pop(context);
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
                            items: const [
                              DropdownMenuItem(
                                value: 'ใบงานทดลอง',
                                child: Text('ใบงานทดลอง'),
                              ),
                              DropdownMenuItem(
                                value: 'การบ้าน',
                                child: Text('การบ้าน'),
                              ),
                              DropdownMenuItem(
                                value: 'โครงงาน AIoT',
                                child: Text('โครงงาน AIoT'),
                              ),
                            ],
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
                    DropdownButtonFormField<String>(
                      value: _selectedRubric,
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedRubric = val);
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value:
                              'เกณฑ์ประเมินโครงงาน STEM & AIoT (มาตรฐานโรงเรียน)',
                          child: Text(
                            'เกณฑ์ประเมินโครงงาน STEM & AIoT (มาตรฐานโรงเรียน)',
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'เกณฑ์ตรวจใบงานทดลองเซนเซอร์ (ม.5/2)',
                          child: Text('เกณฑ์ตรวจใบงานทดลองเซนเซอร์ (ม.5/2)'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // AIoT Sensors Selector Section
                    const Text(
                      'ผูกชุดข้อมูลเซนเซอร์ AIoT (สำหรับให้โจทย์ดึงค่า)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: TeacherPalette.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _availableSensors.map((sensor) {
                        final isSelected = _selectedSensors.contains(sensor);
                        return FilterChip(
                          label: Text(sensor),
                          selected: isSelected,
                          onSelected: (sel) {
                            setState(() {
                              if (sel) {
                                _selectedSensors.add(sensor);
                              } else {
                                _selectedSensors.remove(sensor);
                              }
                            });
                          },
                          selectedColor: const Color(
                            0xFF0284C7,
                          ).withValues(alpha: 0.15),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? const Color(0xFF0284C7)
                                : TeacherPalette.muted,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? const Color(0xFF0284C7)
                                : const Color(0xFFE2E8F0),
                          ),
                        );
                      }).toList(),
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
