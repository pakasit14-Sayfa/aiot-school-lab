enum UserRole {
  superAdmin,
  schoolAdmin,
  teacher,
  executive,
  student,
  parent,
}

extension UserRoleExt on UserRole {
  String get value {
    switch (this) {
      case UserRole.superAdmin:
        return 'super_admin';
      case UserRole.schoolAdmin:
        return 'school_admin';
      case UserRole.teacher:
        return 'teacher';
      case UserRole.executive:
        return 'executive';
      case UserRole.student:
        return 'student';
      case UserRole.parent:
        return 'parent';
    }
  }

  String get label {
    switch (this) {
      case UserRole.superAdmin:
        return 'ผู้ดูแลระบบสูงสุด';
      case UserRole.schoolAdmin:
        return 'แอดมินโรงเรียน';
      case UserRole.teacher:
        return 'ครูประจำห้อง';
      case UserRole.executive:
        return 'ผู้บริหาร';
      case UserRole.student:
        return 'นักเรียน';
      case UserRole.parent:
        return 'ผู้ปกครอง';
    }
  }

  static UserRole fromString(String v) {
    switch (v) {
      case 'super_admin':
        return UserRole.superAdmin;
      case 'school_admin':
        return UserRole.schoolAdmin;
      case 'teacher':
        return UserRole.teacher;
      case 'executive':
        return UserRole.executive;
      case 'parent':
        return UserRole.parent;
      default:
        return UserRole.student;
    }
  }
}

class UserModel {
  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final List<UserRole> allRoles;
  final String schoolId;
  final String building;
  final String room;
  final String status;

  /// บัญชีที่ถูกนำเข้าด้วยรหัสชั่วคราว ต้องเปลี่ยนรหัสก่อนใช้งาน —
  /// RoleRouter เปิดหน้าเปลี่ยนรหัสแทนหน้าแรกจนกว่าจะเป็น false
  final bool mustChangePassword;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.allRoles = const [],
    this.schoolId = '',
    this.building = '',
    this.room = '',
    this.status = 'active',
    this.mustChangePassword = false,
  });

  /// True if this user holds [target] as any of their roles, not just
  /// their single collapsed "active_role" — needed because a
  /// multi-role account's active_role only reflects whichever role was
  /// granted most recently (see list_school_users), which would
  /// otherwise silently exclude e.g. a teacher who was later also
  /// granted school_admin from role == teacher filters.
  bool hasRole(UserRole target) =>
      role == target || allRoles.contains(target);

  /// Parses the row shape returned by auth/session/user-list RPCs
  /// (user_id, first_name, last_name, active_role, active_school_id,
  /// building — building is only ever set for facility_manager accounts,
  /// see 20260814000000_facility_manager_building_scope.sql). `all_roles`
  /// is only present on `list_school_users` rows (see
  /// 20260826130000_list_school_users_all_roles.sql) — absent elsewhere,
  /// in which case it falls back to just [role].
  factory UserModel.fromAuthRow(Map<String, dynamic> row) {
    final role = UserRoleExt.fromString(row['active_role'] as String? ?? 'student');
    final rawAllRoles = row['all_roles'] as List?;
    return UserModel(
      uid: row['user_id'] as String,
      name: '${row['first_name']} ${row['last_name']}'.trim(),
      email: row['email'] as String,
      role: role,
      allRoles: rawAllRoles == null
          ? [role]
          : rawAllRoles.map((r) => UserRoleExt.fromString(r as String)).toList(),
      schoolId: row['active_school_id'] as String? ?? '',
      building: row['building'] as String? ?? '',
      status: row['status'] as String? ?? 'active',
      mustChangePassword: row['must_change_password'] == true,
    );
  }

  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    return UserModel(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: UserRoleExt.fromString(map['role'] ?? 'student'),
      schoolId: map['schoolId'] ?? '',
      building: map['building'] ?? '',
      room: map['room'] ?? '',
      status: map['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'email': email,
    'role': role.value,
    'schoolId': schoolId,
    'building': building,
    'room': room,
    'status': status,
  };

  bool get isSchoolAdmin => role == UserRole.schoolAdmin;
  bool get isSuspended => status == 'suspended';

  bool get canControlDevices =>
      role == UserRole.teacher ||
      role == UserRole.schoolAdmin ||
      role == UserRole.superAdmin;

  UserModel copyWith({String? name, UserRole? role, String? status}) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email,
      role: role ?? this.role,
      schoolId: schoolId,
      building: building,
      room: room,
      status: status ?? this.status,
    );
  }
}

/// เซสชัน (เครื่อง) ที่ล็อกอินอยู่ของผู้ใช้ปัจจุบัน — list_my_sessions
class MySessionRecord {
  const MySessionRecord({
    required this.id,
    required this.deviceInfo,
    required this.ipAddress,
    required this.createdAt,
    required this.expiresAt,
    required this.isCurrent,
  });

  final String id;
  final String? deviceInfo;
  final String? ipAddress;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isCurrent;

  factory MySessionRecord.fromRow(Map<String, dynamic> row) => MySessionRecord(
    id: row['id'] as String,
    deviceInfo: row['device_info'] as String?,
    ipAddress: row['ip_address'] as String?,
    createdAt: DateTime.parse(row['created_at'] as String),
    expiresAt: DateTime.parse(row['expires_at'] as String),
    isCurrent: row['is_current'] == true,
  );
}
