import 'user_model.dart';

class AvailableRoleOption {
  const AvailableRoleOption({
    required this.role,
    this.schoolId,
    this.schoolName,
  });

  final UserRole role;
  final String? schoolId;
  final String? schoolName;

  factory AvailableRoleOption.fromJson(Map<String, dynamic> json) {
    final roleStr = json['role'] as String? ?? '';
    final role = UserRoleExt.fromString(roleStr);
    return AvailableRoleOption(
      role: role,
      schoolId: json['school_id'] as String?,
      schoolName: json['school_name'] as String?,
    );
  }

  String get displayName {
    switch (role) {
      case UserRole.superAdmin:
        return 'ผู้ดูแลระบบสูงสุด (Super Admin)';
      case UserRole.schoolAdmin:
        return 'ผู้ดูแลโรงเรียน (School Admin)';
      case UserRole.teacher:
        return 'คุณครู (Teacher)';
      case UserRole.executive:
        return 'ผู้บริหาร (Executive)';
      case UserRole.student:
        return 'นักเรียน (Student)';
      case UserRole.parent:
        return 'ผู้ปกครอง (Parent)';
    }
  }

  String get subtitle {
    if (schoolName != null && schoolName!.isNotEmpty) {
      return schoolName!;
    }
    return role == UserRole.superAdmin ? 'ดูแลทุกโรงเรียนในระบบ' : 'โรงเรียน';
  }
}

class RoleSelectionChallenge {
  const RoleSelectionChallenge({
    required this.roleSelectionToken,
    required this.availableRoles,
  });

  final String roleSelectionToken;
  final List<AvailableRoleOption> availableRoles;

  factory RoleSelectionChallenge.fromResponse(Map<String, dynamic> response) {
    final token = response['role_selection_token'];
    if (token is! String || !token.startsWith('rs_')) {
      throw const FormatException('invalid_role_selection_token');
    }

    final rawRoles = response['available_roles'];
    final roles = <AvailableRoleOption>[];
    if (rawRoles is List) {
      for (final item in rawRoles) {
        if (item is Map<String, dynamic>) {
          roles.add(AvailableRoleOption.fromJson(item));
        } else if (item is Map) {
          roles.add(
            AvailableRoleOption.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    return RoleSelectionChallenge(
      roleSelectionToken: token,
      availableRoles: roles,
    );
  }
}
