import '../models/parent_binding_model.dart';
import 'auth_service.dart';
import 'supabase_config.dart';

/// Parent binding management — โรงเรียนออกรหัสผูกบัญชี, ผู้ปกครองยืนยันตัวตน
/// ผ่านอีเมล OTP แล้วสร้างคำขอผูกบัญชีให้ School Admin อนุมัติ
///
/// การผูกบัญชีไม่ mint session ให้ผู้ปกครองทันที (ต้องรอโรงเรียนอนุมัติก่อน)
/// จึงไม่แตะ AuthService._applySession
class ParentBindingService {
  static Future<Map<String, dynamic>> createBindingCode({
    required String studentCode,
  }) async {
    final rows =
        await supabase.rpc(
              'create_parent_binding_code',
              params: {
                'p_token': AuthService.sessionToken,
                'p_student_code': studentCode.trim(),
              },
            )
            as List;

    final row = rows.first as Map<String, dynamic>;
    return {
      'code': row['binding_code'] as String,
      'expiresAt': DateTime.parse(row['expires_at'] as String),
      'studentName': '${row['student_first_name']} ${row['student_last_name']}'
          .trim(),
    };
  }

  static Future<List<BindingCode>> listBindingCodes({String? schoolId}) async {
    final rows =
        await supabase.rpc(
              'list_binding_codes',
              params: {
                'p_token': AuthService.sessionToken,
                'p_school_id': schoolId,
              },
            )
            as List;

    return rows
        .map((row) => BindingCode.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  static Future<void> revokeBindingCode(String codeId) async {
    await supabase.rpc(
      'revoke_binding_code',
      params: {'p_token': AuthService.sessionToken, 'p_code_id': codeId},
    );
  }

  static Future<String> requestParentBindingOtp({
    required String code,
    required String email,
  }) async {
    final response = await supabase.functions.invoke(
      'request-parent-binding-otp',
      body: {'code': code.trim(), 'email': email.trim().toLowerCase()},
    );

    final data = response.data as Map<String, dynamic>?;
    final verificationToken = data?['verification_token'] as String?;
    if (verificationToken == null || verificationToken.isEmpty) {
      throw Exception('binding_verification_unavailable');
    }
    return verificationToken;
  }

  static Future<void> confirmParentBinding({
    required String verificationToken,
    required String otpCode,
    required String relationship,
    required String firstName,
    required String lastName,
    required String password,
  }) async {
    final rows =
        await supabase.rpc(
              'confirm_parent_binding',
              params: {
                'p_verification_token': verificationToken,
                'p_otp_code': otpCode.trim(),
                'p_relationship': relationship.trim(),
                'p_first_name': firstName.trim(),
                'p_last_name': lastName.trim(),
                'p_password': password,
              },
            )
            as List;

    if (rows.isEmpty) {
      throw Exception('invalid_or_expired_code');
    }

    final row = rows.first as Map<String, dynamic>;
    if (row['status'] != 'pending') {
      throw Exception('invalid_parent_link_status');
    }
  }

  static Future<List<ParentLink>> listParentLinks({
    String status = 'pending',
    String? schoolId,
  }) async {
    final rows =
        await supabase.rpc(
              'list_parent_links',
              params: {
                'p_token': AuthService.sessionToken,
                'p_status': status,
                'p_school_id': schoolId,
              },
            )
            as List;

    return rows
        .map((row) => ParentLink.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  static Future<void> approveParentLink(String parentLinkId) async {
    await supabase.rpc(
      'approve_parent_link',
      params: {
        'p_token': AuthService.sessionToken,
        'p_parent_link_id': parentLinkId,
      },
    );
  }

  static Future<void> requestParentLinkSecondReview(
    String parentLinkId, {
    required String reason,
  }) async {
    await supabase.rpc(
      'request_parent_link_second_review',
      params: {
        'p_token': AuthService.sessionToken,
        'p_parent_link_id': parentLinkId,
        'p_exception_reason': reason.trim(),
      },
    );
  }

  static Future<void> secondApproveParentLink(String parentLinkId) async {
    await supabase.rpc(
      'second_approve_parent_link',
      params: {
        'p_token': AuthService.sessionToken,
        'p_parent_link_id': parentLinkId,
      },
    );
  }

  static Future<void> rejectParentLink(
    String parentLinkId, {
    String? reason,
  }) async {
    await supabase.rpc(
      'reject_parent_link',
      params: {
        'p_token': AuthService.sessionToken,
        'p_parent_link_id': parentLinkId,
        'p_reason': reason,
      },
    );
  }
}
