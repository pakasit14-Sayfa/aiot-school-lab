import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import 'package:url_launcher/url_launcher.dart';
import 'student_redesign_palette.dart';

class _AssignmentWithCourse {
  const _AssignmentWithCourse({
    required this.assignment,
    required this.courseName,
    required this.submitted,
    required this.submittedAt,
  });

  final AssignmentSummary assignment;
  final String courseName;
  final bool submitted;
  final DateTime? submittedAt;
}

class StudentAssignmentsPage extends StatefulWidget {
  const StudentAssignmentsPage({
    super.key,
    this.loadCourses,
    this.loadAssignmentsForCourse,
    this.loadSubmissionVersions,
    this.getAssignmentDetail,
    this.getAttachmentDownloadUrl,
    this.pickFiles,
    this.submitAssignment,
    this.uploadAttachment,
  });

  /// Read/write seams threaded to the corresponding CourseService/
  /// AssignmentService static calls in production — widget tests supply
  /// these to drive the list load and the submit sheet (including the
  /// real signed-URL attachment upload) without a live Supabase client.
  final Future<List<CourseSummary>> Function()? loadCourses;
  final Future<List<AssignmentSummary>> Function(String courseId)?
  loadAssignmentsForCourse;
  final Future<List<SubmissionVersion>> Function(String assignmentId)?
  loadSubmissionVersions;
  final Future<AssignmentDetail> Function(String assignmentId)?
  getAssignmentDetail;
  final Future<String> Function(String attachmentId)? getAttachmentDownloadUrl;
  final Future<List<PlatformFile>?> Function()? pickFiles;
  final Future<({int version, String submissionVersionId})> Function({
    required String assignmentId,
    required String content,
  })?
  submitAssignment;
  final Future<String> Function({
    required String submissionVersionId,
    required String fileName,
    required Uint8List bytes,
  })?
  uploadAttachment;

  @override
  State<StudentAssignmentsPage> createState() => _StudentAssignmentsPageState();
}

class _StudentAssignmentsPageState extends State<StudentAssignmentsPage> {
  int _selectedFilterIndex = 0;
  bool _loading = true;
  String? _error;
  List<_AssignmentWithCourse> _items = const [];

  final List<String> _filters = ['ทั้งหมด', 'ยังไม่ส่ง', 'ส่งแล้ว'];

  List<_AssignmentWithCourse> get _visible {
    if (_selectedFilterIndex == 1) {
      return _items.where((i) => !i.submitted).toList();
    }
    if (_selectedFilterIndex == 2) {
      return _items.where((i) => i.submitted).toList();
    }
    return _items;
  }

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
      final loadCourses = widget.loadCourses ?? CourseService.listMyCourses;
      final loadAssignments =
          widget.loadAssignmentsForCourse ?? AssignmentService.listAssignments;
      final loadVersions = widget.loadSubmissionVersions ??
          AssignmentService.listMySubmissionVersions;

      final courses = (await loadCourses())
          .where((c) => c.isActive)
          .toList();
      final assignmentLists = await Future.wait(
        courses.map((c) => loadAssignments(c.id)),
      );

      final published = <(AssignmentSummary, CourseSummary)>[];
      for (var i = 0; i < courses.length; i++) {
        for (final a in assignmentLists[i].where((a) => a.isPublished)) {
          published.add((a, courses[i]));
        }
      }

      final submissionChecks = await Future.wait(
        published.map((e) => loadVersions(e.$1.id)),
      );

