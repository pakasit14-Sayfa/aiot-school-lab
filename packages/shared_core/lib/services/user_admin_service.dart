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

  static Future<void> deleteUser(String uid) async {
    await supabase.rpc(
      'suspend_user',
      params: {'p_token': AuthService.sessionToken, 'p_target_user_id': uid},
    );
  }
}
