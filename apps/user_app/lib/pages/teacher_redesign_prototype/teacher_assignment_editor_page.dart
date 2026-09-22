// PROTOTYPE: Teacher Assignment Editor & Management Page (ระบบสร้างและจัดการใบงาน)
// Wireframe MVP v1 Section 2.4.1 - 2.4.2
// Allows teachers to manage course assignments, create/edit worksheets/projects,
// toggle group work, attach Rubrics, bind AIoT sensor data streams, and publish assignments.

import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import '../assignments/assignment_save_controller.dart';

import 'teacher_airy_kit.dart';
import 'teacher_date_time_sheet.dart' show showTeacherDateTimeSheet;
import 'teacher_grading_page.dart' show TeacherGradingPage;
import 'teacher_redesign_prototype_page.dart' show TeacherPalette;
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
  String? courseLabel,
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
      courseLabel: courseLabel,
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

  /// 'คณิตศาสตร์ · ม.1/1 · นักเรียน 3 คน' — ชีตสร้างใบงานเอาไปขึ้นหัว
  /// ครูสอนหลายห้อง ต้องเห็นว่ากำลังสร้างให้วิชาไหนก่อนกรอก
  String? _courseLabel;

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

      _courseLabel = [
        course.subjectName,
        if ((course.room ?? '').trim().isNotEmpty) course.room!.trim(),
        if (totalStudents > 0) 'นักเรียน $totalStudents คน',
      ].join(' · ');

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
            rubricTitle: a.rubricTitle ?? 'ยังไม่ได้กำหนดเกณฑ์ให้คะแนน',
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
      courseLabel: _courseLabel,
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

  /// จำนวนใบงานในแต่ละฟิลเตอร์ — ครูจะได้รู้ว่ามีร่างค้างอยู่กี่ใบโดย
  /// ไม่ต้องกดเข้าไปดู
  int _countFor(String tab) => switch (tab) {
    'เผยแพร่แล้ว' => _assignments.where((a) => a.isPublished).length,
    'ร่าง' => _assignments.where((a) => !a.isPublished).length,
    'งานกลุ่ม' => _assignments.where((a) => a.isGroupWork).length,
    _ => _assignments.length,
  };

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
      builder: (context, isDesktop) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(isDesktop ? 24 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ค้นหาและฟิลเตอร์ไม่ต้องมีการ์ดขาวครอบอีกชั้น — เดิมเป็น
              // กล่องเงาซ้อนอยู่บนพื้นเทา แข่งความเด่นกับการ์ดใบงานที่อยู่
              // ใต้มัน ทั้งที่เป็นแค่เครื่องมือกรอง
              TeacherSearchInput(
                hintText: 'ค้นหาชื่อใบงาน คำสั่ง หรือเซนเซอร์ที่ผูกไว้',
                value: _searchQuery,
                onChanged: (val) => setState(() => _searchQuery = val),
                onClear: () => setState(() => _searchQuery = ''),
              ),
              const SizedBox(height: 10),
              // เลื่อนแนวนอนแทนการตัดบรรทัด — ชิปสี่ตัวตัดลงสองบรรทัดกินที่
              // แนวตั้งไปโดยเปล่าประโยชน์ในหน้าที่เป็นรายการยาว
              SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    for (final tab in const [
                      'ทั้งหมด',
                      'เผยแพร่แล้ว',
                      'ร่าง',
                      'งานกลุ่ม',
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _FilterChip(
                          label: tab,
                          count: _countFor(tab),
                          selected: _selectedTab == tab,
                          onTap: () => setState(() => _selectedTab = tab),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // หัวรายการ — ปุ่มสร้างอยู่ตรงนี้ ไม่ใช่ลอยเดี่ยวกินทั้งแถบ
              // ด้านบนสุด เพราะเป็นสิ่งที่กดนาน ๆ ครั้ง ส่วนที่ครูใช้ทุกวัน
              // คือรายการใบงานที่อยู่ใต้มัน
              Padding(
                padding: const EdgeInsets.fromLTRB(2, 0, 2, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        filtered.isEmpty
                            ? 'ยังไม่มีใบงาน'
                            : 'ใบงาน ${filtered.length} รายการ',
                        style: const TextStyle(
                          fontSize: TeacherType.label,
                          fontWeight: FontWeight.w700,
                          color: AirySpec.label,
                        ),
                      ),
                    ),
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => _openCreateEditForm(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE3E1EB)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add_rounded,
                                size: 16,
                                color: TeacherPalette.primary,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'สร้างใบงานใหม่',
                                style: TextStyle(
                                  fontSize: TeacherType.secondary,
                                  fontWeight: FontWeight.w700,
                                  color: TeacherPalette.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

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
                // รายการเดียวคั่นด้วยเส้นผม ไม่ใช่การ์ดแยกใบพร้อมเงา —
                // การ์ดต่อใบกินพื้นที่แนวตั้งเกือบเท่าตัวโดยไม่ได้ให้ข้อมูล
                // เพิ่ม หน้าที่เป็นรายการยาวควรสแกนได้เร็วก่อนอย่างอื่น
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFEDECF2)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (var i = 0; i < filtered.length; i++) ...[
                        if (i > 0)
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: Color(0xFFF4F3F7),
                          ),
                        _AssignmentRow(
                          assignment: filtered[i],
                          onTapEdit: () => _openCreateEditForm(
                            existingAssignment: filtered[i],
                          ),
                        ),
                      ],
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

/// การ์ดแสดงผลใบงานแต่ละรายการ
/// การ์ดใบงานหนึ่งใบ
///
/// ออกแบบใหม่ 2026-09-22 — ของเดิมมีกรอบซ้อนกันสามชั้น (การ์ดขาว → กล่องเทา
/// ของ meta → กล่องเทาของเซนเซอร์) บวกกล่องไอคอน ชิปชนิดงาน ชิปสถานะ และ
/// ปุ่มทึบสองปุ่ม รวมเป็นสิ่งที่ต้องกวาดตา 8 อย่างต่อหนึ่งใบงาน ทั้งที่ครู
/// มองหาแค่สองอย่าง: ชื่องาน กับ ส่งมากี่คนแล้ว
///
/// โครงใหม่เรียงตามลำดับที่ครูอ่านจริง: ชื่อ → สถานะ → ข้อมูลประกอบบรรทัด
/// เดียว → ความคืบหน้า → ปุ่ม
/// ใบงานหนึ่งแถว
///
/// เปลี่ยนจากการ์ดเป็นแถว 2026-09-22 — การ์ดเดิมสูงเกือบ 200pt ต่อใบ ทั้งที่
/// ข้อมูลที่ครูต้องการต่อหนึ่งใบมีแค่ ชื่อ · สถานะ · กำหนดส่ง · ส่งมากี่คน
/// หน้าจอหนึ่งจอจึงเห็นได้แค่สองใบ
///
/// แถบสีซ้ายบอกสถานะโดยไม่ต้องอ่าน · แตะทั้งแถวไปหน้าตรวจงาน · แก้ไขอยู่ใน
/// เมนู ⋯ เพราะเป็นสิ่งที่ทำนาน ๆ ครั้ง ไม่ควรกินที่เท่าปุ่มหลัก
class _AssignmentRow extends StatelessWidget {
  const _AssignmentRow({required this.assignment, required this.onTapEdit});

  final AssignmentModel assignment;
  final VoidCallback onTapEdit;

  @override
  Widget build(BuildContext context) {
    final isPublished = assignment.isPublished;
    final total = assignment.totalStudents;
    final sent = assignment.submittedCount;
    final ratio = total == 0 ? 0.0 : (sent / total).clamp(0.0, 1.0);
    final accent = isPublished
        ? const Color(0xFF107A50)
        : const Color(0xFFB4650F);

    final meta = <String>[
      assignment.type,
      if (assignment.isGroupWork) 'งานกลุ่ม',
      'ส่ง ${assignment.dueDate}',
      if (assignment.rubricTitle.trim().isNotEmpty) assignment.rubricTitle,
    ].join('  ·  ');

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TeacherGradingPage()),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 13, 8, 13),
          // IntrinsicHeight เพราะแถบสีซ้ายใช้ crossAxisAlignment.stretch
          // ซึ่งต้องการความสูงที่มีขอบเขต — Row ในลิสต์ได้ความสูงไม่จำกัด
          // แล้ว assert เป็น BoxConstraints ไม่ถูกต้อง
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ColoredBox เปล่าใน Row จะสูง 0 ถ้าไม่ stretch — ดู PITFALLS
                SizedBox(
                  width: 3,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        assignment.title,
                        style: const TextStyle(
                          fontSize: TeacherType.body,
                          fontWeight: FontWeight.w800,
                          height: 1.35,
                          color: AirySpec.ink,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        meta,
                        style: const TextStyle(
                          fontSize: TeacherType.label,
                          height: 1.5,
                          color: AirySpec.label,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _MiniPill(
                            text: isPublished ? 'เผยแพร่แล้ว' : 'ร่าง',
                            fg: accent,
                            bg: isPublished
                                ? const Color(0xFFE1F6EC)
                                : const Color(0xFFFDF1DE),
                          ),
                          const SizedBox(width: 10),
                          // แถบความคืบหน้าโผล่เฉพาะเมื่อมีนักเรียนจริง —
                          // เส้นเทาที่ 0/0 อ่านเหมือนเส้นคั่น ไม่ใช่ข้อมูล
                          if (total > 0) ...[
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  value: ratio,
                                  minHeight: 4,
                                  backgroundColor: const Color(0xFFF4F3F7),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        TeacherPalette.primary,
                                      ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$sent/$total',
                              style: const TextStyle(
                                fontSize: TeacherType.caption,
                                fontWeight: FontWeight.w800,
                                color: AirySpec.label,
                              ),
                            ),
                          ] else
                            const Expanded(
                              child: Text(
                                'ยังไม่มีนักเรียนในวิชานี้',
                                style: TextStyle(
                                  fontSize: TeacherType.caption,
                                  color: AirySpec.label,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: PopupMenuButton<String>(
                    tooltip: 'ตัวเลือกใบงาน',
                    icon: const Icon(
                      Icons.more_horiz_rounded,
                      size: 20,
                      color: AirySpec.chevron,
                    ),
                    onSelected: (v) {
                      if (v == 'edit') {
                        onTapEdit();
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TeacherGradingPage(),
                          ),
                        );
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('แก้ไขใบงาน')),
                      PopupMenuItem(value: 'grade', child: Text('ตรวจงาน')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.text, required this.fg, required this.bg});
  final String text;
  final Color fg;
  final Color bg;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: TeacherType.caption,
        fontWeight: FontWeight.w800,
        color: fg,
      ),
    ),
  );
}

/// แปลง DateTime เป็นข้อความที่ช่องกำหนดส่งเก็บไว้ ('yyyy-MM-dd HH:mm')
/// และแปลงกลับ — แยกออกมาเป็นฟังก์ชันเพื่อให้เทสต์ตรวจการไป-กลับได้โดยไม่
/// ต้องผ่าน UI หลังจากที่ช่องกรอกวันที่เปลี่ยนเป็นชีตเลือก (2026-09-22)
/// ทำให้พิมพ์วันที่ผิดรูปแบบผ่านหน้าจอไม่ได้อีก
String formatAssignmentDue(DateTime dt) =>
    '${dt.year.toString().padLeft(4, '0')}-'
    '${dt.month.toString().padLeft(2, '0')}-'
    '${dt.day.toString().padLeft(2, '0')} '
    '${dt.hour.toString().padLeft(2, '0')}:'
    '${dt.minute.toString().padLeft(2, '0')}';

/// คืน null เมื่อข้อความว่างหรือไม่ใช่วันที่จริง
///
/// `DateTime.tryParse('2027-02-31')` **ไม่คืน null** แต่เลื่อนเป็น 3 มี.ค.
/// เงียบ ๆ ครูจะได้กำหนดส่งคนละวันกับที่ตั้งใจโดยไม่มีอะไรเตือน จึงเทียบ
/// ค่าที่ parse ได้กับข้อความต้นทางอีกชั้น
DateTime? parseAssignmentDue(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return null;
  final dt = DateTime.tryParse(t.replaceFirst(' ', 'T'));
  if (dt == null) return null;
  return formatAssignmentDue(dt) == t ? dt : null;
}

/// ป้ายหมวดในชีต — ตัวเล็ก เว้นวรรคกว้าง สีจาง
/// หนึ่งตัวเลือกในชีตเกณฑ์ให้คะแนน
class _RubricOption extends StatelessWidget {
  const _RubricOption({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: selected
                  ? TeacherPalette.primary
                  : const Color(0xFFE6E3EE),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: TeacherType.body,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: AirySpec.ink,
                  ),
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle_rounded,
                  size: 19,
                  color: TeacherPalette.primary,
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _SheetLabel extends StatelessWidget {
  const _SheetLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 18, 2, 8),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: TeacherType.caption,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.9,
        color: AirySpec.chevron,
      ),
    ),
  );
}

/// แถบเลือกประเภทงาน — แทน dropdown ที่ต้องกดสองครั้งกว่าจะเลือกได้
///
/// เลื่อนแนวนอนได้ เพราะใบงานเก่าอาจมีชนิดที่ไม่อยู่ในสามตัวมาตรฐาน
/// (ค่ามาจากฐานข้อมูล ไม่ใช่ enum) ซึ่งต้องไม่หายไปตอนเปิดแก้ไข
class _TypeSegmented extends StatelessWidget {
  const _TypeSegmented({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  /// ชนิดมาตรฐานสามตัว พร้อมไอคอนประจำแต่ละชนิด
  static const _standard = <(String, IconData)>[
    ('ใบงานทดลอง', Icons.science_outlined),
    ('การบ้าน', Icons.description_outlined),
    ('โครงงาน AIoT', Icons.insights_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    // ใบงานเก่าอาจมีชนิดนอกสามตัวนี้ (ค่ามาจากฐานข้อมูล ไม่ใช่ enum)
    // ต้องไม่หายไปตอนเปิดแก้ไข — ต่อท้ายเป็นช่องที่สี่
    final options = <(String, IconData)>[
      ..._standard,
      if (!_standard.any((e) => e.$1 == value)) (value, Icons.label_outline),
    ];

    Widget seg((String, IconData) e) {
      final on = e.$1 == value;
      return Expanded(
        child: Material(
          color: on ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          elevation: on ? 1 : 0,
          shadowColor: const Color(0x22301E4E),
          child: InkWell(
            borderRadius: BorderRadius.circular(9),
            onTap: () => onChanged(e.$1),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    e.$2,
                    size: 14,
                    color: on ? TeacherPalette.primary : AirySpec.label,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      e.$1,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: TeacherType.label,
                        fontWeight: FontWeight.w700,
                        color: on ? TeacherPalette.primary : AirySpec.label,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // รางเดียวพื้นเทา ช่องที่เลือกเป็นการ์ดขาวยกขึ้นมา — แบบเดียวกับ
    // แถบกรองในหน้าตรวจงาน จะได้เป็นภาษาเดียวกันทั้งเลน
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F0F6),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(children: [for (final e in options) seg(e)]),
    );
  }
}

/// ช่องกรอกในชีต — ขอบบาง ไม่มีพื้นเทา ไม่มี label ลอยแบบ Material
class _SheetField extends StatelessWidget {
  const _SheetField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String hint;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(
            fontSize: TeacherType.body,
            color: AirySpec.ink,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontSize: TeacherType.secondary,
              color: AirySpec.chevron,
            ),
            isDense: true,
            filled: false,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 12,
            ),
            border: _border(const Color(0xFFE6E3EE)),
            enabledBorder: _border(const Color(0xFFE6E3EE)),
            focusedBorder: _border(TeacherPalette.primary, width: 1.6),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _border(Color c, {double width = 1}) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: c, width: width),
  );
}

/// แถวที่กดแล้วเปิดตัวเลือก — ไอคอนนำ ค่าอยู่กลาง ลูกศรท้าย
class _SheetPickRow extends StatelessWidget {
  const _SheetPickRow({
    this.rowKey,
    required this.icon,
    required this.value,
    required this.placeholder,
    required this.onTap,
  });

  /// ให้เทสต์อ้างถึงแถวได้โดยไม่ผูกกับข้อความที่เปลี่ยนตามดีไซน์
  final Key? rowKey;
  final IconData icon;
  final String? value;
  final String placeholder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final filled = value != null && value!.trim().isNotEmpty;
    return Material(
      key: rowKey,
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE6E3EE)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 17, color: AirySpec.chevron),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  filled ? value! : placeholder,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: TeacherType.secondary,
                    fontWeight: filled ? FontWeight.w600 : FontWeight.w400,
                    color: filled ? AirySpec.ink : AirySpec.chevron,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AirySpec.chevron,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// แถวสวิตช์ — ป้ายบอกผลลัพธ์ปัจจุบันตรง ๆ ไม่ใช่คำอธิบายยาว
class _SheetSwitchRow extends StatelessWidget {
  const _SheetSwitchRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(12, 4, 8, 4),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE6E3EE)),
    ),
    child: Row(
      children: [
        Icon(icon, size: 17, color: AirySpec.chevron),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: TeacherType.secondary,
              fontWeight: FontWeight.w600,
              color: AirySpec.ink,
            ),
          ),
        ),
        Transform.scale(
          scale: 0.85,
          child: Switch(
            value: value,
            activeThumbColor: Colors.white,
            activeTrackColor: TeacherPalette.primary,
            onChanged: onChanged,
          ),
        ),
      ],
    ),
  );
}

