class BindingCode {
  final String id;
  final String studentId;
  final String studentName;
  final String codeHint;
  final String status;
  final DateTime expiresAt;
  final DateTime issuedAt;

  const BindingCode({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.codeHint,
    required this.status,
    required this.expiresAt,
    required this.issuedAt,
  });

  factory BindingCode.fromRow(Map<String, dynamic> row) {
    return BindingCode(
      id: row['id'] as String,
      studentId: row['student_id'] as String,
      studentName:
          '${row['student_first_name']} ${row['student_last_name']}'.trim(),
      codeHint: row['code_hint'] as String? ?? '',
      status: row['status'] as String,
      expiresAt: DateTime.parse(row['expires_at'] as String),
      issuedAt: DateTime.parse(row['issued_at'] as String),
    );
  }

  bool get isIssued => status == 'issued';
}

class ParentLink {
  final String id;
  final String studentId;
  final String studentName;
  final String parentId;
  final String parentName;
  final String parentEmail;
  final String relationship;
  final String status;
  final DateTime requestedAt;

  const ParentLink({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.parentId,
    required this.parentName,
    required this.parentEmail,
    required this.relationship,
    required this.status,
    required this.requestedAt,
  });

  factory ParentLink.fromRow(Map<String, dynamic> row) {
    return ParentLink(
      id: row['id'] as String,
      studentId: row['student_id'] as String,
      studentName:
          '${row['student_first_name']} ${row['student_last_name']}'.trim(),
      parentId: row['parent_id'] as String,
      parentName:
          '${row['parent_first_name']} ${row['parent_last_name']}'.trim(),
      parentEmail: row['parent_email'] as String,
      relationship: row['relationship'] as String,
      status: row['status'] as String,
      requestedAt: DateTime.parse(row['requested_at'] as String),
    );
  }

  bool get isPending => status == 'pending';
}
