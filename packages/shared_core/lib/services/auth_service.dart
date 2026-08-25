import 'dart:async';
import 'dart:convert';
import '../models/user_model.dart';
import '../models/login_otp_challenge.dart';
import '../models/role_selection_challenge.dart';
import 'supabase_config.dart';
import 'session_token_storage.dart';

UserModel? currentUserModel;

/// Owns the signed-in session: establishing it (signIn/selectRole/verifyLoginOtp/
/// acceptInvitation), tearing it down (signOut/signOutAllDevices), and the
/// currentUserModel/authStateChanges state everything else reads.
///
/// Everything that only needs the session token as an input (invitations,
/// parent binding, consent, password reset, user admin, notifications) lives
/// in its own service in this directory and reads AuthService.sessionToken.
class AuthService {
  static final StreamController<UserModel?> _authStateController =
      StreamController<UserModel?>.broadcast();
  static String? _sessionToken;
  static final _tokenStorage = SessionTokenStorage();

  static Stream<UserModel?> get authStateChanges => _authStateController.stream;

  /// Current session token, for services that call token-authenticated RPCs
  /// (e.g. RealtimeService → sensor_latest). Null when signed out.
  static String? get sessionToken => _sessionToken;

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
        currentUserModel = UserModel.fromAuthRow(
          rows.first as Map<String, dynamic>,
        );
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
    Map<String, dynamic>? data;
    try {
      final response = await supabase.functions.invoke(
        'auth-sign-in',
        body: {'email': email.trim().toLowerCase(), 'password': password},
      );
      data = response.data as Map<String, dynamic>?;
    } catch (_) {}

    if (data == null ||
        (data['session'] == null &&
            data['mfa_required'] != true &&
            data['role_selection_required'] != true)) {
      // Direct RPC fallback if edge function is unreachable
      final rows =
          await supabase.rpc(
                'auth_sign_in',
                params: {
                  'p_email': email.trim().toLowerCase(),
                  'p_password': password,
                },
              )
              as List;
      if (rows.isNotEmpty) {
        final row = Map<String, dynamic>.from(rows.first as Map);
        if (row['auth_state'] == 'role_selection_required') {
          List<dynamic> roles = [];
          if (row['building'] != null) {
            try {
              roles = (row['building'] is List)
                  ? row['building'] as List
                  : (row['building'] is String)
                      ? List<dynamic>.from(
                          jsonDecode(row['building'] as String) as List,
                        )
                      : [];
            } catch (_) {}
          }
          data = {
            'role_selection_required': true,
            'role_selection_token': row['otp_token'],
            'available_roles': roles,
          };
        } else if (row['auth_state'] == 'mfa_required') {
          data = {
            'mfa_required': true,
            'otp_token': row['otp_token'],
            'otp_expires_at': row['otp_expires_at']?.toString(),
            'dev_otp_code': row['otp_code'],
          };
        } else if (row['auth_state'] == 'authenticated') {
          data = {'session': row};
        }
      }
    }

    if (data?['role_selection_required'] == true) {
      return AuthSignInResult.roleSelectionRequired(
        RoleSelectionChallenge.fromResponse(data!),
      );
    }
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

  static Future<AuthSignInResult> selectRole({
    required String roleSelectionToken,
    required UserRole role,
    String? schoolId,
  }) async {
    Map<String, dynamic>? data;
    try {
      final response = await supabase.functions.invoke(
        'auth-select-role',
        body: {
          'role_selection_token': roleSelectionToken.trim(),
          'role': role.value,
          if (schoolId != null) 'school_id': schoolId,
        },
      );
      data = response.data as Map<String, dynamic>?;
    } catch (_) {}

    if (data == null ||
        (data['session'] == null && data['mfa_required'] != true)) {
      // Direct RPC fallback
      final rows =
          await supabase.rpc(
                'auth_select_role',
                params: {
                  'p_role_selection_token': roleSelectionToken.trim(),
                  'p_role': role.value,
                  if (schoolId != null) 'p_school_id': schoolId,
                },
              )
              as List;

      if (rows.isEmpty) {
        throw Exception('invalid_or_expired_role_selection');
      }

      final row = Map<String, dynamic>.from(rows.first as Map);
      if (row['auth_state'] == 'mfa_required') {
        data = {
          'mfa_required': true,
          'otp_token': row['otp_token'],
          'otp_expires_at': row['otp_expires_at']?.toString(),
          'dev_otp_code': row['otp_code'],
        };
      } else if (row['auth_state'] == 'authenticated' &&
          row['session_token'] != null) {
        data = {'session': row};
      } else {
        throw Exception('role_selection_failed');
      }
    }

    if (data['mfa_required'] == true) {
      return AuthSignInResult.otpRequired(
        LoginOtpChallenge.fromResponse(data),
      );
    }

    final session = data['session'];
    if (session is! Map) {
      throw Exception('role_selection_failed');
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

    final user = UserModel.fromAuthRow(row);
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
  // School Admin/ครูที่เชิญ (InvitationService.createInvitation +
  // AuthService.acceptInvitation) หรือรหัสผูกบัญชีผู้ปกครองที่โรงเรียนออกให้
  // (ParentBindingService.createBindingCode/confirmParentBinding)
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

  static Future<AuthSignInResult> acceptInvitation({
    required String invitationToken,
    required String firstName,
    required String lastName,
    required String password,
  }) async {
    final response = await supabase.functions.invoke(
      'accept-staff-invitation',
      body: {
        'token': invitationToken.trim(),
        'first_name': firstName.trim(),
        'last_name': lastName.trim(),
        'password': password,
      },
    );
    final data = response.data as Map<String, dynamic>?;
    if (data?['mfa_required'] == true) {
      return AuthSignInResult.otpRequired(
        LoginOtpChallenge.fromResponse(data!),
      );
    }
    final session = data?['session'];
    if (session is! Map) {
      throw Exception('invalid_or_expired_invitation');
    }

    final user = await _applySession(Map<String, dynamic>.from(session));
    return AuthSignInResult.authenticated(user);
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
}
