// PROTOTYPE ONLY: Teacher Course Management & Detail Pages
// Displays teacher's courses, lesson plans, worksheets, and course detail view.
// Redesigned with modern glassmorphic aesthetics, rich stat cards, dynamic badges, and progress indicators.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;

import 'teacher_assignment_editor_page.dart';
import 'teacher_exam_builder_page.dart';
import 'teacher_grading_page.dart';
import 'teacher_incident_inbox_page.dart';
import 'teacher_lesson_editor_page.dart';
import 'teacher_redesign_prototype_page.dart' show TeacherPalette;
import 'teacher_shared_widgets.dart';
import 'teacher_students_page.dart';

/// Data model for a course in the teacher prototype
class TeacherCourseModel {
  const TeacherCourseModel({
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

  // CLS-1 Main Flow ข้อ 4 / BR1: รหัสเข้าร่วมผูกกับรายวิชานั้นเท่านั้น
  // เปลี่ยนรายวิชาต้องสร้างใหม่ — คำนวณจากรหัสวิชาเอง (deterministic)
  // แทนการสุ่ม เพื่อให้ mock data คงที่ทุกครั้งที่เปิดหน้า
  String get joinCode => '${code.toUpperCase()}-JOIN';
}

final List<TeacherCourseModel> mockTeacherCourses = [
  const TeacherCourseModel(
    code: 'ว31281',
    name: 'วิทยาการคำนวณ & AI เบื้องต้น',
    category: 'เทคโนโลยี',
    rooms: ['ม.4/1', 'ม.4/2'],
    studentCount: 82,
    activeAssignments: 3,
    pendingGradingCount: 4,
    completionRate: 0.88,
    coverGradient: [Color(0xFF0F766E), Color(0xFF14B8A6)],
    accentColor: Color(0xFF0D9488),
    nextPeriodText: 'อังคาร คาบ 2-3 (ห้อง 421)',
  ),
  const TeacherCourseModel(
    code: 'ว32282',
    name: 'STEM & Green-Lab IoT',
    category: 'วิทยาศาสตร์',
    rooms: ['ม.5/2'],
    studentCount: 41,
    activeAssignments: 2,
    pendingGradingCount: 1,
    completionRate: 0.94,
    coverGradient: [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
    accentColor: Color(0xFF2563EB),
    nextPeriodText: 'พุธ คาบ 5-6 (ห้อง GreenLab)',
  ),
  const TeacherCourseModel(
    code: 'ว33283',
    name: 'ฟิสิกส์ประยุกต์ & หุ่นยนต์',
    category: 'ฟิสิกส์',
    rooms: ['ม.6/1', 'ม.6/3'],
    studentCount: 78,
    activeAssignments: 1,
    pendingGradingCount: 1,
    completionRate: 0.79,
    coverGradient: [Color(0xFF6D28D9), Color(0xFF8B5CF6)],
    accentColor: Color(0xFF7C3AED),
    nextPeriodText: 'พฤหัส คาบ 1-2 (ห้อง 602)',
  ),
  const TeacherCourseModel(
    code: 'ว30205',
    name: 'การเขียนโปรแกรม Python & Data Science',
    category: 'เทคโนโลยี',
    rooms: ['ม.5/1'],
    studentCount: 38,
    activeAssignments: 2,
    pendingGradingCount: 2,
    completionRate: 0.65,
    coverGradient: [Color(0xFF4338CA), Color(0xFF6366F1)],
    accentColor: Color(0xFF4F46E5),
    nextPeriodText: 'จันทร์ คาบ 3-4 (ห้อง Com 2)',
  ),
  const TeacherCourseModel(
    code: 'ค33201',
    name: 'คณิตศาสตร์วิศวกรรม & AI Modeling',
    category: 'คณิตศาสตร์',
    rooms: ['ม.6/2'],
    studentCount: 35,
    activeAssignments: 1,
    pendingGradingCount: 0,
    completionRate: 0.50,
    coverGradient: [Color(0xFFC2410C), Color(0xFFF97316)],
    accentColor: Color(0xFFEA580C),
    nextPeriodText: 'ศุกร์ คาบ 1-2 (ห้อง 514)',
    // demo: ครูถูกถอดออกจากวิชานี้แล้ว ใช้ทดสอบ Permission Denied state
    hasAccess: false,
  ),
  const TeacherCourseModel(
    code: 'ว30291',
    name: 'โครงงานนวัตกรรมพลังงานสะอาด (Clean Energy)',
    category: 'วิทยาศาสตร์',
    rooms: ['ม.4/3'],
    studentCount: 40,
    activeAssignments: 3,
    pendingGradingCount: 3,
    completionRate: 0.42,
    coverGradient: [Color(0xFFBE123C), Color(0xFFFB7185)],
    accentColor: Color(0xFFE11D48),
    // demo: ภาคเรียนปิดแล้ว ใช้ทดสอบ Course Closed state
    isClosed: true,
    nextPeriodText: 'อังคาร คาบ 6-7 (ห้อง ปฏิบัติการวิทยาศาสตร์)',
  ),
];

class TeacherCoursesPage extends StatefulWidget {
  const TeacherCoursesPage({super.key});

  @override
  State<TeacherCoursesPage> createState() => _TeacherCoursesPageState();
}

class _TeacherCoursesPageState extends State<TeacherCoursesPage> {
  String _searchQuery = '';
  String _selectedRoom = 'ทั้งหมด';

  void _openNewCourseModal() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _NewCourseModalSheet(
        onCourseCreated: (newCourse) {
          setState(() {
            mockTeacherCourses.insert(0, newCourse);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white),
                  const SizedBox(width: 10),
                  Text('สร้างรายวิชา ${newCourse.code} สำเร็จ!'),
                ],
              ),
              backgroundColor: const Color(0xFF059669),
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
    TeacherCourseModel? sourceCourse = mockTeacherCourses.first;
    String targetSemester = 'ภาคเรียนที่ 2/2569';
    final nameCtrl = TextEditingController(
      text: '${mockTeacherCourses.first.name} (คัดลอก)',
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
                    items: mockTeacherCourses
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
                    onChanged: (v) =>
                        setModalState(() => targetSemester = v!),
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
                  final isDuplicate = mockTeacherCourses.any(
                    (c) => c.name == newName,
                  );
                  if (isDuplicate) {
                    setModalState(
                      () => nameError = 'ชื่อนี้ซ้ำกับรายวิชาที่มีอยู่ — ตั้งชื่อใหม่ก่อนบันทึก',
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
                  setState(() => mockTeacherCourses.insert(0, copy));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'คัดลอกโครงสร้างวิชา "${src.name}" ไปเป็น "$newName" ($targetSemester) แล้ว '
                        '— ตรวจสอบก่อนเผยแพร่',
                      ),
                      backgroundColor: const Color(0xFF10B981),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 3),
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
        final filteredCourses = mockTeacherCourses.where((c) {
          final matchesSearch =
              c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              c.code.toLowerCase().contains(_searchQuery.toLowerCase());
          final matchesRoom =
              _selectedRoom == 'ทั้งหมด' || c.rooms.contains(_selectedRoom);
          return matchesSearch && matchesRoom;
        }).toList();

        final totalStudents = mockTeacherCourses.fold<int>(
          0,
          (sum, c) => sum + c.studentCount,
        );
        final totalPendingGrading = mockTeacherCourses.fold<int>(
          0,
          (sum, c) => sum + c.pendingGradingCount,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🌟 1. HERO HEADER CARD
            _buildHeroHeader(
              context,
              totalCourses: mockTeacherCourses.length,
              totalStudents: totalStudents,
            ),
            const SizedBox(height: 20),

            // 📊 2. STATS OVERVIEW CARDS
            _buildStatsGrid(
              context: context,
              totalCourses: mockTeacherCourses.length,
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
                    _TeacherCourseCard(course: filteredCourses[i]),
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
                          builder: (_) => const TeacherAssignmentEditorPage(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.assignment_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'จัดการใบงาน/โจทย์',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.35),
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
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'ค้นหาด้วยชื่อวิชา รหัสวิชา หรือกลุ่มสาระ...',
              hintStyle: const TextStyle(
                color: TeacherPalette.muted,
                fontSize: 13,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: TeacherPalette.primary,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: TeacherPalette.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: TeacherPalette.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: TeacherPalette.primary,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRooms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกห้องเรียนอย่างน้อย 1 ห้อง')),
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
    Navigator.pop(context);
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
  const _TeacherCourseCard({required this.course});

  final TeacherCourseModel course;

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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              TeacherCourseDetailPage(course: course),
                        ),
                      );
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              TeacherCourseDetailPage(course: course),
                        ),
                      );
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

// CLS-4: รายชื่อนักเรียนของโรงเรียนที่เลือกเพิ่มเข้ารายวิชานี้ได้ — คนที่ทำ
// เครื่องหมาย "อยู่ในวิชานี้แล้ว" ไว้ล่วงหน้าจำลอง Exception Flow
// "นักเรียนอยู่ในรายวิชานี้แล้ว → ข้าม ไม่เพิ่มซ้ำ"
const _schoolRosterMock = [
  'นายกิตติศักดิ์ ขยันยิ่ง (ม.5/2)',
  'นางสาวชลดา สายธาร (ม.5/2)',
  'นายธนากร เกียรติศักดิ์ (ม.5/2)',
  'นางสาวปาริชาติ ใจงาม (ม.5/1)',
  'นายวรากร สุขสันต์ (ม.5/1)',
  'นางสาวศิริพร รุ่งโรจน์ (ม.4/3)',
];

class _TeacherCourseDetailPageState extends State<TeacherCourseDetailPage> {
  String _activeTab = 'บทเรียน';

  // เดโม: จำลองว่า 2 คนแรกอยู่ในวิชานี้อยู่แล้วก่อนเปิดหน้า
  final Set<String> _enrolledFromRoster = {
    'นายกิตติศักดิ์ ขยันยิ่ง (ม.5/2)',
    'นางสาวชลดา สายธาร (ม.5/2)',
  };

  @override
  Widget build(BuildContext context) {
    final c = widget.course ?? mockTeacherCourses.first;

    return TeacherMockPageShell(
      title: 'รายละเอียดวิชา ${c.code}',
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
          onPressed: () => _openGroupManagementModal(context),
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
                  const SizedBox(height: 8),
                  Text(
                    'ห้องเรียน: ${c.rooms.join(', ')} • นักเรียนรวม ${c.studentCount} คน • ${c.nextPeriodText}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                    ),
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
                courseCode: c.code,
                courseName: c.name,
                isCourseClosed: c.isClosed,
                hasAccess: c.hasAccess,
              )
            else if (_activeTab == 'นักเรียน') ...[
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: () => _openAddStudentModal(context, c),
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                  label: const Text('เพิ่มนักเรียนเข้ารายวิชา'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: TeacherPalette.primary,
                    side: const BorderSide(color: TeacherPalette.primary),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TeacherStudentsPage(initialRoomFilter: c.rooms),
            ]
            else if (_activeTab == 'ใบงาน' || _activeTab == 'คะแนน')
              const TeacherGradingPage()
            else if (_activeTab == 'กลุ่ม')
              const _StudentGroupManagementWidget()
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('รหัสเข้าร่วมรายวิชา', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 2),
            Text(
              '${course.code} · ${course.name}',
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
              child: Text(
                course.joinCode,
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
            const Text(
              'รหัสนี้ผูกกับรายวิชานี้เท่านั้น หากต้องการใช้กับรายวิชาอื่นต้องสร้างใหม่',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: TeacherPalette.muted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ปิด'),
          ),
          FilledButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: course.joinCode));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('คัดลอกรหัสเข้าร่วมแล้ว'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('คัดลอกรหัส'),
            style: FilledButton.styleFrom(
              backgroundColor: TeacherPalette.primary,
            ),
          ),
        ],
      ),
    );
  }

  // CLS-4: ค้นหา/เลือกนักเรียนจากรายชื่อโรงเรียนเพื่อเพิ่มเข้ารายวิชานี้ —
  // ข้ามคนที่อยู่ในวิชาแล้ว (Exception Flow 1) ไม่เพิ่มซ้ำ
  void _openAddStudentModal(BuildContext context, TeacherCourseModel course) {
    final selected = <String>{};
    String query = '';
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) {
          final results = _schoolRosterMock
              .where((name) => name.toLowerCase().contains(query.toLowerCase()))
              .toList();
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
                    'เพิ่มนักเรียนเข้าวิชา ${course.code}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'ค้นหา/เลือกได้จากรายชื่อนักเรียนของโรงเรียนเดียวกันเท่านั้น',
                    style: TextStyle(fontSize: 12, color: TeacherPalette.muted),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    onChanged: (v) => setModalState(() => query = v),
                    decoration: InputDecoration(
                      hintText: 'ค้นหาชื่อนักเรียน...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: results.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final name = results[index];
                        final alreadyIn = _enrolledFromRoster.contains(name);
                        final isSelected = selected.contains(name);
                        return CheckboxListTile(
                          value: alreadyIn ? true : isSelected,
                          onChanged: alreadyIn
                              ? null
                              : (v) => setModalState(() {
                                  if (v == true) {
                                    selected.add(name);
                                  } else {
                                    selected.remove(name);
                                  }
                                }),
                          title: Text(
                            name,
                            style: const TextStyle(fontSize: 13.5),
                          ),
                          subtitle: alreadyIn
                              ? const Text(
                                  'อยู่ในวิชานี้แล้ว',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: TeacherPalette.muted,
                                  ),
                                )
                              : null,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: selected.isEmpty
                          ? null
                          : () {
                              setState(() {
                                _enrolledFromRoster.addAll(selected);
                              });
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'เพิ่มนักเรียน ${selected.length} คนเข้าวิชา ${course.code} แล้ว',
                                  ),
                                  backgroundColor: const Color(0xFF10B981),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: TeacherPalette.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        selected.isEmpty
                            ? 'เลือกนักเรียนก่อน'
                            : 'เพิ่ม ${selected.length} คนเข้าวิชา',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openGroupManagementModal(BuildContext context) {
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
            children: const [_StudentGroupManagementWidget()],
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
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('ปิดรายวิชา ${course.code} เรียบร้อยแล้ว'),
                    backgroundColor: const Color(0xFF10B981),
                  ),
                );
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
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEA580C), size: 24),
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
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'ปิดรายวิชา ${course.code} เรียบร้อยแล้ว (รับทราบความเสี่ยงจากงานค้าง)',
                  ),
                  backgroundColor: const Color(0xFFDC2626),
                ),
              );
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

/// Widget สำหรับจัดการกลุ่มนักเรียนในวิชา (Student Group Management)
class _StudentGroupManagementWidget extends StatefulWidget {
  const _StudentGroupManagementWidget();

