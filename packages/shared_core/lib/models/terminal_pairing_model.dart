class TerminalPairingResult {
  final String status;
  final String? sessionToken;
  final String studentName;

  const TerminalPairingResult({
    required this.status,
    this.sessionToken,
    required this.studentName,
  });

  factory TerminalPairingResult.fromRow(Map<String, dynamic> row) =>
      TerminalPairingResult(
        status: (row['status'] as String?) ?? 'unknown',
        sessionToken: row['session_token'] as String?,
        studentName: (row['student_name'] as String?) ?? '',
      );

  bool get isClaimed => status == 'claimed' && sessionToken != null;
  bool get isExpired => status == 'expired';
}
