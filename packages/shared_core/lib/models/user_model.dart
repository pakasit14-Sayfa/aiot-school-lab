enum UserRole {
  superAdmin,
  schoolAdmin,
  teacher,
  executive,
  student,
  parent,
  facilityManager,
  technician,
}

extension UserRoleExt on UserRole {
  String get value {
    switch (this) {
      case UserRole.superAdmin: return 'super_admin';
      case UserRole.schoolAdmin: return 'school_admin';
      case UserRole.teacher: return 'teacher';
      case UserRole.executive: return 'executive';
      case UserRole.student: return 'student';
      case UserRole.parent: return 'parent';
      case UserRole.facilityManager: return 'facility_manager';
      case UserRole.technician: return 'technician';
    }
  }

  String get label {
    switch (this) {
      case UserRole.superAdmin: return 'ผู้ดูแลระบบสูงสุด';
      case UserRole.schoolAdmin: return 'แอดมินโรงเรียน';
      case UserRole.teacher: return 'ครูประจำห้อง';
      case UserRole.executive: return 'ผู้บริหาร';
      case UserRole.student: return 'นักเรียน';
      case UserRole.parent: return 'ผู้ปกครอง';
      case UserRole.facilityManager: return 'ผู้ดูแลอาคาร';
      case UserRole.technician: return 'ช่างเทคนิค';
    }
  }

  static UserRole fromString(String v) {
    switch (v) {
      case 'super_admin': return UserRole.superAdmin;
      case 'school_admin': return UserRole.schoolAdmin;
      case 'teacher': return UserRole.teacher;
      case 'executive': return UserRole.executive;
      case 'parent': return UserRole.parent;
      case 'facility_manager': return UserRole.facilityManager;
      case 'technician': return UserRole.technician;
      default: return UserRole.student;
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

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.schoolId = '',
    this.building = '',
    this.room = '',
  });

  /// Parses the row shape returned by auth/session/user-list RPCs
  /// (user_id, first_name, last_name, active_role, active_school_id).
  factory UserModel.fromAuthRow(Map<String, dynamic> row) {
    return UserModel(
      uid: row['user_id'] as String,
      name: '${row['first_name']} ${row['last_name']}'.trim(),
      email: row['email'] as String,
      role: UserRoleExt.fromString(row['active_role'] as String? ?? 'student'),
      schoolId: row['active_school_id'] as String? ?? '',
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
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'email': email,
    'role': role.value,
    'schoolId': schoolId,
    'building': building,
    'room': room,
  };

  bool get isSchoolAdmin => role == UserRole.schoolAdmin;

  bool get canControlDevices =>
      role == UserRole.teacher ||
      role == UserRole.facilityManager ||
      role == UserRole.schoolAdmin;

  UserModel copyWith({String? name, UserRole? role}) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email,
      role: role ?? this.role,
      schoolId: schoolId,
      building: building,
      room: room,
    );
  }
}
