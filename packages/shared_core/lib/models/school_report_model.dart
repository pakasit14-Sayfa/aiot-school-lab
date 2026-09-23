/// One report filed with the director.
///
/// The old page carried a page count for every file. Nothing on the server can
/// count the pages of an uploaded PDF, so there is no field for it here.
class SchoolReport {
  const SchoolReport({
    required this.reportId,
    required this.title,
    required this.reportType,
    required this.fileName,
    required this.fileType,
    required this.sizeBytes,
    required this.status,
    required this.submittedBy,
    required this.submitterName,
    required this.submittedAt,
    this.description,
    this.departmentId,
    this.departmentName,
    this.submitterPosition,
    this.periodStart,
    this.periodEnd,
    this.reviewerName,
    this.reviewedAt,
    this.reviewNote,
    this.requirementId,
    this.requirementTitle,
  });

  final String reportId;
  final String title;
  final String? description;

  /// `daily` · `weekly` · `monthly` · `term` · `incident` · `ad_hoc`.
  final String reportType;
  final String fileName;

  /// `pdf` · `excel` · `word` · `image` · `other`, derived from the extension
  /// by the backend so a client cannot label a file as something it is not.
  final String fileType;
  final int sizeBytes;

  /// ฝ่ายผู้ส่ง. Null when the submitter belongs to no ฝ่าย — shown as such
  /// rather than filed under a borrowed one.
  final String? departmentId;
  final String? departmentName;
  final DateTime? periodStart;
  final DateTime? periodEnd;

  /// `submitted` · `under_review` · `approved` · `needs_revision`.
  ///
  /// There is deliberately no `overdue`: lateness belongs to a
  /// [ReportRequirement]'s due date, not to a file that exists.
  final String status;
  final String submittedBy;
  final String submitterName;

  /// ตำแหน่ง from `staff_profiles`, null when the school has not recorded one.
  final String? submitterPosition;
  final DateTime submittedAt;
  final String? reviewerName;
  final DateTime? reviewedAt;
  final String? reviewNote;
  final String? requirementId;
  final String? requirementTitle;

  bool get isAwaitingReview =>
      status == 'submitted' || status == 'under_review';
  bool get isApproved => status == 'approved';

  static const Map<String, String> statusLabels = {
    'submitted': 'ส่งแล้ว',
    'under_review': 'กำลังตรวจ',
    'approved': 'อนุมัติแล้ว',
    'needs_revision': 'ต้องแก้ไข',
  };

  static const Map<String, String> reportTypeLabels = {
    'daily': 'รายวัน',
    'weekly': 'รายสัปดาห์',
    'monthly': 'รายเดือน',
    'term': 'ภาคเรียน',
    'incident': 'เหตุการณ์',
    'ad_hoc': 'เฉพาะกิจ',
  };

  static const Map<String, String> fileTypeLabels = {
    'pdf': 'PDF',
    'excel': 'Excel',
    'word': 'Word',
    'image': 'รูปภาพ',
    'other': 'อื่น ๆ',
  };

  String get statusLabel => statusLabels[status] ?? status;
  String get reportTypeLabel => reportTypeLabels[reportType] ?? reportType;
  String get fileTypeLabel => fileTypeLabels[fileType] ?? fileType;

