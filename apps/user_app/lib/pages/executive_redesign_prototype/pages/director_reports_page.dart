import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_palette.dart';
import '../widgets/director_common_widgets.dart';
import '../widgets/timeline_feed.dart';

/// Read seams so loading / data / empty / failure can each be driven in a
/// test, and write seams so the review and upload paths can be exercised
/// without a live backend.
typedef SchoolReportsLoader = Future<List<SchoolReport>> Function();
typedef ReportSummaryLoader = Future<SchoolReportSummary?> Function();
typedef ReportRequirementsLoader = Future<List<ReportRequirement>> Function();
typedef ReportDepartmentsLoader = Future<List<SchoolDepartment>> Function();
typedef ReportReviewer =
    Future<void> Function(String reportId, String status, String? note);
typedef ReportDownloadUrlLoader = Future<String> Function(String reportId);
typedef ReportSubmitter =
    Future<String> Function({
      required String title,
      required String reportType,
      required String fileName,
      required Uint8List bytes,
      String? departmentId,
      String? description,
    });

class DirectorReportsPage extends StatefulWidget {
  const DirectorReportsPage({
    super.key,
    this.loadReports,
    this.loadSummary,
    this.loadRequirements,
    this.loadDepartments,
    this.reviewReport,
    this.loadDownloadUrl,
    this.submitReport,
  });

  final SchoolReportsLoader? loadReports;
  final ReportSummaryLoader? loadSummary;
  final ReportRequirementsLoader? loadRequirements;
  final ReportDepartmentsLoader? loadDepartments;
  final ReportReviewer? reviewReport;
  final ReportDownloadUrlLoader? loadDownloadUrl;
  final ReportSubmitter? submitReport;

  @override
  State<DirectorReportsPage> createState() => _DirectorReportsPageState();
}

class _DirectorReportsPageState extends State<DirectorReportsPage> {
  static const String _anyDepartment = 'ทุกฝ่าย';
  static const String _anyReportType = 'ทุกประเภท';
  static const String _anyFileType = 'ทุกไฟล์';
  static const String _anyStatus = 'ทุกสถานะ';

  String searchText = '';
  String selectedDepartment = _anyDepartment;
  String selectedReportType = _anyReportType;
  String selectedFileType = _anyFileType;
  String selectedStatus = _anyStatus;

  List<SchoolReport> _reports = const [];
  List<ReportRequirement> _requirements = const [];
  List<SchoolDepartment> _departments = const [];

  /// Null while loading and after a failure — never a zeroed summary. The old
  /// page printed 128 / 102 / 8 / 12 / 3 / 2 with nothing behind them.
  SchoolReportSummary? _summary;

  bool _loading = true;
  bool _loadFailed = false;

