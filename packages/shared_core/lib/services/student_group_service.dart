import '../models/course_model.dart';
import 'auth_service.dart';
import 'supabase_config.dart';

class StudentGroupItem {
  final String id;
  final String courseId;
  final String name;
  final DateTime createdAt;
  final List<CourseStudent> members;

  const StudentGroupItem({
    required this.id,
    required this.courseId,
    required this.name,
    required this.createdAt,
    required this.members,
  });

  factory StudentGroupItem.fromJson(Map<String, dynamic> json) {
    final rawMembers = json['members'] as List<dynamic>? ?? [];
    final membersList = rawMembers.map((m) {
      final map = m as Map<String, dynamic>;
      return CourseStudent(
        studentId: map['student_id'] as String? ?? '',
        firstName: map['first_name'] as String? ?? '',
        lastName: map['last_name'] as String? ?? '',
        email: map['email'] as String? ?? '',
        enrolledAt: DateTime.now(),
      );
    }).toList();

    return StudentGroupItem(
      id: json['id'] as String,
      courseId: json['course_id'] as String,
      name: json['name'] as String,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      members: membersList,
    );
  }
}

class StudentGroupService {
  static Future<List<StudentGroupItem>> listStudentGroups(
    String courseId,
  ) async {
    final rows =
        await supabase.rpc(
              'list_student_groups',
              params: {
                'p_token': AuthService.sessionToken,
                'p_course_id': courseId,
              },
            )
            as List;

    return rows
        .map((row) => StudentGroupItem.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  static Future<String?> createStudentGroup({
    required String courseId,
    required String name,
  }) async {
    final res = await supabase.rpc(
      'create_student_group',
      params: {
        'p_token': AuthService.sessionToken,
        'p_course_id': courseId,
        'p_name': name,
      },
    );
    return res as String?;
  }

  static Future<void> renameStudentGroup({
    required String groupId,
    required String name,
  }) async {
    await supabase.rpc(
      'rename_student_group',
      params: {
        'p_token': AuthService.sessionToken,
        'p_group_id': groupId,
        'p_name': name,
      },
    );
  }

  static Future<void> deleteStudentGroup(String groupId) async {
    await supabase.rpc(
      'delete_student_group',
      params: {'p_token': AuthService.sessionToken, 'p_group_id': groupId},
    );
  }

  static Future<void> addGroupMember({
    required String groupId,
    required String studentId,
  }) async {
    await supabase.rpc(
      'add_group_member',
      params: {
        'p_token': AuthService.sessionToken,
        'p_group_id': groupId,
        'p_student_id': studentId,
      },
    );
  }

  static Future<void> removeGroupMember({
    required String groupId,
    required String studentId,
  }) async {
    await supabase.rpc(
      'remove_group_member',
      params: {
        'p_token': AuthService.sessionToken,
        'p_group_id': groupId,
        'p_student_id': studentId,
      },
    );
  }
}