  /// Formatted from the real byte count. The old page printed "2.4 MB" beside
  /// files that did not exist.
  String get sizeLabel {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static String? _text(dynamic v) =>
      (v?.toString().trim().isEmpty ?? true) ? null : v.toString();

  static DateTime? _date(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString());

  factory SchoolReport.fromRow(Map<String, dynamic> row) => SchoolReport(
    reportId: row['report_id'].toString(),
    title: row['title']?.toString() ?? '',
    description: _text(row['description']),
    reportType: row['report_type']?.toString() ?? 'ad_hoc',
    fileName: row['file_name']?.toString() ?? '',
    fileType: row['file_type']?.toString() ?? 'other',
    sizeBytes: (row['size_bytes'] as num?)?.toInt() ?? 0,
    departmentId: _text(row['department_id']),
    departmentName: _text(row['department_name']),
    periodStart: _date(row['period_start']),
    periodEnd: _date(row['period_end']),
    status: row['status']?.toString() ?? 'submitted',
    submittedBy: row['submitted_by'].toString(),
    submitterName: row['submitter_name']?.toString().trim() ?? '',
    submitterPosition: _text(row['submitter_position']),
    submittedAt: _date(row['submitted_at'])?.toLocal() ?? DateTime.now(),
    reviewerName: _text(row['reviewer_name']),
    reviewedAt: _date(row['reviewed_at'])?.toLocal(),
    reviewNote: _text(row['review_note']),
    requirementId: _text(row['requirement_id']),
    requirementTitle: _text(row['requirement_title']),
  );
}

/// A report the school expects — the thing that has a deadline.
///
/// The old page showed "ส่งแล้ว 3/6" next to a hand-written 6. Here the
/// denominator is how many ฝ่าย the requirement actually asks, and
/// [missingDepartments] names the ones that have not filed.
class ReportRequirement {
  const ReportRequirement({
    required this.requirementId,
    required this.title,
    required this.reportType,
    required this.expectedCount,
    required this.filedCount,
    required this.isOverdue,
    required this.missingDepartments,
    this.description,
    this.periodStart,
    this.periodEnd,
    this.dueDate,
  });

  final String requirementId;
  final String title;
  final String? description;
  final String reportType;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final DateTime? dueDate;

  /// How many ฝ่าย are asked, and how many have filed.
  final int expectedCount;
  final int filedCount;

  /// Past its due date with at least one ฝ่าย still missing. Computed by the
  /// backend so two pages cannot disagree about what "เกินกำหนด" means.
  final bool isOverdue;
  final List<String> missingDepartments;

  bool get isComplete => expectedCount > 0 && filedCount >= expectedCount;

  String get reportTypeLabel =>
      SchoolReport.reportTypeLabels[reportType] ?? reportType;

  factory ReportRequirement.fromRow(Map<String, dynamic> row) =>
      ReportRequirement(
        requirementId: row['requirement_id'].toString(),
        title: row['title']?.toString() ?? '',
        description: SchoolReport._text(row['description']),
        reportType: row['report_type']?.toString() ?? 'ad_hoc',
        periodStart: SchoolReport._date(row['period_start']),
        periodEnd: SchoolReport._date(row['period_end']),
        dueDate: SchoolReport._date(row['due_date']),
        expectedCount: (row['expected_count'] as num?)?.toInt() ?? 0,
        filedCount: (row['filed_count'] as num?)?.toInt() ?? 0,
        isOverdue: row['is_overdue'] == true,
        missingDepartments: row['missing_departments'] is List
            ? (row['missing_departments'] as List)
                  .map((e) => e.toString())
                  .where((e) => e.isNotEmpty)
                  .toList()
            : const <String>[],
      );
}

/// The figures behind the register's summary cards.
class SchoolReportSummary {
  const SchoolReportSummary({
    required this.totalReports,
    required this.awaitingReview,
    required this.approved,
    required this.needsRevision,
    required this.submittedThisMonth,
    required this.openRequirements,
    required this.overdueRequirements,
  });

  final int totalReports;
  final int awaitingReview;
  final int approved;
  final int needsRevision;
  final int submittedThisMonth;

  /// Requirements not yet filed by every ฝ่าย asked.
  final int openRequirements;

  /// A subset of [openRequirements]: those past their due date.
  final int overdueRequirements;

  static int _int(dynamic v) => (v as num?)?.toInt() ?? 0;

  factory SchoolReportSummary.fromRow(Map<String, dynamic> row) =>
      SchoolReportSummary(
        totalReports: _int(row['total_reports']),
        awaitingReview: _int(row['awaiting_review']),
        approved: _int(row['approved']),
        needsRevision: _int(row['needs_revision']),
        submittedThisMonth: _int(row['submitted_this_month']),
        openRequirements: _int(row['open_requirements']),
        overdueRequirements: _int(row['overdue_requirements']),
      );
}