  /// Keyed by report id so one row's review spinner does not lock the page.
  final Set<String> _busyReports = <String>{};
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final results = await Future.wait<Object?>([
        widget.loadReports?.call() ?? SchoolReportService.listReports(),
        widget.loadSummary?.call() ?? SchoolReportService.getSummary(),
        widget.loadRequirements?.call() ??
            SchoolReportService.listRequirements(onlyOpen: true),
        widget.loadDepartments?.call() ??
            StaffOrgService.listDepartments(kind: 'administrative'),
      ]);
      if (!mounted) return;
      setState(() {
        _reports = results[0] as List<SchoolReport>;
        _summary = results[1] as SchoolReportSummary?;
        _requirements = results[2] as List<ReportRequirement>;
        _departments = results[3] as List<SchoolDepartment>;
        _loading = false;
      });
    } catch (e) {
      debugPrint('DirectorReportsPage load failed: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  // -------------------------------------------------------------------------
  // Filters — every option is built from the rows on screen.
  //
  // The four lists that used to sit here were written by hand: eight ฝ่าย
  // including a 'ระบบอัตโนมัติ' that nothing produces, and a status list with
  // 'เกินกำหนด', which is not a state a filed report can be in — lateness
  // belongs to a requirement's due date.
  // -------------------------------------------------------------------------

  List<String> get _departmentOptions {
    final names = <String>{
      for (final d in _departments) d.name,
      for (final r in _reports)
        if (r.departmentName != null) r.departmentName!,
    };
    final sorted = names.toList()..sort();
    return [_anyDepartment, ...sorted];
  }

  List<String> get _reportTypeOptions {
    final labels = _reports.map((r) => r.reportTypeLabel).toSet().toList()
      ..sort();
    return [_anyReportType, ...labels];
  }

  List<String> get _fileTypeOptions {
    final labels = _reports.map((r) => r.fileTypeLabel).toSet().toList()
      ..sort();
    return [_anyFileType, ...labels];
  }

  List<String> get _statusOptions {
    final labels = _reports.map((r) => r.statusLabel).toSet().toList()..sort();
    return [_anyStatus, ...labels];
  }

  String _safeSelection(String selected, List<String> options) =>
      options.contains(selected) ? selected : options.first;

  List<SchoolReport> _filteredReports() {
    final query = searchText.trim().toLowerCase();

    return _reports.where((report) {
      final matchesSearch =
          query.isEmpty ||
          report.title.toLowerCase().contains(query) ||
          report.fileName.toLowerCase().contains(query) ||
          report.submitterName.toLowerCase().contains(query) ||
          (report.submitterPosition ?? '').toLowerCase().contains(query) ||
          (report.departmentName ?? '').toLowerCase().contains(query);

      final matchesDepartment =
          selectedDepartment == _anyDepartment ||
          report.departmentName == selectedDepartment;

      final matchesType =
          selectedReportType == _anyReportType ||
          report.reportTypeLabel == selectedReportType;

      final matchesFile =
          selectedFileType == _anyFileType ||
          report.fileTypeLabel == selectedFileType;

      final matchesStatus =
          selectedStatus == _anyStatus || report.statusLabel == selectedStatus;

      return matchesSearch &&
          matchesDepartment &&
          matchesType &&
          matchesFile &&
          matchesStatus;
    }).toList();
  }

  bool _hasActiveFilters() =>
      searchText.isNotEmpty ||
      selectedDepartment != _anyDepartment ||
      selectedReportType != _anyReportType ||
      selectedFileType != _anyFileType ||
      selectedStatus != _anyStatus;

  void _clearFilters() {
    setState(() {
      searchText = '';
      selectedDepartment = _anyDepartment;
      selectedReportType = _anyReportType;
      selectedFileType = _anyFileType;
      selectedStatus = _anyStatus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredReports();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DirectorSectionHeader(
            title: 'รายงานผู้บริหาร',
            subtitle:
                'ทะเบียนรายงานที่ฝ่ายต่าง ๆ ส่งเข้ามา — ใครส่ง ไฟล์อะไร เมื่อไร '
                'อยู่ฝ่ายไหน และสถานะการตรวจ',
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppPalette.primaryPink,
              ),
              onPressed: _uploading ? null : _pickAndSubmitReport,
              icon: _uploading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file_rounded, size: 16),
              label: Text(_uploading ? 'กำลังส่ง...' : 'ส่งรายงาน'),
            ),
          ),
          const SizedBox(height: 14),
          if (_loadFailed) ...[_loadErrorBanner(), const SizedBox(height: 14)],
          _statsAndActivityCard(),
          const SizedBox(height: 16),
          _allReportsSection(filtered),
        ],
      ),
    );
  }

  /// Failure stated on the page. Without it an unreachable backend renders as
  /// a school that has filed no reports at all.
  Widget _loadErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 20,
            color: Color(0xFFB91C1C),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'โหลดทะเบียนรายงานไม่สำเร็จ ตัวเลขและรายการด้านล่างจึงยังไม่ทราบ',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFFB91C1C),
              ),
            ),
          ),
          TextButton(
            onPressed: _loading ? null : _load,
            child: const Text('ลองใหม่'),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Summary rail
  // -------------------------------------------------------------------------

  List<_ReportSummaryCard> _summaryItems() {
    final s = _summary;
    // '—' rather than 0: an unread figure and a figure of zero are different
    // statements, and only one of them is safe to act on.
    String figure(int Function(SchoolReportSummary s) pick) =>
        s == null ? '—' : '${pick(s)}';

    return [
      _ReportSummaryCard(
        title: 'รายงานทั้งหมด',
        value: figure((s) => s.totalReports),
        subtitle: 'ในทะเบียนของโรงเรียน',
        icon: Icons.folder_copy_rounded,
        color: AppPalette.softPink,
      ),
      _ReportSummaryCard(
        title: 'ส่งเดือนนี้',
        value: figure((s) => s.submittedThisMonth),
        subtitle: 'นับตามวันที่ส่งจริง',
        icon: Icons.upload_file_rounded,
        color: AppPalette.softBlue,
      ),
      _ReportSummaryCard(
        title: 'รอตรวจ',
        value: figure((s) => s.awaitingReview),
        subtitle: 'ยังไม่ได้ตัดสิน',
        icon: Icons.rate_review_rounded,
        color: AppPalette.softCream,
      ),
      _ReportSummaryCard(
        title: 'อนุมัติแล้ว',
        value: figure((s) => s.approved),
        subtitle: 'ผ่านการตรวจ',
        icon: Icons.verified_rounded,
        color: AppPalette.softMint,
      ),
      _ReportSummaryCard(
        title: 'ต้องแก้ไข',
        value: figure((s) => s.needsRevision),
        subtitle: 'ส่งกลับผู้จัดทำแล้ว',
        icon: Icons.edit_document,
        color: AppPalette.softPink2,
      ),
      _ReportSummaryCard(
        title: 'เกินกำหนด',
        value: figure((s) => s.overdueRequirements),
        // Named precisely: it counts รายการที่สั่งให้ส่ง, not files.
        subtitle: 'รายการที่เลยกำหนดส่ง',
        icon: Icons.warning_amber_rounded,
        color: AppPalette.softPink2,
      ),
    ];
  }

  /// Slim vertical rail instead of 6 equal boxes — most of the numbers are 0
  /// until reports actually get filed, and 6 empty boxes each claiming a
  /// quarter of the width wastes space no matter the number inside.
  Widget _statRail() {
    final items = _summaryItems();

    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _statRailItem(items[i]),
        ],
      ],
    );
  }

  Widget _statRailItem(_ReportSummaryCard item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppPalette.pageBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: item.color,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(item.icon, size: 14, color: AppPalette.textDark),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 8.5,
                    color: AppPalette.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 7.4,
                    color: AppPalette.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Stats + activity feed — one shared card. Recent submissions and open
  // requirements are one feed instead of two side-by-side cards that were
  // both empty at the same time, and the stat rail sits inside the same
  // card as the feed instead of floating unbordered beside a bordered one.
  // -------------------------------------------------------------------------

  Widget _statsAndActivityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'กิจกรรมรายงาน',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'รายงานที่ส่งเข้ามาล่าสุด และรายการที่กำหนดให้ส่งแต่ยังไม่ครบ',
            style: TextStyle(fontSize: 10, color: AppPalette.textMuted),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 640) {
                return Column(
                  children: [
                    _statRail(),
                    const SizedBox(height: 20),
                    _activityFeedBody(),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 200, child: _statRail()),
                  const SizedBox(width: 18),
                  Expanded(child: _activityFeedBody()),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _activityFeedBody() {
    final recent = _reports.take(5).toList();
    final bothEmpty =
        !_loading && !_loadFailed && recent.isEmpty && _requirements.isEmpty;

    if (_loading) {
      return _notice(icon: Icons.hourglass_empty_rounded, title: 'กำลังโหลด');
    }
    if (_loadFailed) {
      return _notice(
        icon: Icons.cloud_off_rounded,
        title: 'โหลดกิจกรรมรายงานไม่สำเร็จ',
      );
    }
    if (bothEmpty) {
      return const TimelineEmptyState(
        icon: Icons.inbox_rounded,
        title: 'ยังไม่มีกิจกรรมรายงาน',
        message:
            'รายงานล่าสุดที่ส่งเข้ามาและรายการที่ค้างส่งจะขึ้นตรงนี้ '
            '— ตอนนี้ยังไม่มีใครส่งเข้ามาเลย',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _feedSubHeader('ส่งล่าสุด'),
        const SizedBox(height: 10),
        if (recent.isEmpty)
          _feedSubEmpty('ยังไม่มีรายงานส่งเข้ามา')
        else
          TimelineFeed(items: [for (final r in recent) _recentReportItem(r)]),
        const SizedBox(height: 20),
        _feedSubHeader('กำลังรอส่ง'),
        const SizedBox(height: 10),
        if (_requirements.isEmpty)
          _feedSubEmpty('ไม่มีรายการที่ค้างส่ง')
        else
          TimelineFeed(
            items: [for (final r in _requirements) _requirementItem(r)],
          ),
      ],
    );
  }

  Widget _feedSubHeader(String title) => Text(
    title,
    style: const TextStyle(
      fontSize: 10.5,
      fontWeight: FontWeight.w800,
      color: AppPalette.textMuted,
      letterSpacing: .2,
    ),
  );

  Widget _feedSubEmpty(String text) => Text(
    text,
    style: const TextStyle(fontSize: 10, color: AppPalette.textMuted),
  );

  TimelineItem _recentReportItem(SchoolReport report) {
    return TimelineItem(
      dotColor: _statusColor(report.status),
      title: report.fileName,
      trailing: report.statusLabel,
      meta:
          'ส่งโดย ${report.submitterName} • '
          '${report.departmentName ?? 'ไม่ระบุฝ่าย'}',
      // No page count: nothing on the server can count the pages of an
      // uploaded file, and the old tile printed one anyway.
      detail: '${_dateTimeLabel(report.submittedAt)} • ${report.sizeLabel}',
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: () => _showReportDetail(report),
          child: const Text(
            'ดูรายละเอียด',
            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  TimelineItem _requirementItem(ReportRequirement item) {
    final color = item.isOverdue ? AppPalette.danger : AppPalette.warning;

    return TimelineItem(
      dotColor: color,
      title: item.title,
      trailing: item.isOverdue ? 'เกินกำหนด' : null,
      meta: item.reportTypeLabel,
      detail: item.dueDate == null
          ? 'ไม่ได้กำหนดวันส่ง'
          : 'กำหนดส่ง ${_dateLabel(item.dueDate!)}',
      subLines: [
        'ส่งแล้ว ${item.filedCount}/${item.expectedCount} ฝ่าย',
        // The old card stopped at "3/6". Naming who is missing is the part
        // the director can act on.
        if (item.missingDepartments.isNotEmpty)
          'ยังไม่ส่ง: ${item.missingDepartments.join(' • ')}',
      ],
    );
  }

  // -------------------------------------------------------------------------
  // The register itself
  // -------------------------------------------------------------------------

  Widget _allReportsSection(List<SchoolReport> filtered) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ไฟล์รายงานทั้งหมด',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'ค้นหาจากชื่อรายงาน ชื่อไฟล์ ผู้ส่ง หรือตำแหน่ง '
            'และกรองตามฝ่าย ประเภทรายงาน ประเภทไฟล์ หรือสถานะ',
            style: TextStyle(fontSize: 10, color: AppPalette.textMuted),
          ),
          const SizedBox(height: 14),
          _filtersArea(),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                _loading
                    ? 'กำลังโหลด...'
                    : _loadFailed
                    ? 'ยังไม่ทราบจำนวน'
                    : 'พบ ${filtered.length} ไฟล์',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppPalette.textMuted,
                ),
              ),
              const Spacer(),
              if (_hasActiveFilters())
                TextButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('ล้างตัวกรอง'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_loading)
            _notice(icon: Icons.hourglass_empty_rounded, title: 'กำลังโหลด')
          else if (_loadFailed)
            _notice(
              icon: Icons.cloud_off_rounded,
              title: 'โหลดทะเบียนรายงานไม่สำเร็จ',
              detail: 'ยังไม่ทราบว่ามีรายงานอยู่กี่ไฟล์',
            )
          else if (_reports.isEmpty)
            _notice(
              icon: Icons.folder_open_rounded,
              title: 'ยังไม่มีรายงานในทะเบียน',
              detail: 'ยังไม่มีฝ่ายใดส่งไฟล์เข้ามา',
            )
          else if (filtered.isEmpty)
            // A filtered-to-nothing list is not an empty register, and the
            // two must not read the same.
            _notice(
              icon: Icons.find_in_page_rounded,
              title: 'ไม่พบไฟล์รายงานตามเงื่อนไข',
              detail:
                  'มีรายงานในทะเบียน ${_reports.length} ไฟล์ '
                  'แต่ไม่มีไฟล์ที่ตรงกับตัวกรองที่เลือก',
            )
          else
            ...filtered.map(_reportFileTile),
        ],
      ),
    );
  }

  /// Search gets its own full-width row (the primary way to narrow the
  /// register); the 4 filters sit below as small pills instead of 4
  /// equal-width boxes that, unfiltered, all just repeat "ทุก...".
  Widget _filtersArea() {
    final search = TextField(
      onChanged: (value) => setState(() => searchText = value),
      decoration: InputDecoration(
        hintText: 'ค้นหาชื่อรายงาน ไฟล์ ผู้ส่ง หรือฝ่าย...',
        hintStyle: const TextStyle(fontSize: 9.5),
        prefixIcon: const Icon(
          Icons.search_rounded,
          size: 18,
          color: AppPalette.primaryPink,
        ),
        filled: true,
        fillColor: AppPalette.pageBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppPalette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppPalette.border),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        search,
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _filterPill(
              value: _safeSelection(selectedDepartment, _departmentOptions),
              items: _departmentOptions,
              icon: Icons.account_tree_rounded,
              onChanged: (value) {
                if (value == null) return;
                setState(() => selectedDepartment = value);
              },
            ),
            _filterPill(
              value: _safeSelection(selectedReportType, _reportTypeOptions),
              items: _reportTypeOptions,
              icon: Icons.event_note_rounded,
              onChanged: (value) {
                if (value == null) return;
                setState(() => selectedReportType = value);
              },
            ),
            _filterPill(
              value: _safeSelection(selectedFileType, _fileTypeOptions),
              items: _fileTypeOptions,
              icon: Icons.insert_drive_file_rounded,
              onChanged: (value) {
                if (value == null) return;
                setState(() => selectedFileType = value);
              },
            ),
            _filterPill(
              value: _safeSelection(selectedStatus, _statusOptions),
              items: _statusOptions,
              icon: Icons.fact_check_rounded,
              onChanged: (value) {
                if (value == null) return;
                setState(() => selectedStatus = value);
              },
            ),
          ],
        ),
      ],
    );
  }

  // A PopupMenuButton instead of a DropdownButton: DropdownButton reserves
  // Material's default ~48px touch-target height and computes its own
  // intrinsic width, both of which fought the compact pill shape once
  // squeezed into a Wrap. PopupMenuButton just wraps whatever child it's
  // given, so the pill's own Row fully controls its layout.
  Widget _filterPill({
    required String value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return PopupMenuButton<String>(
      initialValue: value,
      onSelected: onChanged,
      itemBuilder: (context) => [
        for (final item in items)
          PopupMenuItem<String>(value: item, child: Text(item)),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppPalette.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppPalette.primaryPink),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 130),
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: AppPalette.textDark,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.expand_more_rounded,
              size: 16,
              color: AppPalette.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _reportFileTile(SchoolReport report) {
    final fileColor = _fileColor(report.fileType);
    final statusColor = _statusColor(report.status);

    return InkWell(
      borderRadius: BorderRadius.circular(17),
      onTap: () => _showReportDetail(report),
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: AppPalette.border),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 760;

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _fileIcon(report),
                      const SizedBox(width: 10),
                      Expanded(child: _reportMainInfo(report)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      _smallTag(report.fileTypeLabel, fileColor),
                      _smallTag(
                        report.reportTypeLabel,
                        AppPalette.learningBlue,
                      ),
                      _smallTag(report.statusLabel, statusColor),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ส่งโดย ${report.submitterName} • '
                    '${_dateTimeLabel(report.submittedAt)}',
                    style: const TextStyle(
                      fontSize: 8.5,
                      color: AppPalette.textMuted,
                    ),
                  ),
                ],
              );
            }

            return Row(
              children: [
                _fileIcon(report),
                const SizedBox(width: 11),
                Expanded(flex: 3, child: _reportMainInfo(report)),
                Expanded(
                  flex: 2,
                  child: _listInfo('ผู้ส่ง', report.submitterName),
                ),
                Expanded(
                  flex: 2,
                  child: _listInfo('ฝ่าย', report.departmentName ?? 'ไม่ระบุ'),
                ),
                Expanded(child: _listInfo('ประเภท', report.fileTypeLabel)),
                Expanded(child: _listInfo('ขนาด', report.sizeLabel)),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppPalette.tint(statusColor, 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    report.statusLabel,
                    style: TextStyle(
                      fontSize: 8.4,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppPalette.textMuted,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _fileIcon(SchoolReport report) {
    final color = _fileColor(report.fileType);

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppPalette.tint(color, 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(_fileIconData(report.fileType), size: 21, color: color),
    );
  }

  Widget _reportMainInfo(SchoolReport report) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          report.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 10.8, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(
          report.fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 8.7, color: AppPalette.textMuted),
        ),
        const SizedBox(height: 2),
        Text(
          '${report.reportTypeLabel} • ${_periodLabel(report)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 8.2, color: AppPalette.textMuted),
        ),
      ],
    );
  }

  Widget _listInfo(String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 8.1, color: AppPalette.textMuted),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 8.8, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _smallTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppPalette.tint(color, 0.09),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 8.2,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _notice({
    required IconData icon,
    required String title,
    String? detail,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 26),
      decoration: BoxDecoration(
        color: AppPalette.pageBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, size: 30, color: AppPalette.textMuted),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
          if (detail != null) ...[
            const SizedBox(height: 4),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 9.6,
                height: 1.45,
                color: AppPalette.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Detail + review
  // -------------------------------------------------------------------------

  void _showReportDetail(SchoolReport report) {
    final fileColor = _fileColor(report.fileType);
    final statusColor = _statusColor(report.status);
    final busy = _busyReports.contains(report.reportId);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 20,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720, maxHeight: 760),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppPalette.tint(fileColor, 0.10),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          _fileIconData(report.fileType),
                          color: fileColor,
                          size: 23,
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              report.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              report.fileName,
                              style: const TextStyle(
                                fontSize: 9.5,
                                color: AppPalette.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 13),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      _smallTag(report.fileTypeLabel, fileColor),
                      _smallTag(
                        report.reportTypeLabel,
                        AppPalette.learningBlue,
                      ),
                      _smallTag(report.statusLabel, statusColor),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _detailSectionTitle('ข้อมูลไฟล์'),
                          _detailRow('ชื่อไฟล์', report.fileName),
                          _detailRow('ประเภทไฟล์', report.fileTypeLabel),
                          _detailRow('ขนาดไฟล์', report.sizeLabel),
                          // จำนวนหน้า is gone: no column, and no way to
                          // compute one from an arbitrary upload.
                          _detailRow('ช่วงข้อมูล', _periodLabel(report)),
                          const SizedBox(height: 13),
                          _detailSectionTitle('ข้อมูลผู้ส่ง'),
                          _detailRow('ผู้ส่ง', report.submitterName),
                          _detailRow(
                            'ตำแหน่ง',
                            report.submitterPosition ?? 'ยังไม่ได้ระบุตำแหน่ง',
                          ),
                          _detailRow(
                            'ฝ่าย',
                            report.departmentName ?? 'ไม่ได้สังกัดฝ่าย',
                          ),
                          _detailRow(
                            'ส่งเมื่อ',
                            _dateTimeLabel(report.submittedAt),
                          ),
                          if (report.requirementTitle != null)
                            _detailRow(
                              'ส่งตามรายการ',
                              report.requirementTitle!,
                            ),
                          const SizedBox(height: 13),
                          _detailSectionTitle('รายละเอียดรายงาน'),
                          Text(
                            report.description ?? 'ผู้ส่งไม่ได้กรอกรายละเอียด',
                            style: const TextStyle(
                              fontSize: 9.7,
                              height: 1.5,
                              color: AppPalette.textMuted,
                            ),
                          ),
                          const SizedBox(height: 13),
                          _detailSectionTitle('ผลการตรวจ'),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppPalette.tint(statusColor, 0.06),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              report.reviewedAt == null
                                  ? 'ยังไม่ได้ตรวจ'
                                  : '${report.statusLabel} โดย '
                                        '${report.reviewerName ?? 'ไม่ทราบผู้ตรวจ'} '
                                        'เมื่อ ${_dateTimeLabel(report.reviewedAt!)}'
                                        '${report.reviewNote == null ? '' : '\n${report.reviewNote}'}',
                              style: const TextStyle(
                                fontSize: 9.7,
                                height: 1.5,
                                color: AppPalette.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 520;

                      final downloadButton = OutlinedButton.icon(
                        onPressed: busy
                            ? null
                            : () => _openReport(dialogContext, report),
                        icon: const Icon(Icons.download_rounded, size: 16),
                        label: const Text('เปิด / ดาวน์โหลด'),
                      );

                      final reviseButton = OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppPalette.danger,
                        ),
                        onPressed: busy
                            ? null
                            : () => _askForRevision(dialogContext, report),
                        icon: const Icon(Icons.edit_document, size: 16),
                        label: const Text('ให้แก้ไข'),
                      );

                      final approveButton = FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppPalette.primaryPink,
                        ),
                        onPressed: busy || report.isApproved
                            ? null
                            : () => _review(
                                dialogContext,
                                report,
                                'approved',
                                null,
                              ),
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: Text(
                          report.isApproved ? 'อนุมัติแล้ว' : 'อนุมัติ',
                        ),
                      );

                      if (compact) {
                        return Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: downloadButton,
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: reviseButton,
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: approveButton,
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: downloadButton),
                          const SizedBox(width: 9),
                          Expanded(child: reviseButton),
                          const SizedBox(width: 9),
                          Expanded(child: approveButton),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openReport(
    BuildContext dialogContext,
    SchoolReport report,
  ) async {
    setState(() => _busyReports.add(report.reportId));
    try {
      final url =
          await (widget.loadDownloadUrl?.call(report.reportId) ??
              SchoolReportService.getDownloadUrl(report.reportId));
      final uri = Uri.tryParse(url);
      if (uri == null) throw StateError('invalid_download_url');
      final launched = await launchUrl(
        uri,
        webOnlyWindowName: '_blank',
        mode: LaunchMode.externalApplication,
      );
      if (!launched) throw StateError('launch_failed');
      if (dialogContext.mounted) Navigator.pop(dialogContext);
    } catch (e) {
      debugPrint('report download failed: $e');
      // The raw error never reaches the screen.
      _showMessage('เปิดไฟล์ไม่สำเร็จ ลองใหม่อีกครั้ง');
    } finally {
      if (mounted) setState(() => _busyReports.remove(report.reportId));
    }
  }

  Future<void> _askForRevision(
    BuildContext dialogContext,
    SchoolReport report,
  ) async {
    final controller = TextEditingController();
    final note = await showDialog<String>(
      context: dialogContext,
      builder: (ctx) => AlertDialog(
        title: const Text('ส่งกลับให้แก้ไข'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'ต้องแก้อะไร',
            hintText: 'ระบุให้ผู้จัดทำทราบว่าต้องแก้ส่วนไหน',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('ส่งกลับ'),
          ),
        ],
      ),
    );
    if (note == null) return;
    if (note.isEmpty) {
      // The backend refuses this too; saying so here saves a round trip.
      _showMessage('ต้องระบุเหตุผลก่อนส่งกลับให้แก้ไข');
      return;
    }
    if (!dialogContext.mounted) return;
    await _review(dialogContext, report, 'needs_revision', note);
  }

  /// Writes, then re-reads the register and confirms the row really changed
  /// before saying anything succeeded.
  Future<void> _review(
    BuildContext dialogContext,
    SchoolReport report,
    String status,
    String? note,
  ) async {
    setState(() => _busyReports.add(report.reportId));
    try {
      await (widget.reviewReport?.call(report.reportId, status, note) ??
          SchoolReportService.reviewReport(
            reportId: report.reportId,
            status: status,
            note: note,
          ));

      final fresh =
          await (widget.loadReports?.call() ??
              SchoolReportService.listReports());
      final updated = fresh
          .where((r) => r.reportId == report.reportId)
          .firstOrNull;
      if (updated == null || updated.status != status) {
        throw StateError('backend_review_not_confirmed');
      }

      if (!mounted) return;
      setState(() => _reports = fresh);
      // The summary counts by status, so it is stale the moment one changes.
      final summary =
          await (widget.loadSummary?.call() ??
              SchoolReportService.getSummary());
      if (mounted) setState(() => _summary = summary);

      if (dialogContext.mounted) Navigator.pop(dialogContext);
      _showMessage(
        status == 'approved' ? 'อนุมัติรายงานแล้ว' : 'ส่งกลับให้แก้ไขแล้ว',
      );
    } catch (e) {
      debugPrint('review failed: $e');
      _showMessage('บันทึกผลการตรวจไม่สำเร็จ สถานะยังไม่เปลี่ยน');
    } finally {
      if (mounted) setState(() => _busyReports.remove(report.reportId));
    }
  }

  // -------------------------------------------------------------------------
  // Submit
  // -------------------------------------------------------------------------

  Future<void> _pickAndSubmitReport() async {
    final form = await showDialog<_ReportDraft>(
      context: context,
      builder: (ctx) => _SubmitReportDialog(departments: _departments),
    );
    if (form == null) return;

    setState(() => _uploading = true);
    try {
      await (widget.submitReport?.call(
            title: form.title,
            reportType: form.reportType,
            fileName: form.fileName,
            bytes: form.bytes,
            departmentId: form.departmentId,
            description: form.description,
          ) ??
          SchoolReportService.submitReport(
            title: form.title,
            reportType: form.reportType,
            fileName: form.fileName,
            bytes: form.bytes,
            departmentId: form.departmentId,
            description: form.description,
          ));
      if (!mounted) return;
      _showMessage('ส่งรายงานเข้าทะเบียนแล้ว');
      await _load();
    } catch (e) {
      debugPrint('submit report failed: $e');
      _showMessage('ส่งรายงานไม่สำเร็จ ไฟล์ยังไม่ถูกบันทึกในทะเบียน');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  // -------------------------------------------------------------------------
  // Small helpers
  // -------------------------------------------------------------------------

  Widget _detailSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 9.2,
                color: AppPalette.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 9.8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  static String _two(int v) => v.toString().padLeft(2, '0');

  static String _dateLabel(DateTime d) =>
      '${_two(d.day)}/${_two(d.month)}/${d.year + 543}';

  static String _dateTimeLabel(DateTime d) =>
      '${_dateLabel(d)} • ${_two(d.hour)}:${_two(d.minute)} น.';

  /// The period the report covers, or a statement that the submitter did not
  /// give one — never a made-up range.
  static String _periodLabel(SchoolReport r) {
    if (r.periodStart == null && r.periodEnd == null) return 'ไม่ได้ระบุช่วง';
    if (r.periodEnd == null) return _dateLabel(r.periodStart!);
    if (r.periodStart == null) return _dateLabel(r.periodEnd!);
    if (r.periodStart == r.periodEnd) return _dateLabel(r.periodStart!);
    return '${_dateLabel(r.periodStart!)} - ${_dateLabel(r.periodEnd!)}';
  }

  Color _fileColor(String fileType) {
    switch (fileType) {
      case 'pdf':
        return AppPalette.danger;
      case 'excel':
        return AppPalette.success;
      case 'word':
        return AppPalette.learningBlue;
      default:
        return AppPalette.textMuted;
    }
  }

  IconData _fileIconData(String fileType) {
    switch (fileType) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'excel':
        return Icons.table_chart_rounded;
      case 'word':
        return Icons.description_rounded;
      case 'image':
        return Icons.image_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return AppPalette.success;
      case 'under_review':
        return AppPalette.warning;
      case 'needs_revision':
        return AppPalette.danger;
      default:
        return AppPalette.learningBlue;
    }
  }
}

