class LeaveRequestForReview {
  final String leaveId;
  final String studentId;
  final String studentName;
  final String leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final String? reason;
  final String? attachmentPath;
  final String status;
  final String? reviewNote;
  final DateTime createdAt;

  LeaveRequestForReview({
    required this.leaveId,
    required this.studentId,
    required this.studentName,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    this.reason,
    this.attachmentPath,
    required this.status,
    this.reviewNote,
    required this.createdAt,
  });

  factory LeaveRequestForReview.fromRow(Map<String, dynamic> row) {
    return LeaveRequestForReview(
      leaveId: row['leave_id'] as String,
      studentId: row['student_id'] as String,
      studentName: row['student_name'] as String? ?? 'ไม่ทราบชื่อ',
      leaveType: row['leave_type'] as String,
      startDate: DateTime.parse(row['start_date'] as String),
      endDate: DateTime.parse(row['end_date'] as String),
      reason: row['reason'] as String?,
      attachmentPath: row['attachment_path'] as String?,
      status: row['status'] as String,
      reviewNote: row['review_note'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}

class MyLeaveRequestItem {
  final String leaveId;
  final String leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final String? reason;
  final String status;
  final String? reviewNote;
  final DateTime createdAt;

  MyLeaveRequestItem({
    required this.leaveId,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    this.reason,
    required this.status,
    this.reviewNote,
    required this.createdAt,
  });

  factory MyLeaveRequestItem.fromRow(Map<String, dynamic> row) {
    return MyLeaveRequestItem(
      leaveId: row['leave_id'] as String,
      leaveType: row['leave_type'] as String,
      startDate: DateTime.parse(row['start_date'] as String),
      endDate: DateTime.parse(row['end_date'] as String),
      reason: row['reason'] as String?,
      status: row['status'] as String,
      reviewNote: row['review_note'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}
