// PROTOTYPE ONLY: Teacher Course Management & Detail Pages
// Displays teacher's courses, lesson plans, worksheets, and course detail view.
// Redesigned with modern glassmorphic aesthetics, rich stat cards, dynamic badges, and progress indicators.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:shared_core/shared_core.dart';

import 'teacher_assignment_editor_page.dart';
import 'teacher_exam_builder_page.dart';
import 'teacher_grading_page.dart';
import 'teacher_incident_inbox_page.dart';
import 'teacher_lesson_editor_page.dart';
import 'teacher_pbl_activity_editor_page.dart';
import 'teacher_redesign_prototype_page.dart' show TeacherPalette;
import 'teacher_shared_widgets.dart';
import 'teacher_students_page.dart';

/// Data model for a course in the teacher prototype
class TeacherCourseModel {
  const TeacherCourseModel({
    this.id,
    required this.code,
    required this.name,
    required this.category,
    required this.rooms,
    required this.studentCount,
    required this.activeAssignments,
    required this.pendingGradingCount,
    required this.completionRate,
    required this.coverGradient,
    required this.accentColor,
    required this.nextPeriodText,
    this.isClosed = false,
    this.hasAccess = true,
  });

  final String? id;
  final String code;
  final String name;
  final String category;
  final List<String> rooms;
  final int studentCount;
  final int activeAssignments;
  final int pendingGradingCount;
  final double completionRate;
  final List<Color> coverGradient;
  final Color accentColor;
  final String nextPeriodText;
  // รายวิชาปิดแล้ว — ดูได้แต่แก้ไข/เผยแพร่ไม่ได้
  final bool isClosed;
  // ครูคนนี้ไม่มีสิทธิ์สอนวิชานี้ (เช่น ถูกถอดออกจากวิชาแล้ว)
  final bool hasAccess;
}

/// CLS-1: real, backend-persisted join code (get_or_create_course_join_code
/// / regenerate_course_join_code), fetched/regenerated on demand — replaces
/// the old client-computed `'${code}-JOIN'` placeholder.
class _JoinCodeDialog extends StatefulWidget {
  const _JoinCodeDialog({
    required this.courseId,
    required this.courseCode,
    required this.courseName,
  });

  final String courseId;
  final String courseCode;
  final String courseName;

  @override
  State<_JoinCodeDialog> createState() => _JoinCodeDialogState();
}

class _JoinCodeDialogState extends State<_JoinCodeDialog> {
  bool _loading = true;
  bool _busy = false;
  String? _code;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final code = await CourseService.getOrCreateJoinCode(widget.courseId);
      if (!mounted) return;
      setState(() {
        _code = code;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading join code: $e');
      if (!mounted) return;
      setState(() {
        _error = 'โหลดรหัสเข้าร่วมไม่สำเร็จ';
        _loading = false;
      });
    }
  }

  Future<void> _regenerate() async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final code = await CourseService.regenerateJoinCode(widget.courseId);
      if (!mounted) return;
      setState(() {
        _code = code;
        _busy = false;
      });
      messenger.showSnackBar(
        const SnackBar(
          content: Text('สร้างรหัสเข้าร่วมใหม่แล้ว (รหัสเดิมใช้ไม่ได้อีกต่อไป)'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('Error regenerating join code: $e');
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(
        const SnackBar(content: Text('สร้างรหัสใหม่ไม่สำเร็จ')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('รหัสเข้าร่วมรายวิชา', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 2),
          Text(
            '${widget.courseCode} · ${widget.courseName}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: TeacherPalette.muted,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 160,
            height: 160,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF1EEF9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: TeacherPalette.border),
            ),
            child: const Icon(
              Icons.qr_code_2_rounded,
              size: 96,
              color: TeacherPalette.primary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _loading
                ? const SizedBox(
                    height: 24,
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                : Text(
                    _error != null ? '—' : (_code ?? '—'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: TeacherPalette.ink,
                    ),
                  ),
          ),
          const SizedBox(height: 10),
          if (_error != null)
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Color(0xFFDC2626)),
            )
          else
            const Text(
              'รหัสนี้ผูกกับรายวิชานี้เท่านั้น กด "สร้างรหัสใหม่" เพื่อยกเลิกรหัสเดิม',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: TeacherPalette.muted),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('ปิด'),
        ),
        OutlinedButton.icon(
          onPressed: (_loading || _busy) ? null : _regenerate,
          icon: _busy
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('สร้างรหัสใหม่'),
        ),
        FilledButton.icon(
          onPressed: (_loading || _code == null)
              ? null
              : () {
                  Clipboard.setData(ClipboardData(text: _code!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('คัดลอกรหัสเข้าร่วมแล้ว'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
          icon: const Icon(Icons.copy_rounded, size: 16),
          label: const Text('คัดลอกรหัส'),
          style: FilledButton.styleFrom(backgroundColor: TeacherPalette.primary),
        ),
      ],
    );
  }
}

// รายวิชาจริงของครูที่ล็อกอินอยู่ โหลดผ่าน CourseService.listMyCourses() ใน
// _loadRealCourses() แล้วเทลงลิสต์ตัวนี้ — เดิมลิสต์นี้ถูก seed ด้วยรายวิชา
// ปลอม 6 ตัว (ว31281 ฯลฯ พร้อมจำนวนนักเรียน/งานค้างตรวจที่แต่งขึ้น) ซึ่ง
// หน้ารายละเอียดวิชายังหยิบไปแสดงได้ผ่าน fallback `?? .first` เริ่มจากว่าง
final List<TeacherCourseModel> teacherCourses = [];

class TeacherCoursesPage extends StatefulWidget {
  const TeacherCoursesPage({
    super.key,
    this.loadCourses,
    this.loadCourseStudents,
  });

  /// Seams for tests: ให้เทสต์พิสูจน์ได้ว่าหน้านี้ไม่มีรายวิชาปลอมค้างอยู่
  /// ทั้งตอนโหลด ตอนโหลดพัง และตอนครูไม่มีรายวิชาจริงเลย
  final Future<List<CourseSummary>> Function()? loadCourses;
  final Future<List<CourseStudent>> Function(String courseId)?
  loadCourseStudents;

  @override
  State<TeacherCoursesPage> createState() => _TeacherCoursesPageState();
}

class _TeacherCoursesPageState extends State<TeacherCoursesPage> {
  String _searchQuery = '';
  String _selectedRoom = 'ทั้งหมด';
  bool _loading = true;
  String? _loadError;

  static const _coverGradients = [
    [Color(0xFF0F766E), Color(0xFF14B8A6)],
    [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
    [Color(0xFF6D28D9), Color(0xFF8B5CF6)],
    [Color(0xFF4338CA), Color(0xFF6366F1)],
    [Color(0xFFC2410C), Color(0xFFF97316)],
  ];
  static const _accentColors = [
    Color(0xFF0D9488),
    Color(0xFF2563EB),
    Color(0xFF7C3AED),
    Color(0xFF4F46E5),
    Color(0xFFEA580C),
  ];

  @override
  void initState() {
    super.initState();
    _loadRealCourses();
  }

  // โหลดรายวิชาจริงของครูที่ login อยู่ตอนเปิดหน้า แล้วเทลง teacherCourses
  // — ยังคงใช้ list ตัวเดิมร่วมกัน (แค่เปลี่ยนเนื้อหา) เพื่อไม่
  // ต้องแตะ logic สร้าง/คัดลอกรายวิชา (CLS-1/CLS-6) ที่ผูกกับ list ตัวนี้
  // อยู่แล้ว — CLS-1 (สร้างรายวิชาใหม่) ยิง CourseService.createCourse จริง
  // แล้ว (ดู _NewCourseModalSheet._submit) แล้วรีโหลดรายการจริงทับของที่สร้าง
  // ในเครื่อง — CLS-6 (คัดลอกรายวิชา) ยังไม่มี RPC รองรับ ยังคงบันทึกแค่ใน
  // เครื่องและ disclose ตรง ๆ ในสี snackbar เตือนว่า "ยังไม่บันทึกลง
  // เซิร์ฟเวอร์" (ดู _openCopyCourseModal)
  Future<void> _loadRealCourses() async {
    try {
      final loadCourses = widget.loadCourses ?? CourseService.listMyCourses;
      final loadStudents =
          widget.loadCourseStudents ?? CourseService.listCourseStudents;
      final courses = await loadCourses();
      final mapped = <TeacherCourseModel>[];
      for (var i = 0; i < courses.length; i++) {
        final c = courses[i];
        var studentCount = 0;
        try {
          studentCount = (await loadStudents(c.id)).length;
        } catch (_) {
          studentCount = 0;
        }
        mapped.add(
          TeacherCourseModel(
            id: c.id,
            code: c.id.length > 8 ? c.id.substring(0, 8) : c.id,
            name: c.subjectName,
            category: c.gradeLevel ?? '-',
            rooms: [if (c.room != null) c.room!],
            studentCount: studentCount,
            activeAssignments: 0,
            pendingGradingCount: 0,
            completionRate: 0,
            coverGradient: _coverGradients[i % _coverGradients.length],
            accentColor: _accentColors[i % _accentColors.length],
            nextPeriodText: c.status == 'published'
                ? 'เผยแพร่แล้ว'
                : 'ฉบับร่าง — ยังไม่เผยแพร่',
          ),
        );
      }
      if (!mounted) return;
      setState(() {
        teacherCourses
          ..clear()
          ..addAll(mapped);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        // ไม่โชว์ข้อความ exception ดิบให้ครูเห็น — log ไว้สำหรับ debug แทน
        debugPrint('teacher_courses_page: listMyCourses failed: $e');
        _loadError = 'โหลดรายวิชาไม่สำเร็จ กรุณาลองใหม่อีกครั้ง';
        _loading = false;
      });
    }
  }

  void _openNewCourseModal() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => _NewCourseModalSheet(
        onCourseCreated: (newCourse) async {
          final messenger = ScaffoldMessenger.of(context);
          await _loadRealCourses();
          if (!mounted) return;
          messenger.showSnackBar(
            SnackBar(
              content: Text('เพิ่ม ${newCourse.name} เรียบร้อยแล้ว'),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
      ),
    );
  }

  // CLS-6: คัดลอกโครงสร้างรายวิชา (บทเรียน/ใบงาน/รูบริก) ไปภาคเรียนใหม่ —
  // BR1: ห้ามคัดลอกรายชื่อนักเรียนและคะแนนเดิมมาด้วยเด็ดขาด
  void _openCopyCourseModal() {
    if (teacherCourses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ยังไม่มีรายวิชาให้คัดลอก — สร้างรายวิชาใหม่ก่อน'),
        ),
      );
      return;
    }
    TeacherCourseModel? sourceCourse = teacherCourses.first;
    String targetSemester = 'ภาคเรียนที่ 2/2569';
    final nameCtrl = TextEditingController(
      text: '${teacherCourses.first.name} (คัดลอก)',
    );
    String? nameError;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Text(
              'คัดลอกรายวิชาจากภาคเรียนก่อน',
              style: TextStyle(fontSize: 16),
            ),
            content: SizedBox(
              width: 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'เลือกรายวิชาต้นทาง',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<TeacherCourseModel>(
                    value: sourceCourse,
                    isExpanded: true,
                    items: teacherCourses
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(
                              '${c.code} · ${c.name}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12.5),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setModalState(() {
                      sourceCourse = v;
                      nameCtrl.text = '${v!.name} (คัดลอก)';
                      nameError = null;
                    }),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'ภาคเรียนปลายทาง',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: targetSemester,
                    items: const [
                      DropdownMenuItem(
                        value: 'ภาคเรียนที่ 2/2569',
                        child: Text(
                          'ภาคเรียนที่ 2/2569',
                          style: TextStyle(fontSize: 12.5),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'ภาคเรียนที่ 1/2570',
                        child: Text(
                          'ภาคเรียนที่ 1/2570',
                          style: TextStyle(fontSize: 12.5),
                        ),
                      ),
                    ],
                    onChanged: (v) => setModalState(() => targetSemester = v!),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'ชื่อรายวิชาใหม่',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameCtrl,
                    onChanged: (_) => setModalState(() => nameError = null),
                    decoration: InputDecoration(
                      errorText: nameError,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'จะคัดลอกโครงสร้างบทเรียน/ใบงาน/Rubric เท่านั้น — ไม่คัดลอก'
                      'รายชื่อนักเรียนหรือคะแนนเดิมมาด้วย',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF1D4ED8),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('ยกเลิก'),
              ),
              FilledButton(
                onPressed: () {
                  final newName = nameCtrl.text.trim();
                  // Exception Flow 1: ชื่อซ้ำในภาคเรียนปลายทาง → ต้องตั้งชื่อใหม่
                  final isDuplicate = teacherCourses.any(
                    (c) => c.name == newName,
                  );
                  if (isDuplicate) {
                    setModalState(
                      () => nameError =
                          'ชื่อนี้ซ้ำกับรายวิชาที่มีอยู่ — ตั้งชื่อใหม่ก่อนบันทึก',
                    );
                    return;
                  }
                  final src = sourceCourse!;
                  final copy = TeacherCourseModel(
                    code: '${src.code}-C',
                    name: newName,
                    category: src.category,
                    rooms: const [],
                    // BR1: ไม่คัดลอกนักเรียน/คะแนน/งานที่ส่งแล้วมาด้วยเด็ดขาด
                    studentCount: 0,
                    activeAssignments: 0,
                    pendingGradingCount: 0,
                    completionRate: 0,
                    coverGradient: src.coverGradient,
                    accentColor: src.accentColor,
                    nextPeriodText: 'ยังไม่กำหนดตาราง — $targetSemester',
                  );
                  setState(() => teacherCourses.insert(0, copy));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'เพิ่ม "$newName" ($targetSemester) ในรายการแล้ว '
                        '(ยังไม่บันทึกลงเซิร์ฟเวอร์ — ฟีเจอร์คัดลอกรายวิชาจริง'
                        'อยู่ระหว่างพัฒนา)',
                      ),
                      backgroundColor: const Color(0xFFD97706),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: TeacherPalette.primary,
                ),
                child: const Text('คัดลอกรายวิชา'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TeacherMockPageShell(
      title: 'จัดการรายวิชาที่สอน',
      activeMenuLabel: 'รายวิชา',
      actions: [
        IconButton(
          icon: const Icon(Icons.copy_all_rounded),
          tooltip: 'คัดลอกรายวิชาจากภาคเรียนก่อน',
          onPressed: _openCopyCourseModal,
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline_rounded),
          tooltip: 'สร้างรายวิชาใหม่',
          onPressed: _openNewCourseModal,
        ),
      ],
      builder: (context, isDesktop) {
        if (_loading) {
          return const Padding(
            padding: EdgeInsets.all(48),
            child: Center(
              child: CircularProgressIndicator(color: TeacherPalette.primary),
            ),
          );
        }
        if (_loadError != null) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _loadError!,
                  style: const TextStyle(
                    color: Color(0xFFDC2626),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _loading = true;
                      _loadError = null;
                    });
                    _loadRealCourses();
                  },
                  child: const Text('ลองใหม่'),
                ),
              ],
            ),
          );
        }
        final filteredCourses = teacherCourses.where((c) {
          final matchesSearch =
              c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              c.code.toLowerCase().contains(_searchQuery.toLowerCase());
          final matchesRoom =
              _selectedRoom == 'ทั้งหมด' || c.rooms.contains(_selectedRoom);
          return matchesSearch && matchesRoom;
        }).toList();

