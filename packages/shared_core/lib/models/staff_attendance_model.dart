/// เวลาปฏิบัติงานของโรงเรียน — the basis lateness is judged against.
///
/// Absent entirely when the school has not configured one, which is why this
/// is nullable everywhere it is used: "nobody is late" and "lateness is
/// unknowable" are different states and the UI must be able to tell them
/// apart.
class StaffWorkHours {
  const StaffWorkHours({
    required this.workStartTime,
    required this.workEndTime,
    required this.lateGraceMinutes,
  });

  /// `HH:mm:ss` as Postgres `time` renders it.
  final String workStartTime;
  final String workEndTime;
  final int lateGraceMinutes;

  /// `08:00:00` → `08:00`. Returns the raw value if it is not in that shape
  /// rather than guessing at a format.
  static String _hm(String raw) {
    final parts = raw.split(':');
    if (parts.length < 2) return raw;
    return '${parts[0]}:${parts[1]}';
  }

  String get startLabel => _hm(workStartTime);
  String get endLabel => _hm(workEndTime);

  factory StaffWorkHours.fromRow(Map<String, dynamic> row) => StaffWorkHours(
    workStartTime: row['work_start_time']?.toString() ?? '',
    workEndTime: row['work_end_time']?.toString() ?? '',
    lateGraceMinutes: (row['late_grace_minutes'] as num?)?.toInt() ?? 0,
  );
}

/// One staff member's standing on one day.
class StaffAttendanceDay {
  const StaffAttendanceDay({
    required this.userId,
    required this.fullName,
    required this.status,
    this.leaveType,
    this.checkInAt,
    this.checkOutAt,
    this.source,
    this.note,
  });

  final String userId;
  final String fullName;

  /// `present` · `late` · `leave` · `official_duty` · `absent` · `no_record`.
  ///
  /// `no_record` means nobody has said anything about this person today. It is
  /// deliberately not `absent`: absence is an assertion a school_admin makes,
  /// and silence is not evidence of it.
  final String status;

  /// `sick` · `personal` · `vacation` · `maternity`, only when [status] is
  /// `leave`.
  final String? leaveType;
  final DateTime? checkInAt;
  final DateTime? checkOutAt;

  /// `self` when the person checked in, `admin` when it was entered for them.
  final String? source;
  final String? note;

  bool get isRecorded => status != 'no_record';

  static DateTime? _time(dynamic value) =>
      value == null ? null : DateTime.tryParse(value.toString())?.toLocal();

  factory StaffAttendanceDay.fromRow(Map<String, dynamic> row) =>
      StaffAttendanceDay(
        userId: row['user_id'].toString(),
        fullName: row['full_name']?.toString().trim() ?? '',
        status: row['status']?.toString() ?? 'no_record',
        leaveType: row['leave_type']?.toString(),
        checkInAt: _time(row['check_in_at']),
        checkOutAt: _time(row['check_out_at']),
        source: row['source']?.toString(),
        note: (row['note']?.toString().trim().isEmpty ?? true)
            ? null
            : row['note'].toString(),
      );
}

/// The counts behind the "มาปฏิบัติงานวันนี้" cards, counted by the backend so
/// two pages cannot disagree about them.
class StaffAttendanceSummary {
  const StaffAttendanceSummary({
    required this.workDate,
    required this.totalStaff,
    required this.presentCount,
    required this.lateCount,
    required this.leaveCount,
    required this.officialDutyCount,
    required this.absentCount,
    required this.noRecordCount,
    required this.workHoursConfigured,
  });

  final DateTime workDate;
  final int totalStaff;
  final int presentCount;
  final int lateCount;
  final int leaveCount;
  final int officialDutyCount;
  final int absentCount;

  /// Staff nobody has recorded. Shown as its own figure rather than folded
  /// into absent.
  final int noRecordCount;

  /// False when the school has no `staff_work_hours` row — in which case
  /// [lateCount] is zero because nobody *could* be marked late, not because
  /// everyone was on time. The UI must say so.
  final bool workHoursConfigured;

  static int _int(dynamic v) => (v as num?)?.toInt() ?? 0;

  factory StaffAttendanceSummary.fromRow(Map<String, dynamic> row) =>
      StaffAttendanceSummary(
        workDate:
            DateTime.tryParse(row['work_date']?.toString() ?? '') ??
            DateTime.now(),
        totalStaff: _int(row['total_staff']),
        presentCount: _int(row['present_count']),
        lateCount: _int(row['late_count']),
        leaveCount: _int(row['leave_count']),
        officialDutyCount: _int(row['official_duty_count']),
        absentCount: _int(row['absent_count']),
        noRecordCount: _int(row['no_record_count']),
        workHoursConfigured: row['work_hours_configured'] == true,
      );
}

/// การลาของบุคลากร. Distinct from `leave_requests`, which is student leave.
class StaffLeaveRequest {
  const StaffLeaveRequest({
    required this.requestId,
    required this.userId,
    required this.fullName,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.createdAt,
    this.reason,
    this.reviewerName,
    this.reviewedAt,
    this.reviewNote,
  });

  final String requestId;
  final String userId;
  final String fullName;

  /// `sick` · `personal` · `vacation` · `maternity`.
  final String leaveType;
  final DateTime startDate;
  final DateTime endDate;

  /// `pending` · `approved` · `rejected` · `cancelled`.
  final String status;
  final DateTime createdAt;
  final String? reason;
  final String? reviewerName;
  final DateTime? reviewedAt;
  final String? reviewNote;

  bool get isPending => status == 'pending';

  /// Inclusive, the way a school counts leave days.
  int get dayCount => endDate.difference(startDate).inDays + 1;

  static const Map<String, String> leaveTypeLabels = {
    'sick': 'ลาป่วย',
    'personal': 'ลากิจ',
    'vacation': 'ลาพักผ่อน',
    'maternity': 'ลาคลอด',
  };

  String get leaveTypeLabel => leaveTypeLabels[leaveType] ?? leaveType;

  static String? _text(dynamic v) =>
      (v?.toString().trim().isEmpty ?? true) ? null : v.toString();

  factory StaffLeaveRequest.fromRow(Map<String, dynamic> row) =>
      StaffLeaveRequest(
        requestId: row['request_id'].toString(),
        userId: row['user_id'].toString(),
        fullName: row['full_name']?.toString().trim() ?? '',
        leaveType: row['leave_type']?.toString() ?? '',
        startDate:
            DateTime.tryParse(row['start_date']?.toString() ?? '') ??
            DateTime.now(),
        endDate:
            DateTime.tryParse(row['end_date']?.toString() ?? '') ??
            DateTime.now(),
        status: row['status']?.toString() ?? 'pending',
        createdAt:
            DateTime.tryParse(row['created_at']?.toString() ?? '')?.toLocal() ??
            DateTime.now(),
        reason: _text(row['reason']),
        reviewerName: _text(row['reviewer_name']),
        reviewedAt: row['reviewed_at'] == null
            ? null
            : DateTime.tryParse(row['reviewed_at'].toString())?.toLocal(),
        reviewNote: _text(row['review_note']),
      );
}
