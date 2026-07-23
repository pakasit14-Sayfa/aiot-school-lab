import '../models/invitation_model.dart';
import '../models/user_model.dart';
import 'auth_service.dart';
import 'supabase_config.dart';

/// Staff invitation management — School Admin/ครูเชิญบุคลากรเข้าระบบแทน
/// self-signup (ดู Decision Log ที่ AuthService.register) การรับคำเชิญจริง
/// (ซึ่ง mint session ใหม่) อยู่ที่ AuthService.acceptInvitation
class InvitationService {
  static Future<String> createInvitation({
    required String email,
    required UserRole role,
    String? schoolId,
  }) async {
    final rows =
        await supabase.rpc(
              'create_staff_invitation',
              params: {
                'p_token': AuthService.sessionToken,
                'p_email': email.trim().toLowerCase(),
                'p_role': role.value,
                'p_school_id': schoolId,
              },
            )
            as List;

    final row = rows.first as Map<String, dynamic>;
    return row['invitation_token'] as String;
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
