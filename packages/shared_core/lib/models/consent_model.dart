class MyParentLink {
  final String id;
  final String studentId;
  final String studentName;
  final String relationship;
  final String status;

  const MyParentLink({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.relationship,
    required this.status,
  });

  factory MyParentLink.fromRow(Map<String, dynamic> row) => MyParentLink(
    id: row['parent_link_id'] as String,
    studentId: row['student_id'] as String,
    studentName: '${row['student_first_name']} ${row['student_last_name']}'
        .trim(),
    relationship: row['relationship'] as String,
    status: row['status'] as String,
  );

  bool get isApproved => status == 'approved';
}

class ParentConsent {
  final String? consentId;
  final String policyId;
  final String consentType;
  final String version;
  final String documentHash;
  final String contentUrl;
  final bool isRequired;
  final String? status;

  const ParentConsent({
    required this.consentId,
    required this.policyId,
    required this.consentType,
    required this.version,
    required this.documentHash,
    required this.contentUrl,
    required this.isRequired,
    required this.status,
  });

  factory ParentConsent.fromRow(Map<String, dynamic> row) => ParentConsent(
    consentId: row['consent_id'] as String?,
    policyId: row['policy_id'] as String,
    consentType: row['consent_type'] as String,
    version: row['version'] as String,
    documentHash: row['document_hash'] as String,
    contentUrl: row['content_url'] as String,
    isRequired: row['is_required'] as bool? ?? false,
    status: row['status'] as String?,
  );

  bool get isGranted => status == 'granted';
}

class AdminConsentPolicy {
  final String id;
  final String consentType;
  final String version;
  final String documentHash;
  final String contentUrl;
  final bool isRequired;
  final DateTime effectiveAt;
  final DateTime? retiredAt;

  const AdminConsentPolicy({
    required this.id,
    required this.consentType,
    required this.version,
    required this.documentHash,
    required this.contentUrl,
    required this.isRequired,
    required this.effectiveAt,
    required this.retiredAt,
  });

  factory AdminConsentPolicy.fromRow(Map<String, dynamic> row) =>
      AdminConsentPolicy(
        id: row['policy_id'] as String,
        consentType: row['consent_type'] as String,
        version: row['version'] as String,
        documentHash: row['document_hash'] as String,
        contentUrl: row['content_url'] as String,
        isRequired: row['is_required'] as bool? ?? false,
        effectiveAt: DateTime.parse(row['effective_at'] as String),
        retiredAt: row['retired_at'] == null
            ? null
            : DateTime.parse(row['retired_at'] as String),
      );

  bool get isActive =>
      retiredAt == null && !effectiveAt.isAfter(DateTime.now());
}