/// แถวที่ยังกดไม่ได้ หรือเป็นข้อมูลอ่านอย่างเดียว
class _SheetLockedRow extends StatelessWidget {
  const _SheetLockedRow({
    required this.icon,
    required this.text,
    this.muted = true,
  });

  final IconData icon;
  final String text;
  final bool muted;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: const Color(0xFFE6E3EE),
        style: muted ? BorderStyle.solid : BorderStyle.solid,
      ),
      color: muted ? const Color(0xFFFAF9FC) : Colors.white,
    ),
    child: Row(
      children: [
        Icon(icon, size: 17, color: AirySpec.chevron),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: TeacherType.secondary,
              height: 1.45,
              color: muted ? AirySpec.chevron : AirySpec.ink,
            ),
          ),
        ),
        if (muted)
          const Icon(
            Icons.lock_outline_rounded,
            size: 15,
            color: AirySpec.chevron,
          ),
      ],
    ),
  );
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? TeacherPalette.primary : Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? TeacherPalette.primary
                  : const Color(0xFFE3E1EB),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: TeacherType.secondary,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AirySpec.label,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: TeacherType.label,
                  fontWeight: FontWeight.w800,
                  color: selected
                      ? Colors.white.withValues(alpha: 0.8)
                      : AirySpec.chevron,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Modal Sheet สำหรับสร้าง/แก้ไขใบงาน
