import '../models/terminal_pairing_model.dart';
import 'auth_service.dart';
import 'supabase_config.dart';

class TerminalPairingService {
  static Future<({String pairingCode, DateTime expiresAt})> createPairingSession({
    String? terminalName,
  }) async {
    final rows = await supabase.rpc(
      'create_terminal_pairing_session',
      params: {'p_terminal_name': terminalName},
    ) as List;

    final row = rows.first as Map<String, dynamic>;
    return (
      pairingCode: row['pairing_code'] as String,
      expiresAt: DateTime.parse(row['expires_at'] as String).toLocal(),
    );
  }

  static Future<TerminalPairingPeek> peekPairingSession(String pairingCode) async {
    final rows = await supabase.rpc(
      'peek_terminal_pairing_session',
      params: {'p_pairing_code': pairingCode.trim()},
    ) as List;

    if (rows.isEmpty) {
      return const TerminalPairingPeek(isValid: false, terminalName: '');
    }
    return TerminalPairingPeek.fromRow(rows.first as Map<String, dynamic>);
  }

  static Future<({bool success, String studentName, String message})> claimPairingSession(
    String pairingCode,
  ) async {
    final rows = await supabase.rpc(
      'claim_terminal_pairing_session',
      params: {
        'p_token': AuthService.sessionToken,
        'p_pairing_code': pairingCode.trim(),
      },
    ) as List;

    final row = rows.first as Map<String, dynamic>;
    return (
      success: (row['success'] as bool?) ?? false,
      studentName: (row['student_name'] as String?) ?? '',
      message: (row['message'] as String?) ?? '',
    );
  }

  static Future<TerminalPairingResult> checkPairingStatus(String pairingCode) async {
    final rows = await supabase.rpc(
      'check_terminal_pairing_status',
      params: {'p_pairing_code': pairingCode.trim()},
    ) as List;

    if (rows.isEmpty) {
      return const TerminalPairingResult(status: 'not_found', studentName: '');
    }
    return TerminalPairingResult.fromRow(rows.first as Map<String, dynamic>);
  }
}
