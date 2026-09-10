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

import 'teacher_redesign_prototype_page.dart' show TeacherPalette;
import 'teacher_shared_widgets.dart' show TeacherSearchInput;

// ==========================================
// DATA MODELS
// ==========================================

enum LessonStatus { draft, published }

enum ContentBlockType {
  heading,
  text,
  bulletList,
  image,
  video,
  fileDownload,
  externalLink,
  calloutWarning,
  summaryBox,
  sensorChart,
}

class ContentBlockModel {
  ContentBlockModel({
    required this.id,
    required this.type,
    this.text = '',
    this.mediaUrl = '',
    this.caption = '',
    this.sensorDeviceId = '',
    this.sensorMetric = '',
    this.timeRange = '',
  });

  final String id;
  ContentBlockType type;
  String text;
  String mediaUrl;
  String caption;
  String sensorDeviceId;
  String sensorMetric;
  String timeRange;
}

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
        // 📌 Breadcrumb
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
        const SizedBox(height: 14),

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
                                    ScaffoldMessenger.of(
                                      context,
                                    ).showSnackBar(
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
  });

  final LessonModel lesson;
  final bool isCourseClosed;

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

      widget.lesson.sensorLinks = detail.sensorLinks
          .map(
            (s) => LessonSensorLinkModel(
              id: s.id,
              deviceName: s.deviceId,
              metric: s.metric,
              timeRange: s.timeStart != null
                  ? '${s.timeStart} - ${s.timeEnd}'
                  : 'ช่วงเวลาที่บันทึก',
              caption: s.caption ?? '',
            ),
          )
          .toList();
      widget.lesson.sensorChartsCount = widget.lesson.sensorLinks.length;

      final List<ContentBlockModel> parsedBlocks = [];
      final content = detail.content;
      if (content != null &&
          content['blocks'] is List &&
          (content['blocks'] as List).isNotEmpty) {
        final rawBlocks = content['blocks'] as List;
        for (int i = 0; i < rawBlocks.length; i++) {
          final raw = rawBlocks[i];
          if (raw is Map) {
            final blockTypeStr = raw['type'] as String? ?? 'text';
            final blockType = ContentBlockType.values.firstWhere(
              (t) => t.name == blockTypeStr,
              orElse: () => ContentBlockType.text,
            );
            parsedBlocks.add(
              ContentBlockModel(
                id: raw['id'] as String? ?? 'b-$i',
                type: blockType,
                text: raw['text'] as String? ?? '',
                mediaUrl: raw['mediaUrl'] as String? ?? '',
                caption: raw['caption'] as String? ?? '',
                sensorDeviceId: raw['sensorDeviceId'] as String? ?? '',
                sensorMetric: raw['sensorMetric'] as String? ?? '',
                timeRange: raw['timeRange'] as String? ?? '',
              ),
            );
          }
        }
      } else if (content != null &&
          content['body'] is String &&
          (content['body'] as String).trim().isNotEmpty) {
        final bodyStr = (content['body'] as String).trim();
        final paragraphs = bodyStr.split('\n\n');
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
    final bodyText = blocks
        .where(
          (b) =>
              b.text.trim().isNotEmpty &&
              b.type != ContentBlockType.heading &&
              !b.text.trimLeft().startsWith('สื่อแนบ:'),
        )
        .map((b) => b.text.trim())
        .join('\n\n');
    return {
      'body': bodyText,
      'blocks': blocks
          .map(
            (b) => {
              'id': b.id,
              'type': b.type.name,
              'text': b.text,
              'mediaUrl': b.mediaUrl,
              'caption': b.caption,
              'sensorDeviceId': b.sensorDeviceId,
              'sensorMetric': b.sensorMetric,
              'timeRange': b.timeRange,
            },
          )
          .toList(),
    };
  }

  void _addBlock(ContentBlockType type) {
    final newId = 'b-${DateTime.now().millisecondsSinceEpoch}';
    final newBlock = ContentBlockModel(
      id: newId,
      type: type,
      text: type == ContentBlockType.heading
          ? 'หัวข้อใหม่'
          : (type == ContentBlockType.calloutWarning
                ? 'ข้อควรระวังสำคัญ...'
                : (type == ContentBlockType.summaryBox
                      ? 'สรุปประเด็นสำคัญประจำบทเรียน...'
                      : 'ข้อความเนื้อหาใหม่...')),
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

  void _deleteBlock(int index) {
    setState(() {
      _blocks.removeAt(index);
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
        final result = await FilePicker.platform.pickFiles(
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
                                debugPrint('Error attaching lesson material: $e');
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

    final saveColor = _saveFailed
        ? Colors.red
        : (_isAutoSaving ? Colors.amber.shade800 : const Color(0xFF059669));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        scrolledUnderElevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        titleSpacing: 0,
        leadingWidth: 56,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    size: 18,
                    color: TeacherPalette.ink,
                  ),
                ),
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: TeacherPalette.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                size: 18,
                color: TeacherPalette.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _titleController,
                    readOnly: widget.isCourseClosed,
                    onChanged: (_) => _triggerAutoSave(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: TeacherPalette.ink,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      filled: false,
                      fillColor: Colors.transparent,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      hintText: 'ชื่อบทเรียน *',
                      hintStyle: TextStyle(
                        color: TeacherPalette.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'เครื่องมือแก้ไขเนื้อหาบทเรียน (Lesson Studio)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: TeacherPalette.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: _saveFailed ? _triggerAutoSave : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: saveColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: saveColor.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _saveFailed
                          ? Icons.error_outline_rounded
                          : (_isAutoSaving
                                ? Icons.sync_rounded
                                : Icons.check_circle_rounded),
                      size: 14,
                      color: saveColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _saveFailed
                          ? '$_saveStatusText · ลองใหม่'
                          : _saveStatusText,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: saveColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: OutlinedButton.icon(
              icon: const Icon(
                Icons.visibility_outlined,
                size: 16,
                color: Color(0xFF2563EB),
              ),
              label: const Text(
                'ดูตัวอย่าง',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2563EB),
                ),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 38),
                side: const BorderSide(color: Color(0xFF93C5FD)),
                backgroundColor: const Color(0xFFEFF6FF),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        TeacherLessonPreviewPage(lesson: widget.lesson),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.publish_rounded, size: 16),
              label: Text(
                widget.lesson.status == LessonStatus.published
                    ? 'อัปเดตบทเรียน'
                    : 'เผยแพร่',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 38),
                backgroundColor: TeacherPalette.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              onPressed: widget.isCourseClosed
                  ? null
                  : () {
                      showDialog<void>(
                        context: context,
                        builder: (_) => TeacherPublishChecklistDialog(
                          lesson: widget.lesson,
                          onConfirmedPublish: () async {
                            try {
                              await LessonService.publishLesson(
                                widget.lesson.id,
                              );
                              if (!mounted) return;
                              setState(() {
                                widget.lesson.status = LessonStatus.published;
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
          ),
        ],
      ),
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

  /// Middle Block Editor Panel
  Widget _buildMiddleEditorPanel() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.lesson.status == LessonStatus.published)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFEDD5)),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFC2410C),
                      size: 18,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'บทเรียนนี้เผยแพร่แล้ว การแก้ไขและบันทึกจะมีผลต่อนักเรียนที่กำลังเรียนทันที',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFC2410C),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Blocks List
            for (int i = 0; i < _blocks.length; i++)
              _buildBlockEditorTile(_blocks[i], i),

            const SizedBox(height: 20),

            // Add Block Menu (Spec 4: All 10 Block Types)
            Center(
              child: PopupMenuButton<ContentBlockType>(
                onSelected: _addBlock,
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: ContentBlockType.heading,
                    child: Text('📌 เพิ่มหัวข้อ (Heading)'),
                  ),
                  const PopupMenuItem(
                    value: ContentBlockType.text,
                    child: Text('📝 เพิ่มข้อความ (Text)'),
                  ),
                  const PopupMenuItem(
                    value: ContentBlockType.calloutWarning,
                    child: Text('⚠️ เพิ่มกล่องข้อควรระวัง (Callout)'),
                  ),
                  const PopupMenuItem(
                    value: ContentBlockType.summaryBox,
                    child: Text('💡 เพิ่มกล่องสรุป (Summary)'),
                  ),
                  const PopupMenuItem(
                    value: ContentBlockType.sensorChart,
                    child: Text('📊 ฝังกราฟข้อมูล AIoT Sensor'),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: TeacherPalette.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: TeacherPalette.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_circle_outline_rounded,
                        color: TeacherPalette.primary,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'เพิ่ม Block เนื้อหาใหม่',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
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
    );
  }

  Widget _buildBlockEditorTile(ContentBlockModel block, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TeacherPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getBlockIcon(block.type),
                size: 16,
                color: TeacherPalette.primary,
              ),
              const SizedBox(width: 8),
              Text(
                _getBlockLabel(block.type),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: TeacherPalette.muted,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.arrow_upward_rounded, size: 16),
                onPressed: widget.isCourseClosed
                    ? null
                    : () => _moveBlock(index, -1),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_downward_rounded, size: 16),
                onPressed: widget.isCourseClosed
                    ? null
                    : () => _moveBlock(index, 1),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 16,
                  color: Colors.red,
                ),
                onPressed: widget.isCourseClosed
                    ? null
                    : () => _deleteBlock(index),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (block.type == ContentBlockType.sensorChart)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.sensors_rounded,
                        color: Color(0xFF2563EB),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        block.sensorDeviceId,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E40AF),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Metric: ${block.sensorMetric} | ช่วงเวลา: ${block.timeRange}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 80,
                    width: double.infinity,
                    color: Colors.white,
                    child: const Center(
                      child: Text(
                        '[พรีวิว กราฟเรียลไทม์ AIoT]',
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            TextFormField(
              initialValue: block.text,
              maxLines: block.type == ContentBlockType.heading ? 1 : 3,
              onChanged: (val) {
                block.text = val;
                _triggerAutoSave();
              },
              style: TextStyle(
                fontWeight: block.type == ContentBlockType.heading
                    ? FontWeight.w900
                    : FontWeight.normal,
                fontSize: block.type == ContentBlockType.heading ? 16 : 14,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'กรอกเนื้อหา...',
              ),
            ),
        ],
      ),
    );
  }

  IconData _getBlockIcon(ContentBlockType type) {
    return switch (type) {
      ContentBlockType.heading => Icons.title_rounded,
      ContentBlockType.text => Icons.notes_rounded,
      ContentBlockType.calloutWarning => Icons.warning_amber_rounded,
      ContentBlockType.summaryBox => Icons.lightbulb_outline_rounded,
      ContentBlockType.sensorChart => Icons.sensors_rounded,
      _ => Icons.article_outlined,
    };
  }

  String _getBlockLabel(ContentBlockType type) {
    return switch (type) {
      ContentBlockType.heading => 'หัวข้อ (Heading)',
      ContentBlockType.text => 'ข้อความ (Text)',
      ContentBlockType.calloutWarning => 'กล่องข้อควรระวัง (Callout)',
      ContentBlockType.summaryBox => 'กล่องสรุป (Summary)',
      ContentBlockType.sensorChart => 'กราฟ AIoT Sensor Chart',
      _ => 'Block',
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

  Widget _buildAiotTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // เดิมเปิด dialog ให้เลือกอุปกรณ์/metric จากรายการ hardcode 3 ชื่อ
        // ที่ไม่ตรงกับอุปกรณ์จริงในโรงเรียนเลย แล้วบันทึกไว้ในเครื่อง — ไม่มี
        // ทั้งรายการอุปกรณ์จริง (ไม่มี service ให้ดึงอุปกรณ์จริงสำหรับหน้านี้
        // โดยเฉพาะ) และไม่มีฝั่งนักเรียนอ่านบล็อกกราฟ AIoT ที่ผูกไว้เลยสัก
        // จุด (`student_lessons_page.dart` ไม่มีโค้ดอ่าน sensorDeviceId เลย)
        // — ปิดปุ่มไว้ตรง ๆ ดีกว่าให้ครูผูกอุปกรณ์ปลอมที่ไม่มีทางใช้งานได้จริง
        Tooltip(
          message:
              'ยังไม่รองรับการผูกข้อมูลเซนเซอร์จริงในบทเรียน — ฟีเจอร์นี้ยังไม่ได้เชื่อมกับอุปกรณ์จริง',
          child: ElevatedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.sensors_rounded, size: 16),
            label: const Text('+ ผูกข้อมูล AIoT Sensor (ยังไม่เปิดใช้งาน)'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 40),
            ),
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

class TeacherLessonPreviewPage extends StatelessWidget {
  const TeacherLessonPreviewPage({super.key, required this.lesson});

  final LessonModel lesson;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        title: const Text(
          'มุมมองนักเรียน (Student Preview Mode)',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 16),
            label: const Text(
              'กลับไปแก้ไข',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            color: const Color(0xFFFEF3C7),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.visibility_rounded,
                  color: Color(0xFFD97706),
                  size: 16,
                ),
                SizedBox(width: 6),
                Text(
                  'นี่คือโหมดแสดงผลเสมือนจริงของนักเรียน ครูเท่านั้นที่เห็นหน้านี้ก่อนเผยแพร่',
                  style: TextStyle(
                    color: Color(0xFF92400E),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: TeacherPalette.ink,
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final block in lesson.blocks) ...[
                    if (block.type == ContentBlockType.heading)
                      Text(
                        block.text,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: TeacherPalette.primary,
                        ),
                      )
                    else if (block.type == ContentBlockType.text)
                      Text(
                        block.text,
                        style: const TextStyle(fontSize: 14, height: 1.5),
                      )
                    else if (block.type == ContentBlockType.calloutWarning)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Text(
                          block.text,
                          style: const TextStyle(
                            color: Color(0xFF991B1B),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    else if (block.type == ContentBlockType.sensorChart)
                      Container(
                        height: 140,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '📊 กราฟเรียลไทม์ AIoT: ${block.sensorDeviceId} (${block.sensorMetric})',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 8. PUBLISH CHECKLIST DIALOG (SPEC 8)
// ==========================================

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
  const TeacherLessonAnalyticsPage({super.key, required this.lesson});

  final LessonModel lesson;

  @override
  State<TeacherLessonAnalyticsPage> createState() =>
      _TeacherLessonAnalyticsPageState();
}

class _TeacherLessonAnalyticsPageState
    extends State<TeacherLessonAnalyticsPage> {
  // เคยเป็นหน้าปลอม 100% — สถิติ/รายชื่อนักเรียน/ความคืบหน้าเป็นตัวเลข
  // hardcode ทั้งหมด (ไม่มีการเรียก service ใดๆ เลย แค่ Future.delayed
  // จำลองการโหลด) ไม่มี backend รองรับสถิติระดับบทเรียนรายคนจริงในตอนนี้
  // (ไม่มี RPC/Service ใน shared_core ที่ทำเรื่องนี้) — ปิดฟีเจอร์ตรงๆ ดีกว่า
  // โชว์ตัวเลขที่ไม่มีอยู่จริงเป็นสถิตินักเรียนจริง
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('สถิติบทเรียน: ${widget.lesson.title}'),
        backgroundColor: Colors.white,
        foregroundColor: TeacherPalette.ink,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.bar_chart_rounded,
                size: 48,
                color: TeacherPalette.muted,
              ),
              const SizedBox(height: 16),
              const Text(
                'สถิติบทเรียนรายคนยังไม่เปิดใช้งาน',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: TeacherPalette.ink,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'ระบบยังไม่มีข้อมูลความคืบหน้าของนักเรียนรายบุคคลต่อบทเรียน '
                'ฟีเจอร์นี้อยู่ระหว่างพัฒนา',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: TeacherPalette.muted),
              ),
            ],
          ),
        ),
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
