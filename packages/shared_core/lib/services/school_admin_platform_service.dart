import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/super_admin_model.dart';
import '../models/school_building_model.dart';
import '../models/executive_overview_model.dart'
    show PlatformSettings, CourseOverviewRecord;
import 'auth_service.dart';
import 'school_import_service.dart' show BulkImportResult;

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

  /// Register a new device to a school (Super Admin). Returns
  /// {'device_id': ..., 'device_token': ...} — the plaintext token is
  /// only ever returned here, once, for provisioning the physical device.
  Future<Map<String, dynamic>> registerDevice({
    required String schoolId,
    required String name,
    required String type,
    String? categoryCode,
    String? deviceCode,
    String? building,
    String? room,
  }) async {
    final token = await _requireToken();
    final res = await _resolvedClient.rpc('register_device_for_super_admin', params: {
      'p_token': token,
      'p_school_id': schoolId,
      'p_name': name,
      'p_type': type,
      if (categoryCode != null) 'p_category_code': categoryCode,
      if (deviceCode != null) 'p_device_code': deviceCode,
      if (building != null) 'p_building': building,
      if (room != null) 'p_room': room,
    });

    return Map<String, dynamic>.from(res as Map);
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

  /// Fetch the single platform-wide settings row (Super Admin only)
  Future<PlatformSettings> getPlatformSettings() async {
    final token = await _requireToken();
    final res = await _resolvedClient.rpc('get_platform_settings', params: {
      'p_token': token,
    });

    return PlatformSettings.fromRow(Map<String, dynamic>.from(res as Map));
  }

  /// Update the platform-wide settings row (Super Admin only). Only
  /// non-null params are changed; the rest keep their current value.
  Future<PlatformSettings> updatePlatformSettings({
    double? mq2Threshold,
    double? pm25Threshold,
    double? temperatureThreshold,
    int? offlineMinutes,
    String? mqttHost,
    int? mqttPort,
    bool? lineNotify,
    bool? emailNotify,
    bool? pushNotify,
    bool? automaticBackup,
    bool? maintenanceMode,
    bool? twoFactorRequired,
    bool? auditLogEnabled,
    String? language,
    String? timezone,
    int? logRetentionDays,
    String? backupTime,
  }) async {
    final token = await _requireToken();
    final res = await _resolvedClient.rpc('update_platform_settings', params: {
      'p_token': token,
      if (mq2Threshold != null) 'p_mq2_threshold': mq2Threshold,
      if (pm25Threshold != null) 'p_pm25_threshold': pm25Threshold,
      if (temperatureThreshold != null)
        'p_temperature_threshold': temperatureThreshold,
      if (offlineMinutes != null) 'p_offline_minutes': offlineMinutes,
      if (mqttHost != null) 'p_mqtt_host': mqttHost,
      if (mqttPort != null) 'p_mqtt_port': mqttPort,
      if (lineNotify != null) 'p_line_notify': lineNotify,
      if (emailNotify != null) 'p_email_notify': emailNotify,
      if (pushNotify != null) 'p_push_notify': pushNotify,
      if (automaticBackup != null) 'p_automatic_backup': automaticBackup,
      if (maintenanceMode != null) 'p_maintenance_mode': maintenanceMode,
      if (twoFactorRequired != null)
        'p_two_factor_required': twoFactorRequired,
      if (auditLogEnabled != null) 'p_audit_log_enabled': auditLogEnabled,
      if (language != null) 'p_language': language,
      if (timezone != null) 'p_timezone': timezone,
      if (logRetentionDays != null)
        'p_log_retention_days': logRetentionDays,
      if (backupTime != null) 'p_backup_time': backupTime,
    });

    return PlatformSettings.fromRow(Map<String, dynamic>.from(res as Map));
  }

  /// Cross-school course/lesson counts (Super Admin oversight only —
  /// editing stays with teachers via CourseService/LessonService)
  Future<List<CourseOverviewRecord>> getCoursesOverview() async {
    final token = await _requireToken();
    final res = await _resolvedClient.rpc('list_courses_for_super_admin', params: {
      'p_token': token,
    });

    if (res is! List) return [];
    return res
        .map((e) => CourseOverviewRecord.fromRow(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Bulk-import buildings (real backend write — see import_school_buildings_batch)
  Future<BulkImportResult> importBuildingsBatch(
    List<Map<String, dynamic>> buildings,
  ) async {
    final token = await _requireToken();
    final res = await _resolvedClient.rpc('import_school_buildings_batch', params: {
      'p_token': token,
      'p_buildings': buildings,
    });
    return BulkImportResult.fromJson(Map<String, dynamic>.from(res as Map));
  }

  /// Bulk-import rooms, each row referencing a building by its code
  /// (see import_school_rooms_batch)
  Future<BulkImportResult> importRoomsBatch(
    List<Map<String, dynamic>> rooms,
  ) async {
    final token = await _requireToken();
    final res = await _resolvedClient.rpc('import_school_rooms_batch', params: {
      'p_token': token,
      'p_rooms': rooms,
    });
    return BulkImportResult.fromJson(Map<String, dynamic>.from(res as Map));
  }

  /// Bulk-import devices — also used for ชุดฝึก (training kits), which are
  /// just device rows sharing a kit_code (see import_school_devices_batch)
  Future<BulkImportResult> importDevicesBatch(
    List<Map<String, dynamic>> devices,
  ) async {
    final token = await _requireToken();
    final res = await _resolvedClient.rpc('import_school_devices_batch', params: {
      'p_token': token,
      'p_devices': devices,
    });
    return BulkImportResult.fromJson(Map<String, dynamic>.from(res as Map));
  }
}

