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

class TerminalPairingPeek {
  final bool isValid;
  final String terminalName;
  final DateTime? createdAt;
  final DateTime? expiresAt;

  const TerminalPairingPeek({
    required this.isValid,
    required this.terminalName,
    this.createdAt,
    this.expiresAt,
  });

  factory TerminalPairingPeek.fromRow(Map<String, dynamic> row) =>
      TerminalPairingPeek(
        isValid: (row['is_valid'] as bool?) ?? false,
        terminalName: (row['terminal_name'] as String?) ?? 'เครื่องแล็บ',
        createdAt: row['created_at'] != null
            ? DateTime.parse(row['created_at'] as String).toLocal()
            : null,
        expiresAt: row['expires_at'] != null
            ? DateTime.parse(row['expires_at'] as String).toLocal()
            : null,
      );
}
