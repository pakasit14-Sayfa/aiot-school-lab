import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
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

    final row = rows.first as Map<String, dynamic>;
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
  // ยังไม่เชื่อม Supabase จริง — decision log ห้าม self-signup
  // (register แบบ public ขัดกับ "ทุกบัญชีเริ่มจากโรงเรียนเท่านั้น") และยังไม่มี
  // RPC สำหรับ invite flow นี้ ยังเป็น mock เดิมไปก่อน
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
    return currentUserModel != null ? [currentUserModel!] : [];
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