  @override
  State<_StudentGroupManagementWidget> createState() =>
      __StudentGroupManagementWidgetState();
}

class __StudentGroupManagementWidgetState
    extends State<_StudentGroupManagementWidget> {
  final List<Map<String, dynamic>> _groups = [
    {
      'id': 'g1',
      'name': 'กลุ่ม 1: AIoT Smart Agriculture (ฟาร์มอัจฉริยะ)',
      'members': [
        'นายสมชาย เข็มกลัด (ม.5/2 เลขที่ 1)',
        'นางสาวมณี รุ่งเรือง (ม.5/2 เลขที่ 2)',
      ],
    },
    {
      'id': 'g2',
      'name': 'กลุ่ม 2: Weather Sensor Station (สถานีวัดอากาศ)',
      'members': [
        'นายปิติ สุขใจ (ม.5/2 เลขที่ 3)',
        'นางสาววิภาดา เรียนดี (ม.5/2 เลขที่ 4)',
      ],
    },
  ];

  final List<String> _availableStudents = [
    'นายกิตติศักดิ์ ขยันยิ่ง (ม.5/2 เลขที่ 5)',
    'นางสาวชลดา สายธาร (ม.5/2 เลขที่ 6)',
    'นายธนากร เกียรติศักดิ์ (ม.5/2 เลขที่ 7)',
  ];

  void _addGroup() {
    setState(() {
      _groups.add({
        'id': 'g-${DateTime.now().millisecondsSinceEpoch}',
        'name': 'กลุ่ม ${_groups.length + 1}: โครงงานใหม่',
        'members': <String>[],
      });
    });
  }

  void _addStudentToGroup(String groupName, String studentName) {
    // Rule Enforcement: Check if student already belongs to another group!
    for (final g in _groups) {
      final members = g['members'] as List<String>;
      if (members.contains(studentName)) {
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

    setState(() {
      final targetGroup = _groups.firstWhere((g) => g['name'] == groupName);
      (targetGroup['members'] as List<String>).add(studentName);
      _availableStudents.remove(studentName);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('เพิ่ม $studentName เข้าสู่ $groupName เรียบร้อยแล้ว'),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: TeacherPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'จัดการกลุ่มนักเรียนสำหรับทำกิจกรรม',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: TeacherPalette.ink,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'กติกา: นักเรียน 1 คนสังกัดได้เพียง 1 กลุ่มต่อกิจกรรมเท่านั้น',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: TeacherPalette.muted,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _addGroup,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('เพิ่มกลุ่มใหม่'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TeacherPalette.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Group List Loop
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _groups.length,
            itemBuilder: (context, gIndex) {
              final group = _groups[gIndex];
              final members = group['members'] as List<String>;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.groups_rounded,
                          color: TeacherPalette.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            group['name'] as String,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                              color: TeacherPalette.ink,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${members.length} สมาชิก',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0284C7),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    if (members.isEmpty)
                      const Text(
                        'ยังไม่มีสมาชิกในกลุ่มนี้',
                        style: TextStyle(
                          fontSize: 12,
                          color: TeacherPalette.muted,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    else
                      Column(
                        children: members.map((m) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.person_rounded,
                                  size: 14,
                                  color: TeacherPalette.muted,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    m,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: TeacherPalette.ink,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      members.remove(m);
                                      _availableStudents.add(m);
                                    });
                                  },
                                  icon: const Icon(
                                    Icons.remove_circle_outline_rounded,
                                    color: Color(0xFFEF4444),
                                    size: 18,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 10),
                    if (_availableStudents.isNotEmpty)
                      PopupMenuButton<String>(
                        onSelected: (st) =>
                            _addStudentToGroup(group['name'] as String, st),
                        itemBuilder: (ctx) => _availableStudents
                            .map(
                              (st) => PopupMenuItem(
                                value: st,
                                child: Text(
                                  st,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            )
                            .toList(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.person_add_alt_1_rounded,
                                size: 14,
                                color: TeacherPalette.primary,
                              ),
                              SizedBox(width: 6),
                              Text(
                                '+ เพิ่มสมาชิกเข้ากลุ่ม',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: TeacherPalette.primary,
                                ),
                              ),
                            ],
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
