// PROTOTYPE: Teacher Assignment Editor & Management Page (ระบบสร้างและจัดการใบงาน)
// Wireframe MVP v1 Section 2.4.1 - 2.4.2
// Allows teachers to manage course assignments, create/edit worksheets/projects,
// toggle group work, attach Rubrics, bind AIoT sensor data streams, and publish assignments.

import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import '../assignments/assignment_save_controller.dart';

import 'teacher_grading_page.dart' show TeacherGradingPage;
import 'teacher_redesign_prototype_page.dart' show TeacherPalette;
import 'teacher_rubric_page.dart' show TeacherRubricPage;
import 'teacher_shared_widgets.dart'
    show TeacherMockPageShell, TeacherSearchInput;

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
  const TeacherAssignmentEditorPage({
    super.key,
    this.loadCourses,
    this.loadAssignmentsForCourse,
    this.loadCourseStudents,
    this.loadSubmissions,
    this.listMyRubrics,
    this.updateAssignment,
    this.createAssignment,
    this.publishAssignment,
    this.listDevices,
    this.linkSensorDataset,
    this.loadAssignmentDetail,
  });

  /// Read seams threaded to the corresponding CourseService/
  /// AssignmentService static calls in production.
  final Future<List<CourseSummary>> Function()? loadCourses;
  final Future<List<AssignmentSummary>> Function(String courseId)?
  loadAssignmentsForCourse;
  final Future<List<CourseStudent>> Function(String courseId)?
  loadCourseStudents;
  final Future<List<SubmissionRoster>> Function(String assignmentId)?
  loadSubmissions;

  /// Threaded down to the create/edit form sheet's own seams — see
  /// openAssignmentFormModal for what each one replaces in production.
  final Future<List<RubricModel>> Function()? listMyRubrics;
  final Future<void> Function({
    required String assignmentId,
    String? title,
    String? instructions,
    DateTime? dueAt,
    String? rubricId,
    bool? isGroup,
  })?
  updateAssignment;
  final Future<String> Function({
    required String courseId,
    required String type,
    required String title,
    String? instructions,
    DateTime? dueAt,
    String? rubricId,
    bool isGroup,
  })?
  createAssignment;
  final Future<void> Function(String assignmentId)? publishAssignment;

  /// PBL-4 seams, threaded down through _openCreateEditForm to
  /// openAssignmentFormModal / _AssignmentFormSheet.
  final Future<List<DeviceOption>> Function()? listDevices;
  final Future<void> Function({
    required String assignmentId,
    required String deviceId,
    required String metric,
    DateTime? timeStart,
    DateTime? timeEnd,
    String? label,
  })?
  linkSensorDataset;
  final Future<AssignmentDetail> Function(String assignmentId)?
  loadAssignmentDetail;

  @override
  State<TeacherAssignmentEditorPage> createState() =>
      _TeacherAssignmentEditorPageState();
}

