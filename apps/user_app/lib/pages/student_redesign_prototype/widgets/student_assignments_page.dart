import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
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
  const StudentAssignmentsPage({super.key});

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
      final courses = (await CourseService.listMyCourses())
          .where((c) => c.isActive)
          .toList();
      final assignmentLists = await Future.wait(
        courses.map((c) => AssignmentService.listAssignments(c.id)),
      );

      final published = <(AssignmentSummary, CourseSummary)>[];
      for (var i = 0; i < courses.length; i++) {
        for (final a in assignmentLists[i].where((a) => a.isPublished)) {
          published.add((a, courses[i]));
        }
      }

      final submissionChecks = await Future.wait(
        published.map(
          (e) => AssignmentService.listMySubmissionVersions(e.$1.id),
        ),
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
        _error = 'โหลดข้อมูลไม่สำเร็จ: $e';
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
          child: AssignmentCard(item: item, onSubmitted: _load),
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

/// ส่งงานจริง — ระบบนี้รับแค่ข้อความ (submit_assignment RPC มี content เป็น
/// text เท่านั้น ไม่มีระบบแนบไฟล์ผูกกับใบงานเลย) จึงตัด UI อัปโหลดไฟล์เดิม
/// ที่จำลอง progress bar ปลอมออกทั้งหมด แทนที่ด้วยฟอร์มข้อความจริง
class _AssignmentSubmitSheet extends StatefulWidget {
  const _AssignmentSubmitSheet({required this.item, required this.onSubmitted});

  final _AssignmentWithCourse item;
  final VoidCallback onSubmitted;

  @override
  State<_AssignmentSubmitSheet> createState() => _AssignmentSubmitSheetState();
}

class _AssignmentSubmitSheetState extends State<_AssignmentSubmitSheet> {
  final _controller = TextEditingController();
  bool _submitting = false;
  String? _detailError;
  AssignmentDetail? _detail;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      final detail = await AssignmentService.getAssignment(
        widget.item.assignment.id,
      );
      if (!mounted) return;
      setState(() => _detail = detail);
    } catch (e) {
      if (!mounted) return;
      setState(() => _detailError = 'โหลดรายละเอียดไม่สำเร็จ: $e');
    }
  }

  Future<void> _submit() async {
    if (_controller.text.trim().isEmpty) return;
    setState(() => _submitting = true);
    try {
      await AssignmentService.submitAssignment(
        assignmentId: widget.item.assignment.id,
        content: _controller.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context);
      widget.onSubmitted();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ส่งงานเรียบร้อยแล้ว'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ส่งงานไม่สำเร็จ: $e')));
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
                child: const Icon(
                  Icons.send_rounded,
                  color: SchoolPalette.deepGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ส่งงาน',
                      style: TextStyle(
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
                  label: const Text('ยืนยันการส่งงาน'),
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
  });

  final _AssignmentWithCourse item;
  final VoidCallback onSubmitted;

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
    if (item.submitted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _AssignmentSubmitSheet(item: item, onSubmitted: onSubmitted),
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
                    if (!item.submitted) _buildActionPill(status.color),
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
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.upload_file_rounded, size: 15, color: Colors.white),
          SizedBox(width: 5),
          Text(
            'ส่งงาน',
            style: TextStyle(
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
