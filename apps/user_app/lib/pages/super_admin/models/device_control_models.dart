import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import '../theme/app_palette.dart';

class SchoolItem {
  const SchoolItem({
    required this.databaseId,
    required this.schoolCode,
    required this.name,
    required this.province,
    required this.packageName,
    required this.status,
    required this.totalDevices,
    required this.onlineDevices,
    required this.openAlerts,
  });

  final String databaseId;
  final String schoolCode;
  final String name;
  final String province;
  final String packageName;
  final String status;
  final int totalDevices;
  final int onlineDevices;
  final int openAlerts;

  factory SchoolItem.fromRecord(DeviceControlSchoolRecord record) {
    return SchoolItem(
      databaseId: record.databaseId,
      schoolCode: record.schoolCode,
      name: record.name,
      province: record.province,
      packageName: record.packageName,
      status: record.status,
      totalDevices: record.totalDevices,
      onlineDevices: record.onlineDevices,
      openAlerts: record.openAlerts,
    );
  }
}

class ProtectedScope {
  const ProtectedScope({
    required this.code,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String code;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
}

class ApprovalItem {
  const ApprovalItem({
    required this.databaseId,
    required this.schoolId,
    required this.schoolName,
    required this.scope,
    required this.action,
    required this.reason,
    required this.targetCount,
    required this.status,
    required this.requestedBy,
    required this.requesterName,
    required this.requestedAt,
    required this.expiresAt,
    required this.approverName,
    required this.decisionNote,
  });

  final String databaseId;
  final String schoolId;
  final String schoolName;
  final String scope;
  final String action;
  final String reason;
  final int targetCount;
  final String status;
  final String requestedBy;
  final String requesterName;
  final DateTime? requestedAt;
  final DateTime? expiresAt;
  final String? approverName;
  final String decisionNote;

  factory ApprovalItem.fromRecord(DeviceControlApprovalRecord record) {
    return ApprovalItem(
      databaseId: record.id,
      schoolId: record.schoolId,
      schoolName: record.schoolName,
      scope: record.command.contains('building')
          ? 'building'
          : (record.command.contains('school') ? 'school' : 'main'),
      action: record.command,
      reason: record.notes ?? '',
      targetCount: 1,
      status: record.status,
      requestedBy: record.requestedBy,
      requesterName: record.requesterName,
      requestedAt: record.createdAt,
      expiresAt: record.createdAt?.add(const Duration(hours: 24)),
      approverName: record.reviewerName,
      decisionNote: record.notes ?? '',
    );
  }

  bool get turnOn => action == 'power_on';

  String get scopeLabel {
    switch (scope) {
      case 'water':
        return 'ระบบน้ำ';
      case 'electricity':
        return 'ระบบไฟฟ้า';
      case 'main':
      default:
        return 'อุปกรณ์หลัก';
    }
  }

  String get requestedLabel {
    final DateTime? value = requestedAt;

    if (value == null) {
      return '-';
    }

    final String hour = value.hour.toString().padLeft(2, '0');
    final String minute = value.minute.toString().padLeft(2, '0');

    return '${value.day}/${value.month}/${value.year + 543} '
        '$hour:$minute น.';
  }
}

class DeviceItem {
  final String databaseId;
  final String schoolId;
  final String id;
  final String name;
  final String school;
  final String building;
  final String room;
  final String type;
  final String categoryCode;
  final IconData icon;
  final bool online;
  final String reading;
  final String updated;
  final String commandStatus;
  final Map<String, dynamic> metadata;

  bool isOn;
  bool autoMode;

  DeviceItem({
    required this.databaseId,
    required this.schoolId,
    required this.id,
    required this.name,
    required this.school,
    required this.building,
    required this.room,
    required this.type,
    required this.categoryCode,
    required this.icon,
    required this.online,
    required this.isOn,
    required this.autoMode,
    required this.reading,
    required this.updated,
    required this.commandStatus,
    required this.metadata,
  });

  factory DeviceItem.fromRecord(DeviceControlItemRecord record) {
    IconData icon;

    switch (record.categoryCode) {
      case 'SEN':
        icon = Icons.sensors_rounded;
        break;
      case 'CAM':
        icon = Icons.videocam_rounded;
        break;
      case 'RLY':
        icon = Icons.electrical_services_rounded;
        break;
      case 'WTR':
        icon = Icons.water_drop_rounded;
        break;
      case 'PWR':
        icon = Icons.power_rounded;
        break;
      case 'GTW':
        icon = Icons.router_rounded;
        break;
      case 'CTL':
      default:
        icon = Icons.developer_board_rounded;
        break;
    }

    final DateTime? updatedDt = record.updatedAt;
    final String updatedStr = updatedDt != null
        ? '${updatedDt.day}/${updatedDt.month} ${updatedDt.hour.toString().padLeft(2, '0')}:${updatedDt.minute.toString().padLeft(2, '0')}'
        : '-';

    return DeviceItem(
      databaseId: record.databaseId,
      schoolId: record.schoolId,
      id: record.deviceCode,
      name: record.name,
      school: record.schoolName,
      building: record.building,
      room: record.room,
      type: record.categoryCode,
      categoryCode: record.categoryCode,
      icon: icon,
      online: record.online,
      isOn: record.isPoweredOn,
      autoMode: record.controlMode == 'auto',
      reading: record.readingLabel,
      updated: updatedStr,
      commandStatus: 'idle',
      metadata: Map<String, dynamic>.from(record.metadata),
    );
  }

  bool get commandPending {
    return <String>{
      'pending',
      'processing',
      'queued',
    }.contains(commandStatus.toLowerCase());
  }
}

class ActionLog {
  final String title;
  final String detail;
  final String time;
  final String actor;
  final bool success;

  const ActionLog({
    required this.title,
    required this.detail,
    required this.time,
    required this.actor,
    required this.success,
  });

  factory ActionLog.fromRecord(DeviceControlLogRecord record) {
    final DateTime? dt = record.createdAt;
    final String timeStr = dt != null
        ? '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
        : '-';

    final String eventTypeLower = record.eventType.toLowerCase();
    final bool looksFailed = eventTypeLower.contains('fail') ||
        eventTypeLower.contains('error') ||
        eventTypeLower.contains('denied') ||
        eventTypeLower.contains('reject');

    return ActionLog(
      title: record.eventType,
      detail: record.message,
      time: timeStr,
      actor: 'ระบบ',
      success: !looksFailed,
    );
  }
}

class ControlPermission {
  final String email;
  final String detail;
  final Color color;

  const ControlPermission({
    required this.email,
    required this.detail,
    required this.color,
  });

  factory ControlPermission.fromRecord(DeviceControlPermissionRecord record) {
    Color color;

    switch (record.role) {
      case 'super_admin':
        color = AppPalette.deepBlue;
        break;
      case 'support':
        color = AppPalette.gardenGreen;
        break;
      case 'school_admin':
        color = AppPalette.circusYellow;
        break;
      case 'operator':
      default:
        color = const Color(0xFF1676B5);
        break;
    }

    return ControlPermission(
      email: record.email,
      detail: '${record.fullName} (${record.schoolName ?? "ทุกโรงเรียน"})',
      color: color,
    );
  }
}
