import '../models/invitation_model.dart';
import '../models/user_model.dart';
import 'auth_service.dart';
import 'supabase_config.dart';

/// Staff invitation management — School Admin/ครูเชิญบุคลากรเข้าระบบแทน
/// self-signup (ดู Decision Log ที่ AuthService.register) การรับคำเชิญจริง
/// (ซึ่ง mint session ใหม่) อยู่ที่ AuthService.acceptInvitation
class InvitationService {
  /// Issue a staff invitation. Returns the one-time token the admin must
  /// relay to the invitee manually, together with its expiry so the UI can
  /// state how long it stays valid instead of guessing.
  static Future<StaffInvitationTicket> createInvitation({
    required String email,
    required UserRole role,
    String? schoolId,
  }) async {
    final res = await supabase.rpc(
      'create_staff_invitation',
      params: {
        'p_token': AuthService.sessionToken,
        'p_email': email.trim().toLowerCase(),
        'p_role': role.value,
        'p_school_id': schoolId,
      },
    );

    final row = res is List
        ? (res.isEmpty ? null : Map<String, dynamic>.from(res.first as Map))
        : (res is Map ? Map<String, dynamic>.from(res) : null);
    if (row == null) throw StateError('invitation_not_created');

    final token = row['invitation_token']?.toString() ?? '';
    if (token.isEmpty) throw StateError('invitation_token_missing');

    return StaffInvitationTicket(
      token: token,
      expiresAt: DateTime.tryParse(row['expires_at']?.toString() ?? ''),
    );
  }

  static Future<List<StaffInvitation>> listInvitations({
    String? schoolId,
  }) async {
    final rows =
        await supabase.rpc(
              'list_school_invitations',
              params: {
                'p_token': AuthService.sessionToken,
                'p_school_id': schoolId,
              },
            )
            as List;

    return rows
        .map((row) => StaffInvitation.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  static Future<void> revokeInvitation(String invitationId) async {
    await supabase.rpc(
      'revoke_staff_invitation',
      params: {
        'p_token': AuthService.sessionToken,
        'p_invitation_id': invitationId,
      },
    );
  }
}