class _ReportSummaryCard {
  const _ReportSummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
}

class _ReportDraft {
  const _ReportDraft({
    required this.title,
    required this.reportType,
    required this.fileName,
    required this.bytes,
    this.departmentId,
    this.description,
  });

  final String title;
  final String reportType;
  final String fileName;
  final Uint8List bytes;
  final String? departmentId;
  final String? description;
}

/// Collects the file and its metadata. The submit button stays disabled until
/// a file is actually attached, rather than accepting a submission that has
/// nothing to store.
class _SubmitReportDialog extends StatefulWidget {
  const _SubmitReportDialog({required this.departments});

  final List<SchoolDepartment> departments;

  @override
  State<_SubmitReportDialog> createState() => _SubmitReportDialogState();
}

class _SubmitReportDialogState extends State<_SubmitReportDialog> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _description = TextEditingController();
  String _reportType = 'monthly';
  String? _departmentId;
  String? _fileName;
  Uint8List? _bytes;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    final file = result?.files.singleOrNull;
    if (file == null || file.bytes == null) return;
    setState(() {
      _fileName = file.name;
      _bytes = file.bytes;
    });
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _bytes != null && _title.text.trim().isNotEmpty;

    return AlertDialog(
      title: const Text('ส่งรายงานเข้าทะเบียน'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _title,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(labelText: 'ชื่อรายงาน'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _reportType,
                decoration: const InputDecoration(labelText: 'ประเภทรายงาน'),
                items: SchoolReport.reportTypeLabels.entries
                    .map(
                      (e) =>
                          DropdownMenuItem(value: e.key, child: Text(e.value)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _reportType = v ?? 'monthly'),
              ),
              const SizedBox(height: 12),
              // Only ฝ่าย the school actually has. Empty when none exist yet,
              // which is a real state rather than a list of six defaults.
              DropdownButtonFormField<String?>(
                value: _departmentId,
                decoration: InputDecoration(
                  labelText: widget.departments.isEmpty
                      ? 'ยังไม่มีฝ่ายในระบบ'
                      : 'ฝ่ายผู้ส่ง',
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('ไม่ระบุฝ่าย'),
                  ),
                  ...widget.departments.map(
                    (d) => DropdownMenuItem<String?>(
                      value: d.departmentId,
                      child: Text(d.name),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _departmentId = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _description,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'รายละเอียด (ไม่บังคับ)',
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.attach_file_rounded, size: 16),
                label: Text(_fileName ?? 'เลือกไฟล์'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ยกเลิก'),
        ),
        FilledButton(
          onPressed: canSubmit
              ? () => Navigator.pop(
                  context,
                  _ReportDraft(
                    title: _title.text.trim(),
                    reportType: _reportType,
                    fileName: _fileName!,
                    bytes: _bytes!,
                    departmentId: _departmentId,
                    description: _description.text.trim().isEmpty
                        ? null
                        : _description.text.trim(),
                  ),
                )
              : null,
          child: const Text('ส่ง'),
        ),
      ],
    );
  }
}
