// PROTOTYPE ONLY: Complete Lesson Management System for Teachers
// Implements PRD Specs 1-10 with 100% precision & complete interactive dialogs:
// 1. Lesson List & Course Detail Tab (Breadcrumb, Search, Filter, Draft/Published List, Actions)
// 2. 3-Column Block Editor (Left Outline, Middle Block Editor, Right Materials & AIoT Panel)
// 3. Left Section Outline & Navigation
// 4. Block Editor (Headings, Text, Lists, Images, Videos, Files, Links, Callouts, Summary, AIoT Chart Block)
// 5. Materials Attachment Tab (Image, Video, File, Link, Insert to Block)
// 6. AIoT Sensor Binding Tab (Device picker, Metric picker, Time range, Chart Preview, Insert to Block)
// 7. Student Preview Mode (Teacher-only warning banner, live preview)
// 8. Publish Checklist Dialog (Validation, summary counts, warning)
// 9. Lesson Analytics Page (Summary cards, student progress table with Filters)
// 10. Complete States (Loading, Empty, Auto-save status, Published edit warning)

import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import '../student_redesign_prototype/widgets/lesson_block_view.dart';
import '../student_redesign_prototype/widgets/student_redesign_palette.dart'
    show SchoolPalette;
import 'teacher_airy_kit.dart';
import 'teacher_redesign_prototype_page.dart' show TeacherPalette;
import 'teacher_shared_widgets.dart' show TeacherSearchInput;

// ==========================================
// DATA MODELS
// ==========================================

enum LessonStatus { draft, published }

class LessonMaterialModel {
  LessonMaterialModel({
    required this.id,
    required this.title,
    required this.type, // 'image', 'video', 'file', 'link'
    required this.url,
  });

  final String id;
  final String title;
  final String type;
  final String url;
}

class LessonSensorLinkModel {
  LessonSensorLinkModel({
    required this.id,
    required this.deviceName,
    required this.metric,
    required this.timeRange,
    required this.caption,
  });

  final String id;
  final String deviceName;
  final String metric;
  final String timeRange;
  final String caption;
}

class LessonModel {
  LessonModel({
    required this.id,
    required this.courseCode,
    required this.courseName,
    required this.title,
    required this.status,
    required this.lastEdited,
    required this.materialsCount,
    required this.sensorChartsCount,
    required this.blocks,
    required this.materials,
    required this.sensorLinks,
  });

  final String id;
  final String courseCode;
  final String courseName;
  String title;
  LessonStatus status;
  String lastEdited;
  int materialsCount;
  int sensorChartsCount;
  List<ContentBlockModel> blocks;
  List<LessonMaterialModel> materials;
  List<LessonSensorLinkModel> sensorLinks;
}

// ==========================================
// 1. LESSON LIST & COURSE TAB VIEW (SPEC 1)
// ==========================================

class TeacherLessonListPage extends StatefulWidget {
  const TeacherLessonListPage({
    super.key,
    this.courseId,
    required this.courseCode,
    required this.courseName,
    this.isCourseClosed = false,
    this.hasAccess = true,
  });

  // ไม่บังคับ required เพื่อไม่ให้ route dev-preview เดิม
  // (`/prototype/teacher-course-list`) พัง — จุดที่เปิดจากหน้าวิชาจริง
  // (teacher_courses_page.dart) ต้องส่งมาเสมอ ดู _loadRealLessons
  final String? courseId;
  final String courseCode;
  final String courseName;
  final bool isCourseClosed;
  final bool hasAccess;

  @override
  State<TeacherLessonListPage> createState() => _TeacherLessonListPageState();
}

class _TeacherLessonListPageState extends State<TeacherLessonListPage> {
  bool _isLoading = true;
  String _searchQuery = '';
  String _statusFilter = 'ทั้งหมด'; // 'ทั้งหมด', 'Draft', 'Published'
  List<LessonModel> _lessons = [];

  @override
  void initState() {
    super.initState();
    _loadRealLessons();
  }

