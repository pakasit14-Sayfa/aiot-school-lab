import 'package:flutter/foundation.dart';
import 'package:shared_core/shared_core.dart';

import 'school_admin_async_state.dart';

typedef SchoolAdminDeviceScheduleLoadSchedulesLoader =
    Future<List<DeviceSchedule>> Function();
typedef SchoolAdminDeviceScheduleLoadDevicesLoader =
    Future<List<DeviceOption>> Function();
typedef SchoolAdminDeviceScheduleCreateSchedule =
    Future<String> Function({
      required String deviceId,
      required String label,
      required Map<String, dynamic> command,
      required List<int> daysOfWeek,
      required String timeOfDay,
    });
typedef SchoolAdminDeviceScheduleToggleSchedule =
    Future<void> Function({required String scheduleId, required bool enabled});
typedef SchoolAdminDeviceScheduleDeleteSchedule =
    Future<void> Function({required String scheduleId});

final class SchoolAdminDeviceScheduleSnapshot {
  SchoolAdminDeviceScheduleSnapshot({
    required List<DeviceSchedule> schedules,
    required List<DeviceOption> devices,
  }) : schedules = List<DeviceSchedule>.unmodifiable(schedules),
       devices = List<DeviceOption>.unmodifiable(devices);

  final List<DeviceSchedule> schedules;
  final List<DeviceOption> devices;
}

final class SchoolAdminDeviceScheduleController extends ChangeNotifier {
  SchoolAdminDeviceScheduleController({
    required SchoolAdminDeviceScheduleLoadSchedulesLoader loadSchedules,
    required SchoolAdminDeviceScheduleLoadDevicesLoader loadDevices,
    required SchoolAdminDeviceScheduleCreateSchedule createSchedule,
    required SchoolAdminDeviceScheduleToggleSchedule toggleSchedule,
    required SchoolAdminDeviceScheduleDeleteSchedule deleteSchedule,
  }) : _loadSchedules = loadSchedules,
       _loadDevices = loadDevices,
       _createSchedule = createSchedule,
       _toggleSchedule = toggleSchedule,
       _deleteSchedule = deleteSchedule;

  final SchoolAdminDeviceScheduleLoadSchedulesLoader _loadSchedules;
  final SchoolAdminDeviceScheduleLoadDevicesLoader _loadDevices;
  final SchoolAdminDeviceScheduleCreateSchedule _createSchedule;
  final SchoolAdminDeviceScheduleToggleSchedule _toggleSchedule;
  final SchoolAdminDeviceScheduleDeleteSchedule _deleteSchedule;

  SchoolAdminAsyncState<SchoolAdminDeviceScheduleSnapshot> _state =
      const SchoolAdminLoading<SchoolAdminDeviceScheduleSnapshot>();
  SchoolAdminDeviceScheduleSnapshot? _lastConfirmedData;
  bool _isMutating = false;
  bool _disposed = false;

  SchoolAdminAsyncState<SchoolAdminDeviceScheduleSnapshot> get state => _state;
  bool get isMutating => _isMutating;

  Future<void> load() async {
    final previousData = _lastConfirmedData;
    _publish(SchoolAdminLoading(previousData: previousData));
    try {
      _publishCanonical(await _loadCanonical());
    } catch (error, stackTrace) {
      _publish(
        SchoolAdminError(
          message: 'โหลดข้อมูลตารางเวลาอุปกรณ์ไม่สำเร็จ',
          error: error,
          stackTrace: stackTrace,
          previousData: previousData,
        ),
      );
    }
  }