class _AssignmentFormSheet extends StatefulWidget {
  const _AssignmentFormSheet({
    required this.assignment,
    this.courseLabel,
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

  /// 'วิชา · ห้อง · จำนวนนักเรียน' แสดงใต้ชื่อชีต
  final String? courseLabel;
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
        rubricTitle: confirmed.rubricTitle ?? 'ยังไม่ได้กำหนดเกณฑ์ให้คะแนน',
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

  static const _thMonths = [
    'ม.ค.',
    'ก.พ.',
    'มี.ค.',
    'เม.ย.',
    'พ.ค.',
    'มิ.ย.',
    'ก.ค.',
    'ส.ค.',
    'ก.ย.',
    'ต.ค.',
    'พ.ย.',
    'ธ.ค.',
  ];

  /// ข้อความกำหนดส่งแบบไทยที่ครูอ่านออก — ตัว controller ยังเก็บรูปแบบ
  /// 'yyyy-MM-dd HH:mm' เหมือนเดิมเพราะตรรกะบันทึกอ่านจากตรงนั้น
  String? _dueLabel() {
    final raw = _dueDateController.text.trim();
    if (raw.isEmpty) return null;
    final dt = parseAssignmentDue(raw);
    if (dt == null) return raw;
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${_thMonths[dt.month - 1]} ${dt.year + 543} · $hh:$mm น.';
  }

  Future<void> _openDuePicker() async {
    final raw = _dueDateController.text.trim();
    final initial =
        parseAssignmentDue(raw) ?? DateTime.now().add(const Duration(days: 7));
    final picked = await showTeacherDateTimeSheet(
      context: context,
      initial: initial,
      accent: TeacherPalette.primary,
      title: 'กำหนดส่งงาน',
      first: DateTime(2024),
      last: DateTime(2035, 12, 31),
    );
    if (!mounted || picked == null) return;
    setState(() => _dueDateController.text = formatAssignmentDue(picked));
  }

  /// ค่าที่ชีตคืนเมื่อครูเลือก "ไม่ใช้เกณฑ์" — ต้องแยกจาก null ที่แปลว่า
  /// ปิดชีตทิ้ง ไม่งั้นการปัดชีตลงจะไปล้างเกณฑ์ที่ผูกไว้โดยครูไม่ได้สั่ง
  static const _noRubric = '__none__';

  /// ชีตเลือกเกณฑ์ให้คะแนน — แทน dropdown เดิม ให้เป็นภาษาเดียวกับวันที่
  /// และประเภทงานในชีตนี้ และเห็นชื่อเกณฑ์เต็มโดยไม่โดนตัด
  Future<void> _openRubricPicker() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(22, 20, 22, 12),
              child: Text(
                'เกณฑ์ให้คะแนน',
                style: TextStyle(
                  fontSize: TeacherType.title,
                  fontWeight: FontWeight.w800,
                  color: AirySpec.ink,
                ),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  _RubricOption(
                    title: 'ไม่ใช้เกณฑ์ — ให้คะแนนดิบ',
                    selected: _selectedRubricId == null,
                    onTap: () => Navigator.pop(sheetContext, _noRubric),
                  ),
                  for (final r in _rubrics)
                    _RubricOption(
                      title: r.title,
                      selected: _selectedRubricId == r.id,
                      onTap: () => Navigator.pop(sheetContext, r.id),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (!mounted || picked == null) return;
    setState(() => _selectedRubricId = picked == _noRubric ? null : picked);
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
                  // หัวชีต: ไอคอนในกรอบ + ชื่อ + วิชาที่กำลังสร้างให้
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: TeacherPalette.primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(
                          isEditMode ? Icons.edit_outlined : Icons.add_rounded,
                          color: TeacherPalette.primary,
                          size: 19,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEditMode ? 'แก้ไขใบงาน' : 'สร้างใบงานใหม่',
                              style: const TextStyle(
                                fontSize: TeacherType.title,
                                fontWeight: FontWeight.w800,
                                height: 1.3,
                                color: AirySpec.ink,
                              ),
                            ),
                            if (widget.courseLabel != null ||
                                widget.assignment != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  widget.courseLabel ??
                                      widget.assignment!.courseName,
                                  style: const TextStyle(
                                    fontSize: TeacherType.caption,
                                    height: 1.5,
                                    color: AirySpec.label,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // ปุ่มปิดเป็นกรอบ 28x28 แทนไอคอนลอยที่กดยาก
                      Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(9),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(9),
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(
                                color: const Color(0xFFE6E3EE),
                              ),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: AirySpec.chevron,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        const _SheetLabel('ประเภทงาน'),
                        // แถบเลือกแทน dropdown — เห็นทุกตัวเลือกพร้อมกัน
                        // กดครั้งเดียวจบ ไม่ต้องเปิดเมนูแล้วค่อยเลือก
                        _TypeSegmented(
                          value: _type,
                          onChanged: (v) => setState(() => _type = v),
                        ),

                        const _SheetLabel('รายละเอียด'),
                        _SheetField(
                          controller: _titleController,
                          hint: 'ชื่อใบงาน เช่น ใบงานทดลองที่ 3 การวัดค่าฝุ่น',
                        ),
                        const SizedBox(height: 8),
                        _SheetField(
                          controller: _instructionsController,
                          hint: 'คำสั่งงาน — สิ่งที่นักเรียนต้องทำและวิธีส่ง',
                          maxLines: 3,
                        ),

                        const _SheetLabel('กำหนดและเกณฑ์'),
                        // แถวเปิดชีตเลือกวัน-เวลา ไม่ใช่ช่องให้พิมพ์
                        // '2027-01-25 16:30' เอง — ครูไม่ควรต้องจำรูปแบบ
                        // และไม่ควรพิมพ์วันที่ที่ไม่มีอยู่จริงได้
                        _SheetPickRow(
                          rowKey: const Key('assignment-due-field'),
                          icon: Icons.calendar_today_outlined,
                          value: _dueLabel(),
                          placeholder: 'ยังไม่กำหนดวันส่ง',
                          onTap: _openDuePicker,
                        ),
                        const SizedBox(height: 8),
                        if (_rubricsLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
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
                        else
                          _SheetPickRow(
                            icon: Icons.checklist_rounded,
                            value: _selectedRubricId == null
                                ? null
                                : _rubrics
                                      .where((r) => r.id == _selectedRubricId)
                                      .map((r) => r.title)
                                      .firstOrNull,
                            placeholder: 'ยังไม่ได้กำหนดเกณฑ์ให้คะแนน',
                            onTap: _openRubricPicker,
                          ),
                        const SizedBox(height: 8),
                        _SheetSwitchRow(
                          icon: Icons.groups_outlined,
                          label: _isGroupWork
                              ? 'ส่งเป็นกลุ่ม'
                              : 'นักเรียนส่งงานรายคน',
                          value: _isGroupWork,
                          onChanged: (v) => setState(() => _isGroupWork = v),
                        ),
                        const Padding(
                          padding: EdgeInsets.fromLTRB(4, 6, 4, 0),
                          child: Text(
                            'เปิดไว้ = หนึ่งกลุ่มส่งงานหนึ่งชิ้น · '
                            'ปิด = ทุกคนส่งของตัวเอง',
                            style: TextStyle(
                              fontSize: TeacherType.caption,
                              height: 1.5,
                              color: AirySpec.label,
                            ),
                          ),
                        ),

                        const _SheetLabel('ข้อมูลเซนเซอร์'),
                        if (widget.assignment == null)
                          const _SheetLockedRow(
                            icon: Icons.insights_outlined,
                            text: 'ผูกได้หลังบันทึกร่าง',
                          )
                        else if (_sensorDatasetsLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
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
                        else ...[
                          _SheetPickRow(
                            icon: Icons.insights_outlined,
                            value: null,
                            placeholder: 'ผูกชุดข้อมูลเซนเซอร์',
                            onTap: _openLinkSensorDialog,
                          ),
                          for (final d in _sensorDatasets)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: _SheetLockedRow(
                                icon: Icons.sensors_rounded,
                                text:
                                    '${_deviceNames[d.deviceId] ?? d.deviceId}'
                                    ' · ${d.metric}'
                                    '${d.label != null && d.label!.isNotEmpty ? ' — ${d.label}' : ''}',
                                muted: false,
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
                        label: const Text(
                          'บันทึกร่าง',
                          style: TextStyle(
                            fontSize: TeacherType.secondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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
                        label: const Text(
                          'เผยแพร่ให้นักเรียน',
                          style: TextStyle(
                            fontSize: TeacherType.secondary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
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
