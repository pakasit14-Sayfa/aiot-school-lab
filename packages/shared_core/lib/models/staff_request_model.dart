class StaffRequest {
  StaffRequest.fromRow(Map<String, dynamic> r)
    : id = r['request_id'] as String,
      requesterId = r['requester_id'] as String,
      requester = r['requester_name'] as String,
      type = r['request_type'] as String,
      subject = r['subject'] as String,
      detail = r['detail'] as String?,
      date = DateTime.parse(r['start_date'] as String),
      status = r['status'] as String,
      department = r['department_name'] as String?,
      location = r['location'] as String?,
      headDecision = r['head_decision'] as String?,
      headName = r['head_by_name'] as String?,
      headNote = r['head_note'] as String?,
      execDecision = r['exec_decision'] as String?,
      execName = r['exec_by_name'] as String?,
      execNote = r['exec_note'] as String?;
  final String id, requesterId, requester, type, subject, status;
  final DateTime date;
  final String? detail,
      department,
      location,
      headDecision,
      headName,
      headNote,
      execDecision,
      execName,
      execNote;
  bool get isMeeting => type == 'meet_request' || type == 'meeting_request';
}

class StaffRequestUnconfirmed implements Exception {
  const StaffRequestUnconfirmed();
}
