import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/invitation_model.dart';
import '../models/parent_binding_model.dart';
import 'supabase_config.dart';

UserModel? currentUserModel;

class AuthService {
  static final StreamController<UserModel?> _authStateController = StreamController<UserModel?>.broadcast();
  static String? _sessionToken;

  static Stream<UserModel?> get authStateChanges => _authStateController.stream;

  static UserModel _userFromRow(Map<String, dynamic> row) {
    return UserModel(
      uid: row['user_id'] as String,
      name: '${row['first_name']} ${row['last_name']}'.trim(),
      email: row['email'] as String,
      role: UserRoleExt.fromString(row['active_role'] as String? ?? 'student'),
      schoolId: row['active_school_id'] as String? ?? '',
    );
  }

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('session_token');

    if (token == null) {
      currentUserModel = null;
      _authStateController.add(null);
      return;
    }

    try {
      final rows = await supabase.rpc('auth_validate_session', params: {'p_token': token}) as List;
      if (rows.isNotEmpty) {
        _sessionToken = token;
        currentUserModel = _userFromRow(rows.first as Map<String, dynamic>);
        _authStateController.add(currentUserModel);
      } else {
        await prefs.remove('session_token');
        currentUserModel = null;
        _authStateController.add(null);
      }
    } catch (_) {
      currentUserModel = null;
      _authStateController.add(null);
    }
  }

  static Future<UserModel?> getUserModel(String uid) async {
    return currentUserModel;
  }

  static Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    final rows = await supabase.rpc('auth_sign_in', params: {
      'p_email': email.trim().toLowerCase(),
      'p_password': password,
    }) as List;

    if (rows.isEmpty) {
      throw Exception('invalid_credentials');
    }

    return _applySession(rows.first as Map<String, dynamic>);
  }

  static Future<UserModel?> _applySession(Map<String, dynamic> row) async {
    _sessionToken = row['session_token'] as String;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('session_token', _sessionToken!);

    currentUserModel = _userFromRow(row);
    _authStateController.add(currentUserModel);
    return currentUserModel;
  }

  static Future<void> signOut() async {
    if (_sessionToken != null) {
      await supabase.rpc('auth_sign_out', params: {'p_token': _sessionToken});
    }
    _sessionToken = null;
    currentUserModel = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_token');
    _authStateController.add(null);
  }

  // ---------------------------------------------------------------------
  // Public self-signup ไม่อนุญาตตาม Decision Log ของวอลต์ — บัญชีต้องสร้างผ่าน
  // School Admin/ครูที่เชิญ (createInvitation/acceptInvitation) หรือรหัสผูก
  // บัญชีผู้ปกครองที่โรงเรียนออกให้ (createBindingCode/redeemBindingCode)
  // ---------------------------------------------------------------------

  static Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    UserRole role = UserRole.student,
  }) async {
    throw UnimplementedError(
      'Self-signup ไม่อนุญาตตาม Decision Log ของวอลต์ — บัญชีต้องสร้างผ่าน '
      'School Admin/ครู (user_invitations) หรือ parent_binding_codes เท่านั้น',
    );
  }

  static Future<String> createInvitation({
    required String email,
    required UserRole role,
    String? schoolId,
  }) async {
    final rows = await supabase.rpc('create_staff_invitation', params: {
      'p_token': _sessionToken,
      'p_email': email.trim().toLowerCase(),
      'p_role': role.value,
      'p_school_id': schoolId,
    }) as List;

    final row = rows.first as Map<String, dynamic>;
    return row['invitation_token'] as String;
  }

  static Future<List<StaffInvitation>> listInvitations({String? schoolId}) async {
    final rows = await supabase.rpc('list_school_invitations', params: {
      'p_token': _sessionToken,
      'p_school_id': schoolId,
    }) as List;

    return rows
        .map((row) => StaffInvitation.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  static Future<void> revokeInvitation(String invitationId) async {
    await supabase.rpc('revoke_staff_invitation', params: {
      'p_token': _sessionToken,
      'p_invitation_id': invitationId,
    });
  }

  static Future<UserModel?> acceptInvitation({
    required String invitationToken,
    required String firstName,
    required String lastName,
    required String password,
  }) async {
    final rows = await supabase.rpc('accept_staff_invitation', params: {
      'p_token': invitationToken.trim(),
      'p_first_name': firstName.trim(),
      'p_last_name': lastName.trim(),
      'p_password': password,
    }) as List;

    if (rows.isEmpty) {
      throw Exception('invalid_or_expired_invitation');
    }

    return _applySession(rows.first as Map<String, dynamic>);
  }

  // ---------------------------------------------------------------------
  // Parent binding — MVP scope. ไม่มี COI second-review, ไม่เก็บ PDPA
  // consent จริง (consent_policies/consents/consent_events ยังไม่ต่อ) —
  // ดู comment ใน migration 20260716030000_parent_binding_rpc.sql
  // ---------------------------------------------------------------------

  static Future<Map<String, dynamic>> createBindingCode({
    required String studentCode,
  }) async {
    final rows = await supabase.rpc('create_parent_binding_code', params: {
      'p_token': _sessionToken,
      'p_student_code': studentCode.trim(),
    }) as List;

    final row = rows.first as Map<String, dynamic>;
    return {
      'code': row['binding_code'] as String,
      'expiresAt': DateTime.parse(row['expires_at'] as String),
      'studentName':
          '${row['student_first_name']} ${row['student_last_name']}'.trim(),
    };
  }

  static Future<List<BindingCode>> listBindingCodes({String? schoolId}) async {
    final rows = await supabase.rpc('list_binding_codes', params: {
      'p_token': _sessionToken,
      'p_school_id': schoolId,
    }) as List;

    return rows
        .map((row) => BindingCode.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  static Future<void> revokeBindingCode(String codeId) async {
    await supabase.rpc('revoke_binding_code', params: {
      'p_token': _sessionToken,
      'p_code_id': codeId,
    });
  }

  static Future<UserModel?> redeemBindingCode({
    required String code,
    required String relationship,
    required String email,
    required String firstName,
    required String lastName,
    required String password,
  }) async {
    final rows = await supabase.rpc('redeem_parent_binding_code', params: {
      'p_code': code.trim(),
      'p_relationship': relationship.trim(),
      'p_email': email.trim().toLowerCase(),
      'p_first_name': firstName.trim(),
      'p_last_name': lastName.trim(),
      'p_password': password,
    }) as List;

    if (rows.isEmpty) {
      throw Exception('invalid_or_expired_code');
    }

    return _applySession(rows.first as Map<String, dynamic>);
  }

  static Future<List<ParentLink>> listParentLinks({
    String status = 'pending',
    String? schoolId,
  }) async {
    final rows = await supabase.rpc('list_parent_links', params: {
      'p_token': _sessionToken,
      'p_status': status,
      'p_school_id': schoolId,
    }) as List;

    return rows
        .map((row) => ParentLink.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  static Future<void> approveParentLink(String parentLinkId) async {
    await supabase.rpc('approve_parent_link', params: {
      'p_token': _sessionToken,
      'p_parent_link_id': parentLinkId,
    });
  }

  static Future<void> rejectParentLink(String parentLinkId, {String? reason}) async {
    await supabase.rpc('reject_parent_link', params: {
      'p_token': _sessionToken,
      'p_parent_link_id': parentLinkId,
      'p_reason': reason,
    });
  }

  static Future<void> resetPassword(String email) async {
    await supabase.functions.invoke('request-password-reset', body: {
      'email': email.trim().toLowerCase(),
    });
  }

  static Future<void> confirmPasswordReset({
    required String email,
    required String otpCode,
    required String newPassword,
  }) async {
    await supabase.rpc('confirm_password_reset', params: {
      'p_email': email.trim().toLowerCase(),
      'p_otp_code': otpCode.trim(),
      'p_new_password': newPassword,
    });
  }

  static Future<List<UserModel>> getAllUsers() async {
    final rows = await supabase.rpc('list_school_users', params: {
      'p_token': _sessionToken,
    }) as List;

    return rows
        .map((row) => _userFromRow(row as Map<String, dynamic>))
        .toList();
  }

  static Future<void> updateProfile({
    required String uid,
    required String name,
  }) async {
    final trimmed = name.trim();
    final parts = trimmed.split(RegExp(r'\s+'));
    final firstName = parts.first;
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    await supabase.rpc('update_user_profile', params: {
      'p_token': _sessionToken,
      'p_target_user_id': uid,
      'p_first_name': firstName,
      'p_last_name': lastName,
    });

    if (currentUserModel?.uid == uid) {
      currentUserModel = currentUserModel!.copyWith(name: trimmed);
      _authStateController.add(currentUserModel);
    }
  }

  static Future<void> updateRole({
    required String uid,
    required UserRole role,
  }) async {
    await supabase.rpc('update_user_role', params: {
      'p_token': _sessionToken,
      'p_target_user_id': uid,
      'p_new_role': role.value,
    });
  }

  static Future<void> deleteUser(String uid) async {
    await supabase.rpc('suspend_user', params: {
      'p_token': _sessionToken,
      'p_target_user_id': uid,
    });
  }
}