void openAssignmentFormModal(
  BuildContext context, {
  AssignmentModel? assignment,
  ValueChanged<AssignmentModel>? onSave,
  Future<List<RubricModel>> Function()? listMyRubrics,
  Future<List<CourseSummary>> Function()? loadCoursesForNew,
  Future<void> Function({
    required String assignmentId,
    String? title,
    String? instructions,
    DateTime? dueAt,
    String? rubricId,
    bool? isGroup,
  })?
  updateAssignment,
  Future<String> Function({
    required String courseId,
    required String type,
    required String title,
    String? instructions,
    DateTime? dueAt,
    String? rubricId,
    bool isGroup,
  })?
  createAssignment,
  Future<void> Function(String assignmentId)? publishAssignment,
  Future<List<DeviceOption>> Function()? listDevices,
  Future<void> Function({
    required String assignmentId,
    required String deviceId,
    required String metric,
    DateTime? timeStart,
    DateTime? timeEnd,
    String? label,
  })?
  linkSensorDataset,
  Future<AssignmentDetail> Function(String assignmentId)? loadAssignmentDetail,
  Future<List<AssignmentSummary>> Function(String courseId)?
  loadAssignmentsForCourse,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _AssignmentFormSheet(
      assignment: assignment,
      onSave: onSave ?? (_) {},
      listMyRubrics: listMyRubrics,
      loadCoursesForNew: loadCoursesForNew,
      updateAssignment: updateAssignment,
      createAssignment: createAssignment,
      publishAssignment: publishAssignment,
      listDevices: listDevices,
      linkSensorDataset: linkSensorDataset,
      loadAssignmentDetail: loadAssignmentDetail,
      loadAssignmentsForCourse: loadAssignmentsForCourse,
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
      final loadCourses = widget.loadCourses ?? CourseService.listMyCourses;
      final loadAssignments =
          widget.loadAssignmentsForCourse ?? AssignmentService.listAssignments;
      final loadStudents =
          widget.loadCourseStudents ?? CourseService.listCourseStudents;
      final loadSubmissions =
          widget.loadSubmissions ?? AssignmentService.listSubmissions;

      final courses = await loadCourses();
      if (courses.isEmpty) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final course = courses.first;
      final list = await loadAssignments(course.id);

      // นับนักเรียนในวิชาครั้งเดียว ใช้ร่วมกันทุกใบงานของวิชานี้ แทน
      // hardcode 28/30 ตายตัวทุกใบงาน
      int totalStudents = 0;
      try {
        final roster = await loadStudents(course.id);
        totalStudents = roster.length;
      } catch (_) {
        // เหลือ 0 — โชว์ 'ยังไม่มีข้อมูล' ตรงๆ ดีกว่าเดา
      }

      // One submissions RPC per assignment, awaited in the loop — N sequential
      // round trips before the editor could render. They are independent.
      final submittedCounts = await Future.wait(
        list.map((a) async {
          try {
            final subs = await loadSubmissions(a.id);
            return subs.where((s) => s.submittedAt != null).length;
          } catch (_) {
            // เหลือ 0 — ไม่ใช่ของปลอม แค่ยังไม่รู้ค่าจริง
            return 0;
          }
        }),
      );
      final mapped = <AssignmentModel>[];
      for (var ai = 0; ai < list.length; ai++) {
        final a = list[ai];
        final submittedCount = submittedCounts[ai];

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
      listMyRubrics: widget.listMyRubrics,
      loadCoursesForNew: widget.loadCourses,
      updateAssignment: widget.updateAssignment,
      createAssignment: widget.createAssignment,
      publishAssignment: widget.publishAssignment,
      listDevices: widget.listDevices,
      linkSensorDataset: widget.linkSensorDataset,
      loadAssignmentDetail: widget.loadAssignmentDetail,
      loadAssignmentsForCourse: widget.loadAssignmentsForCourse,
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
                      hintText:
                          'ค้นหาชื่อใบงาน, คำสั่ง หรือเซนเซอร์ที่ผูกไว้...',
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
                            fontSize: 12,
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
                              fontSize: 11,
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
                                    fontSize: 11,
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
                        fontSize: 15,
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
                        fontSize: 12,
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
                          fontSize: 11,
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
                          fontSize: 11,
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
                                    fontSize: 11,
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
                          assignment.totalStudents == 0
                              ? 'ยังไม่มีนักเรียน'
                              : '${((assignment.submittedCount / assignment.totalStudents) * 100).round()}%',
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
                        value: assignment.totalStudents == 0
                            ? 0
                            : (assignment.submittedCount /
                                      assignment.totalStudents)
                                  .clamp(0.0, 1.0),
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
  const _AssignmentFormSheet({
    required this.assignment,
    required this.onSave,
    this.listMyRubrics,
    this.loadCoursesForNew,
    this.updateAssignment,
    this.createAssignment,
    this.publishAssignment,
    this.listDevices,
    this.linkSensorDataset,
    this.loadAssignmentDetail,
    this.loadAssignmentsForCourse,
  });

  final AssignmentModel? assignment;
  final ValueChanged<AssignmentModel> onSave;
  final Future<List<AssignmentSummary>> Function(String courseId)?
  loadAssignmentsForCourse;
  final Future<List<RubricModel>> Function()? listMyRubrics;
  final Future<List<CourseSummary>> Function()? loadCoursesForNew;
  final Future<void> Function({
    required String assignmentId,
    String? title,
    String? instructions,
    DateTime? dueAt,
    String? rubricId,
    bool? isGroup,
  })?
  updateAssignment;
  final Future<String> Function({
    required String courseId,
    required String type,
    required String title,
    String? instructions,
    DateTime? dueAt,
    String? rubricId,
    bool isGroup,
  })?
  createAssignment;
  final Future<void> Function(String assignmentId)? publishAssignment;

  /// PBL-4 seams — same `??` fallback-to-real-service pattern as the rest
  /// of this widget.
  final Future<List<DeviceOption>> Function()? listDevices;
  final Future<void> Function({
    required String assignmentId,
    required String deviceId,
    required String metric,
    DateTime? timeStart,
    DateTime? timeEnd,
    String? label,
  })?
  linkSensorDataset;
  final Future<AssignmentDetail> Function(String assignmentId)?
  loadAssignmentDetail;

  @override
  State<_AssignmentFormSheet> createState() => _AssignmentFormSheetState();
}

class _AssignmentFormSheetState extends State<_AssignmentFormSheet> {
  late final AssignmentSaveController _saveController;
  bool _saving = false;
  String? _saveError;
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

  // PBL-4 — only meaningful once the assignment has a real backend id
  // (link_assignment_sensor_dataset requires p_assignment_id), so this
  // stays empty in "create new" mode and only loads in edit mode.
  List<AssignmentSensorDataset> _sensorDatasets = [];
  bool _sensorDatasetsLoading = false;
  Map<String, String> _deviceNames = {};

  /// Only the 7 values link_assignment_sensor_dataset's `p_metric metric_type`
  /// column actually accepts (20260715000000_initial_schema.sql). Devices
  /// like `water_meter` report metrics (water_flow_lmin, ...) entirely
  /// outside this set — offering those here would fail the RPC's enum cast,
  /// so they're filtered out below rather than copied in from
  /// DeviceOption.metrics unfiltered.
  static const _validMetricTypes = {
    'pm25',
    'aqi',
    'temperature',
    'humidity',
    'light_lux',
    'energy_kwh',
    'power_w',
  };

  @override
  void initState() {
    super.initState();
    final a = widget.assignment;
    _titleController = TextEditingController(text: a?.title ?? '');
    _instructionsController = TextEditingController(
      text: a?.instructions ?? '',
    );
    _dueDateController = TextEditingController(
      text: a?.dueDate == 'ไม่มีกำหนดส่ง' ? '' : a?.dueDate ?? '',
    );
    _saveController = AssignmentSaveController(
      assignmentId: a?.id,
      create: widget.createAssignment ?? AssignmentService.createAssignment,
      update: widget.updateAssignment ?? AssignmentService.updateAssignment,
      publish: widget.publishAssignment ?? AssignmentService.publishAssignment,
      read:
          widget.loadAssignmentsForCourse ?? AssignmentService.listAssignments,
    );
    _type = a?.type ?? 'ใบงานทดลอง';
    _isGroupWork = a?.isGroupWork ?? false;
    _selectedRubricId = a?.rubricId;
    _loadRubrics();
    if (a != null) _refreshSensorDatasets();
  }

  Future<void> _refreshSensorDatasets() async {
    final assignmentId = widget.assignment?.id;
    if (assignmentId == null) return;
    setState(() => _sensorDatasetsLoading = true);
    try {
      final loadDetail =
          widget.loadAssignmentDetail ?? AssignmentService.getAssignment;
      final detail = await loadDetail(assignmentId);
      if (!mounted) return;
      setState(() {
        _sensorDatasets = detail.sensorDatasets;
        _sensorDatasetsLoading = false;
      });
      if (detail.sensorDatasets.isNotEmpty && _deviceNames.isEmpty) {
        await _loadDeviceNames();
      }
    } catch (e) {
      debugPrint('_AssignmentFormSheet: โหลดชุดข้อมูลเซนเซอร์ไม่สำเร็จ — $e');
      if (mounted) setState(() => _sensorDatasetsLoading = false);
    }
  }

  Future<void> _loadDeviceNames() async {
    try {
      final listDevices = widget.listDevices ?? LessonService.listSchoolDevices;
      final devices = await listDevices();
      if (!mounted) return;
      setState(() {
        _deviceNames = {for (final d in devices) d.id: d.name};
      });
    } catch (e) {
      debugPrint('_AssignmentFormSheet: โหลดชื่ออุปกรณ์ไม่สำเร็จ — $e');
    }
  }

  Future<void> _openLinkSensorDialog() async {
    final assignmentId = widget.assignment?.id;
    if (assignmentId == null) return;

    final listDevices = widget.listDevices ?? LessonService.listSchoolDevices;
    List<DeviceOption> devices;
    try {
      // list_school_devices คืนทุกชนิด (รีเลย์ กล้อง gateway ปุ่มฉุกเฉิน ...)
      // — ผูกได้เฉพาะเซนเซอร์ที่มี metric อยู่ใน metric_type enum จริง
      // (ตัด water_meter ทิ้งไปเลยเพราะไม่มี metric ไหนอยู่ใน enum นี้)
      devices = (await listDevices())
          .where((d) => d.isSensor && d.metrics.any(_validMetricTypes.contains))
          .toList();
    } catch (e) {
      debugPrint('_AssignmentFormSheet: โหลดรายการอุปกรณ์ไม่สำเร็จ — $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('โหลดรายการอุปกรณ์ไม่สำเร็จ กรุณาลองใหม่'),
        ),
      );
      return;
    }
    if (!mounted) return;
    if (devices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'โรงเรียนยังไม่มีอุปกรณ์เซนเซอร์ที่ผูกได้ในระบบ ให้แอดมินลงทะเบียนอุปกรณ์ก่อน',
          ),
        ),
      );
      return;
    }
    setState(() {
      _deviceNames = {..._deviceNames, for (final d in devices) d.id: d.name};
    });

    var deviceId = devices.first.id;
    List<String> metricsFor(String id) => devices
        .firstWhere((d) => d.id == id)
        .metrics
        .where(_validMetricTypes.contains)
        .toList();

    var metric = metricsFor(deviceId).first;
    final labelCtrl = TextEditingController();
    var submitting = false;
    String? error;

    // ช่วงเวลาของชุดข้อมูล — link_assignment_sensor_dataset รับ
    // p_time_start/p_time_end อยู่แล้ว แต่ dialog เดิมไม่มีช่องให้กรอก
    // ทำให้ปักได้แค่ "24 ชม.ล่าสุด" ปักข้อมูลย้อนหลังไม่ได้เลย (พบ 2026-09-20
    // ตอนทดสอบบน iPhone กับ prod ที่เซนเซอร์หยุดส่งไป 5 วัน). null = ไม่กำหนด
    // = ฝั่งนักเรียนใช้ 24 ชม.ล่าสุด เหมือนเดิม
    var windowPreset = _SensorWindowPreset.custom;
    DateTime? timeStart;
    DateTime? timeEnd;
    void applyPreset(_SensorWindowPreset p) {
      windowPreset = p;
      final now = DateTime.now();
      switch (p) {
        case _SensorWindowPreset.last24h:
          timeStart = now.subtract(const Duration(hours: 24));
          timeEnd = now;
        case _SensorWindowPreset.last7d:
          timeStart = now.subtract(const Duration(days: 7));
          timeEnd = now;
        case _SensorWindowPreset.last30d:
          timeStart = now.subtract(const Duration(days: 30));
          timeEnd = now;
        case _SensorWindowPreset.custom:
          break;
      }
    }

    Future<DateTime?> pickDateTime(BuildContext ctx, DateTime initial) async {
      final date = await showDatePicker(
        context: ctx,
        initialDate: initial,
        firstDate: DateTime(2024),
        lastDate: DateTime.now().add(const Duration(days: 1)),
      );
      if (date == null || !ctx.mounted) return null;
      final time = await showTimePicker(
        context: ctx,
        initialTime: TimeOfDay.fromDateTime(initial),
      );
      if (time == null) return null;
      return DateTime(date.year, date.month, date.day, time.hour, time.minute);
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialog) {
          Future<void> submit() async {
            setDialog(() {
              submitting = true;
              error = null;
            });
            try {
              final link =
                  widget.linkSensorDataset ??
                  ({
                    required String assignmentId,
                    required String deviceId,
                    required String metric,
                    DateTime? timeStart,
                    DateTime? timeEnd,
                    String? label,
                  }) => AssignmentService.linkSensorDataset(
                    assignmentId: assignmentId,
                    deviceId: deviceId,
                    metric: metric,
                    timeStart: timeStart,
                    timeEnd: timeEnd,
                    label: label,
                  );
              final label = labelCtrl.text.trim();
              if (timeStart != null &&
                  timeEnd != null &&
                  !timeEnd!.isAfter(timeStart!)) {
                setDialog(() {
                  submitting = false;
                  error = 'เวลาสิ้นสุดต้องอยู่หลังเวลาเริ่ม';
                });
                return;
              }
              await link(
                assignmentId: assignmentId,
                deviceId: deviceId,
                metric: metric,
                timeStart: timeStart,
                timeEnd: timeEnd,
                label: label.isEmpty ? null : label,
              );
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('ผูกชุดข้อมูลเซนเซอร์กับใบงานแล้ว'),
                ),
              );
              // อ่านกลับจากหลังบ้าน ไม่เติมรายการในเครื่องเอง
              await _refreshSensorDatasets();
            } catch (e) {
              debugPrint(
                '_AssignmentFormSheet: link_assignment_sensor_dataset ล้ม — $e',
              );
              // ครูอาจกดพื้นหลังปิด dialog ไปแล้วระหว่างรอ — ห้าม setState
              // บน StatefulBuilder ที่ถูกถอดไปแล้ว
              if (!dialogContext.mounted) return;
              setDialog(() {
                submitting = false;
                error = 'ผูกชุดข้อมูลเซนเซอร์ไม่สำเร็จ กรุณาลองใหม่อีกครั้ง';
              });
            }
          }

          return _OwnControllers(
            controllers: [labelCtrl],
            child: AlertDialog(
              title: const Text('ผูกชุดข้อมูลเซนเซอร์ AIoT กับใบงาน'),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        value: deviceId,
                        decoration: const InputDecoration(labelText: 'อุปกรณ์'),
                        items: [
                          for (final d in devices)
                            DropdownMenuItem(
                              value: d.id,
                              child: Text(
                                d.location == null || d.location!.isEmpty
                                    ? d.name
                                    : '${d.name} · ${d.location}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: submitting
                            ? null
                            : (v) {
                                if (v == null) return;
                                setDialog(() {
                                  deviceId = v;
                                  metric = metricsFor(v).first;
                                });
                              },
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: metric,
                        decoration: const InputDecoration(
                          labelText: 'ค่าที่ต้องการให้นักเรียนดู',
                        ),
                        items: [
                          for (final m in metricsFor(deviceId))
                            DropdownMenuItem(value: m, child: Text(m)),
                        ],
                        onChanged: submitting
                            ? null
                            : (v) => setDialog(() => metric = v ?? metric),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'ช่วงเวลาของข้อมูล',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: TeacherPalette.ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final p in _SensorWindowPreset.values)
                            ChoiceChip(
                              label: Text(p.label),
                              selected: windowPreset == p,
                              onSelected: submitting
                                  ? null
                                  : (_) => setDialog(() => applyPreset(p)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _SensorWindowRow(
                        label: 'เริ่ม',
                        value: timeStart,
                        enabled: !submitting,
                        onTap: () async {
                          final v = await pickDateTime(
                            dialogContext,
                            timeStart ??
                                DateTime.now().subtract(
                                  const Duration(days: 7),
                                ),
                          );
                          if (v == null) return;
                          setDialog(() {
                            windowPreset = _SensorWindowPreset.custom;
                            timeStart = v;
                          });
                        },
                        onClear: () => setDialog(() {
                          windowPreset = _SensorWindowPreset.custom;
                          timeStart = null;
                        }),
                      ),
                      _SensorWindowRow(
                        label: 'สิ้นสุด',
                        value: timeEnd,
                        enabled: !submitting,
                        onTap: () async {
                          final v = await pickDateTime(
                            dialogContext,
                            timeEnd ?? DateTime.now(),
                          );
                          if (v == null) return;
                          setDialog(() {
                            windowPreset = _SensorWindowPreset.custom;
                            timeEnd = v;
                          });
                        },
                        onClear: () => setDialog(() {
                          windowPreset = _SensorWindowPreset.custom;
                          timeEnd = null;
                        }),
                      ),
                      if (timeStart == null && timeEnd == null)
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            'ไม่กำหนด = นักเรียนเห็นค่า 24 ชั่วโมงล่าสุด ณ ตอนเปิดดู',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: labelCtrl,
                        decoration: const InputDecoration(
                          labelText: 'คำอธิบายชุดข้อมูล (ถ้ามี)',
                        ),
                      ),
                      if (error != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          error!,
                          style: const TextStyle(
                            color: Color(0xFFB91C1C),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: submitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('ยกเลิก'),
                ),
                FilledButton(
                  onPressed: submitting ? null : submit,
                  child: Text(submitting ? 'กำลังบันทึก…' : 'ผูกข้อมูล'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _loadRubrics() async {
    try {
      final listRubrics = widget.listMyRubrics ?? RubricService.listMyRubrics;
      final list = await listRubrics();
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
    if (_saving) return;
    final title = _titleController.text.trim();
    final dateText = _dueDateController.text.trim();
    final dueAt = dateText.isEmpty ? null : DateTime.tryParse(dateText);
    // DateTime.parse normalizes invalid dates (e.g. February 31); require
    // the exact local date/time typed by the teacher, not a rolled-over date.
    final validDate =
        dateText.isEmpty ||
        (RegExp(r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}$').hasMatch(dateText) &&
            dueAt != null &&
            dueAt.toString().substring(0, 16) == dateText);
    if (title.isEmpty || !validDate) {
      setState(
        () => _saveError = title.isEmpty
            ? 'กรุณากรอกชื่อใบงาน'
            : 'กรุณากรอกวันและเวลาให้ถูกต้อง เช่น 2027-01-25 16:30',
      );
      return;
    }
    // The current RPC treats null as "keep existing", not "clear".
    if (dueAt == null &&
        widget.assignment != null &&
        widget.assignment!.dueDate != 'ไม่มีกำหนดส่ง' &&
        widget.assignment!.dueDate.isNotEmpty) {
      setState(
        () => _saveError = 'ยังล้างกำหนดส่งเดิมไม่ได้ กรุณาระบุวันและเวลาใหม่',
      );
      return;
    }
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      final existing = widget.assignment;
      String courseId;
      String courseName;
      if (existing != null) {
        courseId = existing.courseId;
        courseName = existing.courseName;
      } else {
        final courses =
            await (widget.loadCoursesForNew ?? CourseService.listMyCourses)();
        if (courses.isEmpty) {
          if (mounted) {
            setState(
              () => _saveError =
                  'ไม่พบรายวิชาของคุณในระบบ กรุณาสร้างรายวิชาก่อนสร้างใบงาน',
            );
          }
          return;
        }
        courseId = courses.first.id;
        courseName = courses.first.subjectName;
      }
      final confirmed = await _saveController.save(
        courseId: courseId,
        type: _type == 'โครงงาน AIoT'
            ? 'project'
            : (_type == 'ใบงานทดลอง' ? 'worksheet' : 'homework'),
        title: title,
        instructions: _instructionsController.text.trim(),
        dueAt: dueAt,
        rubricId: _selectedRubricId,
        isGroup: _isGroupWork,
        publishNow: publish,
      );
      if (!mounted) return;
      final saved = AssignmentModel(
        id: confirmed.id,
        courseId: courseId,
        courseName: courseName,
        title: confirmed.title,
        instructions: confirmed.instructions ?? '',
        type: confirmed.type == 'project'
            ? 'โครงงาน AIoT'
            : (confirmed.type == 'worksheet' ? 'ใบงานทดลอง' : 'การบ้าน'),
        dueDate:
            confirmed.dueAt?.toLocal().toString().substring(0, 16) ??
            'ไม่มีกำหนดส่ง',
        isGroupWork: confirmed.isGroup,
        rubricId: confirmed.rubricId,
        rubricTitle: confirmed.rubricTitle ?? 'ยังไม่ได้กำหนด Rubric',
        attachedSensorMetrics: existing?.attachedSensorMetrics ?? const [],
        status: confirmed.isPublished ? 'เผยแพร่แล้ว' : 'ร่าง',
        submittedCount: confirmed.submittedCount,
        totalStudents: confirmed.totalStudents,
        updatedAt: confirmed.createdAt == null
            ? 'ยังไม่มีข้อมูล'
            : 'สร้างเมื่อ ${confirmed.createdAt!.toLocal().toString().substring(0, 10)}',
      );
      widget.onSave(saved);
      Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(
          () => _saveError = _saveController.hasWritten
              ? 'บันทึกคำขอแล้ว แต่ยังยืนยันข้อมูลล่าสุดไม่ได้ กรุณาลองอีกครั้ง'
              : 'บันทึกใบงานไม่สำเร็จ กรุณาลองใหม่',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.assignment != null;

    return PopScope(
      canPop: !_saving,
      child: AbsorbPointer(
        absorbing: _saving,
        child: DraggableScrollableSheet(
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
                              color: TeacherPalette.primary.withValues(
                                alpha: 0.12,
                              ),
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
                              fontSize: 17,
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
                                items:
                                    {
                                          'ใบงานทดลอง',
                                          'การบ้าน',
                                          'โครงงาน AIoT',
                                          _type,
                                        }
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
                                  hintText: '2027-01-25 16:30',
                                  helperText:
                                      'ปี ค.ศ. เวลาท้องถิ่น · เว้นว่างหากไม่กำหนด',
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
                              const Expanded(
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.groups_rounded,
                                      color: Color(0xFF0284C7),
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'กำหนดเป็นงานกลุ่ม',
                                            style: TextStyle(
                                              fontSize: 13,
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
                                    ),
                                  ],
                                ),
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
                            const Expanded(
                              child: Text(
                                'ผูก Rubric เกณฑ์การประเมิน',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: TeacherPalette.ink,
                                ),
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
                              icon: const Icon(
                                Icons.open_in_new_rounded,
                                size: 14,
                              ),
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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
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

                        const SizedBox(height: 16),
                        // PBL-4: this heading used to be removed with a comment
                        // saying a link made here would be invisible to
                        // students — true when written (2026-09-16), no longer
                        // true since PBL-6 (2026-09-18) made the redesigned
                        // student assignment sheet render pinned sensor
                        // datasets via StudentSensorDatasetPage.
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'ชุดข้อมูลเซนเซอร์ AIoT',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: TeacherPalette.ink,
                                ),
                              ),
                            ),
                            if (widget.assignment != null)
                              TextButton.icon(
                                onPressed: _openLinkSensorDialog,
                                icon: const Icon(
                                  Icons.sensors_rounded,
                                  size: 16,
                                ),
                                label: const Text('ผูกข้อมูล'),
                              ),
                          ],
                        ),
                        if (widget.assignment == null)
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              'บันทึกร่างใบงานนี้ก่อน แล้วค่อยกลับมาผูกชุดข้อมูลเซนเซอร์ทีหลังได้',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          )
                        else if (_sensorDatasetsLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          )
                        else if (_sensorDatasets.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              'ยังไม่มีชุดข้อมูลเซนเซอร์ผูกกับใบงานนี้',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          )
                        else ...[
                          for (final d in _sensorDatasets)
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.sensors_rounded,
                                    size: 14,
                                    color: TeacherPalette.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${_deviceNames[d.deviceId] ?? d.deviceId} · ${d.metric}'
                                      '${d.label != null && d.label!.isNotEmpty ? ' — ${d.label}' : ''}',
                                      style: const TextStyle(fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  // Footer Action Buttons
                  if (_saveError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _saveError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  if (_saving) const LinearProgressIndicator(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _saving
                            ? null
                            : () => _handleSave(publish: false),
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
                        onPressed: _saving
                            ? null
                            : () => _handleSave(publish: true),
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
        ),
      ),
    );
  }
}

/// Same helper as teacher_lesson_editor_page.dart's private `_OwnControllers`
/// (can't be reused across files — library-private). Disposing a dialog's
/// TextEditingController right after `showDialog` returns races the pop
/// animation: a pending rebuild frame can still reference the field after
/// dispose() runs, throwing "used after being disposed". Tying dispose to
/// this wrapper's own State.dispose() ties it to the dialog route's actual
/// removal instead.
class _OwnControllers extends StatefulWidget {
  const _OwnControllers({required this.controllers, required this.child});

  final List<TextEditingController> controllers;
  final Widget child;

  @override
  State<_OwnControllers> createState() => _OwnControllersState();
}

class _OwnControllersState extends State<_OwnControllers> {
  @override
  void dispose() {
    for (final c in widget.controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

enum _SensorWindowPreset {
  last24h('24 ชม.ล่าสุด'),
  last7d('7 วันล่าสุด'),
  last30d('30 วันล่าสุด'),
  custom('กำหนดเอง');

  const _SensorWindowPreset(this.label);
  final String label;
}

class _SensorWindowRow extends StatelessWidget {
  const _SensorWindowRow({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onTap,
    required this.onClear,
  });

  final String label;
  final DateTime? value;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback onClear;

  static String _fmt(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year + 543} ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 52,
          child: Text(label, style: const TextStyle(fontSize: 12)),
        ),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: enabled ? onTap : null,
            icon: const Icon(Icons.schedule_rounded, size: 16),
            label: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                value == null ? 'ไม่กำหนด' : _fmt(value!),
                style: const TextStyle(fontSize: 12),
              ),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
          ),
        ),
        if (value != null)
          IconButton(
            tooltip: 'ล้าง',
            onPressed: enabled ? onClear : null,
            icon: const Icon(Icons.close_rounded, size: 16),
          ),
      ],
    );
  }
}
