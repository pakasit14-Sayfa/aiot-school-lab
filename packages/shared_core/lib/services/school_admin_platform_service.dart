import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/super_admin_model.dart';
import '../models/school_building_model.dart';
import 'auth_service.dart';

class SchoolAdminPlatformService {
  SchoolAdminPlatformService({
    SupabaseClient? client,
  })  : _client = client;

  final SupabaseClient? _client;

  SupabaseClient get _resolvedClient => _client ?? Supabase.instance.client;

  Future<String> _requireToken() async {
    final token = AuthService.sessionToken;
    if (token == null || token.isEmpty) {
      throw const AuthException('กรุณาเข้าสู่ระบบก่อนทำรายการ');
    }
    return token;
  }

  /// List all schools with aggregated real-time metrics for Super Admin
  Future<List<SchoolPlatformRecord>> fetchSchools() async {
    final token = await _requireToken();
    final res = await _resolvedClient.rpc('list_schools_for_super_admin', params: {
      'p_token': token,
    });

    if (res is! List) return [];
    return res
        .map((e) => SchoolPlatformRecord.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Create a new school
  Future<Map<String, dynamic>> createSchool({
    required String name,
    String? province,
    String? adminEmail,
    String packageName = 'Standard',
    int maxUsers = 100,
    int maxDevices = 100,
    DateTime? licenseExpiresAt,
  }) async {
    final token = await _requireToken();
    final res = await _resolvedClient.rpc('create_school_for_super_admin', params: {
      'p_token': token,
      'p_name': name,
      if (province != null) 'p_province': province,
      if (adminEmail != null) 'p_admin_email': adminEmail,
      'p_package_name': packageName,
      'p_max_users': maxUsers,
      'p_max_devices': maxDevices,
      if (licenseExpiresAt != null)
        'p_license_expires_at': licenseExpiresAt.toUtc().toIso8601String(),
    });

    return Map<String, dynamic>.from(res as Map);
  }

  /// Update existing school
  Future<bool> updateSchool({
    required String schoolId,
    required String name,
    String? province,
    String? adminEmail,
    String? packageName,
    int? maxUsers,
    int? maxDevices,
    DateTime? licenseExpiresAt,
  }) async {
    final token = await _requireToken();
    final res = await _resolvedClient.rpc('update_school_for_super_admin', params: {
      'p_token': token,
      'p_school_id': schoolId,
      'p_name': name,
      if (province != null) 'p_province': province,
      if (adminEmail != null) 'p_admin_email': adminEmail,
      if (packageName != null) 'p_package_name': packageName,
      if (maxUsers != null) 'p_max_users': maxUsers,
      if (maxDevices != null) 'p_max_devices': maxDevices,
      if (licenseExpiresAt != null)
        'p_license_expires_at': licenseExpiresAt.toUtc().toIso8601String(),
    });

    return res == true;
  }

  /// Update school status (active / suspended)
  Future<bool> setSchoolStatus({
    required String schoolId,
    required String status,
  }) async {
    final token = await _requireToken();
    final res = await _resolvedClient.rpc('set_school_status_for_super_admin', params: {
      'p_token': token,
      'p_school_id': schoolId,
      'p_status': status,
    });

    return res == true;
  }

  /// Fetch all device control data (schools, devices, approvals, permissions, logs)
  Future<DeviceControlDataModel> fetchDeviceControlData() async {
    final token = await _requireToken();
    final res = await _resolvedClient.rpc('list_device_control_data_for_super_admin', params: {
      'p_token': token,
    });

    return DeviceControlDataModel.fromJson(Map<String, dynamic>.from(res as Map));
  }

  /// Send device command via existing rate-limited queue_device_command RPC
  Future<String> queueDeviceCommand({
    required String deviceId,
    required Map<String, dynamic> command,
  }) async {
    final token = await _requireToken();
    final res = await _resolvedClient.rpc('queue_device_command', params: {
      'p_token': token,
      'p_device_id': deviceId,
      'p_command': command,
    });

    return res.toString();
  }

  /// Create control approval request
  Future<Map<String, dynamic>> createControlApprovalRequest({
    required String deviceId,
    required String command,
    String? reason,
  }) async {
    final token = await _requireToken();
    final res = await _resolvedClient.rpc('create_control_approval_request', params: {
      'p_token': token,
      'p_device_id': deviceId,
      'p_command': command,
      if (reason != null) 'p_reason': reason,
    });

    return Map<String, dynamic>.from(res as Map);
  }

  /// Decide control approval request (Approve or Reject)
  Future<Map<String, dynamic>> decideControlApprovalRequest({
    required String requestId,
    required bool approved,
    String? reason,
  }) async {
    final token = await _requireToken();
    final res = await _resolvedClient.rpc('decide_control_approval_request', params: {
      'p_token': token,
      'p_request_id': requestId,
      'p_approved': approved,
      if (reason != null) 'p_reason': reason,
    });

    return Map<String, dynamic>.from(res as Map);
  }

  /// Fetch school buildings list
  Future<List<SchoolBuildingRecord>> fetchBuildings() async {
    final token = await _requireToken();
    final res = await _resolvedClient.rpc('list_school_buildings', params: {
      'p_token': token,
    });

    if (res is! List) return [];
    return res
        .map((e) => SchoolBuildingRecord.fromRow(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Fetch school rooms list
  Future<List<SchoolRoomRecord>> fetchRooms({String? buildingId}) async {
    final token = await _requireToken();
    final res = await _resolvedClient.rpc('list_school_rooms', params: {
      'p_token': token,
      if (buildingId != null) 'p_building_id': buildingId,
    });

    if (res is! List) return [];
    return res
        .map((e) => SchoolRoomRecord.fromRow(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Fetch school admin dashboard aggregate summary
  Future<SchoolAdminDashboardSummary> fetchDashboardSummary() async {
    final token = await _requireToken();
    final res = await _resolvedClient.rpc('get_school_admin_dashboard_summary', params: {
      'p_token': token,
    });

    return SchoolAdminDashboardSummary.fromJson(Map<String, dynamic>.from(res as Map));
  }

  /// Fetch school admin audit logs
  Future<List<SchoolAdminAuditLog>> fetchAuditLogs({int limit = 20}) async {
    final token = await _requireToken();
    final res = await _resolvedClient.rpc('list_school_admin_audit_logs', params: {
      'p_token': token,
      'p_limit': limit,
    });

    if (res is! List) return [];
    return res
        .map((e) => SchoolAdminAuditLog.fromRow(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}

