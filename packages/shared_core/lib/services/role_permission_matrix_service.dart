import '../models/role_permission_matrix_model.dart';
import 'auth_service.dart';
import 'supabase_config.dart';

class RolePermissionMatrixService {
  static Future<List<RolePermissionEntry>> listMatrix() async {
    final rows =
        await supabase.rpc(
              'list_role_permission_matrix',
              params: {'p_token': AuthService.sessionToken},
            )
            as List;

    return rows
        .map(
          (row) => RolePermissionEntry.fromRow(row as Map<String, dynamic>),
        )
        .toList();
  }
}
