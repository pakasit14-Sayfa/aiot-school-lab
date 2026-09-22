// PROTOTYPE: Teacher Assignment Editor & Management Page (ระบบสร้างและจัดการใบงาน)
// Wireframe MVP v1 Section 2.4.1 - 2.4.2
// Allows teachers to manage course assignments, create/edit worksheets/projects,
// toggle group work, attach Rubrics, bind AIoT sensor data streams, and publish assignments.

import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import 'teacher_airy_kit.dart';
import 'teacher_assignment_detail_page.dart' show TeacherAssignmentDetailPage;
import 'teacher_assignment_form_page.dart' show TeacherAssignmentFormPage;
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
  String? _courseId;
  String? _courseName;

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

      _courseId = course.id;
      _courseName = course.subjectName;

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

  /// เปิดหน้าแก้ไขใบงานตัวเดียวกับที่หน้าตรวจงานใช้
  ///
  /// เดิมหน้านี้มีชีตแก้ไขของตัวเอง ทำให้มีหน้าจอแก้ใบงานสองชุดที่หน้าตา
  /// และความสามารถไม่เท่ากัน — ชีตผูกเซนเซอร์ให้ใบงานใหม่ไม่ได้ ไม่มีป้าย
  /// เหนือช่องกรอก และไม่เห็นสถานะ/วันคงเหลือที่หัวหน้า ยุบเหลือชุดเดียว
  /// เมื่อ 2026-09-22
  Future<void> _openCreateEditForm({
    AssignmentModel? existingAssignment,
  }) async {
    final courseId = existingAssignment?.courseId ?? _courseId;
    if (courseId == null) return;
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TeacherAssignmentFormPage(
          courseId: courseId,
          courseName:
              existingAssignment?.courseName ?? _courseName ?? 'รายวิชา',
          existing: existingAssignment == null
              ? null
              : _toSummary(existingAssignment),
          listMyRubrics: widget.listMyRubrics,
          listDevices: widget.listDevices,
          loadAssignmentDetail: widget.loadAssignmentDetail,
          loadAssignmentsForCourse: widget.loadAssignmentsForCourse,
          linkSensorDataset: widget.linkSensorDataset,
          createAssignment: widget.createAssignment,
          updateAssignment: widget.updateAssignment,
          publishAssignment: widget.publishAssignment,
        ),
      ),
    );
    if (saved != true || !mounted) return;
    // ข้อความยืนยันหลังบันทึกเคยอยู่ใน onSave ของชีตที่ถูกลบ — ถ้าไม่ใส่กลับ
    // ครูกดบันทึกแล้วหน้าปิดไปเฉย ๆ ไม่มีอะไรบอกว่าสำเร็จ
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('บันทึกใบงานเรียบร้อยแล้ว')));
    _loadRealAssignments();
  }

  /// เปิดหน้ารายละเอียดของใบงานใบนั้น
  ///
  /// เดิมทั้งการแตะแถวและเมนู 'ตรวจงาน' เรียก `TeacherGradingPage()` เปล่า ๆ
  /// โดยไม่ส่ง id ไปเลย กดจากใบงานไหนก็ไปโผล่หน้าตรวจงานรวมเหมือนกันหมด
  /// ครูต้องมาหาใบงานเดิมซ้ำอีกรอบ
  Future<void> _openDetail(AssignmentModel a) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TeacherAssignmentDetailPage(
          assignment: _toSummary(a),
          courseId: a.courseId,
          courseName: a.courseName,
        ),
      ),
    );
    if (mounted) _loadRealAssignments();
  }

  /// แปลงโมเดลของหน้านี้เป็นชนิดที่หน้าฟอร์มรับ — สองหน้านี้ใช้คนละโมเดล
  /// มาตั้งแต่ต้น การยุบหน้าจอไม่ได้ยุบโมเดล
  AssignmentSummary _toSummary(AssignmentModel a) => AssignmentSummary(
    id: a.id,
    type: a.type,
    title: a.title,
    instructions: a.instructions,
    isGroup: a.isGroupWork,
    dueAt: parseAssignmentDue(a.dueDate),
    status: a.isPublished ? 'published' : 'draft',
    rubricId: a.rubricId,
    rubricTitle: a.rubricTitle,
    submittedCount: a.submittedCount,
    totalStudents: a.totalStudents,
  );

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
                          onTapOpen: () => _openDetail(filtered[i]),
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
  const _AssignmentRow({
    required this.assignment,
    required this.onTapEdit,
    required this.onTapOpen,
  });

  final AssignmentModel assignment;
  final VoidCallback onTapEdit;
  final VoidCallback onTapOpen;

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
        onTap: onTapOpen,
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
