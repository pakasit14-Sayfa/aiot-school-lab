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
  final String schoolId;
  final String building;
  final String room;
  final String status;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.schoolId = '',
    this.building = '',
    this.room = '',
    this.status = 'active',
  });

  /// Parses the row shape returned by auth/session/user-list RPCs
  /// (user_id, first_name, last_name, active_role, active_school_id,
  /// building — building is only ever set for facility_manager accounts,
  /// see 20260814000000_facility_manager_building_scope.sql).
  factory UserModel.fromAuthRow(Map<String, dynamic> row) {
    return UserModel(
      uid: row['user_id'] as String,
      name: '${row['first_name']} ${row['last_name']}'.trim(),
      email: row['email'] as String,
      role: UserRoleExt.fromString(row['active_role'] as String? ?? 'student'),
      schoolId: row['active_school_id'] as String? ?? '',
      building: row['building'] as String? ?? '',
      status: row['status'] as String? ?? 'active',
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
