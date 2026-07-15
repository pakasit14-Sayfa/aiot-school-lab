enum UserRole {
  student,
  teacher,
  buildingAdmin,
  schoolAdmin,
  executive,
  developer,
  parent,
}

extension UserRoleExt on UserRole {
  String get value {
    switch (this) {
      case UserRole.student: return 'student';
      case UserRole.teacher: return 'teacher';
      case UserRole.buildingAdmin: return 'buildingAdmin';
      case UserRole.schoolAdmin: return 'schoolAdmin';
      case UserRole.executive: return 'executive';
      case UserRole.developer: return 'developer';
      case UserRole.parent: return 'parent';
    }
  }

  String get label {
    switch (this) {
      case UserRole.student: return 'นักเรียน';
      case UserRole.teacher: return 'ครูประจำห้อง';
      case UserRole.buildingAdmin: return 'ผู้ดูแลอาคาร';
      case UserRole.schoolAdmin: return 'แอดมินโรงเรียน';
      case UserRole.executive: return 'ผู้บริหาร';
      case UserRole.developer: return 'ผู้พัฒนาระบบ';
      case UserRole.parent: return 'ผู้ปกครอง';
    }
  }

  static UserRole fromString(String v) {
    switch (v) {
      case 'teacher': return UserRole.teacher;
      case 'buildingAdmin': return UserRole.buildingAdmin;
      case 'schoolAdmin': return UserRole.schoolAdmin;
      case 'executive': return UserRole.executive;
      case 'developer': return UserRole.developer;
      case 'parent': return UserRole.parent;
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
      role == UserRole.buildingAdmin ||
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
