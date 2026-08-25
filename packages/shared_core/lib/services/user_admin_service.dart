import '../models/user_model.dart';
import 'auth_service.dart';
import 'supabase_config.dart';

/// School Admin / super_admin actions on other users' accounts.
/// Editing the signed-in user's own profile stays in AuthService because it
/// mutates the shared currentUserModel/authStateChanges state.
class UserAdminService {
  static Future<List<UserModel>> getAllUsers() async {
    final rows =
        await supabase.rpc(
              'list_school_users',
              params: {'p_token': AuthService.sessionToken},
            )
            as List;

    return rows
        .map((row) => UserModel.fromAuthRow(row as Map<String, dynamic>))
        .toList();
  }

  static Future<void> updateRole({
    required String uid,
    required UserRole role,
  }) async {
    await supabase.rpc(
      'update_user_role',
      params: {
        'p_token': AuthService.sessionToken,
        'p_target_user_id': uid,
        'p_new_role': role.value,
      },
    );
  }

  static Future<void> addSecondaryRole({
    required String uid,
    required UserRole role,
    String? schoolId,
  }) async {
    final params = <String, dynamic>{
      'p_token': AuthService.sessionToken,
      'p_target_user_id': uid,
      'p_role': role.value,
    };
    if (schoolId != null) params['p_school_id'] = schoolId;
    await supabase.rpc('add_secondary_role', params: params);
  }

  static Future<void> deleteUser(String uid) async {
    await supabase.rpc(
      'suspend_user',
      params: {'p_token': AuthService.sessionToken, 'p_target_user_id': uid},
    );
  }

  static Future<void> reactivateUser(String uid) async {
    await supabase.rpc(
      'reactivate_user',
      params: {'p_token': AuthService.sessionToken, 'p_target_user_id': uid},
    );
  }

  // LA-9 BR1: ผู้บริหารเห็นภาพรวมระดับโรงเรียนเท่านั้น ไม่ใช่รายชื่อ/อีเมล
  // รายคน — RPC นี้คืนแค่ {role, count} ต่างจาก list_school_users ที่คืน
  // ข้อมูลรายคนทั้งหมด (getAllUsers ด้านบน ยังจำกัดสิทธิ์ school_admin/
  // super_admin เหมือนเดิม ไม่เปิดให้ executive)
  static Future<Map<String, int>> countUsersByRole() async {
    final rows =
        await supabase.rpc(
              'count_school_users_by_role',
              params: {'p_token': AuthService.sessionToken},
            )
            as List;

    return {
      for (final row in rows.cast<Map<String, dynamic>>())
        row['active_role'] as String: (row['user_count'] as num).toInt(),
    };
  }

  /// Batch import users for school_admin / super_admin
  static Future<int> importSchoolUsersBatch({
    required UserRole role,
    required List<Map<String, dynamic>> users,
  }) async {
    final token = AuthService.sessionToken;
    if (token == null) throw Exception('not_signed_in');
    final res = await supabase.rpc(
      'import_school_users_batch_for_school_admin',
      params: {
        'p_token': token,
        'p_role': role.value,
        'p_users': users,
      },
    );

    if (res is Map && res['inserted_count'] != null) {
      return (res['inserted_count'] as num).toInt();
    }
    return 0;
  }
}