      final items = <_AssignmentWithCourse>[];
      for (var i = 0; i < published.length; i++) {
        final (assignment, course) = published[i];
        final versions = submissionChecks[i];
        items.add(
          _AssignmentWithCourse(
            assignment: assignment,
            courseName: course.subjectName,
            submitted: versions.isNotEmpty,
            submittedAt: versions.isEmpty ? null : versions.last.submittedAt,
          ),
        );
      }
      items.sort((a, b) {
        final aDue = a.assignment.dueAt ?? DateTime(2100);
        final bDue = b.assignment.dueAt ?? DateTime(2100);
        return aDue.compareTo(bDue);
      });

      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'โหลดข้อมูลไม่สำเร็จ';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dueCount = _items.where((i) => !i.submitted).length;
    final submittedCount = _items.where((i) => i.submitted).length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: SchoolPalette.ink,
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text(
          'ใบงานและการบ้านของฉัน',
          style: TextStyle(
            color: SchoolPalette.ink,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            child: Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = constraints.maxWidth;
                  final isDesktop = screenWidth >= 1024;
                  final horizontalPadding = screenWidth < 520 ? 14.0 : 16.0;

                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isDesktop ? 720 : 640,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSummaryHeader(
                            context,
                            dueCount,
                            submittedCount,
                          ),
                          const SizedBox(height: 18),
                          if (_error != null) ...[
                            _buildErrorBanner(),
                            const SizedBox(height: 12),
                          ],
                          _buildFilterPills(),
                          const SizedBox(height: 16),
                          _buildAssignmentList(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFDC2626),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(
                color: Color(0xFFB91C1C),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(onPressed: _load, child: const Text('ลองใหม่')),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader(
    BuildContext context,
    int dueCount,
    int submittedCount,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: SchoolPalette.glassBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: SchoolPalette.softGreenBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: SchoolPalette.glassBorder),
                ),
                child: const Icon(
                  Icons.assignment_turned_in_rounded,
                  color: SchoolPalette.deepGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'สรุปงานของฉัน',
                      style: TextStyle(
                        color: SchoolPalette.navy,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'ตรวจสอบกำหนดส่งงานจากทุกวิชาที่ลงทะเบียน',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: SchoolPalette.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final tiles = [
                _SummaryStatTile(
                  value: '$dueCount',
                  label: 'ยังไม่ส่ง',
                  color: const Color(0xFFDC2626),
                  bgTint: const Color(0xFFFEF2F2),
                  icon: Icons.priority_high_rounded,
                ),
                _SummaryStatTile(
                  value: '$submittedCount',
                  label: 'ส่งแล้ว',
                  color: SchoolPalette.deepGreen,
                  bgTint: SchoolPalette.softGreenBg,
                  icon: Icons.check_circle_outline_rounded,
                ),
              ];

              if (constraints.maxWidth < 420) {
                return Column(
                  children: [
                    for (var i = 0; i < tiles.length; i++) ...[
                      tiles[i],
                      if (i != tiles.length - 1) const SizedBox(height: 8),
                    ],
                  ],
                );
              }

              return Row(
                children: [
                  for (var i = 0; i < tiles.length; i++) ...[
                    Expanded(child: tiles[i]),
                    if (i != tiles.length - 1) const SizedBox(width: 8),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPills() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(_filters.length, (index) {
          final isSelected = _selectedFilterIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: isSelected,
              label: Text(_filters[index]),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : SchoolPalette.navy,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                fontSize: 12.5,
              ),
              selectedColor: SchoolPalette.deepGreen,
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
                side: BorderSide(
                  color: isSelected
                      ? SchoolPalette.deepGreen
                      : SchoolPalette.glassBorder,
                ),
              ),
              onSelected: (selected) {
                setState(() => _selectedFilterIndex = index);
              },
            ),
          );
        }),
      ),
    );
  }

  Widget _buildAssignmentList() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final items = _visible;

    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: SchoolPalette.glassBorder),
        ),
        child: Column(
          children: [
            Icon(
              Icons.inbox_rounded,
              size: 36,
              color: SchoolPalette.muted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 8),
            const Text(
              'ไม่มีงานในหมวดนี้',
              style: TextStyle(
                color: SchoolPalette.muted,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AssignmentCard(
            item: item,
            onSubmitted: _load,
            getAssignmentDetail: widget.getAssignmentDetail,
            loadPreviousVersions: widget.loadSubmissionVersions,
            getAttachmentDownloadUrl: widget.getAttachmentDownloadUrl,
            pickFiles: widget.pickFiles,
            submitAssignment: widget.submitAssignment,
            uploadAttachment: widget.uploadAttachment,
          ),
        );
      }).toList(),
    );
  }
}

class _SummaryStatTile extends StatelessWidget {
  const _SummaryStatTile({
    required this.value,
    required this.label,
    required this.color,
    required this.bgTint,
    required this.icon,
  });