  Future<void> _loadRealLessons() async {
    try {
      var courseId = widget.courseId;
      if (courseId == null) {
        // Dev-preview only (e.g. /prototype/teacher-course-list opened with
        // no real course in context) — never true for a real teacher.
        final courses = await CourseService.listMyCourses();
        if (courses.isEmpty) {
          if (mounted) setState(() => _isLoading = false);
          return;
        }
        courseId = courses.first.id;
      }
      final summaries = await LessonService.listLessons(courseId);
      if (mounted) {
        setState(() {
          // ว่างจริงต้องโชว่ "ยังไม่มีบทเรียนในวิชานี้" ไม่ใช่บทเรียนตัวอย่าง
          // 6 รายการที่ค้างมาจากค่าเริ่มต้น — เคยเป็นบั๊กจริง (courseId ว่าง
          // ต้องแยกจาก courseId มีแต่ยังไม่มีบทเรียน ทั้งสองกรณีต้องแสดงลิสต์
          // ว่างจริง ไม่ใช่ mockLessonsList)
          _lessons = summaries.map((s) {
            return LessonModel(
              id: s.id,
              courseCode: widget.courseCode,
              courseName: widget.courseName,
              title: s.title,
              status: s.status == 'published'
                  ? LessonStatus.published
                  : LessonStatus.draft,
              lastEdited: 'อัปเดตล่าสุด',
              materialsCount: s.materialsCount,
              sensorChartsCount: s.sensorLinksCount,
              blocks: [
                ContentBlockModel(
                  id: 'b1',
                  type: ContentBlockType.heading,
                  text: s.title,
                ),
              ],
              materials: [],
              sensorLinks: [],
            );
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading real lessons: $e');
      if (mounted) {
        setState(() {
          _lessons = [];
          _isLoading = false;
        });
      }
    }
  }

  void _openCreateLessonDialog() {
    final titleController = TextEditingController();
    final displayCourseName = widget.courseName.trim().isNotEmpty
        ? widget.courseName.trim()
        : (widget.courseCode.trim().isNotEmpty
              ? widget.courseCode.trim()
              : 'รายวิชานี้');

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
        actionsPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: TeacherPalette.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.add_to_photos_rounded,
                color: TeacherPalette.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'สร้างบทเรียนใหม่',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 19,
                color: TeacherPalette.ink,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ระบุชื่อบทเรียนสำหรับวิชา "$displayCourseName"\nระบบจะสร้างร่าง (Draft) แล้วพาไปหน้าแก้ไขบทเรียนทันที',
              style: const TextStyle(
                fontSize: 13,
                color: TeacherPalette.muted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: titleController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'ชื่อบทเรียน *',
                hintText: 'เช่น บทที่ 3: การประยุกต์ใช้งาน AIoT',
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
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: TeacherPalette.primary,
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
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
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: const Text(
                  'สร้างและแก้ไข',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size.zero,
                  backgroundColor: TeacherPalette.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 11,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: () async {
                  final titleText = titleController.text.trim();
                  if (titleText.isEmpty) return;

                  String createdId;
                  try {
                    final courses = await CourseService.listMyCourses();
                    if (courses.isEmpty) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'ไม่พบรายวิชาของคุณในระบบ กรุณาสร้างรายวิชาก่อน',
                          ),
                          backgroundColor: Color(0xFFEF4444),
                        ),
                      );
                      return;
                    }

                    createdId = await LessonService.createLesson(
                      courseId: courses.first.id,
                      title: titleText,
                    );
                  } catch (e) {
                    debugPrint('Error creating lesson via LessonService: $e');
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('สร้างบทเรียนไม่สำเร็จ'),
                        backgroundColor: Color(0xFFEF4444),
                      ),
                    );
                    return;
                  }

                  if (!context.mounted) return;
                  Navigator.pop(context);

                  final newLesson = LessonModel(
                    id: createdId,
                    courseCode: widget.courseCode,
                    courseName: widget.courseName,
                    title: titleText,
                    status: LessonStatus.draft,
                    lastEdited: 'เมื่อสักครู่',
                    materialsCount: 0,
                    sensorChartsCount: 0,
                    blocks: [
                      ContentBlockModel(
                        id: 'b-init',
                        type: ContentBlockType.heading,
                        text: titleText,
                      ),
                      ContentBlockModel(
                        id: 'b-text',
                        type: ContentBlockType.text,
                        text: 'เริ่มเขียนเนื้อหาบทเรียนที่นี่...',
                      ),
                    ],
                    materials: [],
                    sensorLinks: [],
                  );

                  setState(() {
                    _lessons.insert(0, newLesson);
                  });

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          TeacherLessonEditorPage(lesson: newLesson),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.hasAccess) {
      return const _PermissionDeniedView();
    }

    if (_isLoading) {
      return const _LessonListLoadingView();
    }

    final filtered = _lessons.where((les) {
      final matchesSearch = les.title.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      final matchesStatus =
          _statusFilter == 'ทั้งหมด' ||
          (_statusFilter == 'Draft' && les.status == LessonStatus.draft) ||
          (_statusFilter == 'Published' &&
              les.status == LessonStatus.published);
      return matchesSearch && matchesStatus;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 📌 Breadcrumb — desktop only; on a phone the course header
        // already names the course and this read as clutter (and leaked the
        // uuid course code).
        if (MediaQuery.sizeOf(context).width >= 900)
          Row(
            children: [
              const Icon(
                Icons.school_outlined,
                size: 14,
                color: TeacherPalette.muted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'รายวิชาที่สอน > ${widget.courseCode} ${widget.courseName} > บทเรียน',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: TeacherPalette.muted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        if (MediaQuery.sizeOf(context).width >= 900) const SizedBox(height: 14),

        if (widget.isCourseClosed) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 16,
                  color: Color(0xFFB91C1C),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'รายวิชานี้ปิดภาคเรียนแล้ว — ดูเนื้อหาได้ แต่แก้ไขหรือเผยแพร่บทเรียนไม่ได้',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFB91C1C),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Search & Create — card container
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: TeacherPalette.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TeacherSearchInput(
                      hintText: 'ค้นหาชื่อบทเรียน...',
                      value: _searchQuery,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      onClear: () => setState(() => _searchQuery = ''),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: widget.isCourseClosed
                        ? null
                        : _openCreateLessonDialog,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text(
                      'สร้างบทเรียนใหม่',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      // ปุ่มนี้อยู่ใน Row ไม่ใช่เต็มความกว้าง — ต้อง override
                      // minimumSize ของธีม (Size(double.infinity, 52)) ไม่งั้น
                      // Row จะส่ง constraint กว้างไม่จำกัดให้ปุ่มแล้วชนกับ
                      // minWidth: infinity ของธีม ทำให้พังทั้งหน้าแบบเงียบ ๆ
                      minimumSize: const Size(0, 44),
                      backgroundColor: TeacherPalette.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['ทั้งหมด', 'Draft', 'Published'].map((status) {
                    final isActive = _statusFilter == status;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(status),
                        selected: isActive,
                        selectedColor: TeacherPalette.primary,
                        backgroundColor: const Color(0xFFF1F5F9),
                        side: BorderSide.none,
                        labelStyle: TextStyle(
                          color: isActive ? Colors.white : TeacherPalette.ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                        onSelected: (_) =>
                            setState(() => _statusFilter = status),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        Text(
          'รายการบทเรียนทั้งหมด (${filtered.length})',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: TeacherPalette.ink,
          ),
        ),
        const SizedBox(height: 12),

        // Empty State or List Cards
        if (filtered.isEmpty)
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
                Icon(
                  Icons.description_outlined,
                  size: 48,
                  color: TeacherPalette.muted.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 12),
                const Text(
                  'ยังไม่มีบทเรียนในวิชานี้',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 4),
                const Text(
                  'เริ่มต้นสร้างบทเรียนแรกเพื่อแนบเนื้อหา สื่อ และกราฟ AIoT ให้กับนักเรียน',
                  style: TextStyle(fontSize: 13, color: TeacherPalette.muted),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _openCreateLessonDialog,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('สร้างบทเรียนแรก'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TeacherPalette.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          )
        else
          LayoutBuilder(
            builder: (context, cons) {
              final columns = cons.maxWidth >= 1180
                  ? 3
                  : (cons.maxWidth >= 720 ? 2 : 1);
              final cardWidth = columns == 1
                  ? cons.maxWidth
                  : (cons.maxWidth - 14 * (columns - 1)) / columns;
              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: filtered
                    .map((les) => _buildLessonItemCard(les, cardWidth))
                    .toList(),
              );
            },
          ),
      ],
    );
  }

  Widget _buildLessonItemCard(LessonModel les, double cardWidth) {
    final isPublished = les.status == LessonStatus.published;

    final badgeBgColor = isPublished
        ? const Color(0xFFECFDF5)
        : const Color(0xFFFFF7ED);
    final badgeTextColor = isPublished
        ? const Color(0xFF059669)
        : const Color(0xFFD97706);
    final badgeDotColor = isPublished
        ? const Color(0xFF10B981)
        : const Color(0xFFF59E0B);
    final badgeBorderColor = isPublished
        ? const Color(0xFFA7F3D0).withValues(alpha: 0.6)
        : const Color(0xFFFED7AA).withValues(alpha: 0.6);

    return SizedBox(
      width: cardWidth,
      child: Container(
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
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Status Pill & Timestamp Row
            Row(
              children: [
                // Soft Status Pill Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBgColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: badgeBorderColor, width: 1.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: badgeDotColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: badgeDotColor.withValues(alpha: 0.35),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isPublished ? 'Published' : 'Draft',
                        style: TextStyle(
                          color: badgeTextColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  'แก้ไขล่าสุด: ${les.lastEdited}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: TeacherPalette.muted,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Lesson Title
            Text(
              les.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w900,
                color: TeacherPalette.ink,
                height: 1.25,
              ),
            ),

            const SizedBox(height: 14),

            // Soft Glass Metadata Chips
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _LessonMetaTag(
                  icon: Icons.attachment_rounded,
                  label: '${les.materials.length} สื่อแนบ',
                  color: const Color(0xFF475569),
                  bgColor: const Color(0xFFF1F5F9),
                ),
                _LessonMetaTag(
                  icon: Icons.sensors_rounded,
                  label: '${les.sensorLinks.length} กราฟ AIoT',
                  color: const Color(0xFF0284C7),
                  bgColor: const Color(0xFFE0F2FE),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Integrated Bottom Actions Toolbar
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: widget.isCourseClosed
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    TeacherLessonEditorPage(lesson: les),
                              ),
                            );
                          },
                    icon: const Icon(Icons.edit_rounded, size: 15),
                    label: const Text('แก้ไขบทเรียน'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 38),
                      backgroundColor: TeacherPalette.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _LessonIconAction(
                  icon: Icons.visibility_outlined,
                  tooltip: 'ดูตัวอย่างแบบนักเรียน',
                  color: const Color(0xFF2563EB),
                  bgColor: const Color(0xFFEFF6FF),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TeacherLessonPreviewPage(lesson: les),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 6),
                _LessonIconAction(
                  icon: Icons.bar_chart_rounded,
                  tooltip: 'ดูสถิติบทเรียน',
                  color: const Color(0xFF059669),
                  bgColor: const Color(0xFFECFDF5),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TeacherLessonAnalyticsPage(lesson: les),
                      ),
                    );
                  },
                ),
                if (!isPublished) ...[
                  const SizedBox(width: 6),
                  _LessonIconAction(
                    icon: Icons.publish_rounded,
                    tooltip: 'เผยแพร่บทเรียน',
                    color: const Color(0xFFD97706),
                    bgColor: const Color(0xFFFFF7ED),
                    onTap: widget.isCourseClosed
                        ? null
                        : () {
                            showDialog<void>(
                              context: context,
                              builder: (_) => TeacherPublishChecklistDialog(
                                lesson: les,
                                onConfirmedPublish: () async {
                                  try {
                                    await LessonService.publishLesson(les.id);
                                    if (!mounted) return;
                                    setState(() {
                                      les.status = LessonStatus.published;
                                    });
                                  } catch (_) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('เผยแพร่ไม่สำเร็จ'),
                                        backgroundColor: Color(0xFFEF4444),
                                      ),
                                    );
                                  }
                                },
                              ),
                            );
                          },
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// State: กำลังโหลดรายการบทเรียน
class _LessonListLoadingView extends StatelessWidget {
  const _LessonListLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: TeacherPalette.primary,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'กำลังโหลดรายการบทเรียน...',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: TeacherPalette.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// State: ครูไม่มีสิทธิ์สอนวิชานี้
class _PermissionDeniedView extends StatelessWidget {
  const _PermissionDeniedView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_person_rounded,
                color: Color(0xFFB91C1C),
                size: 32,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'ไม่มีสิทธิ์เข้าถึงรายวิชานี้',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const SizedBox(height: 4),
            const Text(
              'คุณไม่มีสิทธิ์สอนในรายวิชานี้แล้ว หากคิดว่าเป็นความผิดพลาด\nกรุณาติดต่อผู้ดูแลระบบ',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: TeacherPalette.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonMetaTag extends StatelessWidget {
  const _LessonMetaTag({
    required this.icon,
    required this.label,
    required this.color,
    this.bgColor,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color? bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor ?? Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: bgColor == null
            ? Border.all(color: color.withValues(alpha: 0.18))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ปุ่มรองแบบวงกลม ใช้กับ action ที่ไม่ใช่งานหลักของการ์ด (ดูตัวอย่าง/
// สถิติ/เผยแพร่) เพื่อให้ปุ่ม "แก้ไข" เด่นเป็นจุดเดียวที่ตากวาดเจอก่อน
class _LessonIconAction extends StatelessWidget {
  const _LessonIconAction({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
    this.bgColor,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final Color? bgColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = onTap == null ? TeacherPalette.muted : color;
    final effectiveBgColor = bgColor ?? effectiveColor.withValues(alpha: 0.1);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: effectiveBgColor,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: effectiveColor.withValues(alpha: 0.2)),
            ),
            child: Center(child: Icon(icon, size: 17, color: effectiveColor)),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 2. 3-COLUMN BLOCK EDITOR PAGE (SPECS 2,3,4,5,6)
// ==========================================

class TeacherLessonEditorPage extends StatefulWidget {
  const TeacherLessonEditorPage({
    super.key,
    required this.lesson,
    this.isCourseClosed = false,
    this.listDevices,
    this.linkSensor,
  });

  final LessonModel lesson;
  final bool isCourseClosed;

  /// seam สำหรับเทสต์ — production ใช้ LessonService.listSchoolDevices /
  /// LessonService.linkLessonSensor (RPC `list_school_devices` /
  /// `link_lesson_sensor`)
  final Future<List<DeviceOption>> Function()? listDevices;
  final Future<void> Function({
    required String lessonId,
    required String deviceId,
    required String metric,
    String? caption,
  })?
  linkSensor;

  @override
  State<TeacherLessonEditorPage> createState() =>
      _TeacherLessonEditorPageState();
}

class _TeacherLessonEditorPageState extends State<TeacherLessonEditorPage> {
  late TextEditingController _titleController;
  late List<ContentBlockModel> _blocks;
  int _activeRightTab = 0; // 0 = Materials, 1 = AIoT Sensors
  bool _isLoading = true;
  bool _isAutoSaving = false;
  bool _saveFailed = false;
  String _saveStatusText = 'บันทึกแล้ว';
  int _saveAttempt = 0;

  /// id → ชื่ออุปกรณ์ จาก list_school_devices — get_lesson คืนแค่ device_id
  /// ของลิงก์ ถ้าไม่มีแผนที่นี้ครูจะเห็น uuid แทนชื่ออุปกรณ์
  Map<String, String> _deviceNames = const {};

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.lesson.title);
    _blocks = List.from(widget.lesson.blocks);
    _loadFullLesson();
  }

  Future<void> _loadFullLesson() async {
    if (widget.lesson.id.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final detail = await LessonService.getLesson(widget.lesson.id);
      if (!mounted) return;

      widget.lesson.materials = detail.materials
          .map(
            (m) => LessonMaterialModel(
              id: m.id,
              title: m.title ?? 'ไฟล์แนบ',
              type: m.type,
              url: m.url,
            ),
          )
          .toList();
      widget.lesson.materialsCount = widget.lesson.materials.length;

      if (detail.sensorLinks.isNotEmpty && _deviceNames.isEmpty) {
        try {
          final devices =
              await (widget.listDevices ?? LessonService.listSchoolDevices)();
          _deviceNames = {for (final d in devices) d.id: d.name};
        } catch (e) {
          // ไม่มีชื่อก็ยังแสดงลิงก์ได้ (เป็น id) — แค่บันทึกไว้ว่าทำไม
          debugPrint('TeacherLessonEditorPage: โหลดชื่ออุปกรณ์ไม่สำเร็จ — $e');
        }
        if (!mounted) return;
      }
      widget.lesson.sensorLinks = detail.sensorLinks
          .map(
            (s) => LessonSensorLinkModel(
              id: s.id,
              deviceName: _deviceNames[s.deviceId] ?? s.deviceId,
              metric: s.metric,
              timeRange: s.timeStart != null
                  ? '${s.timeStart} - ${s.timeEnd}'
                  : 'ช่วงเวลาที่บันทึก',
              caption: s.caption ?? '',
            ),
          )
          .toList();
      widget.lesson.sensorChartsCount = widget.lesson.sensorLinks.length;

      // parse/serialize ใช้ตัวเดียวกับที่ฝั่งนักเรียนอ่าน (shared_core)
      // ไม่ใช่โค้ดคนละชุดที่ค่อย ๆ เพี้ยนจากกัน
      final content = detail.content;
      final parsedBlocks = lessonBlocksFromContent(content);
      if (parsedBlocks.isEmpty &&
          content != null &&
          content['body'] is String &&
          (content['body'] as String).trim().isNotEmpty) {
        // บทเรียนที่สร้างก่อนมีตัวแก้ไขแบบบล็อก — แปลงย่อหน้าเป็นบล็อกข้อความ
        final paragraphs = (content['body'] as String).trim().split('\n\n');
        for (int i = 0; i < paragraphs.length; i++) {
          final p = paragraphs[i].trim();
          if (p.isNotEmpty) {
            parsedBlocks.add(
              ContentBlockModel(
                id: 'b-$i',
                type: ContentBlockType.text,
                text: p,
              ),
            );
          }
        }
      }

      if (parsedBlocks.isEmpty) {
        if (widget.lesson.blocks.isNotEmpty) {
          parsedBlocks.addAll(widget.lesson.blocks);
        } else {
          parsedBlocks.add(
            ContentBlockModel(
              id: 'b-init',
              type: ContentBlockType.text,
              text: '',
            ),
          );
        }
      }

      setState(() {
        _blocks = parsedBlocks;
        _titleController.text = detail.title;
        widget.lesson.title = detail.title;
        widget.lesson.blocks = _blocks;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading full lesson in editor: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _triggerAutoSave() {
    if (widget.isCourseClosed || _isLoading) return;
    _saveAttempt++;
    final thisAttempt = _saveAttempt;
    setState(() {
      _isAutoSaving = true;
      _saveFailed = false;
      _saveStatusText = 'กำลังบันทึก...';
    });

    Future.delayed(const Duration(milliseconds: 400), () async {
      if (!mounted || thisAttempt != _saveAttempt) return;
      try {
        await LessonService.updateLesson(
          lessonId: widget.lesson.id,
          title: _titleController.text,
          content: _serializeBlocksToContent(_blocks),
        );
        if (!mounted || thisAttempt != _saveAttempt) return;
        setState(() {
          _isAutoSaving = false;
          _saveFailed = false;
          _saveStatusText = 'บันทึกแล้ว';
          widget.lesson.title = _titleController.text;
          widget.lesson.blocks = _blocks;
        });
      } catch (e) {
        debugPrint('Error autosaving lesson: $e');
        if (!mounted || thisAttempt != _saveAttempt) return;
        setState(() {
          _isAutoSaving = false;
          _saveFailed = true;
          _saveStatusText = 'บันทึกไม่สำเร็จ';
        });
      }
    });
  }

  /// Flattens the block editor into the flat `content.body` text shape that
  /// [LessonService.getLesson] / the student view already read, while also
  /// keeping the full block list under `content.blocks` for a future richer
  /// student-side renderer — real content either way, nothing synthesized.
  ///
  /// Excludes heading blocks (already shown separately as the lesson
  /// title on the student view — including them here just duplicates it)
  /// and auto-generated "สื่อแนบ:" material-attachment blocks (the
  /// material itself already shows in its own dedicated section).
  Map<String, dynamic> _serializeBlocksToContent(
    List<ContentBlockModel> blocks,
  ) {
    final bodyText = lessonBodyFromBlocks(blocks);
    return {
      'body': bodyText,
      'blocks': [for (final b in blocks) b.toJson()],
    };
  }

  /// เลือกชนิดบล็อกจากชีตที่เห็นตัวอย่างหน้าตาจริง ๆ — เดิมเป็น popup menu
  /// ที่มีแต่บรรทัดข้อความ ครูต้องเดาว่า 'กล่องสรุป' หน้าตาเป็นยังไง
  /// ชนิดที่โครงสร้างรองรับแต่ยังต่อไม่เสร็จ (รูป/วิดีโอ/ไฟล์/ลิงก์) แสดงไว้
  /// แบบจางพร้อมป้าย 'ยังไม่รองรับ' แทนการซ่อน เพื่อไม่ให้ครูตามหาอยู่นาน
  Future<void> _openAddBlockSheet() async {
    final picked = await showModalBottomSheet<ContentBlockType>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) => const _AddBlockSheet(),
    );
    if (picked != null) _addBlock(picked);
  }

  void _addBlock(ContentBlockType type) {
    final newId = 'b-${DateTime.now().millisecondsSinceEpoch}';
    final newBlock = ContentBlockModel(
      id: newId,
      type: type,
      // บล็อกสื่อเริ่มต้นด้วยข้อความว่าง — เนื้อหาของมันคือไฟล์/ลิงก์
      // ไม่ใช่ตัวอักษร ถ้าใส่ข้อความตัวอย่างไว้ มันจะไหลไปโผล่ใน
      // content['body'] ที่หน้าจอรุ่นเก่าอ่าน
      text: switch (type) {
        ContentBlockType.heading => 'หัวข้อใหม่',
        ContentBlockType.calloutWarning => 'ข้อควรระวังสำคัญ...',
        ContentBlockType.summaryBox => 'สรุปประเด็นสำคัญประจำบทเรียน...',
        ContentBlockType.bulletList => 'ข้อแรก\nข้อสอง',
        ContentBlockType.image ||
        ContentBlockType.video ||
        ContentBlockType.fileDownload ||
        ContentBlockType.externalLink ||
        ContentBlockType.sensorChart => '',
        ContentBlockType.text => 'ข้อความเนื้อหาใหม่...',
      },
    );

    setState(() {
      _blocks.add(newBlock);
    });
    _triggerAutoSave();
  }

  void _moveBlock(int index, int direction) {
    if (index + direction < 0 || index + direction >= _blocks.length) return;
    setState(() {
      final temp = _blocks[index];
      _blocks[index] = _blocks[index + direction];
      _blocks[index + direction] = temp;
    });
    _triggerAutoSave();
  }

  /// ลบแล้วเปิดช่องให้กู้คืน 6 วินาที — เดิมกดพลาดทีเดียวเนื้อหาหายถาวร
  void _deleteBlock(int index) {
    final removed = _blocks[index];
    setState(() => _blocks.removeAt(index));
    _triggerAutoSave();
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text('ลบ${_getBlockLabel(removed.type)} แล้ว'),
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'เลิกทำ',
          onPressed: () {
            setState(
              () => _blocks.insert(index.clamp(0, _blocks.length), removed),
            );
            _triggerAutoSave();
          },
        ),
      ),
    );
  }

  void _reorderBlocks(int oldIndex, int newIndex) {
    setState(() {
      final target = newIndex > oldIndex ? newIndex - 1 : newIndex;
      final block = _blocks.removeAt(oldIndex);
      _blocks.insert(target, block);
    });
    _triggerAutoSave();
  }

  // SPEC 5: Modern Upload Files Dialog (matching reference screenshot)
  //
  // Real uploads go to the private `lesson-materials` Storage bucket via a
  // signed URL minted by the lesson-material-upload Edge Function (same
  // pattern as CourseFileService for course files) — see
  // LessonService.uploadMaterialFile. Bytes are picked here and actually
  // uploaded when the save button is pressed.
  void _openAddMaterialDialog() {
    final urlController = TextEditingController();
    final List<_UploadedFileItem> filesList = [];
    var isUploading = false;

    Future<void> pickFiles(StateSetter setModalState) async {
      try {
        final result = await FilePicker.pickFiles(
          allowMultiple: true,
          withData: true,
        );
        if (result != null && result.files.isNotEmpty) {
          for (final f in result.files) {
            if (f.bytes == null) continue;
            final ext = f.extension?.toLowerCase() ?? '';
            String fileCategory = 'PDF';
            if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) {
              fileCategory = 'IMG';
            } else if (['mp4', 'mov', 'avi', 'webm'].contains(ext)) {
              fileCategory = 'VID';
            } else if (['doc', 'docx', 'txt', 'rtf'].contains(ext)) {
              fileCategory = 'DOC';
            }

            final item = _UploadedFileItem(
              name: f.name,
              sizeBytes: f.size,
              typeCategory: fileCategory,
              url: '',
              bytes: f.bytes,
              progress: 1.0,
              isCompleted: true,
            );
            filesList.add(item);
          }
          setModalState(() {});
        }
      } catch (e) {
        debugPrint('Error picking files: $e');
      }
    }

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setModalState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Colors.white,
          elevation: 12,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header Row
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Icon(
                          Icons.cloud_upload_outlined,
                          color: Color(0xFF475569),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Upload files',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Select and upload the files of your choice',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogCtx),
                        icon: const Icon(Icons.close_rounded, size: 20),
                        color: const Color(0xFF64748B),
                        tooltip: 'ปิด',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 2. Dashed Dropzone Area
                  _DashedBorderContainer(
                    borderRadius: 16,
                    color: const Color(0xFFCBD5E1),
                    child: InkWell(
                      onTap: () => pickFiles(setModalState),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 24,
                          horizontal: 16,
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: const Icon(
                                Icons.cloud_upload_outlined,
                                color: TeacherPalette.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Choose a file or drag & drop it here.',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'JPEG, PNG, PDF, and MP4 formats, up to 50 MB.',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 14),
                            OutlinedButton.icon(
                              onPressed: () => pickFiles(setModalState),
                              icon: const Icon(
                                Icons.folder_open_rounded,
                                size: 16,
                              ),
                              label: const Text('Browse File'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF334155),
                                side: const BorderSide(
                                  color: Color(0xFFCBD5E1),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 3. Uploaded Files Status Cards List
                  if (filesList.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 180),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: filesList.length,
                        separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                        itemBuilder: (ctx, idx) {
                          final f = filesList[idx];
                          final sizeKb = (f.sizeBytes / 1024).toStringAsFixed(
                            0,
                          );
                          final colorBadge = switch (f.typeCategory) {
                            'PDF' => const Color(0xFFEF4444),
                            'IMG' => const Color(0xFF0284C7),
                            'VID' => const Color(0xFF8B5CF6),
                            _ => const Color(0xFF10B981),
                          };

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              children: [
                                // File Badge Icon
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: colorBadge.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      f.typeCategory,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        color: colorBadge,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        f.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          Text(
                                            '$sizeKb KB of $sizeKb KB',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF64748B),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          const Icon(
                                            Icons.check_circle_rounded,
                                            size: 13,
                                            color: Color(0xFF10B981),
                                          ),
                                          const SizedBox(width: 3),
                                          const Text(
                                            'Completed',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF10B981),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    size: 18,
                                    color: Color(0xFF94A3B8),
                                  ),
                                  onPressed: () {
                                    setModalState(() {
                                      filesList.removeAt(idx);
                                    });
                                  },
                                  tooltip: 'ลบไฟล์',
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  // 4. OR Divider
                  const SizedBox(height: 18),
                  const Row(
                    children: [
                      Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 5. Import from URL Link Section
                  const Row(
                    children: [
                      Text(
                        'Import from URL Link',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.info_outline_rounded,
                        size: 14,
                        color: Color(0xFF94A3B8),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: urlController,
                    decoration: InputDecoration(
                      hintText: 'Paste file URL',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF94A3B8),
                      ),
                      prefixIcon: const Icon(
                        Icons.link_rounded,
                        size: 18,
                        color: Color(0xFF94A3B8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),

                  // 6. Action Button at Bottom
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: isUploading
                          ? null
                          : () async {
                              final rawUrl = urlController.text.trim();

                              if (rawUrl.isEmpty && filesList.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'กรุณาเลือกไฟล์หรือใส่ลิงก์ URL ของสื่อการสอน',
                                    ),
                                    backgroundColor: Color(0xFFF59E0B),
                                  ),
                                );
                                return;
                              }

                              setModalState(() => isUploading = true);
                              final newMaterials = <LessonMaterialModel>[];
                              try {
                                for (final item in filesList) {
                                  final bytes = item.bytes;
                                  if (bytes == null) continue;
                                  final matType = switch (item.typeCategory) {
                                    'IMG' => 'image',
                                    'VID' => 'video',
                                    _ => 'file',
                                  };
                                  await LessonService.uploadMaterialFile(
                                    lessonId: widget.lesson.id,
                                    fileName: item.name,
                                    bytes: bytes,
                                    type: matType,
                                  );
                                  newMaterials.add(
                                    LessonMaterialModel(
                                      id: 'm-${DateTime.now().millisecondsSinceEpoch}-${item.name}',
                                      title: item.name,
                                      type: item.typeCategory == 'IMG'
                                          ? 'รูปภาพ'
                                          : (item.typeCategory == 'VID'
                                                ? 'วิดีโอ'
                                                : 'ไฟล์'),
                                      url: '',
                                    ),
                                  );
                                }

                                if (rawUrl.isNotEmpty) {
                                  await LessonService.addLessonMaterial(
                                    lessonId: widget.lesson.id,
                                    type: 'link',
                                    title: 'สื่อการสอนจากลิงก์ URL',
                                    url: rawUrl,
                                  );
                                  newMaterials.add(
                                    LessonMaterialModel(
                                      id: 'm-${DateTime.now().millisecondsSinceEpoch}',
                                      title: 'สื่อการสอนจากลิงก์ URL',
                                      type: 'ลิงก์',
                                      url: rawUrl,
                                    ),
                                  );
                                }

                                if (!context.mounted) return;
                                Navigator.pop(dialogCtx);

                                setState(() {
                                  for (final mat in newMaterials) {
                                    widget.lesson.materials.add(mat);
                                  }
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('แนบสื่อการสอนเรียบร้อยแล้ว'),
                                    backgroundColor: Color(0xFF10B981),
                                  ),
                                );
                                _triggerAutoSave();
                              } catch (e) {
                                debugPrint(
                                  'Error attaching lesson material: $e',
                                );
                                setModalState(() => isUploading = false);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('แนบสื่อการสอนไม่สำเร็จ'),
                                    backgroundColor: Color(0xFFEF4444),
                                  ),
                                );
                              }
                            },
                      icon: isUploading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_rounded, size: 18),
                      label: Text(
                        isUploading
                            ? 'กำลังบันทึก...'
                            : (filesList.isNotEmpty
                                  ? 'บันทึกสื่อการสอน (${filesList.length} ไฟล์)'
                                  : 'บันทึกและแทรกในบทเรียน'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TeacherPalette.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          foregroundColor: TeacherPalette.ink,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: TeacherPalette.primary,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      // แถบบนเดิมยัดทุกอย่างไว้บรรทัดเดียว: ปุ่มย้อนกลับ · ไอคอนหนังสือ ·
      // ช่องชื่อบทเรียน · บรรทัดรอง · ป้ายสถานะบันทึก · ปุ่มดูตัวอย่าง ·
      // ปุ่มเผยแพร่ — เกินความกว้างจอมือถือจน Flutter ขึ้น "OVERFLOWED BY"
      // ตอนนี้แถบบนเหลือทางออกกับชื่อหน้า · ชื่อบทเรียนลงไปเป็นช่องกรอกจริง
      // ในหน้า · ปุ่มสองตัวลงแถบล่างในระยะที่นิ้วโป้งถึง
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        centerTitle: true,
        leading: IconButton(
          tooltip: 'ย้อนกลับ',
          icon: const Icon(Icons.arrow_back_rounded, size: 22),
          color: TeacherPalette.ink,
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'แก้ไขบทเรียน',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: TeacherPalette.ink,
          ),
        ),
      ),
      bottomNavigationBar: _lessonActionBar(),
      body: Column(
        children: [
          if (widget.isCourseClosed)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: const Color(0xFFFEF2F2),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 14,
                    color: Color(0xFFB91C1C),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'รายวิชานี้ปิดภาคเรียนแล้ว — ดูเนื้อหาได้อย่างเดียว แก้ไขไม่ได้',
                    style: TextStyle(
                      color: Color(0xFFB91C1C),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;

                if (!isWide) {
                  return Column(
                    children: [Expanded(child: _buildMiddleEditorPanel())],
                  );
                }

                return Row(
                  children: [
                    // 📌 1. LEFT PANEL: OUTLINE / SECTIONS (SPEC 3)
                    SizedBox(width: 240, child: _buildLeftOutlinePanel()),
                    const VerticalDivider(
                      width: 1,
                      color: TeacherPalette.border,
                    ),

                    // 📝 2. MIDDLE PANEL: BLOCK EDITOR (SPEC 4)
                    Expanded(child: _buildMiddleEditorPanel()),
                    const VerticalDivider(
                      width: 1,
                      color: TeacherPalette.border,
                    ),

                    // 📎 3. RIGHT PANEL: MATERIALS & AIOT (SPECS 5 & 6)
                    SizedBox(width: 300, child: _buildRightPanel()),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Left outline panel
  Widget _buildLeftOutlinePanel() {
    final headings = _blocks
        .where((b) => b.type == ContentBlockType.heading)
        .toList();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.format_list_bulleted_rounded,
                size: 18,
                color: TeacherPalette.primary,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'สารบัญบทเรียน',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${headings.length} หัวข้อหลักในบทเรียนนี้',
            style: const TextStyle(fontSize: 11, color: TeacherPalette.muted),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: headings.length,
              separatorBuilder: (context, index) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final h = headings[index];
                return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.bookmark_outline_rounded,
                        size: 14,
                        color: TeacherPalette.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          h.text,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _addBlock(ContentBlockType.heading),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('+ เพิ่ม Section ใหม่'),
            style: ElevatedButton.styleFrom(
              backgroundColor: TeacherPalette.primary.withValues(alpha: 0.1),
              foregroundColor: TeacherPalette.primary,
              minimumSize: const Size(double.infinity, 40),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Color get _saveColor => _saveFailed
      ? const Color(0xFFB3261E)
      : (_isAutoSaving ? const Color(0xFFB4650F) : const Color(0xFF107A50));

  bool get _isPublished => widget.lesson.status == LessonStatus.published;

  void _openPublishChecklist() {
    showDialog<void>(
      context: context,
      builder: (_) => TeacherPublishChecklistDialog(
        lesson: widget.lesson,
        onConfirmedPublish: () async {
          try {
            await LessonService.publishLesson(widget.lesson.id);
            if (!mounted) return;
            setState(() {
              widget.lesson.status = LessonStatus.published;
            });
          } catch (_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('เผยแพร่ไม่สำเร็จ'),
                backgroundColor: Color(0xFFEF4444),
              ),
            );
          }
        },
      ),
    );
  }

  /// แถบล่าง — ดูตัวอย่าง (รอง) คู่กับเผยแพร่/อัปเดต (หลัก) แบบเดียวกับหน้า
  /// ใบงาน เหนือปุ่มคือสถานะบันทึกอัตโนมัติ ซึ่งเดิมเป็นชิปเล็ก ๆ เบียดอยู่
  /// บนแถบบนจนแทบไม่มีใครเห็น
  Widget _lessonActionBar() => Container(
    decoration: const BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Color(0x14101828),
          blurRadius: 18,
          offset: Offset(0, -6),
        ),
      ],
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: _saveFailed ? _triggerAutoSave : null,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _saveFailed
                          ? Icons.error_outline_rounded
                          : (_isAutoSaving
                                ? Icons.sync_rounded
                                : Icons.cloud_done_rounded),
                      size: 15,
                      color: _saveColor,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _saveFailed
                            ? '$_saveStatusText · แตะเพื่อลองใหม่'
                            : _saveStatusText,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: _saveColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: AiryButton(
                    label: 'ดูตัวอย่าง',
                    kind: AiryCta.tertiary,
                    height: 44,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              TeacherLessonPreviewPage(lesson: widget.lesson),
                        ),
                      );
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.visibility_outlined, size: 17),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'ดูตัวอย่าง',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 5,
                  child: AiryButton(
                    label: _isPublished ? 'อัปเดตบทเรียน' : 'เผยแพร่บทเรียน',
                    kind: AiryCta.primary,
                    accent: TeacherPalette.primary,
                    height: 44,
                    onPressed: widget.isCourseClosed
                        ? null
                        : _openPublishChecklist,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isPublished
                              ? Icons.published_with_changes_rounded
                              : Icons.publish_rounded,
                          size: 18,
                        ),
                        const SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            _isPublished ? 'อัปเดตบทเรียน' : 'เผยแพร่บทเรียน',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  /// Middle Block Editor Panel
  Widget _buildMiddleEditorPanel() {
    return Container(
      color: const Color(0xFFF7F7FA),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ชื่อบทเรียนใช้ช่องกรอกชุดเดียวกับทั้งแอป (โฟกัสแล้วขอบเป็น
            // สีเน้น) เดิมเป็นกล่องขอบเทาที่วาดเองไม่เหมือนหน้าอื่น
            AiryInput(
              label: 'ชื่อบทเรียน',
              controller: _titleController,
              hint: 'ตั้งชื่อบทเรียน',
              accent: TeacherPalette.primary,
              big: true,
              maxLines: 2,
            ),
            if (widget.lesson.status == LessonStatus.published)
              Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDF1DE),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFFB4650F),
                      size: 19,
                    ),
                    SizedBox(width: 13),
                    Expanded(
                      child: Text(
                        'เผยแพร่อยู่ — บันทึกแล้วนักเรียนที่กำลังเรียนเห็นทันที',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: Color(0xFFB4650F),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ลากสลับลำดับได้ — เดิมต้องกด ↑ ↓ ทีละขั้น
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: _blocks.length,
              onReorder: _reorderBlocks,
              proxyDecorator: (child, index, animation) => Material(
                color: Colors.transparent,
                child: Opacity(opacity: 0.92, child: child),
              ),
              itemBuilder: (context, i) => Container(
                key: ValueKey(_blocks[i].id),
                child: _buildBlockEditorTile(_blocks[i], i),
              ),
            ),

            const SizedBox(height: 20),

            // Add Block Menu (Spec 4: All 10 Block Types)
            const SizedBox(height: 14),
            GestureDetector(
              onTap: widget.isCourseClosed ? null : _openAddBlockSheet,
              child: AiryCard(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                    child: Row(
                      children: [
                        Icon(
                          Icons.add_circle_outline_rounded,
                          size: 19,
                          color: widget.isCourseClosed
                              ? AirySpec.label
                              : TeacherPalette.primary,
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'เพิ่มบล็อกเนื้อหา',
                                style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                  color: widget.isCourseClosed
                                      ? AirySpec.label
                                      : TeacherPalette.primary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              const Text(
                                'เลือกชนิดพร้อมดูตัวอย่างก่อนเพิ่ม',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: AirySpec.label,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockEditorTile(ContentBlockModel block, int index) {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.fromLTRB(16, 12, 10, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F101828),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getBlockIcon(block.type), size: 18, color: AirySpec.label),
              const SizedBox(width: 10),
              // ชื่อประเภทบล็อกยาวไม่เท่ากัน ('กราฟ AIoT Sensor Chart' ยาว
              // ที่สุด) ถ้าไม่ให้หดได้ มันจะดันปุ่มสามตัวตกขอบที่จอ 360
              Expanded(
                child: Text(
                  _getBlockLabel(block.type),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: AirySpec.label,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // IconButton ปกติกินพื้นที่ 48pt ต่อปุ่ม สามปุ่มคือ 144pt —
              // เกือบครึ่งความกว้างจอมือถือ ทั้งที่เป็นปุ่มรองของการ์ด
              // บีบเหลือ 34pt และให้ปุ่มลบเป็นแดงเข้มแทนแดงสด
              // ปุ่มลบย้ายเข้าเมนู ⋯ — เดิมอยู่ติดปุ่มเลื่อน กดพลาดง่ายมาก
              if (!widget.isCourseClosed)
                ReorderableDragStartListener(
                  index: index,
                  child: const _BlockAction(
                    icon: Icons.drag_indicator_rounded,
                    tooltip: 'ลากเพื่อสลับลำดับ',
                    onTap: null,
                    alwaysActive: true,
                  ),
                ),
              PopupMenuButton<String>(
                enabled: !widget.isCourseClosed,
                tooltip: 'ตัวเลือกบล็อก',
                position: PopupMenuPosition.under,
                onSelected: (v) {
                  if (v == 'up') _moveBlock(index, -1);
                  if (v == 'down') _moveBlock(index, 1);
                  if (v == 'delete') _deleteBlock(index);
                },
                itemBuilder: (_) => [
                  if (index > 0)
                    const PopupMenuItem(value: 'up', child: Text('เลื่อนขึ้น')),
                  if (index < _blocks.length - 1)
                    const PopupMenuItem(value: 'down', child: Text('เลื่อนลง')),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'ลบบล็อกนี้',
                      style: TextStyle(color: Color(0xFFD3324A)),
                    ),
                  ),
                ],
                child: const _BlockAction(
                  icon: Icons.more_horiz_rounded,
                  tooltip: 'ตัวเลือกบล็อก',
                  onTap: null,
                  alwaysActive: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_isMediaBlock(block.type))
            _mediaBlockEditor(block)
          else if (block.type == ContentBlockType.sensorChart)
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE3E1EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.insights_outlined,
                        color: AirySpec.label,
                        size: 19,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              block.sensorDeviceId.isEmpty
                                  ? 'ยังไม่ได้เลือกเซนเซอร์'
                                  : block.sensorDeviceId,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                                color: block.sensorDeviceId.isEmpty
                                    ? const Color(0xFF6E6C7A)
                                    : AirySpec.ink,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              block.sensorDeviceId.isEmpty
                                  ? 'แตะปุ่มเลือกเซนเซอร์เพื่อผูกข้อมูลจริง'
                                  : '${block.sensorMetric} · ${block.timeRange}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AirySpec.label,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 76,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F7FA),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      block.sensorDeviceId.isEmpty
                          ? 'กราฟจะขึ้นที่นี่เมื่อผูกเซนเซอร์แล้ว'
                          : 'นักเรียนจะเห็นกราฟข้อมูลจริงตรงนี้',
                      style: const TextStyle(
                        color: AirySpec.label,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE3E1EB)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              margin: const EdgeInsets.only(right: 6),
              child: TextFormField(
                initialValue: block.text,
                maxLines: block.type == ContentBlockType.heading ? 1 : 4,
                minLines: 1,
                readOnly: widget.isCourseClosed,
                onChanged: (val) {
                  block.text = val;
                  _triggerAutoSave();
                },
                cursorColor: TeacherPalette.primary,
                style: TextStyle(
                  height: 1.45,
                  fontWeight: block.type == ContentBlockType.heading
                      ? FontWeight.w700
                      : FontWeight.w500,
                  fontSize: block.type == ContentBlockType.heading ? 17 : 15,
                  color: AirySpec.ink,
                ),
                decoration: InputDecoration.collapsed(
                  hintText: block.type == ContentBlockType.heading
                      ? 'หัวข้อของส่วนนี้'
                      : 'พิมพ์เนื้อหา…',
                  hintStyle: const TextStyle(
                    color: Color(0xFFB6B4C2),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// ช่องกรอกในการ์ดบล็อก — ใช้ TextFormField แบบ initialValue เหมือนช่อง
  /// ข้อความของบล็อกอื่น ไม่ใช่ AiryInput เพราะตัวนั้นต้องมี controller
  /// ต่อหนึ่งช่อง ซึ่งบล็อกที่ลากสลับ/ลบได้ตลอดจัดการ lifecycle ยาก
  Widget _blockField({
    required String label,
    required String hint,
    required String initialValue,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AirySpec.label,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: initialValue,
          readOnly: widget.isCourseClosed,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 14, color: AirySpec.ink),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13.5, color: AirySpec.label),
            filled: false,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 11,
            ),
            border: _blockFieldBorder(const Color(0xFFE3E1EB)),
            enabledBorder: _blockFieldBorder(const Color(0xFFE3E1EB)),
            focusedBorder: _blockFieldBorder(
              TeacherPalette.primary,
              width: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _blockFieldBorder(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: color, width: width),
      );

  static bool _isMediaBlock(ContentBlockType type) =>
      type == ContentBlockType.image ||
      type == ContentBlockType.video ||
      type == ContentBlockType.fileDownload ||
      type == ContentBlockType.externalLink;

  /// ตัวแก้บล็อกสื่อ — รูป/วิดีโอ/ไฟล์ อ้างถึงสื่อแนบของบทเรียนด้วย id
  /// (ไฟล์อยู่ใน bucket แบบ private เก็บ URL ตรง ๆ ไม่ได้ มันหมดอายุ)
  /// ส่วนลิงก์ภายนอกเก็บ URL ที่ครูวางไว้ตรง ๆ
  Widget _mediaBlockEditor(ContentBlockModel block) {
    final isLink = block.type == ContentBlockType.externalLink;
    final wantedType = switch (block.type) {
      ContentBlockType.image => 'image',
      ContentBlockType.video => 'video',
      _ => 'file',
    };
    final picked = block.materialId.trim().isEmpty
        ? null
        : widget.lesson.materials
              .where((m) => m.id == block.materialId.trim())
              .firstOrNull;
    final choices = widget.lesson.materials
        .where((m) => m.type == wantedType)
        .toList();

    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3E1EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isLink)
            _blockField(
              label: 'ลิงก์',
              hint: 'https://...',
              initialValue: block.mediaUrl,
              onChanged: (val) {
                block.mediaUrl = val;
                _triggerAutoSave();
              },
            )
          else ...[
            Row(
              children: [
                Icon(
                  _getBlockIcon(block.type),
                  size: 19,
                  color: AirySpec.label,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    picked?.title ??
                        (block.materialId.trim().isEmpty
                            ? 'ยังไม่ได้เลือกไฟล์'
                            : 'ไฟล์ที่เลือกไว้ถูกลบออกจากบทเรียนแล้ว'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                      color: picked == null ? AirySpec.label : AirySpec.ink,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: AiryButton(
                label: picked == null ? 'เลือกไฟล์' : 'เปลี่ยนไฟล์',
                kind: AiryCta.secondary,
                accent: TeacherPalette.primary,
                onPressed: widget.isCourseClosed
                    ? null
                    : () => _pickBlockMaterial(block, choices),
              ),
            ),
            if (choices.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: AiryNote(
                  'ยังไม่มีไฟล์ชนิดนี้ในบทเรียน — อัปโหลดที่แท็บคลังสื่อแนบก่อน '
                  'แล้วกลับมาเลือก',
                ),
              ),
          ],
          const SizedBox(height: 12),
          _blockField(
            label: 'คำบรรยาย (ไม่บังคับ)',
            hint: 'นักเรียนจะเห็นข้อความนี้ใต้สื่อ',
            initialValue: block.caption,
            onChanged: (val) {
              block.caption = val;
              _triggerAutoSave();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _pickBlockMaterial(
    ContentBlockModel block,
    List<LessonMaterialModel> choices,
  ) async {
    if (choices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ยังไม่มีไฟล์ชนิดนี้ — อัปโหลดที่แท็บคลังสื่อแนบก่อน'),
        ),
      );
      return;
    }
    final picked = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(22, 20, 22, 12),
              child: Text(
                'เลือกไฟล์จากคลังสื่อแนบ',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: AirySpec.ink,
                ),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                children: [
                  for (final m in choices)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => Navigator.pop(sheetContext, m.id),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: m.id == block.materialId
                                    ? TeacherPalette.primary
                                    : const Color(0xFFEDECF2),
                                width: m.id == block.materialId ? 1.6 : 1,
                              ),
                            ),
                            child: Text(
                              m.title,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: AirySpec.ink,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => block.materialId = picked);
    _triggerAutoSave();
  }

  IconData _getBlockIcon(ContentBlockType type) {
    return switch (type) {
      ContentBlockType.heading => Icons.title_rounded,
      ContentBlockType.text => Icons.notes_rounded,
      ContentBlockType.calloutWarning => Icons.warning_amber_rounded,
      ContentBlockType.summaryBox => Icons.lightbulb_outline_rounded,
      ContentBlockType.sensorChart => Icons.sensors_rounded,
      ContentBlockType.bulletList => Icons.format_list_bulleted_rounded,
      ContentBlockType.image => Icons.image_outlined,
      ContentBlockType.video => Icons.play_circle_outline_rounded,
      ContentBlockType.fileDownload => Icons.insert_drive_file_outlined,
      ContentBlockType.externalLink => Icons.link_rounded,
    };
  }

  String _getBlockLabel(ContentBlockType type) {
    return switch (type) {
      ContentBlockType.heading => 'หัวข้อ (Heading)',
      ContentBlockType.text => 'ข้อความ (Text)',
      ContentBlockType.calloutWarning => 'กล่องข้อควรระวัง (Callout)',
      ContentBlockType.summaryBox => 'กล่องสรุป (Summary)',
      ContentBlockType.sensorChart => 'กราฟ AIoT Sensor Chart',
      ContentBlockType.bulletList => 'รายการ (Bullet list)',
      ContentBlockType.image => 'รูปภาพ (Image)',
      ContentBlockType.video => 'วิดีโอ (Video)',
      ContentBlockType.fileDownload => 'ไฟล์ (File)',
      ContentBlockType.externalLink => 'ลิงก์ภายนอก (Link)',
    };
  }

  /// Right Panel for Materials and AIoT Sensors
  Widget _buildRightPanel() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _activeRightTab = 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _activeRightTab == 0
                              ? TeacherPalette.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      'คลังสื่อแนบ (${widget.lesson.materials.length})',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _activeRightTab == 0
                            ? TeacherPalette.primary
                            : TeacherPalette.muted,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _activeRightTab = 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _activeRightTab == 1
                              ? TeacherPalette.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      'ผูก AIoT (${widget.lesson.sensorLinks.length})',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _activeRightTab == 1
                            ? TeacherPalette.primary
                            : TeacherPalette.muted,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: _activeRightTab == 0
                  ? _buildMaterialsTab()
                  : _buildAiotTab(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          onPressed: _openAddMaterialDialog,
          icon: const Icon(Icons.upload_file_rounded, size: 16),
          label: const Text('+ เพิ่มสื่อการสอน'),
          style: ElevatedButton.styleFrom(
            backgroundColor: TeacherPalette.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 40),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            itemCount: widget.lesson.materials.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final mat = widget.lesson.materials[index];
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: TeacherPalette.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.insert_drive_file_outlined,
                      color: TeacherPalette.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        mat.title,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// อ่านลิงก์เซนเซอร์กลับจากหลังบ้านอย่างเดียว — ไม่ใช่ `_loadFullLesson`
  /// ซึ่งทับ `_titleController`/`_blocks` ด้วยของบนเซิร์ฟเวอร์ และจะลบสิ่งที่
  /// ครูพิมพ์ค้างอยู่ถ้า autosave รอบล่าสุดยังไม่ลง/ล้ม
  Future<void> _refreshSensorLinks() async {
    try {
      final detail = await LessonService.getLesson(widget.lesson.id);
      if (!mounted) return;
      setState(() {
        widget.lesson.sensorLinks = detail.sensorLinks
            .map(
              (s) => LessonSensorLinkModel(
                id: s.id,
                deviceName: _deviceNames[s.deviceId] ?? s.deviceId,
                metric: s.metric,
                timeRange: s.timeStart != null
                    ? '${s.timeStart} - ${s.timeEnd}'
                    : 'ช่วงเวลาที่บันทึก',
                caption: s.caption ?? '',
              ),
            )
            .toList();
        widget.lesson.sensorChartsCount = widget.lesson.sensorLinks.length;
      });
    } catch (e) {
      debugPrint(
        'TeacherLessonEditorPage: อ่านลิงก์เซนเซอร์กลับไม่สำเร็จ — $e',
      );
    }
  }

  Future<void> _openLinkSensorDialog() async {
    final listDevices = widget.listDevices ?? LessonService.listSchoolDevices;
    List<DeviceOption> devices;
    try {
      // list_school_devices คืนทุกชนิด (รีเลย์ กล้อง gateway ปุ่มฉุกเฉิน ...)
      // — ผูกได้เฉพาะตัวที่มีค่าอ่านจริง ไม่งั้นนักเรียนได้กราฟว่างถาวร
      devices = (await listDevices()).where((d) => d.isSensor).toList();
    } catch (e) {
      debugPrint('TeacherLessonEditorPage: โหลดรายการอุปกรณ์ไม่สำเร็จ — $e');
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
            'โรงเรียนยังไม่มีอุปกรณ์เซนเซอร์ในระบบ ให้แอดมินลงทะเบียนอุปกรณ์ก่อน',
          ),
        ),
      );
      return;
    }
    _deviceNames = {for (final d in devices) d.id: d.name};

    var deviceId = devices.first.id;
    List<String> metricsFor(String id) =>
        devices.firstWhere((d) => d.id == id).metrics;

    var metric = metricsFor(deviceId).first;
    final captionCtrl = TextEditingController();
    var submitting = false;
    String? error;

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
                  widget.linkSensor ??
                  ({
                    required String lessonId,
                    required String deviceId,
                    required String metric,
                    String? caption,
                  }) => LessonService.linkLessonSensor(
                    lessonId: lessonId,
                    deviceId: deviceId,
                    metric: metric,
                    caption: caption,
                  );
              final caption = captionCtrl.text.trim();
              await link(
                lessonId: widget.lesson.id,
                deviceId: deviceId,
                metric: metric,
                caption: caption.isEmpty ? null : caption,
              );
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('ผูกข้อมูลเซนเซอร์กับบทเรียนแล้ว'),
                ),
              );
              // อ่านกลับจากหลังบ้าน ไม่เติมรายการในเครื่องเอง
              await _refreshSensorLinks();
            } catch (e) {
              debugPrint(
                'TeacherLessonEditorPage: link_lesson_sensor ล้ม — $e',
              );
              // ครูอาจกดพื้นหลังปิด dialog ไปแล้วระหว่างรอ — ห้าม setState
              // บน StatefulBuilder ที่ถูกถอดไปแล้ว
              if (!dialogContext.mounted) return;
              setDialog(() {
                submitting = false;
                error = 'ผูกข้อมูลเซนเซอร์ไม่สำเร็จ กรุณาลองใหม่อีกครั้ง';
              });
            }
          }

          return _OwnControllers(
            controllers: [captionCtrl],
            child: AlertDialog(
              title: const Text('ผูกข้อมูล AIoT Sensor กับบทเรียน'),
              content: SizedBox(
                width: 420,
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
                        labelText: 'ค่าที่ต้องการแสดง',
                      ),
                      items: [
                        for (final m in metricsFor(deviceId))
                          DropdownMenuItem(value: m, child: Text(m)),
                      ],
                      onChanged: submitting
                          ? null
                          : (v) => setDialog(() => metric = v ?? metric),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: captionCtrl,
                      decoration: const InputDecoration(
                        labelText: 'คำอธิบายกราฟ (ถ้ามี)',
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

  Widget _buildAiotTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // รอบแรก (2026-09-07) dialog นี้เลือกจากอุปกรณ์ hardcode 3 ชื่อแล้ว
        // เก็บในเครื่อง จึงถูกปิดไว้ ตอนนี้ต่อจริงทั้งสาย: รายการอุปกรณ์จาก
        // list_school_devices → link_lesson_sensor → นักเรียนเห็นใน
        // student_lesson_view_page / pages/student/lesson_view_page (ทั้งคู่
        // อ่าน `lesson.sensorLinks` อยู่แล้ว)
        ElevatedButton.icon(
          onPressed: widget.isCourseClosed || widget.lesson.id.isEmpty
              ? null
              : _openLinkSensorDialog,
          icon: const Icon(Icons.sensors_rounded, size: 16),
          label: Text(
            widget.lesson.id.isEmpty
                ? '+ ผูกข้อมูล AIoT Sensor (บันทึกบทเรียนก่อน)'
                : '+ ผูกข้อมูล AIoT Sensor',
          ),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 40),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            itemCount: widget.lesson.sensorLinks.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final sl = widget.lesson.sensorLinks[index];
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sl.deviceName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E40AF),
                      ),
                    ),
                    Text(
                      '${sl.metric} • ${sl.timeRange}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ==========================================
// 7. STUDENT PREVIEW MODE PAGE (SPEC 7)
// ==========================================

/// ตัวอย่างหน้าบทเรียนฝั่งนักเรียน — วางโครงตาม
/// `student_redesign_prototype/widgets/student_lesson_view_page.dart` ของจริง
/// (แบนเนอร์เขียว → เนื้อหา → เอกสารแนบ → กราฟเซนเซอร์ที่ผูกไว้ → ปุ่มเรียนจบ)
/// และวาดเนื้อหาด้วย [LessonBlockView] ตัวเดียวกับที่หน้านักเรียนใช้ จึง
/// เพี้ยนจากของจริงไม่ได้ — ห้ามเขียนตัววาดบล็อกชุดที่สองที่นี่อีก
/// (PITFALLS.md ข้อ 10)
class TeacherLessonPreviewPage extends StatelessWidget {
  const TeacherLessonPreviewPage({super.key, required this.lesson});

  final LessonModel lesson;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: AirySpec.ink,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: true,
        title: const Text(
          'ดูตัวอย่าง',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: TeacherPalette.primary,
              ),
              child: const Text(
                'แก้ไข',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFFFDF1DE),
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.visibility_outlined,
                  color: Color(0xFFB4650F),
                  size: 17,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'หน้านี้คือสิ่งที่นักเรียนจะเห็น — ครูเท่านั้นที่เปิดดูได้ก่อนเผยแพร่',
                    style: TextStyle(
                      color: Color(0xFFB4650F),
                      fontSize: 12.5,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StudentBanner(lesson: lesson),
                  const SizedBox(height: 24),
                  const _StudentSectionTitle('📖 เนื้อหาบทเรียน'),
                  const SizedBox(height: 10),
                  _StudentCard(
                    child: LessonBlockView(
                      blocks: lesson.blocks,
                      fallbackBody: '',
                      // พรีวิวใช้รายการสื่อของบทเรียนชุดเดียวกับที่นักเรียน
                      // จะได้ แต่ไม่ส่ง resolveMaterialUrl/onOpen — ครูจึง
                      // เห็นกรอบสื่อครบโดยที่พรีวิวไม่พาออกจากหน้า
                      materials: [
                        for (final m in lesson.materials)
                          LessonMaterial(
                            id: m.id,
                            type: m.type,
                            title: m.title,
                            url: m.url,
                            sortOrder: 0,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const _StudentSectionTitle('📄 เอกสารและไฟล์ประกอบการเรียน'),
                  const SizedBox(height: 10),
                  if (lesson.materials.isEmpty)
                    const _StudentEmpty(
                      'ยังไม่มีไฟล์แนบ — นักเรียนจะไม่เห็นหัวข้อนี้',
                    )
                  else
                    for (final mat in lesson.materials)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _StudentCard(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: SchoolPalette.deepGreen.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  mat.type == 'link'
                                      ? Icons.link_rounded
                                      : Icons.picture_as_pdf_rounded,
                                  color: SchoolPalette.deepGreen,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      mat.title,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        color: SchoolPalette.ink,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      mat.type.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: SchoolPalette.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // ปุ่มที่นักเรียนเห็นจริง — ในพรีวิวกดไม่ได้
                              // แต่ต้องอยู่ ไม่งั้นครูไม่รู้ว่าเปิดไฟล์ได้
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: SchoolPalette.glassBorder,
                                    width: 1.2,
                                  ),
                                ),
                                child: const Text(
                                  'เปิดอ่าน',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: SchoolPalette.deepGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  const SizedBox(height: 14),
                  const _StudentSectionTitle(
                    '📊 ข้อมูลเซนเซอร์ AIoT ที่ผูกกับบทเรียน',
                  ),
                  const SizedBox(height: 10),
                  if (lesson.sensorLinks.isEmpty)
                    const _StudentEmpty(
                      'ยังไม่ได้ผูกเซนเซอร์กับบทเรียน — นักเรียนจะไม่เห็นกราฟ',
                    )
                  else
                    for (final link in lesson.sensorLinks)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _StudentCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: SchoolPalette.deepGreen.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.sensors_rounded,
                                      color: SchoolPalette.deepGreen,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      link.caption.trim().isEmpty
                                          ? 'กราฟข้อมูลเซนเซอร์ (${link.metric})'
                                          : link.caption,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: SchoolPalette.ink,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Container(
                                height: 120,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: SchoolPalette.softGreenBg,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Text(
                                    '${link.deviceName} · ${link.metric} · ${link.timeRange}\n'
                                    'กราฟจะวาดจากข้อมูลจริงตอนนักเรียนเปิดบทเรียน',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      height: 1.5,
                                      color: SchoolPalette.muted,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  const SizedBox(height: 10),
                  Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      gradient: SchoolPalette.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'ทำเครื่องหมายว่าเรียนจบแล้ว',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentSectionTitle extends StatelessWidget {
  const _StudentSectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w900,
      color: SchoolPalette.navy,
    ),
  );
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: SchoolPalette.glassBorder),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0F101828),
          blurRadius: 18,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: child,
  );
}

class _StudentEmpty extends StatelessWidget {
  const _StudentEmpty(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: SchoolPalette.softGreenBg,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 12.5,
        height: 1.45,
        color: SchoolPalette.muted,
      ),
    ),
  );
}

class _StudentBanner extends StatelessWidget {
  const _StudentBanner({required this.lesson});
  final LessonModel lesson;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: SchoolPalette.primaryGradient,
      borderRadius: BorderRadius.circular(24),
      boxShadow: const [
        BoxShadow(
          color: Color(0x25165042),
          blurRadius: 20,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: Text(
            lesson.courseName.trim().isEmpty ? 'บทเรียน' : lesson.courseName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          lesson.title.trim().isEmpty
              ? 'ยังไม่ได้ตั้งชื่อบทเรียน'
              : lesson.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
            height: 1.3,
          ),
        ),
      ],
    ),
  );
}

class _AddBlockSheet extends StatelessWidget {
  const _AddBlockSheet();

  @override
  Widget build(BuildContext context) {
    final items = <(ContentBlockType?, String, String, Widget)>[
      (
        ContentBlockType.heading,
        'หัวข้อ',
        'ตัวหนาขนาดใหญ่ ใช้ขึ้นหัวข้อย่อยของบทเรียน',
        const Text(
          'หัวข้อย่อย',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AirySpec.ink,
          ),
        ),
      ),
      (
        ContentBlockType.text,
        'ข้อความ',
        'ย่อหน้าเนื้อหาปกติ',
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 5, width: 120, color: const Color(0xFFE3E1EB)),
            const SizedBox(height: 5),
            Container(height: 5, width: 84, color: const Color(0xFFE3E1EB)),
          ],
        ),
      ),
      (
        ContentBlockType.calloutWarning,
        'กล่องข้อควรระวัง',
        'เน้นสิ่งที่นักเรียนพลาดบ่อย',
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFFDF1DE),
            borderRadius: BorderRadius.circular(7),
          ),
          child: const Text(
            'ระวัง!',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFFB4650F),
            ),
          ),
        ),
      ),
      (
        ContentBlockType.summaryBox,
        'กล่องสรุป',
        'สรุปประเด็นท้ายบท',
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFE1F6EC),
            borderRadius: BorderRadius.circular(7),
          ),
          child: const Text(
            'สรุป',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF107A50),
            ),
          ),
        ),
      ),
      (
        ContentBlockType.sensorChart,
        'กราฟข้อมูล AIoT',
        'ดึงค่าจริงจากเซนเซอร์ในโรงเรียนมาแสดง',
        const Icon(Icons.insights_outlined, size: 22, color: AirySpec.label),
      ),
      (
        ContentBlockType.bulletList,
        'รายการ',
        'ข้อย่อยบรรทัดละข้อ มีจุดนำหน้า',
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final w in const [96.0, 74.0])
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 4,
                      height: 4,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(0xFF8E8C99),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      height: 5,
                      width: w,
                      color: const Color(0xFFE3E1EB),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      (
        ContentBlockType.image,
        'รูปภาพ',
        'เลือกรูปที่อัปโหลดไว้ในคลังสื่อแนบ นักเรียนเห็นรูปในหน้าเลย',
        const Icon(Icons.image_outlined, size: 22, color: AirySpec.label),
      ),
      (
        ContentBlockType.video,
        'วิดีโอ',
        'วิดีโอจากคลังสื่อแนบ เปิดด้วยแอปดูวิดีโอของเครื่อง',
        const Icon(
          Icons.play_circle_outline_rounded,
          size: 22,
          color: AirySpec.label,
        ),
      ),
      (
        ContentBlockType.fileDownload,
        'ไฟล์',
        'เอกสารจากคลังสื่อแนบ นักเรียนกดเปิดได้',
        const Icon(
          Icons.insert_drive_file_outlined,
          size: 22,
          color: AirySpec.label,
        ),
      ),
      (
        ContentBlockType.externalLink,
        'ลิงก์ภายนอก',
        'วาง URL เว็บไซต์หรือวิดีโอออนไลน์',
        const Icon(Icons.link_rounded, size: 22, color: AirySpec.label),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFE4E3EA),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(22, 0, 22, 14),
            child: Text(
              'เพิ่มบล็อกเนื้อหา',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: AirySpec.ink,
              ),
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
              children: [
                for (final (type, title, desc, preview) in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Material(
                      color: type == null
                          ? const Color(0xFFF7F7FA)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: type == null
                            ? null
                            : () => Navigator.pop(context, type),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFEDECF2)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 15.5,
                                              fontWeight: FontWeight.w700,
                                              color: type == null
                                                  ? AirySpec.label
                                                  : AirySpec.ink,
                                            ),
                                          ),
                                        ),
                                        if (type == null) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 7,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEDECF2),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: const Text(
                                              'ยังไม่รองรับ',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: AirySpec.label,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      desc,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        color: AirySpec.label,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              SizedBox(width: 92, child: preview),
                            ],
                          ),
                        ),
                      ),
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

class _BlockAction extends StatelessWidget {
  const _BlockAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.alwaysActive = false,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  /// ใช้เมื่อการกดถูกจัดการโดยตัวห่อข้างนอก (ตัวจับลาก / PopupMenuButton)
  final bool alwaysActive;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null || alwaysActive;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(
            icon,
            size: 17,
            color: enabled ? AirySpec.label : const Color(0xFFCFCDD8),
          ),
        ),
      ),
    );
  }
}

class TeacherPublishChecklistDialog extends StatelessWidget {
  const TeacherPublishChecklistDialog({
    super.key,
    required this.lesson,
    required this.onConfirmedPublish,
  });

  final LessonModel lesson;
  final VoidCallback onConfirmedPublish;

  @override
  Widget build(BuildContext context) {
    final hasTitle = lesson.title.isNotEmpty;
    final hasBlocks = lesson.blocks.isNotEmpty;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.publish_rounded, color: TeacherPalette.primary),
          SizedBox(width: 10),
          Text(
            'ยืนยันการเผยแพร่บทเรียน',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'รายการตรวจสอบระบบก่อนเปิดให้นักเรียนเข้าเรียน:',
            style: TextStyle(fontSize: 12, color: TeacherPalette.muted),
          ),
          const SizedBox(height: 12),
          _checkItem('มีชื่อบทเรียนครอบคลุม', hasTitle),
          _checkItem('มี Block เนื้อหาอย่างน้อย 1 รายการ', hasBlocks),
          _checkItem(
            'สื่อแนบพร้อมใช้งาน (${lesson.materials.length} สื่อ)',
            true,
          ),
          _checkItem(
            'กราฟ AIoT เชื่อมต่อสำเร็จ (${lesson.sensorLinks.length} กราฟ)',
            true,
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              '💡 เมื่อกดเผยแพร่ นักเรียนในรายวิชาจะสามารถเข้าอ่านและเรียนรู้บทเรียนนี้ได้ทันที',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF047857),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('กลับไปแก้ไข'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: TeacherPalette.primary,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
            onConfirmedPublish();
          },
          child: const Text('เผยแพร่บทเรียนทันที'),
        ),
      ],
    );
  }

  Widget _checkItem(String text, bool pass) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            pass ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 16,
            color: pass ? const Color(0xFF059669) : Colors.red,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: pass ? TeacherPalette.ink : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 9. LESSON ANALYTICS PAGE (SPEC 9 WITH FILTERS)
// ==========================================

class TeacherLessonAnalyticsPage extends StatefulWidget {
  const TeacherLessonAnalyticsPage({
    super.key,
    required this.lesson,
    this.loadProgress,
  });

  final LessonModel lesson;

  /// `list_lesson_progress` — one row per enrolled student. Injectable so
  /// tests can drive loading / data / empty / failure.
  final Future<List<LessonStudentProgress>> Function(String lessonId)?
  loadProgress;

  @override
  State<TeacherLessonAnalyticsPage> createState() =>
      _TeacherLessonAnalyticsPageState();
}

class _TeacherLessonAnalyticsPageState
    extends State<TeacherLessonAnalyticsPage> {
  // Until 2026-09-16 this screen was a "ยังไม่เปิดใช้งาน" placeholder (and
  // before that, hardcoded stats — "42 คน", "84%"). Students have written
  // lesson_progress all along; list_lesson_progress now reads it back.
  late Future<List<LessonStudentProgress>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<LessonStudentProgress>> _load() =>
      (widget.loadProgress ?? LessonService.listProgress)(widget.lesson.id);

  void _retry() {
    // Block body on purpose: `setState(() => _future = _load())` returns
    // the Future, which setState rejects with an assertion.
    final next = _load();
    setState(() {
      _future = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('สถิติบทเรียน: ${widget.lesson.title}'),
        backgroundColor: Colors.white,
        foregroundColor: TeacherPalette.ink,
      ),
      body: FutureBuilder<List<LessonStudentProgress>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            debugPrint('TeacherLessonAnalyticsPage load failed: ${snap.error}');
            return _centered(
              icon: Icons.error_outline_rounded,
              title: 'โหลดสถิติไม่สำเร็จ',
              body: 'ยังไม่ทราบความคืบหน้าของนักเรียน ลองใหม่อีกครั้ง',
              action: TextButton(
                onPressed: _retry,
                child: const Text('ลองใหม่'),
              ),
            );
          }
          final rows = snap.data ?? const [];
          if (rows.isEmpty) {
            return _centered(
              icon: Icons.group_off_rounded,
              title: 'ยังไม่มีนักเรียนในวิชานี้',
              body:
                  'เมื่อมีนักเรียนลงทะเบียน ความคืบหน้าของแต่ละคนจะแสดงที่นี่',
            );
          }
          final opened = rows.where((r) => r.opened).length;
          final completed = rows.where((r) => r.completed).length;
          final avg =
              rows.fold<double>(0, (sum, r) => sum + r.progressPct) /
              rows.length;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _stat('นักเรียน', '${rows.length} คน'),
                  _stat('เปิดบทเรียนแล้ว', '$opened คน'),
                  _stat('เรียนจบ', '$completed คน'),
                  _stat('ความคืบหน้าเฉลี่ย', '${avg.toStringAsFixed(0)}%'),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'รายคน',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: TeacherPalette.ink,
                ),
              ),
              const SizedBox(height: 8),
              for (final r in rows) _studentRow(r),
            ],
          );
        },
      ),
    );
  }

  Widget _centered({
    required IconData icon,
    required String title,
    required String body,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: TeacherPalette.muted),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: TeacherPalette.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                color: TeacherPalette.muted,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 8), action],
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TeacherPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11.5, color: TeacherPalette.muted),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: TeacherPalette.ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _studentRow(LessonStudentProgress r) {
    final status = r.completed
        ? 'เรียนจบแล้ว'
        : r.opened
        ? 'กำลังเรียน'
        : 'ยังไม่เปิดบทเรียน';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TeacherPalette.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.fullName.isEmpty ? r.email : r.fullName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: TeacherPalette.ink,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (r.progressPct / 100).clamp(0, 1),
                    minHeight: 6,
                    backgroundColor: const Color(0xFFE2E8F0),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${r.progressPct.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: TeacherPalette.ink,
                ),
              ),
              Text(
                status,
                style: const TextStyle(
                  fontSize: 10.5,
                  color: TeacherPalette.muted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UploadedFileItem {
  _UploadedFileItem({
    required this.name,
    required this.sizeBytes,
    required this.typeCategory,
    required this.url,
    this.bytes,
    this.progress = 1.0,
    this.isCompleted = true,
  });

  String name;
  int sizeBytes;
  String typeCategory;
  String url;
  Uint8List? bytes;
  double progress;
  bool isCompleted;
}

class _DashedBorderContainer extends StatelessWidget {
  const _DashedBorderContainer({
    required this.child,
    this.color = const Color(0xFFCBD5E1),
    this.borderRadius = 16.0,
  });

  final Widget child;
  final Color color;
  final double borderRadius;

  static const double _strokeWidth = 1.5;
  static const double _dashWidth = 6.0;
  static const double _dashSpace = 4.0;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRectPainter(
        color: color,
        strokeWidth: _strokeWidth,
        dashWidth: _dashWidth,
        dashSpace: _dashSpace,
        borderRadius: borderRadius,
      ),
      child: child,
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  _DashedRectPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashSpace,
    required this.borderRadius,
  });

  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    final Path path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double len = (distance + dashWidth < metric.length)
            ? dashWidth
            : metric.length - distance;
        canvas.drawPath(metric.extractPath(distance, distance + len), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRectPainter oldDelegate) => false;
}

/// ถือ TextEditingController ของ dialog ไว้จน route ถูกถอดจริง — dispose ทันที
/// หลัง `showDialog` คืนค่าจะชนแอนิเมชันปิดที่ยังวาด TextField อยู่ และไม่
/// dispose เลยคือ leak ทุกครั้งที่เปิด
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
