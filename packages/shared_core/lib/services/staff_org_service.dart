import '../models/staff_org_model.dart';
import 'auth_service.dart';
import 'supabase_config.dart';

/// ฝ่าย / กลุ่มสาระ and the staff directory built on them.
///
/// Backed by `20260907000000_staff_org_structure.sql`. Reads are open to
/// school_admin and executive — the director's personnel page is the reason
/// the tables exist — while every write is school_admin only.
class StaffOrgService {
  /// Departments for the caller's school, optionally narrowed to one [kind]
  /// (`administrative` or `subject_group`).
  static Future<List<SchoolDepartment>> listDepartments({String? kind}) async {
    final token = AuthService.sessionToken;
    if (token == null) return const [];
    final rows =
        await supabase.rpc(
              'list_departments',
              params: {'p_token': token, 'p_kind': kind},
            )
            as List;
    return rows
        .map(
          (row) =>
              SchoolDepartment.fromRow(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }

  /// Every staff member with their groups, roles and standing. Students and
  /// parents are excluded by the RPC.
  static Future<List<StaffDirectoryEntry>> listStaffDirectory() async {
    final token = AuthService.sessionToken;
    if (token == null) return const [];
    final rows =
        await supabase.rpc('list_staff_directory', params: {'p_token': token})
            as List;
    return rows
        .map(
          (row) => StaffDirectoryEntry.fromRow(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();
  }

  /// Returns the new department's id.
  static Future<String> createDepartment({
    required String name,
    required String kind,
    int sortOrder = 0,
  }) async {
    final token = AuthService.sessionToken;
    if (token == null) throw Exception('not_signed_in');
    final res = await supabase.rpc(
      'create_department',
      params: {
        'p_token': token,
        'p_name': name.trim(),
        'p_kind': kind,
        'p_sort_order': sortOrder,
      },
    );
    final id = res?.toString() ?? '';
    if (id.isEmpty || id.toLowerCase() == 'null') {
      throw StateError('backend_department_id_missing');
    }
    return id;
  }

  static Future<void> updateDepartment({
    required String departmentId,
    required String name,
    required int sortOrder,
  }) async {
    final token = AuthService.sessionToken;
    if (token == null) throw Exception('not_signed_in');
    await supabase.rpc(
      'update_department',
      params: {
        'p_token': token,
        'p_department_id': departmentId,
        'p_name': name.trim(),
        'p_sort_order': sortOrder,
      },
    );
  }

  static Future<void> deleteDepartment(String departmentId) async {
    final token = AuthService.sessionToken;
    if (token == null) throw Exception('not_signed_in');
    await supabase.rpc(
      'delete_department',
      params: {'p_token': token, 'p_department_id': departmentId},
    );
  }

  /// Adds or updates one membership. Idempotent on (department, user), so a
  /// repeated assignment is safe.
  static Future<void> setDepartmentMember({
    required String departmentId,
    required String userId,
    bool isHead = false,
  }) async {
    final token = AuthService.sessionToken;
    if (token == null) throw Exception('not_signed_in');
    await supabase.rpc(
      'set_department_member',
      params: {
        'p_token': token,
        'p_department_id': departmentId,
        'p_user_id': userId,
        'p_is_head': isHead,
      },
    );
  }

  static Future<void> removeDepartmentMember({
    required String departmentId,
    required String userId,
  }) async {
    final token = AuthService.sessionToken;
    if (token == null) throw Exception('not_signed_in');
    await supabase.rpc(
      'remove_department_member',
      params: {
        'p_token': token,
        'p_department_id': departmentId,
        'p_user_id': userId,
      },
    );
  }

  /// Position title and phone. Separate from `update_user_profile`, which
  /// owns the name and can be called by the user themselves.
  static Future<void> setStaffProfile({
    required String userId,
    String? positionTitle,
    String? phone,
  }) async {
    final token = AuthService.sessionToken;
    if (token == null) throw Exception('not_signed_in');
    await supabase.rpc(
      'set_staff_profile',
      params: {
        'p_token': token,
        'p_user_id': userId,
        'p_position_title': positionTitle?.trim(),
        'p_phone': phone?.trim(),
      },
    );
  }
}
