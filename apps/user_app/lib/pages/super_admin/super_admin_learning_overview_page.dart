import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import 'theme/app_palette.dart';
import 'widgets/dev_ui.dart';

/// Real cross-school course/lesson overview for Super Admin —
/// oversight only (counts pulled from the courses/lessons tables that
/// teachers already populate for real). Not an editor: editing content
/// stays with teachers via CourseService/LessonService, where it
/// already works.
class SuperAdminLearningOverviewPage extends StatefulWidget {
  const SuperAdminLearningOverviewPage({
    super.key,
    this.embedded = false,
    this.loadCourses,
  });

  /// True when embedded in [SuperAdminNavigationShell]'s desktop sidebar
  /// layout — suppresses this page's own AppBar since the sidebar
  /// already shows which page is selected.
  final bool embedded;

  final Future<List<CourseOverviewRecord>> Function()? loadCourses;

  @override
  State<SuperAdminLearningOverviewPage> createState() =>
      _SuperAdminLearningOverviewPageState();
}

class _SuperAdminLearningOverviewPageState
    extends State<SuperAdminLearningOverviewPage> {
  final SchoolAdminPlatformService _service = SchoolAdminPlatformService();

  bool _isLoading = true;
  String? _loadError;
  List<CourseOverviewRecord> _records = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }
    try {
      final records =
          await (widget.loadCourses ?? _service.getCoursesOverview)();
      if (!mounted) return;
      setState(() {
        _records = records;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = e.toString();
      });
    }
  }

  int get _totalCourses =>
      _records.fold(0, (sum, r) => sum + r.coursesTotal);
  int get _totalLessons =>
      _records.fold(0, (sum, r) => sum + r.lessonsTotal);
  int get _totalPublished =>
      _records.fold(0, (sum, r) => sum + r.lessonsPublished);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: widget.embedded
          ? null
          : AppBar(
              title: const Text(
                'แพลตฟอร์มการเรียนรู้ (Learning Overview)',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              actions: [
                IconButton(
                  tooltip: 'รีเฟรชข้อมูล',
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: () => _load(),
                ),
              ],
            ),
      body: _isLoading && _records.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _load(showLoading: false),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  if (_loadError != null && _records.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppPalette.carnivalRed.withAlpha(20),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        'โหลดข้อมูลไม่สำเร็จ: $_loadError',
                        style: const TextStyle(
                          color: AppPalette.carnivalRed,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  AppPanel(
                    title: 'ภาพรวมทั้งระบบ',
                    child: Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            icon: Icons.menu_book_rounded,
                            title: 'คอร์สทั้งหมด',
                            value: '$_totalCourses',
                            footnote: '${_records.length} โรงเรียน',
                            accent: AppPalette.deepBlue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            icon: Icons.description_rounded,
                            title: 'บทเรียนทั้งหมด',
                            value: '$_totalLessons',
                            footnote: 'เผยแพร่แล้ว $_totalPublished',
                            accent: AppPalette.gardenGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  AppPanel(
                    title: 'แยกตามโรงเรียน (School Overview)',
                    child: _records.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Text(
                              'ยังไม่มีโรงเรียนในระบบ',
                              style: TextStyle(color: AppPalette.textSecondary),
                            ),
                          )
                        : Column(
                            children: [
                              for (int i = 0; i < _records.length; i++) ...[
                                _schoolRow(_records[i]),
                                if (i < _records.length - 1)
                                  const Divider(height: 20),
                              ],
                            ],
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _schoolRow(CourseOverviewRecord r) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppPalette.deepBlue.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.apartment_rounded,
            color: AppPalette.deepBlue,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                r.schoolName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppPalette.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${r.coursesTotal} คอร์ส (${r.coursesActive} กำลังเปิด) • '
                '${r.lessonsTotal} บทเรียน',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppPalette.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            StatusBadge(
              label: 'เผยแพร่ ${r.lessonsPublished}',
              color: AppPalette.gardenGreen,
            ),
            const SizedBox(height: 4),
            if (r.lessonsDraft > 0)
              Text(
                'ร่าง ${r.lessonsDraft}',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppPalette.textSecondary,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