  final String value;
  final String label;
  final Color color;
  final Color bgTint;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgTint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$value งาน',
                style: TextStyle(
                  color: color,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                label,
                style: TextStyle(
                  color: color.withValues(alpha: 0.85),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ส่งงานจริง — เดิมระบบนี้รับแค่ข้อความ (submit_assignment RPC เดิมไม่มี
/// ที่ทางให้แนบไฟล์เลย) เลยเคยตัด UI อัปโหลดไฟล์ที่จำลอง progress bar ปลอม
/// ออกไปก่อน 2026-08-27: เพิ่มการแนบไฟล์จริงกลับเข้ามาแล้ว โดยใช้ตาราง
/// submission_attachments ที่มีอยู่แล้วในสคีมาแต่ไม่เคยมี RPC ใดแตะเลย —
/// อัปโหลดผ่าน signed URL (submission-attachment-upload Edge Function)
/// เหมือนแพทเทิร์นเดียวกับ lesson-material/quiz-attachment
class _AssignmentSubmitSheet extends StatefulWidget {
  const _AssignmentSubmitSheet({
    required this.item,
    required this.onSubmitted,
    this.getAssignmentDetail,
    this.loadPreviousVersions,
    this.getAttachmentDownloadUrl,
    this.pickFiles,
    this.submitAssignment,
    this.uploadAttachment,
  });

  final _AssignmentWithCourse item;
  final VoidCallback onSubmitted;

  /// Read/write seams threaded to the corresponding AssignmentService
  /// static calls (and file_picker) in production — widget tests supply
  /// these to drive the submit/edit flow, including the real signed-URL
  /// attachment upload, without a live Supabase client or file picker.
  final Future<AssignmentDetail> Function(String assignmentId)?
  getAssignmentDetail;
  final Future<List<SubmissionVersion>> Function(String assignmentId)?
  loadPreviousVersions;
  final Future<String> Function(String attachmentId)? getAttachmentDownloadUrl;
  final Future<List<PlatformFile>?> Function()? pickFiles;
  final Future<({int version, String submissionVersionId})> Function({
    required String assignmentId,
    required String content,
  })?
  submitAssignment;
  final Future<String> Function({
    required String submissionVersionId,
    required String fileName,
    required Uint8List bytes,
  })?
  uploadAttachment;

  @override
  State<_AssignmentSubmitSheet> createState() => _AssignmentSubmitSheetState();
}

class _AssignmentSubmitSheetState extends State<_AssignmentSubmitSheet> {
  final _controller = TextEditingController();
  bool _submitting = false;
  bool _loadingPrevious = false;
  String? _detailError;
  AssignmentDetail? _detail;
  final List<PlatformFile> _pickedFiles = [];
  List<SubmissionAttachment> _previousAttachments = const [];

  bool get _isEdit => widget.item.submitted;

  @override
  void initState() {
    super.initState();
    _loadDetail();
    if (_isEdit) _loadPreviousSubmission();
  }

  Future<void> _loadDetail() async {
    try {
      final getDetail =
          widget.getAssignmentDetail ?? AssignmentService.getAssignment;
      final detail = await getDetail(widget.item.assignment.id);
      if (!mounted) return;
      setState(() => _detail = detail);
    } catch (_) {
      if (!mounted) return;
      setState(() => _detailError = 'โหลดรายละเอียดไม่สำเร็จ');
    }
  }

  /// แก้ไขงานที่ส่งไปแล้ว — โหลดข้อความ/ไฟล์แนบจากการส่งครั้งล่าสุดมาแสดง
  /// ก่อน ให้แก้ต่อได้แทนที่จะต้องพิมพ์ใหม่ทั้งหมด
  Future<void> _loadPreviousSubmission() async {
    setState(() => _loadingPrevious = true);
    try {
      final loadVersions = widget.loadPreviousVersions ??
          AssignmentService.listMySubmissionVersions;
      final versions = await loadVersions(widget.item.assignment.id);
      if (!mounted) return;
      if (versions.isNotEmpty) {
        final latest = versions.first;
        setState(() {
          _controller.text = latest.content ?? '';
          _previousAttachments = latest.attachments;
        });
      }
    } catch (_) {
      // เงียบไว้ — ยังแก้/ส่งใหม่ได้แม้โหลดของเดิมไม่สำเร็จ แค่ต้องพิมพ์ใหม่เอง
    } finally {
      if (mounted) setState(() => _loadingPrevious = false);
    }
  }

  Future<void> _openPreviousAttachment(SubmissionAttachment attachment) async {
    try {
      final getUrl = widget.getAttachmentDownloadUrl ??
          AssignmentService.getSubmissionAttachmentDownloadUrl;
      final url = await getUrl(attachment.id);
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('เปิดไฟล์แนบไม่สำเร็จ')));
    }
  }

  Future<void> _pickFiles() async {
    try {
      final pick = widget.pickFiles ??
          () async => (await FilePicker.pickFiles(withData: true))
              ?.files;
      final files = await pick();
      if (files == null) return;
      setState(() => _pickedFiles.addAll(files));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('เลือกไฟล์ไม่สำเร็จ')));
    }
  }

