import 'auth_service.dart';
import 'supabase_config.dart';

class WiringGroupMember {
  final String studentId;
  final String studentName;
  final String studentCode;

  const WiringGroupMember({
    required this.studentId,
    required this.studentName,
    required this.studentCode,
  });

  factory WiringGroupMember.fromJson(Map<String, dynamic> json) {
    return WiringGroupMember(
      studentId: json['student_id'] as String,
      studentName: (json['student_name'] as String?) ?? '',
      studentCode: (json['student_code'] as String?) ?? '',
    );
  }
}

class WiringGroupItem {
  final String groupId;
  final String courseId;
  final String kitCode;
  final String name;
  final String status;
  final String? inspectionNote;
  final String? inspectedByName;
  final DateTime? inspectedAt;
  final DateTime createdAt;
  final int memberCount;
  final List<WiringGroupMember> members;
  final int kitDeviceCount;
  final int kitOnlineCount;

  const WiringGroupItem({
    required this.groupId,
    required this.courseId,
    required this.kitCode,
    required this.name,
    required this.status,
    this.inspectionNote,
    this.inspectedByName,
    this.inspectedAt,
    required this.createdAt,
    required this.memberCount,
    required this.members,
    required this.kitDeviceCount,
    required this.kitOnlineCount,
  });

  factory WiringGroupItem.fromRow(Map<String, dynamic> row) {
    final rawMembers = row['members'] as List<dynamic>? ?? [];
    return WiringGroupItem(
      groupId: row['group_id'] as String,
      courseId: row['course_id'] as String,
      kitCode: (row['kit_code'] as String?) ?? '',
      name: (row['name'] as String?) ?? '',
      status: (row['status'] as String?) ?? 'wiring',
      inspectionNote: row['inspection_note'] as String?,
      inspectedByName: row['inspected_by_name'] as String?,
      inspectedAt: row['inspected_at'] != null
          ? DateTime.tryParse(row['inspected_at'] as String)
          : null,
      createdAt:
          DateTime.tryParse(row['created_at'] as String? ?? '') ??
          DateTime.now(),
      memberCount: (row['member_count'] as num?)?.toInt() ?? 0,
      members: rawMembers
          .map((m) => WiringGroupMember.fromJson(m as Map<String, dynamic>))
          .toList(),
      kitDeviceCount: (row['kit_device_count'] as num?)?.toInt() ?? 0,
      kitOnlineCount: (row['kit_online_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class WiringLabSummary {
  final int kitsTotal;
  final int kitsReady;
  final int devicesTotal;
  final int devicesOnline;
  final int wiringCount;
  final int passedCount;
  final int waitingToRunCount;
  final int needsReviewCount;
  final String? alertKitCode;
  final String? alertDeviceName;
  final String? alertDeviceStatus;
  final DateTime? alertLastSeenAt;

  const WiringLabSummary({
    required this.kitsTotal,
    required this.kitsReady,
    required this.devicesTotal,
    required this.devicesOnline,
    required this.wiringCount,
    required this.passedCount,
    required this.waitingToRunCount,
    required this.needsReviewCount,
    this.alertKitCode,
    this.alertDeviceName,
    this.alertDeviceStatus,
    this.alertLastSeenAt,
  });

  factory WiringLabSummary.fromRow(Map<String, dynamic> row) {
    return WiringLabSummary(
      kitsTotal: (row['kits_total'] as num?)?.toInt() ?? 0,
      kitsReady: (row['kits_ready'] as num?)?.toInt() ?? 0,
      devicesTotal: (row['devices_total'] as num?)?.toInt() ?? 0,
      devicesOnline: (row['devices_online'] as num?)?.toInt() ?? 0,
      wiringCount: (row['wiring_count'] as num?)?.toInt() ?? 0,
      passedCount: (row['passed_count'] as num?)?.toInt() ?? 0,
      waitingToRunCount: (row['waiting_to_run_count'] as num?)?.toInt() ?? 0,
      needsReviewCount: (row['needs_review_count'] as num?)?.toInt() ?? 0,
      alertKitCode: row['alert_kit_code'] as String?,
      alertDeviceName: row['alert_device_name'] as String?,
      alertDeviceStatus: row['alert_device_status'] as String?,
      alertLastSeenAt: row['alert_last_seen_at'] != null
          ? DateTime.tryParse(row['alert_last_seen_at'] as String)
          : null,
    );
  }
}

class WiringGroupService {
  static Future<List<WiringGroupItem>> listWiringGroups(
    String courseId,
  ) async {
    final rows =
        await supabase.rpc(
              'list_wiring_groups',
              params: {
                'p_token': AuthService.sessionToken,
                'p_course_id': courseId,
              },
            )
            as List;

    return rows
        .map((row) => WiringGroupItem.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  static Future<String?> createWiringGroup({
    required String courseId,
    required String kitCode,
    required String name,
  }) async {
    final res = await supabase.rpc(
      'create_wiring_group',
      params: {
        'p_token': AuthService.sessionToken,
        'p_course_id': courseId,
        'p_kit_code': kitCode,
        'p_name': name,
      },
    );
    return res as String?;
  }

  static Future<void> deleteWiringGroup(String groupId) async {
    await supabase.rpc(
      'delete_wiring_group',
      params: {'p_token': AuthService.sessionToken, 'p_group_id': groupId},
    );
  }

  static Future<void> addWiringGroupMember({
    required String groupId,
    required String studentId,
  }) async {
    await supabase.rpc(
      'add_wiring_group_member',
      params: {
        'p_token': AuthService.sessionToken,
        'p_group_id': groupId,
        'p_student_id': studentId,
      },
    );
  }

  static Future<void> removeWiringGroupMember({
    required String groupId,
    required String studentId,
  }) async {
    await supabase.rpc(
      'remove_wiring_group_member',
      params: {
        'p_token': AuthService.sessionToken,
        'p_group_id': groupId,
        'p_student_id': studentId,
      },
    );
  }

  static Future<void> setWiringGroupStatus({
    required String groupId,
    required String status,
    String? note,
  }) async {
    await supabase.rpc(
      'set_wiring_group_status',
      params: {
        'p_token': AuthService.sessionToken,
        'p_group_id': groupId,
        'p_status': status,
        'p_note': note,
      },
    );
  }

  static Future<WiringLabSummary?> getWiringLabSummary() async {
    final rows =
        await supabase.rpc(
              'get_wiring_lab_summary',
              params: {'p_token': AuthService.sessionToken},
            )
            as List;
    if (rows.isEmpty) return null;
    return WiringLabSummary.fromRow(rows.first as Map<String, dynamic>);
  }
}
