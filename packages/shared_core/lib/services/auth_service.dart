import 'dart:async';
import '../models/user_model.dart';
import '../models/invitation_model.dart';
import '../models/parent_binding_model.dart';
import '../models/consent_model.dart';
import '../models/notification_model.dart';
import '../models/login_otp_challenge.dart';
import 'supabase_config.dart';
import 'session_token_storage.dart';

UserModel? currentUserModel;

class AuthService {
  static final StreamController<UserModel?> _authStateController =
      StreamController<UserModel?>.broadcast();
  static String? _sessionToken;
  static final _tokenStorage = SessionTokenStorage();

  static Stream<UserModel?> get authStateChanges => _authStateController.stream;

  /// Current session token, for services that call token-authenticated RPCs
  /// (e.g. RealtimeService → sensor_latest). Null when signed out.
  static String? get sessionToken => _sessionToken;

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
    final token = await _tokenStorage.readAndMigrate();

    if (token == null) {
      currentUserModel = null;
      _authStateController.add(null);
      return;
    }

    try {
      final rows =
          await supabase.rpc(
                'auth_validate_session',
                params: {'p_token': token},
              )
              as List;
      if (rows.isNotEmpty) {
        _sessionToken = token;
        currentUserModel = _userFromRow(rows.first as Map<String, dynamic>);
        _authStateController.add(currentUserModel);
      } else {
        await _tokenStorage.delete();
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

  static Future<AuthSignInResult> signIn({
    required String email,
    required String password,
  }) async {
    final response = await supabase.functions.invoke(
      'auth-sign-in',
      body: {'email': email.trim().toLowerCase(), 'password': password},
    );
    final data = response.data as Map<String, dynamic>?;
    if (data?['mfa_required'] == true) {
      return AuthSignInResult.otpRequired(
        LoginOtpChallenge.fromResponse(data!),
      );
    }
    final session = data?['session'];
    if (session is! Map) {
      throw Exception('invalid_credentials');
    }

    final user = await _applySession(Map<String, dynamic>.from(session));
    return AuthSignInResult.authenticated(user);
  }

  static Future<UserModel> verifyLoginOtp({
    required String otpToken,
    required String otpCode,
  }) async {
    final response = await supabase.functions.invoke(
      'auth-verify-otp',
      body: {'otp_token': otpToken.trim(), 'otp_code': otpCode.trim()},
    );
    final data = response.data as Map<String, dynamic>?;
    final session = data?['session'];
    if (session is! Map) {
      throw Exception('invalid_or_expired_otp');
    }
    return _applySession(Map<String, dynamic>.from(session));
  }

  static Future<UserModel> _applySession(Map<String, dynamic> row) async {
    _sessionToken = row['session_token'] as String;

    await _tokenStorage.write(_sessionToken!);

    final user = _userFromRow(row);
    currentUserModel = user;
    _authStateController.add(user);
    return user;
  }

  static Future<void> signOut() async {
    try {
      if (_sessionToken != null) {
        await supabase.rpc('auth_sign_out', params: {'p_token': _sessionToken});
      }
    } finally {
      _sessionToken = null;
      currentUserModel = null;
      await _tokenStorage.delete();
      _authStateController.add(null);
    }
  }

  static Future<void> signOutAllDevices() async {
    try {
      if (_sessionToken != null) {
        await supabase.rpc(
          'auth_sign_out_all',
          params: {'p_token': _sessionToken},
        );
      }
    } finally {
      _sessionToken = null;
      currentUserModel = null;
      await _tokenStorage.delete();
      _authStateController.add(null);
    }
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
    final rows =
        await supabase.rpc(
              'create_staff_invitation',
              params: {
                'p_token': _sessionToken,
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
              params: {'p_token': _sessionToken, 'p_school_id': schoolId},
            )
            as List;

    return rows
        .map((row) => StaffInvitation.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  static Future<void> revokeInvitation(String invitationId) async {
    await supabase.rpc(
      'revoke_staff_invitation',
      params: {'p_token': _sessionToken, 'p_invitation_id': invitationId},
    );
  }

  static Future<UserModel?> acceptInvitation({
    required String invitationToken,
    required String firstName,
    required String lastName,
    required String password,
  }) async {
    final rows =
        await supabase.rpc(
              'accept_staff_invitation',
              params: {
                'p_token': invitationToken.trim(),
                'p_first_name': firstName.trim(),
                'p_last_name': lastName.trim(),
                'p_password': password,
              },
            )
            as List;

    if (rows.isEmpty) {
      throw Exception('invalid_or_expired_invitation');
    }

    return _applySession(rows.first as Map<String, dynamic>);
  }

  // ---------------------------------------------------------------------
  // Parent binding. The public app first requests an email OTP and receives
  // only an opaque verification token. Account/link creation happens only
  // after the OTP is confirmed.
  // ---------------------------------------------------------------------

  static Future<Map<String, dynamic>> createBindingCode({
    required String studentCode,
  }) async {
    final rows =
        await supabase.rpc(
              'create_parent_binding_code',
              params: {
                'p_token': _sessionToken,
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
              params: {'p_token': _sessionToken, 'p_school_id': schoolId},
            )
            as List;

    return rows
        .map((row) => BindingCode.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  static Future<void> revokeBindingCode(String codeId) async {
    await supabase.rpc(
      'revoke_binding_code',
      params: {'p_token': _sessionToken, 'p_code_id': codeId},
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
                'p_token': _sessionToken,
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
      params: {'p_token': _sessionToken, 'p_parent_link_id': parentLinkId},
    );
  }

  static Future<void> requestParentLinkSecondReview(
    String parentLinkId, {
    required String reason,
  }) async {
    await supabase.rpc(
      'request_parent_link_second_review',
      params: {
        'p_token': _sessionToken,
        'p_parent_link_id': parentLinkId,
        'p_exception_reason': reason.trim(),
      },
    );
  }

  static Future<void> secondApproveParentLink(String parentLinkId) async {
    await supabase.rpc(
      'second_approve_parent_link',
      params: {'p_token': _sessionToken, 'p_parent_link_id': parentLinkId},
    );
  }

  static Future<void> rejectParentLink(
    String parentLinkId, {
    String? reason,
  }) async {
    await supabase.rpc(
      'reject_parent_link',
      params: {
        'p_token': _sessionToken,
        'p_parent_link_id': parentLinkId,
        'p_reason': reason,
      },
    );
  }

  static Future<List<MyParentLink>> listMyParentLinks() async {
    final rows =
        await supabase.rpc(
              'list_my_parent_links',
              params: {'p_token': _sessionToken},
            )
            as List;
    return rows
        .map((row) => MyParentLink.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  static Future<List<ParentConsent>> listMyConsents(String parentLinkId) async {
    final rows =
        await supabase.rpc(
              'list_my_consents',
              params: {
                'p_token': _sessionToken,
                'p_parent_link_id': parentLinkId,
              },
            )
            as List;
    return rows
        .map((row) => ParentConsent.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  static Future<void> grantParentConsent({
    required String parentLinkId,
    required String policyId,
  }) async {
    await supabase.rpc(
      'grant_parent_consent',
      params: {
        'p_token': _sessionToken,
        'p_parent_link_id': parentLinkId,
        'p_policy_id': policyId,
        'p_evidence': {'confirmed_read': true, 'channel': 'flutter_parent_app'},
      },
    );
  }

  static Future<void> withdrawParentConsent(String consentId) async {
    await supabase.rpc(
      'withdraw_parent_consent',
      params: {
        'p_token': _sessionToken,
        'p_consent_id': consentId,
        'p_reason': 'withdrawn_by_parent_in_app',
      },
    );
  }

  static Future<List<AdminConsentPolicy>> listAdminConsentPolicies() async {
    final rows =
        await supabase.rpc(
              'list_consent_policies_admin',
              params: {'p_token': _sessionToken},
            )
            as List;
    return rows
        .map((row) => AdminConsentPolicy.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  static Future<void> publishConsentPolicy({
    required String consentType,
    required String version,
    required String documentHash,
    required String contentUrl,
    required bool isRequired,
  }) async {
    await supabase.rpc(
      'publish_consent_policy',
      params: {
        'p_token': _sessionToken,
        'p_consent_type': consentType.trim(),
        'p_version': version.trim(),
        'p_document_hash': documentHash.trim().toLowerCase(),
        'p_content_url': contentUrl.trim(),
        'p_is_required': isRequired,
      },
    );
  }

  static Future<void> retireConsentPolicy(String policyId) async {
    await supabase.rpc(
      'retire_consent_policy',
      params: {'p_token': _sessionToken, 'p_policy_id': policyId},
    );
  }

  static Future<void> resetPassword(String email) async {
    await supabase.functions.invoke(
      'request-password-reset',
      body: {'email': email.trim().toLowerCase()},
    );
  }

  static Future<void> confirmPasswordReset({
    required String email,
    required String otpCode,
    required String newPassword,
  }) async {
    await supabase.rpc(
      'confirm_password_reset',
      params: {
        'p_email': email.trim().toLowerCase(),
        'p_otp_code': otpCode.trim(),
        'p_new_password': newPassword,
      },
    );
  }

  static Future<List<UserModel>> getAllUsers() async {
    final rows =
        await supabase.rpc(
              'list_school_users',
              params: {'p_token': _sessionToken},
            )
            as List;

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

    await supabase.rpc(
      'update_user_profile',
      params: {
        'p_token': _sessionToken,
        'p_target_user_id': uid,
        'p_first_name': firstName,
        'p_last_name': lastName,
      },
    );

    if (currentUserModel?.uid == uid) {
      currentUserModel = currentUserModel!.copyWith(name: trimmed);
      _authStateController.add(currentUserModel);
    }
  }

  static Future<void> updateRole({
    required String uid,
    required UserRole role,
  }) async {
    await supabase.rpc(
      'update_user_role',
      params: {
        'p_token': _sessionToken,
        'p_target_user_id': uid,
        'p_new_role': role.value,
      },
    );
  }

  static Future<void> deleteUser(String uid) async {
    await supabase.rpc(
      'suspend_user',
      params: {'p_token': _sessionToken, 'p_target_user_id': uid},
    );
  }

  static Future<List<AppNotification>> listMyNotifications() async {
    final rows =
        await supabase.rpc(
              'list_my_notifications',
              params: {'p_token': _sessionToken},
            )
            as List;

    return rows
        .map((row) => AppNotification.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  static Future<void> markNotificationRead(String notificationId) async {
    await supabase.rpc(
      'mark_notification_read',
      params: {'p_token': _sessionToken, 'p_notification_id': notificationId},
    );
  }
}
