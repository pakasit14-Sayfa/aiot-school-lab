/// One RPC's real role gate, as read live from its own function body via
/// `list_role_permission_matrix` — never hand-typed. [allowedRoles] is null
/// when the function's access check doesn't match the project's standard
/// `v_actor.role not in (...)` pattern (a helper function, a NOT EXISTS
/// subquery, etc.) — an honest gap, not a guess.
class RolePermissionEntry {
  const RolePermissionEntry({
    required this.functionName,
    required this.allowedRoles,
  });

  final String functionName;
  final List<String>? allowedRoles;

  factory RolePermissionEntry.fromRow(Map<String, dynamic> row) {
    final roles = row['allowed_roles'] as List<dynamic>?;
    return RolePermissionEntry(
      functionName: row['function_name'] as String,
      allowedRoles: roles?.map((r) => r as String).toList(),
    );
  }
}