        final totalStudents = teacherCourses.fold<int>(
          0,
          (sum, c) => sum + c.studentCount,
        );
        final totalPendingGrading = teacherCourses.fold<int>(
          0,
          (sum, c) => sum + c.pendingGradingCount,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🌟 1. HERO HEADER CARD
            _buildHeroHeader(
              context,
              totalCourses: teacherCourses.length,
              totalStudents: totalStudents,
            ),
            const SizedBox(height: 20),

            // 📊 2. STATS OVERVIEW CARDS
            _buildStatsGrid(
              context: context,
              totalCourses: teacherCourses.length,
              totalStudents: totalStudents,
              totalPendingGrading: totalPendingGrading,
              isDesktop: isDesktop,
            ),
            const SizedBox(height: 22),

            // 🔍 3. SEARCH & FILTERS CONTAINER
            _buildSearchAndFilters(context),
            const SizedBox(height: 22),

            // 📚 4. COURSES LIST HEADER & ITEMS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.menu_book_rounded,
                      color: TeacherPalette.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'รายวิชาของคุณ (${filteredCourses.length})',
                      style: const TextStyle(
                        color: TeacherPalette.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () =>
                      showTeacherMockAction(context, 'จัดเรียงรายวิชา'),
                  icon: const Icon(
                    Icons.swap_vert_rounded,
                    size: 18,
                    color: TeacherPalette.muted,
                  ),
                  label: const Text(
                    'จัดเรียง',
                    style: TextStyle(
                      color: TeacherPalette.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (filteredCourses.isEmpty)
              _buildEmptySearchResult()
            else
              Column(
                children: [
                  for (int i = 0; i < filteredCourses.length; i++) ...[
                    _TeacherCourseCard(
                      course: filteredCourses[i],
                      onChanged: _loadRealCourses,
                    ),
                    if (i < filteredCourses.length - 1)
                      const SizedBox(height: 18),
                  ],
                ],
              ),
          ],
        );
      },
    );
  }

  /// Hero Banner Top Header
  Widget _buildHeroHeader(
    BuildContext context, {
    required int totalCourses,
    required int totalStudents,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF35204E), Color(0xFF542E85), Color(0xFF7448A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26542E85),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.stars_rounded,
                          color: Color(0xFFFFD700),
                          size: 14,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'ภาคเรียนที่ 1 / 2569',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.more_horiz_rounded,
                      color: Colors.white70,
                    ),
                    onPressed: () =>
                        showTeacherMockAction(context, 'ตัวเลือกเพิ่มเติม'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'จัดการรายวิชาที่สอน 📖',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'ดูแลแผนการสอน สื่อการเรียนรู้ ตรวจงาน และติดตามพัฒนาการนักเรียนรวม $totalStudents คน จาก $totalCourses รายวิชา',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.88),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ElevatedButton.icon(
                    onPressed: _openNewCourseModal,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text(
                      'เพิ่มรายวิชาใหม่',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF35204E),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 11,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TeacherGradingPage(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.fact_check_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'ไปยังศูนย์ตรวจงาน',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.4),
                        width: 1.2,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 11,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TeacherIncidentInboxPage(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.emergency_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'รับแจ้งเหตุฉุกเฉิน',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.4),
                        width: 1.2,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 11,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Stat cards layout
  Widget _buildStatsGrid({
    required BuildContext context,
    required int totalCourses,
    required int totalStudents,
    required int totalPendingGrading,
    required bool isDesktop,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 640;
        final cards = [
          _StatTile(
            title: 'รายวิชาทั้งหมด',
            value: '$totalCourses วิชา',
            subtitle: '3 กลุ่มเรียนหลัก',
            icon: Icons.menu_book_rounded,
            gradientColors: const [Color(0xFF0F766E), Color(0xFF14B8A6)],
          ),
          _StatTile(
            title: 'นักเรียนรวม',
            value: '$totalStudents คน',
            subtitle: 'อัตราเข้าเรียน 98.4%',
            icon: Icons.groups_rounded,
            gradientColors: const [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
          ),
          _StatTile(
            title: 'งานรอตรวจ',
            value: '$totalPendingGrading รายการ',
            subtitle: 'ต้องการการตอบกลับ',
            icon: Icons.assignment_late_rounded,
            gradientColors: const [Color(0xFFD97706), Color(0xFFF59E0B)],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TeacherGradingPage()),
              );
            },
          ),
          _StatTile(
            title: 'ความคืบหน้าสอน',
            value: '87%',
            subtitle: 'ตามแผนการสอน',
            icon: Icons.trending_up_rounded,
            gradientColors: const [Color(0xFF6D28D9), Color(0xFF8B5CF6)],
          ),
        ];

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < cards.length; i++) ...[
                Expanded(child: cards[i]),
                if (i < cards.length - 1) const SizedBox(width: 10),
              ],
            ],
          );
        }

        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.5,
          children: cards,
        );
      },
    );
  }

  /// Search input & filtering bar
  Widget _buildSearchAndFilters(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TeacherPalette.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          TeacherSearchInput(
            hintText: 'ค้นหาด้วยชื่อวิชา รหัสวิชา หรือกลุ่มสาระ...',
            value: _searchQuery,
            onChanged: (val) => setState(() => _searchQuery = val),
            onClear: () => setState(() => _searchQuery = ''),
          ),
          const SizedBox(height: 14),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'กรองตามห้องเรียน:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: TeacherPalette.muted,
                ),
              ),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children:
                      [
                        'ทั้งหมด',
                        'ม.4/1',
                        'ม.4/2',
                        'ม.5/2',
                        'ม.6/1',
                        'ม.6/3',
                      ].map((room) {
                        final isActive = _selectedRoom == room;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(room),
                            selected: isActive,
                            selectedColor: TeacherPalette.primary,
                            backgroundColor: const Color(0xFFF1F5F9),
                            checkmarkColor: Colors.white,
                            labelStyle: TextStyle(
                              color: isActive
                                  ? Colors.white
                                  : TeacherPalette.ink,
                              fontWeight: isActive
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              fontSize: 12,
                            ),
                            onSelected: (_) =>
                                setState(() => _selectedRoom = room),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: isActive
                                    ? TeacherPalette.primary
                                    : Colors.transparent,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySearchResult() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TeacherPalette.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 48,
            color: TeacherPalette.muted.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          const Text(
            'ไม่พบรายวิชาที่ตรงกับการค้นหา',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: TeacherPalette.ink,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'ลองเปลี่ยนคำค้นหา หรือรีเซ็ตตัวกรองห้องเรียน',
            style: TextStyle(fontSize: 13, color: TeacherPalette.muted),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _selectedRoom = 'ทั้งหมด';
              });
            },
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('รีเซ็ตการค้นหา'),
            style: ElevatedButton.styleFrom(
              backgroundColor: TeacherPalette.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 🎨 NEW MODERN CREATE COURSE MODAL SHEET
class _NewCourseModalSheet extends StatefulWidget {
  const _NewCourseModalSheet({required this.onCourseCreated});

  final void Function(TeacherCourseModel course) onCourseCreated;

  @override
  State<_NewCourseModalSheet> createState() => _NewCourseModalSheetState();
}

class _NewCourseModalSheetState extends State<_NewCourseModalSheet> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController(text: 'ว31284');
  final _nameController = TextEditingController(
    text: 'ปัญญาประดิษฐ์ & วิทยาการข้อมูล',
  );
  final _nextPeriodController = TextEditingController(
    text: 'จันทร์ คาบ 1-2 (ห้อง Lab AI)',
  );

  String _selectedCategory = 'เทคโนโลยี';
  int _selectedColorIndex = 0;
  final Set<String> _selectedRooms = {'ม.4/1'};

  final List<Map<String, dynamic>> _coverGradients = [
    {
      'label': 'Teal Mint',
      'colors': [const Color(0xFF0F766E), const Color(0xFF14B8A6)],
      'accent': const Color(0xFF0D9488),
    },
    {
      'label': 'Royal Blue',
      'colors': [const Color(0xFF1D4ED8), const Color(0xFF3B82F6)],
      'accent': const Color(0xFF2563EB),
    },
    {
      'label': 'Vivid Purple',
      'colors': [const Color(0xFF6D28D9), const Color(0xFF8B5CF6)],
      'accent': const Color(0xFF7C3AED),
    },
    {
      'label': 'Crimson Red',
      'colors': [const Color(0xFFBE123C), const Color(0xFFFB7185)],
      'accent': const Color(0xFFE11D48),
    },
    {
      'label': 'Amber Orange',
      'colors': [const Color(0xFFC2410C), const Color(0xFFF97316)],
      'accent': const Color(0xFFEA580C),
    },
  ];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRooms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกห้องเรียนอย่างน้อย 1 ห้อง')),
      );
      return;
    }

    try {
      final terms = await CourseService.listTerms();
      if (terms.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ไม่พบภาคเรียนในระบบ กรุณาติดต่อผู้ดูแลระบบ'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
        return;
      }

      await CourseService.createCourse(
        termId: terms.first.id,
        subjectName: _nameController.text.trim(),
        gradeLevel: _selectedCategory,
        room: _selectedRooms.join(','),
        description: _nextPeriodController.text.trim(),
      );
    } catch (e) {
      debugPrint('Error creating course in Supabase: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('สร้างรายวิชาไม่สำเร็จ'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    final chosenGradient = _coverGradients[_selectedColorIndex];
    final newCourse = TeacherCourseModel(
      code: _codeController.text.trim(),
      name: _nameController.text.trim(),
      category: _selectedCategory,
      rooms: _selectedRooms.toList()..sort(),
      studentCount: 40,
      activeAssignments: 1,
      pendingGradingCount: 0,
      completionRate: 0.10,
      coverGradient: chosenGradient['colors'] as List<Color>,
      accentColor: chosenGradient['accent'] as Color,
      nextPeriodText: _nextPeriodController.text.trim(),
    );

    widget.onCourseCreated(newCourse);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Handle Indicator
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Header Banner
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF35204E),
                    Color(0xFF542E85),
                    Color(0xFF7448A6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add_to_photos_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'สร้างรายวิชาใหม่ 📖',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'ออกแบบคลาสเรียน เลือกกลุ่มสาระ และกำหนดห้องเรียน',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Form Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Code & Name
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 110,
                          child: TextFormField(
                            controller: _codeController,
                            decoration: InputDecoration(
                              labelText: 'รหัสวิชา',
                              labelStyle: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                              hintText: 'ว31284',
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'ระบุรหัส' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'ชื่อรายวิชา',
                              labelStyle: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                              hintText: 'เช่น ปัญญาประดิษฐ์เบื้องต้น',
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'ระบุชื่อวิชา' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Category Selector
                    const Text(
                      'กลุ่มสาระการเรียนรู้:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: TeacherPalette.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children:
                            [
                              'เทคโนโลยี',
                              'วิทยาศาสตร์',
                              'ฟิสิกส์',
                              'คณิตศาสตร์',
                              'ทั่วไป',
                            ].map((cat) {
                              final isSelected = _selectedCategory == cat;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(cat),
                                  selected: isSelected,
                                  selectedColor: TeacherPalette.primary,
                                  backgroundColor: const Color(0xFFF1F5F9),
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : TeacherPalette.ink,
                                    fontWeight: isSelected
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                  onSelected: (_) =>
                                      setState(() => _selectedCategory = cat),
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Cover Theme Color Picker
                    const Text(
                      'ธีมสีการ์ดวิชา:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: TeacherPalette.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(_coverGradients.length, (idx) {
                        final item = _coverGradients[idx];
                        final colors = item['colors'] as List<Color>;
                        final isSelected = _selectedColorIndex == idx;

                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedColorIndex = idx),
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(colors: colors),
                              border: Border.all(
                                color: isSelected
                                    ? TeacherPalette.ink
                                    : Colors.transparent,
                                width: isSelected ? 3 : 0,
                              ),
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 4),
                              ],
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 18,
                                  )
                                : null,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),

                    // Room Selector
                    const Text(
                      'เลือกห้องเรียนที่สอน:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: TeacherPalette.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children:
                          [
                            'ม.4/1',
                            'ม.4/2',
                            'ม.5/1',
                            'ม.5/2',
                            'ม.6/1',
                            'ม.6/3',
                          ].map((room) {
                            final isSelected = _selectedRooms.contains(room);
                            return FilterChip(
                              label: Text(room),
                              selected: isSelected,
                              selectedColor: TeacherPalette.primary,
                              backgroundColor: const Color(0xFFF1F5F9),
                              checkmarkColor: Colors.white,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : TeacherPalette.ink,
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                fontSize: 12,
                              ),
                              onSelected: (val) {
                                setState(() {
                                  if (val) {
                                    _selectedRooms.add(room);
                                  } else {
                                    if (_selectedRooms.length > 1) {
                                      _selectedRooms.remove(room);
                                    }
                                  }
                                });
                              },
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Next Period
                    TextFormField(
                      controller: _nextPeriodController,
                      decoration: InputDecoration(
                        labelText: 'ตาราง/คาบเรียนถัดไป',
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                        hintText: 'เช่น อังคาร คาบ 2-3 (ห้อง 421)',
                        prefixIcon: const Icon(
                          Icons.schedule_rounded,
                          color: TeacherPalette.muted,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'ยกเลิก',
                              style: TextStyle(
                                color: TeacherPalette.muted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _submit,
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: const Text(
                              'สร้างรายวิชา',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: TeacherPalette.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Single Stat Tile Widget
class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    this.onTap,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: TeacherPalette.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x060F172A),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradientColors),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: TeacherPalette.muted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: TeacherPalette.ink,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: gradientColors.first,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Course Card Widget
class _TeacherCourseCard extends StatelessWidget {
  const _TeacherCourseCard({required this.course, this.onChanged});

  final TeacherCourseModel course;
  final VoidCallback? onChanged;

  void _openCreateWorksheetSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'สร้างสื่อ / งานใหม่ในวิชา ${course.code}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: TeacherPalette.ink,
              ),
            ),
            Text(
              course.name,
              style: const TextStyle(fontSize: 13, color: TeacherPalette.muted),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: TeacherPalette.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.assignment_add,
                  color: TeacherPalette.primary,
                ),
              ),
              title: const Text(
                'สร้างใบงานดิจิทัล (Worksheet)',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: const Text(
                'มอบหมายงาน แบบฝึกหัด หรือการบ้านให้นักเรียน',
              ),
              onTap: () {
                Navigator.pop(context);
                showTeacherMockAction(context, 'สร้างใบงานดิจิทัลใหม่');
              },
            ),
            const Divider(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.quiz_outlined,
                  color: Color(0xFF2563EB),
                ),
              ),
              title: const Text(
                'สร้างคลังข้อสอบ (Exam Builder)',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: const Text(
                'จัดทำข้อสอบปรนัย/อัตนัย พร้อมระบบตรวจอัตโนมัติ',
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TeacherExamBuilderPage(
                      courseId: course.id,
                      courseCode: course.code,
                      courseName: course.name,
                    ),
                  ),
                );
              },
            ),
            const Divider(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.upload_file_rounded,
                  color: Color(0xFF059669),
                ),
              ),
              title: const Text(
                'แนบสไลด์ / สื่อการสอน (Slide & PDF)',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: const Text(
                'อัปโหลดไฟล์สไลด์ วิดีโอ หรือลิงก์การเรียนรู้',
              ),
              onTap: () {
                Navigator.pop(context);
                showTeacherMockAction(context, 'อัปโหลดสื่อการสอน');
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: TeacherPalette.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🎨 COURSE CARD GRADIENT BANNER
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: course.coverGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      course.code,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      course.category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    onPressed: () {
                      Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              TeacherCourseDetailPage(course: course),
                        ),
                      ).then((changed) {
                        if (changed == true) onChanged?.call();
                      });
                    },
                  ),
                ],
              ),
            ),

            // 📄 CARD CONTENT BODY
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  InkWell(
                    onTap: () {
                      Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              TeacherCourseDetailPage(course: course),
                        ),
                      ).then((changed) {
                        if (changed == true) onChanged?.call();
                      });
                    },
                    child: Text(
                      course.name,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: TeacherPalette.ink,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Info chips (Next period & rooms)
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 15,
                        color: TeacherPalette.muted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'คาบถัดไป: ${course.nextPeriodText}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: TeacherPalette.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      const Icon(
                        Icons.meeting_room_rounded,
                        size: 15,
                        color: TeacherPalette.muted,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'ห้องเรียน: ',
                        style: TextStyle(
                          fontSize: 12,
                          color: TeacherPalette.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: course.rooms.map((r) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                r,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: TeacherPalette.ink,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.person_outline_rounded,
                        size: 15,
                        color: TeacherPalette.muted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${course.studentCount} คน',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: TeacherPalette.ink,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Progress Bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'ความคืบหน้าหลักสูตร',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: TeacherPalette.muted,
                            ),
                          ),
                          Text(
                            '${(course.completionRate * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: course.accentColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: course.completionRate,
                          backgroundColor: const Color(0xFFE2E8F0),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            course.accentColor,
                          ),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Action Buttons Responsive Wrap
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('สร้างงาน / สื่อ'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TeacherPalette.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () => _openCreateWorksheetSheet(context),
                      ),
                      if (course.pendingGradingCount > 0)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.fact_check_rounded, size: 16),
                          label: Text(
                            'ตรวจงาน (${course.pendingGradingCount})',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFF7ED),
                            foregroundColor: const Color(0xFFC2410C),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            elevation: 0,
                            side: const BorderSide(
                              color: Color(0xFFFFEDD5),
                              width: 1.2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TeacherGradingPage(),
                              ),
                            );
                          },
                        ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.groups_rounded, size: 18),
                        label: const Text('นักเรียน'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: TeacherPalette.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          side: const BorderSide(
                            color: TeacherPalette.border,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TeacherStudentsPage(
                                initialRoomFilter: course.rooms,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Redesigned Course Detail Page
class TeacherCourseDetailPage extends StatefulWidget {
  const TeacherCourseDetailPage({super.key, this.course});

  final TeacherCourseModel? course;

  @override
  State<TeacherCourseDetailPage> createState() =>
      _TeacherCourseDetailPageState();
}

class _TeacherCourseDetailPageState extends State<TeacherCourseDetailPage> {
  String _activeTab = 'บทเรียน';
  int? _dynamicStudentCount;

  @override
  void initState() {
    super.initState();
    _refreshStudentCount();
  }

  Future<void> _refreshStudentCount() async {
    final courseId = widget.course?.id ?? widget.course?.code;
    if (courseId == null) return;
    try {
      final list = await CourseService.listCourseStudents(courseId);
      if (mounted) {
        setState(() {
          _dynamicStudentCount = list.length;
        });
      }
    } catch (e) {
      // ตัวเลขเดิมค้างไว้ (ไม่ใช่ข้อมูลปลอม) แต่ต้องมีร่องรอยใน log
      debugPrint('TeacherCourseCard: นับนักเรียนไม่สำเร็จ — $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // เดิม fallback เป็น `teacherCourses.first` ซึ่งตอนที่ลิสต์ยัง seed ด้วย
    // รายวิชาปลอมอยู่ แปลว่าเปิดหน้านี้โดยไม่มีวิชาจริงจะได้หน้ารายละเอียด
    // ของวิชาปลอมเต็มหน้า ตอนนี้บอกตรง ๆ ว่าไม่มีวิชาให้แสดง
    final c = widget.course;
    if (c == null) {
      return TeacherMockPageShell(
        title: 'รายละเอียดวิชา',
        activeMenuLabel: 'รายวิชา',
        builder: (context, isDesktop) => const Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text(
              'ยังไม่มีข้อมูลรายวิชา — กรุณาเปิดจากรายการรายวิชาของคุณ',
              textAlign: TextAlign.center,
              style: TextStyle(color: TeacherPalette.muted),
            ),
          ),
        ),
      );
    }

    return TeacherMockPageShell(
      title: 'รายละเอียดวิชา ${c.name.isNotEmpty ? c.name : c.code}',
      activeMenuLabel: 'รายวิชา',
      actions: [
        OutlinedButton.icon(
          onPressed: () => _openJoinCodeModal(context, c),
          icon: const Icon(Icons.qr_code_2_rounded, size: 16),
          label: const Text('รหัสเข้าร่วม'),
          style: OutlinedButton.styleFrom(
            foregroundColor: TeacherPalette.primary,
            side: const BorderSide(color: TeacherPalette.primary),
            minimumSize: const Size(0, 40),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: () => _openGroupManagementModal(context, c),
          icon: const Icon(Icons.groups_rounded, size: 16),
          label: const Text('จัดการกลุ่มนักเรียน'),
          style: ElevatedButton.styleFrom(
            backgroundColor: TeacherPalette.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 40),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 0,
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: () => _handleCloseCourse(context, c),
          icon: const Icon(Icons.lock_reset_rounded, size: 16),
          label: const Text('ปิดรายวิชา'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFDC2626),
            side: const BorderSide(color: Color(0xFFFECACA)),
            minimumSize: const Size(0, 40),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
      builder: (context, isDesktop) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Course Detail Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: c.coverGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x200F172A),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          c.code,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          c.category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    c.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                    ),
                  ),
                  Builder(
                    builder: (context) {
                      final studentCount =
                          _dynamicStudentCount ?? c.studentCount;
                      return Text(
                        'ห้องเรียน: ${c.rooms.join(', ')} • นักเรียนรวม $studentCount คน • ${c.nextPeriodText}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 18),

                  // Progress overview
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'ความคืบหน้าการสอน ${(c.completionRate * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: c.completionRate,
                          backgroundColor: Colors.white.withValues(alpha: 0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Navigation Tabs Bar (PRD Spec 1: นักเรียน / บทเรียน / ใบงาน / แบบทดสอบ / กลุ่ม / คะแนน)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children:
                    [
                      'นักเรียน',
                      'บทเรียน',
                      'ใบงาน',
                      'แบบทดสอบ',
                      'กลุ่ม',
                      'คะแนน',
                    ].map((tab) {
                      final isActive = _activeTab == tab;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: InkWell(
                          onTap: () => setState(() => _activeTab = tab),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? TeacherPalette.primary
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isActive
                                    ? TeacherPalette.primary
                                    : TeacherPalette.border,
                              ),
                            ),
                            child: Text(
                              tab,
                              style: TextStyle(
                                color: isActive
                                    ? Colors.white
                                    : TeacherPalette.ink,
                                fontWeight: isActive
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
            const SizedBox(height: 18),

            // Tab Content Display
            if (_activeTab == 'บทเรียน')
              TeacherLessonListPage(
                courseId: c.id,
                courseCode: c.code,
                courseName: c.name,
                isCourseClosed: c.isClosed,
                hasAccess: c.hasAccess,
              )
            else if (_activeTab == 'นักเรียน')
              TeacherStudentRosterTab(course: c)
            else if (_activeTab == 'ใบงาน')
              _CourseAssignmentListTabWidget(course: c)
            else if (_activeTab == 'คะแนน')
              _CourseGradebookTabWidget(course: c)
            else if (_activeTab == 'กลุ่ม')
              _StudentGroupManagementWidget(course: c)
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: TeacherPalette.border),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.widgets_outlined,
                      size: 48,
                      color: TeacherPalette.muted.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'หน้า $_activeTab วิชา ${c.code}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ข้อมูลและเครื่องมือสำหรับแถบ $_activeTab พร้อมใช้งาน',
                      style: const TextStyle(
                        fontSize: 13,
                        color: TeacherPalette.muted,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  // CLS-1 Main Flow ข้อ 4-5: หลังสร้างรายวิชาแล้วมีรหัสเข้าร่วม/QR ให้ครู
  // เผยแพร่ให้นักเรียนเข้าร่วม — BR1: รหัสผูกกับรายวิชานี้เท่านั้น
  void _openJoinCodeModal(BuildContext context, TeacherCourseModel course) {
    final courseId = course.id;
    if (courseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่พบรหัสรายวิชา ไม่สามารถออกรหัสเข้าร่วมได้')),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => _JoinCodeDialog(
        courseId: courseId,
        courseCode: course.code,
        courseName: course.name,
      ),
    );
  }

  void _openGroupManagementModal(
    BuildContext context,
    TeacherCourseModel course,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (ctx, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: scrollController,
            children: [_StudentGroupManagementWidget(course: course)],
          ),
        ),
      ),
    );
  }

  void _handleCloseCourse(BuildContext context, TeacherCourseModel course) {
    // Mock simulation: check if there are pending gradings or COI review pending
    final bool hasPendingCoiReview = course.pendingGradingCount > 0;

    if (hasPendingCoiReview) {
      // CLS-8 Exception Flow: มีงานที่ยังไม่ตรวจ/คะแนนยังไม่ยืนยัน → เตือนก่อนปิด
      // ให้ครูเลือกได้ว่าจะ "ดำเนินการต่อ" (กลับไปตรวจงานก่อน) หรือ
      // "ปิดโดยรับทราบความเสี่ยง" — ไม่ใช่การบล็อกเด็ดขาดแบบเดิม
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFDC2626),
                size: 24,
              ),
              SizedBox(width: 10),
              Text(
                'รายวิชานี้ยังมีภารกิจค้างอยู่',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: Color(0xFFDC2626),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'รายวิชา ${course.code} (${course.name}) ยังมีภารกิจค้างอยู่:',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• มีใบงานรอตรวจค้างอยู่: ${course.pendingGradingCount} รายการ',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFDC2626),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '• มีสถานะคะแนนรออนุมัติ COI (coi_review_status = pending) ค้างอยู่',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFDC2626),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'แนะนำให้ตรวจงานและอนุมัติคะแนนให้เสร็จก่อนปิดรายวิชา แต่ถ้าจำเป็น '
                'สามารถปิดรายวิชาโดยรับทราบความเสี่ยงได้ — งานค้างเหล่านี้จะแก้ไข/'
                'ตรวจต่อไม่ได้อีกหลังปิด',
                style: TextStyle(fontSize: 12, color: TeacherPalette.muted),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('กลับไปตรวจงานก่อน'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _confirmCloseCourseWithRisk(context, course);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              child: const Text('ปิดโดยรับทราบความเสี่ยง'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFEA580C),
                size: 24,
              ),
              SizedBox(width: 10),
              Text(
                'ยืนยันการปิดรายวิชา',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ],
          ),
          content: Text(
            'เมื่อปิดรายวิชา ${course.code} แล้วจะไม่สามารถแก้ไขคะแนน แก้ไขใบงาน หรือเพิ่มนักเรียนย้อนหลังได้อีก คุณต้องการปิดวิชานี้ใช่หรือไม่?',
            style: const TextStyle(fontSize: 13, color: TeacherPalette.muted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _closeCourseReal(context, course);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              child: const Text('ยืนยันปิดรายวิชา'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _closeCourseReal(
    BuildContext context,
    TeacherCourseModel course,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    if (course.id == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('ไม่พบรหัสรายวิชา ไม่สามารถปิดรายวิชาได้'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }
    try {
      await CourseService.closeCourse(course.id!);
      messenger.showSnackBar(
        SnackBar(
          content: Text('ปิดรายวิชา ${course.code} เรียบร้อยแล้ว'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
      if (context.mounted) Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint('Error closing course: $e');
      messenger.showSnackBar(
        const SnackBar(
          content: Text('ปิดรายวิชาไม่สำเร็จ'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
    }
  }

  /// ยืนยันขั้นสุดท้ายก่อนปิดรายวิชาทั้งที่ยังมีงานค้าง (CLS-8 Exception Flow)
  void _confirmCloseCourseWithRisk(
    BuildContext context,
    TeacherCourseModel course,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFEA580C),
              size: 24,
            ),
            SizedBox(width: 10),
            Text(
              'ยืนยันปิดรายวิชาโดยรับทราบความเสี่ยง',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
            ),
          ],
        ),
        content: Text(
          'รายวิชา ${course.code} จะถูกล็อกเป็น read-only ทันที '
          'งานที่ยังไม่ตรวจและคะแนนที่ยังไม่ยืนยัน COI จะค้างอยู่แบบนั้นถาวร '
          'แก้ไขหรือตรวจต่อไม่ได้อีก ยืนยันหรือไม่?',
          style: const TextStyle(fontSize: 13, color: TeacherPalette.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _closeCourseWithRiskReal(context, course);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text('ยืนยันปิดรายวิชา'),
          ),
        ],
      ),
    );
  }

  Future<void> _closeCourseWithRiskReal(
    BuildContext context,
    TeacherCourseModel course,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    if (course.id == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('ไม่พบรหัสรายวิชา ไม่สามารถปิดรายวิชาได้'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }
    try {
      await CourseService.closeCourse(course.id!);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'ปิดรายวิชา ${course.code} เรียบร้อยแล้ว (รับทราบความเสี่ยงจากงานค้าง)',
          ),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
      if (context.mounted) Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint('Error closing course with pending work: $e');
      messenger.showSnackBar(
        const SnackBar(
          content: Text('ปิดรายวิชาไม่สำเร็จ'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
    }
  }
}

/// Widget สำหรับจัดการกลุ่มนักเรียนในวิชา (Student Group Management)
class _StudentGroupManagementWidget extends StatefulWidget {
  const _StudentGroupManagementWidget({required this.course});

  final TeacherCourseModel course;

  @override
  State<_StudentGroupManagementWidget> createState() =>
      __StudentGroupManagementWidgetState();
}

class __StudentGroupManagementWidgetState
    extends State<_StudentGroupManagementWidget> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _groups = [];
  List<String> _availableStudents = [];
  final Map<String, String> _studentNameToId = {};

  @override
  void initState() {
    super.initState();
    _fetchRealDataFromSupabase();
  }

  Future<void> _fetchRealDataFromSupabase() async {
    setState(() => _isLoading = true);
    try {
      final courseId = widget.course.id ?? '';

      // 1. Fetch real enrolled students via SECURITY DEFINER RPC
      final enrolledStudents = await CourseService.listCourseStudents(courseId);

      _studentNameToId.clear();
      final List<String> fetchedStudents = [];
      for (final st in enrolledStudents) {
        final displayName = '${st.fullName} (${st.email.split('@').first})';
        _studentNameToId[displayName] = st.studentId;
        _studentNameToId[st.fullName] = st.studentId;
        fetchedStudents.add(displayName);
      }

      // 2. Fetch real student groups via SECURITY DEFINER RPC
      final groupsRes = await StudentGroupService.listStudentGroups(courseId);

      final List<Map<String, dynamic>> fetchedGroups = [];
      for (final g in groupsRes) {
        final membersList = g.members.map((m) => m.fullName).toList();
        final rawMembers = g.members
            .map((m) => {'id': m.studentId, 'name': m.fullName})
            .toList();

        for (final mName in membersList) {
          fetchedStudents.removeWhere((st) => st.contains(mName));
        }
        fetchedGroups.add({
          'id': g.id,
          'name': g.name,
          'members': membersList,
          'rawMembers': rawMembers,
        });
      }

      if (mounted) {
        setState(() {
          _availableStudents = fetchedStudents;
          _groups = fetchedGroups;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching real student groups via RPC: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addGroup() async {
    final defaultName = 'กลุ่ม ${_groups.length + 1}: โครงงานใหม่';
    final courseId = widget.course.id ?? '';
    try {
      final newGroupId = await StudentGroupService.createStudentGroup(
        courseId: courseId,
        name: defaultName,
      );
      await _fetchRealDataFromSupabase();
      if (newGroupId != null && mounted) {
        final idx = _groups.indexWhere((g) => g['id'] == newGroupId);
        if (idx != -1) {
          _renameGroup(idx);
        }
      }
    } catch (e) {
      debugPrint('Error creating student group: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('เกิดข้อผิดพลาดในการสร้างกลุ่ม'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _renameGroup(int index) {
    final group = _groups[index];
    final groupId = group['id'] as String;
    final controller = TextEditingController(text: group['name'] as String);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(
              Icons.edit_note_rounded,
              color: TeacherPalette.primary,
              size: 24,
            ),
            SizedBox(width: 10),
            Text(
              'ตั้งชื่อกลุ่มใหม่',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ระบุชื่อกลุ่ม หรือ ชื่อหัวข้อโครงงานกิจกรรม:',
              style: TextStyle(fontSize: 13, color: TeacherPalette.muted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'เช่น กลุ่ม 1: ฟาร์มอัจฉริยะ',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                Navigator.pop(ctx);
                try {
                  await StudentGroupService.renameStudentGroup(
                    groupId: groupId,
                    name: newName,
                  );
                  await _fetchRealDataFromSupabase();
                } catch (e) {
                  debugPrint('Error renaming student group: $e');
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('เกิดข้อผิดพลาดในการเปลี่ยนชื่อกลุ่ม'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: TeacherPalette.primary,
              foregroundColor: Colors.white,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteGroup(int index) async {
    final group = _groups[index];
    final groupId = group['id'] as String;
    try {
      await StudentGroupService.deleteStudentGroup(groupId);
      await _fetchRealDataFromSupabase();
    } catch (e) {
      debugPrint('Error deleting student group: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('เกิดข้อผิดพลาดในการลบกลุ่ม'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _addStudentToGroup(String groupName, String studentName) async {
    for (final g in _groups) {
      final members = g['members'] as List<String>;
      if (members.contains(studentName) ||
          members.any((m) => studentName.contains(m))) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '⚠️ ไม่สามารถเพิ่ม $studentName ได้ เนื่องจากอยู่ใน "${g['name']}" อยู่แล้ว (กติกา: นักเรียน 1 คนอยู่ได้เพียง 1 กลุ่มต่อกิจกรรมเท่านั้น)',
            ),
            backgroundColor: const Color(0xFFEA580C),
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }
    }

    final targetGroup = _groups.firstWhere(
      (g) => g['name'] == groupName,
      orElse: () => {},
    );
    if (targetGroup.isEmpty) return;
    final groupId = targetGroup['id'] as String;
    final studentId = _studentNameToId[studentName];

    if (studentId == null || studentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่พบรหัสนักเรียนในระบบ'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await StudentGroupService.addGroupMember(
        groupId: groupId,
        studentId: studentId,
      );
      await _fetchRealDataFromSupabase();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เพิ่ม $studentName เข้าสู่ $groupName เรียบร้อยแล้ว'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } catch (e) {
      debugPrint('Error adding student to group: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('เกิดข้อผิดพลาดในการเพิ่มนักเรียนเข้ากลุ่ม'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _removeStudentFromGroup(String groupId, String studentId) async {
    try {
      await StudentGroupService.removeGroupMember(
        groupId: groupId,
        studentId: studentId,
      );
      await _fetchRealDataFromSupabase();
    } catch (e) {
      debugPrint('Error removing student from group: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('เกิดข้อผิดพลาดในการถอดนักเรียนออกจากกลุ่ม'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openStudentPickerModal(String groupName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredList = _availableStudents
                .where(
                  (st) => st.toLowerCase().contains(searchQuery.toLowerCase()),
                )
                .toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.65,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_add_rounded,
                        color: TeacherPalette.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'เลือกนักเรียนเข้า "$groupName"',
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w900,
                            color: TeacherPalette.ink,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    onChanged: (val) => setModalState(() => searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'พิมพ์ค้นหาชื่อ หรือ เลขที่นักเรียน...',
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: TeacherPalette.muted,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: filteredList.isEmpty
                        ? const Center(
                            child: Text(
                              'ไม่มีรายชื่อนักเรียนที่ยังไม่ได้จัดกลุ่ม',
                              style: TextStyle(
                                color: TeacherPalette.muted,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredList.length,
                            itemBuilder: (context, idx) {
                              final st = filteredList[idx];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: TeacherPalette.primary
                                            .withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.person_rounded,
                                        size: 18,
                                        color: TeacherPalette.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        st,
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        _addStudentToGroup(groupName, st);
                                      },
                                      icon: const Icon(
                                        Icons.add_rounded,
                                        size: 16,
                                      ),
                                      label: const Text('เลือกเข้ากลุ่ม'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: TeacherPalette.primary,
                                        foregroundColor: Colors.white,
                                        minimumSize: Size.zero,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 8,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: TeacherPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.groups_rounded,
                    color: TeacherPalette.primary,
                    size: 26,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'จัดการกลุ่มนักเรียนสำหรับทำกิจกรรม',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: TeacherPalette.ink,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _addGroup,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('เพิ่มกลุ่มใหม่'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TeacherPalette.primary,
                  foregroundColor: Colors.white,
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
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
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFFD97706),
                  size: 18,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'กติกา: นักเรียน 1 คนสังกัดได้เพียง 1 กลุ่มต่อกิจกรรมเท่านั้น (กดปุ่ม ✏️ เพื่อตั้งชื่อกลุ่มได้)',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF92400E),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_groups.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.groups_outlined,
                    size: 36,
                    color: TeacherPalette.muted,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'ยังไม่มีกลุ่มนักเรียนสำหรับทำกิจกรรมในระบบ',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: TeacherPalette.ink,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'กดปุ่ม "+ เพิ่มกลุ่มใหม่" ด้านบนเพื่อเริ่มจัดกลุ่มนักเรียน',
                    style: TextStyle(fontSize: 12, color: TeacherPalette.muted),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _groups.length,
              itemBuilder: (context, gIndex) {
                final group = _groups[gIndex];
                final members = group['members'] as List<String>;

                return Container(
                  margin: const EdgeInsets.only(bottom: 18),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: TeacherPalette.primary.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.diversity_3_rounded,
                              color: TeacherPalette.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              group['name'] as String,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: TeacherPalette.ink,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${members.length} สมาชิก',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0284C7),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          PopupMenuButton<String>(
                            icon: const Icon(
                              Icons.more_vert_rounded,
                              color: Color(0xFF64748B),
                              size: 20,
                            ),
                            elevation: 8,
                            shadowColor: Colors.black.withValues(alpha: 0.15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            color: Colors.white,
                            onSelected: (val) {
                              if (val == 'rename') {
                                _renameGroup(gIndex);
                              } else if (val == 'delete') {
                                _deleteGroup(gIndex);
                              }
                            },
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(
                                value: 'rename',
                                height: 40,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.edit_note_rounded,
                                      size: 18,
                                      color: TeacherPalette.primary,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'แก้ไขชื่อกลุ่ม',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                height: 40,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete_outline_rounded,
                                      size: 18,
                                      color: Color(0xFFEF4444),
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'ลบกลุ่มนี้',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFFEF4444),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Divider(height: 24, color: Color(0xFFE2E8F0)),
                      if (members.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          alignment: Alignment.center,
                          child: const Text(
                            'ยังไม่มีสมาชิกในกลุ่มนี้ (กดเลือกนักเรียนด้านล่าง)',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: TeacherPalette.muted,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        )
                      else
                        Column(
                          children: members.map((m) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 30,
                                    height: 30,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF1F5F9),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.person_outline_rounded,
                                      size: 16,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      m,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(8),
                                      onTap: () async {
                                        final groupId = group['id'] as String;
                                        final rawMembers =
                                            group['rawMembers']
                                                as List<dynamic>? ??
                                            [];
                                        final rawM = rawMembers.firstWhere(
                                          (item) => item['name'] == m,
                                          orElse: () => <String, dynamic>{},
                                        );
                                        final studentId =
                                            (rawM['id'] as String?) ??
                                            _studentNameToId[m];
                                        if (studentId != null &&
                                            studentId.isNotEmpty) {
                                          await _removeStudentFromGroup(
                                            groupId,
                                            studentId,
                                          );
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEF2F2),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.close_rounded,
                                          color: Color(0xFFEF4444),
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 12),
                      if (_availableStudents.isNotEmpty)
                        OutlinedButton.icon(
                          onPressed: () =>
                              _openStudentPickerModal(group['name'] as String),
                          icon: const Icon(
                            Icons.person_add_alt_1_rounded,
                            size: 16,
                            color: TeacherPalette.primary,
                          ),
                          label: const Text(
                            '+ เลือกนักเรียนเข้ากลุ่มนี้',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: TeacherPalette.primary,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: TeacherPalette.primary.withValues(
                              alpha: 0.08,
                            ),
                            side: BorderSide(
                              color: TeacherPalette.primary.withValues(
                                alpha: 0.25,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _AddStudentModalSheet extends StatefulWidget {
  const _AddStudentModalSheet({
    required this.course,
    required this.onEnrolledSuccess,
  });

  final TeacherCourseModel course;
  final VoidCallback onEnrolledSuccess;

  @override
  State<_AddStudentModalSheet> createState() => _AddStudentModalSheetState();
}

class _AddStudentModalSheetState extends State<_AddStudentModalSheet> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _searchFailed = false;
  String _searchQuery = '';

  List<StudentLookup> _students = [];
  Set<String> _alreadyEnrolledStudentIds = {};
  final Set<String> _selectedStudentIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final courseId = widget.course.id ?? widget.course.code;
    try {
      final enrolled = await CourseService.listCourseStudents(courseId);
      final enrolledIds = enrolled.map((s) => s.studentId).toSet();

      final students = await CourseService.searchSchoolStudents(
        query: _searchQuery,
      );

      if (mounted) {
        setState(() {
          _alreadyEnrolledStudentIds = enrolledIds;
          _students = students;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _students = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _performSearch(String q) async {
    _searchQuery = q;
    try {
      final students = await CourseService.searchSchoolStudents(query: q);
      if (mounted) {
        setState(() {
          _students = students;
          _searchFailed = false;
        });
      }
    } catch (e) {
      // เดิมกลืนเงียบ → รายการเก่าค้าง/ว่าง ครูอ่านว่า "ไม่พบนักเรียน"
      debugPrint('EnrollStudentSheet: ค้นหานักเรียนไม่สำเร็จ — $e');
      if (mounted) setState(() => _searchFailed = true);
    }
  }

  Future<void> _submitEnrollment() async {
    if (_selectedStudentIds.isEmpty || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    final courseId = widget.course.id ?? widget.course.code;
    int successCount = 0;
    int failCount = 0;

    for (final studentId in _selectedStudentIds) {
      try {
        await CourseService.enrollStudent(
          courseId: courseId,
          studentId: studentId,
        );
        successCount++;
      } catch (e) {
        failCount++;
      }
    }

    if (!mounted) return;

    Navigator.pop(context);

    if (failCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'เพิ่มนักเรียน $successCount คนเข้าวิชา ${widget.course.code} เรียบร้อยแล้ว',
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'เพิ่มสำเร็จ $successCount คน, ไม่สำเร็จ $failCount คน',
          ),
          backgroundColor: const Color(0xFFD97706),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    widget.onEnrolledSuccess();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (ctx, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'เพิ่มนักเรียนเข้าวิชา ${widget.course.code}',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const SizedBox(height: 4),
            const Text(
              'ค้นหา/เลือกได้จากรายชื่อนักเรียนของโรงเรียนเดียวกันเท่านั้น',
              style: TextStyle(fontSize: 12, color: TeacherPalette.muted),
            ),
            const SizedBox(height: 14),
            TextField(
              onChanged: (v) => _performSearch(v),
              decoration: InputDecoration(
                hintText: 'ค้นหาชื่อหรืออีเมลนักเรียน...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _searchFailed
                  ? const Center(
                      child: Text(
                        'ค้นหาไม่สำเร็จ กรุณาลองใหม่อีกครั้ง',
                        style: TextStyle(
                          fontSize: 13,
                          color: TeacherPalette.red,
                        ),
                      ),
                    )
                  : _students.isEmpty
                  ? const Center(
                      child: Text(
                        'ไม่พบรายชื่อนักเรียน',
                        style: TextStyle(
                          fontSize: 13,
                          color: TeacherPalette.muted,
                        ),
                      ),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      itemCount: _students.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final s = _students[index];
                        final alreadyIn = _alreadyEnrolledStudentIds.contains(
                          s.studentId,
                        );
                        final isSelected = _selectedStudentIds.contains(
                          s.studentId,
                        );
                        return CheckboxListTile(
                          value: alreadyIn ? true : isSelected,
                          onChanged: alreadyIn || _isSubmitting
                              ? null
                              : (v) {
                                  setState(() {
                                    if (v == true) {
                                      _selectedStudentIds.add(s.studentId);
                                    } else {
                                      _selectedStudentIds.remove(s.studentId);
                                    }
                                  });
                                },
                          title: Text(
                            s.fullName,
                            style: const TextStyle(fontSize: 13.5),
                          ),
                          subtitle: Text(
                            alreadyIn ? 'อยู่ในวิชานี้แล้ว' : s.email,
                            style: TextStyle(
                              fontSize: 11,
                              color: alreadyIn
                                  ? TeacherPalette.muted
                                  : TeacherPalette.softText,
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _selectedStudentIds.isEmpty || _isSubmitting
                    ? null
                    : _submitEnrollment,
                style: FilledButton.styleFrom(
                  backgroundColor: TeacherPalette.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _selectedStudentIds.isEmpty
                            ? 'เลือกนักเรียนก่อน'
                            : 'เพิ่ม ${_selectedStudentIds.length} คนเข้าวิชา',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void openAddStudentModalSheet(
  BuildContext context,
  TeacherCourseModel course, [
  VoidCallback? onSuccess,
]) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (modalContext) => _AddStudentModalSheet(
      course: course,
      onEnrolledSuccess: () {
        if (onSuccess != null) onSuccess();
      },
    ),
  );
}

/// แท็บ "นักเรียน" ของหน้ารายละเอียดวิชา — เป็น public เพื่อให้ widget test
/// ฉีด `loadStudents` ได้โดยไม่ต้อง mount ทั้งหน้ารายละเอียด (ซึ่งโหลด
/// บทเรียน/ใบงาน/คะแนนจากหลายบริการพร้อมกัน)
class TeacherStudentRosterTab extends StatefulWidget {
  const TeacherStudentRosterTab({
    super.key,
    required this.course,
    this.loadStudents,
  });

  final TeacherCourseModel course;
  final Future<List<CourseStudent>> Function(String courseId)? loadStudents;

  @override
  State<TeacherStudentRosterTab> createState() =>
      _TeacherStudentRosterTabState();
}

class _TeacherStudentRosterTabState extends State<TeacherStudentRosterTab> {
  bool _isLoading = true;
  bool _loadFailed = false;
  List<Map<String, dynamic>> _students = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadStudentsFromSupabase();
  }

  Future<void> _loadStudentsFromSupabase() async {
    setState(() => _isLoading = true);
    try {
      final enrolled = await (widget.loadStudents ??
          CourseService.listCourseStudents)(widget.course.id ?? '');
      final List<Map<String, dynamic>> list = enrolled
          .map(
            (st) => {
              'id': st.studentId,
              'name': st.fullName,
              'email': st.email,
              // list_course_students ไม่คืนรหัสนักเรียน — เดิมตัด 8 ตัวแรก
              // ของ uuid มาโชว์เป็น "รหัส" และใส่ 'ม.4/1' ให้ทุกคน ตอนนี้ใช้
              // ห้องของรายวิชาจริงและอีเมลแทน
              'email_label': st.email,
              'room': widget.course.rooms.isEmpty
                  ? null
                  : widget.course.rooms.join(', '),
            },
          )
          .toList();

      if (mounted) {
        setState(() {
          _students = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      // เดิมโหลดล้ม = รายการว่าง ครูอ่านว่า "ยังไม่มีนักเรียนลงทะเบียน"
      debugPrint('Error loading students in tab via RPC: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadFailed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _students.where((s) {
      final name = (s['name'] as String).toLowerCase();
      final email = (s['email_label'] as String? ?? '').toLowerCase();
      final q = _searchQuery.toLowerCase();
      return name.contains(q) || email.contains(q);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'รายชื่อนักเรียนในวิชา (${_students.length} คน)',
              style: const TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w900,
                color: TeacherPalette.ink,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => openAddStudentModalSheet(
                context,
                widget.course,
                _loadStudentsFromSupabase,
              ),
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
              label: const Text('เพิ่มนักเรียนเข้ารายวิชา'),
              style: ElevatedButton.styleFrom(
                backgroundColor: TeacherPalette.primary,
                foregroundColor: Colors.white,
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        TeacherSearchInput(
          hintText: 'พิมพ์ค้นหาชื่อ หรือ รหัสนักเรียน...',
          value: _searchQuery,
          onChanged: (val) => setState(() => _searchQuery = val),
          onClear: () => setState(() => _searchQuery = ''),
        ),
        const SizedBox(height: 16),
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(36),
              child: CircularProgressIndicator(color: TeacherPalette.primary),
            ),
          )
        else if (_loadFailed)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: TeacherPalette.border),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  size: 40,
                  color: TeacherPalette.red,
                ),
                const SizedBox(height: 10),
                const Text(
                  'โหลดรายชื่อนักเรียนไม่สำเร็จ',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: TeacherPalette.ink,
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _loadStudentsFromSupabase,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('ลองใหม่'),
                ),
              ],
            ),
          )
        else if (filtered.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: TeacherPalette.border),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.person_off_rounded,
                  size: 40,
                  color: TeacherPalette.muted,
                ),
                SizedBox(height: 10),
                Text(
                  'ยังไม่มีนักเรียนลงทะเบียนในรายวิชานี้',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: TeacherPalette.ink,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'กดปุ่ม "+ เพิ่มนักเรียนเข้ารายวิชา" ด้านบนเพื่อลงทะเบียนนักเรียนเข้าเรียน',
                  style: TextStyle(fontSize: 12, color: TeacherPalette.muted),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            itemBuilder: (ctx, idx) {
              final st = filtered[idx];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: TeacherPalette.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: TeacherPalette.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                st['name'] as String,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: TeacherPalette.ink,
                                ),
                              ),
                              // ป้ายห้องมาจากห้องของรายวิชา — วิชาที่ยังไม่ระบุ
                              // ห้องไม่แสดงป้าย (อีเมลอยู่บรรทัดถัดไปอยู่แล้ว)
                              if (st['room'] != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'ห้อง ${st['room']}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            st['email'] as String,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: TeacherPalette.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: const Text(
                        '🟢 เรียนปกติ (Active)',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF047857),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

class _CourseGradebookTabWidget extends StatefulWidget {
  const _CourseGradebookTabWidget({required this.course});

  final TeacherCourseModel course;

  @override
  State<_CourseGradebookTabWidget> createState() =>
      _CourseGradebookTabWidgetState();
}

class _CourseGradebookTabWidgetState extends State<_CourseGradebookTabWidget> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _students = [];

  @override
  void initState() {
    super.initState();
    _fetchGradeData();
  }

  Future<void> _fetchGradeData() async {
    setState(() => _isLoading = true);
    try {
      final courseId = widget.course.id ?? '';
      final enrolled = await CourseService.listCourseStudents(courseId);
      List<GradeRecord> grades = [];
      try {
        grades = await GradeService.listCourseGrades(courseId);
      } catch (e) {
        debugPrint('Error fetching course grades via RPC: $e');
      }
      final gradesByStudent = <String, List<GradeRecord>>{};
      for (final g in grades) {
        gradesByStudent.putIfAbsent(g.studentId, () => []).add(g);
      }

      final List<Map<String, dynamic>> list = enrolled.map((st) {
        final entries = gradesByStudent[st.studentId] ?? const [];
        final totalScore = entries.fold<num>(0, (sum, g) => sum + g.score);
        final totalMax = entries.fold<num>(0, (sum, g) => sum + g.maxScore);
        final confirmedCount = entries
            .where((g) => g.status == 'confirmed')
            .length;
        return {
          'name': st.fullName,
          'code': st.studentId.length >= 8
              ? st.studentId.substring(0, 8)
              : st.studentId,
          'entryCount': entries.length,
          'totalScore': totalScore,
          'totalMax': totalMax,
          'confirmedCount': confirmedCount,
        };
      }).toList();

      if (mounted) {
        setState(() {
          _students = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching grade data via RPC: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalScore = _students.fold<num>(
      0,
      (sum, st) => sum + (st['totalScore'] as num),
    );
    final totalMax = _students.fold<num>(
      0,
      (sum, st) => sum + (st['totalMax'] as num),
    );
    final avgLabel = totalMax > 0
        ? '${(totalScore / totalMax * 100).round()}%'
        : 'ยังไม่มีคะแนน';
    final entryCount = _students.fold<int>(
      0,
      (sum, st) => sum + (st['entryCount'] as int),
    );
    final studentsWithGrades = _students
        .where((st) => (st['entryCount'] as int) > 0)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 700;
            return GridView.count(
              crossAxisCount: isDesktop ? 3 : 1,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: isDesktop ? 2.4 : 3.0,
              children: [
                _buildSummaryCard(
                  title: 'คะแนนเฉลี่ยรวมรายวิชา',
                  value: avgLabel,
                  subtitle: 'คำนวณจากคะแนนที่บันทึกจริงในระบบ',
                  icon: Icons.grade_rounded,
                  color: const Color(0xFF059669),
                  bgColor: const Color(0xFFECFDF5),
                ),
                _buildSummaryCard(
                  title: 'จำนวนรายการคะแนนที่บันทึกแล้ว',
                  value: '$entryCount รายการ',
                  subtitle: 'รวมทุกรายการคะแนนที่ครูบันทึกในวิชานี้',
                  icon: Icons.assignment_turned_in_rounded,
                  color: TeacherPalette.primary,
                  bgColor: TeacherPalette.primary.withValues(alpha: 0.08),
                ),
                _buildSummaryCard(
                  title: 'นักเรียนที่มีคะแนนแล้ว',
                  value: '$studentsWithGrades/${_students.length} คน',
                  subtitle: _students.isEmpty
                      ? '-'
                      : '${(studentsWithGrades / _students.length * 100).round()}% ของทั้งห้องเรียน',
                  icon: Icons.people_alt_rounded,
                  color: const Color(0xFF2563EB),
                  bgColor: const Color(0xFFEFF6FF),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'สมุดบันทึกคะแนน (Gradebook Overview)',
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w900,
                color: TeacherPalette.ink,
              ),
            ),
            // ยังไม่มี backend รองรับการส่งออกคะแนน (ไม่มี RPC/Service ใดใน
            // shared_core ที่ทำเรื่องนี้) — ปิดปุ่มไว้ตรง ๆ ดีกว่าขึ้นข้อความ
            // ว่า "กำลังส่งออก..." ทั้งที่ไม่ได้ยิงอะไรเลย
            const Tooltip(
              message:
                  'ยังไม่รองรับการส่งออกคะแนนเป็นไฟล์ — ฟีเจอร์นี้ยังไม่ได้เชื่อมกับเซิร์ฟเวอร์',
              child: OutlinedButton(
                onPressed: null,
                style: ButtonStyle(
                  minimumSize: WidgetStatePropertyAll(Size.zero),
                  padding: WidgetStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.file_download_rounded, size: 16),
                    SizedBox(width: 6),
                    Text('ส่งออกคะแนน (ยังไม่เปิดใช้งาน)'),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(36),
              child: CircularProgressIndicator(color: TeacherPalette.primary),
            ),
          )
        else if (_students.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: TeacherPalette.border),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.assessment_outlined,
                  size: 40,
                  color: TeacherPalette.muted,
                ),
                SizedBox(height: 10),
                Text(
                  'ยังไม่มีข้อมูลคะแนนนักเรียนในระบบ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: TeacherPalette.ink,
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  const Color(0xFFF8FAFC),
                ),
                headingTextStyle: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: TeacherPalette.ink,
                ),
                dataTextStyle: const TextStyle(
                  fontSize: 13,
                  color: TeacherPalette.ink,
                ),
                columns: const [
                  DataColumn(label: Text('ชื่อ-นามสกุล นักเรียน')),
                  DataColumn(label: Text('รหัสนักเรียน')),
                  DataColumn(label: Text('คะแนนรวมที่บันทึกแล้ว')),
                  DataColumn(label: Text('จำนวนรายการคะแนน')),
                  DataColumn(label: Text('สถานะ')),
                ],
                rows: _students.map((st) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: TeacherPalette.primary.withValues(
                                  alpha: 0.1,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                size: 18,
                                color: TeacherPalette.primary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              st['name'] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DataCell(Text(st['code'] as String)),
                      DataCell(
                        (st['entryCount'] as int) == 0
                            ? const Text(
                                'ยังไม่มีคะแนน',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: TeacherPalette.muted,
                                ),
                              )
                            : Text(
                                '${st['totalScore']}/${st['totalMax']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: TeacherPalette.primary,
                                ),
                              ),
                      ),
                      DataCell(Text('${st['entryCount']} รายการ')),
                      DataCell(
                        (st['entryCount'] as int) == 0
                            ? const Text(
                                'ยังไม่มีคะแนน',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: TeacherPalette.muted,
                                  fontSize: 12,
                                ),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    (st['confirmedCount'] as int) ==
                                            st['entryCount']
                                        ? Icons.check_circle_rounded
                                        : Icons.hourglass_bottom_rounded,
                                    size: 16,
                                    color: (st['confirmedCount'] as int) ==
                                            st['entryCount']
                                        ? const Color(0xFF059669)
                                        : const Color(0xFFCA8A04),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'ยืนยันแล้ว ${st['confirmedCount']}/${st['entryCount']} รายการ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: (st['confirmedCount'] as int) ==
                                              st['entryCount']
                                          ? const Color(0xFF059669)
                                          : const Color(0xFFCA8A04),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: TeacherPalette.muted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: TeacherPalette.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseAssignmentListTabWidget extends StatefulWidget {
  const _CourseAssignmentListTabWidget({required this.course});

  final TeacherCourseModel course;

  @override
  State<_CourseAssignmentListTabWidget> createState() =>
      _CourseAssignmentListTabWidgetState();
}

class _CourseAssignmentListTabWidgetState
    extends State<_CourseAssignmentListTabWidget> {
  bool _isLoading = true;
  List<AssignmentSummary> _assignments = [];

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  Future<void> _loadAssignments() async {
    setState(() => _isLoading = true);
    try {
      final list = await AssignmentService.listAssignments(
        widget.course.id ?? '',
      );
      if (mounted) {
        setState(() {
          _assignments = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading assignments: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'รายการใบงาน/ภารกิจ (${_assignments.length} งาน)',
              style: const TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w900,
                color: TeacherPalette.ink,
              ),
            ),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    final courseId = widget.course.id;
                    if (courseId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'วิชานี้สร้างในเครื่องเท่านั้น ยังไม่บันทึกลง'
                            'เซิร์ฟเวอร์ จึงยังสร้างกิจกรรม PBL ไม่ได้',
                          ),
                        ),
                      );
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            TeacherPblActivityEditorPage(courseId: courseId),
                      ),
                    );
                  },
                  icon: const Icon(Icons.science_rounded, size: 16),
                  label: const Text('สร้างกิจกรรม PBL'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: TeacherPalette.primary,
                    side: const BorderSide(color: TeacherPalette.primary),
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    openAssignmentFormModal(
                      context,
                      onSave: (_) => _loadAssignments(),
                    );
                  },
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('สร้างใบงานใหม่'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TeacherPalette.primary,
                    foregroundColor: Colors.white,
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
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
        const SizedBox(height: 16),
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(36),
              child: CircularProgressIndicator(color: TeacherPalette.primary),
            ),
          )
        else if (_assignments.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: TeacherPalette.border),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.assignment_outlined,
                  size: 44,
                  color: TeacherPalette.muted,
                ),
                const SizedBox(height: 12),
                const Text(
                  'ยังไม่มีใบงานในรายวิชานี้',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: TeacherPalette.ink,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'กดปุ่ม "+ สร้างใบงานใหม่" ด้านบนเพื่อเริ่มสร้างโจทย์และภารกิจให้นักเรียน',
                  style: TextStyle(fontSize: 12.5, color: TeacherPalette.muted),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TeacherAssignmentEditorPage(),
                      ),
                    ).then((_) => _loadAssignments());
                  },
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('สร้างใบงานแรกของวิชา'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TeacherPalette.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _assignments.length,
            itemBuilder: (ctx, idx) {
              final a = _assignments[idx];
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                size: 13,
                                color: Color(0xFF047857),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'เผยแพร่แล้ว',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF047857),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          'ส่งแล้ว 1/1 คน (100%)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: TeacherPalette.muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      a.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: TeacherPalette.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: TeacherPalette.muted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'กำหนดส่ง: ${a.dueAt ?? "ไม่กำหนดวันสิ้นสุด"}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: TeacherPalette.muted,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: TeacherPalette.primary.withValues(
                              alpha: 0.08,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.sensors_rounded,
                                size: 12,
                                color: TeacherPalette.primary,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'ผูกเซนเซอร์ AIoT',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: TeacherPalette.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            // เดิมสร้าง instructions/rubric/จำนวนส่งงานปลอม
                            // ทั้งหมดตอนกด "แก้ไขใบงาน" ทับข้อมูลจริงของ
                            // ใบงานนี้เงียบๆ (a มาจาก AssignmentService.
                            // listAssignments ซึ่งตอนนี้คืน instructions/
                            // rubric จริงอยู่แล้ว) ใช้ค่าจริงจาก a แทน
                            final model = AssignmentModel(
                              id: a.id,
                              courseId: widget.course.id ?? '',
                              title: a.title,
                              instructions: a.instructions ?? '',
                              type: 'ใบงานทดลอง',
                              courseName: widget.course.name,
                              dueDate: a.dueAt != null
                                  ? a.dueAt!
                                        .toLocal()
                                        .toString()
                                        .substring(0, 16)
                                  : 'ไม่มีกำหนดส่ง',
                              status: a.isPublished ? 'เผยแพร่แล้ว' : 'ร่าง',
                              isGroupWork: a.isGroup,
                              rubricId: a.rubricId,
                              rubricTitle:
                                  a.rubricTitle ?? 'ยังไม่ได้กำหนด Rubric',
                              attachedSensorMetrics: const [],
                              submittedCount: 0,
                              totalStudents: 0,
                              updatedAt: a.createdAt != null
                                  ? 'สร้างเมื่อ ${a.createdAt!.toLocal().toString().substring(0, 10)}'
                                  : 'ยังไม่มีข้อมูล',
                            );
                            openAssignmentFormModal(
                              context,
                              assignment: model,
                              onSave: (_) => _loadAssignments(),
                            );
                          },
                          icon: const Icon(Icons.edit_outlined, size: 15),
                          label: const Text('แก้ไขใบงาน'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
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
                          icon: const Icon(
                            Icons.rate_review_outlined,
                            size: 15,
                          ),
                          label: const Text('ตรวจงานและให้คะแนน'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: TeacherPalette.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
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
            },
          ),
      ],
    );
  }
}