  Future<void> _submit() async {
    if (_controller.text.trim().isEmpty) return;
    setState(() => _submitting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final submit = widget.submitAssignment ?? AssignmentService.submitAssignment;
      final upload =
          widget.uploadAttachment ?? AssignmentService.uploadSubmissionAttachment;
      final result = await submit(
        assignmentId: widget.item.assignment.id,
        content: _controller.text.trim(),
      );

      for (final file in _pickedFiles) {
        final bytes = file.bytes;
        if (bytes == null) continue;
        await upload(
          submissionVersionId: result.submissionVersionId,
          fileName: file.name,
          bytes: bytes,
        );
      }

      if (!mounted) return;
      Navigator.pop(context);
      widget.onSubmitted();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('ส่งงานเรียบร้อยแล้ว'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      messenger.showSnackBar(const SnackBar(content: Text('ส่งงานไม่สำเร็จ กรุณาลองใหม่')));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Icon(
                  _isEdit ? Icons.edit_rounded : Icons.send_rounded,
                  color: SchoolPalette.deepGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEdit ? 'แก้ไขงานที่ส่งไปแล้ว' : 'ส่งงาน',
                      style: const TextStyle(
                        color: SchoolPalette.navy,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.item.assignment.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: SchoolPalette.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.close_rounded,
                  color: SchoolPalette.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(height: 1, color: SchoolPalette.glassBorder),
          const SizedBox(height: 14),
          if (_detailError != null)
            Text(
              _detailError!,
              style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12),
            )
          else if (_detail?.instructions != null)
            Text(
              _detail!.instructions!,
              style: const TextStyle(
                color: SchoolPalette.muted,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          if (_isEdit) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 15,
                    color: Color(0xFFB45309),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _loadingPrevious
                          ? 'กำลังโหลดสิ่งที่เคยส่งไว้...'
                          : 'แก้ไขข้อความด้านล่างแล้วส่งใหม่ได้ — ระบบจะเก็บ'
                                'เป็นครั้งที่ส่งใหม่ ไม่ทับของเดิม',
                      style: const TextStyle(
                        color: Color(0xFF92400E),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_previousAttachments.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'ไฟล์แนบจากการส่งครั้งก่อน',
                style: TextStyle(
                  color: SchoolPalette.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final a in _previousAttachments)
                    ActionChip(
                      avatar: const Icon(Icons.attach_file_rounded, size: 16),
                      label: Text(
                        a.fileName ?? 'ไฟล์แนบ',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      onPressed: () => _openPreviousAttachment(a),
                    ),
                ],
              ),
            ],
          ],
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: 'พิมพ์คำตอบ/สิ่งที่ต้องการส่งที่นี่...',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _submitting ? null : _pickFiles,
            icon: const Icon(Icons.attach_file_rounded, size: 16),
            label: const Text('แนบไฟล์'),
            style: OutlinedButton.styleFrom(
              foregroundColor: SchoolPalette.deepGreen,
              side: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
          ),
          if (_pickedFiles.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final file in _pickedFiles)
                  Chip(
                    label: Text(
                      file.name,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    onDeleted: _submitting
                        ? null
                        : () => setState(() => _pickedFiles.remove(file)),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: SchoolPalette.navy,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('ปิดหน้าต่าง'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                  label: Text(_isEdit ? 'ยืนยันการส่งใหม่' : 'ยืนยันการส่งงาน'),
                  style: FilledButton.styleFrom(
                    backgroundColor: SchoolPalette.deepGreen,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AssignmentCard extends StatelessWidget {
  const AssignmentCard({
    super.key,
    required this.item,
    required this.onSubmitted,
    this.getAssignmentDetail,
    this.loadPreviousVersions,
    this.getAttachmentDownloadUrl,
    this.pickFiles,
    this.submitAssignment,
    this.uploadAttachment,
  });

  final _AssignmentWithCourse item;
  final VoidCallback onSubmitted;

  /// Threaded down to the submit sheet's own seams — see
  /// _AssignmentSubmitSheet for what each one replaces in production.
  final Future<AssignmentDetail> Function(String assignmentId)?
  getAssignmentDetail;
  final Future<List<SubmissionVersion>> Function(String assignmentId)?
  loadPreviousVersions;
  final Future<String> Function(String attachmentId)? getAttachmentDownloadUrl;
  final Future<List<PlatformFile>?> Function()? pickFiles;
  final Future<({int version, String submissionVersionId})> Function({
    required String assignmentId,
    required String content,
  })?
  submitAssignment;
  final Future<String> Function({
    required String submissionVersionId,
    required String fileName,
    required Uint8List bytes,
  })?
  uploadAttachment;

  ({String label, Color color, Color bg, IconData icon}) get _status {
    if (item.submitted) {
      return (
        label: 'ส่งแล้ว',
        color: SchoolPalette.deepGreen,
        bg: SchoolPalette.softGreenBg,
        icon: Icons.check_circle_rounded,
      );
    }
    final dueAt = item.assignment.dueAt;
    if (dueAt != null && dueAt.isBefore(DateTime.now())) {
      return (
        label: 'เลยกำหนดส่งแล้ว',
        color: const Color(0xFFDC2626),
        bg: const Color(0xFFFEF2F2),
        icon: Icons.assignment_late_rounded,
      );
    }
    if (dueAt != null && dueAt.difference(DateTime.now()).inHours <= 24) {
      return (
        label: 'ด่วนที่สุด',
        color: const Color(0xFFDC2626),
        bg: const Color(0xFFFEF2F2),
        icon: Icons.priority_high_rounded,
      );
    }
    return (
      label: 'ยังไม่ส่ง',
      color: const Color(0xFFD97706),
      bg: const Color(0xFFFFFBEB),
      icon: Icons.assignment_late_rounded,
    );
  }

  String get _dueDateLabel {
    if (item.submitted) {
      final at = item.submittedAt;
      return at == null
          ? 'ส่งแล้ว'
          : 'ส่งแล้ว ${at.day}/${at.month}/${at.year}';
    }
    final dueAt = item.assignment.dueAt;
    if (dueAt == null) return 'ไม่มีกำหนดส่ง';
    return 'กำหนดส่ง ${dueAt.day}/${dueAt.month}/${dueAt.year} '
        '${dueAt.hour.toString().padLeft(2, '0')}:${dueAt.minute.toString().padLeft(2, '0')} น.';
  }

  void _openSubmit(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AssignmentSubmitSheet(
        item: item,
        onSubmitted: onSubmitted,
        getAssignmentDetail: getAssignmentDetail,
        loadPreviousVersions: loadPreviousVersions,
        getAttachmentDownloadUrl: getAttachmentDownloadUrl,
        pickFiles: pickFiles,
        submitAssignment: submitAssignment,
        uploadAttachment: uploadAttachment,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFBEDCD0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
          BoxShadow(
            color: Color(0x0E0F172A),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () => _openSubmit(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: status.bg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(status.icon, size: 12, color: status.color),
                          const SizedBox(width: 4),
                          Text(
                            status.label,
                            style: TextStyle(
                              color: status.color,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        item.courseName,
                        style: const TextStyle(
                          color: SchoolPalette.navy,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  item.assignment.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SchoolPalette.navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                Container(height: 1, color: SchoolPalette.glassBorder),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 13,
                            color: status.color,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              _dueDateLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: status.color,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                height: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildActionPill(status.color),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionPill(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            item.submitted ? Icons.edit_rounded : Icons.upload_file_rounded,
            size: 15,
            color: Colors.white,
          ),
          const SizedBox(width: 5),
          Text(
            item.submitted ? 'แก้ไข' : 'ส่งงาน',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          SizedBox(width: 4),
          Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.white),
        ],
      ),
    );
  }
}