  Future<bool> create({
    required String deviceId,
    required String label,
    required Map<String, dynamic> command,
    required List<int> daysOfWeek,
    required String timeOfDay,
  }) async {
    final normalizedDeviceId = deviceId.trim();
    final normalizedLabel = label.trim();
    final normalizedTime = timeOfDay.trim();
    if (_disposed ||
        _isMutating ||
        normalizedDeviceId.isEmpty ||
        normalizedLabel.isEmpty ||
        command.isEmpty ||
        daysOfWeek.isEmpty ||
        normalizedTime.isEmpty) {
      return false;
    }

    return _runMutation(
      failureMessage: 'บันทึกตารางเวลาอุปกรณ์ไม่สำเร็จ',
      action: () async {
        final scheduleId = (await _createSchedule(
          deviceId: normalizedDeviceId,
          label: normalizedLabel,
          command: Map<String, dynamic>.unmodifiable(command),
          daysOfWeek: List<int>.unmodifiable(daysOfWeek),
          timeOfDay: normalizedTime,
        )).trim();
        if (scheduleId.isEmpty || scheduleId.toLowerCase() == 'null') {
          throw StateError('backend_schedule_id_missing');
        }
        final snapshot = await _loadCanonical();
        if (!snapshot.schedules.any((schedule) => schedule.id == scheduleId)) {
          throw StateError('backend_schedule_not_confirmed');
        }
        return snapshot;
      },
    );
  }

  Future<bool> toggle(String scheduleId, bool enabled) async {
    final normalizedId = scheduleId.trim();
    if (_disposed || _isMutating || normalizedId.isEmpty) return false;

    return _runMutation(
      failureMessage: 'เปลี่ยนสถานะตารางเวลาอุปกรณ์ไม่สำเร็จ',
      action: () async {
        await _toggleSchedule(scheduleId: normalizedId, enabled: enabled);
        final snapshot = await _loadCanonical();
        final confirmed = snapshot.schedules.any(
          (schedule) =>
              schedule.id == normalizedId && schedule.enabled == enabled,
        );
        if (!confirmed) throw StateError('backend_toggle_not_confirmed');
        return snapshot;
      },
    );
  }

  Future<bool> delete(String scheduleId) async {
    final normalizedId = scheduleId.trim();
    if (_disposed || _isMutating || normalizedId.isEmpty) return false;

    return _runMutation(
      failureMessage: 'ลบตารางเวลาอุปกรณ์ไม่สำเร็จ',
      action: () async {
        await _deleteSchedule(scheduleId: normalizedId);
        final snapshot = await _loadCanonical();
        if (snapshot.schedules.any((schedule) => schedule.id == normalizedId)) {
          throw StateError('backend_delete_not_confirmed');
        }
        return snapshot;
      },
    );
  }

  Future<bool> _runMutation({
    required String failureMessage,
    required Future<SchoolAdminDeviceScheduleSnapshot> Function() action,
  }) async {
    final previousData = _lastConfirmedData;
    _isMutating = true;
    _notifySafely();
    try {
      _publishCanonical(await action());
      return true;
    } catch (error, stackTrace) {
      _publish(
        SchoolAdminError(
          message: failureMessage,
          error: error,
          stackTrace: stackTrace,
          previousData: previousData,
        ),
      );
      return false;
    } finally {
      _isMutating = false;
      _notifySafely();
    }
  }

  Future<SchoolAdminDeviceScheduleSnapshot> _loadCanonical() async {
    final results = await Future.wait<dynamic>(<Future<dynamic>>[
      _loadSchedules(),
      _loadDevices(),
    ]);
    return SchoolAdminDeviceScheduleSnapshot(
      schedules: results[0] as List<DeviceSchedule>,
      devices: results[1] as List<DeviceOption>,
    );
  }

  void _publishCanonical(SchoolAdminDeviceScheduleSnapshot snapshot) {
    if (_disposed) return;
    _lastConfirmedData = snapshot;
    _publish(SchoolAdminData(snapshot));
  }

  void _publish(SchoolAdminAsyncState<SchoolAdminDeviceScheduleSnapshot> next) {
    if (_disposed) return;
    _state = next;
    notifyListeners();
  }

  void _notifySafely() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
