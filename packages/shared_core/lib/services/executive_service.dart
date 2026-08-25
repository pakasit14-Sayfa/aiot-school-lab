import '../models/executive_overview_model.dart';
import 'auth_service.dart';
import 'supabase_config.dart';

class ExecutiveService {
  static Future<ClassroomsOverviewItem?> getClassroomsOverview() async {
    final token = AuthService.sessionToken;
    if (token == null) return null;

    final rows =
        await supabase.rpc(
              'get_classrooms_overview',
              params: {'p_token': token},
            )
            as List;

    if (rows.isEmpty) return null;
    return ClassroomsOverviewItem.fromRow(rows.first as Map<String, dynamic>);
  }

  static Future<List<SchoolScheduleItem>> listAllSchoolSchedules() async {
    final token = AuthService.sessionToken;
    if (token == null) return const [];

    final rows =
        await supabase.rpc(
              'list_all_school_schedules',
              params: {'p_token': token},
            )
            as List;

    return rows
        .map((row) => SchoolScheduleItem.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  static Future<List<CameraAccessGrantItem>> listCameraAccessGrants() async {
    final token = AuthService.sessionToken;
    if (token == null) return const [];

    final rows =
        await supabase.rpc(
              'list_camera_access_grants',
              params: {'p_token': token},
            )
            as List;

    return rows
        .map((row) => CameraAccessGrantItem.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  static Future<String?> grantCameraAccess({
    required String userId,
    String? cameraDeviceId,
    required String reason,
    required DateTime validUntil,
  }) async {
    final token = AuthService.sessionToken;
    if (token == null) return null;

    final grantId =
        await supabase.rpc(
              'grant_camera_access',
              params: {
                'p_token': token,
                'p_user_id': userId,
                'p_camera_device_id': cameraDeviceId,
                'p_reason': reason,
                'p_valid_until': validUntil.toIso8601String(),
              },
            )
            as String?;

    return grantId;
  }

  static Future<bool> revokeCameraAccess(String grantId) async {
    final token = AuthService.sessionToken;
    if (token == null) return false;

    final result =
        await supabase.rpc(
              'revoke_camera_access',
              params: {'p_token': token, 'p_grant_id': grantId},
            )
            as bool?;

    return result ?? false;
  }
}

